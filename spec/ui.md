# Cogna Desktop UI 设计（Shadcn 风格草案）

## 1. 目标

本设计围绕 `spec/api.md` 中定义的五个用户侧接口展开：

- `Build`
- `Diff`
- `FetchPackages`
- `QueryOutlines`
- `Query`

设计目标不是暴露内部 bundle / purl / SQL，而是提供一个面向“当前项目”的桌面探索器：

1. 用户先看到当前项目相关包树
2. 再浏览某个包的公开接口大纲
3. 再对该包做精确或模糊查询
4. `Build` / `Diff` 保持可见，但当前以 CLI guidance 形式提供

## 2. 设计原则

### 2.1 信息架构以 public API 为中心

UI 主叙事必须直接映射用户侧 API：

- 左侧：`FetchPackages`
- 中间：`QueryOutlines` / `Query`
- 顶部与辅助区：`Build` / `Diff` guidance

不在主界面暴露：

- bundle id
- bundle path
- internal SQL
- registry 内部缓存布局

### 2.2 Shadcn 风格，而不是 marketing landing page

视觉和交互参考 Shadcn / Radix 常见数据工作台风格：

- 深色背景
- 中性面板 + 清晰边框
- 圆角卡片
- 高信息密度但分区明确
- 轻量徽标、badge、segmented control、table/list/detail pane
- 支持 split-pane / master-detail 心智模型

### 2.3 Build / Diff 当前是“可指导，不强做”

根据当前产品方向：

- `Build`、`Diff` 暂不作为桌面 demo 的主交互入口
- UI 中展示当前状态、说明和 CLI 命令
- 让用户知道这两个能力存在，并知道下一步如何执行

## 3. SDK 接入结论

### 3.1 Desktop 已接入真实 SDK

`integrations/desktop/` 当前已通过 Electron `main -> preload -> renderer` 边界接入真实 `@cogna-dev/sdk`：

1. SDK 只在 `main process` 导入与调用
2. renderer 只通过 `window.api.sdk.*` 访问
3. 包树 / outlines / query / build / diff 都来自真实 SDK 返回

### 3.2 接入边界结论

当前实现遵循以下边界：

- renderer 不直接 import `@cogna-dev/sdk`
- main process 负责 IPC handler 与错误 envelope
- preload 暴露 typed API，避免 renderer 直接触达 `ipcRenderer`

### 3.3 后续优化方向

后续演进重点不再是 mock 替换，而是：

1. 增强 desktop 端 loading/error/empty 状态的交互一致性
2. 增强 `Build` / `Diff` 的执行反馈与结果可视化
3. 持续对齐 SDK contract 与桌面端 DTO 映射

## 4. 信息架构

## 4.1 主布局

桌面端采用三段式工作台：

```text
┌───────────────────────────────────────────────────────────────┐
│ Header: project status / SDK status / Build & Diff guidance  │
├───────────────┬──────────────────────────────┬────────────────┤
│ Package Tree  │ Explorer Pane                │ Detail Pane    │
│ FetchPackages │ QueryOutlines / Query        │ symbol details │
│               │                              │ docs / loc     │
└───────────────┴──────────────────────────────┴────────────────┘
```

### 4.2 分区职责

#### A. Header

负责：

- 当前项目上下文提示
- sdk 状态标识
- Build 状态摘要
- Diff 摘要
- CLI guidance 入口

#### B. Package Tree

直接映射 `FetchPackages.root`：

- 显示根项目
- 显示 workspace / direct / transitive relation
- 支持展开 / 折叠
- 单击节点切换当前 active package

#### C. Explorer Pane

有两个主模式：

1. `Outlines`
   - 展示当前包公开接口大纲
2. `Query`
   - 提供 `exact_id` / `exact_symbol` / `text` 三种查询模式

#### D. Detail Pane

展示当前 outline 或 query match 的详情：

- symbol
- kind
- signature
- summary
- docs snippet
- source location

## 5. 主要交互流

## 5.1 FetchPackages → QueryOutlines

默认打开后：

1. 左侧加载 package tree
2. 默认选中首个可浏览包
3. 中间展示该包 outlines
4. 右侧展示第一个 outline 的详情

这条路径对应“我先浏览当前项目依赖了哪些包，再看某个包暴露了哪些 API”。

## 5.2 Query

Query 面板需支持三种模式切换：

- `Exact ID`
- `Exact Symbol`
- `Fuzzy Text`

交互要求：

1. 模式切换后 placeholder 改变
2. 结果列表显示 mode badge
3. fuzzy 模式显示 score
4. 选中结果后右侧同步展示完整详情

## 5.3 Build / Diff CLI Guidance

由于当前阶段不强做 GUI 写操作，顶部保留两个 guidance card：

### Build

文案：

- “Build 会为当前项目刷新 `.cogna/sbom.spdx.json` 与查询上下文”

建议命令：

```bash
pnpm exec cogna build
```

### Diff

文案：

- “Diff 适合在发布前比较 working tree 与基线的公开接口变化”

建议命令：

```bash
pnpm exec cogna diff --base v1.1.0 --target working-tree --include-test-changes
```

## 6. 组件建议

建议使用 Shadcn 风格 primitives 组织，但本轮 demo 可先以轻量自实现方式表达相同结构。

### 6.1 核心组件

- `AppShell`
- `StatusCard`
- `CliGuidanceCard`
- `PackageTree`
- `ExplorerTabs`
- `QueryComposer`
- `ResultList`
- `DetailCard`
- `Badge`

### 6.2 视觉语言

- 背景：深灰 + 轻微渐变
- 面板：比背景略亮一层
- 边框：低对比但稳定可见
- 主强调色：蓝紫系
- 关系 badge：
  - `root`
  - `workspace`
  - `direct`
  - `transitive`
- 风险/级别 badge：
  - `breaking`
  - `minor`
  - `info`

## 7. API 到 UI 的映射

| API | UI 呈现 | 备注 |
|-----|---------|------|
| `Build` | Header 状态卡 + CLI guidance | 当前 demo 只做只读引导 |
| `Diff` | Header 状态卡 + recent changes preview + CLI guidance | 当前 demo 只做只读引导 |
| `FetchPackages` | 左侧 package tree | 主导航入口 |
| `QueryOutlines` | Explorer 的 outlines tab | 浏览型主流 |
| `Query` | Explorer 的 query tab | 精确 / 模糊统一入口 |

## 8. Demo 场景要求

本轮 demo 至少覆盖以下状态：

1. **默认浏览态**：包树 + outlines + detail
2. **查询态**：切换模式后返回不同结果
3. **空结果态**：查询无结果时给出说明
4. **CLI guidance 态**：Build / Diff 展示清晰命令
5. **SDK error 态**：SDK 请求失败时明确显示错误并可恢复

## 9. 交付要求

`integrations/desktop/` demo 本轮交付应满足：

1. 能直接打开并 review
2. 使用真实 SDK runtime（通过 main/preload IPC）
3. 视觉风格接近 Shadcn 数据工作台
4. 数据 shape 对齐 `spec/api.md`
5. 后续可低成本替换为真实 SDK / IPC data source
