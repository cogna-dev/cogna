#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：单机工作流与内置 OPA 兼容性策略计划",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    CodeIQ 当前已经完成单机 Local Registry、SBOM foundation、provider semantic depth 与 OPA diff enrichment 的主线收口。接下来的 active plan 不再回到 trust verifier、remote registry 或 distributed productization，而是基于现有 `CIQ OPA Bundle`、`check --policy`、`semanticDiff` / `componentDiff` 与最小 SARIF runtime，推进 #strong[A002：内置 OPA 规则集]。这一阶段的目标，是把当前仍停留在浅层 `added/changed/removed/deprecated` 的默认规则，升级为覆盖 Go、Rust、Terraform 与 OpenAPI 的稳定 built-in OPA rules baseline，同时把用户文档继续收敛为 Divio 四象限结构，并保持所有对外说明与 repo reality 一致。
  ],
  keywords: (
    "CodeIQ",
    "Plan",
    "OPA",
    "Compatibility",
    "SARIF",
    "Local Registry",
    "MCP",
  ),
  date: "March 27, 2026",
)

= 当前 active boundary

从当前版本开始，CodeIQ 的 active boundary 固定为：#strong[单机 CLI + Local Registry + local query runtime]。

- #strong[单机优先]：`init / build / diff / check / query / publish / registry / mcp` 都服务于单台机器上的本地工作流；
- #strong[共享本地存储]：CLI、Local Registry 与 MCP 共享同一套本地 bundle store，而不是面向 hosted / distributed deployment；
- #strong[本地策略执行]：`check` 继续使用本地 `opa eval --bundle ... data.codeiq.compat.deny`，不引入 hosted policy runtime；
- #strong[继续推进语义治理]：后续主线集中在 semantic diff、built-in policy、SARIF 可解释性和用户文档，而不是远端签名与多节点治理；
- #strong[文档分层]：用户文档按 Divio 四象限组织，贡献者文档承接架构边界、计划与 proposal 对账。

= 当前 repo 基线（可复用，不回退）

#table(
  columns: (18%, 18%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*能力*], [*状态*], [*当前结论*], [*关键证据*],

  [`workflow + CIQ artifacts`], [#strong[已完成]], [`init → build → diff → check → query` 与 `publish / registry / mcp` 已形成单机 baseline], [`src/cmd/main/main.mbt`；`src/cmd/build/main_test.mbt`；`src/cmd/diff/main_test.mbt`；`src/cmd/check/main_test.mbt`；`src/cmd/query/main_test.mbt`],

  [`CIQ Bundle / CIQ OPA Bundle`], [#strong[已完成，可复用]], [`build` 已稳定产出 `ciq-bundle/v1` 与 `ciq-opa-bundle/v1`；`policy-bundle` 已进入 config/runtime contract], [`src/config/schema.mbt`；`src/cmd/build/main.mbt`；`src/cmd/build/main_test.mbt`],

  [`Local Registry baseline`], [#strong[已完成，可复用]], [本地 publish / resolve / versions / detail / download 与 loopback HTTP server 已闭环，产品边界明确为 local private registry], [`src/registry/server.mbt`；`src/cmd/registry/main.mbt`；`src/cmd/publish/main.mbt`；`src/e2e/registry_test.mbt`],

  [`MCP local query runtime`], [#strong[已完成，可复用]], [`mcp start / serve / status / stop` 已切到本地 JSON-RPC runtime，并暴露 `codeiq.query.outlines` / `codeiq.query.symbol` / `codeiq.runtime.context`], [`src/cmd/mcp/core/main.mbt`；`src/cmd/mcp/main_test.mbt`；`src/e2e/review/main_test.mbt`],

  [`semantic diff + policy baseline`], [#strong[已完成，可复用]], [`diff` 已输出 `semanticCategory`、`semanticDiff`、`componentDiff`；`check` 已整形成 OPA-friendly input 并输出最小 SARIF], [`src/cmd/diff/main.mbt`；`src/cmd/check/main.mbt`；`src/schema/contracts.mbt`；`src/cmd/check/main_test.mbt`],

  [`built-in default policy rules`], [#strong[过浅，待升级]], [当前 `policy.rules.json` 仍只有 `compat.removed/changed/deprecated/added-public-api` 四条浅层规则，无法承接 Go / Rust / Terraform / OpenAPI richer semantic categories], [`src/cmd/build/main.mbt`；`src/cmd/build/main_test.mbt`],

  [`docs information architecture`], [#strong[已完成 baseline，需继续充实]], [用户文档已按 Divio 四象限收口，但仍需继续补足 proposal 中对用户仍有价值的命令、产物、流程和边界信息], [`docs/src/pages/index.astro`；`docs/src/pages/docs/index.astro`；`docs/src/content/docs/*`],
)

= 范围收敛后的硬约束

- #strong[唯一 authoritative storage 继续收敛到本地 cache / registry store]；
- #strong[Local Registry 只是共享本地 bundle store 的 façade，不是 hosted product]；
- #strong[`check` 继续以本地 `opa eval --bundle ... data.codeiq.compat.deny` 为唯一 active runtime]；
- #strong[新 policy 设计必须优先消费当前已经存在的 `semanticCategory` / `semanticDiff` / `componentDiff`]；
- #strong[同一时刻只有一个 active detailed item；完成项和未来项保持 summary-only]；
- #strong[用户文档必须优先描述 repo reality，而不是 proposal 中更宽的 aspiration wording]。

= Delivery ledger（按当前边界重排）

#table(
  columns: (18%, 18%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Item*], [*状态*], [*范围*], [*当前结论*],

  [`R11`], [#strong[completed]], [`Local-Only Storage + SBOM Foundation`], [共享本地 store、SBOM foundation、bundle integration 与 docs sync 已完成],
  [`R12`], [#strong[completed]], [`Provider Semantic Depth + CIQ Schema Richness`], [provider semantic depth、consumer readiness 与 richer declaration transport 已完成],
  [`R13`], [#strong[completed]], [`OPA Diff Enrichment`], [`semanticCategory` / `semanticDiff` / `componentDiff`、OPA input shaping 与 SARIF enrichment 已完成闭环],
  [`A002`], [#strong[active]], [`Built-in OPA Rules`], [下一阶段主线：把当前 shallow default policy rules 升级为 Go / Rust / Terraform / OpenAPI built-in OPA rules baseline，并同步 docs / dashboard],
)

== R11：Local-Only Storage + SBOM Foundation（completed summary）

- `.codeiq/cache/*` 与 Local Registry baseline 已成为当前 bundle materialization / sharing 的 authoritative local surface；
- `software-components.ndjson`、`sbom.cdx.json`、`sbom.spdx.json` 已成为 bundle contract 的稳定组成部分；
- trust verifier、remote registry、distributed / hosted wording 已退出 active plan。

== R12：Provider Semantic Depth + CIQ Schema Richness（completed summary）

- Go / Rust / Terraform / OpenAPI 的 richer declaration facts 已稳定落到 `shape`、`relations` 与 `language_specific` additive contract；
- `build`、`bundle reader`、`query` 与 `diff` 已形成接收 / 透传 / 比较 richer payload 的 consumer baseline；
- `beforeRecord` / `afterRecord` 已可作为 `ciq-diff/v1` richer evidence handoff。

== R13：OPA Diff Enrichment（completed summary）

- `diff` 已对 declaration changes 输出 `semanticCategory` 与 `semanticDiff`，并对 component changes 输出 `componentDiff`；
- `check` 已把 diff 整形成 OPA-friendly envelope（`changes` + `componentChanges`），并输出 local minimal SARIF v2.1.0；
- 当前 policy runtime 已可消费本地 `CIQ OPA Bundle`，但 built-in 默认规则仍停留在 shallow baseline。

= A002：Built-in OPA Rules（active）

A002 的目标不是重新设计 policy runtime，而是：#strong[把当前 repo 已经存在的 `policy-bundle + opa eval + semantic diff + SARIF` 主线，提升为真正可工程化消费的 built-in OPA rules baseline]。

== 为什么 A002 是下一阶段 active item

#table(
  columns: (22%, 18%, 60%),
  inset: 6pt,
  stroke: 0.4pt,
  [*锚点*], [*当前状态*], [*A002 响应*],

  [`policy-bundle profile`], [#strong[已实现]], [继续沿用 `ciq-opa-bundle/v1` 与 `codeiq/compat/deny` manifest contract，把 built-in rules 做成 canonical baseline],
  [`check runtime`], [#strong[已实现]], [继续使用 `opa eval --bundle ... data.codeiq.compat.deny`，不引入 hosted 或 remote policy evaluation],
  [`semanticDiff match surface`], [#strong[待统一]], [当前 diff 已有 enriched evidence；A002 的下一步是把 canonical match surface 收敛到 `semanticDiff.findings[]`，并清理不必要的重复 selector],
  [`policy.rules.json`], [#strong[过浅]], [把当前四条浅层规则升级为 generated rule catalog，最小化字段并与 Rego authoring source 保持同源],
  [`SARIF mapping`], [#strong[已实现 baseline]], [继续保持 `rule_id` / `level` / `message` / `path` / `docs` → SARIF 的稳定映射，不发明第二套 report format],
)

== A002 总体验收标准

- #strong[规则 taxonomy 冻结]：至少覆盖 `compat.core.*`、`compat.go.*`、`compat.rust.*`、`compat.terraform.*`、`compat.openapi.*`、`compat.component.*`；
- #strong[输入契约稳定]：stage-1 规则直接消费当前 `prepare_opa_input(diff)` 结构，stage-2 richer rules 只以 additive input 扩展推进；
- #strong[输出契约稳定]：policy decision object 至少稳定承载 `rule_id`、`level`、`message`，并带 `path` / `docs` 作为 report enrichment；
- #strong[docs 与 dashboard 对齐]：用户文档明确当前 local-only boundary、supported ecosystems、policy-bundle 用法与 built-in baseline 方向；
- #strong[不回退 scope]：不把 trust verifier、remote registry、distributed replication 重新拉回 active plan。

== A002 stage ledger

#table(
  columns: (14%, 16%, 30%, 40%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Stage*], [*状态*], [*范围*], [*验收结果*],

  [`A002-1`], [#strong[completed]], [design freeze + spec authoring], [`spec/A002-opa-builtin-rules.typ` 冻结 `semanticDiff.findings[]` canonical contract、`data.codeiq.compat.deny`、Rego vs catalog 分工、deliverables 与 stage rollout],
  [`A002-2`], [#strong[active]], [core + Go / Rust built-ins], [把 shallow built-in rules 升级为 `compat.core.*`、`compat.go.*`、`compat.rust.*` stage-1 baseline，并同步 tests / docs],
  [`A002-3`], [pending], [OPA input enrichment], [把 `beforeRecord` / `afterRecord` 与 richer component evidence 以 additive 方式加入 OPA input],
  [`A002-4`], [pending], [Terraform / OpenAPI deeper rules], [在 richer input ready 后实现 `compat.terraform.*` 与 `compat.openapi.*` stage-2 rules],
  [`A002-5`], [pending], [override / catalog / acceptance], [完成 exact-rule overrides、catalog/docs 对齐与 SARIF acceptance regression],
)

=== A002-2：core + Go / Rust built-ins（active detailed checklist）

- #strong[目标]：把 `default_policy_rules()` 当前输出的四条 shallow 规则，升级为与 `semanticDiff.findings[]` 对齐的 built-in OPA rules baseline；
- #strong[必须交付]：
  - built-in rule ids 至少覆盖 `compat.core.removed-declaration`、`compat.core.new-declaration`、`compat.core.deprecated-declaration`、`compat.go.*`、`compat.rust.*`；
  - `policy.rules.json` 升级为真正的 generated rule catalog，而不是仅按 `kind` 分类的浅层目录；
  - stage-1 built-in rules 统一通过 `findings[]` 匹配 normalized codes，而不是混用 top-level `semanticCategory` 与 raw `changedFields`；
  - `build` / `check` tests 明确验证新的 rule ids、docs/helpUri 与 built-in catalog contract；
  - 用户文档解释当前 built-in baseline 仍是 local-only policy library，而不是 hosted policy service。
- #strong[实现原则]：
  - 优先匹配 `semanticDiff.findings[]` 中的 normalized codes；
  - 允许一个 change 因多个 findings 产出多条 policy result，但 generic shared rule 必须通过 selector 避免与更具体的 ecosystem rule 重复；
  - 保持 `error / warning / note` severity model 与当前 SARIF runtime 一致；
  - 继续让 `check --policy <bundle>` 成为用户侧显式入口，不在本阶段扩展自动 alias resolution。
- #strong[通过标准]：
  - `policy-bundle` build artifact 与 `policy.rules.json` contract 升级后仍满足 `ciq-opa-bundle/v1`；
  - `check` 产出的 SARIF `ruleId` / `helpUri` 与 built-in catalog 一致；
  - 新文档与 progress dashboard 只把 `A002-2` 作为 detailed active stage，已完成与未来阶段保持 summary-only。

=== A002-3：OPA input enrichment（summary-only）

- 仅在 `A002-2` built-in baseline 稳定后推进；
- 目标是把 `beforeRecord` / `afterRecord` 与 richer component evidence 直接暴露给 OPA，以支撑 Terraform / OpenAPI deeper rules；
- 不改变当前 `check` 命令入口和 OPA entrypoint。

=== A002-4：Terraform / OpenAPI deeper rules（summary-only）

- 依赖 richer input ready；
- 重点覆盖 `input became required`、`output removed`、`response status removed`、`response schema narrowed` 等更深 breaking judgement；
- 保持 `findings[] first`，只在需要时读取 before/after contract evidence。

=== A002-5：override / catalog / acceptance（summary-only）

- 仅支持 exact rule id 级别的 disable / level override；
- 完成 built-in catalog、docs、schema/tests 与 SARIF acceptance 收口；
- 不引入 wildcard family override、path-level suppression 或 remote policy layering。

= Proposal 对账（proposal → implementation reconciliation）

`spec/proposal.typ` 继续保留项目申报、问题定义、场景叙事与术语价值；但当前 active plan 以 #strong[实现 + schema + tests + docs] 为准，尤其不能再把更宽的 registry / trust / hosted / distributed wording 读成当前承诺。

#table(
  columns: (20%, 16%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Proposal surface*], [*状态*], [*当前对账结论*], [*关键证据*],

  [`CIQ Config`], [#strong[implemented differently]], [proposal 中 `profile` 只列四个生态；当前 schema 已把 `policy-bundle` 纳入正式 contract], [`src/config/schema.mbt`；`src/cmd/build/main.mbt`],

  [`CIQ Bundle / declaration contract`], [#strong[implemented differently]], [proposal 中把 `shape` 写作 reserved-for-future-design；当前 repo 已把 `shape`、`relations` 与 `language_specific` 落成 additive declaration contract], [`src/schema/declarations.mbt`；`src/cmd/build/extractor.mbt`；`src/cmd/query/main.mbt`],

  [`CIQ OPA Bundle`], [#strong[implemented differently]], [proposal 用更宽的 OPA / policy distribution narrative；当前 repo reality 是本地 `ciq-opa-bundle/v1` + `opa eval --bundle ... data.codeiq.compat.deny`], [`src/cmd/build/main.mbt`；`src/cmd/check/main.mbt`],

  [`CIQ Diff`], [#strong[implemented differently]], [proposal 样例仍以浅层 `kind` / `level` 为主；当前 `R13` 已稳定输出 `semanticCategory`、`semanticDiff`、`componentDiff` 与 richer handoff evidence], [`src/cmd/diff/main.mbt`；`src/schema/contracts.mbt`；`src/cmd/diff/main_test.mbt`],

  [`SARIF`], [#strong[implemented differently]], [当前 repo 承诺的是 #strong[local minimal SARIF v2.1.0 output]，由 diff + policy runtime 合成，而不是 hosted ingestion promise], [`src/cmd/check/main.mbt`；`src/cmd/check/main_test.mbt`],

  [`Local Registry`], [#strong[partially implemented]], [当前产品边界只能表述为 local private registry / local cache / shared local store，不应再写成 hosted registry capability], [`src/registry/server.mbt`；`src/cmd/registry/main.mbt`；`src/cmd/publish/main.mbt`],

  [`MCP Agent`], [#strong[implemented differently]], [当前实现是 single-machine local query runtime，稳定工具面为 `codeiq.query.outlines` / `codeiq.query.symbol` / `codeiq.runtime.context`], [`src/cmd/mcp/core/main.mbt`；`src/cmd/mcp/core/main_test.mbt`],

  [`Built-in policy baseline`], [#strong[active gap，正在推进]], [proposal 只说明 `CIQ OPA Bundle` 的一般形态；A002 正把它落为覆盖多生态的 canonical built-in rules baseline], [`spec/A002-opa-builtin-rules.typ`；`src/cmd/build/main.mbt`；`src/cmd/check/main.mbt`],
)

- #strong[Planning rule]：后续 active item 一律以 repo 中已验证的 schema / implementation / tests / docs 为准；
- #strong[Documentation rule]：用户文档继续保留 proposal 中对用户仍有价值的目标、流程、命令、产物与边界信息，但不承诺 repo 尚未实现的 hosted / distributed capability；
- #strong[Terminology rule]：Registry 统一写作 local private registry / local cache，MCP 统一写作 local query runtime，SARIF 统一写作 local minimal SARIF v2.1.0 output。

= Non-goals（当前明确不做）

- #strong[trust verifier / trust root / key rotation / KMS]；
- #strong[remote registry / hosted registry / distributed replication / multi-node HA]；
- #strong[把 remote auth / transport hardening 重新拉回主线 roadmap]；
- #strong[把 MCP 扩展成 build / diff / check / publish 的替代入口]；
- #strong[在 A002 中引入 path-based suppression、wildcard family overrides 或 remote policy layering]。

= 当前阶段结论

R11–R13 已经把 CodeIQ 的单机工作流、SBOM、semantic diff 与本地 policy runtime 基线收口。当前 active plan 因此不再追求更宽的 hosted / trust / distributed 叙事，而是把下一阶段清晰收束为 #strong[A002 built-in OPA compatibility library]：先把 stage-1 built-ins、rule catalog、docs 与 dashboard 对齐，再逐步推进 richer input 和 Terraform / OpenAPI deeper rules。
