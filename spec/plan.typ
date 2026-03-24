#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：主业务流程优先的下一阶段 Release Plan",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本文重新设计 CodeIQ 的当前 release plan，核心原则是#strong[先闭环主业务流程，再做分发、部署与安全加固]。仓库已经具备 `init → build → diff → check → query → mcp` 的本地工作流和大量 e2e / unit test 证据，而 registry / publish / signature / verifier 虽然已有局部实现，但它们不应继续占据当前 release 的中心。新的计划因此把优先级调整为三层：第一层是开发代码提取、分析、审查主流程；第二层是单机 registry + 免认证基线；第三层才是 registry 信任链、部署与安全硬化。
  ],
  keywords: ("CodeIQ", "Plan", "Workflow", "Registry", "MCP", "Security"),
  date: "March 23, 2026",
)

= 计划定位

这份计划只回答三个问题：

- #strong[当前最应优先关闭的主业务流程是什么]；
- #strong[单机 registry 与免认证基线应该排在什么位置]；
- #strong[哪些 registry / verifier / deployment / security 工作必须明确降级到后续 release]。

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
  [`single-machine publish / registry stub`], [#strong[存在但降级]], [本地 publish / registry stub 已实现，但不再作为当前 release 中心], [`src/cmd/registry/main_test.mbt`；`src/cmd/registry/download_bundle_test.mbt`；`src/cmd/publish/main_test.mbt`],
)

这意味着新的 active release 不应该再以 registry / verifier 为中心，而应围绕#strong[开发代码提取、分析、审查主流程] 去补齐最后的闭环。

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
  - registry trust / verifier / deployment / security 进入 `R7+ / backlog`。

=== R5 收口任务（唯一执行清单）

==== R5-1：Extractor / artifact contract freeze

- #strong[Goal]：把当前 build-time extractor baseline、bundle artifact layout、declaration schema 与相关 snapshots 作为主流程真值源固定下来。
- #strong[Main touchpoints]：`src/cmd/build/*`、`src/schema/declarations.mbt`、`src/schema/declarations_test.mbt`、`src/e2e/lsp_extractor_test.mbt`、`examples/*/snapshots/*`。
- #strong[Depends on]：无。
- #strong[Done when]：
  - declaration / symbol / metadata / checksums / bundle layout 在当前 v1 语义下冻结；
  - Terraform `lib/hcl` 与 Go/Rust build-time extraction 的当前定位在文档中稳定表达；
  - snapshots 与 schema tests 成为后续 release 的固定回归基线。
- #strong[Verify]：
  - `moon test src/cmd/build/main_test.mbt`
  - `moon test src/cmd/build/snapshot_test.mbt`
  - `moon test src/e2e/lsp_extractor_test.mbt`
  - `moon test src/schema/declarations_test.mbt`
- #strong[Out of scope]：registry / publish / verifier 能力扩展。

==== R5-2：Analysis / review loop stabilization（completed）

- #strong[Goal]：把 `diff → check → query` 定义为当前主分析与审查链路，并让 MCP 明确承担 review consumption 角色。
- #strong[Main touchpoints]：`src/cmd/diff/*`、`src/cmd/check/*`、`src/cmd/query/*`、`src/cmd/mcp/*`、`src/lib/mcp-sdk/*`、`src/e2e/init_test.mbt`。
- #strong[Depends on]：`R5-1`。
- #strong[Done when]：
  - diff / check / query 的输入输出 contract 与 CLI 叙述稳定；
  - MCP 工具面（`codeiq.query.outlines` / `codeiq.query.symbol`）在主业务流程中的定位被明确为 review 消费面；
  - 当前 review 流程所需的最小本地证据链（bundle → diff → sarif / result → MCP query）被文档和测试同时覆盖。
- #strong[Verify]：
  - `moon test src/cmd/diff/main_test.mbt`
  - `moon test src/cmd/check/main_test.mbt`
  - `moon test src/cmd/query/main_test.mbt`
  - `moon test src/cmd/mcp/main_test.mbt`
  - `moon test src/e2e/init_test.mbt`
- #strong[Out of scope]：真实远端 registry、MCP 多会话 / long-running supervision、signature trust chain。

- #strong[Result]：已完成。
  - `diff/check/query` contract 在 CLI 与测试中保持一致；
  - MCP 保持 review consumption 角色（`codeiq.query.outlines` / `codeiq.query.symbol`）；
  - review 证据链已由 `src/e2e/review/main_test.mbt`（wasm）与 `src/e2e/review/lifecycle_test.mbt`（native）补齐；
  - 为绕过当前 MoonBit link-core ICE，大图命令测试目标已按语义拆分：`diff/query/init/review` 主链路回归走 wasm，MCP detached lifecycle 维持 native。

==== R5-3：Workflow docs / product language closeout（completed）

- #strong[Goal]：让 CLI / progress / plan 对主业务流程的优先级保持一致，不再让 registry / verifier 抢占 roadmap 中心。
- #strong[Main touchpoints]：`docs/src/content/docs/cli.mdx`、`docs/src/content/docs/progress.mdx`、`spec/plan.typ`。
- #strong[Depends on]：`R5-2`。
- #strong[Done when]：
  - 文档把主业务流程明确写成第一优先级；
  - publish / registry 被降级为后续 release，而不是当前 active release 的 headline；
  - progress page 与 plan 对 release 顺序完全一致。
- #strong[Verify]：
  - `pnpm build`（在 `docs/` 下）
- #strong[Out of scope]：同时关闭后续 registry / security release。

- #strong[Result]：已完成。
  - `cli/progress/plan` 已统一强调主业务流程优先（`init → build → diff → check → query → MCP review`）；
  - `publish/registry` 已统一降级到后续 release（`R6+`），不再作为当前 headline；
  - R5 主流程证据链引用已与最新测试结构对齐（`src/e2e/review/*`）。

==== R5-4：Release closeout（completed）

- #strong[Goal]：在 `R5-1` 到 `R5-3` 完成后关闭主业务流程优先的当前 release。
- #strong[Main touchpoints]：`spec/plan.typ`、`docs/src/content/docs/progress.mdx`。
- #strong[Depends on]：`R5-1`、`R5-2`、`R5-3`。
- #strong[Done when]：
  - `spec/plan.typ` 与 `progress.mdx` 都把 R5 标为 completed；
  - verify 清单只引用主业务流程闭环的证据；
  - registry / publish / trust / deployment 被统一移到后续 release。
- #strong[Verify]：
  - `pnpm build`（在 `docs/` 下）
  - 相关 MoonBit tests 通过
- #strong[Out of scope]：继续把 platform/back-end work 混入当前 release。

- #strong[Result]：已完成。
  - `spec/plan.typ` 与 `docs/src/content/docs/progress.mdx` 已统一将 R5 标记为 completed；
  - 验证清单聚焦主业务流程闭环证据（含 `src/e2e/review/main_test.mbt` 与 `src/e2e/review/lifecycle_test.mbt`）；
  - registry / publish / trust / deployment 统一顺延到 `R6-R8`。

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

=== R6 收口任务（唯一执行清单）

==== R6-1：Single-machine registry loop freeze（completed）

- #strong[Goal]：把 `publish ↔ registry(upload-local/download-local/download)` 的单机闭环固定为当前 release 的回归基线。
- #strong[Main touchpoints]：`src/cmd/registry/*`、`src/cmd/publish/*`、`src/e2e/registry_test.mbt`、`src/schema/contracts_test.mbt`、`docs/src/content/docs/cli.mdx`、`docs/src/content/docs/progress.mdx`。
- #strong[Depends on]：`R5`。
- #strong[Done when]：
  - `registry upload-local / download-local / download(materialize)` 与 `publish` 在单机路径形成稳定闭环；
  - `codeiq-registry-upload/v1`、`codeiq-registry-download/v1`、`codeiq-publish-receipt/v1` 的 contract 与命令行为保持一致；
  - 端到端最小证据链（build bundle → registry upload-local → registry resolve/download → publish receipt）有独立 e2e 覆盖。
- #strong[Verify]：
  - `moon test src/cmd/registry/main_test.mbt --target wasm -v`
  - `moon test src/cmd/registry/download_bundle_test.mbt --target wasm -v`
  - `moon test src/cmd/publish/main_test.mbt --target wasm -v`
  - `moon test src/e2e/registry_test.mbt --target wasm -v`
  - `moon test src/schema/contracts_test.mbt --target native -v`
  - `pnpm build`（在 `docs/` 下）
- #strong[Out of scope]：registry HTTP server productization、shared verifier、hosted deployment、KMS/key rotation。

- #strong[Result]：已完成。
  - `registry upload-local / download-local / download(materialize)` 与 `publish` 单机闭环已稳定；
  - `codeiq-registry-upload/v1`、`codeiq-registry-download/v1`、`codeiq-publish-receipt/v1` contract 与命令行为一致；
  - `spec/plan.typ`、`docs/src/content/docs/progress.mdx`、`docs/src/content/docs/cli.mdx` 已统一 R6 语义与验证命令。

== R7：Registry Trust & Verifier（planned）

- #strong[Scope]：等单机 registry baseline 已稳定后，再处理 signature path、shared verifier feasibility、以及是否继续保留 shell OpenSSL CLI 的正式决定。

== R8：Deployment & Security Hardening（planned）

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

`R6 Single-Machine Registry Baseline` 已关闭。下一步进入 `R7` 处理 trust / verifier 议题，再进入 `R8` 处理 deployment / security / ops 收口。这样做既符合 repo 当前证据，也符合产品优先级的重新排序。
