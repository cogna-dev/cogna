#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：主业务流程优先的下一阶段 Release Plan",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本文重新设计 CodeIQ 的当前 release plan，核心原则是#strong[先闭环主业务流程与 provider 证据面，再处理分发信任链、部署与安全加固]。仓库已经具备 `init → build → diff → check → query → mcp` 的本地工作流、单机 registry baseline 与大量 e2e / unit test 证据，而下一阶段最缺的不是 registry trust，而是#strong[把 Go / Rust / Terraform / OpenAPI 的 provider 能力矩阵完整冻结成 repo 级证据]。新的计划因此把优先级调整为四层：第一层是开发代码提取、分析、审查主流程；第二层是单机 registry + 免认证基线；第三层是 provider matrix coverage；第四层才是 registry 信任链、部署与安全硬化。
  ],
  keywords: ("CodeIQ", "Plan", "Workflow", "Registry", "Providers", "Security"),
  date: "March 24, 2026",
)

= 计划定位

这份计划只回答四个问题：

- #strong[当前最应优先关闭的主业务流程是什么]；
- #strong[单机 registry 与免认证基线应该排在什么位置]；
- #strong[provider 能力矩阵何时收口为 repo 级证据]；
- #strong[哪些 trust / deployment / security 工作必须明确降级到后续 release]。

本计划继续遵循以下硬约束：

- #strong[代码和测试优先于叙述]；
- #strong[Done when 必须是 repo 可验证条件]；
- #strong[同一时刻最多只有一个 active release]；
- #strong[Non-goals 与 Backlog 不得反向阻塞当前 release]。

= 当前可复用基线（不回退）

#table(
  columns: (20%, 18%, 26%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*能力*], [*状态*], [*当前结论*], [*关键证据*],

  [`init/build/diff/check/query`], [#strong[本地基线已形成]], [主业务流程已经存在 repo 级命令实现与 e2e 证据], [`src/e2e/init_test.mbt`；`src/cmd/build/main_test.mbt`；`src/cmd/diff/main_test.mbt`；`src/cmd/check/main_test.mbt`；`src/cmd/query/main_test.mbt`],
  [`build-time extractor baseline`], [#strong[已形成第一版]], [LSP extractor 已作为 build-time baseline 接入；Terraform 已转向 `lib/hcl`], [`src/e2e/lsp_extractor_test.mbt`；`src/cmd/build/extractor.mbt`；`src/lib/hcl/*`],
  [`MCP review surface`], [#strong[局部闭环]], [`mcp start / status / stop`、`tools/list`、`tools/call` 已存在；可消费本地 bundle 查询结果], [`src/cmd/mcp/main_test.mbt`；`src/e2e/review/lifecycle_test.mbt`；`src/lib/mcp-sdk/*`],
  [`single-machine publish / registry stub`], [#strong[已完成并降级]], [本地 publish / registry stub 已实现并完成收口，但不再作为当前 release 中心], [`src/cmd/registry/main_test.mbt`；`src/cmd/registry/download_bundle_test.mbt`；`src/cmd/publish/main_test.mbt`],
)

这意味着新的 active release 不应该再以 registry / verifier 为中心，而应围绕#strong[provider 能力矩阵与 build-time extractor 证据面] 去补齐最后的闭环。

= 新的 release 顺序

== R5：Core Workflow Complete（completed）

- #strong[Scope]：把 `init → build → diff → check → query → MCP-assisted review` 收敛成当前阶段的主业务闭环。
- #strong[Done when]：
  - 本地 `init → build → diff → check → query` 链路在 repo 中继续保持绿色，并有对外一致的文档表述；
  - MCP 被明确定义为#strong[主业务流程的消费面]，用于 review / query，而不是继续被 platform/runtime hardening 议题压过优先级；
  - `check` 的 policy review 语义、`query` 的 bundle 消费语义、以及 MCP 的查询语义在 plan / progress / CLI docs 中保持统一。
- #strong[Verify]：
  - `moon test src/e2e/init_test.mbt`
  - `moon test src/e2e/lsp_extractor_test.mbt`
  - `moon test src/cmd/build/main_test.mbt`
  - `moon test src/cmd/diff/main_test.mbt`
  - `moon test src/cmd/check/main_test.mbt`
  - `moon test src/cmd/query/main_test.mbt`
  - `moon test src/cmd/mcp/main_test.mbt`
  - `pnpm build`（在 `docs/` 下）
- #strong[Non-goals]：registry remote HTTP fixture、shared verifier、部署、auth、KMS、security hardening。
- #strong[Carries forward]：
  - 单机 registry + 免认证 baseline 进入 `R6`；
  - provider matrix coverage 进入 `R7`；
  - registry trust / verifier / deployment / security 进入 `R8+ / backlog`。

== R6：Single-Machine Registry Baseline（completed）

- #strong[Scope]：在 R5 关闭后，交付单机 registry + 免认证 baseline，聚焦本地 artifact movement 与 publish/registry 可回归语义，不提前承诺 trust / deployment / auth。
- #strong[Includes]：
  - 本地 / localhost registry baseline；
  - `publish` 的单机可用路径；
  - 无认证、单机、开发环境可回归语义。
- #strong[Done when]：
  - `registry upload-local / download-local / download(materialize)` 与 `publish` 在单机路径形成稳定闭环；
  - `codeiq-registry-upload/v1`、`codeiq-registry-download/v1`、`codeiq-publish-receipt/v1` 的 contract 与命令行为保持一致；
  - plan / progress / CLI docs 对 R6 的 no-auth baseline 语义与验证命令保持一致。
- #strong[Verify]：
  - `moon test src/cmd/registry/main_test.mbt --target wasm -v`
  - `moon test src/cmd/registry/download_bundle_test.mbt --target wasm -v`
  - `moon test src/cmd/publish/main_test.mbt --target wasm -v`
  - `moon test src/e2e/registry_test.mbt --target wasm -v`
  - `moon test src/schema/contracts_test.mbt --target native -v`
  - `pnpm build`（在 `docs/` 下）
- #strong[Explicitly excludes]：shared verifier、auth、hosted deployment、enterprise security。

== R7：Provider Matrix Coverage（completed）

- #strong[Scope]：在 R6 关闭后，优先把 `spec/A001-lsp-extractor.typ` 中列出的 provider 能力矩阵尽量冻结为 repo 证据，覆盖 Go / Rust / Terraform / OpenAPI 的完整 examples、snapshots、extractor 与 e2e 测试，而不是立即转入 trust / verifier 议题。
- #strong[Includes]：
  - Go：package doc、embedded field、generic type/function、deprecated / 注释样本；
  - Rust：独立 doc comment 样本；
  - Terraform：data source、复杂 object type；
  - OpenAPI：path、discriminator、reference normalization；
  - `providers.mdx` / `progress.mdx` / `plan.typ` 的同步收口。
- #strong[Done when]：
  - `examples/*/full/repo/*` 与 `examples/*/full/snapshots/lsp/*` 对 provider matrix 关键项形成 repo 级证据；
  - `src/cmd/build/extractor.mbt`、`src/lib/hcl/parse.mbt` 与 `src/e2e/lsp_extractor_test.mbt` 对新增 provider records 有稳定验证；
  - docs / progress / plan 对 active release 与 verify 命令完全一致。
- #strong[Verify]：
  - `moon check`
  - `moon test src/cmd/build/snapshot_test.mbt`
  - `moon test src/e2e/lsp_extractor_test.mbt`
  - `pnpm build`（在 `docs/` 下）
- #strong[Explicitly excludes]：shared verifier、auth、hosted deployment、enterprise security。

=== R7 收口任务（唯一执行清单）

==== R7-1：Provider fixture / snapshot closure（completed）

- #strong[Goal]：补齐 examples 语料与 snapshots，让 provider matrix 的关键缺口都有 repo 级证据。
- #strong[Main touchpoints]：`examples/go-module/full/repo/main.go`、`examples/rust-crate/full/repo/lib.rs`、`examples/terraform-module/full/repo/main.tf`、`examples/openapi-spec/full/repo/openapi/payment.yaml`、`examples/*/full/snapshots/lsp/*`。
- #strong[Depends on]：`R6`。
- #strong[Done when]：
  - Go snapshot 覆盖 package doc、embedded field、generic type/function、deprecated / 注释样本；
  - Rust snapshot 覆盖独立 doc comment；
  - Terraform snapshot 覆盖 data source 与 object type；
  - OpenAPI snapshot 覆盖 path 与 discriminator。
- #strong[Verify]：
  - `moon test src/cmd/build/snapshot_test.mbt`
- #strong[Out of scope]：原生 `CodeIQ Extractor` 交叉验证实现。

==== R7-2：Extractor implementation closure（completed）

- #strong[Goal]：让 build-time extractor 与 parser-first/provider-specific 路径真实产出 provider matrix 所需 records，而不是只在 docs 中声明。
- #strong[Main touchpoints]：`src/cmd/build/extractor.mbt`、`src/lib/hcl/parse.mbt`、`src/e2e/lsp_extractor_test.mbt`。
- #strong[Depends on]：`R7-1`。
- #strong[Done when]：
  - Terraform inline data block 能被 parser-first 路径提取；
  - OpenAPI path / discriminator / `$ref` normalization 能稳定落盘；
  - Go field / embedded field 与 Rust doc comment 样本能稳定进入 bundle records。
- #strong[Verify]：
  - `moon check`
  - `moon test src/e2e/lsp_extractor_test.mbt`
- #strong[Out of scope]：LSP runtime productization、shared verifier。

==== R7-3：Provider docs / dashboard / release alignment（completed）

- #strong[Goal]：让 `providers/progress/plan` 对 active release、provider coverage 现状和验证矩阵保持一致。
- #strong[Main touchpoints]：`docs/src/content/docs/providers.mdx`、`docs/src/content/docs/progress.mdx`、`spec/plan.typ`。
- #strong[Depends on]：`R7-1`、`R7-2`。
- #strong[Done when]：
  - 文档把 provider matrix 作为当前 active release 明确写出；
  - progress / plan 与 provider docs 对 release 顺序、验证命令和下一步保持一致；
  - docs build 继续通过。
- #strong[Verify]：
  - `pnpm build`（在 `docs/` 下）
- #strong[Out of scope]：同时展开 `R8+` 的 trust / deployment 实施细节。

== R8：Registry Trust & Verifier（planned）

- #strong[Scope]：等 provider matrix baseline 已稳定后，再处理 signature path、shared verifier feasibility、以及是否继续保留 shell OpenSSL CLI 的正式决定。

== R9：Deployment & Security Hardening（planned）

- #strong[Scope]：最后再处理部署、认证鉴权、transport / storage security、KMS、key rotation、运维和企业级 hardening。

= Backlog（不阻塞当前 active release）

- #strong[shared non-shell verifier implementation]；
- #strong[registry remote HTTP boundary hardening]（在进入 R6 前不再抢占优先级）；
- #strong[hosted registry productization]：auth、deployment、operations；
- #strong[trust root / key rotation / KMS]；
- #strong[MCP runtime hardening]：supervision、崩溃恢复、多会话控制；
- #strong[SARIF / governance productization]：更强 provenance、平台接入与运营闭环。

= 当前阶段结论

`R5 Core Workflow Complete` 已关闭。该 release 已把#strong[开发代码提取、分析、审查主流程]收口为当前版本最清晰、最可信、最可演示的业务闭环。

`R6 Single-Machine Registry Baseline` 已关闭。`R7 Provider Matrix Coverage` 现已完成：Go / Rust / Terraform / OpenAPI 的 provider 能力矩阵已冻结为 repo 级证据。下一步进入 `R8` 处理 trust / verifier，再进入 `R9` 处理 deployment / security / ops 收口。这样做既符合 repo 当前证据，也符合产品优先级的重新排序。
