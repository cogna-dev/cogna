# Extractor / Virtual Package / Native Build-Diff 重构计划（2026-04-18）

本文覆盖下一轮 extractor 系统重构，目标不是继续修补当前 `src/sdk/build.mbt` / `src/sdk/diff.mbt`，而是重建一个**统一输入模型**：

1. 本地源码目录；
2. 包管理器**已经安装到本机**的 package@version（Cargo / Go / Terraform）；
3. Git 仓库快照；

都先被解析成同一种 **readonly virtual package**，再交给 extractor 统一处理。

---

## 1. 本计划解决什么问题

当前仓库的 extractor / build / diff 仍有四个根问题：

1. `src/sdk/build.mbt` 同时承担了：
   - 抽取；
   - 写 `dist/*`；
   - 写 dependency bundles；
   - cache restore/store；
   - bundle materialize；
   这使 `src/sdk/` 不是 readonly SDK，而是 side-effectful runtime。
2. `src/cmd/build/main.mbt` 只是薄封装，直接委托 `@sdk.run_build(...)`；
3. `src/sdk/diff.mbt` 仍默认读取 `software-components.ndjson`，把 dependency artifact 混进 bundle public contract；
4. extractor 只能稳定处理本地目录，对“本机已安装 package source / git repo snapshot”没有统一输入抽象。

本轮必须把这些边界收口清楚。

---

## 2. 不可退让的硬规则

## 2.1 Build / Diff 只允许 native target

从本轮开始：

- `build` 是 **native-only** command；
- `diff` 是 **native-only** command；
- 任何需要：
  - 文件写入；
  - cache 写入；
  - HTTP 下载；
  - archive 解包；
  - git clone；
  的逻辑，都不得再停留在 `src/sdk/` 公共 API 中。

## 2.2 `src/sdk/` 必须变成 readonly

`src/sdk/` 只允许保留：

- query / outlines；
- fetch packages（从当前 workspace 的 `.cogna/sbom.spdx.json` 读取）；
- bundle / diff result / query result 的 parse / load / normalize helper；
- 纯函数：只读文件、只做内存计算、绝不写 `dist/`。

明确禁止：

- `sdk.build()`
- `sdk.diff()`
- `sdk.run_build()`
- `sdk_write_*`
- cache put/get materialize 这种命令级副作用

## 2.3 当前工作目录 `.` 仍是产品主交互边界

用户侧产品模型仍然是：

- 打开源码仓库目录 `.`；
- 读取 `cogna.yml`；
- 读取 / 写入 `.cogna/`；
- 生成 `dist/`；

因此：

- Cargo / Go / Terraform 的 package@version **不再解释成隐式远程下载入口**；
- build 只读取包管理器已经安装在本机的内容；
- 若本机未安装，则立即报错并提示用户先运行对应包管理器命令；
- 不把 `e2e` fixture 当成运行时 fallback；
- 不把 package manager registry / proxy 直接包装成新的用户主工作流，直到本地源码工作流完全稳定。

## 2.4 Virtual package 一律是 readonly file map

统一输入模型必须表现为：

```text
path -> content(bytes)
```

至少具备：

- 规范化路径；
- 读取 bytes / text；
- 枚举文件；
- 计算内容摘要；

但不应默认暴露写入能力。

## 2.5 `software-components.ndjson` 不再是 bundle public contract

本轮默认目标：

- bundle 内删除 `software-components.ndjson`；
- 当前 workspace 的直接依赖事实以 `.cogna/sbom.spdx.json` 为准；
- 若 `diff` 仍需 dependency changes，则在 native diff 过程中**临时**从 SPDX 派生，不再把它作为 bundle artifact 持久化。

---

## 3. 目标架构

## 3.1 统一输入：`VirtualPackage`

新增统一模型：

```text
SourceSpec -> NativeResolver -> VirtualPackage -> Extractor -> Declarations
```

建议核心类型：

### `SourceSpec`

```text
LocalWorkspace {
  root_dir: String
}

CargoPackage {
  name: String
  version: String
}

GoModule {
  module_path: String
  version: String
}

TerraformPackage {
  kind: "module" | "provider"
  source: String
  version?: String
}

GitRepo {
  url: String
  ref?: String
}
```

### `VirtualFile`

```text
{
  path: String,
  bytes: Bytes,
  sha256: String,
  size: Int,
}
```

### `VirtualPackage`

```text
{
  source_kind: "local" | "cargo" | "gomod" | "terraform" | "git",
  source_id: String,
  display_name: String,
  root_hint: String,
  files: Array[VirtualFile],
}
```

### `ReadonlyPackageView`

extractor 真正依赖的接口应是：

```text
list_paths() -> Array[String]
read_bytes(path) -> Result[Bytes, String]
read_text(path) -> Result[String, String]
exists(path) -> Bool
```

> v1 可直接用 eager `Array[VirtualFile]` 实现，不必一开始就做 lazy filesystem/mount abstraction。

## 3.2 路径规范化规则

所有 `VirtualPackage` 路径统一为：

- 相对包根目录；
- `/` 分隔；
- 无 `./` 前缀；
- 禁止 `..` 逃逸；
- 安装缓存根目录（例如 `crate-name-version/`、`module@version/`、`.terraform/modules/<key>/`）在进入 extractor 前剥离。

## 3.3 代码边界

### 纯逻辑（可跨 target）

放在 `src/core/virtual_package/*` 与 extractor/core 层：

- `SourceSpec` / `VirtualPackage` / `ReadonlyPackageView` 类型；
- path normalization；
- directory / installed-cache to file-map normalize helper；
- extractor against readonly package；
- declaration normalization；
- diff pure compare helper；
- SPDX 读取与 direct dependency normalize helper。

### native-only 适配层

放在 `src/cmd/build/*` / `src/cmd/diff/*`：

- git clone；
- 本地 package-manager install path 探测；
- cache read/write；
- bundle materialize / cache restore；
- 写 `dist/` / `.cogna/`；
- 调用纯逻辑后把结果落盘。

---

## 4. 本地已安装 source 读取设计

本轮的核心原则是：

- build **不主动下载** Cargo / Go / Terraform 依赖；
- 对 package@version，只探测包管理器已经安装到本机的内容；
- 如果本机没有，就立即失败，并给出明确的安装提示；
- Git clone 仅保留给 repo acceptance 场景，不把 package manager registry / proxy 当作运行时入口。

## 4.1 Cargo package source（v1 支持范围）

### 支持目标

对 `name + version`：

1. 优先读取 repo 内 `vendor/`；
2. 否则读取 Cargo 已经解包到本机的 registry source；
3. 将目录直接归一化成 `VirtualPackage`；
4. 若本机不存在，提示用户先安装。

### 本地探测顺序

按顺序短路：

1. `<repo>/vendor/<name>/`
2. `<repo>/vendor/<name>-<version>/`
3. `$CARGO_HOME/registry/src/<registry-dir>/<name>-<version>/`
4. 若 `CARGO_HOME` 未设置，则回退 `$HOME/.cargo/registry/src/<registry-dir>/<name>-<version>/`

说明：

- 第 3 / 4 项是 Cargo 在 `cargo fetch` / `cargo build` 后已经解包好的 source tree；
- build 直接读取该目录，不再回头读取 `.crate` archive。

### 缺失时的行为

三处均不存在时，直接失败，例如：

```text
Cargo dependency <name>@<version> is not available locally.
Run `cargo fetch` or `cargo vendor`.
```

### v1 明确禁止

- 读取 Cargo registry index；
- 下载 `.crate`；
- 校验远端 `cksum`；
- 任何 HTTP 请求；
- 把 package@version 自动解释成联网解析。

### v1 明确跳过

- 私有 registry auth；
- git index protocol；
- `latest` / semver range 解析；
- 非 canonical version 自动回退；
- Cargo features matrix 派生的多构型抓取。

## 4.2 Go module source（v1 支持范围）

### 支持目标

对 `module_path + version`：

1. 优先读取 repo 内 `vendor/`；
2. 否则读取 Go 已安装到本机 module cache 的目录；
3. 将目录直接归一化成 `VirtualPackage`；
4. 若本机不存在，提示用户先安装。

### 本地探测顺序

按顺序短路：

1. `<repo>/vendor/<module_path>/`
2. `$GOMODCACHE/<escaped-module-path>@<version>/`
3. 若 `GOMODCACHE` 未设置，则回退 `$GOPATH/pkg/mod/<escaped-module-path>@<version>/`
4. 若 `GOPATH` 未设置，则回退 `$HOME/go/pkg/mod/<escaped-module-path>@<version>/`

说明：

- `vendor/` 对应 `go mod vendor` 场景；
- module cache 路径遵循 Go 的 escaped module path 规则（大写字母编码为 `!x`）；
- build 直接读取解包后的 module source tree，不再读取 `.zip` / `.mod`。

### 缺失时的行为

所有位置均不存在时，直接失败，例如：

```text
Go module <purl> is not available locally.
Run `go mod download` or `go mod vendor`.
```

### v1 明确禁止

- 任何 GOPROXY HTTP 请求；
- 下载 `.mod` / `.zip`；
- 任何网络探测；
- 把 package@version 自动解释成联网解析。

### v1 明确跳过

- `direct` VCS fallback；
- `latest` / branch / commit query；
- 私有 proxy / auth；
- workspace mode / replace 指令重写后的远程解析；
- 复杂 pseudo-version 生成。

## 4.3 Terraform package source（v1 支持范围）

Terraform 依赖分成两类，必须分开处理：

### Providers（二进制插件）

- 事实来源：`.terraform.lock.hcl`
- 已安装路径：
  - workspace-local `.terraform/providers/...`
  - 或用户配置的 shared plugin cache（例如 `TF_PLUGIN_CACHE_DIR` / CLI `plugin_cache_dir`）
- providers 是二进制插件，不是 source tree；build 不尝试解析其二进制内容。
- v1 只要求：
  1. 能确认 provider 已通过 `terraform init` 安装；
  2. 从 lock file 读取 provider identity / version / hashes；
  3. 缺失时提示用户先运行 `terraform init`。

若 `.tf` 中存在 `required_providers` 但 `.terraform.lock.hcl` 不存在，应直接失败：

```text
Terraform providers are not initialized.
Run `terraform init`.
```

### Modules（源码树）

- 本地模块（`source = "./subdir"`）直接按相对路径读取；
- 外部模块在 `terraform init` 后会落到：
  - `.terraform/modules/modules.json`（manifest）
  - `.terraform/modules/<key>/`（实际模块目录）
- build 应优先读取 `modules.json` 获取安装目录，再把模块目录归一化成 `VirtualPackage`；
- 若 `.tf` 中引用了外部模块但 `.terraform/modules/` 不存在，应直接失败：

```text
Terraform modules are not initialized.
Run `terraform init`.
```

### v1 明确禁止

- 访问 Terraform registry API；
- 下载 module archive；
- 下载 provider binary；
- 任何联网解析。

## 4.4 Git repo source（v1 支持范围）

Git source **优先只用于 acceptance**：

- `repo` case 克隆到 `/tmp/cogna-e2e-*`；
- 若 case 指定 `ref`，checkout 到对应 ref；
- 然后走 `LocalWorkspace -> VirtualPackage` 同一路径；
- 不把 git clone 暴露成当前用户主命令面的新日常路径。

### v1 明确跳过

- submodules；
- Git LFS；
- 私有仓库 auth；
- shallow clone 失败后的复杂回退策略。

---

## 5. Extractor 重构目标

## 5.1 从“读磁盘目录”改成“读 readonly package”

当前 extractor 逻辑大量依赖真实路径与 `@fs`。本轮要把 extractor 输入统一改成：

```text
extract(package_view, config) -> declarations
```

而不是：

```text
extract(repo_path, glob_patterns) -> declarations
```

## 5.2 `src/cmd/build/extractor.mbt` 的职责变化

它不再直接面向 repo 文件系统，而是：

1. 从 `SourceSpec` 获取 `VirtualPackage`；
2. 根据 `config.inputs.include_paths` 在 `package_view` 上筛选输入；
3. 把筛选结果交给 language extractor；
4. 产出统一 declarations。

## 5.3 建议新增模块

### 纯核心

```text
src/core/virtual_package/types.mbt
src/core/virtual_package/view.mbt
src/core/virtual_package/normalize.mbt
src/core/virtual_package/archive.mbt
src/core/deps/spdx.mbt
```

### native resolver

```text
src/cmd/build/source/main.mbt
src/cmd/build/source/local.mbt
src/cmd/build/source/cargo.mbt
src/cmd/build/source/gomod.mbt
src/cmd/build/source/terraform.mbt
src/cmd/build/source/git.mbt
src/cmd/build/source/cache.mbt
```

### acceptance harness

```text
src/e2e/extractors/main_test.mbt
src/e2e/extractors/cases.mbt
src/e2e/extractors/runtime.mbt
```

> `e2e/extractors/*.json` 保留为 machine-readable case manifest；真正测试实现仍放 `src/e2e/*`。

---

## 6. Build / Diff / SDK 边界重组

## 6.1 `src/sdk/` 的最终职责

最终 `src/sdk/` 只保留：

- `fetch_packages()`：从当前 workspace 的 `.cogna/sbom.spdx.json` 返回 package tree；
- `query_outlines()`；
- `query()`；
- bundle / diff / query 的 readonly parser / mapper；

### 必删 API

- `src/sdk/build.mbt` public build API
- `src/sdk/diff.mbt` public diff API
- `src/sdk/js.mbt` 中的 `build_js` / `diff_js`
- `src/sdk/moon.pkg` 中的 JS `build` / `diff` exports

## 6.2 `build` 的新职责分层

### 纯层

```text
resolve SourceSpec -> VirtualPackage
extract -> declarations
direct dependency scan -> workspace SPDX JSON model
compose manifest / metadata / checksums / bundle bytes
```

### native command 层

```text
restore cache
probe local installed package-manager paths
emit install guidance when missing
write dist/*
write .cogna/sbom.spdx.json
store cache
```

## 6.3 `diff` 的新职责分层

### 纯层

- compare declarations；
- optional: compare direct dependencies derived from SPDX；
- assemble diff JSON。

### native command 层

- resolve current workspace；
- prepare baseline / target source snapshots；
- 写 `dist/diff.json`。

## 6.4 CLI / Desktop / Node SDK 变化

### CLI

- `cogna build` / `cogna diff` 继续存在，但实现移动到 native command 层；
- `src/cmd/main/main.mbt` 帮助文本明确这两个命令是 native-only。

### Node SDK

公开 API 删除：

- `build`
- `diff`

只保留：

- `fetchPackages`
- `queryOutlines`
- `query`

因此受影响文件包括但不限于：

- `integrations/sdk/node/src/moonbit.ts`
- `integrations/sdk/node/src/index.ts`
- `integrations/sdk/node/src/sdk.test.ts`

### Desktop

Desktop main process 不再通过 `@cogna-dev/sdk` 调 `build/diff`。

新的设计是：

- `sdk:fetch-packages` / `sdk:query-outlines` / `sdk:query` 继续使用 readonly SDK；
- `sdk:build` / `sdk:diff` 改为调用 native CLI（或将来的内嵌 native sidecar），不走 SDK runtime。

---

## 7. Bundle artifact contract 重写

## 7.1 普通 bundle

最终目标：

```text
dist/
├── manifest.json
├── declarations.ndjson
├── metadata.json
├── checksums.txt
└── bundle.ciq.tgz
```

不再包含：

- `symbols.ndjson`
- `software-components.ndjson`
- `sbom.spdx.json`

## 7.2 `.cogna/` 的职责

当前 workspace 的 direct dependency truth 统一收口到：

```text
.cogna/sbom.spdx.json
```

要求：

1. 仅针对当前打开的源码仓库；
2. 不把三方 package 的 SPDX 当作 bundle 交换格式；
3. `fetch_packages()` 只读取这里；
4. 如要做 dependency diff，则在 native diff 里从 base/target SPDX transiently 生成比较输入。

## 7.3 过渡策略

由于当前代码与测试广泛依赖 `software-components.ndjson`，本轮不能一步删光而不留迁移计划。

过渡分两步：

### Step A

- 先把它降级为**命令内部过渡产物**；
- 不再写入 manifest artifact 列表；
- 不再打进 `bundle.ciq.tgz`；
- 不再被 SDK / docs / review 当成 public contract。

### Step B

- diff 改成直接比较 SPDX direct dependencies；
- 所有测试和 docs 切走后，彻底停止生成该文件。

---

## 8. 真实世界 acceptance 设计

## 8.1 case manifest 格式

沿用用户已定义的 `e2e/extractors/rust.json` 风格：

```json
{
  "cases": [
    {
      "extractor": "rust",
      "package": "aws-sdk-dynamodb",
      "version": "1.110.0"
    },
    {
      "extractor": "rust",
      "repo": "https://github.com/awslabs/aws-sdk-rust"
    }
  ]
}
```

在兼容该格式的前提下，允许后续扩展字段：

- `id`
- `prepare`
- `ref`
- `skip`
- `reason`
- `notes`

## 8.2 执行规则

### package + version

- 不触网；
- 只读取包管理器已经安装到本机的内容；
- 运行 acceptance 前，应先准备好本机环境：
  - Rust -> `cargo fetch` 或 `cargo vendor`
  - Go -> `go mod download` 或 `go mod vendor`
  - Terraform -> `terraform init`
- 若 case 缺少本机安装前提，harness 直接失败并给出安装提示；
- 归一化成 `VirtualPackage`；
- 跑 extractor；
- 把声明结果写入 acceptance snapshot。

### repo

- clone 到 `/tmp/cogna-e2e-*`；
- checkout 指定 ref（如有）；
- 作为 `LocalWorkspace` 走同一 extractor pipeline。

## 8.3 snapshot baseline

建议目录：

```text
e2e/extractors/<extractor>/<case-id>/snapshots/cogna/
├── declarations.ndjson
├── manifest.json
├── metadata.json
└── checksums.txt
```

注意：

- acceptance baseline 不引入 `software-components.ndjson`；
- 重点验证“能否正常解析、输出是否稳定、结果是否有效”；
- 失败时区分：
  - resolver failure
  - archive normalization failure
  - extractor parse failure
  - unsupported feature skip

## 8.4 有效性判定

真实世界 acceptance 至少满足：

1. `declarations.ndjson` 非空；
2. 每行均为合法 JSON；
3. 每条 declaration 至少具备：
   - `id`
   - `kind`
   - `symbol`
   - `signature`
4. `manifest.json` 与 `checksums.txt` 自洽；
5. 若 case 被标记 skip，必须在兼容性矩阵记录理由。

---

## 9. `spec/compitable.md` 的职责

新增文件：

```text
spec/compitable.md
```

它不是迁移计划，而是**兼容性矩阵**。

必须记录：

1. source type 支持情况；
2. extractor × source type 支持情况；
3. 哪些 case 已实测通过；
4. 哪些能力被跳过；
5. 跳过原因与后续动作。

记录粒度至少包括：

- LocalWorkspace
- CargoPackage
- GoModule
- TerraformPackage
- GitRepo

以及：

- native build
- native diff
- readonly SDK query/fetch
- acceptance coverage

---

## 10. 分阶段执行计划

## Phase 0 — 先收口 spec 与边界

### 目标

- 冻结本文计划；
- 新建 `spec/compitable.md`；
- 明确 `software-components.ndjson` 将退出 public contract。

### 完成标准

1. `spec/plan.md` 与 `spec/compitable.md` 已写清楚 target architecture；
2. 所有后续实现以此为准，不再回头把 build/diff 塞回 SDK。

## Phase 1 — 建立 `VirtualPackage` 纯核心

### 必做动作

1. 新增 `src/core/virtual_package/*`；
2. 把 local directory -> file map 先实现好；
3. 定义 extractor 读取 `ReadonlyPackageView` 的统一接口；
4. 让现有 local workspace build 先走新接口，但功能保持不变。

### 完成标准

1. local workspace extractor 已不直接依赖裸 `@fs` 遍历 repo；
2. `VirtualPackage` 可稳定表示当前 repo 输入。

## Phase 2 — 落地 native 本地 package discovery

### 必做动作

1. 实现 Cargo vendor + registry src 本地探测；
2. 实现 Go vendor + module cache 本地探测；
3. 实现 Terraform modules/providers 本地探测；
4. 保留 Git clone resolver（先供 acceptance 使用）；
5. 所有缺失场景统一返回明确安装提示，不发起网络请求。

### 完成标准

1. 能把 Cargo package@version 归一化为 `VirtualPackage`；
2. 能把 Go module@version 归一化为 `VirtualPackage`；
3. 能把 Terraform 已安装 module/provider 信息归一化为 build 可读输入；
4. 能把 git repo clone 后归一化为 `VirtualPackage`；
5. 构建路径中不存在 package manager registry / proxy 下载逻辑。

## Phase 3 — 把 build 从 SDK 中移出

### 必做动作

1. 删除 `src/sdk/build.mbt` public API；
2. `src/cmd/build/*` 接管 cache / write / materialize；
3. `src/sdk/moon.pkg` 删除 JS `build` export；
4. Node / Desktop 移除 build SDK 调用。

### 完成标准

1. `src/sdk/` 不再暴露 build API；
2. `cogna build` 仍可用，但实现已是 native command-owned；
3. `rg "build_js|pub fn build\(" src/sdk integrations/sdk/node` 结果只允许命中历史生成物或迁移注释。

## Phase 4 — 把 diff 从 SDK 中移出

### 必做动作

1. 删除 `src/sdk/diff.mbt` public diff API；
2. 把 pure diff compare helper 下沉到 internal core；
3. `src/cmd/diff/*` 接管 source resolution 与文件写出；
4. Node / Desktop 移除 diff SDK 调用。

### 完成标准

1. `src/sdk/` 不再暴露 diff API；
2. `cogna diff` 仍可用且 native-only；
3. Desktop build/diff 改走 native command path。

## Phase 5 — 删除 `software-components.ndjson`

### 必做动作

1. 先从 manifest / bundle 移除该 artifact；
2. `fetch_packages` 与 docs 统一切到 `.cogna/sbom.spdx.json`；
3. diff 若仍需 dependency compare，则改为从 SPDX transient derive；
4. 更新所有 snapshot / examples / tests / docs。

### 完成标准

1. bundle 中不再包含 `software-components.ndjson`；
2. docs / review / snapshot 不再把它当 current truth；
3. `.cogna/sbom.spdx.json` 成为唯一 dependency truth。

## Phase 6 — 落地真实世界 acceptance + 兼容性矩阵

### 必做动作

1. 新增 `src/e2e/extractors/*` harness；
2. 读取 `e2e/extractors/*.json`；
3. package case 走本机已安装 package discovery；
4. repo case 走 git clone；
5. 统一 snapshot compare；
6. 生成 / 更新 `spec/compitable.md`。

### 完成标准

1. 至少 Rust real-world acceptance 跑通；
2. 兼容性矩阵有真实结果，不是空表；
3. skip 项均有明确原因。

---

## 11. 文件级执行清单

## 必改代码文件

- `src/sdk/build.mbt`
- `src/sdk/diff.mbt`
- `src/sdk/js.mbt`
- `src/sdk/moon.pkg`
- `src/cmd/build/main.mbt`
- `src/cmd/build/extractor.mbt`
- `src/cmd/diff/main.mbt`
- `src/core/snapshot/main.mbt`（可复用 path/digest helper，但不得继续承载 resolver 语义漂移）
- `integrations/sdk/node/src/moonbit.ts`
- `integrations/sdk/node/src/index.ts`
- `integrations/sdk/node/src/sdk.test.ts`
- `integrations/desktop/src/main/index.ts`
- `integrations/desktop/src/main/sdk.ts`

## 必改 proto / generated boundary

- `proto/xaclabs/cogna/v1/build.proto`
- `proto/xaclabs/cogna/v1/diff.proto`
- `src/sdk/generated/*.mbt`
- `integrations/sdk/node/src/generated/*.ts`

## 必增文件

- `src/core/virtual_package/*`
- `src/cmd/build/source/*`
- `src/e2e/extractors/*`
- `spec/compitable.md`

## 必审查文档

- `docs/src/content/docs/cli.mdx`
- `docs/src/content/docs/indexing.mdx`
- `docs/src/content/docs/runtime-model.mdx`
- `docs/src/content/docs/providers.mdx`
- `spec/cache.md`
- `spec/review.md`
- `spec/ui.md`
- `spec/desktop.md`

---

## 12. 验证命令

## Phase 1 / 2 后

```bash
moon test --target native src/cmd/build
moon test --target native src/extractors
```

## Phase 3 / 4 后

```bash
moon check --target native src/cmd/build src/cmd/diff
rg "build_js|diff_js|pub fn build\(|pub fn diff\(" src/sdk integrations/sdk/node
pnpm --dir integrations/sdk/node test
pnpm --dir integrations/desktop run typecheck
```

要求：

- `src/sdk/` 不再暴露 build/diff public API；
- Node / Desktop 不再把 build/diff 当 readonly SDK surface。

## Phase 5 后

```bash
rg "software-components.ndjson" src docs spec integrations examples
```

要求：

- 只允许命中历史说明或迁移注释；
- 不允许命中当前 bundle contract、active docs、snapshot baseline。

## Phase 6 后

```bash
moon test --target native src/e2e/extractors
```

要求：

- acceptance harness 能跑；
- `spec/compitable.md` 已更新。

---

## 13. 最终验收标准

以下全部成立，才算本计划完成：

1. 本地目录、本机已安装的 Cargo package / Go module / Terraform module、Git repo 都能统一归一化为 `VirtualPackage`；
2. extractor 统一读取 readonly package view，而不是裸磁盘目录；
3. `build` / `diff` 已完全移出 `src/sdk/` 公共 API；
4. `build` / `diff` 只在 native command 层拥有副作用；
5. Node SDK 只保留 readonly API；
6. Desktop 不再通过 SDK runtime 调 `build/diff`；
7. `software-components.ndjson` 不再是 bundle public contract；
8. `.cogna/sbom.spdx.json` 成为 dependency truth source；
9. `e2e/extractors/*.json` 驱动的真实世界 acceptance 已落地；
10. `spec/compitable.md` 中所有 skip / unsupported 项都有明确记录。

---

## 14. 一句话执行摘要

先把所有 extractor 输入统一成 `VirtualPackage(path -> bytes)`，再让 build 只读取包管理器已经安装到本机的内容，把网络 / cache / 写盘副作用全部赶出 `src/sdk/`，让 `build/diff` 回到 native command 层，同时用真实世界 package/repo acceptance 和兼容性矩阵来验证这套架构是否真的可用。
