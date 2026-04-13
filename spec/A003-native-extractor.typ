#import "@preview/arkheion:0.1.1": arkheion

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "CodeIQ：A003 Native Extractor（共享语义核心版）",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本提案重新定义 CodeIQ 的 `Native Extractor` 路线。A003 不再把 Go / Rust 的“native”理解为两套彼此独立、各自产生黄金快照的 backend，也不再把 `src/native/go` / `src/native/rust` helper binary 视为主实现。新的核心结论是：#strong[CodeIQ 必须收敛到一套由两层组成的 MoonBit 抽取体系]：底层是可独立发布的通用 parser combinator + token stream framework，上层是依赖该 framework 的 Go / Rust public API parser 与 CodeIQ extraction logic。LSP 只保留为验证 / benchmark / 回归定位模式。对同一份代码，`lsp` 与 `native` 运行后写出的最终 `ExtractOutput`、bundle 产物与黄金快照 #strong[不能有任何差异]；若要扩展新的可分析语义，必须由语言 parser 与 LSP 验证模式在同一轮一起收敛，保持输出一致。
  ],
  keywords: (
    "CodeIQ",
    "CIQ",
    "Native Extractor",
    "LSP",
    "MoonBit",
    "Parser Combinator",
    "Go",
    "Rust",
    "LSIF",
  ),
  date: "April 9, 2026",
)

= 一句话结论与边界

这轮工作不是“保留一条 LSP 语义链，再另做一条 native 语义链”，而是：#strong[把 CodeIQ 的抽取层收敛成一套共享的 MoonBit semantic core]。`native` 与 `lsp` 的差别只允许发生在 #strong[执行模式] 上，不允许发生在 #strong[最终 bundle 输出] 上。`declarations.ndjson`、`symbols.ndjson`、`metadata.json`、`manifest.json`、`checksums.txt` 与 `bundle.ciq.tgz` 必须保持同一份真相；LSP 只能验证、对照、度量，不能再成为另一套可接受但不同的结果来源。

本提案的目标有五项：

- #strong[建立两层共享语义核心]：在 `src/lib/` 中把 #strong[通用 parser combinator framework] 与 #strong[Go / Rust 具体 parser + extraction logic] 明确拆成不同 package；通用层未来可独立发布，语言层继续留在 CodeIQ repo 中；
- #strong[统一快照真相源]：同一份 fixture 只保留一套 canonical snapshot；`native` / `lsp` 跑同一份代码时必须得到同一份最终结果；
- #strong[把 LSP 退回验证 / benchmark 模式]：LSP 继续存在，但它的职责是对共享语义核心做 cross-check、回归定位与性能对照，而不是 author bundle；
- #strong[以启发式 token parsing 提升性能]：跳过非 public 内容，避免完整编译器级解析，用平衡分隔符、token tree、doc comment 与 visibility 驱动 public API 提取；
- #strong[保留 benchmark，但把 parity 设为硬约束]：性能、内存、LSIF vs CIQ Bundle 体积仍要度量，但只有 `snapshotDiffCount == 0` 的模式才算语义达标。

本提案的非目标同样需要明确：

- 不在 MoonBit 中重写 Go / Rust 的完整编译器；
- 不把 proc-macro 展开、cfg 求值、trait resolution、类型推断做到编译器级完备；
- 不保留 `snapshots/native/` 作为第二份 canonical truth；
- 不允许新语义只在某一个模式上线；
- 不把 LSIF / SCIP 变成 CodeIQ 的主产物格式。

= 当前 repo reality 与设计压力

#table(
  columns: (22%, 30%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*位置*], [*当前 reality*], [*为什么重要*],

  [`src/cmd/build/main.mbt`], [`write_bundle_skeleton()` 只依赖 `ExtractOutput` 写 bundle。], [这意味着 A003 的主战场仍是抽取层；只要共享核心产出稳定 `ExtractOutput`，其余打包链可以继续复用。],
  [`src/cmd/build/extractor.mbt`], [当前代码里同时存在 LSP baseline 路径、helper binary 假设与 `backend` / `routing` metadata 骨架。], [必须把这些概念重新收口：保留 routing，但把“helper binary = primary native”从设计中移除。],
  [`src/cmd/build/snapshot_test.mbt`], [当前 harness 仍沿用 `snapshots/lsp` 与 `snapshots/native` 的双目录假设。], [这与“最终输出不能有任何差异”的新要求冲突；A003 必须改成单一 snapshot truth。],
  [`src/e2e/lsp_extractor_test.mbt`], [现有 e2e 已覆盖 Go / Rust / Terraform / OpenAPI 的关键字段面。], [共享核心必须至少保住这批字段；新增语义也必须同步进入验证模式。],
  [`src/lib/hcl/parse.mbt`], [仓内已经存在 MoonBit parser-first 实践。], [说明“在 MoonBit 内做启发式语法抽取”并不是全新路径；现在要做的是把通用 parsing framework 与语言 parser 的包边界定义清楚。],
  [`.claude/skills/moonbit-lang/reference/toml-parser-parser.mbt`], [已有 token view + 手写 parser 的 MoonBit 参考实现。], [可直接借鉴其 token view / update_view / error 组织方式，作为 combinator library 的风格样板。],
  [`src/native/go/` / `src/native/rust/`], [仓内曾有 helper binary 原型与相关叙述；目标状态是不再保留这些目录。], [在新设计下它们不能继续作为主路径，最终应完全从仓库中删除。],
  [`docs/src/content/docs/progress.mdx`], [当前对 A003 的完成度叙述与 repo 新要求不符。], [设计文档更新后，progress 必须同步回到真实状态。],
)

= 核心决策

== 决策摘要

#table(
  columns: (20%, 24%, 56%),
  inset: 6pt,
  stroke: 0.4pt,
  [*决策项*], [*提案结论*], [*说明*],

  [语义权威来源], [`MoonBit shared core`], [Go / Rust 的最终声明、关系、metadata 必须都来自同一套 MoonBit 抽取核心。],
  [LSP 的角色], [验证 / benchmark], [LSP 继续存在，但只用于校验共享核心的结果与性能对照。],
  [快照策略], [单一真相源], [每个 fixture 只能有一份 canonical snapshot；若保留 `snapshots/lsp` 作为迁移路径，也不得再引入第二份 canonical `snapshots/native`。],
  [backend 的语义], [执行模式而非语义分支], [`native` / `lsp` 只表示运行时是否附带 LSP 验证，不再表示允许不同输出。],
  [Go / Rust 实现方法], [MoonBit 启发式 token parser], [不使用标准原生 Go / Rust parser 作为主实现，而是在 MoonBit 中自行 token 化并做启发式抽取。],
  [非 public 内容], [可直接丢弃], [为了性能，默认只保留 public API、文档注释、必要的宿主上下文与导出关系。],
  [Rust 宏策略], [token tree + 启发式恢复], [支持 item-like macros、`macro_rules!`、属性宏的 token-tree 识别与跳过，不承诺完整展开。],
  [benchmark 通过条件], [`snapshotDiffCount == 0`], [没有 parity 的 benchmark 只能算实验数据，不能算 extractor 成功。],
)

== 与 A001 LSP 提取器的关系

A001 的判断仍然成立：#strong[LSP 不是 CodeIQ 的产品中心]。A003 现在把这个判断进一步收紧：

- A001 允许“未来出现 CodeIQ 自己的 extractor”；
- 新版 A003 明确这套 extractor 必须是 #strong[共享语义核心]，而不是另一套彼此可漂移的 backend；
- 因此，LSP 与 shared core 的关系不是 “baseline vs primary but both can differ”，而是 #strong[validator vs canonical author]。

= 共享语义核心总体架构

== build-only 原则保持不变

无论是否开启 LSP 验证，抽取都继续局限在 `build` 内：

1. 读取 `codeiq.yml` / `codeiq.yaml`；
2. 根据 `profile` 与运行模式选择是否附带 LSP 验证；
3. 使用 MoonBit shared core 对源码做 token 化、启发式解析、record 归一化；
4. 如启用 LSP，则对 canonical records 做对照检查与 benchmark 指标收集；
5. 统一通过 `write_bundle_skeleton()` 写出 bundle。

因此，A003 仍不引入 daemon、IDE runtime 或远程执行层。

== backend / validation contract

推荐把当前 routing contract 重解释为：

```json
{
  "profile": "go-module",
  "engine": "moonbit-public-api-parser",
  "validation": "none | lsp",
  "canonicalSnapshot": "shared",
  "parityRequired": true
}
```

其中关键变化是：

- `engine` 不再是 `codeiq-extract-go` / `codeiq-extract-rust` 这类外部 helper，而是统一的 MoonBit 抽取核心；
- `validation` 才表示是否附带 LSP；
- canonical snapshot 只有一份；
- `parityRequired = true` 表示 `validation=lsp` 时也不得改写最终 bundle。

== 推荐目录布局

```text
src/
├── lib/
│   ├── parsec/
│   │   ├── token.mbt
│   │   ├── stream.mbt
│   │   ├── combinator.mbt
│   │   └── recover.mbt
│   └── extract/
│       ├── item.mbt
│       ├── emit.mbt
│       ├── go/
│       │   └── main.mbt
│       └── rust/
│           └── main.mbt
└── cmd/
    ├── build/
    │   ├── extractor.mbt
    │   └── bench.mbt
     └── scripts/
         └── benchmark/
        └── main.mbt
```

设计意图：

- `src/lib/parsec/` 是可独立发布的通用 parser combinator framework；
- `src/lib/extract/` 是 CodeIQ 自己的 extraction 层，承载 item model、emit 与语言 parser；
- `src/cmd/build/` 只负责 orchestration、config、metadata 与 bundle packaging；
- `src/native/go` / `src/native/rust` 不再出现在主设计路径中；仓库最终状态应直接删除这两组 legacy helper 源码。

== publishable parser combinator framework 最小面

受 Rust `nom` 启发，但只实现 A003 需要的最小集合：

#table(
  columns: (22%, 22%, 56%),
  inset: 6pt,
  stroke: 0.4pt,
  [*能力*], [*最小接口*], [*在上层 parser 中的用途*],

  [输入抽象], [`TokenStream` / `TokenView`], [支持 cheap slice、offset、balanced delimiter 扫描与 zero-copy token window。],
  [结果模型], [`ParseResult[T] = Ok | Error | Failure | Incomplete`], [区分可恢复失败、提交后失败与输入不足，便于性能控制。],
  [基础匹配], [`tag` / `pred` / `peek` / `recognize`], [识别关键字、标点、visibility、doc comment 与 item opener。],
  [组合], [`seq` / `alt` / `map` / `flat_map` / `opt`], [把 token 片段组织成 declaration / relation 所需结构。],
  [重复], [`many0` / `many1` / `separated_list0`], [处理属性列表、generic params、trait items、macro token tree 中的重复结构。],
  [分隔符], [`delimited` / `preceded` / `terminated`], [处理 `(...)`、`{...}`、`[...]`、receiver、where clause、macro body。],
  [提交], [`cut`], [在 item opener 已确定时停止无意义回溯，控制性能。],
  [恢复], [`recover_until` / `skip_balanced`], [遇到复杂宏、坏 token tree 或不支持语法时线性跳过，继续扫描下一个 public item。],
)

这里的目标不是“表达完整 grammar”，而是：#strong[提供一个足够小、足够稳定、可以独立发布的 parsing framework]，让上层语言 parser 在不泄漏 Go / Rust 生态细节的前提下稳定抽取 public API 所需的 token 片段。

== framework 与 language parser 的依赖方向

#table(
  columns: (22%, 24%, 54%),
  inset: 6pt,
  stroke: 0.4pt,
  [*层次*], [*包建议*], [*依赖规则*],

  [通用 parsing framework], [`src/lib/parsec`], [只能依赖 MoonBit core / 必要基础库；不得 import Go / Rust / CodeIQ declaration schema。],
  [语言无关 extraction 层], [`src/lib/extract`], [依赖 `@parsec`，定义 item model、emit、normalize、relation rewrite。],
  [Go parser], [`src/lib/extract/go`], [依赖 `@parsec` 与 `@extract`；不得反向让 `@parsec` 感知 Go grammar。],
  [Rust parser], [`src/lib/extract/rust`], [依赖 `@parsec` 与 `@extract`；不得反向让 `@parsec` 感知 Rust 宏细节。],
  [build orchestration], [`src/cmd/build`], [只依赖 `@extract` 暴露的稳定入口，不直接拼装低层 combinator。],
)

这个拆分的目的有三项：

- 让 `parsec` 的 public API 足够小，未来可独立发布；
- 让 Go / Rust parser 保持项目内演进速度，不把生态细节强塞进通用 framework；
- 让 `src/cmd/build` 面向稳定 extraction API，而不是直接耦合 parser internals。

== canonical item model

语言 parser 应先生成一层语言无关的中间 item model，再统一 emit 成 `ExtractOutput`：

- visibility / export status；
- docs / summary；
- item kind；
- canonical path / signature；
- source range；
- language-specific shape；
- relation seeds（例如 declared_in、has_member、returns、references_type）。

这里的 package 分工必须明确为：

- `@parsec` 只关心 token / combinator / recover；
- `@extract` 只关心 item model / emit / normalize；
- `@extract/go` 与 `@extract/rust` 才关心各自语法。

这样做的目的是：

- Go / Rust 可以共用 emit / normalize / sort-and-dedup 路径；
- LSP 验证模式也只需要对 item model 或最终 record 做对照，而不是单独 author JSON。

= Go 启发式抽取设计

== 实现原则

Go 部分不再依赖 `go/packages`、`go/types`、`go/ast` 作为主实现。相反，#strong[`@extract/go` 应建立在 `@parsec` + `@extract` 之上]，在 MoonBit 中完成：

1. token 化源码，保留 identifier、keyword、punctuation、string/raw string、comment、newline 与 span；
2. 只扫描 package doc 与 exported declaration opener；
3. 遇到 function / method / type / const / var 时，通过 balanced delimiter 和启发式组合子提取 signature；
4. 对 function body、非 public declaration、复杂表达式与局部语句直接跳过；
5. 用统一的 relation rewrite 逻辑生成 method set、embedded field、returns、references_type 等现有字段。

== Go 首期必须覆盖的 surface

- package doc；
- exported const / var / type / func；
- generic type / function；
- method receiver / pointer receiver；
- embedded field；
- interface member 与 struct member；
- deprecated doc comment；
- 当前 e2e 已覆盖的 relations。

== Go 性能策略

为了性能，Go parser 应默认：

- 一旦确认 declaration 不是 exported，就整段跳过；
- 一旦进入 function body，用平衡花括号直接跳过函数体；
- 对 import、表达式、初始化值、复合字面量只做最少 token 识别，不追求完整解析；
- doc comment 与 signature 只保留 `ExtractOutput` 必需字段。

= Rust 启发式抽取设计

== 实现原则

Rust 部分同样不再以 `rust-analyzer`、`syn`、`rustc` parser 作为主实现；#strong[`@extract/rust` 必须建立在 `@parsec` + `@extract` 之上]，在 MoonBit 中自己处理 token stream。

Rust 抽取的核心思想是：#strong[先识别 top-level public item，再用 token tree 与恢复组合子处理复杂语法]。

== Rust token 模型与宏处理

Rust token 流至少要显式编码：

- `pub` / `pub(crate)` / `pub(in ...)` 等 visibility 片段；
- `#[]` 属性、doc comment、`cfg` 属性；
- `fn` / `struct` / `enum` / `trait` / `impl` / `type` / `use` / `mod` 等 item opener；
- `!` 与后续分隔符形成的 macro invocation；
- `()` / `{}` / `[]` 三类 delimiter，用于形成 token tree；
- `unsafe`、`extern`、`where`、lifetime、const generic 等 signature 组成片段。

宏相关策略：

- 对 `macro_rules!`、`#[macro_export]`、item-like macro invocation，需要识别其存在与导出性；
- 对无法稳定理解的宏 body，不做展开，而是用 `skip_balanced` / `recover_until` 跳过 token tree；
- 宏可以阻塞局部语法，但 #strong[不能阻塞 top-level public item 扫描继续前进]。

== Rust 首期必须覆盖的 surface

- `pub mod` / `pub use` / `pub fn` / `pub struct` / `pub enum` / `pub trait` / `pub type`；
- trait / impl / associated item；
- `typeParams` / lifetime / const generic / where clause；
- `unsafe` / `externAbi`；
- doc comment / deprecated attribute；
- exported macro 定义或调用；
- 当前 fixture 已验证的 `implements` / `has_member` / `traitTarget` / `implTarget` 等字段。

== Rust 风险边界

首期不承诺：

- proc-macro 展开结果；
- name resolution、type inference、宏 hygiene；
- 复杂 `cfg` 条件下的精确可见性求值；
- 编译器级 item tree / HIR 完整一致性。

但 A003 要求：#strong[即便只做启发式，也要在当前 fixture surface 上稳定产出与验证模式一致的最终结果]。

= 与 `CIQ Bundle` / metadata 的关系

== 顶层 bundle contract 不变

共享核心与验证模式都继续输出当前的 bundle 结构：

- `declarations.ndjson`
- `symbols.ndjson`
- `metadata.json`
- `manifest.json`
- `checksums.txt`
- `bundle.ciq.tgz`

新的原则是：#strong[这些文件本身不承载“允许 backend 漂移”的语义]。任何 backend / validation 信息都只能是附加、可规范化或可迁移的运行元数据，不能导致 golden snapshot 分叉。

== metadata 策略

A003 推荐把 bundle metadata 重新收敛为“canonical engine”视角：

```json
{
  "extractor": {
    "engine": "moonbit-public-api-parser",
    "validation": "none | lsp",
    "mode": "parser-first",
    "version": "v0.1.0",
    "fallback": false,
    "stats": {
      "declarations": 148,
      "symbols": 201,
      "diagnosticFiles": 0
    }
  }
}
```

如果仓内暂时保留 `backend` / `routing` 字段，也应满足：

- 它们不能让 canonical snapshot 分叉；
- snapshot normalization 必须把运行期差异字段去噪；
- benchmark / report 中可以保留更丰富的 mode 信息，但 bundle 本体仍以一致性优先。

= 共享快照与 benchmark 设计

== 快照策略

A003 推荐把当前 `examples/*/snapshots/lsp` 迁移为更中性的 canonical snapshot（例如 `snapshots/shared`）。如果迁移成本过高，首期也可以让 `snapshots/lsp` 临时继续承载 canonical truth，但必须满足：

- 不再新增 `snapshots/native` 作为第二份 canonical snapshot；
- 所有 `native` / `lsp` 运行都对比同一份黄金快照；
- 若 bundle 有差异，则视为 semantic parity 失败，而不是“允许存在另一份 golden”。

== benchmark 目标

benchmark 仍然需要回答三类问题：

1. 共享核心本身的性能、内存、体积表现；
2. 开启 LSP 验证后增加了多少额外成本；
3. LSIF dump 与 CIQ Bundle 在同一语料上的体积差异有多大。

但 benchmark 成功的前提是：#strong[canonical output 完全一致]。

== benchmark 指标

#table(
  columns: (20%, 24%, 18%, 38%),
  inset: 6pt,
  stroke: 0.4pt,
  [*指标*], [*字段建议*], [*是否必须*], [*说明*],

  [语义一致性], [`snapshotDiffCount` / `parity`], [是], [`snapshotDiffCount` 必须为 `0`，否则本次 run 只能算失败样本。],
  [性能], [`wallMs` / `cpuMs`], [是], [比较 shared core 单跑与附带 LSP 验证时的额外成本。],
  [内存], [`peakRssMb`], [是], [避免把更快建立在不受控的内存膨胀上。],
  [CIQ 体积], [`bundleBytesRaw` / `bundleBytesGzip`], [是], [衡量自身产物成本。],
  [LSIF 体积], [`lsifBytesRaw` / `lsifBytesGzip`], [是], [完成 todo 中对 LSIF vs CIQ Bundle 的对账。],
  [对象规模], [`declarations` / `symbols` / `bytesPerDeclaration`], [是], [帮助解释不同 fixture 的 size 差异。],
)

== benchmark harness 的推荐形态

推荐提供：

- `src/scripts/benchmark/main.mbt`：benchmark 脚本入口；
- `src/cmd/build/bench.mbt`：共享 benchmark utility；
- canonical snapshot 读取器：统一读取同一份 golden snapshot；
- 可选 LSP validator：只负责对照，不直接 author bundle；
- `examples/*/full/bench/lsif/`：LSIF dump 与 size summary。

= 验证与落地阶段

#table(
  columns: (14%, 16%, 28%, 42%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Stage*], [*状态*], [*范围*], [*验收结果*],

  [`A003-1`], [#strong[planned]], [contract reset], [冻结“single semantic core + shared snapshot + parity required”的新 contract。],
  [`A003-2`], [#strong[planned]], [publishable parsing framework], [`src/lib/parsec/` 中最小 parser combinator 与 token stream library 可运行，并具备独立发布边界。],
  [`A003-3`], [#strong[planned]], [Go heuristic parser], [`src/lib/extract/go` 基于 `@parsec` 与 `@extract` 在共享快照上通过 parity 验证。],
  [`A003-4`], [#strong[planned]], [Rust heuristic parser], [`src/lib/extract/rust` 基于 `@parsec` 与 `@extract` 在共享快照上通过 parity 验证。],
  [`A003-5`], [#strong[planned]], [LSP validation + benchmark], [LSP 模式只做验证 / benchmark，且 `snapshotDiffCount == 0`。],
  [`A003-6`], [#strong[planned]], [cleanup & docs], [移除 helper-binary-first 叙述，文档与 progress 全部与 shared core reality 对齐。],
)

= 风险与缓解措施

#table(
  columns: (28%, 30%, 42%),
  inset: 6pt,
  stroke: 0.4pt,
  [*风险*], [*影响*], [*控制措施*],

  [通用 framework API 被语言细节污染], [`parsec` 难以独立发布或稳定演进], [严格限制 `@parsec` 只暴露通用 parsing primitives，把 Go/Rust-specific helper 留在 `@extract/*`。],
  [启发式 parser 对 Rust 宏支持不足], [Rust fixture parity 无法达标], [把 token tree 与恢复组合子放在首期核心能力中，并显式冻结当前 fixture surface。],
  [语义扩展只改一边], [shared snapshot 立刻分叉], [把“任何新语义必须 shared core + validator 同步进入”写入验收与 code review 规则。],
  [metadata 过度暴露运行模式], [即使 declarations 一致，snapshot 仍被 metadata 噪声打碎], [把 backend-specific 字段迁出 canonical truth，或纳入 normalization。],
  [追求性能导致过度跳过], [public API coverage 回退], [把当前 e2e / snapshot 已覆盖字段列为首期硬边界。],
  [helper binary 旧实现继续污染叙述], [团队对主路径产生误解], [在 plan / progress / A003 中把它们降级为 legacy compatibility path。],
)

= 验收

本提案对应的实现完成时，至少应满足：

- Go / Rust 的最终 bundle 都来自 MoonBit extraction 层，而该层建立在独立的 `@parsec` framework 之上；
- `validation=lsp` 与 `validation=none` 对同一份代码产出的 canonical snapshot 完全一致；
- canonical snapshot 只有一份；
- `snapshotDiffCount == 0` 成为 parity 通过条件；
- benchmark harness 能输出 shared core vs shared core + LSP validation 以及 LSIF vs CIQ Bundle 的指标；
- 仓库中不再把 helper binary 或 `snapshots/native` 描述为主设计事实。

建议的验收命令如下：

```bash
typst compile spec/A003-native-extractor.typ /tmp/codeiq-a003.pdf
moon test src/cmd/build/snapshot_test.mbt
moon test src/e2e
moon run src/scripts/benchmark -- --profile go-module --fixture full --validation lsp
moon run src/scripts/benchmark -- --profile rust-crate --fixture full --validation lsp
```

= 相关研究与实践基础

本提案直接参考以下现实：

- Rust `nom` 证明了“小而稳定的 combinator surface + recoverable / cut / delimited”足以支撑一个可独立发布的 parsing framework；
- `chumsky` 等库表明 nested input / token tree / recovery 对复杂语法尤其重要；
- 仓内 `src/lib/hcl/parse.mbt` 与 MoonBit TOML parser 参考已经展示了 parser-first 的实现风格；
- LSIF / SCIP 继续只作为对照物，而不是 CodeIQ 的主产物。

关键参考链接：

- `nom`: `https://github.com/rust-bakery/nom`
- `chumsky`: `https://github.com/zesterer/chumsky`
- LSIF: `https://code.visualstudio.com/blogs/2019/02/19/lsif`
- `src/lib/hcl/parse.mbt`
- `.claude/skills/moonbit-lang/reference/toml-parser-parser.mbt`

= 当前阶段结论

A003 现在的重点不再是“再造一个与 LSP 并列的 native backend”，而是：#strong[把 CodeIQ 的抽取层收敛成“可独立发布的 parsing framework + 项目内 extraction 层”两层结构]。只要继续守住四条底线——#strong[framework 与语言 parser 分层、canonical snapshot 只有一份、最终输出不能漂移、任何新语义必须双模式同轮收敛]——那么 Go / Rust 的启发式高性能抽取就会是一条可持续演进的架构路径，而不是再次引入分叉真相源。
