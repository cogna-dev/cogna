# Cogna Cache-First 重构设计

本文定义 Cogna 下一轮从 **registry / publish / bundle 分发工作流** 迁移到 **cache-first** 架构的目标形态。

这次重构的关键不是把 registry 改名，而是把“远程复用一个包的构建结果”收口成一个更小、更稳定的抽象：

- 核心 cache 接口只有 `get` / `put`
- `get` / `put` 的语义单位是**完整包**，不是 manifest + 多个 blob
- backend 可以是 local filesystem、HTTP、未来的 DB
- `build` 依赖 cache，而不是依赖 `publish` / `registry bundle` 工作流
- `serve` 暴露的是 HTTP cache proxy，而不是 package registry

---

## 1. 背景与问题

当前实现的问题不在于“registry 做得不够多”，而在于概念层次过重：

- CLI 暴露了 `publish`、`registry serve`、`registry status`
- 配置文件包含 `publish` / `registry` 两个独立 section
- HTTP contract 以 bundle upload / resolve / versions 为中心
- build / publish / registry 三层之间耦合了 `bundleId`、`downloadUrl`、`receipt`、`ETag` 等中间概念

这导致两个直接问题：

1. 用户必须理解过多内部概念，才能复用远程产物
2. 想扩展新的 storage/backend（例如 HTTP cache、DB cache）时，必须复制整套 registry 语义，而不是复用一个小接口

因此本轮重构的目标不是继续优化 registry，而是**用 cache 抽象取代 registry 抽象**。

同时，本轮也明确做出一个设计选择：

> 对 Cogna 来说，`get` / `put` 的原子单位是**一个完整包的 bundle**，而不是若干独立 artifact 组成的 manifest。

这意味着一个包不会拆成多次 `put`，从而避免部分成功、部分失败的中间态。

---

## 2. 设计目标

## 2.1 核心目标

1. **统一 cache 接口**
   - 只保留 `get(key)` / `put(key, bundle)`
   - backend 不感知 package registry、publish receipt、bundleId 等高层概念

2. **初始支持两个 backend**
   - `src/cache/local`
   - `src/cache/http`

3. **build 改为依赖 cache**
   - 默认使用 local cache
   - 若配置为 http cache，则 build 对依赖先走远程 read-through，再落回 local cache
   - 命中 cache 时不再重新构建依赖

4. **CLI 改造**
   - 删除 `publish`
   - 删除 `registry ...`
   - 新增 `cogna serve`
   - 新增 `cogna cache list/add/remove`

5. **serve 改为 cache proxy**
   - `cogna serve` 作为一个 HTTP cache proxy
   - 对外只暴露完整 package bundle 的读取/写入语义
   - proxy 到当前配置的 backend（本轮为 local，未来可扩展 DB）

## 2.2 次级目标

- 保留 `.cogna/cache/` 作为本地缓存根目录的直觉
- 最大化复用现有 HTTP client/server、atomic write、digest helper、bundle materialize helper
- 让用户只需要理解“一个包对应一个 bundle object”，而不必理解 manifest/blob/CAS 细节

---

## 3. 非目标

本轮明确**不做**：

1. 不保留兼容旧 registry API 的双写模式
2. 不继续维护 `cogna-registry-upload/v1`、`cogna-publish-receipt/v1`、`cogna-registry-download/v1`
3. 不要求 build 在 remote miss 时自动把结果回写到远端 HTTP cache
4. 不在 v1 里把 cache management HTTP API 扩展成完整管理平面（`list/remove` 先保留在 CLI 本地管理面）
5. 不把 backend 接口膨胀成 enumerate/delete/query 等大而全协议
6. 不引入 `manifest + blob` 形式的多对象 package 协议

核心原则是：**backend 接口小，package 语义原子，管理能力按需要在更上层补。**

---

## 4. 核心抽象

## 4.1 Cache object

cache backend 只处理“key 对应的一段 bytes”，但在 Cogna v1 中，这段 bytes 的业务语义被明确约束为：

> **一个完整 package bundle**

逻辑结构：

```text
Cache.get(key) -> CacheObject?
Cache.put(key, object) -> PutResult
```

建议对象模型：

```text
CacheObject {
  key: String,
  body: Bytes,
  content_type: String,
  digest: String,
}
```

说明：

- `body` 是完整 bundle bytes
- `content_type` 用于 HTTP 传输和调试
- `digest` 用于校验与幂等判断
- backend 本身不需要理解包内部的 manifest、declarations、symbols、sbom 等内容

## 4.2 原子性约束

本设计的第一原则是：

> **一个包 = 一个 cache key = 一个完整 bundle = 一次原子 get/put**

这意味着：

- 一个 package 不应拆成多次 `put`
- 一个 package 的远程获取不应拆成“先取 manifest，再拉多个 blob”
- `put` 成功后，后续 `get` 要么得到完整 bundle，要么 miss，不能暴露半成品状态

这是一个刻意取舍。

我们放弃 blob 级 dedup、manifest-last push、orphan blob GC 等复杂度，换取：

- package 语义简单
- 失败模型简单
- 客户端与服务端实现简单
- 对小包和多包仓库更符合直觉

## 4.3 Key 设计

cache key 仍然是 **opaque string**，但 Cogna v1 约定一个标准 package namespace：

```text
package/<escaped-purl>/<source-digest>
```

也可等价简写为：

```text
pkg/<escaped-purl>/<source-digest>
```

其中：

- `escaped-purl` 用于表达包身份
- `source-digest` 用于表达构建输入快照

设计目标：

- backend 仍然只看 string key + bytes
- build 层可以稳定定位“这个 package 这次输入对应的完整 bundle”
- 不再需要区分 `blob/...` 与 `index/...`

## 4.4 数据交换格式

cache 协议层传输的是**完整 bundle 文件**，不是高层 manifest 文档。

Cogna v1 的 exchange format 为：

```text
bundle.ciq.tgz
```

即：

```text
key -> bundle.ciq.tgz
```

bundle 内部包含：

- `manifest.json`
- `declarations.ndjson`
- `metadata.json`
- `checksums.txt`
- policy profile 需要的附加文件

关键区分是：

- `manifest.json` 是 **bundle 内部格式** 的一部分
- 它**不是 cache 协议层对象**

换句话说，本轮设计不是删除 manifest，而是把 manifest 限定在 bundle 内部，不再把它提升成外部 cache contract。

相较于早期设计，以下内容已从 bundle 中移除：

- `symbols.ndjson`：其字段是 `declarations.ndjson` 的子集，查询层可直接从 declarations 满足 `QueryOutlines` / `Query` 所需，不再需要独立索引文件
- `sbom.spdx.json`：三方包的完整 SPDX SBOM 不再作为 bundle 产物分发；当前项目的 SBOM 只缓存到项目根目录 `.cogna/sbom.spdx.json`（参见 `spec/api.md §1.3`）

## 4.5 bundle 内部字段约束

bundle 内部文件的字段集合应与用户侧 API 所需保持对齐，不应把内部实现字段全量写入交换格式。

### declarations.ndjson

每行一条 JSON，字段约束：

| 字段 | 是否必须 | 说明 |
|------|----------|------|
| `id` | ✅ | 稳定接口 ID，如 `decl:go:pkg.Func` |
| `kind` | ✅ | `function` / `method` / `struct` / `interface` 等 |
| `symbol` | ✅ | canonical path，即用户侧 `symbol` 字段 |
| `signature` | ✅ | 规范化签名文本 |
| `summary` | 可选 | 摘要，一行 |
| `docs` | 可选 | 文档片段 |
| `deprecated` | 可选 | 是否废弃 |
| `location` | 可选 | `{ uri, startLine, endLine }` |

以下字段**不应写入 bundle**：

- `shape`：已编码在 `signature` 中，重复且体积大
- `language_specific`：各语言特有扩展字段，对查询 / 浏览无必要
- `source_refs`：`location` 已覆盖位置信息，`source_refs` 数组是冗余
- `baselineRole`：内部流程概念，不属于交换格式
- `relations`：结构关系图，体积大且不被当前用户侧 API 消费
- `visibility`：bundle 只包含 public 声明，此字段无信息量

### dependency truth（替代说明）

`software-components.ndjson` 已退出 bundle public contract。

当前依赖事实来源统一为：

- workspace 根目录 `.cogna/sbom.spdx.json`

如果 `diff` 需要 dependency changes，应在 native diff 过程中从 SPDX **临时派生**比较输入，而不是把 `software-components.ndjson` 持久化进 bundle。

---

## 5. Backend 设计

## 5.1 `src/cache/local`

本地 backend 是所有模式下的基础。

职责：

- 按 key 读取完整 bundle object
- 原子写入完整 bundle object
- 维护最小 metadata 以支持 `cache list/remove`
- 作为 http read-through 的落地点

### 建议目录布局

```text
.cogna/cache/
├── objects/
│   └── <key-hash>.tgz
├── meta/
│   └── <key-hash>.json
├── index/
│   └── keys.jsonl
└── tmp/
```

其中：

- `objects/` 保存完整 bundle bytes
- `meta/` 保存原始 key、digest、size、contentType、timestamps
- `index/keys.jsonl` 用于实现 prefix list
- `tmp/` 用于原子写入

### 原子性要求

本地 backend 的**权威提交点**必须围绕完整 bundle 文件设计：

1. 先把完整 bundle 写入 `tmp/`
2. 校验 digest / size
3. 原子 rename 到 `objects/<key-hash>.tgz`
4. metadata 与 list index 作为辅助结构更新

重要约束：

- `objects/` 是权威数据
- `meta/` 与 `index/` 是辅助结构
- 即使 metadata 或 index 损坏，也不应影响“对象已成功写入”这一事实

换句话说，`get(key)` 的可用性不能被 sidecar 元数据绑定成共同提交事务。

### 为什么不用“key 直接映射到路径”

因为 key 是 opaque string，未来可能包含 `/`、`:`、`@`、`?` 等符号。直接映射路径会把 backend 和 key 编码强耦合。采用 `key-hash + metadata` 的本地布局更稳定，也更容易支持 prefix list。

### 可复用现有代码

- `src/registry/server/storage.mbt`
  - `ensure_dir()`
  - `write_bytes_atomic()` / lockdir 模式
  - sha256 digest helper
- `src/core/snapshot/main.mbt`
  - 内容摘要计算
- `src/core/bundle/reader.mbt`
  - 从 `bundle.ciq.tgz` materialize 到 `dist/`

## 5.2 `src/cache/http`

HTTP backend 的职责是把远程 cache server 映射成同样的 `get/put` 语义。

职责：

- `get(key)` -> 发 HTTP GET，返回完整 bundle bytes
- `put(key, object)` -> 发 HTTP PUT，提交完整 bundle bytes
- 处理 200/404/409/5xx 等状态
- 透传 `Content-Type` 与 `X-Cogna-Digest`

### HTTP backend 约束

- v1 默认是**同步 request/response** 语义
- 不要求 streaming multipart
- 不要求 server-side `list/remove`
- build 不依赖 HTTP backend 的 enumerate 能力

### 幂等与冲突语义

同一个 key 建议视为**不可变对象标识**。

因此：

- 重复上传相同 digest 的同一 key，可返回 `200` 或 `201`
- 同一 key 若对应不同 digest，应返回 `409`

这能避免“同一个 package key 被覆盖成不同 bundle”带来的语义漂移。

---

## 6. HTTP Cache Proxy（`cogna serve`）

## 6.1 目标

`cogna serve` 的职责不是提供 package registry，而是把当前配置的 cache backend 暴露成一个稳定的 HTTP package bundle cache。

这使得：

- 本地 filesystem cache 可以被远程消费
- 将来 DB cache 可以通过同一 HTTP contract 暴露
- 网关、鉴权、流控都可以放在 proxy 前面处理

## 6.2 路由设计

目标形态的 v1 建议只暴露 3 条路由：

### `GET /health`

健康检查。

### `GET /cache/v1/package?key=<key>`

- 命中返回 `200`
- body 为完整 `bundle.ciq.tgz` bytes
- `Content-Type` 建议返回 `application/vnd.cogna.bundle.v1+gzip`
- 也允许兼容返回 `application/gzip`
- 可返回 `X-Cogna-Digest`
- 未命中返回 `404`

### `PUT /cache/v1/package?key=<key>`

- 请求体为完整 `bundle.ciq.tgz` bytes
- 请求头应包含 `Content-Type`
- 可包含 `X-Cogna-Digest`
- 成功返回 `200` 或 `201`
- 若 key 已存在但 digest 不一致，返回 `409`

### 为什么使用 query 参数传 key

因为 key 是 opaque string。使用 `?key=` 比把 key 编进 path 更容易保持“backend 不关心 key 编码细节”的原则。

## 6.3 serve 行为

- `cache.type=local`：直接代理到 local backend
- `cache.type=http`：serve 不应再次代理回上游 http backend 形成自环；v1 中 `serve` 只服务本地 store

因此在 v1：

- `cogna serve` 的真实服务对象应始终是本地 store
- `cache.type=http` 仅表示 build 的默认读取来源是远端 HTTP cache

这能避免“serve 出去的还是另一个 serve”的递归语义。

## 6.4 术语约束

在本 spec 中：

- `bundle`：指一个 package 的自包含归档
- `object`：指 cache backend 存储的对象
- 在 Cogna v1 中，两者是一一对应关系

也就是说：

```text
package bundle == cache object
```

---

## 7. 配置设计

## 7.1 配置目标

配置文件需要表达两件事：

1. 默认使用哪种 cache backend
2. backend 的参数是什么

同时，**无论是否选择 http backend，都必须保留本地 store**，因为 build 需要把远程结果落到本地并 materialize。

因此，`storeDir` 不应挂在 `cache.local.*` 下，而应提升为 `cache.*` 的共享字段。

## 7.2 目标配置结构

```yaml
cache:
  type: local
  storeDir: .cogna/cache
  http:
    baseUrl: http://127.0.0.1:8787
    timeoutMs: 10000
    headers: {}
```

### 默认配置

用户不需要显式配置本地 store 也可以工作，因此推荐默认配置写法尽量简化：

```yaml
cache:
  type: local
```

默认值为：

```yaml
cache:
  type: local
  storeDir: .cogna/cache
  http:
    baseUrl: ""
    timeoutMs: 10000
    headers: {}
```

### HTTP 模式示例

```yaml
cache:
  type: http
  http:
    baseUrl: https://cache.example.com
    timeoutMs: 10000
    headers:
      Authorization: Bearer ${COGNA_CACHE_TOKEN}
```

这里没有重复配置 `storeDir`，因为本地 store 在任何模式下都存在，只是默认值通常够用。

## 7.3 验证规则

- `cache.type` 必须是 `local` 或 `http`
- `cache.storeDir` 若显式配置则不能为空
- 若 `cache.type == http`：
  - `cache.http.baseUrl` 不能为空
  - `cache.http.timeoutMs` 必须在合法范围内

## 7.4 配置迁移

删除：

- `publish.*`
- `registry.port`
- `registry.storeDir`

新增：

- `cache.type`
- `cache.storeDir`
- `cache.http.baseUrl`
- `cache.http.timeoutMs`
- `cache.http.headers`

---

## 8. Build 与 Cache 的关系

## 8.1 总体原则

`build` 不再依赖 `publish` / `registry download` 工作流，而改成：

1. 为当前输入生成 source digest
2. 生成 package key
3. 先查 local cache
4. 若配置为 http，则在 local miss 时查 remote http cache
5. remote hit 时把完整 bundle 写回 local cache
6. 都 miss 时，本地构建并写入 local cache

## 8.2 Read-through 行为

当 `cache.type=http` 时，build 的行为是：

```text
local.get(package-key)
  miss -> http.get(package-key)
    hit -> local.put(package-key, full-bundle) -> materialize dist/
    miss -> local build -> local.put(package-key, full-bundle)
```

v1 中**不默认执行 `http.put(...)`**。

原因：

- 远端 cache 往往需要额外鉴权/审批
- build 的默认职责是消费 cache，而不是发布 cache
- 远端写入可以通过后续 CI、`cogna cache add` 或独立 pipeline 完成

## 8.3 Build 需要缓存什么

build 缓存的不是若干独立 artifact，而是**完整 bundle**。

即：

- `manifest.json`
- `declarations.ndjson`（字段已按 §4.5 裁剪）
- `metadata.json`
- `checksums.txt`
- 以及可选 policy artifacts

不包含：

- `symbols.ndjson`（已移除，查询层从 declarations 直接满足）
- `sbom.spdx.json`（已移除，当前项目 SBOM 缓存到 `.cogna/sbom.spdx.json`，不随三方包 bundle 分发）

这些内容一起打包成：

```text
bundle.ciq.tgz
```

并作为一个完整 cache object 存储。

## 8.4 为什么不采用 manifest + blob

`manifest + blob` 的优势在于：

- blob 级 dedup
- 并行上传/下载
- 细粒度复用

但它也天然带来：

- 多次 `put`
- manifest-last 顺序依赖
- orphan blob
- manifest 引用缺失
- 更复杂的失败恢复与 GC

对 Cogna 来说，这个 tradeoff 不成立：

- 单个 package 的尺寸通常不大
- 大型 monorepo 通常天然拆成多个 package
- “一个 package 一次原子 get/put”比 blob 级 dedup 更重要

因此本轮明确选择：

> **优先 package 原子性，而不是 blob 级去重。**

## 8.5 与当前代码的主要改造点

- `src/cmd/build/main.mbt`
  - 保持 `bundle.ciq.tgz` 作为 cache 主体
  - package key 改为统一 package namespace
- `src/cmd/build/local_index.mbt`
  - 删除旧 config 透传残留
- `src/cmd/build/sbom.mbt`
  - 去掉对旧 registry helper 的耦合
- build orchestration
  - 保持“先查 cache，再构建”的 read-through 路径

---

## 9. CLI 设计

## 9.1 删除的命令

- `cogna publish`
- `cogna registry serve`
- `cogna registry status`

## 9.2 新增命令

### `cogna serve`

启动 HTTP cache proxy。

建议参数：

- `--port <int>`：监听端口

### `cogna cache list`

列出本地 cache 中的 key。

建议参数：

- `--prefix <string>`：按 key 前缀过滤

### `cogna cache add`

把一个完整 bundle 写入本地 cache。

建议参数：

- `--key <string>`
- `--file <path>` 或 `--stdin`
- `--content-type <string>`（可选）

### `cogna cache remove`

从本地 cache 删除一个 key。

建议参数：

- `--key <string>`

## 9.3 为什么 list/add/remove 先做“本地管理面”

因为核心 backend 接口被有意限制为 `get/put`。`list/remove` 属于运维管理能力，不应反向要求所有 backend 都实现 enumerate/delete。

因此 v1 选择：

- `cache list/add/remove` 先管理 local cache
- 远端管理若需要，后续再做专门的 admin API 或外部工具

---

## 10. 模块与文件重组

## 10.1 新模块

- `src/cache/main.mbt`
  - cache types / shared helpers / backend selection
- `src/cache/local/main.mbt`
  - local filesystem backend
- `src/cache/http/main.mbt`
  - HTTP backend
- `src/cmd/serve/main.mbt`
  - `cogna serve`
- `src/cmd/cache/main.mbt`
  - `cache list/add/remove`

## 10.2 需要删除或退役的模块

- `src/cmd/publish/`
- `src/cmd/registry/`
- `src/registry/`

## 10.3 需要重构的模块

- `src/cmd/main/main.mbt`
  - subcommand parser / help / dispatch
- `src/config/types.mbt`
  - 删除 `PublishSettings` / `RegistrySettings`
  - `CacheSettings` 改为 `type + storeDir + http`
- `src/config/defaults.mbt`
- `src/config/load.mbt`
- `src/config/validate.mbt`
- `src/cmd/init/config.mbt`
  - 默认模板改为精简 `cache:` section
- `openapi.json`
  - 从旧 registry API 改为 package bundle cache API

---

## 11. 迁移策略

## Stage A — 设计冻结

交付物：

- `spec/cache.md`
- config / command / build / HTTP contract 的目标形状

验收标准：

- 可以明确回答“registry / publish 将如何被替换”
- 可以明确回答“为什么 package 是原子 get/put 单位”
- 可以明确回答“http cache 与 local cache 在 build 时如何协作”

## Stage B — 配置与命令骨架

交付物：

- 新 `cache` config model
- `cogna serve`
- `cogna cache list/add/remove`
- 删除旧 CLI surface

验收标准：

- `cogna --help` 不再出现 `publish` / `registry`
- init 生成的配置模板只包含 `cache`

## Stage C — backend 落地

交付物：

- `src/cache/local`
- `src/cache/http`
- package bundle cache proxy HTTP server

验收标准：

- local get/put 通过
- http get/put 通过
- `cogna serve` 能稳定代理 local store

## Stage D — build read-through 集成

交付物：

- build 先查 cache，再构建
- http hit -> local mirror 生效

验收标准：

- 在 `cache.type=http` 模式下，依赖命中远端 cache 时不会重新构建
- 远端命中 bundle 被写入 local cache，二次构建可离线命中

## Stage E — 旧系统删除与文档收口

交付物：

- 删除 `src/registry/` / `src/cmd/publish/` / `src/cmd/registry/`
- 更新文档、OpenAPI、progress

验收标准：

- 仓库中不再以 registry/publish 作为主叙事
- 用户侧文档以 package-atomic cache-first 为准

---

## 12. 风险与关键决策

## 12.1 风险：旧 build 仍深度依赖 registry helper

当前 `src/cmd/build/sbom.mbt`、`src/cmd/build/local_index.mbt` 仍带着一些历史残留。重构时应先把“配置透传”和“transport helper”拆开，再完全收口到 cache。

## 12.2 风险：把管理能力塞回 backend 接口

如果为了 `cache list/remove` 把 backend 强行扩成 enumerate/delete，就会重蹈 registry 概念过重的问题。v1 必须守住“核心接口只有 get/put”。

## 12.3 决策：build remote miss 不自动推送远端

这是一个刻意决定，而不是遗漏。它让 build 行为更可预测，也避免把消费路径和发布路径重新绑死。

## 12.4 决策：package 是原子 get/put 单位

这是本轮最重要的设计决定。

原因：

- 多于一次 `put` 就会引入部分失败的风险
- Cogna 包体一般较小，不值得为 blob 级 dedup 引入高复杂度
- 大型仓库通常通过多 package 拆分，而不是依赖单 package 巨型对象

因此本轮明确不采用 `manifest + blobs`。

## 12.5 决策：serve 面向本地 store，而不是继续转发到上游 http

`cogna serve` 的价值是把本地或底层 storage 暴露成一个标准 HTTP cache 面。若直接把上游 http cache 再 serve 一层，会产生不必要的代理递归和配置歧义。

---

## 13. 当前结论

本轮重构的核心不是“把 registry 改名成 cache”，而是：

1. 把 transport/backend 收口成 `get/put`
2. 把一个 package 的远程复用单位固定为**完整 bundle**
3. 把远程复用改成 http read-through local cache
4. 把 CLI 从 `publish/registry` 改成 `serve/cache`

这样之后：

- backend 可扩展
- 构建链路更简单
- 失败模型更简单
- transport 更薄
- 用户不必理解 bundleId、receipt、manifest/blob、downloadUrl 等中间概念

这就是 Cogna 下一轮 **package-atomic cache-first** 架构的目标状态。
