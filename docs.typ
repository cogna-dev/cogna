#set text(font: "Source Han Sans", lang: "zh", region: "cn", size: 10.5pt)
#show heading.where(level: 1): set text(size: 18pt, weight: "bold")
#show heading.where(level: 2): set text(size: 14pt, weight: "bold")
#show heading.where(level: 3): set text(size: 11.5pt, weight: "bold")
#show table.cell: set align(left)

#align(center)[
  = CodeIQ 用户视角文档重写提纲
  #v(6pt)
  #text(size: 10pt, fill: rgb("666666"))[第一版：索引与内容概要（供审核）]
]

= 重写目标

这份提纲不直接改写 `docs/` 现有页面，而是先回答两个问题：

- #strong[用户进入文档站后，应该先看到什么？]
- #strong[不同角色的用户，应该沿着什么顺序理解 CodeIQ？]

建议把新文档改写成 #strong[用户任务优先] 的结构，而不是按内部模块或实现目录来组织。核心原则如下：

- #strong[先讲价值，再讲实现]：先回答“我为什么要用它”“今天能帮我做什么”；
- #strong[先讲路径，再讲概念]：先给第一次成功路径，再补 bundle / diff / policy / MCP 的模型；
- #strong[Guide / Concept / Reference 分层]：任务文档、概念文档、参考文档不要混写；
- #strong[明确 current scope]：持续强调当前是 #strong[单机 CLI + Local Registry + local query runtime]，避免用户误解成 hosted platform；
- #strong[对 AI 用户友好]：把 `outlines -> symbol`、本地 cache、SARIF、PURL 等高频概念放到用户能直接复用的位置。

= 推荐导航索引

建议把文档导航重组为四层：#strong[Start Here]、#strong[Common Tasks]、#strong[Core Concepts]、#strong[Reference & Status]。

#table(
  columns: (14%, 24%, 18%, 44%),
  inset: 6pt,
  stroke: 0.4pt,
  [*分组*], [*建议页面*], [*目标读者*], [*这一页回答什么问题*],

  [Start Here], [1. CodeIQ 能帮我解决什么问题？], [所有新用户], [CodeIQ 是什么、和普通文档检索/静态检查有什么不同、适合哪些场景、当前边界是什么],
  [Start Here], [2. 第一次跑通：10 分钟完成 build -> diff -> check -> query], [第一次试用者], [如何最快得到一次成功体验、每一步会产出什么、看到什么结果算成功],

  [Common Tasks], [3. 发版前兼容性检查], [SDK / API / 平台维护者], [发布前如何生成 diff、执行 policy check、读取 SARIF、判断是否可放行],
  [Common Tasks], [4. 让 AI / Agent 查询依赖与 API], [AI 使用者、代码审查者], [什么时候用 CLI query，什么时候用 MCP，为什么推荐 `outlines -> symbol`],
  [Common Tasks], [5. 在本机共享 bundle：publish / registry / materialize], [本地自动化、团队维护者], [如何把 bundle 写入共享本地 store、如何按 PURL 下载和物化、哪些能力明确不做],

  [Core Concepts], [6. 理解 CodeIQ 产物：Config / Bundle / OPA Bundle / Diff / Result / SARIF], [需要建立心智模型的用户], [每种产物是什么、谁生成它、谁消费它、应该什么时候关心它],
  [Core Concepts], [7. 理解 Local Registry、PURL 与 local query runtime], [进阶用户], [为什么是 local-only、PURL 在这里起什么作用、Registry 和 MCP 的职责边界是什么],
  [Core Concepts], [8. 支持范围与当前限制], [评估落地可行性的用户], [支持哪些 profile、哪些语义已经稳定、哪些只是当前边界内的最小承诺],

  [Reference & Status], [9. CLI Reference], [需要精确查命令的人], [各命令参数、输入输出、常见组合、当前行为边界],
  [Reference & Status], [10. MCP / Registry Reference], [需要接自动化的人], [MCP tools、Registry endpoints、本地 runtime 行为与结果结构],
  [Reference & Status], [11. Progress / Product Status], [想看成熟度与范围的人], [当前 release ledger、scope reset、明确非目标、当前已验证基线],
)

= 每一页的内容概要

== 1. CodeIQ 能帮我解决什么问题？

建议定位为新的首页/概览页，用用户语言回答价值，而不是先讲实现细节。

建议包含：

- CodeIQ 的一句话定位；
- 典型场景：SDK 发版、OpenAPI 变更、Terraform Module 升级、AI 查询第三方依赖；
- 和 README / grep / LSP / lint 的区别；
- 一张用户工作流图：`build -> diff -> check -> query/publish`；
- 当前产品边界：single-machine、local-only、query runtime 只负责查询。

== 2. 第一次跑通：10 分钟完成 build -> diff -> check -> query

这一页应该是新用户第一条成功路径。

建议包含：

- 前置条件（本地环境、OPA CLI、可用仓库）；
- 最短命令序列；
- 每一步会看到的输出文件；
- 如何判断自己已经“跑通”；
- 下一步分流：继续做发布前检查、继续接 AI、继续做本地共享。

== 3. 发版前兼容性检查

这页对应最强用户价值：发布前 gate。

建议包含：

- 适用对象：SDK / API / Terraform / OpenAPI 维护者；
- 从 bundle 到 diff 到 check 的最短路径；
- `CIQ Diff` 里用户最应该关心哪些字段；
- `SARIF` 如何解读（error / warning / note）；
- 本页只讲用户动作，不深入 OPA bundle 内部结构。

== 4. 让 AI / Agent 查询依赖与 API

这页应该明确解释：为什么有时用 `query`，有时用 MCP。

建议包含：

- 一次性查询 vs 交互式查询的选择标准；
- 推荐顺序：`codeiq.query.outlines -> codeiq.query.symbol`；
- AI 用户会拿到什么信息（签名、位置、契约摘要、richer payload）；
- 当前 local query runtime 的边界；
- 常见误解：MCP 不负责 build / diff / check / publish。

== 5. 在本机共享 bundle：publish / registry / materialize

这页面向希望在本机多个工具之间复用 bundle 的用户。

建议包含：

- 为什么要 publish 到本地 shared store；
- `publish`、`registry download-local`、`registry download` 分别解决什么问题；
- `.codeiq/cache/registry/*` 与 `.codeiq/cache/mcp/*` 的角色；
- Local Registry 是 façade，不是 hosted cloud product；
- 适合的用户：本地自动化、评审流程、AI runtime 复用。

== 6. 理解 CodeIQ 产物：Config / Bundle / OPA Bundle / Diff / Result / SARIF

这页是核心概念页，建议用“谁生成、谁消费、什么时候需要关心”来写。

建议包含：

- `CIQ Config`：初始化与 profile 选择；
- `CIQ Bundle`：声明、symbol、software component、SBOM；
- `CIQ OPA Bundle`：policy check 用的本地 bundle；
- `CIQ Diff`：变更事实，不是源代码 patch；
- `CIQ Result`：查询结果；
- `SARIF`：给审查与 CI 消费的检查输出。

== 7. 理解 Local Registry、PURL 与 local query runtime

这页解释系统边界与名词，而不是教用户敲命令。

建议包含：

- 为什么 current scope 是 local-only；
- PURL 在 bundle identity、download、query 中的作用；
- Registry 与 MCP 的职责分工；
- “local private registry / local cache / local query runtime” 这组术语应该如何理解；
- proposal 与当前实现的差异，以用户能理解的口径写清楚。

== 8. 支持范围与当前限制

这页是用户做落地评估时最关心的页面。

建议包含：

- 当前支持的 profile：Go、Rust、Terraform、OpenAPI、policy-bundle；
- 当前能稳定产出的声明事实 / component facts / SBOM facts；
- 当前不是目标的内容：hosted、distributed、trust verifier、remote registry；
- 用户在评估引入时最需要知道的 caveats。

== 9. CLI Reference

保留为 reference 页面，但应减少 roadmap 口吻，增加“什么时候用这个命令”。

建议包含：

- 命令总览表；
- 每个命令的最常用调用方式；
- 输入输出产物；
- 常见命令组合；
- 把“实现背景”移到概念页或状态页，避免参考文档过重。

== 10. MCP / Registry Reference

建议把当前 `mcp.mdx` 和 Registry API/reference 内容重组到一页或两页里，但导航上仍作为同组 reference 出现。

建议包含：

- MCP tools：`codeiq.query.outlines`、`codeiq.query.symbol`、`codeiq.runtime.context`；
- MCP runtime：`start / serve / status / stop`；
- Registry endpoints：publish、resolve、versions、detail、download；
- 返回结构的用户级解释；
- 当前明确边界：都是 local-only runtime。

== 11. Progress / Product Status

这一页保留，但应明确它回答的是“成熟度与边界”，不是“怎么用”。

建议包含：

- release ledger；
- 当前 active scope；
- proposal -> implementation reconciliation 摘要；
- 明确非目标；
- 最新已验证基线。

= 建议的重组关系（现有页面 -> 新结构）

#table(
  columns: (30%, 30%, 40%),
  inset: 6pt,
  stroke: 0.4pt,
  [*现有页面*], [*建议去向*], [*处理建议*],

  [`introduction.mdx`], [页面 1 + 页面 8], [保留定位与价值说明，把边界/限制拆去“支持范围与当前限制”],
  [`quickstart.mdx`], [页面 2], [保留为第一条成功路径，并减少术语铺陈],
  [`indexing.mdx`], [页面 4 + 页面 6], [把 AI 查询路径写进任务页，把 bundle / outlines / symbol 的模型写进概念页],
  [`mcp.mdx`], [页面 4 + 页面 10], [把使用路径与 reference 拆开],
  [`cli.mdx`], [页面 9 + 页面 5], [保留命令参考，同时把 publish / registry 的用户动作提炼成任务页],
  [`providers.mdx`], [页面 8], [从 extractor 内部矩阵改写成“用户现在可以信赖什么”],
  [`progress.mdx`], [页面 11], [继续保留为状态页，不放太多首次使用信息],
)

= 推荐的首页进入路径

建议首页只提供三条入口，让不同用户快速选路：

1. #strong[我第一次接触 CodeIQ] -> 跳到“10 分钟完成 build -> diff -> check -> query”；
2. #strong[我想在发版前做兼容性检查] -> 跳到“发版前兼容性检查”；
3. #strong[我想让 AI 查询依赖 / API] -> 跳到“让 AI / Agent 查询依赖与 API”。

这样可以避免首页同时承担“产品介绍、术语解释、命令手册、进度面板”四种职责。

= 审核点

这版提纲建议你重点审核以下问题：

- 这个导航是否符合你希望的用户心智，而不是 repo 内部模块心智？
- `Guide / Concept / Reference / Status` 四层是否清晰？
- 是否需要把 “发版前兼容性检查” 和 “共享本地 bundle” 再拆得更细？
- 是否接受把当前 `providers.mdx` 从 extractor 报告改写成“支持范围与当前限制”的用户文档？
- `MCP / Registry Reference` 是合并成一页更好，还是拆成两页更好？

如果这个索引方向通过，下一步再按这个结构逐页重写 `docs/src/content/docs/*`。
