#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：当前实现导向的设计说明",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本文不是愿景型 proposal，而是对当前仓库实现的技术设计收口：它以 `src/`、`docs/`、`README.md` 与现有测试为准，描述 CodeIQ 在本地单机场景下如何通过 `codeiq.yml`、CIQ bundle、CIQ diff、OPA policy bundle、Local Registry 与 MCP 服务完成公开声明提取、差异比较、策略检查与上下文查询。文中只陈述已经在仓库中落地的能力，并对 proposal 中仍属未来态或近似表述的部分做显式校正。
  ],
  keywords: (
    "CodeIQ",
    "CIQ",
    "Design",
    "MoonBit",
    "Registry",
    "MCP",
    "SARIF",
    "SBOM",
  ),
  date: "April 13, 2026",
)

= 文档目标与适用范围

本文的目标是为 reviewer 提供一份#strong[当前实现导向]的设计说明。它回答的不是“CodeIQ 未来可能支持什么”，而是：#strong[当前仓库已经如何组织 package boundary、CLI、bundle contract、registry、MCP 与 schema]。

本文刻意遵循以下边界：

- 只描述仓库中已经存在并可从代码/测试证明的行为；
- 对 proposal 中仍属未来态、可选态或表述过宽的部分，明确标成“当前未实现”或“当前仓库内约定”；
- 以本地单机工作流为中心，不把云端 registry、远程服务、CycloneDX 等未完成项写成既成事实。

= 当前仓库架构

== 顶层 package boundary

CodeIQ 当前仓库已经完成 boundary cleanup：#strong[`src/lib/` 只保留更接近可复用库的包]，而与产品语义直接绑定的能力位于 `src/` 顶层业务域。当前更清晰的边界如下：

- #strong[业务域]：`src/extractors/`、`src/policy/`、`src/sbom/`、`src/registry/`、`src/schema/`、`src/config/`、`src/cli/`；
- #strong[命令编排层]：`src/cmd/*`；
- #strong[复用库]：`src/lib/parsec/`、`src/lib/hcl/`、`src/lib/json-schema/`、`src/lib/mcp-sdk/`、`src/lib/registry/` 等；
- #strong[e2e 与 benchmark / scripts]：`src/e2e/` 与 `src/scripts/`。

这一边界意味着：command 层负责入口、参数和流程编排，长期稳定的数据模型、schema、registry protocol、extractor logic 与 SBOM / policy 能力则各归其业务域所有。

== 语言与构建系统

仓库主体使用 #strong[MoonBit] 编写，包边界由 `moon.pkg` 管理，常规开发/验证使用 `moon check`、`moon test` 与必要的原生/wasm target 组合。Typst 仅用于 `spec/` 下的设计与报告文档生成。

= 当前命令面与工作流

== CLI 命令面

当前 `src/cmd/main/main.mbt` 中实现的命令面为：

- `codeiq init`
- `codeiq build`
- `codeiq diff`
- `codeiq check`
- `codeiq query <query-file>`
- `codeiq publish`
- `codeiq registry serve`
- `codeiq registry status`
- `codeiq mcp serve`
- `codeiq mcp status`

需要特别说明的是：proposal 中若出现 `mcp start` 之类表述，当前实现应以 #strong[`mcp serve|status`] 为准。

== 本地工作流

当前 README 与命令实现共同定义的主工作流是：

```text
init -> build -> diff -> check -> query -> publish
```

其中：

- `init` 负责生成本地配置模板；
- `build` 把仓库或 policy source 构建为 bundle；
- `diff` 对比两个已构建 bundle；
- `check` 以 diff + policy bundle 为输入生成 SARIF；
- `query` 从本地 bundle 读取结构化结果；
- `publish` 将 bundle 写入本地 registry store；
- `registry serve|status` 与 `mcp serve|status` 则把同一套本地产物通过 HTTP service 暴露给自动化与 AI 调用方。

= 配置模型

== 配置文件名与解析优先级

当前实现的默认配置文件名是 #strong[`codeiq.yml`]。`init` 默认输出 `./codeiq.yml`，而运行时解析逻辑会：

- 优先查找 `codeiq.yml`；
- 若不存在，再回退到 `codeiq.yaml`；
- 若两者都不存在，则报“tried codeiq.yml, codeiq.yaml”。

因此，设计文档中应将 #strong[`codeiq.yml` 视为当前主文件名]，同时保留 `codeiq.yaml` 作为兼容回退路径，而不是把两者写成完全等价的默认推荐名。

== 当前配置 schema 与字段

`init` 生成的默认模板采用：

```yaml
schemaVersion: ciq-config/v2
profile: openapi-spec
validation: none
purl: pkg:openapi/acme/payment-api@2026.03.01
source:
  repo: https://github.com/acme/payment-api
  ref: main
inputs:
  include:
    - openapi/**/*.yaml
checks:
  format: sarif
  policy: ./dist/policy.ciq.tgz
diff:
  includeTestChanges: false
sbom:
  format: spdx
  dependencyBundles: true
  requireLocalPackages: true
publish:
  includeDependencies: true
registry:
  port: 8787
  storeDir: .codeiq/cache/registry
mcp:
  port: 3000
```

当前 `Config` 模型包含以下顶层字段：

- `schema_version`
- `profile`
- `validation`
- `purl`
- `source`
- `inputs`
- `checks`
- `diff`
- `sbom`
- `publish`
- `registry`
- `mcp`

其中值得 reviewer 特别关注的实现性字段有：

- `diff.includeTestChanges`
- `sbom.dependencyBundles`
- `sbom.requireLocalPackages`
- `publish.includeDependencies`
- `registry.storeDir`

这些字段都已进入当前实现路径，而不是 proposal 中仅作方向性占位的设置。

== Profile 集合

当前 schema/实现使用的 profile 集合包括：

- `go-module`
- `rust-crate`
- `terraform-module`
- `openapi-spec`
- `policy-bundle`

其中 `policy-bundle` 是#strong[一等 profile]，而不是“普通 bundle 外加一些附属文件”的临时变体。

= 构建产物与 CIQ Bundle

== 常规 bundle 产物

`build` 对普通代码/规格仓库构建后，当前标准输出位于 `dist/`，核心文件为：

```text
dist/
├── manifest.json
├── declarations.ndjson
├── symbols.ndjson
├── software-components.ndjson
├── sbom.spdx.json
├── metadata.json
├── checksums.txt
└── bundle.ciq.tgz
```

当前实现中，`bundle.ciq.tgz` 是最终归档文件名；registry 内部也围绕 `.ciq.tgz` 后缀与 `bundleId` 进行存储和下载。

proposal 中若把产物写成 `pkg:cargo/tokio@1.43.0.ciq.tgz` 这样的语义文件名，应理解为#strong[可读示例]，不是当前命令落地时的标准输出文件名。当前落地文件名是 `dist/bundle.ciq.tgz`。

== SPDX-first，而非当前已支持 CycloneDX

虽然 proposal 中可能同时展示 `sbom.cdx.json` 与 `sbom.spdx.json`，当前实现和测试可证明的稳定输出是：#strong[`sbom.spdx.json`]。

因此当前设计文档应写成：

- CodeIQ 当前已实现 #strong[SPDX JSON] 输出；
- `software-components.ndjson` 是导出 SPDX 与组件事实的重要中间产物；
- CycloneDX 不应被写成当前默认已实现的标准产物。

== metadata / checksums / signature provenance

当前 `metadata.json` 包含构建状态、extractor role/backend、timing/statistics 等信息；`checksums.txt` 则对 bundle 内部主要文件给出 SHA-256 摘要。对 policy bundle，manifest/provenance 还会携带 runtime signature metadata。

也就是说，CodeIQ 当前 bundle contract 不只是“若干 ndjson 文件的 tarball”，而是一组面向发布、审计、下载和本地缓存的一致性产物集合。

== CIQ OPA Bundle

当 `profile == policy-bundle` 时，`build` 输出的是：

- `schemaVersion: ciq-opa-bundle/v1`
- `profile: policy-bundle`
- 附加产物：
  - `opa-bundle.tar.gz`
  - `policy.rules.json`

因此设计文档应把 `CIQ OPA Bundle` 明确描述为一类独立 manifest/schema 的 bundle，而不是“普通 bundle 中附带 OPA 文件”的非正式扩展。

= 声明模型与 Schema

== 当前 declaration schema 的核心结论

当前 `declarations.ndjson` 并非只保留原始签名；它已经稳定围绕：

- `signature`
- `shape`
- `language_specific`

三个层次组织。`build` 生成的 manifest 中，`declarationSchema.model` 明确写为：

```text
signature + shape + language_specific tagged union
```

== `shape` 已经是当前实现的一部分

proposal 中如果把 `shape` 描述成“尚待未来设计”的 reserved placeholder，当前实现已不再适用。当前 schema 已要求 `shape` 至少包含：

- `kind`
- `subkind`
- `form`
- `signature`
- 可选：`owner`
- 可选：`type_params`
- 可选：`parameters`
- 可选：`returns`

这意味着 `shape` 已直接参与：

- declaration 序列化；
- query 结果透传；
- diff 的 semantic / shape 差异判断；
- reviewer 对跨语言 API shape 的比较。

== `language_specific` 是具体模型，不只是文档示意

当前 `language_specific` 也已经是具体 schema，而不只是示意性的 tagged union 示例。它至少要求：

- `profile`
- `server`

并可按 profile 携带：

- `go`
- `rust`
- `terraform`
- `openapi`
- `providers`

这使得 Go receiver、Rust extern ABI、Terraform provider/dependsOn、OpenAPI operation/status/media types 等细节都已可被当前实现保真表达。

== 关系与定位信息

当前 declaration schema 同时要求：

- `source_refs`
- `relations`
- `location`
- `baselineRole`

其中 `relations` 集合已覆盖 `declared_in`、`contains`、`has_member`、`has_parameter`、`returns`、`references_type`、`implements`、`uses_provider`、`provided_by` 等稳定关系类型。这说明 CodeIQ 当前并非只做“静态字符串索引”，而是在统一 schema 上保留了足够供 diff/query/check 消费的结构化关系层。

= Diff、Check 与 Query

== CIQ Diff

`diff` 当前从：

- `repo/dist/base`
- `repo/dist/target`

读取两份已构建 bundle 产物，输出：

- `dist/diff.json`
- `schemaVersion: ciq-diff/v1`

当前 diff 结果至少包含：

- `basePurl`
- `targetPurl`
- `summary`
- `changes[]`

且 `changes[]` 的单项不仅有 `kind/id/path/level`，还可能携带：

- `before`
- `after`
- `beforeRecord`
- `afterRecord`
- `semanticDiff`
- `componentDiff`

若 `includeTestChanges` 打开，还会进一步附加：

- `includeTestChanges: true`
- `testSummary`
- `testChanges`

因此 proposal 若只把 CIQ Diff 描述为“added/removed/changed 的简化集合”，会低估当前实现已经落地的数据丰富度。

== Check 与 SARIF

`check` 当前接收：

- 一个 `ciq-diff/v1` 文件；
- 一个 policy bundle 路径；

并执行：

- `opa eval --bundle ... --input ... data.codeiq.compat.deny`

最终输出：

- `check.sarif.json`

当前实现还会把 diff 规范化为 OPA 更容易消费的 envelope，并将 policy 结果和 diff 自带变化一起汇总成 SARIF 结果。SARIF 生成后还会经过最小 `SARIF 2.1.0` schema 校验。

== Query 与 Result

`query` 当前读取一个 `ciq-query/v1` 文件，基于本地 `dist/` 下的 ndjson 产物进行匹配，然后输出：

- `<query>.result.json`
- `schemaVersion: ciq-result/v1`

查询输入至少包含：

- `purl`
- `selector.path`

并可附带：

- `selector.kind`
- `repo`
- `intent`

结果 `matches` 中会透传 declaration 的关键字段，包括 `shape` 与 `language_specific`。因此当前 query 已经不是模糊文本检索，而是对统一 declaration record 的结构化选择和回传。

= Registry 设计

== Local-only store 与 descriptor

CodeIQ 当前 registry 是本地优先、单机缓存模型。默认 store root 为：

```text
.codeiq/cache/registry
```

服务启动时会写出：

- `dist/registry-server.json`

descriptor 至少包含：

- `schemaVersion: codeiq-registry-descriptor/v1`
- `name: codeiq-registry`
- `transport: http`
- `port`
- `baseUrl`
- `healthUrl`

== HTTP API

当前 registry server 路由为：

- `GET /health`
- `POST /api/v1/bundles`
- `GET /api/v1/packages/{purl}/versions`
- `GET /api/v1/bundles/{bundleId}`
- `GET /api/v1/bundles/{bundleId}/download`
- `GET /api/v1/bundles/resolve?purl=...`

其中 `resolve` 路由在当前实现中已承担重要职责：它不仅返回 bundle metadata，还配合 `If-None-Match` / `ETag` 完成 304 not-modified 语义。

== bundleId、downloadUrl 与 ETag

当前 registry 的主键不是“以 PURL 直接作为文件名”的简单模型，而是：

- 使用 `bundleId` 标识存储对象；
- bundle 文件存于 `bundles/<bundleId>.ciq.tgz`；
- 通过 `downloadUrl` 暴露下载位置；
- 通过 `ETag` 和 `If-None-Match` 支持缓存协商；
- publish receipt / download response / bundle detail response 都围绕这些字段建模。

在本地模式下，`downloadUrl` 常表现为：

```text
local://<store-path>
```

对 HTTP server 入口，则会改写成 server-visible `/api/v1/bundles/{bundleId}/download` URL。

= MCP 设计

== 当前 MCP 服务边界

CodeIQ 当前 MCP 服务是本地查询代理，而不是构建或发布代理。它的职责是：

- 读取本地 bundle / registry；
- 在需要时按 PURL 物化本地 repo cache；
- 通过 MCP tool surface 向 AI 提供结构化上下文。

服务启动会写出：

- `dist/mcp-server.json`

descriptor 至少包含：

- `schemaVersion: codeiq-mcp-descriptor/v1`
- `protocolVersion: 2025-11-25`
- `transport: http`
- `baseUrl`
- `rpcUrl`
- `healthUrl`
- `initializeResult`
- `tools`

== 传输与端点

当前 `mcp serve` 实现使用 HTTP transport，并暴露：

- `/health`
- `/rpc`

RPC 处理委托给 `mcp-sdk` 的标准 request handler，与当前 descriptor/initialize/tool state 同步逻辑一致。

== 当前工具面

当前 `tool_definitions()` 注册了三个工具：

- `codeiq.query.outlines`
- `codeiq.query.symbol`
- `codeiq.runtime.context`

其中：

- `codeiq.query.outlines` 支持 `purl`、`limit`、`cursor`；
- `codeiq.query.symbol` 支持 `purl`、`selector`、`kind`、`intent`；
- `codeiq.runtime.context` 返回 MCP runtime request snapshot。

因此若 proposal 中只覆盖前两个工具，设计文档也应补上当前已经实现的 `codeiq.runtime.context`。

= Extractors、Profiles 与 PURL 约定

== 当前 extractor 覆盖范围

当前仓库已落地的 extractor/profile 覆盖至少包括：

- Go (`go-module`)
- Rust (`rust-crate`)
- Terraform (`terraform-module`)
- OpenAPI (`openapi-spec`)
- Policy (`policy-bundle`)

在 build/extractor orchestration 中，不同 profile 会映射到当前 extractor mode / server：

- Go: `gopls`
- Rust: `rust-analyzer`
- Terraform: `hcl-parser`
- OpenAPI: `none`（parser-only）
- Policy: `opa`

== 当前 PURL 写法

仓库当前广泛使用如下 PURL 风格：

- `pkg:golang/...`
- `pkg:cargo/...`
- `pkg:terraform/...`
- `pkg:openapi/...`
- 必要时回退到 `pkg:generic/...`

需要强调的是：在设计说明中，应将 `terraform` 与 `openapi` 这类类型表述为#strong[当前仓库/文档中的工作约定]，而不是无条件宣称它们已经是所有外部工具都可直接接受的正式标准类型。若要谈互操作性，应同时说明：某些路径仍可能回退到 `pkg:generic/...`。

= 当前限制与对 proposal 的校正

本文建议 reviewer 把以下几类 proposal 表述统一校正为实现导向版本：

- #strong[命令名校正]：使用 `mcp serve|status`，不要写 `mcp start`；
- #strong[配置校正]：默认配置文件名写 `codeiq.yml`，同时注明 `codeiq.yaml` fallback；默认模板 schemaVersion 应写 `ciq-config/v2`；
- #strong[SBOM 校正]：当前实现写 `sbom.spdx.json`，不要把 CycloneDX 写成默认已产出文件；
- #strong[声明模型校正]：`shape` 与 `language_specific` 已是当前 schema 的正式组成；
- #strong[registry 校正]：强调 `bundleId` / `downloadUrl` / `ETag` / `If-None-Match` 语义，而不是只写一个抽象“本地存储目录”；
- #strong[MCP 校正]：把第三个已实现工具 `codeiq.runtime.context` 纳入工具面；
- #strong[PURL 校正]：把 `pkg:terraform` / `pkg:openapi` 写成当前仓库约定，而不是过度外推到标准化事实。

= 一句话结论

CodeIQ 当前已经不是“只停留在 proposal 阶段的声明治理设想”，而是一个#strong[本地单机、配置驱动、bundle-first]的实现体系：它以 `codeiq.yml` 和 MoonBit command orchestration 为入口，以 `signature + shape + language_specific` declaration model 为事实层，以 `diff -> check -> SARIF` 为治理链路，以 Local Registry 与 MCP 为上下文分发接口。设计文档的任务不是继续拔高愿景，而是把这些已经落地的 contract 准确写清楚。
