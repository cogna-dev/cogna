#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：执行计划与差距收敛路线图",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本计划基于 2026-03-22 的最新代码与测试结果更新。相较于上一版，项目已完成 `W1-W16` 的首轮目标：Bundle 真值基础、声明级 diff/query、MCP 基础能力、policy 决策执行、registry 本地上传闭环、以及 LSP/fallback + shape/relations 第一版均已落地。本计划目标从“差距识别”收敛到#strong[发布前收口与基线锁定]：保证 docs/spec/CLI 与测试证据一致，并以 `W17` 完成当前阶段闭环。
  ],
  keywords: ("CodeIQ", "Plan", "CIQ", "Bundle", "Diff", "SARIF", "OPA", "Registry", "MCP"),
  date: "March 22, 2026",
)

= 计划目标

本计划回答三个问题：

- 当前仓库#strong[已经交付到哪个阶段]；
- 相对于 `spec/proposal.typ`，#strong[当前仍存在哪些关键设计偏差]；
- 下一阶段（P2/P3）应按什么顺序推进，才能最短路径收敛为可发布闭环。

本计划以#strong[当前仓库代码现实]为准，而不是以理想化设计图为准。任何后续开发，都应优先消除“规格 / 文档 / 命令 / 产物”之间的漂移，再扩大功能面。

= 当前仓库状态摘要（更新版）

#table(
  columns: (16%, 14%, 30%, 40%),
  inset: 6pt,
  stroke: 0.4pt,
  [*子系统*], [*状态*], [*当前现实*], [*关键证据*],

  [`init`], [#strong[完成]], [可以稳定生成 `codeiq.yaml`，已有 e2e 覆盖], [`src/cmd/init/main.mbt`；`src/e2e/init_test.mbt`],
  [`build`], [#strong[高完成度]], [已生成真实 `zstd`/`sha256`/`bundle.ciq.tgz`；并支持 `policy-bundle` profile 与 `ciq-opa-bundle/v1` 产物], [`src/cmd/build/main.mbt`；`src/cmd/build/extractor.mbt`；`src/cmd/build/main_test.mbt`],
  [`diff`], [#strong[已完成当前阶段]], [已改为基于 declarations/symbols 记录计算 added/removed/changed/deprecated，不再是纯 manifest 比较], [`src/cmd/diff/main.mbt`；`src/cmd/diff/main_test.mbt`],
  [`check`], [#strong[已完成当前阶段]], [已执行 OPA CLI（`opa eval`）并把 policy decision 合并映射到 SARIF rules/results], [`src/cmd/check/main.mbt`；`src/cmd/check/main_test.mbt`],
  [`query`], [#strong[已完成当前阶段]], [已从本地 bundle 读取 declarations/symbols 执行查询，placeholder 路径已移除], [`src/cmd/query/main.mbt`；`src/cmd/query/main_test.mbt`],
  [`publish`], [#strong[已完成当前阶段]], [已接入本地 registry stub 上传链路，输出并校验 `codeiq-publish-receipt/v1`], [`src/cmd/publish/main.mbt`；`src/cmd/registry/main.mbt`],
  [`mcp`], [#strong[第一版完成]], [`tools/list` / `tools/call` 已复用 query backend；`mcp start/status/stop` 已实现 descriptor 生命周期], [`src/cmd/mcp/main.mbt`；`src/cmd/mcp/main_test.mbt`；`src/cmd/main/main.mbt`],
  [Schema / Config], [#strong[完成度较高]], [`ciq-bundle`、`ciq-diff`、`ciq-query`、`ciq-result`、SARIF 最小 schema 已定义], [`src/schema/contracts.mbt`；`src/config/*`],
  [OPA / Registry contract], [#strong[合同先行]], [已新增 `ciq-opa-bundle`、`registry-upload`、`publish-receipt` schema 与测试，但命令侧仍未完成执行/上传], [`src/schema/contracts.mbt`；`src/schema/contracts_test.mbt`],
  [Examples / Snapshot], [#strong[完成度较高]], [Go / Rust / Terraform / OpenAPI 已有较完整 examples 和 LSP baseline 快照], [`examples/*`；`src/cmd/build/snapshot_test.mbt`],
  [Docs / Spec], [#strong[需持续校准]], [随着 W10 落地，`plan/progress/cli` 需同步修正 W11/W12/W14 的真实状态与边界], [`docs/src/content/docs/*.mdx`；`spec/proposal.typ`],
  [Registry], [#strong[已完成本地 stub]], [已提供本地文件型 registry stub（upload/index/bundles）供 publish 链路接入], [`src/cmd/registry/main.mbt`],
  [`CodeIQ Extractor`], [#strong[第一版进行中]], [当前仍是 parser-first baseline，但已补充 LSP 子进程可用性探测与 fallback metadata], [`spec/A001-lsp-extractor.typ`；`src/cmd/build/extractor.mbt`],
)

= 当前设计与实现的核心偏差（按 proposal 对齐）

#table(
  columns: (24%, 32%, 44%),
  inset: 6pt,
  stroke: 0.4pt,
  [*设计承诺*], [*当前现实*], [*影响*],

  [`codeiq build <repo>` / `codeiq diff <repo>`], [`src/cmd/main/main.mbt` 已解析 repo positional，并支持 `diff --since --test-changes`], [CLI 合同与 proposal 主路径已对齐],
  [LSP build-time extractor], [`src/cmd/build/extractor.mbt` 仍是 parser-first baseline，但已加入 `gopls` / `rust-analyzer` 可用性探测与 fallback 记录], [A001 的“build-time 子进程接入”已有第一版落地，后续需补充真实结果合并],
  [Diff CLI contract], [`diff` 已输出 `since/includeTestChanges/testSummary/testChanges`], [proposal 中测试变化链路已建立最小实现],
  [OPA + SARIF], [`src/cmd/check/main.mbt` 已执行 OPA CLI 并输出 policy decision 驱动 SARIF], [`check` 治理闭环已打通],
  [Registry publish], [`src/cmd/publish/main.mbt` 已接入本地 registry stub 并输出 immutable receipt], [分发链路本地可用，后续可替换为远端 HTTP client],
  [MCP runtime depth], [`mcp start/status/stop` 已有第一版，但生命周期仍基于 descriptor 文件，缺少更强进程管理语义], [可用但能力边界应在 docs 中明确],
  [OPA bundle packaging shape], [当前 policy-bundle 仍带 `declarations/symbols` 与 `policy.rules.json`，与 proposal 里的最小 OPA 包装示意存在差异], [需在 W11/W13 决定是兼容扩展还是收敛为最小结构],
)

= 执行原则

后续实现应遵循以下原则：

- #strong[先修正契约漂移，再扩大功能面]：CLI、文档和 spec 的承诺必须先对齐。
- #strong[先让 Bundle 成为真值，再让下游命令消费它]：`diff`、`query`、`check`、`publish` 都应建立在真实 bundle 语义之上。
- #strong[共享本地读取层]：`query` 与 `mcp` 应复用同一套 bundle reader / selector 逻辑，避免双份 placeholder 演化。
- #strong[先打通一条真实闭环，再追求所有 profile 的高级语义]：先让 `init → build → diff → check → publish → query/mcp` 真正成立。
- #strong[保持 baseline 可验证]：`LSP Extractor` 与 examples/snapshots 继续作为未来 `CodeIQ Extractor` 的对照组。

= 工作项总表（按当前状态标注）

以下工作项按依赖顺序组织；其中 `W1`–`W4` 为 Bundle foundation，`W5`–`W9` 为本地消费闭环，`W10`–`W14` 为治理与分发闭环，`W15`–`W16` 为抽取质量层，`W17` 为发布收口。状态标签：`✅` 已完成、`🟡` 部分完成、`⏳` 未完成。

== Phase A：Bundle 真值基础层

#table(
  columns: (8%, 24%, 16%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*ID*], [*工作项*], [*依赖*], [*完成标准*],

  [W1], [✅ 真实 SHA-256 摘要], [无], [已完成：`manifest/declarations/symbols/metadata` 写入真实 SHA-256],
  [W2], [✅ 真实 zstd 压缩与 artifact reader], [W1], [已完成：`.ndjson.zst` 真压缩，reader 可供 `diff/query/mcp` 复用],
  [W3], [✅ git commit / source metadata 真实化], [无], [已完成：commit 解析与 metadata timing 基线已落地],
  [W4], [✅ `.ciq.tgz` 打包语义落地], [W1, W2, W3], [已完成：build 产出 bundle tarball，并由测试覆盖],
)

== Phase B：本地声明消费闭环

#table(
  columns: (8%, 24%, 16%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*ID*], [*工作项*], [*依赖*], [*完成标准*],

  [W5], [✅ 声明级 diff engine], [W2, W3], [已完成：基于 declarations/symbols 记录计算 diff 结果],
  [W6], [✅ CLI 契约对齐：`build/diff` positional + `--since` + `--test-changes`], [W5 可并行], [已完成：`diff --since --test-changes` 参数解析、输出字段与测试覆盖],
  [W7], [✅ 真实 query backend], [W2], [已完成：query 从本地 bundle 读取真实记录，无 placeholder],
  [W8], [✅ MCP stdio loop + bundle loader（第一版）], [W7], [已完成第一版：tools/list + tools/call 复用 query backend，stdio 请求读写可用],
  [W9], [✅ `mcp status` / `mcp stop`（第一版）], [W8], [已完成第一版：descriptor 状态管理与 stop 清理已可验证],
)

== Phase C：治理与分发闭环

#table(
  columns: (8%, 24%, 16%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*ID*], [*工作项*], [*依赖*], [*完成标准*],

  [W10], [✅ `CIQ OPA Bundle` 格式与 build 路径（第一版）], [W4], [已完成第一版：`policy-bundle` profile、`ciq-opa-bundle/v1` manifest、`opa-bundle.tar.gz` 与 `policy.rules.json`],
  [W11], [✅ OPA policy 执行 + SARIF 映射], [W5, W10], [已完成：`check` 执行 `opa eval` 并将 decision 映射至 SARIF],
  [W12], [✅ Registry API contract 与本地开发桩], [W4], [已完成：schema contract + `registry` 本地 stub + `publish` 接线],
  [W13], [⏳ Docs / Spec / CLI contract alignment], [W6, W9, W11], [待持续：清理过度承诺，保证文档只描述已实现行为],
  [W14], [✅ 真实 publish client（本地 stub 版本）], [W4, W12], [已完成：替换本地 skeleton，接入上传链路并输出 immutable receipt],
)

== Phase D：抽取质量提升层

#table(
  columns: (8%, 24%, 16%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*ID*], [*工作项*], [*依赖*], [*完成标准*],

  [W15], [✅ Go / Rust LSP 子进程集成（第一版）], [W4], [已完成第一版：build metadata 记录 server 探测、version 与 fallback],
  [W16], [✅ `shape` / `relations` 结构化模型（第一版）], [W5, W15], [已完成第一版：声明记录写入最小结构化 shape/subkind/form/relations],
)

== Phase E：发布收口

#table(
  columns: (8%, 24%, 16%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*ID*], [*工作项*], [*依赖*], [*完成标准*],

  [W17], [✅ 发布前收口与基线锁定], [W1–W16], [已完成：治理闭环与 docs/spec/e2e 同步收口，验证链路通过],
)

= 里程碑规划（当前状态）

#table(
  columns: (14%, 24%, 24%, 38%),
  inset: 6pt,
  stroke: 0.4pt,
  [*里程碑*], [*目标*], [*包含工作项*], [*退出条件*],

  [M1], [可信 Bundle], [W1, W2, W3, W4], [#strong[已完成]],
  [M2], [本地可查询 / 可比较], [W5, W6, W7, W8, W9], [#strong[已完成]；含 W6 参数契约补齐],
  [M3], [治理闭环], [W10, W11, W12, W13, W14], [#strong[已完成当前阶段]；W10-W12-W14 全链路可验证],
  [M4], [baseline 稳定发布], [W15, W16, W17], [#strong[已完成当前阶段]；W15/W16/W17 全部可验证],
)

= 子系统完成度判断标准

为避免再次出现“功能已在文档中完成，但代码仍是 skeleton”的情况，本计划要求每个子系统都用以下标准判断是否完成：

#table(
  columns: (22%, 18%, 60%),
  inset: 6pt,
  stroke: 0.4pt,
  [*子系统*], [*必须满足*], [*说明*],

  [CLI], [命令可解析], [parser、帮助文本、docs 三者必须一致],
  [Bundle], [artifact 为真], [文件名、压缩、checksum、tarball、metadata 不能再使用 placeholder],
  [Diff], [比较声明事实], [必须比较 bundle 内容，而不是只比较 manifest 字段],
  [Check], [执行真实 policy], [必须基于 `CIQ Diff + CIQ OPA Bundle` 做 rule decision],
  [Query / MCP], [检索真实 bundle], [必须读取 declarations / symbols，而不是读取 stub 文件或构造 placeholder],
  [Publish], [上传真实 bundle], [必须与明确的 Registry contract 对接],
  [Docs / Spec], [与代码一致], [未实现功能必须标注 planned，不得伪装成 shipped],
)

= 当下执行计划（滚动）

当前建议按“已完成回顾 + 最终收口”推进：

1. #strong[迭代 A（治理执行）]：✅ 已完成，`check` 已从“diff->SARIF 映射”升级到“policy decision->SARIF”。
2. #strong[迭代 B（分发接线）]：✅ 已完成，`W12 + W14` 本地 registry stub 与 publish 上传链路已打通。
3. #strong[迭代 C（契约收口）]：✅ 已完成，`W6` 参数补齐与 docs/spec/CLI 对齐已落地。
4. #strong[迭代 D（质量增强）]：✅ 已完成，`W15/W16` 最小可交付实现与快照验证已收敛。
5. #strong[最终收口]：✅ 已完成，`W17` 发布前收口与基线锁定完成。

当前阶段结论：主线闭环已经打通，后续进入“增强而非补洞”的增量阶段。

= 已经稳定、应避免重写的资产

以下资产已经具备较高稳定性，后续应优先复用，而不是重写：

- `src/schema/contracts.mbt`：可继续作为 schema 与 artifact contract 的统一入口。
- `src/config/*`：配置类型、默认值、验证路径已经比较完整。
- `src/cmd/build/snapshot_test.mbt` 与 `examples/*`：这是后续 baseline / native extractor 对照的关键基础设施。
- `src/e2e/*`：虽然现在验证的是 skeleton 闭环，但结构已经具备扩展价值。
- `docs/src/content/docs/progress.mdx`：已被明确设为开发周期结束后的必更新看板。

= 当前计划之外但必须保留的后续路线

本计划优先解决 proposal 中已经承诺但尚未兑现的功能，不把未来研究课题与当前闭环混写。以下事项应保留为下一阶段：

- #strong[原生 `CodeIQ Extractor`]：在 `LSP Extractor` baseline 稳定后再推进；届时使用同一套 examples / snapshots 做交叉验证。
- #strong[更细粒度的兼容性规则]：例如生命周期注解、feature flag、语义版本映射等，应该建立在 W16 完成之后。
- #strong[Registry 的企业级能力]：权限模型、缓存层、签名校验、对象存储后端等，可在 W14 完成后继续增强。

= 结论

当前仓库已完成从“skeleton CLI”到“可验证治理闭环”的阶段跃迁：Bundle 真值、声明级 diff/query、MCP、本地 policy 决策执行、registry 上传链路、以及抽取质量增强第一版均已交付并通过验证。`W17` 收口后，当前计划阶段已闭环完成。下一阶段建议转向增强路线：提高 LSP 真实抽取深度、细化 shape/relations 语义、并演进远端 registry 能力与发布策略。
