# Cogna MCP Tool 设计（标准 MCP / HTTP-SSE）

本文定义 Cogna 在标准 MCP（Model Context Protocol）下对外暴露的 **tool contract**。

目标不是继续暴露当前仓库里遗留的内部概念（例如 bundle、purl、selector query 的细粒度内部接口），而是让 MCP tool 尽可能向 `spec/api.md` 中已经冻结的用户侧 API 靠拢。

换句话说：

- `spec/api.md` 定义产品 API
- `spec/mcp.md` 定义这些产品 API 如何映射成 MCP tools

当前阶段，MCP server 已切到标准 `streamable-http` 传输，endpoint 为 `/mcp`。下一步重点不再是 transport，而是 **tool surface 收口**。

---

## 1. 设计目标

### 1.1 MCP tools 应直接对应产品能力

MCP 层不应再优先暴露内部机制型工具，例如：

- `query by purl`
- `query by selector`
- `runtime context`
- bundle / registry / materialize / internal SQL 的细节

MCP 面在设计上仍参考产品侧的 5 个用户接口：

1. `Build`
2. `Diff`
3. `FetchPackages`
4. `QueryOutlines`
5. `Query`

但当前阶段更现实的收口方式是：

- MCP 主工具面优先保留查询类能力：`fetch_packages`、`query_outlines`、`query`
- `Build`、`Diff` 暂不作为推荐 MCP tool 主能力
- 需要构建或对比时，引导用户优先使用 CLI：`cogna build` / `cogna diff`

### 1.2 不泄露 bundle / purl / internal query model

根据 `spec/api.md`：

- 用户不应感知 bundle
- 用户不应显式传 `purl`
- 查询应以“当前项目上下文 + 包名”为主

所以 MCP tool 输入中：

- 不应要求 `purl`
- 不应要求 `bundle_id` / `bundle_path`
- 不应要求 selector query 的内部编码方式作为主入口

### 1.3 MCP tools 既要给 LLM 看，也要给程序看

基于标准 MCP tool 设计建议：

- tool 名称应稳定、面向产品能力
- 输入 schema 要清晰、最小化、AI-friendly
- 输出要兼顾人类可读和程序可消费

当前 `cogna-dev/mcp-sdk` 的 `ToolResult` 主要依赖 `content[]` 返回，因此建议统一采用：

1. 第一条 `text`：简短摘要（便于 LLM 理解）
2. 第二条 `text`：完整 JSON payload（便于程序和 agent 二次解析）

后续如果 SDK 支持更强的 structured content，再迁移；当前阶段先保持一致约定。

---

## 2. 标准 MCP Server 约束

### 2.1 Transport

- `transport`: `streamable-http`
- `baseUrl`: `http://127.0.0.1:<port>`
- `mcpUrl`: `http://127.0.0.1:<port>/mcp`

### 2.2 Server Instructions

Server-level instructions 应引导 agent 使用产品接口，而不是内部概念。例如：

- 若当前项目上下文尚未准备好，先引导用户使用 CLI 执行 `cogna build`
- 使用 `fetch_packages` 获取当前项目相关包列表
- 使用 `query_outlines` 做浏览
- 使用 `query` 做精确或模糊检索
- 若需要比较基线差异，引导用户使用 CLI 执行 `cogna diff`

### 2.3 Tool Naming

采用小写 snake_case，直接使用产品 API 名：

- `fetch_packages`
- `query_outlines`
- `query`
- （可选过渡）`build`
- （可选过渡）`diff`

原因：

- 与 `spec/api.md` 一致
- 避免再发明 `cogna.query.symbol` 这类偏内部的命名
- 对 agent 来说更容易建立稳定心智模型

---

## 3. 当前项目隐式上下文

所有 MCP tools 都隐含“当前项目上下文”。

tool 调用时应默认完成这些事：

1. 解析当前项目路径（通常就是当前工作目录）
2. 读取 `cogna.yml`
3. 读取或刷新 `.cogna/sbom.spdx.json`
4. 基于当前项目上下文执行对应操作

因此：

- `build` 无显式业务参数
- `fetch_packages` 无显式业务参数
- `query_outlines` 只需要 `package`
- `query` 只需要 `package + query pattern`
- `diff` 只需要比较范围

---

## 4. MCP Tool 总览

| Tool | 输入 | 输出 payload | 作用 |
|------|------|--------------|------|
| `fetch_packages` | `{}` | `FetchPackagesOutput` | 返回当前项目相关包树 |
| `query_outlines` | `QueryOutlinesInput` | `QueryOutlinesOutput` | 浏览某个包的公开 API 大纲 |
| `query` | `QueryInput` | `QueryOutput` | 对某个包做精确或模糊检索 |
| `build` | `{}` | guidance-only / optional | 当前阶段更建议引导用户使用 CLI |
| `diff` | `DiffInput` | guidance-only / optional | 当前阶段更建议引导用户使用 CLI |

---

## 5. Tool 详细定义

## 5.1 `build`（暂不推荐作为 MCP 主工具）

### 目标

建立当前项目的可查询上下文。

但当前阶段更推荐通过 CLI 执行：

- `cogna build`

### 输入

```json
{}
```

### 输出 payload

```json
{
  "success": true
}
```

### MCP 摘要文本建议

- 当前阶段更推荐：`Build is not yet exposed as a stable MCP workflow. Please run cogna build in the CLI first.`
- 若未来接通：`Build completed successfully for the current project.`

### 说明

- 不返回 bundle 路径
- 不返回 purl
- 不返回内部索引路径

---

## 5.2 `diff`（暂不推荐作为 MCP 主工具）

### 目标

比较当前项目与给定基线之间的公开 API 差异。

但当前阶段更推荐通过 CLI 执行：

- `cogna diff`

### 输入

```json
{
  "base": "v1.1.0",
  "target": "working-tree",
  "include_test_changes": true
}
```

### 字段

| 字段 | 类型 | 必填 | 含义 |
|------|------|------|------|
| `base` | `string?` | 否 | 基线版本 / tag / commit / alias |
| `target` | `string?` | 否 | 目标版本，默认当前工作区 |
| `include_test_changes` | `bool?` | 否 | 是否纳入测试变化 |

### 输出 payload

```json
{
  "summary": {
    "added": 3,
    "removed": 0,
    "changed": 2,
    "deprecated": 1
  },
  "changes": [],
  "test_changes": []
}
```

### MCP 摘要文本建议

当前阶段若仍暴露该 tool，应优先返回 guidance：

`Diff is not yet exposed as a stable MCP workflow. Please run cogna diff in the CLI.`

### 说明

- 不暴露 bundle locator
- 不暴露内部 materialization 路径

---

## 5.3 `fetch_packages`

### 目标

返回当前项目相关的包浏览树。

### 输入

```json
{}
```

### 输出 payload

```json
{
  "root": {
    "name": "my-app",
    "version": "0.1.0",
    "ecosystem": "workspace",
    "relation": "root",
    "summary": null,
    "children": []
  }
}
```

### 摘要文本建议

`Fetched package tree for the current project.`

### 说明

- 数据来源应优先走 `.cogna/sbom.spdx.json`
- 若缓存不可用，可回退到当前已有的 `dist/` 产物，但这应视为过渡行为
- 不要求显式传 package / purl

---

## 5.4 `query_outlines`

### 目标

给定一个包名，返回该包的公开 API 大纲。

### 输入

```json
{
  "package": "tokio"
}
```

### 字段

| 字段 | 类型 | 必填 | 含义 |
|------|------|------|------|
| `package` | `string` | 是 | 包名，来自 `fetch_packages` |

### 输出 payload

```json
{
  "package": "tokio",
  "outlines": [
    {
      "id": "decl:rust:tokio::sync::Mutex::lock",
      "symbol": "tokio::sync::Mutex::lock",
      "kind": "function",
      "summary": "Acquire the mutex asynchronously",
      "deprecated": false,
      "location": {
        "uri": "src/sync/mutex.rs",
        "start_line": 120,
        "end_line": 134
      }
    }
  ]
}
```

### 摘要文本建议

`Returned 24 public API outlines for package tokio.`

### 说明

- 输入是 `package`，不是 `purl`
- 这是浏览型 API，不做模糊查询

---

## 5.5 `query`

### 目标

对某个包进行统一查询，支持：

1. 按 `exact_id` 精确命中
2. 按 `exact_symbol` 精确命中
3. 按 `text` 模糊检索

### 输入

```json
{
  "package": "react",
  "text": "effect cleanup",
  "limit": 10
}
```

### 字段

| 字段 | 类型 | 必填 | 含义 |
|------|------|------|------|
| `package` | `string` | 是 | 包名 |
| `exact_id` | `string?` | 否 | 按稳定 ID 精确查询 |
| `exact_symbol` | `string?` | 否 | 按 symbol 精确查询 |
| `text` | `string?` | 否 | 文本模糊检索 |
| `limit` | `int?` | 否 | 返回条数限制 |
| `cursor` | `string?` | 否 | 分页游标 |

### 约束

- `package` 必填
- `exact_id` / `exact_symbol` / `text` 必须且只能提供一个

### 输出 payload

```json
{
  "package": "react",
  "mode": "fuzzy-text",
  "matches": [
    {
      "id": "decl:npm:react:useEffect",
      "symbol": "useEffect",
      "kind": "function",
      "signature": "useEffect(setup, deps?)",
      "summary": "Synchronize a component with an external system",
      "docs": "When your effect returns a function, React will run it as cleanup...",
      "score": 0.97
    }
  ],
  "cursor": null
}
```

### 摘要文本建议

- 精确查询：`Resolved exact query for package react with 1 match.`
- 模糊查询：`Returned 10 matches for fuzzy query in package react.`

---

## 6. 结果封装约定

当前 `cogna-dev/mcp-sdk` 的 `ToolResult` 以 `content[]` 为核心，因此统一采用：

### 成功结果

`ToolResult::ok([...])`，包含两段 `text`：

1. 第一段：简要自然语言摘要
2. 第二段：完整 JSON payload 字符串

示意：

```json
{
  "content": [
    {
      "type": "text",
      "text": "Fetched package tree for the current project."
    },
    {
      "type": "text",
      "text": "{\"root\":{...}}"
    }
  ]
}
```

### 错误结果

使用：

```text
ToolResult::error("...")
```

错误文本要求：

- 对用户可理解
- 不暴露内部 bundle/purl/SQL 细节，除非确实是定位问题必须信息

---

## 7. 与当前实现的差异

当前 MCP 实现仍有如下遗留：

- tool 名称是 `cogna.query.outlines` / `cogna.query.symbol`
- 仍要求 `purl`
- `symbol` 工具实质上更接近旧的 selector query
- 存在 `runtime.context` 这类调试型工具

标准化后当前主工具面应改为：

- `fetch_packages`
- `query_outlines`
- `query`
- `build` / `diff` 仅作为过渡或 guidance 型能力

并且：

- `query_outlines` 输入改成 `package`
- `query` 输入改成 `package + exact_id/exact_symbol/text`
- `runtime.context` 从用户侧 tool surface 移除

---

## 8. 分阶段落地建议

### Stage 1：MCP tool surface 收口

先完成以下动作：

1. 主工具面收口为 `fetch_packages` / `query_outlines` / `query`
2. `build` / `diff` 若保留，则只返回 CLI guidance 或明确标注为过渡能力
3. 输入 schema 改成对齐 `spec/api.md`
4. 删除 `runtime.context`
5. 输出 payload 对齐 SDK JSON shape

### Stage 2：与 SDK / core 真正对齐

在 tool surface 定住后继续做：

1. `fetch_packages()` 改为优先读取 `.cogna/sbom.spdx.json`
2. `core.build()` / `core.diff()` 若要进入 MCP，再补成真实实现

### Stage 3：统一 contract 来源

最终目标：

- `spec/api.md` 是产品 API 真相源
- `spec/mcp.md` 是 MCP 映射真相源
- `src/sdk/*` 与 `src/cmd/mcp/core/*` 都只是在消费同一套 contract

---

## 9. 当前结论

MCP 层的正确方向不是继续堆叠内部查询工具，而是把它收口成产品 API 导向的查询能力，并对尚未成熟的构建/对比能力给出清晰 CLI 引导。

因此当前阶段的标准化结论是：

- **保留标准 MCP transport**
- **当前 MCP 主工具面优先收口为查询类 tools**
- **Build / Diff 暂时通过 CLI 引导暴露**
- **输入输出尽量与 SDK / public API contract 一致**
- **bundle / purl / selector / runtime context 等内部细节退出用户侧 MCP 主叙事**
