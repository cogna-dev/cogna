#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：单机 Local Registry、SBOM 与语义深度计划",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    CodeIQ 当前不再把 trust verifier、hosted registry、distributed distribution 或多节点 productization 作为产品方向。新的产品范围被固化为 #strong[单机 CLI + Local Registry]：CLI、Local Registry 与 MCP 共享同一套本地 bundle store，并以 `src/lib/sbom/*` 为新的组件分析基础层，从源码与包管理器文件提取标准化软件成分，导出 CycloneDX / SPDX，并基于软件成分与声明事实共同构建 bundle。在这一新范围下，后续主线不再是 remote / trust / hosted hardening，而是 #strong[共享本地存储收敛]、#strong[SBOM foundation]、#strong[provider semantic depth + CIQ schema richness] 与 #strong[OPA diff enrichment]。
  ],
  keywords: (
    "CodeIQ",
    "Plan",
    "Local Registry",
    "SBOM",
    "CycloneDX",
    "SPDX",
    "OPA",
  ),
  date: "March 26, 2026",
)

= 产品范围重置

从当前版本开始，CodeIQ 的产品边界改为：

- #strong[单机优先]：只面向单台机器上的 CLI、Local Registry 与 MCP 工作流；
- #strong[单一共享存储]：本地 bundle cache 目录是唯一 authoritative storage，CLI / Local Registry / MCP 共享同一套本地 bundle store；
- #strong[不再支持 trust verifier]：不再把签名校验、trust root、KMS、verified/untrusted policy 视为产品范围；
- #strong[不再支持 distributed / hosted]：不再把 remote registry、分布式同步、多节点 HA、hosted deployment 视为目标能力；
- #strong[新增 `src/lib/sbom/*`]：从源码与包管理器文件抽取标准化软件成分，支持 CycloneDX / SPDX 导出，并把软件成分信息纳入 bundle 构建输入；
- #strong[继续推进语义与 policy]：在本地产品边界内，继续推进 provider semantic depth、CIQ schema richness 与 OPA diff。

= 当前 repo 基线（可复用，不回退）

#table(
  columns: (18%, 18%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*能力*], [*状态*], [*当前结论*], [*关键证据*],

  [`workflow + CIQ artifacts`], [#strong[已完成]], [`init/build/diff/check/query`、CIQ Bundle / Diff / Result 与最小 SARIF 已形成稳定 repo baseline], [`src/cmd/main/main.mbt`；`src/cmd/build/main_test.mbt`；`src/cmd/diff/main_test.mbt`；`src/cmd/check/main_test.mbt`；`src/cmd/query/main_test.mbt`；`src/e2e/init_test.mbt`],

  [`provider extraction baseline`], [#strong[已完成，可复用]], [Go / Rust / Terraform / OpenAPI 都已有 extractor、snapshot 与 e2e 证据，但当前仍停留在 baseline extraction，而非 richer semantic depth], [`src/cmd/build/extractor.mbt`；`src/schema/declarations.mbt`；`src/cmd/build/snapshot_test.mbt`；`src/e2e/lsp_extractor_test.mbt`；`examples/*/full/snapshots/lsp/*`],

  [`Local Registry baseline`], [#strong[已完成，可复用]], [本地 publish / resolve / versions / detail / download 与 loopback HTTP 证据已存在，但当前 authoritative store 仍分裂在 `.codeiq/registry/*` 与 `.codeiq/cache/registry/*`], [`src/registry/storage.mbt`；`src/lib/registry/client.mbt`；`src/registry/server.mbt`；`src/cmd/registry/main_test.mbt`；`src/e2e/registry_test.mbt`；`src/e2e/registry_server_test.mbt`],

  [`MCP local query runtime`], [#strong[已完成，可复用]], [`mcp start / status / stop / serve` 已切到真实 HTTP JSON-RPC runtime，并提供 `codeiq.query.outlines` / `codeiq.query.symbol`], [`src/lib/mcp-sdk/*`；`src/lib/server-runtime/*`；`src/cmd/mcp/main.mbt`；`src/cmd/mcp/core/main.mbt`；`src/cmd/mcp/main_test.mbt`；`src/cmd/mcp/core/main_test.mbt`],

  [`policy + diff baseline`], [#strong[已完成，可复用]], [`diff` / `check` / `CIQ OPA Bundle` 已可用，但当前仍是 `dist/base|target` + `opa eval --bundle ... data.codeiq.compat.deny` baseline], [`src/cmd/diff/main.mbt`；`src/cmd/check/main.mbt`；`src/schema/contracts.mbt`；`src/cmd/check/main_test.mbt`],

  [`legacy remote / trust machinery`], [#strong[legacy，待退出 active scope]], [repo 里仍保留 `CODEIQ_REGISTRY_BASE_URL`、remote/inproc transport、OpenSSL verifier 与 hosted wording；它们是迁移输入，不再是产品目标], [`src/lib/registry/client.mbt`；`src/lib/registry/main.mbt`；`src/cmd/publish/main.mbt`；`docs/src/content/docs/cli.mdx`；`spec/proposal.typ`],
)

= 范围收敛后的硬约束

- #strong[唯一 authoritative storage 收敛到 `.codeiq/cache/*`]；
- #strong[Local Registry 只是共享本地 bundle store 的命令 / HTTP façade，而不是独立产品]；
- #strong[不再把 trust verifier / trust root / KMS 写入 active plan]；
- #strong[不再把 remote / hosted / distributed support 写入 active plan]；
- #strong[新的实现代码继续落在 `src/` 下，因此 SBOM library 规划为 `src/lib/sbom/*`]；
- #strong[同一时刻只有一个 active release；只有当前 active release 保留详细执行清单]。

= Release ledger（按新产品范围重排）

#table(
  columns: (18%, 18%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Release*], [*状态*], [*范围*], [*当前结论*],

  [`R5`], [#strong[completed]], [`Core Workflow Complete`], [`init → build → diff → check → query` 的 repo baseline 已闭环],
  [`R6`], [#strong[completed]], [`Single-Machine Registry Baseline`], [本地 publish / registry baseline 已形成可回归闭环],
  [`R7`], [#strong[completed]], [`Provider Baseline Coverage`], [provider evidence matrix 已冻结为 baseline 证据],
  [`R8`], [#strong[completed]], [`历史 trust/verifier baseline`], [历史 shell verifier / trust hardening 已完成，但不再继续作为产品方向],
  [`R9`], [#strong[completed]], [`历史 remote/security baseline`], [历史 remote auth / transport gate baseline 已完成，但不再继续作为产品方向],
  [`R10`], [#strong[completed]], [`Local Server Capability & Shared Framework Extraction`], [MCP / Registry 本地 server capability、共享框架抽取与 zstd 移除已完成],
  [`R11`], [#strong[completed]], [`Local-Only Storage + SBOM Foundation`], [共享本地 bundle store、SBOM foundation、bundle integration 与 docs sync 已完成],
  [`R12`], [#strong[completed]], [`Provider Semantic Depth + CIQ Schema Richness`], [provider semantic depth、consumer readiness 与 R13 handoff 已完成],
  [`R13`], [#strong[completed]], [`OPA Diff Enrichment`], [semantic diff、component diff、OPA input shaping 与 SARIF enrichment 已完成闭环],
)

== R11：Local-Only Storage + SBOM Foundation（completed summary）

- #strong[Completed outcomes]：
  - `.codeiq/cache/registry/*` 已成为 CLI / Local Registry / MCP 共用的 authoritative local store；
  - trust verifier、remote registry 与 distributed / hosted wording 已从 active implementation 与 docs surface 移出；
  - `src/lib/sbom/*` 已提供 component model、source + package-manager collection，以及 CycloneDX / SPDX exporter；
  - build / bundle / query / diff 已消费 `software-components.ndjson`、`sbom.cdx.json`、`sbom.spdx.json`；
  - active docs / dashboard / proposal 已按单机 Local Registry 范围同步。

== R12：Provider Semantic Depth + CIQ Schema Richness（completed summary）

- #strong[Release focus]：把当前 `signature + shape + language_specific` baseline 推进到可稳定落盘、可被 query / diff / bundle reader 接受、并能为 R13 的 OPA diff 提供输入的 richer semantics；
- #strong[Release principles]：
  - 保持 `id / kind / path / signature / location` 作为当前 declaration identity / matching contract；
  - 新语义优先以 #strong[additive] 方式落到 `shape`、`relations` 与 `language_specific`，避免破坏现有 bundle / query / diff 主链路；
  - 每个 slice 都必须同时更新 #strong[schema + extractor + examples snapshots + tests + active docs]；
  - `R12` 只解决 richer facts 与 consumer readiness，不把 declaration semantic diff / SBOM semantic diff 的完整 policy 判定提前到 `R13`。

#table(
  columns: (12%, 14%, 30%, 44%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Stage*], [*状态*], [*范围*], [*当前结论*],

  [`R12-1`], [#strong[completed]], [`Terraform provider semantic depth`], [Terraform `provider` / `required_providers` / `resource` / `data` 已具备 `uses_provider` / `provided_by` relation，以及 `language_specific.providers.terraform[*]` 的 `name` / `source` / `version` / `alias` contract],

  [`R12-2`], [#strong[completed]], [`Shared CIQ schema enrichment + relation-depth foundation`], [shared `shape` / `relations` / `language_specific` foundation、bundle/query/diff consumer readiness 与 richer snapshots/tests 已完成收口],

  [`R12-3`], [#strong[completed]], [`Go semantic depth`], [receiver、pointer receiver、embedding、method ownership、method set 与 type relation 已提升为稳定 declaration facts，并完成 snapshots/tests/docs 收口],

  [`R12-4`], [#strong[completed]], [`Rust semantic depth`], [trait / impl、associated item、generic、where clause、unsafe / extern 与 ownership/relations 已提升为稳定 additive declaration facts],

  [`R12-5`], [#strong[completed]], [`Terraform contract depth`], [variable/output/module/lifecycle/meta-argument 的 parser-first contract semantics 已提升为稳定 additive declaration facts，并完成 snapshots/tests/docs 收口],

  [`R12-6`], [#strong[completed]], [`OpenAPI semantic depth`], [parameter location / requiredness、request/response media types、statusCodes、discriminator mapping、composition member refs 与 callback/security parser-first contract 已完成收口],

  [`R12-7`], [#strong[completed]], [`Consumer readiness + R13 handoff`], [`ciq-result` / `ciq-diff` handoff surface 已明确，richer declarations 已可被 bundle / query / diff 稳定 transport，并把 semantic interpretation 清晰移交给 `R13`],
)

=== R12-1：Terraform provider semantic depth（completed summary）

- #strong[Goal]：在不改变当前 declaration stable identity 的前提下，把 Terraform provider-level facts 从 snapshot evidence 提升为 schema-backed contract；
- #strong[Completed outcomes]：
  - `src/schema/declarations.mbt` 已接受 `uses_provider` / `provided_by` relation；
  - `language_specific.providers.terraform[*]` 已支持 `name`、`source`、`version`、`alias`；
  - `src/cmd/build/extractor.mbt` 已把 `required_providers`、`provider`、`resource`、`data` 连接成 provider-aware facts；
  - `src/schema/declarations_test.mbt`、`src/e2e/lsp_extractor_test.mbt` 与 `examples/terraform-module/full/snapshots/lsp/*` 已形成验证闭环。
- #strong[Passed verify]：
  - `moon test src/schema/declarations_test.mbt --target wasm -v`
  - `moon test src/e2e/lsp_extractor_test.mbt --target wasm -v`
  - `moon test src/cmd/build/snapshot_test.mbt --target wasm -v`
  - `moon test src/cmd/build/main_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon check`

=== R12-2：Shared CIQ schema enrichment + relation-depth foundation（completed summary）

- #strong[Goal]：为 Go / Rust / Terraform / OpenAPI 的后续 richer semantics 建立统一、可验证、向后兼容的 declaration contract foundation；
- #strong[Completed outcomes]：
  - declaration schema 与 result contract 已稳定接受 shared richer `shape` / `language_specific` payload，并保持 `id / kind / path / signature / location` stable identity 不变；
  - `src/cmd/build/extractor.mbt` 已把 Go / Rust / Terraform / OpenAPI 的 shared richer facts 落到稳定 snapshots，修正了一轮 heuristic 偏差；
  - `src/cmd/bundle/reader.mbt`、`src/cmd/query/main.mbt`、`src/cmd/diff/main.mbt` 已形成“接受 / 透传 / 比较” richer declaration payload 的 consumer baseline；
  - `src/schema/declarations_test.mbt`、`src/schema/contracts_test.mbt`、`src/cmd/query/main_test.mbt`、`src/cmd/diff/main_test.mbt`、`src/cmd/bundle/reader_test.mbt`、`src/e2e/lsp_extractor_test.mbt` 与 `examples/*/full/snapshots/lsp/*` 已形成 shared foundation 验证闭环。
- #strong[Passed verify]：
  - `moon test src/schema/declarations_test.mbt --target wasm -v`
  - `moon test src/schema/contracts_test.mbt --target wasm -v`
  - `moon test src/cmd/build/snapshot_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/e2e/lsp_extractor_test.mbt --target wasm -v`
  - `moon check`

=== R12-3：Go semantic depth（completed summary）

- #strong[Goal]：把 Go 当前 examples 中已经存在的 receiver、embedding、generic 与 method-set 相关语义，从 baseline snapshot 提升为稳定 CIQ facts；
- #strong[Completed outcomes]：
  - `src/cmd/build/extractor.mbt` 已补齐 Go method/function/field 的 richer relation rewrite，并新增 method ownership、embedding index 与 method-set propagation；
  - `src/schema/declarations.mbt` 已接受 `language_specific.go.methodSetTypes`，让 Go method-set 成为 schema-backed contract；
  - `examples/go-module/full/repo/main.go`、`examples/go-module/full/snapshots/lsp/declarations.ndjson` 已补 value receiver fixture 与稳定 golden evidence；
  - `src/e2e/lsp_extractor_test.mbt`、`src/cmd/query/main_test.mbt`、`src/cmd/diff/main_test.mbt`、`src/cmd/bundle/reader_test.mbt` 已覆盖 richer Go facts 的 consumer compatibility。
- #strong[Passed verify]：
  - `moon test src/schema/declarations_test.mbt --target wasm -v`
  - `moon test src/schema/contracts_test.mbt --target wasm -v`
  - `moon test src/cmd/build/snapshot_test.mbt --target wasm -v`
  - `moon test src/e2e/lsp_extractor_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon build`
  - `moon check`

=== R12-4：Rust semantic depth（completed summary）

- #strong[Goal]：把 Rust 当前 baseline 中的 trait / impl / associated item / generic surface 继续提升为稳定、可比较、可 query 的 richer CIQ facts；
- #strong[Completed outcomes]：
  - `src/cmd/build/extractor.mbt` 已补齐 Rust `unsafe` / `externAbi` / richer type params / owner normalization，并新增 Rust postprocess relation rewrite 与 owner/member/implements propagation；
  - `examples/rust-crate/full/repo/lib.rs` 已补 trait impl、lifetime + const-generic、`unsafe fn` 与 `extern "C" fn` fixtures；
  - `examples/rust-crate/full/snapshots/lsp/*` 已刷新为稳定 Rust semantic depth golden evidence，覆盖 trait impl、ownership、`implements` 与 `language_specific.rust` richer facts；
  - `src/schema/declarations_test.mbt`、`src/e2e/lsp_extractor_test.mbt`、`src/cmd/query/main_test.mbt`、`src/cmd/diff/main_test.mbt`、`src/cmd/bundle/reader_test.mbt` 已形成 schema + consumer readiness 验证闭环。
- #strong[Passed verify]：
  - `moon test src/schema/declarations_test.mbt --target wasm -v`
  - `moon test src/schema/contracts_test.mbt --target wasm -v`
  - `moon test src/cmd/build/snapshot_test.mbt --target wasm -v`
  - `moon test src/e2e/lsp_extractor_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon build`
  - `moon check`

=== R12-5：Terraform contract depth（completed summary）

- #strong[Goal]：在已完成 provider slice 的基础上，继续把 Terraform 的 variable / output / module / lifecycle / meta-argument semantics 提升到稳定 declaration contract；
- #strong[Completed outcomes]：
  - `src/cmd/build/extractor.mbt` 已补 variable requiredness、module provider binding、output/meta `depends_on`、以及 lifecycle `preventDestroy` / `createBeforeDestroy` / `ignoreChanges` 的 parser-first richer facts；
  - `src/schema/declarations.mbt` 已接受新增 Terraform lifecycle metadata，保持 `language_specific.terraform` additive contract；
  - `examples/terraform-module/full/repo/main.tf` 与 `examples/terraform-module/full/snapshots/lsp/*` 已补 optional/sensitive variables、sensitive output、module provider binding、resource/module/output depends_on 与 lifecycle golden evidence；
  - `src/schema/declarations_test.mbt`、`src/e2e/lsp_extractor_test.mbt`、`src/cmd/query/main_test.mbt`、`src/cmd/diff/main_test.mbt`、`src/cmd/bundle/reader_test.mbt` 已验证 Terraform richer facts 的 schema 与 consumer compatibility。
- #strong[Passed verify]：
  - `moon test src/schema/declarations_test.mbt --target wasm -v`
  - `moon test src/schema/contracts_test.mbt --target wasm -v`
  - `moon test src/cmd/build/snapshot_test.mbt --target wasm -v`
  - `moon test src/e2e/lsp_extractor_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon build`
  - `moon check`

=== R12-6：OpenAPI semantic depth（completed summary）

- #strong[Goal]：把 OpenAPI 当前已存在的 path / operation / schema baseline，推进到 parameter location、requiredness、media type、explicit statusCodes、discriminator / composition / callback scope 的稳定 declaration contract；
- #strong[Completed outcomes]：
  - `src/cmd/build/extractor.mbt` 已补齐 parameter location / requiredness、requestBody required/mediaTypes、response statusCodes/mediaTypes、callbackExpression、security scheme type/location/name、以及 composition member refs / discriminator mapping 的 parser-first richer facts；
  - `src/schema/declarations.mbt` 已接受 `language_specific.openapi.discriminatorMapping` 与 `memberRefs`，保持 OpenAPI richer contract additive；
  - `examples/openapi-spec/full/repo/openapi/payment.yaml` 与 `examples/openapi-spec/full/snapshots/lsp/*` 已补 callback/webhook response media-type evidence 并刷新 golden snapshots；
  - `src/schema/declarations_test.mbt`、`src/e2e/lsp_extractor_test.mbt`、`src/cmd/query/main_test.mbt`、`src/cmd/diff/main_test.mbt`、`src/cmd/bundle/reader_test.mbt` 已验证 OpenAPI richer facts 的 schema 与 consumer compatibility。
- #strong[Passed verify]：
  - `moon test src/schema/declarations_test.mbt --target wasm -v`
  - `moon test src/cmd/build/snapshot_test.mbt --target wasm -v`
  - `moon test src/e2e/lsp_extractor_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon build`
  - `moon check`

=== R12-7：Consumer readiness + R13 handoff（completed summary）

- #strong[Goal]：确保 richer declaration facts 在 `build`、`bundle reader`、`query`、`diff` 与后续 OPA input 之间形成稳定 handoff，而不会提前把 `R13` 的 semantic diff 责任混入 `R12`；
- #strong[Completed outcomes]：
  - `src/schema/contracts.mbt` 已明确 `ciq-result/v1` 的 additive consumer payload surface，并允许 `ciq-diff/v1` change entries 稳定承载 `beforeRecord` / `afterRecord` handoff evidence；
  - `src/cmd/query/main.mbt` 现在在不改变 selector / matching behavior 的前提下，稳定透传 `path`、`name`、`canonical_name`、`language`、`baselineRole`、`source_refs`、`relations`、`visibility`、`docs`、`shape` 与 `language_specific`；
  - `src/cmd/diff/main.mbt` 继续使用 stable keys 做匹配，但对 `changed` / `added` / `removed` / `deprecated` 输出 additive richer before/after records，供 `R13` 直接消费；
  - `src/schema/contracts_test.mbt`、`src/cmd/query/main_test.mbt`、`src/cmd/diff/main_test.mbt` 与 `src/cmd/bundle/reader_test.mbt` 已形成 consumer-readiness regression coverage，并证明 richer payload 是 transport surface 而非新 identity。
- #strong[R12 → R13 handoff matrix]：
  - stable identity 仍是 `id / kind / path / signature / location`；
  - additive consumer payload 包括 `shape`、`language_specific`、`name`、`canonical_name`、`language`、`baselineRole`、`source_refs`、`relations`、`visibility`、`docs`；
  - `ciq-diff/v1` 的 `beforeRecord` / `afterRecord` 只提供 richer evidence，不在 `R12` 内解释为 semantic policy judgement；
  - provider semantic diff、SBOM diff、OPA input shaping 与 policy interpretation 明确留给 `R13`。
- #strong[Passed verify]：
  - `moon test src/schema/contracts_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon build`
  - `moon check`

== R13：OPA Diff Enrichment（completed summary）

- #strong[Release focus]：消费 `R12` 已交付的 richer declaration / component evidence，推进 declaration semantic diff、provider semantic diff 与 SBOM diff 的统一 policy input；
- #strong[Completed outcomes]：
  - `src/cmd/diff/main.mbt` 已对 changed declarations 输出 `semanticCategory` 与 `semanticDiff`，并对 component changes 输出 `componentDiff`；
  - component diff 现在按稳定 component identity 聚合升级，不再把纯版本升级拆成 remove + add；
  - `src/cmd/check/main.mbt` 已把 diff 整形成 OPA-friendly envelope（`changes` + `componentChanges`），并在 SARIF 中使用 semantic category 与 declaration record location enrichment；
  - `src/schema/contracts.mbt` 已显式接受 `componentDiff`，相关 contract tests 已同步；
  - `src/cmd/check/main_test.mbt` 已验证真实 diff record 的 `location.uri` / `startLine` 会进入 SARIF。
- #strong[Passed verify]：
  - `moon test src/schema/contracts_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/cmd/check/main_test.mbt --target wasm -v`
  - `moon build`
  - `moon check`

= Proposal 对账（proposal → implementation reconciliation）

`spec/proposal.typ` 继续保留项目申报、问题定义与技术叙事价值，但它不再等同于当前 repo 的 active contract。当前计划文档以 #strong[实现 + schema + tests + docs] 为准，并把 proposal 中仍停留在历史样例、aspirational wording 或 broader narrative 的部分显式降格为背景说明。

#table(
  columns: (20%, 16%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Proposal surface*], [*状态*], [*当前对账结论*], [*关键证据*],

  [`CIQ Config`], [#strong[implemented differently]], [proposal 只把 `profile` 写成 `go-module` / `rust-crate` / `terraform-module` / `openapi-spec`；当前 schema 与 build/runtime 已把 `policy-bundle` 纳入正式 contract], [`src/config/schema.mbt`；`src/cmd/build/main.mbt`；`src/cmd/build/main_test.mbt`],

  [`CIQ Bundle / declaration shape`], [#strong[implemented differently]], [proposal 仍把 `shape` 写成 reserved-for-future-design；当前 repo 已把 `shape`、`relations` 与 `language_specific` 落为稳定 additive declaration contract，并被 build / bundle reader / query / diff 共同消费], [`src/schema/declarations.mbt`；`src/cmd/build/extractor.mbt`；`src/cmd/bundle/reader.mbt`；`src/cmd/query/main.mbt`；`src/cmd/diff/main.mbt`],

  [`CIQ OPA Bundle`], [#strong[implemented differently]], [当前 active path 是本地 policy bundle + `opa eval --bundle ...` 的 CLI runtime；proposal 中对 OPA bundle/signature/distribution 的更宽泛叙事不应再被读成当前 release promise], [`src/cmd/check/main.mbt`；`src/cmd/build/main.mbt`；`src/schema/contracts.mbt`],

  [`CIQ Diff`], [#strong[implemented differently]], [proposal 样例仍以浅层 `kind` / `id` / `path` / `level` + `testChanges` 为主；当前 `R13` 基线已经稳定输出 `semanticCategory`、`semanticDiff`、`componentDiff`、`beforeRecord` / `afterRecord` 与 OPA-friendly handoff surface], [`src/cmd/diff/main.mbt`；`src/schema/contracts.mbt`；`src/cmd/diff/main_test.mbt`；`src/cmd/check/main_test.mbt`],

  [`SARIF`], [#strong[implemented differently]], [当前 repo 承诺的是 #strong[本地 minimal SARIF v2.1.0 output]：由 diff + OPA runtime 合成并经最小 schema 校验；proposal 中任何关于 hosted ingestion / broad consumer compatibility 的含义，都不属于当前 active claim], [`src/cmd/check/main.mbt`；`src/cmd/check/main_test.mbt`；`spec/proposal.typ`],

  [`Local Registry`], [#strong[partially implemented]], [本地 publish / versions / detail / download 已闭环，但当前产品边界只能表述为 #strong[local private registry / local cache / shared local store]；proposal 中更宽的 registry narrative 只能作为背景，不再视为 hosted capability 承诺], [`src/registry/storage.mbt`；`src/lib/registry/client.mbt`；`src/cmd/registry/main_test.mbt`；`src/e2e/registry_test.mbt`],

  [`MCP Agent`], [#strong[implemented differently]], [当前实现是 single-machine local HTTP JSON-RPC query runtime，工具面除 `codeiq.query.outlines` / `codeiq.query.symbol` 外还包括 `codeiq.runtime.context`；proposal 中“按依赖自动发现并装载相关 bundle”的说法宽于当前 cache / cwd / PURL materialization 行为], [`src/cmd/mcp/core/main.mbt`；`src/cmd/mcp/core/main_test.mbt`；`src/e2e/review/main_test.mbt`],

  [`PURL terminology`], [#strong[partially implemented]], [repo 继续把 PURL 作为 canonical identifier，但 `pkg:terraform` / `pkg:openapi` 仍应被视为 interoperability-sensitive wording；对外叙述必须保留 proposal 已提到的 `pkg:generic` fallback caveat], [`spec/proposal.typ`；`src/config/schema.mbt`；`src/cmd/build/snapshot_test.mbt`],
)

- #strong[Planning rule]：后续 active release 一律以 repo 中已验证的 schema / tests / docs 为准，不再以 proposal 示例 JSON 或 aspiration wording 直接定义当前 contract；
- #strong[Documentation rule]：继续保留 proposal 的问题定义与技术动机，但所有 reference / dashboard / release ledger 必须优先描述当前 local-only runtime reality；
- #strong[Terminology rule]：Registry 统一写作 local private registry / local cache，MCP 统一写作 local query runtime，SARIF 统一写作 local minimal SARIF v2.1.0 output，避免再把 hosted / remote / broad-ecosystem compatibility 写成当前承诺。

= Non-goals（当前明确不做）

- #strong[trust verifier / trust root / key rotation / KMS]；
- #strong[remote registry / hosted registry / distributed replication / multi-node HA]；
- #strong[把 remote auth / transport hardening 继续作为主线 roadmap]；
- #strong[把 Local Registry 做成独立云产品，而不是本地 façade]。

= 当前阶段结论

CodeIQ 的当前基线已经完成从本地存储收敛、SBOM foundation、provider semantic depth 到 OPA diff enrichment 的主线闭环；proposal 对账后，当前 active plan 也已经明确区分了 repo reality 与 broader narrative。后续 release 应继续在这一单机边界上推进，而不是回到 remote/trust/distributed hardening。
