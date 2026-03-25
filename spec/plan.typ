#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：Server Capability 与共享框架抽取的下一阶段 Release Plan",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    CodeIQ 当前已经完成 `R5-R9` 的 repo baseline：主业务流程、provider 证据面、registry trust baseline 与 remote transport security 都已在仓库中落地并有测试覆盖。当前 `R10` 也已经落地关键 server capability 抽取：MCP 已切到真实 HTTP JSON-RPC runtime；Registry 已完成 `src/lib/registry/*`（shared contracts/helpers + generic async client）、`src/registry/*`（server/storage concrete implementation）、`src/cmd/registry/*`（thin CLI wiring）三层边界，并切到基于 async runtime wrapper 的真实 HTTP client/server；build/query/diff/bundle reader 主链路也已删除 zstd。因此，当前阶段不再是架构引导，而是把这些已落地边界与验证证据完整收口到 plan / docs / dashboard。
  ],
  keywords: (
    "CodeIQ",
    "Plan",
    "Registry",
    "MCP",
    "Server",
    "Framework",
  ),
  date: "March 25, 2026",
)

= 计划定位

这份计划重新回答四个问题：

- #strong[`spec/proposal.typ` 中关于 Registry / MCP server 的目标，与当前 repo 的差距到底是什么]；
- #strong[哪些 baseline 已完成，可以直接复用而不回退]；
- #strong[当前阶段如何把 MCP / Registry 已落地的 `src/lib/*` / `src/registry/*` / `src/cmd/*` 边界与 server capability 证据写实到 plan / docs / dashboard]；
- #strong[哪些事项继续明确留在 backlog，避免再次与当前 active release 混写]。

本计划继续遵循以下硬约束：

- #strong[代码和测试优先于叙述]；
- #strong[Done when 必须是 repo 可验证条件]；
- #strong[同一时刻最多只有一个 active release]；
- #strong[只有当前 active release 保留详细执行清单]；
- #strong[Non-goals 与 Backlog 不得反向阻塞当前 release]。

= 当前可复用基线（已完成，不回退）

#table(
  columns: (19%, 17%, 27%, 37%),
  inset: 6pt,
  stroke: 0.4pt,
  [*能力*], [*状态*], [*当前结论*], [*关键证据*],

  [`init/build/diff/check/query`], [#strong[已完成]], [主业务流程已形成稳定 repo baseline], [`src/e2e/init_test.mbt`；`src/cmd/build/main_test.mbt`；`src/cmd/diff/main_test.mbt`；`src/cmd/check/main_test.mbt`；`src/cmd/query/main_test.mbt`],

  [`provider evidence matrix`], [#strong[已完成]], [Go / Rust / Terraform / OpenAPI provider evidence 已冻结为 repo 级证据], [`src/e2e/lsp_extractor_test.mbt`；`src/cmd/build/snapshot_test.mbt`；`examples/*/full/snapshots/lsp/*`],

  [`registry trust / transport baseline`], [#strong[已完成]], [shell OpenSSL verifier、downgrade、remote auth header、HTTPS gate、TLS env contract 已落地], [`src/cmd/registry/main.mbt`；`src/cmd/publish/main.mbt`；`src/cmd/registry/main_test.mbt`；`src/cmd/publish/main_test.mbt`；`src/e2e/registry_test.mbt`],

  [`MCP query framework`], [#strong[部分完成，可复用]], [`src/lib/mcp-sdk/*` 已承载 JSON-RPC、tool schema、request context、cancel/deadline 等公共框架；当前 transport/runtime 已切到真实 HTTP JSON-RPC baseline], [`src/lib/mcp-sdk/jsonrpc.mbt`；`src/lib/mcp-sdk/context.mbt`；`src/lib/mcp-sdk/server.mbt`；`src/lib/mcp-sdk/tools.mbt`],

  [`MCP / registry server runtime`], [#strong[部分完成，可复用]], [MCP 已切到真实 HTTP JSON-RPC runtime；Registry 已切到 async HTTP server/client，并完成 `src/lib/registry/*` / `src/registry/*` / `src/cmd/registry/*` 边界收口；剩余 gap 主要是 docs / target / ops 收口], [`src/cmd/mcp/main.mbt`；`src/cmd/mcp/core/main.mbt`；`src/lib/registry/client.mbt`；`src/registry/server.mbt`；`src/e2e/review/lifecycle_test.mbt`；`src/e2e/registry_server_test.mbt`],
)

= 与 `spec/proposal.typ` 的关键 gap

#table(
  columns: (18%, 27%, 25%, 30%),
  inset: 6pt,
  stroke: 0.4pt,
  [*维度*], [*proposal 目标*], [*当前 repo 状态*], [*gap / 下一步*],

  [`MCP transport/runtime`], [`CodeIQ MCP Agent` 是本地常驻查询代理，`mcp start` 后为 AI 暴露稳定查询能力], [`src/cmd/mcp/main.mbt` / `src/cmd/mcp/core/main.mbt` 已切到真实 HTTP JSON-RPC runtime 与 health contract；兼容 `--stdio` 仅保留为入参兼容层], [剩余 gap 主要是补齐 `src/cmd/mcp/core/main_test.mbt` 的 target / e2e / 文档证据，而不是继续停留在 stdio-only baseline],

  [`Registry server API`], [`spec/proposal.typ` 期望 `POST /api/v1/bundles`、版本索引、bundle detail / download 等真实 Registry API], [`src/lib/registry/*` 已承载 shared contracts/helpers + generic async client，`src/registry/*` 已承载 server/storage concrete implementation，remote path 已切到 async HTTP runtime，并保留 `inproc://registry` 作为显式 local shortcut], [剩余 gap 主要是统一 proposal / plan / docs wording，并冻结版本索引 API 的对外叙述],

  [`公共框架拆分`], [proposal 把云端层与 agent 层作为独立架构层次，但没有细化到 MoonBit 包拆分], [MCP 已有 `src/lib/mcp-sdk/*`；Registry 已完成 `src/lib/registry/*` / `src/registry/*` / `src/cmd/registry/*` 分层], [剩余工作主要是把这些已落地边界准确同步到 docs/progress/plan，而不是继续做 Registry 架构拆分],

  [`server ops / supervision`], [proposal 把 Registry / MCP 视为可长期运行的服务能力], [当前 repo 只有 descriptor、pid 探活、stop/status 等轻量 lifecycle；无真正 supervision / recovery / health contract], [需要把 server runtime、health、session、supervision 与 e2e contract 纳入 active release，而不是继续停留在 descriptor workaround],

  [`trust / hosted productization`], [proposal 中 Registry 具备更完整分发与供应链价值], [当前 repo 已完成 shell verifier + transport baseline，但 shared non-shell verifier、trust root、KMS、hosted deployment 仍在 backlog], [这些事项本轮继续明确排除，不与 server capability 混写]
)

= Release ledger（按当前状态重排）

#table(
  columns: (18%, 18%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Release*], [*状态*], [*范围*], [*当前结论*],

  [`R5`], [#strong[completed]], [`Core Workflow Complete`], [`init → build → diff → check → query → MCP review` 已闭环],
  [`R6`], [#strong[completed]], [`Single-Machine Registry Baseline`], [本地 publish / registry baseline 已关闭],
  [`R7`], [#strong[completed]], [`Provider Matrix Coverage`], [provider evidence 已冻结],
  [`R8`], [#strong[completed]], [`Registry Trust & Verifier`], [shell verifier + downgrade + local/no-auth baseline 已冻结],
  [`R9`], [#strong[completed]], [`Deployment & Security Hardening`], [remote auth、transport security、TLS env contract 已冻结],
  [`R10`], [#strong[active]], [`Server Capability & Shared Framework Extraction`], [MCP / Registry server capability 与全量 `moon test` 已跑通；当前处于 release 收口与下一阶段排序阶段],
)

== R10：Server Capability & Shared Framework Extraction（active）

- #strong[Scope]：在 `R5-R9` baseline 不回退的前提下，完成 MCP / Registry 的#strong[真实 server capability] 收口：MCP 使用真实 HTTP JSON-RPC runtime；Registry 使用 `src/lib/registry/*` + `src/registry/*` + `src/cmd/registry/*` 三层边界与 async HTTP transport；同时让 docs / spec / dashboard 与 zstd 移除后的主链路保持一致。
- #strong[Includes]：
  - MCP：把 `src/lib/mcp-sdk/*` 扩展为 transport-agnostic 的 client / server runtime 框架，而不再把 detached-stdio 当作终态；
  - Registry：`src/lib/registry/*` 承载 shared contracts/helpers + generic async client，`src/registry/*` 承载 server/storage concrete implementation；
  - 命令层：`src/cmd/mcp/*` 与 `src/cmd/registry/*` 只保留命令参数、thin entry wiring 与面向 CLI 的结果包装；
  - API 冻结：统一 `spec/proposal.typ` 与当前 repo 中的 registry route / MCP runtime 语义；
  - e2e：补齐真实 client → server → business handler → storage/query 的回归闭环，不再让 env stub / direct handle_request 成为主要远端证据。
- #strong[Done when]：
  - `mcp start / status / stop / serve` 管理的已经是#strong[真实 server runtime]，而不是 detached-stdio workaround；
  - `registry` 已提供 proposal 级别的最小 server API，并有真实 request/response e2e 证据；
  - MCP / Registry 的公共框架边界都已稳定，Registry 固定为 `src/lib/registry/*` / `src/registry/*` / `src/cmd/registry/*`；
  - build/query/diff/bundle reader 主链路不再依赖 zstd，只消费/产出 plain `*.ndjson`；
  - `plan / progress / cli docs / proposal gap` 对当前 active release 的边界保持一致。
- #strong[Verify]：
  - `moon test src/cmd/mcp/main_test.mbt --target native -v`
  - `moon test src/cmd/mcp/core/main_test.mbt --target llvm -v`
  - `moon test src/e2e/review/lifecycle_test.mbt --target native -v`
  - `moon test src/cmd/registry/main_test.mbt --target wasm -v`
  - `moon test src/cmd/registry/download_bundle_test.mbt --target wasm -v`
  - `moon test src/cmd/diff/main_test.mbt --target wasm -v`
  - `moon test src/cmd/query/main_test.mbt --target wasm -v`
  - `moon test src/cmd/bundle/reader_test.mbt --target wasm -v`
  - `moon test src/cmd/publish/main_test.mbt --target wasm -v`
  - `moon test src/e2e/registry_test.mbt --target wasm -v`
  - `moon test src/e2e/registry_server_test.mbt --target native -v`
  - `moon check`
  - `pnpm build`（在 `docs/` 下）
  - `typst compile spec/plan.typ /tmp/codeiq-plan-r10.pdf`
- #strong[Explicitly excludes]：shared non-shell verifier、trust root / key rotation / KMS、多节点 hosted registry productization、enterprise observability / HA、远端 query federation。

=== R10 执行清单（唯一执行清单）

==== R10-1：共享框架抽取（completed）

- #strong[Goal]：把 MCP / Registry 的 client / server 公共框架抽到 `src/lib/*`，降低 `src/cmd/*` 的协议/transport 负担。
- #strong[Main touchpoints]：`src/lib/mcp-sdk/*`、`src/cmd/mcp/*`、`src/lib/registry/*`、`src/registry/*`、`src/cmd/registry/*`。
- #strong[Done when]：
  - MCP 协议、request context、transport adapter、descriptor/runtime state 明确分层；
  - Registry 的 shared/client、server/storage、CLI wiring 不再混在单一 command 文件中；
  - `src/cmd/main/main.mbt` 继续保持 thin dispatch。
- #strong[Verify]：
  - `moon check`
  - `moon test src/cmd/mcp/main_test.mbt --target native -v`
  - `moon test src/cmd/registry/main_test.mbt --target wasm -v`
- #strong[Out of scope]：直接完成 hosted deployment。

==== R10-2：MCP real server runtime（completed）

- #strong[Goal]：把 MCP 从 stdio / detached-stdio 过渡到真实 server capability，并保留 query-only 边界。
- #strong[Main touchpoints]：`src/cmd/mcp/main.mbt`、`src/cmd/mcp/core/main.mbt`、`src/lib/mcp-sdk/*`、`src/e2e/review/*`。
- #strong[Done when]：
  - `mcp serve` 不再只是 stdio loop，而是可以提供真实 server transport；
  - `mcp start / status / stop` 基于真实 runtime state / health contract；
  - `tools/list`、`tools/call` 与 outlines → symbol 查询链路可以通过真实 server e2e 回归。
- #strong[Verify]：
  - `moon test src/cmd/mcp/core/main_test.mbt --target llvm -v`
  - `moon test src/cmd/mcp/main_test.mbt --target native -v`
  - `moon test src/e2e/review/lifecycle_test.mbt --target native -v`
  - `moon test src/e2e/review/main_test.mbt --target wasm -v`
- #strong[Out of scope]：把 `build / diff / check / publish` 搬进 MCP。

==== R10-3：Registry real server runtime（completed）

- #strong[Goal]：把当前已落地的 Registry local / inproc / async HTTP server capability 冻结为真实 registry server API 与 runtime baseline。
- #strong[Main touchpoints]：`src/lib/registry/*`、`src/registry/*`、`src/cmd/registry/*`、`src/cmd/publish/main.mbt`、`src/e2e/registry_test.mbt`、`src/e2e/registry_server_test.mbt`。
- #strong[Done when]：
  - proposal 中的 publish / version index / bundle detail / download 语义与 repo 内公开 API 统一；
  - publish / download 的远端路径以真实 server 为主证据，而不是 curl/env stub；
  - registry server 与 client 的公共协议/transport 逻辑已完成 `src/lib/registry/*` / `src/registry/*` / `src/cmd/registry/*` 分层。
- #strong[Verify]：
  - `moon test src/cmd/registry/main_test.mbt --target wasm -v`
  - `moon test src/cmd/publish/main_test.mbt --target wasm -v`
  - `moon test src/e2e/registry_test.mbt --target wasm -v`
- #strong[Out of scope]：多租户 object store / CDN / HA productization。

==== R10-4：proposal / docs / dashboard 收口（active）

- #strong[Goal]：让 `proposal / plan / progress / quickstart / mcp / cli` 对已经落地的 server 化边界保持一致。
- #strong[Main touchpoints]：`spec/proposal.typ`、`spec/plan.typ`、`docs/src/content/docs/progress.mdx`、`docs/src/content/docs/quickstart.mdx`、`docs/src/content/docs/mcp.mdx`、`docs/src/content/docs/cli.mdx`。
- #strong[Done when]：
  - `proposal.typ` 中 Registry / MCP 的目标与 repo roadmap 对齐；
  - `plan / progress` 只对 `R10` 保留详细 checklist；
  - docs build、Typst compile 与全量 `moon test` 都继续通过。
- #strong[Verify]：
  - `moon test`
  - `pnpm build`（在 `docs/` 下）
  - `typst compile spec/plan.typ /tmp/codeiq-plan-r10.pdf`
- #strong[Out of scope]：重写整个产品说明文档站。

= Backlog（不阻塞当前 active release）

- #strong[shared non-shell verifier implementation]；
- #strong[trust root / key rotation / KMS]；
- #strong[hosted registry multi-node productization / enterprise observability / HA]；
- #strong[MCP multi-session orchestration / crash recovery / richer supervision]；
- #strong[SARIF / governance productization]：更强 provenance、平台接入与运营闭环。

= 当前阶段结论

`R5-R9` 已完成并冻结为当前 repo baseline：主业务流程、provider evidence、registry trust baseline 与 remote transport security 均已有稳定证据。当前 `R10` 也已完成关键 server capability 抽取：MCP 已切到真实 HTTP runtime，Registry 已完成 `src/lib/registry/*` / `src/registry/*` / `src/cmd/registry/*` 三层边界、async HTTP transport 与 zstd 移除。当前阶段的重点不再是继续做 Registry 架构拆分，而是把这些既有实现完整冻结为 docs / dashboard / verification 证据。
