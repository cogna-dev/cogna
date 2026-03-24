= B001 · MoonBit native link-core ICE（Invalid_argument("Moonc.Basic_lst.iter2")）

== 背景

在当前 CodeIQ 仓库推进 `mcp` / `e2e` native 测试时，出现稳定的 MoonBit 编译器内部错误（ICE）：

- `moonc link-core ...`
- `Error: Invalid_argument("Moonc.Basic_lst.iter2")`

该问题并非单条测试逻辑失败，而是发生在 #strong[链接阶段]，导致目标 test binary 无法生成。

== 环境

- moonc version: `v0.8.3+cd28f524e`
- 目标：`--target native`
- 触发场景：`cmd/mcp` 与 `e2e` 这类大依赖图测试包

== 复现命令（当前稳定复现）

- `moon test src/cmd/mcp/core/main_test.mbt --target native -v`
- `moon test src/e2e/mcp_lifecycle_test.mbt --target native -v`
- `moon test src/e2e/review_test.mbt --target native -v`

复现结果均在 `moonc link-core` 阶段崩溃，并输出 `Invalid_argument("Moonc.Basic_lst.iter2")`。

== 对照验证（已通过）

下述较小范围测试可通过，说明并非所有 async / mcp 代码都不可用：

- `moon test src/lib/mcp-sdk/main_test.mbt --target native -v` ✅
- `moon test src/lib/shell/main_test.mbt --target native -v` ✅
- `moon test src/e2e/async_probe/process/main_test.mbt --target native -v` ✅
- `moon test src/e2e/async_probe/stdio/main_test.mbt --target native -v` ✅
- `moon test src/e2e/async_probe/combo/main_test.mbt --target native -v` ✅

== 已尝试的规避手段

1. `NEW_MOON=0` legacy build graph 重试：
   - `NEW_MOON=0 moon test src/cmd/mcp/main_test.mbt --target native -v`
   - 结果：仍复现相同 ICE。

2. MCP stdio 临时 fallback：
   - 将 native stdin 读取改为 C stub（`src/lib/mcp-sdk/stdio_native_stub.c`）
   - 结果：`lib/mcp-sdk` 包级测试可通过，但 `cmd/mcp` / `e2e` 大图 native 链接依旧 ICE。

3. 最小化 async 能力探针：
   - process / stdio / combo 都能通过，未触发 ICE。
   - 结论：问题更像 #strong[大图链接阶段编译器 bug]，而非最小 async 能力不可用。

== 当前影响范围

- 受影响：`cmd/mcp` 与 `e2e` 的 native 测试闭环
- 未受影响：`lib/mcp-sdk`、`lib/shell`、最小 async 探针

== 当前策略

1. #strong[记录并隔离问题]：保持本 BUG 文档更新，作为 release 风险项。
2. #strong[继续开发]：优先推进 stdio MCP 路径与结构拆分，尽量缩减触发 ICE 的链接图。
3. #strong[回归策略]：在每轮关键改动后重跑上述复现命令，确认是否仍触发同一 ICE。

== 本轮补充（R5-2 阶段推进）

- 为继续推进 `R5-2`，对易触发大图 link-core 的测试包做了目标分离：
  - `src/cmd/diff/moon.pkg` 的 `main_test.mbt` 固定 `wasm`；
  - `src/cmd/query/moon.pkg` 的 `main_test.mbt` 固定 `wasm`；
  - `src/e2e/moon.pkg` 的 `init_test.mbt` 固定 `wasm`；
  - 新增 `src/e2e/review/moon.pkg`，将 review 主链路测试置于 `wasm`，并把 MCP detached lifecycle 单独保留为 native 测试。

- 新增/迁移文件：
  - `src/e2e/review/moon.pkg`
  - `src/e2e/review/main_test.mbt`
  - `src/e2e/review/lifecycle_test.mbt`
  - 删除旧聚合文件：`src/e2e/review_test.mbt`、`src/e2e/mcp_lifecycle_test.mbt`

- 观察结果：
  - `wasm` 目标可稳定执行 `diff/query/init` 相关验证；
  - `review` 主链路在 `wasm` 下不再执行 detached shell 行为（该行为仅 native 支持）；
  - `native` 大图测试仍可能触发同类 `Moonc.Basic_lst.iter2` ICE。

== 后续动作

- 继续将 `cmd/mcp` 拆分为生命周期层与 stdio 核心处理层，减少单包耦合。
- 将能够独立验证的请求处理逻辑下沉到更小包中，优先让核心逻辑保持可测试。
- 在 MoonBit 上游 issue 模板中提交最小复现（含当前命令与错误文本），并跟踪修复版本。
