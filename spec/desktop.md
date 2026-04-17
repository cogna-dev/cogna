# Cogna Desktop 整体设计

本文定义 `cogna.xaclabs.dev`、Cogna CLI、Cogna Desktop 与 cache-first runtime 的整体关系。

目标不是把桌面端做成另一个独立产品，而是让它成为 **当前项目上下文** 的图形化入口，并与 `spec/api.md`、`spec/cache.md` 的 public contract 保持一致。

---

## 1. 产品边界

Cogna 下一阶段应收口为三个用户可感知入口：

1. **Docs Site**：`https://cogna.xaclabs.dev`
2. **CLI**：`cogna ...`
3. **Desktop App**：`cogna` Electron 桌面应用

这三个入口共享同一套事实：

- 当前项目上下文来自本地工作目录
- 当前项目元数据来自 `cogna.yml`
- 当前项目依赖发现来自 `.cogna/sbom.spdx.json`
- 远程复用来自 cache-first bundle store，而不是 registry / publish workflow

---

## 2. 每个入口的职责

## 2.1 Docs Site (`cogna.xaclabs.dev`)

Docs site 是 **唯一公开文档入口**。

它负责：

- 产品说明与快速开始
- 命令参考
- cache / desktop / policy / MCP 说明
- 下载桌面端与 CLI 的引导
- 发布说明与开发进度

它不负责：

- 代替桌面端承载当前项目上下文
- 代替 CLI 执行本地 build / diff / check
- 暴露内部 bundle / cache key / SQL 等实现细节

建议站点信息架构：

- `/docs/*`：用户文档
- `/contrib/*`：贡献者文档
- `/docs/progress`：当前真实进度
- `/docs/desktop`：桌面端使用说明
- `/docs/cache`：cache-first 说明
- `/download` 或首页 CTA：下载桌面端 / CLI

## 2.2 CLI

CLI 仍是 **写操作与自动化入口**。

它负责：

- `cogna init`
- `cogna build`
- `cogna diff`
- `cogna check`
- `cogna query`
- `cogna serve`
- `cogna cache list|add|remove`
- `cogna mcp serve|status`
- `cogna open <folder>`

其中：

- `build` / `diff` / `check` / `serve` 适合终端与 CI
- `open` 负责把“当前项目上下文”显式交给桌面端

CLI 不应承担长期常驻 UI 状态；它更像桌面端与脚本自动化之间的桥梁。

## 2.3 Desktop App

Desktop App 是 **当前项目浏览与查询入口**。

它负责：

- 展示当前项目 package tree（`FetchPackages`）
- 浏览单个 package outlines（`QueryOutlines`）
- 做 exact / fuzzy 查询（`Query`）
- 展示当前项目上下文来源
- 提供 Build / Diff / CLI guidance

它当前不直接承担：

- 复杂写操作编排
- cache 管理平面
- CI/CD 与 release orchestration

换句话说，桌面端是“工作台”，CLI 是“执行器”，docs 站是“公开说明书”。

---

## 3. 当前项目上下文模型

根据 `spec/api.md`，所有能力都应建立在“当前项目”的隐式上下文上。

桌面端中的 `workspace context` 应至少包含：

```text
WorkspaceContext {
  folderPath: String,
  displayName: String,
  contextSummary: String,
  source: default | deep-link | renderer,
}
```

语义：

- `folderPath`：当前项目绝对路径
- `displayName`：用于标题栏和根 package node 展示
- `contextSummary`：给 UI 的人类可读说明
- `source`：上下文来源（默认启动 / deep link / app 内切换）

桌面端不应该自己创造另一套项目身份模型；它只是在图形界面里承接 CLI/API 的同一上下文。

---

## 4. `cogna open <folder>` 与桌面唤醒协议

## 4.1 目标

用户在终端执行：

```bash
cogna open <folder>
```

期望行为：

1. 若桌面端未启动，则启动桌面端
2. 若桌面端已启动，则唤醒已运行实例
3. 将当前工作区上下文切换到 `<folder>`

## 4.2 协议形状

推荐 custom protocol：

```text
cogna://open?folder=<percent-encoded-absolute-path>
```

原因：

- 对 macOS、Windows、Linux 的 Electron deep link 模式最直接
- `folder` 字段可显式表达本地工作区路径
- 与后续 docs / browser / terminal 唤醒模型兼容

## 4.3 实现要求

桌面端必须：

1. 注册 `cogna` protocol
2. 使用 `requestSingleInstanceLock()` 保证单实例
3. 在 macOS 监听 `open-url`
4. 在 Windows / Linux 监听 `second-instance`
5. 冷启动时检查 `process.argv` 中是否带 deep link
6. 解析 deep link 后更新 `WorkspaceContext`

CLI 的 `open` 子命令必须：

1. 解析用户输入 folder
2. 解析为当前 shell 下的项目绝对路径
3. 校验路径存在且为目录
4. 生成 deep link 并交给系统协议处理器

---

## 5. 桌面端信息架构

桌面端延续 `spec/ui.md` 的工作台结构，但当前项目上下文要上移为一级信息。

主布局：

```text
┌────────────────────────────────────────────────────────────┐
│ Title Bar / Workspace Context / Explorer-Diff Toggle      │
├───────────────┬──────────────────────────┬─────────────────┤
│ Package Tree  │ Explorer / Query         │ Detail Pane     │
│ FetchPackages │ QueryOutlines / Query    │ Signature/docs  │
└───────────────┴──────────────────────────┴─────────────────┘
```

需要新增的顶层信息：

- 当前 workspace display name
- 当前 folder path
- 当前上下文来源（默认 / deep link）

这样用户从终端 `cogna open ./repo` 跳转到桌面端后，可以立刻确认自己看的就是那个项目。

---

## 6. 与 cache-first 架构的关系

桌面端不直接暴露 cache backend 细节，但其数据语义必须与 cache-first 设计一致。

### 6.1 一致性要求

- docs 站描述远程复用时，统一使用 cache 叙事，不再使用 registry / publish 叙事
- CLI 的 `serve` 对外是 cache proxy
- Desktop 中如需展示“Build 使用远程复用”，文案应解释为：
  - 当前项目 build 会优先查 local cache
  - 若配置了 `cache.type = http`，则会对依赖做 remote read-through
  - 命中后回填 local cache

### 6.2 非目标

桌面端当前不需要提供：

- cache key 浏览器
- 远程 bundle 管理页
- object/blob 级调试界面

这些内容会把 bundle-internal 细节重新抬回用户主叙事，与 `spec/cache.md` 的收口方向冲突。

---

## 7. 下载与发布面设计

`cogna.xaclabs.dev` 应作为下载入口与文档入口的统一域名。

推荐用户路径：

### 7.1 新用户

1. 打开 `https://cogna.xaclabs.dev`
2. 阅读介绍与快速开始
3. 下载：
   - CLI
   - Desktop installer

### 7.2 已安装用户

1. 在终端中运行 `cogna build` / `cogna diff`
2. 运行 `cogna open .`
3. 桌面端自动聚焦到当前项目上下文

### 7.3 组织内分享

1. 团队成员共享 docs 站链接
2. 用 `cogna serve` 暴露受控 cache proxy
3. 本地 CLI / Desktop 都围绕同一 cache-first contract 工作

---

## 8. 当前阶段落地顺序

建议执行顺序：

1. 完成 `cogna open <folder>` 与桌面 deep link
2. 完成桌面端 `WorkspaceContext` 切换
3. 在 docs 中补充 desktop 使用说明
4. 继续把 Desktop mock data 替换为真实 SDK / IPC 数据源

## 8.1 当前阶段验收标准

当前阶段完成应至少满足：

1. CLI 中存在 `cogna open <folder>`
2. Electron app 使用 `dev.xaclabs.cogna` 作为 app identity
3. Electron app 注册 `cogna://` protocol
4. 已运行桌面实例可被 `cogna open` 唤醒并切换上下文
5. 桌面标题栏能显示当前 workspace name / path
6. docs / progress / spec 对 desktop 叙事一致

---

## 9. 后续演进

当前桌面端仍是 mock-first demo，但其结构应为真实数据源留接口。

后续演进方向：

1. 用真实 `FetchPackages` / `QueryOutlines` / `Query` 替换 mock data
2. 将 Build / Diff 从 CLI guidance 提升为真实可执行动作
3. 引入最近项目列表与最近打开历史
4. 在 docs 站提供“桌面端 + CLI 联动” how-to 文档

长期来看，桌面端不是新的产品分叉，而是 Cogna 用户侧 API 的一个图形化宿主。
