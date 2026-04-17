# Cogna 本地人工验收流程

本文定义基于 `e2e/repo/` 的本地人工验收流程，用于在代码评审、发布前自检、或桌面端联调时，对 **CLI** 与 **Desktop** 做同一套可重复的人工检查。

目标不是替代自动化测试，而是补上两类自动化难以完全覆盖的验收：

1. **用户可见行为是否成立**
2. **CLI 与 Desktop 围绕同一项目上下文是否连通**

本流程的人工验收基准固定为：

```text
./e2e/repo/
```

该基准仓库是一个真实的 Go module，包含：

- `main.go`
- `internal/labels/labels.go`
- `go.mod`
- `go.sum`
- `cogna.yaml`

它足够小，便于人工快速理解；同时又包含 workspace 自身代码和第三方依赖，适合作为 CLI 与 Desktop 的共同验收对象。

---

## 1. 适用范围

以下情况应执行本流程：

1. 修改了 `src/cmd/*` 的用户可见命令行为
2. 修改了 `integrations/desktop/*` 的桌面交互、标题栏、workspace 上下文或 deep-link 行为
3. 修改了 `spec/api.md`、`spec/cache.md`、`spec/desktop.md` 后，需要确认产品叙事与实际体验一致
4. 发布前需要做一轮 repo-centric 的手工冒烟验收

以下情况可只做自动化验证，不强制走完整人工流程：

1. 纯内部重构，用户可见行为不变
2. 仅改动文案/注释且不影响 CLI / Desktop 输出
3. 只改了与 `e2e/repo/` 无关的底层实现，并已有充分自动化覆盖

---

## 2. 验收目标

围绕 `e2e/repo/`，本流程要回答 5 个问题：

1. CLI 是否能围绕这个 repo 正常工作
2. CLI 输出的产物是否与 repo 内容一致
3. Desktop 是否能启动并显示正确的 workspace 上下文
4. `cogna open <folder>` 是否能把 CLI 上下文传递给 Desktop
5. 当行为与自动化测试不一致时，是否有明确的人为判定步骤

---

## 3. 验收前准备

## 3.1 环境准备

在仓库根目录执行：

```bash
moon update
just install-cli
```

建议先跑一轮基础自动化，确认不是在明显坏状态上做人工验收：

```bash
just ci
```

如果本轮涉及桌面端，再补：

```bash
pnpm --dir integrations/desktop install
pnpm --dir integrations/desktop run typecheck
```

## 3.2 基准仓库位置

后续所有命令默认以：

```text
./e2e/repo/
```

为当前工作目录。

示例：

```bash
cd e2e/repo
```

## 3.3 先理解基准 repo 的最小事实

人工验收者应先读这两个文件：

```text
e2e/repo/main.go
e2e/repo/internal/labels/labels.go
```

最低限度应确认：

- repo 的根 package 名是 `sdkacceptance`
- 存在 `Greeter` struct
- 存在 `NewRequestID(prefix string) string`
- 存在 `BuildLabels(items []string) []string`
- 存在 `Greeter.Greet(name string) string`
- 依赖中至少包含：
  - `github.com/google/uuid`
  - `github.com/samber/lo`

如果人工看到的 CLI / Desktop 内容与这些最小事实明显不一致，应直接判定本轮验收失败。

---

## 4. CLI 人工验收流程

## 4.1 验收 1：CLI 能识别当前 repo

在 `e2e/repo/` 下执行：

```bash
cogna --help
```

确认帮助文本中至少出现：

- `build`
- `diff`
- `check`
- `query <query-file>`
- `serve`
- `cache list`
- `mcp serve`
- `open <folder>`

人工判定标准：

- 若 `open <folder>` 不在帮助文本中，则桌面联动能力未正确暴露
- 若帮助文本仍以旧 registry / publish 为中心，则 public surface 未收口完成

## 4.2 验收 2：`cogna build` 能围绕 repo 生成产物

在 `e2e/repo/` 下执行：

```bash
rm -rf dist .cogna
cogna build
```

人工检查：

```bash
ls dist
```

预期至少能看到：

- `bundle.ciq.tgz`
- `declarations.ndjson`
- `software-components.ndjson`
- `manifest.json`
- `metadata.json`
- `checksums.txt`

如果当前实现仍会写出 `symbols.ndjson` 或 `sbom.spdx.json`，可记录为当前 reality，但不能把它们当作本轮人工验收的唯一成功条件。

## 4.3 验收 3：产物内容与 repo 事实一致

人工抽查 `dist/declarations.ndjson`，确认能找到与源码对应的公共符号。建议至少检查：

- `Greeter`
- `NewRequestID`
- `BuildLabels`
- `Greet`

可以用：

```bash
grep -n "Greeter\|NewRequestID\|BuildLabels\|Greet" dist/declarations.ndjson
```

人工判定标准：

- 若这些符号完全缺失，判定失败
- 若符号存在但明显归属错误（例如不属于当前 repo），判定失败

同时抽查依赖信息：

```bash
grep -n "github.com/google/uuid\|github.com/samber/lo" dist/software-components.ndjson
```

人工判定标准：

- 这两个依赖至少应能在依赖产物中被识别出来

## 4.4 验收 4：`cogna query` 的人工冒烟

在 `e2e/repo/` 下创建一个最小查询文件：

```bash
cat > query.json <<'EOF'
{
  "schemaVersion": "ciq-query/v1",
  "purl": "pkg:golang/example/sdkacceptance@0.1.0",
  "selector": {
    "path": "sdkacceptance::main.go::BuildLabels"
  },
  "intent": "review"
}
EOF
```

然后执行：

```bash
cogna query ./query.json
```

人工检查：

```bash
cat query.result.json
```

预期：

- 命令成功返回
- `query.result.json` 被写出
- 结果中应能看到与 `BuildLabels` 对应的命中项，或至少能看出当前查询行为稳定地围绕本 repo 运行

如果当前 query shape 与文档仍有过渡差异，人工应记录“结果结构是否稳定、是否显然来自当前 repo”，而不是纠结字段名的临时波动。

## 4.5 验收 5：必要时的人工失败判定

以下情况即使自动化通过，也应人工判定 CLI 验收失败：

1. `cogna build` 产物与 `e2e/repo` 的源码事实明显不一致
2. `cogna query` 输出不是围绕当前 repo 的结果
3. 用户看不懂命令面，帮助文本仍暴露旧叙事
4. `open <folder>` 帮助、解析或行为与桌面联动目标脱节

---

## 5. Desktop 人工验收流程

## 5.1 验收前提

Desktop 当前是 **mock-first demo**。

这意味着本轮人工验收关注的是：

- workspace 上下文是否正确显示
- CLI 到 desktop 的唤醒链路是否成立
- UI 信息架构是否与 `spec/ui.md` / `spec/desktop.md` 一致

而不是验证真实 SDK 数据是否已经打通。

## 5.2 验收 1：桌面端能启动

在仓库根目录执行：

```bash
pnpm --dir integrations/desktop dev
```

人工观察预期：

1. 窗口成功出现
2. 顶部标题栏可见
3. 默认 workspace 标题为类似 `workspace-app`
4. 主界面是三栏结构：
   - 左：Package Tree
   - 中：Explorer / Query
   - 右：Detail Pane
5. 顶部存在 Explorer / Diff 切换

如果桌面端无法启动、只出现空白页、或三栏工作台结构缺失，直接判定失败。

## 5.3 验收 2：默认桌面信息架构正确

人工检查界面时，应确认：

1. 左侧是 package tree，不是 marketing landing page
2. 中间有 outlines / query 两个主要模式
3. 右侧 detail pane 能展示 symbol 详情
4. 顶部能看到当前 workspace 的名称与路径/说明

这一步主要对应 `spec/ui.md` 的桌面工作台目标。

## 5.4 验收 3：`cogna open ./e2e/repo` 能唤醒 / 切换 desktop

保持 desktop 已启动，在仓库根目录另开一个终端执行：

```bash
cogna open ./e2e/repo
```

人工预期：

1. CLI 命令成功返回
2. 若 desktop 已经启动，则现有窗口被聚焦
3. 标题栏里的 workspace display name 更新为：
   - `repo`
   - 或与 `e2e/repo` basename 对应的显示名
4. 标题栏里的路径更新为 `.../e2e/repo`
5. package tree / detail pane 仍保持可浏览，不出现空白或崩溃

如果 desktop 未被聚焦、上下文未切换、或 UI 崩溃，判定失败。

## 5.5 验收 4：冷启动 deep-link 行为

若要验证冷启动路径：

1. 完全退出 desktop
2. 在仓库根目录执行：

```bash
cogna open ./e2e/repo
```

人工预期：

1. Desktop 被拉起
2. 首次显示就是 `e2e/repo` 对应的 workspace context
3. 标题栏立即显示 repo 名与路径

这一步主要验证：

- protocol registration
- app single-instance / deep-link 冷启动路径

## 5.6 验收 5：必要时的人工失败判定

以下情况即使 typecheck / build 通过，也应人工判定 desktop 验收失败：

1. 标题栏没有清楚显示当前 workspace name / path
2. `cogna open <folder>` 无法把 CLI 上下文传给 desktop
3. 界面结构偏离 `spec/ui.md` 的三栏工作台
4. 用户无法直观看出当前展示的是哪个项目

---

## 6. CLI + Desktop 联合验收

这一步用于验证它们围绕的是同一个 repo，而不是各自独立冒烟。

建议顺序：

1. 在 `e2e/repo/` 下执行 `cogna build`
2. 人工检查 `dist/` 产物与 repo 事实一致
3. 启动 desktop
4. 在仓库根目录执行 `cogna open ./e2e/repo`
5. 确认 desktop 显示的 workspace 就是这个 repo
6. 在 desktop 中人工浏览 package tree / outlines / detail pane
7. 人工确认桌面端呈现出的工作台叙事，与 CLI 刚刚处理的 repo 是一致的

联合验收的关键不是“数据是否已经完全真实”，而是：

> **CLI 与 Desktop 是否围绕同一个项目上下文工作。**

---

## 7. 何时必须进行人工验收

以下改动必须至少走一轮本流程：

1. 修改 `src/cmd/main/main.mbt`
2. 修改 `src/cmd/open/*`
3. 修改 `integrations/desktop/src/main/index.ts`
4. 修改 `integrations/desktop/src/preload/*`
5. 修改 `integrations/desktop/src/renderer/src/App.tsx`
6. 修改 `integrations/ui/src/mock-data.ts`
7. 修改 `spec/ui.md`、`spec/desktop.md`、`spec/api.md` 后，需要确认用户可见行为仍成立

---

## 8. 验收记录建议

建议每次人工验收至少记录：

```text
- 验收日期
- 验收分支 / commit
- 验收基准：./e2e/repo
- CLI 结果：pass / fail
- Desktop 结果：pass / fail
- 联合验收结果：pass / fail
- 发现的问题
- 是否需要补自动化测试
```

如果自动化通过但人工失败，应优先相信人工结果，并补充：

1. 缺失的自动化测试
2. 缺失的 spec / progress 对账
3. 缺失的用户可见行为说明

---

## 9. 当前结论

当前本地人工验收基线固定为：

```text
./e2e/repo/
```

本基线用于统一验证：

- CLI 是否能正确处理一个真实 repo
- Desktop 是否能正确展示并切换 workspace context
- `cogna open <folder>` 是否真正把 repo 上下文从终端传到桌面端

自动化测试负责回归稳定性；人工验收负责最终确认“用户看到的产品是否真的成立”。
