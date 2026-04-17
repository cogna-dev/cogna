#import "@preview/arkheion:0.1.1": arkheion
#import "@preview/fletcher:0.5.8": diagram, node, edge

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "Cogna: 项目申报书",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    Cogna 是一个面向第三方库与 API 的声明级代码索引和变更治理工具。它从 Go、Rust、Terraform Module 和 OpenAPI 规格中提取公开接口与契约，构建可发布的 `CIQ Bundle`，并通过 diff + check 识别破坏性变更，输出 SARIF 格式的结果，接入现有 CI 与代码审查流程。相较于依赖文档检索或通用代码导航的方案，Cogna 聚焦“公开声明”这一更稳定的事实层，并结合单机 Local Registry、CIQ OPA Bundle、本地 SBOM 产物和本地 MCP Agent，为开发者和 AI 提供可追溯、版本绑定、可复用的上下文基础设施。
  ],
  keywords: ("Cogna", "CIQ", "SARIF", "OPA", "Registry", "MCP", "Go", "Rust", "Terraform", "OpenAPI"),
  date: "March 19, 2026",
)

= 项目目标与应用场景

Cogna 的目标不是做一个新的 linter，也不是替代 LSP/IDE 导航，而是构建一个#strong[面向库公开接口（声明）]的事实提取与变更治理系统。它解决的是这样一类问题：当开发者或 AI 代理面对第三方库升级、SDK 发版、Terraform Module 变更、OpenAPI 规格更新时，现有工具往往只能提供文本检索、通用静态分析或实现级告警，却无法稳定回答“这个产物对外承诺了什么”“两个版本之间哪些公开声明发生了变化”“这些变化是否违反组织的兼容性策略”“结果能否接入现有审查与报告工具链”。

首期明确支持范围如下：

- #strong[Go]：Go module 的导出函数、类型、常量、接口、包级符号。
- #strong[Rust]：Rust crate 的 public item、trait、type、module、feature 相关声明。
- #strong[Terraform Module]：变量、输出、provider 约束、module 输入输出契约。
- #strong[OpenAPI（Swagger）Specification]：path、operation、schema、parameter、response 等 API 合约声明。

本项目不把 README、示例项目或外部文档作为输入。#strong[所有事实都仅从代码与规格文件本体中提取]，以减少因文档过时而带来的信息偏差。

项目定位因此可以概括为：#strong[一个面向库公开接口的上下文检索与变更审查工具]。它提供的不是泛文档片段，而是带版本、带位置、带唯一标识的声明级证据。

= 交付物说明

== 拟支持的核心功能与功能边界（Scope）

Cogna 的功能边界必须和 lint 工具明确区分。lint 面向代码实现逻辑、风格和潜在缺陷；Cogna 面向库的#strong[公开接口、契约与差异]。也就是说，Cogna 不做控制流、数据流、漏洞利用链与编码风格判断，只回答“这个库对外暴露了什么”以及“它变了什么”。

#table(
  columns: (1.5fr, 2fr, 2.7fr),
  inset: 6pt,
  stroke: 0.4pt,
  [*维度*], [*传统 lint / 静态检查*], [*Cogna*],
  [分析对象], [实现逻辑、风格、局部缺陷], [公开接口、声明、版本差异、产物契约],
  [输入], [源码文件、AST、CFG], [代码仓库中的声明与规格文件],
  [输出], [warning / error], [CIQ Bundle / CIQ Diff / SARIF / CIQ Result],
  [典型问题], [是否有未使用变量、空指针风险], [是否删除了公开 API、破坏了模块输出契约、改变了对外声明形状],
  [适用对象], [应用开发与实现质量], [库开发、依赖治理、平台门禁、AI 查询],
)

从用户视角看，Cogna 首期提供以下核心能力：

- #strong[把仓库构建成可复用上下文资产]：用户可以把 Go、Rust、Terraform Module 与 OpenAPI 仓库构建成标准化的 `CIQ Bundle`，供团队、CI 和 AI 工具复用。
- #strong[比较两个版本到底变了什么]：用户可以对两个版本执行 `diff`，直接看到公开接口、输入输出契约和 API schema 的变化，而不是自己手工对比文本。
- #strong[在发布前检查变更是否合规]：用户可以把 `CIQ Diff` 与 `CIQ OPA Bundle` 一起输入 `check`，确认这次代码变更是否满足组织 policy，并得到 SARIF 结果。
- #strong[把热点依赖和规则沉淀到共享本地工作流里]：用户可以把 `CIQ Bundle` 与 `CIQ OPA Bundle` 发布到单机 `Local Registry`，让 CLI、MCP 与本地自动化复用同一套 bundle cache。
- #strong[在 AI 工具中直接查询依赖和接口]：用户可以通过本地 CLI 或 `Cogna MCP Agent` 查询声明、签名、注释与契约信息，减少 AI 对外部文档搜索的依赖。
- #strong[用统一方式治理代码与配置变更]：用户可以对代码语言和配置语言采用一致的工作流，统一管理接口变化、策略门禁和上下文分发。

== 输入输出定义与 CIQ 格式

本项目围绕五个直接产生或消费标准化产物的核心命令组织；此外，还提供 `publish` 用于把 bundle 写入单机 `Local Registry`，提供 `mcp start` 用于启动本地查询代理。五个核心命令的输入输出如下：

#table(
  columns: (1.2fr, 2fr, 2fr),
  inset: 6pt,
  stroke: 0.4pt,
  [*命令*], [*输入*], [*输出*],
  [`init`], [无], [`CIQ Config`],
  [`build`], [代码仓库或策略仓库], [`CIQ Bundle` 或 `CIQ OPA Bundle`],
  [`diff`], [代码仓库], [`CIQ Diff`],
  [`check`], [`CIQ Diff`
+ 本地 `CIQ OPA Bundle`], [`SARIF`],
  [`query`], [本地 `CIQ Bundle`
+ `CIQ Query`], [`CIQ Result`],
)

其中，`check` 的目标需要明确说明：#strong[它不是单纯检查某个静态产物，而是检查这次代码变更对应的 `CIQ Diff` 是否符合本地 `CIQ OPA Bundle` 中定义的 policy 要求]，并最终输出 SARIF，供 CI、代码审查与质量平台消费。

其中，#strong[PURL] 是所有包与规格对象的唯一标识。PURL 的核心结构为：

```text
pkg:type/namespace/name@version?qualifiers#subpath
```

在 Cogna 中，典型标识示例如下：

```text
pkg:golang/github.com/gin-gonic/gin@1.10.0
pkg:cargo/tokio@1.43.0
pkg:terraform/hashicorp/terraform-aws-vpc@5.18.1
pkg:openapi/acme/payment-api@2026.03.01
```

=== CIQ Config

`init` 生成 `cogna.yaml`，用于定义项目坐标、抽取 profile、入口与策略配置。其目标是让使用者明确告诉系统“这个仓库在什么生态中、哪些文件定义了公开接口、应使用何种检查策略”。

```yaml
schemaVersion: ciq-config/v1
profile: openapi-spec
purl: pkg:openapi/acme/payment-api@2026.03.01
source:
  repo: https://github.com/acme/payment-api
  ref: main
inputs:
  include:
    - openapi/**/*.yaml
checks:
  format: sarif
  policy: default-compat
```

`CIQ Config` 的关键字段为：

- #strong[`schemaVersion`]：配置 schema 版本。
- #strong[`profile`]：固定取值于 `go-module`、`rust-crate`、`terraform-module`、`openapi-spec`。
- #strong[`purl`]：当前仓库或产物的唯一标识。
- #strong[`source`]：源码仓库、分支、commit/tag 等来源信息。
- #strong[`inputs`]：仅允许代码与规格文件路径，不允许 README、示例目录。
- #strong[`checks`]：输出格式、策略模板、门禁级别等设置。

=== CIQ Bundle

`build` 输入一个代码仓库与其 `CIQ Config`，输出 `CIQ Bundle`。`CIQ Bundle` 是声明事实的快照，而不是导航索引。其封装目标是便于发布、缓存、差异比较和查询。

```text
pkg:cargo/tokio@1.43.0.ciq.tgz
├── manifest.json
├── declarations.ndjson
├── symbols.ndjson
├── software-components.ndjson
├── sbom.cdx.json
├── sbom.spdx.json
├── metadata.json
└── checksums.txt
```

#table(
  columns: (1.5fr, 1.4fr, 3fr),
  inset: 6pt,
  stroke: 0.4pt,
  [*文件*], [*格式*], [*用途*],
  [`manifest.json`], [JSON], [描述 bundle 元数据、PURL、profile、输入文件摘要与产物列表],
  [`declarations.ndjson`], [NDJSON], [逐行记录结构化声明信息：原始签名 + 待演进的抽象 shape + 语言特化 tagged union],
  [`symbols.ndjson`], [NDJSON], [索引声明到逻辑名、路径、父级作用域、唯一 ID],
  [`software-components.ndjson`], [NDJSON], [逐行记录源码文件与包管理器解析出的标准化 software component facts],
  [`sbom.cdx.json`], [JSON], [由 component facts 导出的 CycloneDX SBOM],
  [`sbom.spdx.json`], [JSON-LD], [由 component facts 导出的 SPDX SBOM],
  [`metadata.json`], [JSON], [构建时间、工具版本、语言统计、输入文件列表与摘要],
  [`checksums.txt`], [文本], [bundle 内每个文件的 SHA-256 摘要],
)

`manifest.json` 的建议格式如下：

```json
{
  "schemaVersion": "ciq-bundle/v1",
  "purl": "pkg:cargo/tokio@1.43.0",
  "profile": "rust-crate",
  "source": {
    "repo": "https://github.com/tokio-rs/tokio",
    "ref": "v1.43.0",
    "commit": "<git-sha>"
  },
  "artifacts": [
    {"path": "declarations.ndjson", "sha256": "<digest>", "compression": "none"},
    {"path": "symbols.ndjson", "sha256": "<digest>", "compression": "none"},
    {"path": "software-components.ndjson", "sha256": "<digest>", "compression": "none"},
    {"path": "sbom.cdx.json", "sha256": "<digest>", "compression": "none"},
    {"path": "sbom.spdx.json", "sha256": "<digest>", "compression": "none"}
  ]
}
```

`declarations.ndjson` 的单条记录遵循统一声明模型，但这个“统一”并不意味着抹平语言差异，而是采用 #strong[`signature` + `shape` + `language_specific` tagged union] 的方式，逐步设计一个能够跨 Go、Rust、Terraform、OpenAPI 读取的结构化声明超集。

这组字段当前建议收敛为：

- #strong[`id`]：声明的稳定标识，优先由 bundle 上下文、拥有者路径与签名摘要共同决定。
- #strong[`language`]：声明来源语言，如 `go`、`rust`、`terraform`、`openapi`。
- #strong[`name`] / `canonical_name`：局部名与全限定名。
- #strong[`visibility`]、#strong[`docs`]、#strong[`source_refs`]：最基础的可见性、注释与定位信息。
- #strong[`signature`]：原始签名文本，保留最接近源语言的可读表达。
- #strong[`shape`]：抽象的声明形状，用于表达函数参数类型、返回值类型、对象字段、契约输入输出等结构化信息。
- #strong[`relations`]：`contains`、`has_member`、`has_parameter`、`returns`、`references_type`、`implements` 等小而稳的关系集合。
- #strong[`language_specific`]：tagged union 扩展槽位，用于保留各语言无法安全压平到公共核心中的信息。

其中，#strong[`shape`] 将作为抽象类型系统的公共约定，但在本项目申报阶段 #strong[先不展开具体字段设计]。原因是它需要结合实际开发过程，对 Go、Rust、Terraform 与 OpenAPI 的声明特征做更深入调研，再决定公共字段边界。像 `kind`、`subkind`、`form`、`type_params` 这类更偏抽象形状层的字段，也将延后放入 `shape` 的正式设计中，而不是在当前文档中提前固定。

这样做的好处是：一方面保留 `signature`，方便人类阅读和快速排查；另一方面通过 `shape` 为下游结构化消费预留统一接口，但避免在项目尚未完成前过早固化一套不成熟的类型系统。

一个扩展后的记录示例如下：

```json
{
  "id": "decl:rust:tokio::sync::Mutex::lock",
  "purl": "pkg:cargo/tokio@1.43.0",
  "profile": "rust-crate",
  "language": "rust",
  "name": "lock",
  "canonical_name": "tokio::sync::Mutex::lock",
  "path": "tokio::sync::Mutex::lock",
  "signature": "fn lock(&self) -> impl Future<Output = MutexGuard<'_, T>>",
  "shape": {
    "status": "reserved-for-future-design",
    "note": "abstract declaration shape will be refined during implementation research"
  },
  "visibility": "public",
  "stability": "stable",
  "docs": "Lock this mutex, causing the current task to wait until the lock is acquired.",
  "source_refs": [
    {"uri": "src/sync/mutex.rs", "startLine": 120, "endLine": 134}
  ],
  "relations": [
    {"kind": "returns", "target": "type:rust:MutexGuard"}
  ],
  "language_specific": {
    "tag": "rust",
    "rust": {
      "async": false,
      "unsafe": false,
      "abi": null,
      "where_predicates": []
    }
  }
}
```

对于不同语言的特化部分，可采用同样的 tagged union 方式扩展：

- #strong[Go]：接收者、pointer receiver、embedding、方法集等。
- #strong[Rust]：lifetime、const generic、trait impl、where clause、unsafe/extern 等。
- #strong[Terraform]：`required`、`optional`、`computed`、`sensitive`、`force_new`、输入输出契约等。
- #strong[OpenAPI]：`allOf` / `oneOf` / `anyOf`、`discriminator`、media type、status code、parameter location 等。

这种设计相较于“每种语言各存一份完全不同的 JSON blob”有两个明显优势：

- #strong[下游结构化读取更稳定]：通用消费者只需要理解一套核心字段，就能完成跨语言查询、过滤和比较。
- #strong[语言保真度不被牺牲]：当遇到 Rust 的 lifetime、Go 的 receiver、Terraform 的 computed/sensitive、OpenAPI 的 discriminator 等特殊语义时，可以先通过原始 `signature` 和 `language_specific` 保留权威信息，再逐步把稳定部分沉淀进 `shape`。

=== CIQ OPA Bundle

`CIQ OPA Bundle` 是一种特殊的 `CIQ Bundle`，专门用于存储和管理与 Open Policy Agent (OPA) 相关的策略和规则。它不是面向代码声明查询的索引，而是面向 `check` 阶段的策略载荷：其中包含 OPA 的策略文件、数据文件以及相关元数据，可以像普通 `CIQ Bundle` 一样被 `Cogna Registry` 管理、缓存、下载和版本化。

它的作用是把“检查规则”也纳入 Cogna 的版本治理体系：库团队可以把兼容性规则、发布门禁规则、组织约束规则单独构建成策略产物，再由 `cogna check` 在本地装载执行。这种设计特别适合需要频繁更新和维护策略的项目。

建议的封装形态如下：

```text
compat-policy@2026.03.01.ciq.tgz
├── manifest.json
├── opa-bundle.tar.gz
├── metadata.json
└── checksums.txt
```

其中：

- #strong[`manifest.json`]：记录策略 Bundle 的 `schemaVersion`、PURL、版本、签名摘要、适用规则域。
- #strong[`opa-bundle.tar.gz`]：保存 OPA 原生 bundle，内部可包含 `.rego`、`data.json`、`.manifest`、可选 `.signatures.json` 等文件。
- #strong[`metadata.json`]：描述策略说明、适用场景、默认入口点、兼容的 `check` 模式。
- #strong[`checksums.txt`]：记录各文件摘要，便于 Registry 做去重和缓存一致性校验。

一个典型的使用方式是：SDK 团队先构建并发布 `CIQ OPA Bundle`，随后在业务代码仓库中执行 `cogna check ./dist/sdk.diff.json --policy ./compat-policy@2026.03.01.ciq.tgz`，把差异结果转成 SARIF。这样，策略本身也和代码一样具备清晰版本、可追溯来源和统一分发路径。

=== CIQ Diff

`diff` 输入代码仓库（及其基线版本信息），输出 `CIQ Diff`。它支持 `since` 参数来显式指定比较起点提交，并支持 `--test-changes` 选项把测试用例变化纳入分析范围。`CIQ Diff` 记录的不是源文件的逐行变化，而是#strong[声明层]的 added / removed / changed / deprecated 事件，以及这些事件对应的兼容性影响级别；当启用测试变化分析时，它还会额外记录测试用例的 added / modified / removed 事件。

对于测试用例的识别，Cogna 首期采用与语言生态约定一致的规则，例如：

- #strong[Rust]：识别带有 `#[test]` 标记的测试函数，以及由测试模块暴露出的测试入口。
- #strong[Go]：识别形如 `func TestXxx(t *testing.T)` 的测试函数。

这些测试变化并不替代接口层 diff，而是作为与公开声明变化并行的补充 section，用于回答“这次发布除了改了什么公开接口，还新增、修改或删除了哪些测试用例”。这类信息可进一步用于#strong[测试可观测性分析]、测试覆盖演进分析，以及与外部测试跟踪系统建立变更关联。

```json
{
  "schemaVersion": "ciq-diff/v1",
  "basePurl": "pkg:cargo/tokio@1.42.0",
  "targetPurl": "pkg:cargo/tokio@1.43.0",
  "since": "a1b2c3d4",
  "includeTestChanges": true,
  "summary": {
    "added": 12,
    "removed": 1,
    "changed": 4,
    "deprecated": 2
  },
  "testSummary": {
    "added": 3,
    "modified": 2,
    "removed": 1
  },
  "changes": [
    {
      "kind": "removed",
      "id": "decl:rust:tokio::runtime::Builder::new_multi_thread",
      "path": "tokio::runtime::Builder::new_multi_thread",
      "level": "breaking"
    }
  ],
  "testChanges": [
    {
      "kind": "modified",
      "language": "rust",
      "id": "test:rust:tokio::sync::mutex_tests::lock_is_fair",
      "path": "tokio::sync::mutex_tests::lock_is_fair",
      "signature": "#[test] fn lock_is_fair()",
      "location": {"uri": "tests/mutex.rs", "startLine": 24, "endLine": 41},
      "tracking": {
        "traceabilityKey": "tokio::sync::Mutex::lock",
        "externalIds": ["TMS-1421"]
      }
    }
  ]
}
```

=== SARIF

`check` 的输入是 `CIQ Diff` 与本地 `CIQ OPA Bundle`，输出必须是 SARIF，而不是内部 JSON 决策。这样可以直接接入现有代码扫描、代码审查和质量门禁工具。

在实现上，Cogna 可以先做内部规则判定或策略映射，但对外产物统一输出为 `sarifLog`。其中，`changes[].kind` 用于描述变化类型（如 `added`、`removed`、`changed`、`deprecated`），`changes[].level` 用于描述兼容性影响（如 `breaking`、`warning`、`note`）。典型结果映射为：

- 删除公开 API → SARIF `level: "error"`
- 兼容性风险 → SARIF `level: "warning"`
- 新增但未标注稳定性 → SARIF `level: "note"`

最小 SARIF 结果示例如下：

```json
{
  "version": "2.1.0",
  "runs": [
    {
      "tool": {
        "driver": {
          "name": "cogna-check",
          "rules": [
            {
              "id": "compat.removed-public-api",
              "shortDescription": {"text": "Removed public API requires compatibility review"}
            }
          ]
        }
      },
      "results": [
        {
          "ruleId": "compat.removed-public-api",
          "level": "error",
          "message": {"text": "Public API tokio::runtime::Builder::new_multi_thread was removed."},
          "locations": [
            {
              "physicalLocation": {
                "artifactLocation": {"uri": "src/runtime/builder.rs"},
                "region": {"startLine": 88, "endLine": 102}
              }
            }
          ]
        }
      ]
    }
  ]
}
```

=== CIQ Query / CIQ Result

`query` 输入 `CIQ Query`，输出 `CIQ Result`。两者都应保持机器可消费，便于本地 CLI、MCP Agent 与 AI Agent 复用。这里的查询只针对#strong[本地已存在或已下载的 `CIQ Bundle`]，不依赖 Registry 提供远程查询接口。

`CIQ Query` 示例：

```json
{
  "schemaVersion": "ciq-query/v1",
  "purl": "pkg:cargo/tokio@1.43.0",
  "selector": {
    "path": "tokio::sync::Mutex::lock",
    "kind": "function"
  },
  "intent": "upgrade"
}
```

`CIQ Result` 示例：

```json
{
  "schemaVersion": "ciq-result/v1",
  "purl": "pkg:cargo/tokio@1.43.0",
  "matches": [
    {
      "id": "decl:rust:tokio::sync::Mutex::lock",
      "kind": "function",
      "signature": "fn lock(&self) -> impl Future<Output = MutexGuard<'_, T>>",
      "location": {"uri": "src/sync/mutex.rs", "startLine": 120, "endLine": 134}
    }
  ]
}
```

=== Local Registry

`Local Registry` 是 Cogna 的单机本地实现，也是 `cogna publish` 的目标。它的职责被有意收敛为两类：#strong[接收并缓存整个 `CIQ Bundle` / `CIQ OPA Bundle`]，以及 #strong[按版本提供本地整包下载 / 物化]。Local Registry 不负责远程执行查询；CLI 与本地 MCP Agent 直接复用同一套本地 bundle store。

Registry 的核心模块如下：

#table(
  columns: (24%, 24%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*模块*], [*职责*], [*说明*],
  [Publish API], [接收整包上传], [校验 bundle schema、checksums、PURL 与 bundle 类型，拒绝不完整或重复上传],
  [Version Index], [维护元数据索引], [按 `purl + version + digest` 组织不可变版本，区分普通 bundle 与 OPA bundle，并维护 tag 到 bundleId 的映射],
  [Bundle Store], [持久化整包文件], [把 `.ciq.tgz` 作为整体对象管理，默认落在 `.cogna/cache/registry/bundles`],
  [Bundle Cache], [缓存热点产物], [为频繁物化和 MCP 查询的 bundle 维持本地缓存，降低查询启动时间],
)

Local Registry 的最小接口建议如下：

#table(
  columns: (30%, 26%, 44%),
  inset: 6pt,
  stroke: 0.4pt,
  [*接口*], [*输入*], [*输出*],
  [`POST /api/v1/bundles`], [`CIQ Bundle` 或 `CIQ OPA Bundle`], [`bundleId` / `purl` / `digest` / `bundleType`],
  [`GET /api/v1/packages/{purl-encoded}/versions`], [PURL], [可用版本、tag、bundleId、digest、bundleType 列表],
  [`GET /api/v1/bundles/{bundleId}`], [`bundleId`], [bundle 摘要、下载地址、ETag、创建时间],
  [`GET /api/v1/bundles/{bundleId}/download`], [`bundleId`], [完整 `.ciq.tgz` 下载流],
)

这里需要额外说明 #strong[Bundle ID] 的设计原因。Local Registry 中同一个 bundle 可能同时被多个 tag 或友好版本名引用，例如 `latest`、`v1.43.0` 与某个固定发布时间点标签，都可能指向同一个底层产物；与此同时，用户在可复现的 CI 场景里又希望按不可变内容来引用该产物。因此，Local Registry 同时保留两套引用方式：

- #strong[tag / semantic reference]：便于人类理解与发布管理，但可随时间重绑定。
- #strong[`bundleId` / digest reference]：基于 bundle 内容摘要生成，天然不可变，适合审计、缓存命中与可重复执行。

换句话说，#strong[多个 tag 可以指向同一个 bundleId，而同一个 bundleId 也可以同时被 tag 和 digest 两种方式引用]。因此 Local Registry API 采用 `bundleId` 作为内部下载与缓存主键，是为了在“人类友好引用”和“机器稳定引用”之间取得平衡。

`cogna publish` 的推荐行为如下：先本地构建 `CIQ Bundle` 或 `CIQ OPA Bundle`，再将整包写入 Local Registry，由 Local Registry 验证、缓存并生成下载地址。典型返回值为：

```json
{
  "publishId": "pub_20260319_001",
  "bundleId": "bundle_sha256_abc123",
  "purl": "pkg:cargo/tokio@1.43.0",
  "tags": ["v1.43.0", "latest"],
  "bundleType": "ciq-bundle",
  "downloadUrl": "http://127.0.0.1:8787/api/v1/bundles/bundle_sha256_abc123/download"
}
```

对 Local Registry 而言，#strong[digest 不可变、bundle 整体下载、缓存命中优先] 是三条基本原则。这样既可以支持单机上的 CLI、MCP 与自动化脚本复用稳定产物，也能避免把查询职责扩散到远端服务；查询能力留在本地，从而让职责边界更简单、状态更可控。

=== Cogna MCP Agent

`Cogna MCP Agent` 不是 Cogna 的万能入口，而是一个#strong[本地常驻内存查询代理]。它的职责非常明确：在本地加载一个或多个 `CIQ Bundle` 进入内存后，为 AI Agent 暴露“查声明 / 查签名 / 查注释 / 查契约”这类高频查询能力。那些不需要常驻内存、且更适合批处理和脚本集成的操作，如 `build`、`diff`、`check`、`publish`，都应通过 CLI 调用，而不是通过 MCP 调用。

MCP Agent 的工具接口设计如下：

#table(
  columns: (30%, 30%, 40%),
  inset: 6pt,
  stroke: 0.4pt,
  [*工具名*], [*输入参数*], [*输出*],
  [`cogna.query.outlines`], [`purl`, `limit?`, `cursor?`], [返回指定包的公开接口大纲索引，包括 path、kind、summary 等信息，供 AI 先做浏览和筛选],
  [`cogna.query.symbol`], [`purl`, `selector`, `kind?`, `intent?`], [统一返回精确声明、签名、注释、位置，以及 Terraform/OpenAPI 契约摘要],
)

这里将原先的 `cogna.query.declaration` 与 `cogna.query.contract` 合并为一个统一工具 `cogna.query.symbol`。原因是二者本质上都在做“按 selector 查询 bundle 中的结构化声明信息”，差别只在于返回内容更偏函数签名还是更偏配置/API 契约；合并之后，AI 只需要学会一套精确查询接口，既能查询代码声明，也能查询 Terraform/OpenAPI 的契约结构。

同时，不再提供“列出本地 bundle”这类工具，因为 AI 不需要先知道本地缓存里有哪些 bundle；`mcp start` 会根据当前工作目录中的依赖自动发现并装载相关 bundle。新的推荐流程是：#strong[先调用 `cogna.query.outlines` 根据 PURL 获取公开接口大纲，再调用 `cogna.query.symbol` 对感兴趣的 path 做精确查询]。其中也不再提供 `resolve` 工具：因为 bundle 的解析与下载属于 CLI/Registry 流程，而不是 MCP 的职责；`include` 这类细粒度远程对象选择参数也随之删除。每个 MCP 工具都应在 `tools/list` 中声明 `inputSchema` 与 `outputSchema`，并在 `tools/call` 结果中返回 `structuredContent`。例如，AI 可以先这样调用 `cogna.query.outlines`：

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "tools/call",
  "params": {
    "name": "cogna.query.outlines",
    "arguments": {
      "purl": "pkg:cargo/tokio@1.43.0",
      "limit": 20
    }
  }
}
```

拿到大纲中的候选 path 之后，再调用 `cogna.query.symbol` 获取精确声明：

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "tools/call",
  "params": {
    "name": "cogna.query.symbol",
    "arguments": {
      "purl": "pkg:cargo/tokio@1.43.0",
      "selector": "tokio::sync::Mutex::lock",
      "kind": "function"
    }
  }
}
```

对 AI Agent 而言，MCP Agent 的关键价值在于：它把高频查询能力保持在内存里，减少重复解析 bundle 的成本。但它并不取代 CLI。任何涉及构建、差异计算、策略执行、发布和下载的操作，仍然应通过 CLI 完成。

== 预期使用方式或交互流程

本项目采用用户故事方式来描述交互流程，并把 `Local Registry` 与 `Cogna MCP Agent` 纳入完整使用路径中。

- #strong[用户故事 1：SDK 开发者]
  1. SDK 开发者先在本地代码仓库执行 `build`，得到当前版本的 `CIQ Bundle`，从而把对外公开接口固定为一个可追溯、可复用的声明快照。
  2. 接着他执行 `diff`，将当前快照与上一稳定版本进行对比，产出 `CIQ Diff`，快速识别新增、删除、变更和弃用的公开接口。
  3. 为了把工程规则纳入门禁流程，他会再准备一个本地可用的 `CIQ OPA Bundle`，然后执行 `check <diff-file> --policy <local-policy-bundle>`，验证这次代码变更是否符合 policy 要求，并把结果转成 SARIF，用于 CI 展示与拦截。
  4. 如果团队还维护测试平台或测试追踪系统，他可以进一步把 `CIQ Diff.testChanges` 中的测试用例变化与外部测试 ID 关联，用于测试可观测性分析、回归计划编排和发布证据留存。
  5. 当 `check` 通过后，他再执行 `publish`，把新的 `CIQ Bundle` 发布到单机 `Local Registry`，让同一台机器上的 MCP 与自动化流程复用这份稳定快照。
  6. 最终效果是：SDK 开发者既能在发版前获得确定性的兼容性证据，也能在发版后把可查询的上下文资产沉淀到共享本地 bundle store，同时为测试变化提供可追踪的分析证据。

#figure(
  diagram(
    cell-size: 7mm,
    node-stroke: 0.8pt,
    node((0, 0), [SDK 代码仓库], corner-radius: 2pt),
    node((1, 0), [CIQ Bundle], corner-radius: 2pt),
    node((1, 1), [CIQ Diff], corner-radius: 2pt),
    node((2, 1), [SARIF 报告], corner-radius: 2pt),
    node((2, 0), [Local Registry], corner-radius: 2pt),
    edge((0, 0), (1, 0), "-|>", [`build`], label-pos: 0.5),
    edge((1, 0), (1, 1), "-|>", [`diff`], label-pos: 0.5),
    edge((1, 1), (2, 1), "-|>", [`check`
`--policy`], label-pos: 0.5),
    edge((1, 0), (2, 0), "-|>", [`publish`], label-pos: 0.5),
  ),
  caption: [用户故事 1：SDK 开发者流程]
)

- #strong[用户故事 2：平台工程师]
  1. 平台工程师先分别对 Rust / Go 代码、Terraform Module 和 OpenAPI 规格执行 `build`，生成一组可以独立版本化的 `CIQ Bundle`。
  2. 如果平台还维护统一的组织门禁规则，他会再构建一份 `CIQ OPA Bundle`，把发布策略和兼容性规则也纳入制品体系。
  3. 随后，他执行 `publish` 把这些 bundle 统一发布到 `Local Registry`，让平台能力在单机工作流中以标准化产物的形式沉淀下来。
  4. 需要复用这些产物时，他不再分别翻阅多个仓库，而是直接从共享本地 bundle store 物化所需 bundle，再通过 `query` 或 `mcp start` 使用这些产物。
  5. 最终效果是：平台工程师把“代码实现 + 开放平台契约 + 策略规则”统一交付为可缓存、可物化、可查询的本地资产，同一台机器上的不同工具也能复用同一套上下文来源。

#figure(
  diagram(
    cell-size: 7mm,
    node-stroke: 0.8pt,
    node((0, 0), [平台交付仓库], corner-radius: 2pt),
    node((1, 0), [CIQ Bundle 集合], corner-radius: 2pt),
    node((2, 0), [Local Registry], corner-radius: 2pt),
    node((2, 1), [本地 Bundle Cache], corner-radius: 2pt),
    node((1, 1), [Cogna MCP Agent], corner-radius: 2pt),
    node((0, 1), [下游开发者 AI Agent], corner-radius: 2pt),
    edge((0, 0), (1, 0), "-|>", [`build`], label-pos: 0.5),
    edge((1, 0), (2, 0), "-|>", [`publish`], label-pos: 0.5),
    edge((2, 0), (2, 1), "-|>", [下载 bundle], label-pos: 0.5),
    edge((2, 1), (1, 1), "-|>", [`mcp start`], label-pos: 0.5),
    edge((1, 1), (0, 1), "-|>", [`tools/call`], label-pos: 0.5),
  ),
  caption: [用户故事 2：平台工程师流程]
)

- #strong[用户故事 3：后台开发工程师]
  1. 后台开发工程师在接入第三方库或第三方 API 前，先从 `Local Registry` 物化所需的 `CIQ Bundle` 到本地缓存。
  2. 如果只是一次性查询，他直接执行 `query ./query.json`，根据查询文件中的 PURL 和 selector 获取指定声明、签名或契约说明；如果是高频交互式查询，他会执行 `mcp start`，让 AI Agent 根据当前包管理器依赖自动发现并装载需要的 bundle，再通过 MCP 反复查询这些本地产物。
  3. 当他在本地开发自己的 OpenAPI 时，会先执行 `build` 生成当前版本快照，再执行 `diff --since <stable-commit> --test-changes` 与稳定版本比较，确认公开契约发生了哪些变化，以及验证这些变化是否伴随测试用例调整。
  4. 最后，他会执行 `check <diff-file> --policy <local-policy-bundle>`，把这些变化转成 SARIF，用于确认自己交付的 OpenAPI 没有破坏性变更。
  5. 最终效果是：无论是消费外部依赖，还是维护自己的对外 API，他都能在统一的本地工具链中完成“下载 / 查询 / 对比 / 检查”的闭环。

#figure(
  diagram(
    cell-size: 7mm,
    node-stroke: 0.8pt,
    node((0, 0), [Local Registry], corner-radius: 2pt),
    node((1, 0), [本地 CIQ Bundle], corner-radius: 2pt),
    node((2, 0), [Cogna MCP Agent], corner-radius: 2pt),
    node((2, 1), [AI Agent], corner-radius: 2pt),
    node((1, 1), [CIQ Diff], corner-radius: 2pt),
    node((0, 1), [SARIF 报告], corner-radius: 2pt),
    edge((0, 0), (1, 0), "-|>", [下载 bundle], label-pos: 0.5),
    edge((1, 0), (2, 0), "-|>", [`mcp start`], label-pos: 0.5),
    edge((2, 0), (2, 1), "-|>", [`tools/call`], label-pos: 0.5),
    edge((1, 0), (1, 1), "-|>", [`diff`], label-pos: 0.5),
    edge((1, 1), (0, 1), "-|>", [`check`
`--policy`], label-pos: 0.5),
  ),
  caption: [用户故事 3：后台开发工程师流程]
)

CLI 原型如下：

```bash
cogna init
cogna build ./sdk
cogna build ./policy
cogna diff ./sdk --since <last-release-commit> --test-changes
cogna check ./dist/tokio.diff.json --policy ./dist/compat-policy.ciq.tgz
cogna mcp start
cogna query ./query.json
cogna publish ./dist/tokio@1.43.0.ciq.tgz
```

== 初步测试规划

测试重点将围绕“格式正确、抽取稳定、差异可信、OPA 策略可装载、Registry 可缓存、MCP 可互通、SARIF 可集成”七条主线展开：

- #strong[单元测试]：覆盖 Go / Rust / Terraform / OpenAPI 抽取器、PURL 生成、声明归一化、普通 bundle 与 `CIQ OPA Bundle` 的编解码。
- #strong[格式/契约测试]：验证 `CIQ Config`、`CIQ Bundle`、`CIQ OPA Bundle`、`CIQ Diff`、`CIQ Query`、`CIQ Result` 与 SARIF 输出字段和关键约束保持稳定。
- #strong[集成测试]：跑通 `init → build → diff → check --policy → publish → download → query / mcp start` 全链路，确保产物可被独立消费。
- #strong[回归测试]：构造删除公开函数、修改 OpenAPI response schema、变更 Terraform 输出变量等样例，检查 diff 与 SARIF 结果是否稳定。
- #strong[策略 Bundle 测试]：验证 `opa-bundle.tar.gz` 的加载、版本切换与 `check` 入口点选择是否稳定。
- #strong[Registry 测试]：验证整包上传、版本索引、下载地址、ETag/缓存命中与共享本地 bundle store 语义。
- #strong[MCP 合约测试]：只验证 `cogna.query.outlines` 与 `cogna.query.symbol` 这类常驻内存查询工具的 schema 与结果结构。
- #strong[性能测试]：对比 LSIF/SCIP 类索引方案的体积特征，并评估 Registry 缓存命中后 bundle 下载与本地查询启动延迟。

== 文档与使用说明覆盖范围

文档交付将参考 Divio Documentation System，把文档拆成 #strong[教程（Tutorials）]、#strong[How-to 指南]、#strong[参考（Reference）]、#strong[解释（Explanation）] 四个象限，每个象限只承担一种目标，避免把“教学、操作、查阅、原理”混写在一起。

#table(
  columns: (20%, 22%, 28%, 30%),
  inset: 6pt,
  stroke: 0.4pt,
  [*象限*], [*目标读者*], [*重点内容*], [*典型问题*],
  [Tutorials], [初次接触 Cogna 的开发者], [从零完成一次 `init → build → diff → check → publish` 的学习路径], [我第一次使用 Cogna，应该按什么顺序走通完整流程？],
  [How-to guides], [有明确任务的工程师], [如何发布 bundle、如何运行 check、如何为 AI 启动 MCP、如何下载并查询指定 bundle], [我现在要解决一个具体问题，应该怎么操作？],
  [Reference], [需要精确查阅的人], [CLI 参数、MCP tool schema、CIQ 格式、Registry API、SARIF/OPA Bundle 结构], [某个命令、字段、接口或返回值的准确定义是什么？],
  [Explanation], [需要理解设计取舍的人], [为什么设计 CIQ、为什么选择 SARIF/OPA、为什么需要 Registry、为什么支持配置语言], [这些设计背后的原理、边界和取舍是什么？],
)

= 技术路线说明

== 整体系统架构与核心模块划分

系统架构收敛为六层：

#table(
  columns: (1.3fr, 2fr, 3fr),
  inset: 6pt,
  stroke: 0.4pt,
  [*层次*], [*模块*], [*职责*],
  [配置层], [`CIQ Config`], [定义 profile、PURL、输入文件范围、输出格式与检查策略],
  [抽取层], [Go/Rust/Terraform/OpenAPI extractors], [从代码与规格文件中抽取公开声明与位置信息],
  [规范化层], [declaration normalizer], [统一不同生态的声明形态与差异分类模型],
  [产物层], [Bundle / OPA Bundle / Diff / Query / Result / SARIF], [产出可发布、可比较、可消费的标准化对象],
  [本地存储层], [Local Registry + Bundle Cache], [提供 publish、版本索引、本地整包下载与热点缓存能力],
  [Agent 层], [CLI + 本地 MCP Query Agent], [CLI 负责 build/diff/check/publish，MCP 只负责常驻内存查询],
)

该架构的关键原则是：#strong[Cogna 只负责抽取和组织声明事实，不负责解释实现逻辑]。Local Registry 负责分发整包与缓存，CLI 负责构建、差异和门禁，MCP Agent 只负责把本地已装载的事实以查询工具形式暴露给模型。这种分层使系统更轻量、更稳定，也更容易和现有治理工具集成。

== 大模型与智能体工具在开发过程中的作用

本项目的 AI 开发环境使用 OpenCode + oh-my-opencode，配合 Visual Studio Code 进行代码编辑、运行与调试。

模型分工如下：

- #strong[主力开发模型]：使用 GitHub Copilot 订阅中的 Opus 4.6 作为主力开发模型，承担主要编码与方案实现工作。
- #strong[检索模型]：使用 GPT-5-Mini 进行代码检索、文档检索和资料整理，帮助快速定位实现线索与上下文。
- #strong[调试与测试模型]：使用 GPT-5.4 / GPT-5.3-Codex 作为 DEBUG、测试设计与问题排查工具。
- #strong[补充模型]：另有 MiniMax 订阅，主要用于在配额不足时补充文档撰写与内容整理，但不作为主力编码模型。

这种分工的目标，是在控制模型使用成本的同时，提高检索、开发、调试与测试各环节的效率，并保持关键工程判断的稳定性。

== 关键技术选型说明

=== 为什么要重新设计 CIQ

我们没有直接采用 LSIF 或 SCIP，是因为这两类格式更偏向代码导航场景，例如 Hover、Definition、References 等 IDE 能力。Cogna 的重点则是第三方库的公开接口治理、变更检查、策略门禁和整包分发。为此，CIQ 从一开始更注重声明清晰可读、版本之间便于比较，以及分发和缓存效率，而不是追求完整的代码导航图谱。

#table(
  columns: (22%, 26%, 26%, 26%),
  inset: 6pt,
  stroke: 0.4pt,
  [*对比项*], [*LSIF*], [*SCIP*], [*CIQ*],
  [主要目标], [服务离线代码导航], [用更小体积承载代码导航索引], [承载公开接口、契约差异、策略门禁与上下文分发],
  [核心数据形态], [导航关系数据], [紧凑索引文件], [Bundle 化声明记录、差异结果与策略产物],
  [更适合的查询], [Hover、Definition、References], [精确导航与符号引用], [声明、签名、注释、契约、变更与 policy 结果],
  [对第三方库治理的适配], [可以借用，但不是主要设计目标], [可以借用，但不是主要设计目标], [直接面向库治理场景设计],
  [典型体积], [通常是代码体积的 10–30 倍], [通常约为 LSIF 的 1/10], [不包含代码逻辑，通常比代码小一个数量级],
  [性能重点], [优先保证导航可用], [优先降低索引体积与传输成本], [优先提升缓存命中、本地查询启动与差异比较效率],
  [云端分发方式], [通常作为导航索引文件存储], [通常作为导航索引文件存储], [支持 Registry 缓存与 Bundle ID 管理],
)

因此，CIQ 的优势在于 #strong[更适合库接口治理这个场景]。它用更小、更稳定的核心字段表达结构化声明，用 `CIQ Diff` 表达接口变化，用 `CIQ OPA Bundle` 表达策略规则，再通过 Registry 与本地 MCP 查询能力组合出一条完整工作流。由于 CIQ 不承载实现逻辑和完整导航图谱，在目标场景中通常可以获得更低的存储、缓存与传输成本。

=== SARIF

SARIF（Static Analysis Results Interchange Format）是 OASIS 定义的静态分析结果交换标准，用于描述规则、结果、位置、严重级别、帮助信息以及运行元数据。它的价值在于：不同分析工具即使内部实现完全不同，也可以把结果统一输出成同一套结构，再交给代码托管平台、CI 系统或质量平台消费。

对 Cogna 而言，选择 SARIF 有两个直接好处：

- #strong[结果可被现有工具链直接消费]：不需要额外设计私有格式的上传接口。
- #strong[规则、结果、位置语义完整]：适合表达“哪条 policy 被违反、发生在什么位置、严重级别如何”。

更重要的是，#strong[GitHub 已明确支持 SARIF 作为代码扫描结果的标准格式]，能够解析第三方工具产出的 SARIF 文件，并将其展示为代码扫描告警。这意味着 Cogna 的 `check` 结果可以天然进入 GitHub 与现有代码审查工作流，而不需要额外适配一套自定义展示逻辑。

=== OPA

OPA（Open Policy Agent）是一个通用策略引擎，核心能力是把策略决策从业务实现中解耦出来，让系统通过结构化输入查询策略结果。OPA 在策略引擎领域具有很强的代表性，同时也是 CNCF 的 Graduated 项目，已经在 Kubernetes、CI/CD、API 授权、Terraform 校验等众多云原生安全与治理场景中得到广泛使用。

在 Cogna 中，OPA 的价值主要体现在两点：

- #strong[策略分发成熟]：OPA 原生支持 bundle 机制，适合封装和发布规则。
- #strong[Rego 表达能力强]：Rego 作为声明式策略语言，擅长对 JSON 等结构化输入表达复杂规则，非常适合把 `CIQ Diff`、声明记录和元数据作为输入来做变更门禁。

也正因为如此，Cogna 不需要重新发明一门策略语言，而是把重点放在“如何把结构化声明与差异结果喂给 OPA”，并通过 `CIQ OPA Bundle` 把策略本身纳入统一版本治理。

=== 为什么要构建 Local Registry

Local Registry 的意义，不只是提供一个上传入口，而是为 `CIQ Bundle` 和 `CIQ OPA Bundle` 提供 #strong[性能优化过的共享本地缓存与分发层]。如果没有 Local Registry，同一台机器上的 CLI、MCP 与自动化任务都需要自己重新构建或重复传输同样的 bundle；而有了 Local Registry，热点产物可以被集中缓存、版本索引并按 Bundle ID 精确分发，从而显著降低本地获取上下文的延迟。

除此之外，Local Registry 还有两个关键价值：

- #strong[单机边界清晰]：把 CLI / MCP / Local Registry 固定在同一套本地状态里，避免远端部署与多节点一致性复杂度。
- #strong[缓解软件供应链混乱]：通过整包发布、Bundle ID、digest 和缓存控制，用户可以明确知道自己消费的是哪一个不可变产物，降低被错误引用的风险。

=== 为什么要支持配置语言

在现代软件系统中，风险并不只来自代码实现本身。Terraform Module、OpenAPI Specification 这类配置与契约语言，往往直接决定了部署结果、资源行为、上下游兼容性和 API 使用方式。它们的变化同样可能引入破坏性后果，例如资源销毁、默认值变化、输出字段移除或接口 schema 不兼容。

因此，Cogna 支持配置语言并不是“顺手多做一点”，而是因为 #strong[配置语言本身就是软件系统对外承诺的重要组成部分]。如果只分析代码、不分析配置与 API 规格，那么用户仍然无法真正掌握系统的完整变更风险。通过把 Terraform 与 OpenAPI 纳入统一 Bundle、Diff、Check 和 Query 工作流，Cogna 才能提供面向真实交付系统的完整上下文能力。

= 风险分析与应对方案

== 可能面临的技术或工程风险

- #strong[Rust 宏展开的复杂性]：Rust 的宏展开可能需要更深层次的静态分析，这会增加开发难度与时间成本。
- #strong[共享本地 store 的状态一致性]：CLI、Local Registry 与 MCP 共享一套本地 bundle store 后，需要保证索引、bundle 与物化缓存之间的语义一致性。
- #strong[Terraform / OpenAPI 的 PURL 兼容性]：虽然本文中使用 `pkg:terraform/...` 和 `pkg:openapi/...` 作为目标格式，但这两类类型尚未成为正式 purl-spec 的组成部分，存在与现有 PURL 校验器或下游工具不兼容的风险。

== 对应的缓解措施或替代方案

- #strong[针对 Rust 宏展开]：提前进行专项技术调研，评估 Rust 原生工具链与现有辅助工具/库的能力，必要时引入这些工具简化宏展开处理；在首版实现中优先保证非宏场景与常见宏场景可用，再逐步增强。
- #strong[针对共享本地 store]：优先把 authoritative storage 固定到 `.cogna/cache/*`，并通过 focused tests 验证 publish / download / MCP materialization 共享同一套本地事实。
- #strong[针对 PURL 兼容性]：在文档与实现中同时保留回退策略；当下游工具无法接受 `pkg:terraform/...` 或 `pkg:openapi/...` 时，可退回为 `pkg:generic/terraform-aws-vpc@5.18.1` 与 `pkg:generic/payment-api@2026.03.01`，并在未来视 purl-spec 进展再迁移到正式类型。

= 相关研究与实践基础

项目设计与以下技术实践密切相关：

- #strong[SCIP]：Sourcegraph 用于精确代码导航的 protobuf 索引传输格式，强调更小、更快、更易调试的索引体验。
- #strong[LSIF]：为代码导航而设计的语言服务器索引格式，适合作为离线导航的历史基线方案。
- #strong[MCP]：用于把工具和外部数据源标准化暴露给模型的开放协议，为 Cogna MCP Agent 提供工具接口设计基础。
- #strong[Semgrep]：面向规则与模式匹配的轻量静态分析工具，适合作为“Cogna 不做实现级分析”的对照参照物。
- #strong[PURL]：跨生态的软件包唯一标识规范，为声明快照、依赖治理与结果交换提供统一身份语义。
- #strong[SARIF]：静态分析结果交换标准，使 Cogna 的检查结果可以无缝进入现有工具链。

从技术现状看，SCIP/LSIF 主要解决“导航索引如何表达”的问题，MCP 主要解决“模型如何发现和调用工具”的问题，Semgrep 主要解决“规则与模式如何扫描”的问题，而 Cogna 关注的是“库公开接口如何被结构化抽取、比较、发布和查询”。几者并不冲突，但定位不同。Cogna 的差异化价值在于：把声明级事实抽取、PURL 标识、版本差异、Registry 缓存、MCP 工具接口和 SARIF 集成，统一到一个轻量、可工程化消费的工作流里。

= 个人背景与项目匹配度

我是李宇飞（yufeiminds），长期从事开发者基础设施、开发者工具与平台工程，持续关注 SDK、CLI、云资源编排与 AI 开发流程中的工程确定性问题。相较于追求“更强大的分析器”，我更关注“如何把关键事实提取出来，并稳定接入开发流程”，这与 Cogna 的声明级定位高度一致。

已有积累包括：

- 使用 Rust 实现软件成分分析与工程元数据处理工具；
- 长期研究 tree-sitter、静态类型映射与结构化抽取；
- 在 Dev Infra 场景中实践过接口、版本、发布与自动化门禁之间的联动治理。

这些基础使我能够从工程实现和产品交付两个层面推进 Cogna：既理解声明抽取与格式设计，也理解如何把结果真正纳入 CI、质量平台和 AI 工作流。

= 其它有助于理解项目的补充材料

== 相关链接

- SCIP: `https://sourcegraph.com/blog/announcing-scip`
- MCP Tools: `https://modelcontextprotocol.io/specification/draft/server/tools`
- Semgrep: `https://github.com/semgrep/semgrep`
- LSIF: `https://code.visualstudio.com/blogs/2019/02/19/lsif`
- PURL Spec: `https://github.com/package-url/purl-spec`
- SARIF: `https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html`
- Fletcher: `https://typst.app/universe/package/fletcher/`
