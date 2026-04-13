#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：cleanup-first 仓库收口计划",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本计划的核心修正是重新定义 `src/lib/` 的含义：#strong[`src/lib/` 只保留可独立复用的通用库]，而与 CodeIQ 产品语义、bundle contract、built-in policies、extractor pipeline、dependency bundle 直接绑定的业务 package 必须移动到 `src/` 顶层业务域。由此，`policy_catalog` 应迁到 `src/policy/`，`extractors` 应迁到 `src/extractors/`，`sbom` 应迁到 `src/sbom/`；其中 `snapshot` 的含义被收敛为“对已解析 dependency root 进行文件级快照与内容摘要计算”的 SBOM 子能力，而不是通用仓库快照。除代码重构外，本计划同时要求为每个独立顶层 package 补齐 README，尤其是 `src/lib/` 下的可复用库。
  ],
  keywords: (
    "CodeIQ",
    "Plan",
    "Cleanup",
    "Refactor",
    "MoonBit",
    "SBOM",
    "Policy",
    "Extractor",
  ),
  date: "April 12, 2026",
)

= 一句话结论

`src/lib/` 不应该继续容纳 `policy_catalog`、`extractors`、`sbom` 这类仓库业务域；最安全的路线是：#strong[先冻结新的 package boundary truth，再按 `src/policy` / `src/extractors` / `src/sbom` 迁移业务包，同时保留 `src/lib/` 给真正可复用的库]。

= 本轮目标与非目标

== 本轮必须完成的目标

#table(
  columns: (14%, 26%, 60%),
  inset: 6pt,
  stroke: 0.4pt,
  [*编号*], [*目标*], [*说明*],

  [G0], [truth reset], [重写 `spec/plan.typ` 与 `docs/src/content/docs/progress.mdx`，把 `lib = reusable libraries only` 的规则固定下来。],
  [G1], [业务包移出 `lib`], [把 `policy_catalog`、`extractors`、`sbom` 从 `src/lib/` 迁到 `src/` 顶层业务域。],
  [G2], [SBOM 多 package 收口], [把 SBOM 收口为 `src/sbom/`，并拆出 `snapshot` / `npm` / `cargo` / `go` 等独立 package。],
  [G3], [extractor orchestration 瘦身], [把 `src/cmd/build/extractor.mbt` 收口为 orchestration-only，生态特定逻辑回到 `src/extractors/*`。],
  [G4], [runtime slice 处理], [按 feature slice 删除或替换 `shell` / `server-runtime`。],
  [G5], [native 下线], [把 native 语义收口为 in-repo MoonBit extractor，并删除 `src/native/`。],
  [G6], [README 补齐], [为每个独立顶层 package 补齐 README；其中 `src/lib/` 下的包必须从“独立可使用项目”角度编写。],
  [G7], [warning 清零与待提交状态], [已完成：generated artifacts、warning 与 `git status` 噪声已收口，repo 已回到 clean baseline。],
)

== 本轮明确不做的事

- 不把真正通用的解析 / schema / utility library 也一起搬出 `src/lib/`；
- 不在同一轮里同时引入新的“更大抽象层”来掩盖 boundary 问题；
- 不在 MoonBit native author path 未稳定前贸然删除配套路径或破坏 parity / benchmark 契约；
- 不保留 `.gitignore` 已标记为 generated 的文件继续作为长期真相源。

= 当前 repo 事实

== 已确认 reality

#table(
  columns: (22%, 30%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*位置*], [*当前 reality*], [*为什么重要*],

  [`src/policy/main.mbt`], [提供 built-in rules、docs URL、catalog JSON、rego parsing/serialization。调用方只有 `src/cmd/build`、`src/cmd/check` 与 `src/scripts/gendoc`。], [这是纯 CodeIQ 业务域，不是通用外部库。],
  [`src/lib/extract/**`], [当前是 CodeIQ extractor pipeline 的核心；调用方集中在 `src/cmd/build/extractor.mbt`、bench、e2e 以及语言子包。], [它服务的是本仓库 bundle/extraction contract，而不是独立通用库。],
  [`src/lib/sbom/**`], [当前既负责 SPDX/software component artifacts，也承载 dependency resolution 与 dependency bundle 相关逻辑。], [这仍然是 CodeIQ 产品域，不适合继续放在 `src/lib/`。],
  [`src/lib/sbom/package_manager/main.mbt`], [当前包含 `resolve_root_path`、`snapshot_files`、`snapshot_digest`。], [这些函数并不是“包管理器解析器”，而是 dependency evidence snapshotting。],
  [`src/cmd/build/main.mbt`], [`resolve_root_path` / `snapshot_files` / `snapshot_digest` 只在 build dependency bundle 生成中被调用。], [说明 `sbom/snapshot` 的职责是“生成 dependency bundle 的文件清单和内容摘要”。],
  [`src/lib/`], [除 `json-schema/README.mbt.md` 外，绝大多数顶层 package 还没有 README。], [如果 `src/lib/` 真代表可复用库，这一点必须补齐。],
  [`src/lib/parsec` / `src/lib/hcl` / `src/lib/json-schema` / `src/lib/mcp-sdk`], [这些更接近通用解析 / schema / SDK 支撑库。], [它们才是 `src/lib/` 应保留的主要对象。],
)

== `sbom/snapshot` 是什么

`snapshot` 在这里的含义必须明确收口为：#strong[对一个已经解析出来的 dependency root 做文件级快照，输出 `PackageFile[]`（相对路径、sha256、size）并计算稳定的 `content_digest`]。

它的作用包括：

- 解析 `repo + evidence_path -> root_path`；
- 递归遍历 dependency root；
- 为 dependency bundle 生成 `package.files.json`；
- 生成 `metadata.json` 中需要的 `contentDigest`；
- 为 `ResolvedDependency` 提供稳定摘要；
- 服务 build 阶段的 dependency bundle manifest/checksums 生成。

因此，`snapshot` 不是 declaration snapshot，不是 benchmark snapshot，也不是通用 repo snapshot；它是 #strong[SBOM / dependency provenance 的子能力]。

= 设计原则

== 原则 1：`src/lib/` 只留通用库

如果一个 package 的主要 caller 是 CodeIQ 自己的 command、bundle pipeline、built-in policy 或 extractor orchestration，那么它属于业务域，应位于 `src/` 顶层，而不是 `src/lib/`。

== 原则 2：业务域按产品语义顶层建模

本仓库的主要业务域已经很清楚：policy、extractors、sbom、registry、cli、config、schema。应让目录结构直接表达这些域，而不是把它们伪装成“外部可复用库”。

== 原则 3：command 层只做 orchestration

`src/cmd/*` 负责命令入口、参数和流程编排；真正长期存在的业务逻辑应回到对应域 package，而不是持续堆积在 command 文件里。

== 原则 4：`snapshot` 是 SBOM 子能力，不是包管理器子能力

`resolve_root_path`、`snapshot_files`、`snapshot_digest` 与 npm/cargo/go 本身无关；它们服务的是 dependency evidence hashing，因此应成为 `src/sbom/snapshot/`，而不是 `package_manager` 的一部分。

== 原则 5：README 与 package boundary 同轮收口

当一个 package 被认定为独立顶层边界时，README 也必须同轮到位；否则 boundary 会继续只存在于实现者脑中。

= 最终目录结构

```text
src/
├── cli/
├── config/
├── policy/
│   ├── moon.pkg
│   ├── README.mbt.md
│   └── main.mbt
├── extractors/
│   ├── moon.pkg
│   ├── README.mbt.md
│   ├── core/
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   ├── item.mbt
│   │   ├── state.mbt
│   │   └── emit.mbt
│   ├── go/
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   └── main.mbt
│   ├── rust/
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   └── main.mbt
│   ├── terraform/
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   └── main.mbt
│   └── openapi/
│       ├── moon.pkg
│       ├── README.mbt.md
│       └── main.mbt
├── sbom/
│   ├── moon.pkg
│   ├── README.mbt.md
│   ├── component.mbt
│   ├── parse.mbt
│   ├── snapshot/
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   └── main.mbt
│   ├── npm/
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   └── main.mbt
│   ├── cargo/
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   └── main.mbt
│   └── go/
│       ├── moon.pkg
│       ├── README.mbt.md
│       └── main.mbt
├── registry/
├── schema/
├── cmd/
└── lib/
    ├── hcl/
    │   ├── moon.pkg
    │   └── README.mbt.md
    ├── json-schema/
    │   ├── moon.pkg
    │   └── README.mbt.md
    ├── mcp-sdk/
    │   ├── moon.pkg
    │   └── README.mbt.md
    ├── parsec/
    │   ├── moon.pkg
    │   └── README.mbt.md
    └── <remaining truly reusable libs>/
        ├── moon.pkg
        └── README.mbt.md
```

说明：

- `policy_catalog` 的最终形态是 `src/policy/`，不再留在 `src/lib/`；
- `extractors` 的最终形态是 `src/extractors/`，不再留在 `src/lib/`；
- `sbom` 的最终形态是 `src/sbom/`，不再留在 `src/lib/`；
- `snapshot` 是 `src/sbom/snapshot/`，专门负责 dependency evidence snapshotting；
- `src/lib/` 只保留真正的可复用库，因此 README 要求主要落在这里，但顶层业务 package 也建议各自有 README。

= 推荐执行顺序

#table(
  columns: (14%, 28%, 58%),
  inset: 6pt,
  stroke: 0.4pt,
  [*阶段*], [*主题*], [*为什么现在做*],

  [P0], [plan / progress 重写], [先把新的 boundary truth 固定下来。],
  [P1], [repo-noise cleanup], [先清 generated / temp 噪声，减少后续 review diff。],
  [P2], [`sbom` 迁到 `src/sbom/`], [`snapshot` / manager split 已有最清晰的职责边界，是最适合先落地的业务域迁移。],
  [P3], [`policy_catalog` 迁到 `src/policy/`], [调用方少、业务属性明确，迁移风险低。],
  [P4], [`extract` / `extractors` 迁到 `src/extractors/`], [这是高价值但高 churn 的业务域迁移，应晚于 SBOM/policy。],
  [P5], [瘦身 `cmd/build/extractor.mbt`], [在 `src/extractors/` 稳定后，把 command 层收回 orchestration-only。],
  [P6], [按 slice 删除 `shell` / `server-runtime`], [涉及 registry / MCP / e2e / bench，必须整片处理。],
  [P7], [删除 `src/native/`], [MoonBit native author path 与测试链稳定后再删。],
  [P8], [README / warning / 待提交整理], [最后统一收 README、warning、docs 与 working tree。],
)

= 立即执行 tranche

当前 tranche 已按 #strong[P0 → P8] 顺序完成，closeout 重点已转为保持 clean repo / zero-warning baseline：

- 已重写 `spec/plan.typ` 与 `docs/src/content/docs/progress.mdx`，固定 `lib = reusable libraries only` truth；
- 已将 `src/lib/sbom/package_manager/*` 拆分并迁到 `src/sbom/`，`snapshot` 已作为 `src/sbom/snapshot/` 独立建模；
- 已完成 `policy` / `extractors` / runtime wrapper / native cleanup，并同步更新调用点与 package import；
- 已通过 `moon check --target wasm`、`moon check --target native`、`moon test --target wasm`、`moon test --target native`、`moon build --target native`、docs build 与 Typst compile 验证行为未变。

= 分阶段计划

== P0：truth reset

任务：

- 重写 `spec/plan.typ`；
- 更新 `docs/src/content/docs/progress.mdx`；
- 明确写出 `lib = reusable libraries only`；
- 明确 `policy` / `extractors` / `sbom` 属于业务域。

验收：

```bash
typst compile spec/plan.typ /tmp/codeiq-plan.pdf
pnpm build
```

== P1：repo-noise cleanup

任务：

- 删除 tracked `pkg.generated.mbti`；
- 删除 tracked `tmp_*`、历史派生物、无必要 bench outputs；
- 让 `.gitignore` 与 tracked 文件集合一致。

== P2：`sbom -> src/sbom`

任务：

- 创建 `src/sbom/` 顶层业务域；
- 将当前 `src/lib/sbom/**` 迁到 `src/sbom/**`；
- 创建 `src/sbom/snapshot/`，承接 `resolve_root_path`、`snapshot_files`、`snapshot_digest`；
- 创建 `src/sbom/npm/`、`src/sbom/cargo/`、`src/sbom/go/`；
- 更新 `src/cmd/build/main.mbt` 与对应 moon.pkg import。

需要满足：

- `snapshot` 只负责 dependency evidence snapshotting；
- manager-specific logic 不再与 snapshot utilities 混放；
- artifact contract 不变。

== P3：`policy_catalog -> src/policy`

任务：

- 已将 `src/lib/policy_catalog/` 迁到 `src/policy/`；
- 更新 `src/cmd/build`、`src/cmd/check` 与 `src/scripts/gendoc` 的 import；
- 让 package 名称表达“CodeIQ policy business domain”，而不是“外部 catalog 库”。

== P4：`extract -> src/extractors`

任务：

- 将 `src/lib/extract/**` 迁到 `src/extractors/**`；
- 将 Terraform / OpenAPI 补成一等 extractor package；
- 更新 bench、e2e、build 的 import 和测试。

== P5：瘦身 `cmd/build/extractor.mbt`

任务：

- 迁走 Terraform/OpenAPI-specific logic；
- 迁走共享 helper；
- 保留 orchestration、backend probe、inventory validation。

== P6：删除 / 替换 runtime wrappers

任务：

- 按 feature slice 重写或删除 `shell` / `server-runtime`；
- 不允许留下半删半留状态。

== P7：删除 `src/native/`

任务：

- 将 `backend=native` 收口为 in-repo MoonBit extractor author path；
- 删除 benchmark / e2e 对 `CODEIQ_NATIVE_*` env override 的依赖；
- 删除 `src/native/go/**` 与 `src/native/rust/**`，不再保留 legacy helper 源码。

== P8：README / warning / 最终整理

任务（已完成）：

- 已为每个独立顶层 package 补齐 README；
- `src/lib/` 顶层包的 README 已按独立可复用库角度改写；
- 剩余 warning 已清零，mixed-target stopgap 已通过 target-specific package 与 `supported_targets` 收口；
- `git status` 噪声已整理到 clean baseline，只保留有意源代码 / 文档 / 测试改动。

= 立即需要保住的契约

#table(
  columns: (20%, 28%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*主题*], [*必须保持稳定*], [*原因*],

  [bundle contract], [`declarations.ndjson`、`symbols.ndjson`、`metadata.json`、`manifest.json`、`checksums.txt`], [下游命令与 docs 都建立在这套产物上。],
  [SBOM artifacts], [`SoftwareComponent`、dependency bundle manifest / metadata / files JSON 形状], [迁移只能改 package boundary，不能改 artifact contract。],
  [policy contract], [built-in rule IDs、docs URI、catalog JSON、rego entrypoint 语义], [`src/policy/` 迁移不能改变现有策略行为。],
  [extract parity], [当前 canonical author path 与 `validation=lsp` 的零差异结果], [后续清理不能破坏 benchmark / parity 已取得的真实性结果。],
)

= 风险与缓解

== 主要风险

- 一次性同时做 `sbom`、`policy`、`extractors`、runtime wrapper 与 native removal，会把 diff 放大到无法验证；
- 若继续把业务域伪装在 `src/lib/` 下，后续 README、boundary、review 都会继续混乱；
- 若把 `snapshot` 留在 manager package 内，语义会继续混淆。

== 缓解策略

- 先固定 truth，再按业务域分阶段迁移；
- 先迁调用点少、职责清晰的 `sbom` / `policy`；
- 让 `snapshot` 先独立命名，再进行 manager split；
- 每个阶段都要求 Typst/docs 构建与相关 MoonBit 验证。

= 最终验收标准

当以下条件全部成立时，本计划视为完成：

- `spec/plan.typ` 与 `docs/src/content/docs/progress.mdx` 已按新的 boundary truth 重写；
- `policy_catalog` 已迁到 `src/policy/`；
- `extractors` 已迁到 `src/extractors/`；
- `sbom` 已迁到 `src/sbom/`，且 `snapshot` / `npm` / `cargo` / `go` 为独立 package；
- `src/lib/` 只保留真正的可复用库；
- 每个独立顶层 package 已有 README，其中 `src/lib/` 下包的 README 从独立可复用库角度编写；
- `src/cmd/build/extractor.mbt` 已瘦身，命令层只做 orchestration；
- `shell` / `server-runtime` 已按 feature slice 删除或替换；
- `src/native/` 已删除，且 `backend=native` 已收口为 MoonBit extractor author path；
- `moon check`、相关 tests、docs build、Typst compile 均通过；
- 剩余 warning 为零，repo 处于干净、可继续提交的状态。

以上条件现已满足。收口验证包括：`moon check --target wasm`、`moon check --target native`、`moon test --target wasm`、`moon test --target native`、`moon build --target native`、`pnpm build`、`typst compile spec/plan.typ` 与 `typst compile spec/A003-native-extractor.typ`（2026-04-13）。
