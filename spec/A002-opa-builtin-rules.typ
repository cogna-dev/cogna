#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：A002 内置 OPA 规则集",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本提案定义 CodeIQ 下一阶段的 #strong[内置 OPA 规则集]。当前 repo 已具备 `CIQ OPA Bundle`、`check --policy`、`opa eval --bundle ... data.codeiq.compat.deny`、`CIQ Diff` enriched surface 与最小 SARIF 输出，但默认策略仍停留在 `added/changed/removed/deprecated` 四类浅层规则。A002 的修订结论是：在不突破 single-machine / local-only 边界的前提下，把 #strong[`semanticDiff.findings[]` 设计为唯一 canonical match surface]，并把 Rego 作为唯一 executable policy，把 `policy.rules.json` 收敛为由同一规则源生成的 catalog artifact，从而建立一套更简洁、无兼容包袱、可回归测试的 built-in OPA rules baseline。
  ],
  keywords: (
    "CodeIQ",
    "OPA",
    "Rego",
    "SARIF",
    "Builtin Rules",
    "Go",
    "Rust",
    "Terraform",
    "OpenAPI",
  ),
  date: "March 27, 2026",
)

= 一句话结论与边界

A002 不重新设计 policy runtime；它只做一件事：#strong[定义一套 built-in OPA/Rego 规则集，使 `CIQ Diff -> OPA -> SARIF` 这条现有本地主线可以稳定治理 breaking change]。

边界保持不变：

- 继续使用本地 `opa eval --bundle ... data.codeiq.compat.deny`；
- 继续使用 `ciq-opa-bundle/v1`；
- 不引入 hosted policy registry、remote fetch、distributed evaluation；
- 因为产品尚未正式发布，#strong[本提案不保留为了向后兼容而存在的冗余字段与概念]。

= 评审优先看的内容

== 用户可见输入与输出

#table(
  columns: (18%, 26%, 26%, 30%),
  inset: 6pt,
  stroke: 0.4pt,
  [*阶段*], [*用户输入*], [*用户可见输出*], [*说明*],

  [`build`（代码/规格 repo）], [`codeiq.yaml` + source files], [`dist/manifest.json`、`declarations.ndjson`、`software-components.ndjson`、`sbom.*`、`bundle.ciq.tgz`], [生成普通 `CIQ Bundle`],
  [`diff`], [base/target repo state], [`dist/diff.json`], [`CIQ Diff` 中的 changed declaration 应携带 `semanticDiff.findings[]`],
  [`build`（policy repo）], [policy repo 根目录 `*.rego` + `codeiq.yaml(profile: policy-bundle)`], [`dist/manifest.json`、`dist/opa-bundle.tar.gz`、`dist/policy.rules.json`、`dist/bundle.ciq.tgz`], [生成可供 `check --policy` 使用的 Builtin OPA bundle],
  [`check`], [`<diff-file>` + `--policy <bundle.ciq.tgz>`], [`check.sarif.json`], [用户直接消费的是 SARIF；OPA internal input/output 是内部 machine contract],
)

若从 machine I/O 角度展开，runtime 内部真正关心的是：

#table(
  columns: (20%, 30%, 50%),
  inset: 6pt,
  stroke: 0.4pt,
  [*层次*], [*输入*], [*输出*],

  [CLI 输入], [`ciq-diff/v1` 文件 + 本地 policy bundle 路径], [`codeiq check <diff> --policy <bundle>` 命令调用],
  [OPA 输入], [`prepare_opa_input(diff)` 生成的 JSON envelope], [`changes[*].semanticDiff.findings[]`、`componentChanges[*]`、top-level summary/base/target fields],
  [OPA 输出], [`data.codeiq.compat.deny`], [policy decision objects：`rule_id` / `level` / `message` / `path` / `docs`],
  [CLI 输出], [policy decision objects + diff], [`check.sarif.json`],
)

== Builtin OPA 的交付物

#table(
  columns: (18%, 26%, 56%),
  inset: 6pt,
  stroke: 0.4pt,
  [*视角*], [*交付物*], [*说明*],

  [维护者], [`*.rego` source files], [唯一 executable policy source；真正决定 `data.codeiq.compat.deny` 返回什么],
  [维护者], [`policy.rules.json` source metadata], [从同一规则源生成的 catalog metadata，用于 discoverability、docs、report enrichment 与测试对账],
  [维护者], [spec + tests], [`spec/A002-opa-builtin-rules.typ`、schema/tests、OPA acceptance fixtures],
  [用户], [`dist/bundle.ciq.tgz`], [可直接传给 `codeiq check --policy` 的最终整包 artifact],
  [用户], [`dist/manifest.json`], [`ciq-opa-bundle/v1` manifest，声明 entrypoint、artifacts 与 provenance],
  [用户], [`dist/opa-bundle.tar.gz`], [OPA 原生 bundle 载荷，内部包含 `policy.rego`、`data.json`、`.manifest`],
  [用户], [`dist/policy.rules.json`], [供人类与脚本直接读取的 built-in rule catalog],
  [用户], [`dist/metadata.json`], [规则库版本与说明],
  [用户], [`dist/checksums.txt`], [artifact 完整性与去重依据],
)

== Diff 契约：OPA 应该匹配什么

当前设计的核心不是“让 OPA 重新解释整个 diff”，而是让 diff 先做 normalization，再把 OPA 匹配面收敛到一个字段：#strong[`semanticDiff.findings[]`]。

最小 declaration change 示例：

```json
{
  "schemaVersion": "ciq-diff/v1",
  "basePurl": "pkg:cargo/tokio@1.42.0",
  "targetPurl": "pkg:cargo/tokio@1.43.0",
  "summary": { "added": 1, "removed": 1, "changed": 3, "deprecated": 0 },
  "changes": [
    {
      "id": "decl:rust:tokio::sync::Mutex::lock",
      "kind": "changed",
      "level": "breaking",
      "path": "src/lib.rs",
      "before": "fn lock(&self)",
      "after": "unsafe fn lock(&self) -> Guard",
      "semanticDiff": {
        "findings": [
          { "code": "rust-became-unsafe" },
          { "code": "rust-signature-changed" }
        ],
        "shapeDiff": {
          "before": { "kind": "function", "returns": [] },
          "after": { "kind": "function", "returns": ["Guard"] }
        },
        "languageSpecificDiff": {
          "before": { "rust": { "unsafe": false } },
          "after": { "rust": { "unsafe": true } }
        }
      },
      "beforeRecord": { "location": { "file": "src/lib.rs", "line": 12 } },
      "afterRecord": { "location": { "file": "src/lib.rs", "line": 12 } }
    }
  ],
  "componentChanges": []
}
```

这个例子表达的 contract 很简单：

- declaration rules #strong[只匹配 `changes[*].semanticDiff.findings[*].code`]；
- `kind`、`level`、`path`、`before`、`after`、`shapeDiff`、`languageSpecificDiff`、`beforeRecord`、`afterRecord` 都只是 evidence / context；
- 如果一个 change 同时具有多个语义面，就自然产生多个 finding code；OPA 不需要在不同 change 上切换不同匹配风格；
- component rules 暂时继续使用 `componentChanges[*].componentDiff.upgradeKind` 这一独立 surface。

== OPA / Rego 的策略写法

当前 repo reality 中，OPA 规则确实是 #strong[Rego 文件]。`policy-bundle` 的构建流程是：

- policy repo 根目录下放置一个或多个 `*.rego` 文件；
- `build` 当前会读取 repo 根目录的 `*.rego`，并把它们按顺序拼接成 bundle 内部的单个 `policy.rego`；
- 同时写入 `data.json` 与 `.manifest`，再 gzip 成 `opa-bundle.tar.gz`；
- `check` 最终执行 `opa eval --bundle <policy_bundle> --input <temp_input> --format json data.codeiq.compat.deny`。

当前没有 `.rego` 时的最小占位规则：

```rego
package codeiq.compat

default deny = []
```

Builtin OPA 的目标写法应统一为 helper + finding-code matching：

```rego
package codeiq.compat

default deny = []

has_finding(change, code) if {
  some finding in change.semanticDiff.findings
  finding.code == code
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "rust-became-unsafe")
  out := {
    "rule_id": "compat.rust.became-unsafe",
    "level": "error",
    "message": "Public Rust item became unsafe and now requires caller-side audit.",
    "path": change.path,
    "docs": "https://github.com/yufeiminds/codeiq/blob/main/spec/A002-opa-builtin-rules.typ",
  }
}

deny contains out if {
  change := input.changes[_]
  has_finding(change, "rust-signature-changed")
  out := {
    "rule_id": "compat.rust.signature-changed",
    "level": "error",
    "message": "Public Rust signature changed and callers may need to update usage.",
    "path": change.path,
    "docs": "https://github.com/yufeiminds/codeiq/blob/main/spec/A002-opa-builtin-rules.typ",
  }
}
```

上面的例子刻意体现了修订后的关键点：#strong[同一个 change 可以同时触发多个 built-in rule]。如果一个函数既变成 `unsafe`，又改了函数签名，那么 `semanticDiff.findings[]` 会同时包含两个 finding，OPA 就应该输出两条 deny 结果。

== `policy.rules.json` 和 Rego 的关系

这部分必须说清楚，因为它是评审最容易疑惑的点：

#table(
  columns: (22%, 28%, 50%),
  inset: 6pt,
  stroke: 0.4pt,
  [*对象*], [*是否可执行*], [*职责*],

  [`*.rego`], [#strong[是]], [唯一 executable policy source。OPA 真正执行的是这些规则；`data.codeiq.compat.deny` 的返回值完全由 Rego 决定],
  [`policy.rules.json`], [#strong[否]], [catalog artifact。用于 discoverability、rule reference、docs/helpUri、默认级别说明、测试对账与报告补充，不是第二套策略语言],
)

因此两者 #strong[不是重复功能]，但如果手工分别维护，就会产生 drift。A002 的结论是：

- Rego 是 #strong[执行真相]；
- `policy.rules.json` 是 #strong[描述真相]；
- `policy.rules.json` 必须由和 Rego 同一套规则源生成，而不是人工单独维护；
- OPA #strong[不会执行 `policy.rules.json`]；它只执行 Rego；
- `check` 运行时会读取 `policy.rules.json` 来补全 SARIF driver metadata，但不会把它当成 executable selector；
- 评审与用户应通过 `policy.rules.json` 快速看到“有哪些规则、默认级别是什么、帮助链接在哪里”，而不必先读 Rego 源码。

== `policy.rules.json` 是否还需要 `findingCodes`

这是本提案需要进一步收紧的点。

当前 repo reality 中：

- `policy.rules.json` 会被 `build` 产出、写入 bundle、写入 manifest、写入 checksums，并在 tests 中校验其存在；
- 但 `check` 运行时真正消费的是 #strong[OPA decision objects]，不是 `policy.rules.json`；
- `check` 仍会读取 `policy.rules.json` 来补充 SARIF driver rules / helpUri 等报告元数据，但不会读取其中任何 selector 来参与匹配；
- 当前代码里没有任何运行时逻辑会去读取 `policy.rules.json` 中的 `findingCodes` 来参与匹配。

因此，如果 `findingCodes` 只是把同样的 selector 再从 Rego 抄写一遍放进 JSON，那么它在当前产品边界下 #strong[没有实际执行作用]，只会增加 drift 风险。

所以 A002 的更新结论是：

- `policy.rules.json` #strong[不再保留 `findingCodes`]；
- selector 只存在于 Rego authoring 中；
- `policy.rules.json` 只保留 rule catalog 真正需要的字段：rule id、默认级别、概要、文档链接，以及定位到 Rego entrypoint 的指针；
- 如果未来真的出现 catalog-side filtering / docs-side grouping / static validation 需要 selector 再暴露出来，再单独设计，不在当前阶段预留。

== `policy.rules.json` 最小 contract

因为产品尚未正式发布，A002 不再保留为了未来兼容性预留的复杂 selector 语法；catalog 只保留当前真正需要的最小字段：

```json
{
  "schemaVersion": "codeiq-policy-rules/v1",
  "rules": [
    {
      "id": "compat.rust.signature-changed",
      "family": "rust",
      "defaultLevel": "error",
      "summary": "Public Rust signature changed.",
      "docs": "https://github.com/yufeiminds/codeiq/blob/main/spec/A002-opa-builtin-rules.typ",
      "entrypoint": "data.codeiq.compat.deny"
    }
  ]
}
```

当前明确删掉或不再引入的冗余点：

- 不再保留 `semanticCategory` 作为 design contract 中的 alias；
- 不在 finding 对象里重复写 `family`、`impact`、`summary`；这些语义已经由 rule catalog 与 top-level `level` 承载；
- 不在 policy decision object 中重复写 `family`、`ecosystem`；运行时最小 contract 只要求 `rule_id` / `level` / `message` / `path` / `docs`；
- 不在 `policy.rules.json` 中重复抄写 Rego selector，例如 `findingCodes`；
- 不为 catalog 提前设计 `allOfFindings` / `noneOfFindings` 等复杂 selector，除非后续真有规则需要。

= 设计决策（精简版）

#table(
  columns: (22%, 26%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*决策项*], [*A002 结论*], [*说明*],

  [运行时入口], [`data.codeiq.compat.deny`], [保持 `check` 当前调用方式不变；manifest 中继续写 `codeiq/compat/deny`],
  [规则命名], [`compat.<family>.<rule>`], [统一使用稳定 rule id，family 至少包含 `core/go/rust/terraform/openapi/component`],
  [匹配策略], [#strong[`semanticDiff.findings[]` canonical]], [declaration built-in rules 只匹配 `semanticDiff.findings[].code`],
  [组件匹配], [`componentDiff.upgradeKind`], [component rules 暂时继续用独立 surface，不与 declaration findings 混合],
  [输入契约], [evidence-first], [`shapeDiff`、`languageSpecificDiff`、`beforeRecord`、`afterRecord` 只作为 evidence/context],
  [输出契约], [最小 policy decision object], [只要求 `rule_id` / `level` / `message` / `path` / `docs`],
  [catalog 角色], [generated metadata artifact], [`policy.rules.json` 不可执行，只做 discoverability / docs / report enrichment],
)

= 为什么要这样精简

原先 A002 的问题有三类：

- #strong[匹配面重复]：`kind`、`semanticCategory`、`semanticDiff` 都像 selector；
- #strong[字段重复]：finding 里写一遍 `family/impact/summary`，catalog 里再写一遍；
- #strong[Rego 与 catalog 容易漂移]：两边都像在定义规则。

修订后的精简策略是：

- selector 只保留一个：`semanticDiff.findings[].code`；
- rule metadata 只保留在一个地方：`policy.rules.json`；
- executable logic 只保留在一个地方：Rego。

== 为什么不能只依赖 `changedFields`

仅依赖 `semanticDiff.changedFields` 而完全不做 normalized findings，仍然会有三个问题：

- `shape`、`language_specific`、`path` 这类字段本身不足以稳定表达“这是 Go receiver change、Rust unsafe change、Terraform provider-ref change，还是 OpenAPI became-required”；
- 每一条 policy 都要重新解释 `shapeDiff`、`languageSpecificDiff`、before/after record，导致 drift；
- `policy.rules.json` 很难只靠字段路径表达清楚“这条规则到底匹配什么”。

因此 A002 仍然保留“normalized findings”这一层，但把 finding 对象压缩到最小，只留下真正承担 selector 职责的 `code`。

== 为什么不再保留 `semanticCategory`

用户已明确指出：如果一个 change 同时有多个语义面，`semanticCategory` 会把 OPA 逼回双轨匹配。因此在 pre-release 阶段，最干净的做法不是再保留 alias，而是直接从 #strong[target design] 中删掉它。

这意味着：

- implementation 过渡期可以短暂同时存在旧字段和新字段；
- 但 A002 作为 target design，不再把 `semanticCategory` 写进 normative contract；
- 评审与后续实现都应以 `findings[]` 为唯一 declaration selector。

= 规则 taxonomy

A002 规定 built-in library 至少包含六个 family：

- `compat.core.*`
- `compat.go.*`
- `compat.rust.*`
- `compat.terraform.*`
- `compat.openapi.*`
- `compat.component.*`

severity model 保持不变：

#table(
  columns: (20%, 20%, 60%),
  inset: 6pt,
  stroke: 0.4pt,
  [*level*], [*默认含义*], [*典型场景*],

  [`error`], [blocking], [删除公开 API、Rust 变为 `unsafe`、Rust signature breaking、OpenAPI 必填化、Terraform input became required],
  [`warning`], [needs review], [where clause 改变、providerRef 改变、component major upgrade、额外 success status code 引入],
  [`note`], [informational], [新增公开 API、deprecated、`ignoreChanges` 扩大、额外 media type 引入],
)

stage-1 规则匹配方式保持统一：

- `compat.core.*`：匹配 core finding codes；
- `compat.go.*`：匹配 Go finding codes；
- `compat.rust.*`：匹配 Rust finding codes；
- `compat.terraform.*` / `compat.openapi.*`：stage-2 结合 richer evidence 深化；
- `compat.component.*`：继续匹配 component upgrade kind。

== 各语言 / 生态的 built-in 策略清单

下面的策略清单以 #strong[当前 repo 已有 semantic categories / component upgrade kinds] 为依据，并把 A002 计划中的 stage-2 策略分开标注。

=== `core`

#table(
  columns: (34%, 18%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*策略*], [*级别*], [*概要*],

  [`compat.core.removed-declaration`], [`error`], [公开声明被移除，应视为直接 breaking],
  [`compat.core.new-declaration`], [`note`], [新增公开声明，通常是补充信息，不构成 breaking],
  [`compat.core.deprecated-declaration`], [`note`], [公开声明被标记为 deprecated，应提醒后续治理],
)

=== `go`

#table(
  columns: (34%, 18%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*策略*], [*级别*], [*概要*],

  [`compat.go.pointer-receiver-changed`], [`error`], [pointer receiver 状态变化，可能直接改变调用兼容性],
  [`compat.go.receiver-changed`], [`error`], [receiver 类型变化，可能改变方法集与调用方式],
  [`compat.go.method-set-shrunk`], [`error`], [method set 缩小，调用方可见能力减少],
  [`compat.go.method-set-expanded`], [`warning`], [method set 扩大，通常不是直接 breaking，但需要 review],
  [`compat.go.signature-changed`], [`warning`], [Go 公开签名变化，调用方可能需要修改代码],
)

=== `rust`

#table(
  columns: (34%, 18%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*策略*], [*级别*], [*概要*],

  [`compat.rust.became-unsafe`], [`error`], [公开 Rust item 变成 `unsafe`，调用方审计义务增加],
  [`compat.rust.extern-abi-added`], [`error`], [新增 extern ABI，ABI contract 发生外显变化],
  [`compat.rust.extern-abi-changed`], [`error`], [extern ABI 发生变化，通常视为 breaking],
  [`compat.rust.where-clause-changed`], [`warning`], [where clause 改变，泛型约束可能更严格],
  [`compat.rust.signature-changed`], [`warning`], [Rust 公开签名变化，调用方可能需要修改代码],
)

=== `terraform`

#table(
  columns: (34%, 18%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*策略*], [*级别*], [*概要*],

  [`compat.terraform.provider-ref-changed`], [`error`], [provider reference 变化，部署语义可能直接变化],
  [`compat.terraform.prevent-destroy-added`], [`warning`], [新增 `prevent_destroy`，资源生命周期限制更严格],
  [`compat.terraform.create-before-destroy-added`], [`warning`], [新增 `create_before_destroy`，生命周期顺序变化],
  [`compat.terraform.ignore-changes-expanded`], [`note`], [`ignore_changes` 扩大，更多 drift 会被忽略],
  [`compat.terraform.lifecycle-changed`], [`warning`], [其余 lifecycle 变化，提示需要人工 review],
  [`compat.terraform.input-became-required`], [`error`, stage-2], [输入变量从 optional 变成 required，调用方配置会失效],
  [`compat.terraform.output-removed`], [`error`, stage-2], [output 被移除，下游引用会失效],
)

=== `openapi`

#table(
  columns: (34%, 18%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*策略*], [*级别*], [*概要*],

  [`compat.openapi.http-method-changed`], [`error`], [operation 的 HTTP method 改变，客户端调用语义直接变化],
  [`compat.openapi.became-required`], [`error`], [请求字段或参数变成 required，客户端请求可能失效],
  [`compat.openapi.status-codes-added`], [`warning`], [新增状态码，客户端分支处理可能需要 review],
  [`compat.openapi.media-types-added`], [`note`], [新增 media type，通常是信息性扩展],
  [`compat.openapi.operation-changed`], [`warning`], [其余 operation 变化，提示需要人工 review],
  [`compat.openapi.response-status-removed`], [`error`, stage-2], [响应状态码被移除，客户端兼容性受影响],
  [`compat.openapi.response-schema-narrowed`], [`error`, stage-2], [响应 schema 收窄，客户端解析可能失败],
)

=== `component`

#table(
  columns: (34%, 18%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*策略*], [*级别*], [*概要*],

  [`compat.component.version-upgrade`], [`warning`], [software component 版本变化，需要 review 其外部兼容性影响],
  [`compat.component.metadata-changed`], [`warning`], [component metadata 变化，提示需要人工 review],
)

= 当前 repo reality（非规范说明）

当前 repo 已经基本实现上面的 target design；当前仍需继续推进的主要是 pre-release 收口，而不是规则能力缺口：

- `policy.rules.json` 已按 generated catalog artifact 输出，只保留 `id/family/defaultLevel/summary/docs/entrypoint`；
- 当前运行时不会读取 `policy.rules.json` 里的 selector 信息；真正参与执行的是 Rego 返回的 decision objects；
- `policy.rules.json` 中的 entrypoint 继续使用 `data.codeiq.compat.deny` 形式，而 bundle manifest 使用 `codeiq/compat/deny` 形式；二者指向同一条 Rego entrypoint；
- A002-5 的剩余工作集中在 docs / progress / acceptance wording 持续对齐。

= 验证与落地阶段

#table(
  columns: (14%, 16%, 28%, 42%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Stage*], [*状态*], [*范围*], [*验收结果*],

  [`A002-1`], [#strong[completed]], [contract + authoring + deliverables], [冻结 `semanticDiff.findings[]` canonical contract、`data.codeiq.compat.deny`、Rego vs catalog 角色分离、deliverables 与最小 `policy.rules.json`],
  [`A002-2`], [#strong[completed]], [core + Go / Rust built-ins], [`compat.core.*`、`compat.go.*`、`compat.rust.*` stage-1 rules 与 catalog 已完成],
  [`A002-3`], [#strong[completed]], [OPA input enrichment], [`beforeRecord` / `afterRecord`、richer component evidence、catalog ↔ SARIF reconciliation 与 built-in acceptance 已完成],
  [`A002-4`], [#strong[completed]], [Terraform / OpenAPI deeper rules], [stage-2 Terraform / OpenAPI breaking rules 与 regression fixtures 已完成],
  [`A002-5`], [#strong[completed]], [catalog / docs / tests], [generated catalog、docs、schema/tests 与 SARIF acceptance 收口已完成],
)

= 非目标

- hosted policy registry / remote policy fetch / distributed evaluation；
- trust verifier / KMS / remote signature validation；
- path-based suppression、wildcard family overrides、remote policy layering；
- 任何为了未发布产品而保留的“兼容 alias”字段。

= 当前阶段结论

A002 的核心不是重新发明 policy runtime，而是把当前已经存在的 #strong[Rego source files + OPA bundle + check + SARIF] 主线提升为稳定规则库。修订后的关键结论是：

- declaration selector 只保留 `semanticDiff.findings[].code`；
- Rego 是唯一 executable policy；
- `policy.rules.json` 是 generated catalog artifact，不是第二套策略语言；
- pre-release 阶段直接删掉不必要的兼容字段与重复元数据。

这样，评审和实现都能围绕同一组最小 contract 工作，而不会被 `semanticCategory`、重复字段和双轨匹配方式继续拖累。
