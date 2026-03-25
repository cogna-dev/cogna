#import "@preview/arkheion:0.1.1": arkheion
#import "@preview/fletcher:0.5.8": diagram, node, edge

#set text(font: "Source Han Sans", lang: "zh", region: "cn")
#show table.cell: set align(left)

#show: arkheion.with(
  title: "LSP 提取器",
  authors: (
    (name: "Yufei Li", email: "yufeiminds@gmail.com", affiliation: ""),
  ),
  abstract: [
    本提案定义 CodeIQ 中 `LSP Extractor` 的边界、职责和接入方式。核心结论是：LSP 只在 `build` 命令内部作为一次性抽取后端运行，与 `codeiq build` 进程同生共死，在 `CIQ Bundle` 产出后立即退出；因此本提案不把它设计为常驻服务，也不引入独立的 HTTP 网关或长期生命周期管理。更关键的是，#strong[`LSP Extractor` 不是 CodeIQ 的最终形态，而是该项目在抽取层的 baseline]：后续将实现原生的 `CodeIQ Extractor`，并使用同一套 examples 语料、快照结果与性能指标，对 `CodeIQ Extractor` 和 `LSP Extractor` 进行交叉验证与基准测试。LSP 的价值，不在于替代 CIQ 或提供在线导航，而在于为 `build` 阶段补充符号、定义、类型、签名、注释与位置信息，最终写入 `declarations.ndjson`、`symbols.ndjson` 与 `metadata.json`，再供后续 `diff`、`query`、`mcp start`、`check` 等命令离线消费。
  ],
  keywords: ("CodeIQ", "CIQ", "LSP", "Build", "MCP", "Go", "Rust", "Terraform", "OpenAPI"),
  date: "March 21, 2026",
)

= 提案目标与边界

本提案讨论的不是“是否把 CodeIQ 变成一个 LSP 服务器”，而是：#strong[是否在 `build` 命令内部引入一个一次性 LSP 抽取后端，以更稳定地获取公开声明相关信息，并把这些信息固化到 `CIQ Bundle` 中]。

本提案的目标有三项：

- #strong[提高 `build` 阶段的声明抽取质量]：对 Go / Rust 这类语言，利用语言服务器已有的符号与类型理解能力，补足仅靠浅层语法遍历时容易遗漏的公开声明上下文。
- #strong[把 LSP 输出转换为 CIQ 可复用事实]：LSP 只参与抽取，不直接对外服务；真正对外暴露的仍然是 `CIQ Bundle`、`CIQ Diff`、`CIQ Result` 与 MCP 工具结果。
- #strong[保持 CodeIQ 的产品边界不变]：CodeIQ 依旧是面向公开接口治理的工具，而不是 IDE 导航系统或常驻代码情报服务。
- #strong[建立未来 `CodeIQ Extractor` 的交叉验证与性能基线]：LSP Extractor 的输出、快照与耗时统计，将作为后续原生抽取器的对照组，而不是长期唯一实现。

本提案的非目标同样需要明确：

- 不把 LSP 作为 `query`、`mcp start`、`diff`、`check` 的在线依赖。
- 不引入常驻 LSP 守护进程、共享连接池或独立 HTTP 服务。
- 不让 LSP diagnostics、code action、completion 这类 IDE 能力主导 CodeIQ 的产品定位。

= 核心决策

== 决策摘要

#table(
  columns: (24%, 28%, 48%),
  inset: 6pt,
  stroke: 0.4pt,
  [*决策项*], [*提案结论*], [*说明*],
  [LSP 的运行时机], [`build` 内部], [仅在 `codeiq build` 阶段启动，用于提取与补充声明事实],
  [LSP 的生命周期], [与 `codeiq build` 同生共死], [Bundle 生成后立即退出，因此不存在常驻生命周期管理问题],
  [LSP 的产品角色], [抽取 baseline], [后续 `CodeIQ Extractor` 将复用同一语料与快照，对 LSP baseline 做交叉验证与性能对比],
  [对外接口], [无独立接口], [LSP 不直接对用户、CLI 或 MCP 暴露任何在线协议],
  [下游消费方式], [只消费 `CIQ Bundle`], [`diff` / `query` / `mcp start` / `check` 均只读取产物，不访问活跃 LSP],
  [适用范围], [Go / Rust 强依赖 LSP；Terraform parser-first], [Go / Rust 在 build 阶段直接启动 `gopls` / `rust-analyzer`，失败即报错；Terraform 走独立 `lib/hcl` 解析包；OpenAPI 仍以规格解析为主],
)

== 与此前可行性研究的关系

此前研究中讨论过 `subprocess + HTTP` 的实现形态，但对本项目当前阶段而言，这一形态#strong[不是必要条件]。原因很简单：本提案已经把 LSP 明确限定为 `build` 内部的一次性子过程。既然它不需要跨命令复用，也不需要为 `query` 或 MCP 提供在线服务，那么：

- 进程间通信优先采用 #strong[stdio / pipe] 即可；
- 只需要处理 #strong[单次构建过程中的超时、退出码与错误回收]；
- 不需要设计常驻连接、服务发现、租约、工作区池化等长期运行机制。

因此，本提案的结论是：#strong[LSP Extractor 是 build-time extractor backend，而不是 runtime query service]。

= 与未来 `CodeIQ Extractor` 的关系

本提案必须明确 `LSP Extractor` 在整体路线中的定位：#strong[它是 baseline，而不是终局]。

后续项目会实现一套原生的 `CodeIQ Extractor`，直接面向 CIQ 声明模型进行抽取。届时：

- `LSP Extractor` 继续保留，用于 #strong[交叉验证]：在同一份 examples 语料上比较声明覆盖率、`id` 稳定性、`path`/`signature` 一致性、文档和位置提取结果。
- `LSP Extractor` 继续保留，用于 #strong[性能基准]：记录 `build` 总耗时、抽取阶段耗时、产物大小等指标，作为 `CodeIQ Extractor` 的对照组。
- `CodeIQ Extractor` 才是未来的主抽取器；`LSP Extractor` 应被理解为一种#strong[参考实现与验证工具]。

#table(
  columns: (24%, 20%, 56%),
  inset: 6pt,
  stroke: 0.4pt,
  [*比较项*], [*LSP Extractor*], [*未来 `CodeIQ Extractor` 的关系*],
  [产品定位], [基线抽取器], [提供第一版可运行的 build-time declaration baseline],
  [正确性角色], [参考答案之一], [用于与原生抽取器做快照级交叉验证],
  [性能角色], [对照组], [用于比较耗时、产物大小、记录数量与失败率],
  [长期职责], [保留但不做中心], [让原生抽取器逐步超越 baseline，而不是取代 CIQ Bundle 工作流],
)

= 为什么需要 LSP 提取器

CodeIQ 的核心产物是声明快照，而不是导航索引。但在真实工程里，仅靠轻量语法扫描，往往很难稳定获得以下信息：

- 公开符号的#strong[规范路径]与所属作用域；
- 符号的#strong[精确声明位置]与多文件跳转结果；
- 类型别名、返回类型、关联类型、实现关系等#strong[语义层信息]；
- 函数、方法、trait item、接口方法的#strong[签名与文档摘要]。

这些信息恰好与语言服务器擅长的领域重合。对于 CodeIQ 来说，LSP 的价值不在于“让用户在线点跳转”，而在于：#strong[在 build 时把语言服务器已经能回答的问题，转写为版本绑定、可缓存、可 diff、可 query 的 CIQ 事实]。

= 执行时机与生命周期设计

== build-only 原则

本提案要求 LSP 只在 `build` 命令中起作用。它的触发条件是：

- 当前 `profile` 属于支持 LSP 增强抽取的语言生态；
- 当前机器已安装对应语言服务器，或项目工具链可在本地找到它；
- 该语言的 LSP 输出能够为 CIQ 事实生成带来实质收益。

一旦进入 `build`：

1. `codeiq build` 读取 `CIQ Config` 并识别 profile；
2. 若该 profile 启用 LSP 增强，则以子进程方式启动对应语言服务器；
3. 在当前仓库工作区内完成初始化、文件发现、符号/定义/hover 等抽取；
4. 将结果归一化并写入 `CIQ Bundle`；
5. 构建结束后关闭 LSP 子进程，结束整个命令。

因此，本提案的一个关键结论是：#strong[不存在“LSP 生命周期管理”这个独立问题]。真正需要处理的，只是 `build` 命令内部的普通子进程控制问题，例如超时、退出码、异常输出与失败回退。

#figure(
  diagram(
    cell-size: 7mm,
    node-stroke: 0.8pt,
    node((0, 0), [`codeiq build`], corner-radius: 2pt),
    node((1, 0), [启动 LSP 子进程], corner-radius: 2pt),
    node((2, 0), [抽取符号与声明信息], corner-radius: 2pt),
    node((3, 0), [归一化为 CIQ 记录], corner-radius: 2pt),
    node((4, 0), [写出 `CIQ Bundle`], corner-radius: 2pt),
    node((5, 0), [关闭 LSP 子进程], corner-radius: 2pt),
    edge((0, 0), (1, 0), "-|>", [读取 profile], label-pos: 0.5),
    edge((1, 0), (2, 0), "-|>", [stdio 通信], label-pos: 0.5),
    edge((2, 0), (3, 0), "-|>", [结构化抽取], label-pos: 0.5),
    edge((3, 0), (4, 0), "-|>", [生成产物], label-pos: 0.5),
    edge((4, 0), (5, 0), "-|>", [构建结束], label-pos: 0.5),
  ),
  caption: [LSP 提取器仅在 `build` 阶段存活]
)

== 与其它命令的边界

#table(
  columns: (18%, 18%, 64%),
  inset: 6pt,
  stroke: 0.4pt,
  [*命令*], [*是否直接使用 LSP*], [*说明*],
  [`init`], [否], [只生成配置模板，不需要语义抽取],
  [`build`], [是], [唯一允许启动 LSP 的命令；负责抽取并写入 Bundle],
  [`diff`], [否], [只比较两个既有 `CIQ Bundle` 的声明事实],
  [`check`], [否], [只消费 `CIQ Diff` 与本地 `CIQ OPA Bundle`],
  [`query`], [否], [只查询本地已存在 Bundle 中的结构化记录],
  [`publish`], [否], [只上传整包产物，不参与语义提取],
  [`mcp start`], [否], [只把本地已装载 Bundle 暴露为查询工具，不依赖活跃 LSP],
)

= LSP 能提供哪些信息，以及这些信息在 CodeIQ 中如何使用

这是本提案最关键的部分：#strong[LSP 的价值必须被具体映射到 CodeIQ 的产物与命令上]。如果某类 LSP 信息无法进入 CIQ 事实链路，就不应该进入首期方案。

== 采用的信息

#table(
  columns: (18%, 22%, 26%, 34%),
  inset: 6pt,
  stroke: 0.4pt,
  [*LSP 信息*], [*代表性接口*], [*写入 CodeIQ 的位置*], [*在项目中的具体用途*],
  [公开符号大纲], [`textDocument/documentSymbol`], [`symbols.ndjson`、`declarations.path`、`canonical_name`], [为 `query.outlines` / MCP 大纲浏览提供候选列表；为 `build` 生成符号树和作用域路径],
  [定义 / 声明位置], [`textDocument/definition`、`textDocument/declaration`], [`source_refs`、稳定 `id`、路径归一化], [为 `query.symbol` 提供精确位置；为 `diff` 的声明匹配提供更稳定的 identity；为 `check` / SARIF 提供更可信的位置证据],
  [类型定义信息], [`textDocument/typeDefinition`], [`shape` 候选信息、`relations.references_type`], [补充函数参数、返回值、字段引用的类型上下文；为未来更细粒度的兼容性判定提供基础],
  [签名与文档摘要], [`textDocument/hover`], [`signature`、`docs`、`summary`], [提升 `query` 与 MCP 返回结果的人类可读性；在 diff 结果中提供更好的解释文本],
  [引用 / 实现关系], [`textDocument/references`、`textDocument/implementation`], [`relations` 的扩展槽位], [用于未来的影响分析、`implements` / `references_type` 关系补充；首期可选实现],
)

== 这些信息分别落在哪些功能上

#table(
  columns: (24%, 19%, 57%),
  inset: 6pt,
  stroke: 0.4pt,
  [*CodeIQ 功能*], [*是否直接使用 LSP 输出*], [*具体表现*],
  [`build`], [直接使用], [启动 LSP、读取符号/定义/hover 等结果，并把它们归一化为 `declarations.ndjson`、`symbols.ndjson`、`metadata.json`],
  [`CIQ Bundle`], [间接承载], [成为 LSP 输出的最终持久化载体；后续命令只读这些记录],
  [`diff`], [间接使用], [通过更稳定的 `id`、`path`、`source_refs`、`signature` 提高声明匹配与变化解释的质量],
  [`check`], [间接使用], [通过更精确的位置和声明证据，生成更可读的 SARIF 结果，但不直接调用 LSP],
  [`query`], [间接使用], [返回 `build` 时固化下来的 `signature`、`docs`、`location`、`relations` 等信息],
  [`mcp start`], [间接使用], [MCP 工具复用 Bundle 中已缓存的事实，而不是在线转发 LSP 请求],
)

== 这些信息如何用于未来 `CodeIQ Extractor` 交叉验证

LSP 信息不仅服务当前功能，也服务未来原生抽取器的验证工作。建议把交叉验证聚焦在以下维度：

#table(
  columns: (20%, 30%, 50%),
  inset: 6pt,
  stroke: 0.4pt,
  [*信息类型*], [*与 `CodeIQ Extractor` 的比较点*], [*比较方法*],
  [symbol outline], [公开接口覆盖率], [比较 `symbols.ndjson` 中的 `path`、`kind`、`summary` 与父作用域层级],
  [definition / declaration], [`id` 与位置稳定性], [比较 `id`、`canonical_name`、`source_refs.uri`、行号区间是否一致],
  [typeDefinition], [类型关系抽取质量], [比较 `shape` 与 `relations.references_type` 等字段的完整度],
  [hover/docs], [签名与文档摘要质量], [比较 `signature`、`docs`、`summary` 的可读性与字段缺失率],
  [diagnostics], [抽取置信度与失败分析], [比较哪些文件需要 fallback、哪些文件发生抽取缺口],
)

== 明确不采用的信息

为了避免 CodeIQ 偏离“声明治理工具”的定位，下列 LSP 能力#strong[不应作为首期方案的一部分]：

#table(
  columns: (24%, 24%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*LSP 能力*], [*是否采用*], [*原因*],
  [diagnostics], [否], [CodeIQ 不是 lint / bug finding 工具；`check` 的结果来自 `CIQ Diff + OPA`，不是来自语言服务器告警],
  [completion], [否], [属于交互式 IDE 能力，无法沉淀为稳定的 Bundle 事实],
  [codeAction], [否], [属于编辑建议，不是声明级证据],
  [rename], [否], [是重构操作，不是 build 时可发布的事实],
  [semanticTokens], [否], [对 CodeIQ 的公开接口治理收益有限，且很难直接映射为稳定的 CIQ 字段],
)

= 按语言生态的适用性

不同 profile 的抽取策略不同：Go / Rust 在当前阶段把 LSP 作为 build-time 硬依赖；Terraform 走 parser-first（`lib/hcl`）；OpenAPI 保持 parser-only。

#table(
  columns: (18%, 18%, 28%, 36%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Profile*], [*当前策略*], [*主要收益*], [*权威数据来源*],
  [`go-module`], [LSP 硬依赖], [公开符号、方法集、定义位置、hover 文档、类型关系], [Go 源码 + `gopls`],
  [`rust-crate`], [LSP 硬依赖], [public item、trait item、impl 关系、类型定义、签名与文档], [Rust 源码 + `rust-analyzer`],
  [`terraform-module`], [parser-first (`lib/hcl`)], [block/attribute/meta-argument 的结构化提取与可重复快照], [HCL/模块原始文件 + `src/lib/hcl`],
  [`openapi-spec`], [parser-only], [规格文本已结构化，LSP 增益低], [OpenAPI 文档本体],
)

这意味着实现策略应当分层：

- #strong[Go / Rust]：LSP 是构建硬依赖，启动失败即失败；
- #strong[Terraform]：使用 `lib/hcl` 解析器，不依赖 `terraform-ls`；
- #strong[OpenAPI]：不依赖 LSP，直接解析规格文件。

= 功能输入输出设计

这里的“输入输出”，不是指整个 `codeiq build` 命令的 CLI 语法，而是指 #strong[LSP Extractor 作为 build 内部功能模块] 的输入输出契约。

== 输入

#table(
  columns: (22%, 26%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*输入项*], [*来源*], [*说明*],
  [仓库根目录], [`BuildParams.repo`], [当前待构建代码仓库的根目录，也是 LSP 工作区根目录],
  [`CIQ Config`], [`codeiq.yaml`], [至少提供 `profile`、`purl`、`source`、`inputs.include`、`checks` 等字段],
  [解析后的输入文件集合], [`inputs.include` 解析结果], [供 extractor 确定需要打开、索引与抽取的文件范围],
  [语言服务器描述], [本地工具链解析结果], [包括 server 名称、可执行命令、版本号、能力声明与是否启用 fallback],
  [抽取策略], [build 内部决策], [取值建议为 `parser-only`、`lsp-assisted`、`parser-first + lsp-supplement`],
)

建议把 LSP Extractor 的内部输入归一化为如下概念结构：

```json
{
  "repo": "./sdk",
  "profile": "go-module",
  "purl": "pkg:golang/github.com/gin-gonic/gin@1.10.0",
  "inputPatterns": ["**/*.go"],
  "extractor": {
    "mode": "lsp-assisted",
    "server": "gopls",
    "version": "<server-version>"
  }
}
```

== 输出

LSP Extractor 的输出分为两层：

- #strong[内层输出]：归一化后的声明、符号、文档、位置、统计和错误信息；
- #strong[外层输出]：落盘到 `CIQ Bundle` 的标准化文件。

#table(
  columns: (24%, 20%, 56%),
  inset: 6pt,
  stroke: 0.4pt,
  [*输出项*], [*文件/载体*], [*说明*],
  [声明记录], [`declarations.ndjson`], [逐行写出结构化声明，包含 `id`、`path`、`signature`、`shape`、`docs`、`source_refs`、`language_specific`],
  [符号大纲], [`symbols.ndjson`], [写出公开接口大纲与作用域关系，供 `query.outlines` / MCP 浏览],
  [抽取元数据], [`metadata.json`], [记录 extractor 模式、server、版本、fallback、统计信息与性能指标],
  [Bundle 描述], [`manifest.json`], [声明 artifact 列表、PURL、profile、source 信息与 schemaVersion],
  [摘要校验], [`checksums.txt`], [记录 bundle 内各文件摘要，便于回归比较与后续 Registry 校验],
)

建议把 `metadata.json` 扩展为如下形态：

```json
{
  "schemaVersion": "ciq-metadata/v1",
  "profile": "go-module",
  "inputPatterns": ["**/*.go"],
  "build": {
    "status": "completed"
  },
  "extractor": {
    "role": "baseline",
    "mode": "lsp-assisted",
    "server": "gopls",
    "version": "<server-version>",
    "fallback": false,
    "timingMs": {
      "initialize": 120,
      "extract": 840,
      "normalize": 75,
      "total": 1035
    },
    "stats": {
      "declarations": 148,
      "symbols": 201,
      "diagnosticFiles": 0
    }
  }
}
```

这个扩展有两个目的：

- 为当前 LSP Extractor 留下可追溯的 build 证据；
- 为未来 `CodeIQ Extractor` 提供稳定的 benchmark 对照字段。

= 对 `CIQ Bundle` 的具体影响

LSP 不引入新的顶层产物类型，它只增强已有 Bundle 文件。

#table(
  columns: (24%, 22%, 54%),
  inset: 6pt,
  stroke: 0.4pt,
  [*Bundle 文件*], [*LSP 参与方式*], [*预期写入内容*],
  [`declarations.ndjson`], [主要受益], [更完整的 `signature`、`docs`、`source_refs`、`canonical_name`、`relations`、`shape` 候选信息],
  [`symbols.ndjson`], [主要受益], [基于 document symbols 生成的公开接口大纲、path、kind、summary、owner scope],
  [`metadata.json`], [补充记录], [记录本次 build 是否启用了 LSP、使用了哪个 server、版本号、是否 fallback],
  [`manifest.json`], [通常不变], [无需暴露 LSP 细节，只需保持 Bundle 结构稳定],
)

其中，`metadata.json` 建议增加一类抽取来源信息，例如：

```json
{
  "extractor": {
    "mode": "lsp-assisted",
    "server": "gopls",
    "version": "<server-version>",
    "fallback": false
  }
}
```

这样做的目的不是让下游依赖 LSP，而是保留构建来源的可追溯性：当用户发现某个 Bundle 的符号路径或签名与预期不一致时，可以明确知道该记录是否由 LSP 辅助生成。

= 执行流程建议

== build 内部流程

首期建议的 `build` 内部流程如下：

1. 读取 `codeiq.yaml`，确定 `profile`、输入范围与 PURL。
2. 根据 `profile` 选择抽取策略：`parser-only`、`lsp-assisted` 或 `parser-first + lsp-supplement`。
3. 若启用 LSP，则启动对应语言服务器子进程，并完成最小初始化。
4. 针对公开入口文件或工作区范围，批量拉取 `documentSymbol`、`definition`、`typeDefinition`、`hover` 等信息。
5. 将 LSP 输出与本地解析结果合并，归一化为统一声明模型。
6. 写出 `declarations.ndjson`、`symbols.ndjson`、`metadata.json` 与 `manifest.json`。
7. 关闭 LSP 子进程，结束 `build`。

== 失败与回退策略

由于 LSP 只在 `build` 中起作用，因此失败处理也应当局限在 `build` 内：

- 若语言服务器不可用，则根据 profile 决定：
  - Go / Rust：构建直接失败并返回错误（不再降级到 parser-only）；
  - Terraform：不依赖 LSP，继续按 `lib/hcl` parser-first 路径执行；
  - OpenAPI：无影响。
- 若 LSP 返回结果不完整，则只把其作为#strong[补充信息]，不能覆盖更权威的直接解析结果。
- 若 LSP 与直接解析结果冲突，应优先保留#strong[更可验证、可重复、可解释]的一方，并在 metadata 中记录冲突或回退状态。

= `examples/` 测试用例集与快照设计

为了让 `LSP Extractor` 真正承担 baseline 角色，本提案要求在仓库根目录增加一个 #strong[`examples/`] 目录，作为多语言、可回放、可快照、可 benchmark 的统一语料集。

== 目录结构

建议目录结构如下：

```text
examples/
  go-module/
    full/
      repo/
      snapshots/
        lsp/
        codeiq/
  rust-crate/
    full/
      repo/
      snapshots/
        lsp/
        codeiq/
  terraform-module/
    full/
      repo/
      snapshots/
        lsp/
        codeiq/
  openapi-spec/
    full/
      repo/
      snapshots/
        lsp/
        codeiq/
```

其中：

- `repo/`：每个语言一份#strong[大而全]的完整示例工程；
- `snapshots/lsp/`：`LSP Extractor` 作为 baseline 生成的标准快照；
- `snapshots/codeiq/`：未来 `CodeIQ Extractor` 生成的快照输出位置；
- `full/`：表示该语料目标是覆盖该语言#strong[与声明抽取相关的完整公开语法面]，而不是只覆盖一个最小 happy path。

== 每种语言的示例工程要求

#table(
  columns: (18%, 30%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*语言/Profile*], [*示例工程必须覆盖的内容*], [*说明*],
  [`go-module`], [package doc、const/var、type alias、struct、embedded field、interface、generic type/function、method、re-export 风格注释、deprecated 注释], [覆盖 Go 公开 API 抽取的主要语法面，并验证 `gopls` 对 symbol / definition / hover 的输出是否稳定],
  [`rust-crate`], [pub module、pub fn、pub struct/enum、trait、impl、associated type、const、type alias、generic、where clause、re-export、doc comment、deprecated attribute], [覆盖 Rust crate 对外声明的主要语法面，并验证 `rust-analyzer` 对 item / impl / typeDefinition 的稳定性],
  [`terraform-module`], [variable、output、local、resource、data source、provider、module call、dynamic block、复杂 object type、validation、pre/postcondition], [尽管 Terraform 以 parser-first 为主，也要保留统一语料，验证 LSP 补充信息与原始解析结果的差异],
  [`openapi-spec`], [paths、operation、parameter、requestBody、response、component schema、allOf/oneOf/anyOf、securityScheme、discriminator、external `$ref`], [OpenAPI 不依赖 LSP，但必须纳入同一 examples 体系，作为未来 `CodeIQ Extractor` 的统一验证样本],
)

== 快照内容

每个 `snapshots/lsp/` 或 `snapshots/codeiq/` 目录都建议包含以下文件：

#table(
  columns: (26%, 22%, 52%),
  inset: 6pt,
  stroke: 0.4pt,
  [*快照文件*], [*来源*], [*作用*],
  [`manifest.json`], [build 输出], [验证 bundle 结构、schemaVersion、PURL、artifact 列表],
  [`metadata.json`], [build 输出], [验证 extractor 角色、模式、server 版本、fallback、统计与 timing],
  [`declarations.ndjson`], [排序稳定后的 `declarations.ndjson`], [作为声明级黄金快照，供 `CodeIQ Extractor` 做字段级对比],
  [`symbols.ndjson`], [排序稳定后的 `symbols.ndjson`], [作为大纲级黄金快照，验证 path / kind / summary / owner scope],
  [`summary.json`], [测试 harness 额外生成], [记录 declaration/symbol 数量、缺失率、冲突数与主要性能指标],
)

这里刻意把 `zst` 文件再转储为未压缩、排序稳定的 `*.ndjson` 快照，是因为：

- 人工 review 更容易；
- `git diff` 更容易对比；
- 后续 `CodeIQ Extractor` 可以直接做逐行、逐字段交叉验证。

== 测试流程

建议 extractor 测试 harness 统一遵循如下步骤：

1. 从 `examples/<profile>/full/repo/` 复制示例工程到临时目录；
2. 运行 `codeiq build`，启用 `LSP Extractor` baseline；
3. 读取临时目录下 `dist/manifest.json`、`dist/metadata.json`、`dist/declarations.ndjson`、`dist/symbols.ndjson`；
4. 对 declarations/symbols 做解压、排序、规范化 JSON 输出；
5. 将结果与 `examples/<profile>/full/snapshots/lsp/` 中的黄金快照比较；
6. 如果显式启用更新模式，则覆盖快照；否则任何 diff 都视为回归失败。

未来 `CodeIQ Extractor` 加入后，复用完全相同的 harness，只是把输出写到 `snapshots/codeiq/`，然后做三类比较：

- #strong[正确性比较]：字段、数量、位置、签名、文档和关系是否一致；
- #strong[差异归因]：哪些是 `CodeIQ Extractor` 的新增能力，哪些是回归；
- #strong[性能比较]：总耗时、抽取耗时、产物大小是否优于 LSP baseline。

== 快照测试与 MoonBit 测试体系的关系

本仓库当前的命令测试大多采用“临时目录 + 写入 fixture + 断言输出文件存在”的风格，而 MoonBit 本身也提供 `inspect(..., content=...)` 与 `t.snapshot(...)` 两类快照测试能力。因此本提案建议：

- #strong[examples 目录] 负责存放跨 extractor、跨版本长期保留的黄金语料与快照；
- #strong[MoonBit 测试 harness] 负责驱动 `build`、读取产物、比对快照，并在必要时支持更新快照；
- 二者结合后，既保留当前仓库已有的文件型测试风格，也为未来的跨 extractor 基准对比提供稳定入口。

= 方案收益

本提案成立后，CodeIQ 会得到三类直接收益：

- #strong[`build` 质量提升]：对 Go / Rust 公开接口的路径、签名、定义位置与文档摘要提取更完整。
- #strong[产物可读性提升]：`query` 与 MCP 返回结果会更接近开发者在 IDE 中理解库接口时真正关心的信息。
- #strong[`diff` 解释性提升]：当声明发生变更时，CodeIQ 可以用更稳定的符号路径、位置和签名来解释“到底变了什么”。
- #strong[为原生 `CodeIQ Extractor` 建立 benchmark]：同一套 examples 与快照会沉淀为长期可复用的正确性与性能基线。

但这些收益都必须建立在一个前提之上：#strong[所有在线 LSP 结果都必须在 build 阶段被固化为离线产物]。只有这样，CodeIQ 才仍然是一个以 Bundle 为核心的工程化工作流，而不是一个依赖外部运行时状态的查询系统。

= 风险与控制措施

#table(
  columns: (28%, 30%, 42%),
  inset: 6pt,
  stroke: 0.4pt,
  [*风险*], [*影响*], [*控制措施*],
  [语言服务器行为不一致], [不同语言生态的返回字段稳定性不同], [把 LSP 视为增强后端，而不是唯一真相来源；保留 parser-first 回退策略],
  [构建耗时增加], [`build` 时间可能上升], [仅在收益显著的 profile 上启用；为每类请求设置超时与并发上限],
  [定位漂移或签名不稳定], [影响 diff 匹配质量], [优先使用规范化 path 与稳定 id；将原始 LSP 输出视为证据而非最终主键],
  [baseline 快照陈旧], [会削弱对 `CodeIQ Extractor` 的参考价值], [为 examples 语料提供显式快照更新流程，并在 metadata 中记录生成版本与时间],
  [产品边界漂移], [误把 CodeIQ 做成导航系统], [严格限制 LSP 只在 `build` 中运行，下游统一只读 Bundle],
)

= 结论

本提案的最终结论可以概括为三句话：

1. #strong[LSP 提取器应当只在 `build` 中工作]，并与 `codeiq build` 同生共死；构建完 `CIQ Bundle` 就关闭，因此不存在独立的生命周期管理问题。
2. #strong[LSP 的价值必须体现在 Bundle 中]：它能提供符号、定义、类型、签名、文档与位置等信息，这些信息应分别进入 `declarations.ndjson`、`symbols.ndjson` 与 `metadata.json`，再被 `diff`、`query`、`check` 与 MCP 间接复用。
3. #strong[LSP 不是 CodeIQ 的产品中心]：CIQ Bundle 才是中心；LSP 只是 `build` 阶段的一个增强抽取后端，也是未来 `CodeIQ Extractor` 的 baseline、交叉验证对象和性能对照组。

如果后续实现遵循这一边界，那么 LSP Extractor 将会是对 CodeIQ 的一次#strong[增强抽取能力]补充，而不是一次#strong[产品定位]偏移。
