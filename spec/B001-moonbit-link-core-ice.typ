= B001 · MoonBit native link-core ICE（Invalid_argument("Moonc.Basic_lst.iter2")）

== 背景

在当前 CodeIQ 仓库推进 native 回归时，出现稳定的 MoonBit 编译器内部错误（ICE）：

- `moonc link-core ...`
- `Error: Invalid_argument("Moonc.Basic_lst.iter2")`

该问题并非单条测试逻辑失败，而是发生在 #strong[链接阶段]，导致目标 test binary 无法生成。

== 环境

- moonc version: `v0.8.3+cd28f524e`
- 目标：`--target native`
- 当前已确认：不仅大图 `cmd/*` / `e2e` 会触发，#strong[极小独立 repro] 也可触发

== 复现命令（当前稳定复现）

- `moon test src/cmd/bundle/reader_test.mbt --target native -v`
- `moon test src/cmd/build/main_test.mbt --target native -v`
- `moon test --target native -v`

在独立 repro module `repro/moonbit-link-core-ice/` 中，以下命令也可稳定复现：

- `moon test src/zstd_compress/main_test.mbt --target native -v`
- `moon test src/zstd_direct/main_test.mbt --target native -v`

复现结果均在 `moonc link-core` 阶段崩溃，并输出 `Invalid_argument("Moonc.Basic_lst.iter2")`。

== 对照验证（已通过）

下述对照已通过，说明问题并非“所有 native / 所有 zstd / 所有大图”都会触发：

- `moon test src/lib/mcp-sdk/main_test.mbt --target native -v` ✅
- `moon test src/cmd/mcp/core/smoke_test.mbt --target native -v` ✅
- `moon test src/e2e/async_probe/process/main_test.mbt --target native -v` ✅
- `moon test src/e2e/async_probe/combo/main_test.mbt --target native -v` ✅
- `moon build src/cmd/bundle --target native` ✅

在独立 repro module `repro/moonbit-link-core-ice/` 中，以下对照已通过：

- `moon test src/plain_control/main_test.mbt --target native -v` ✅
- `moon test src/zstd_const/main_test.mbt --target native -v` ✅
- `moon test src/zstd_decl/main_test.mbt --target native -v` ✅
- `moon build src/zstd_compress --target native` ✅
- `moon check --target native` ✅（warnings only）

== 已失效的旧复现命令

此前文档中的下述命令已不再适合作为当前稳定复现：

- `moon test src/cmd/mcp/core/main_test.mbt --target native -v`
  - 当前结果：`Warning: no test entry found. Total tests: 0`
  - 原因：`src/cmd/mcp/core/moon.pkg` 中 `main_test.mbt` 仅配置 `llvm`
- `moon test src/e2e/review/lifecycle_test.mbt --target native -v`
  - 当前结果：通过

== 已尝试的规避手段

1. 先在 repo 内重新搜寻 live failing surface：
   - 结论：旧的 `mcp/review` 命令已过时，但 `cmd/bundle` 与 `cmd/build` 仍可稳定触发。

2. 构建独立 nested MoonBit module：
   - 新增：`repro/moonbit-link-core-ice/`
   - 目标：脱离主项目图，仅保留最小触发依赖与对照组。

3. 对 `Milky2018/zstd` 做 statement / graph 级缩减：
   - import-only blackbox test：通过
   - dead declaration（声明 `@zstd.compress(...)` 但测试不引用）：通过
   - normal package build（`moon build --target native`）：通过
   - blackbox test binary 中 #strong[实际引用] `@zstd.compress(b"")`：稳定 ICE

== 当前影响范围

- 受影响：native #strong[blackbox test] 链接图，当前已确认包括：
  - `src/cmd/bundle/reader_test.mbt`
  - `src/cmd/build/main_test.mbt`
  - `repro/moonbit-link-core-ice/src/zstd_compress/main_test.mbt`
  - `repro/moonbit-link-core-ice/src/zstd_direct/main_test.mbt`
- 未受影响：
  - import-only `zstd` blackbox test
  - 未被测试调用的 `zstd.compress` 声明
  - `moon build --target native` 的普通包构建
  - `mcp-sdk` / async probe 这些当前较小控制样本

== 独立最小化复现

- repro root：`repro/moonbit-link-core-ice/moon.mod.json`
- 对照组：
  - `src/plain_control/*`
  - `src/zstd_const/*`
  - `src/zstd_decl/*`
- 失败组：
  - `src/zstd_compress/*`
  - `src/zstd_direct/*`

当前最小失败命令：

- 在 `repro/moonbit-link-core-ice/` 下运行：
  - `moon test src/zstd_direct/main_test.mbt --target native -v`

当前最小触发语句：

- `repro/moonbit-link-core-ice/src/zstd_direct/main_test.mbt:3`
  - `let out : Result[Bytes, Error] = try? @zstd.compress(b"")`

等价的包内调用链也可触发：

- `repro/moonbit-link-core-ice/src/zstd_compress/main.mbt:3`
  - `@zstd.compress(b"").length()`
- 当该函数被 `src/zstd_compress/main_test.mbt` 调用时，native blackbox test 链接阶段同样 ICE。

结论：当前已将问题定位到 #strong[blackbox test binary 对 `@zstd.compress(b"")` 的 live call edge]，而不是仅仅 import `zstd`、也不是普通 native build。

== 编译器侧线索

- MoonBit compiler 中 `Basic_lst.iter2` / `fold_right2` 在列表长度失配时会 `invalid_arg __FUNCTION__`：
  - `https://github.com/moonbitlang/moonbit-compiler/blob/d4ada10d212b5376f7f8bf49cd2fbaa275a395df/src/basic_lst.ml`
- `link-core` 的链接入口：
  - `https://github.com/moonbitlang/moonbit-compiler/blob/d4ada10d212b5376f7f8bf49cd2fbaa275a395df/src/core_link.ml`
- `-main` 等 link-core 参数来源：
  - `https://github.com/moonbitlang/moonbit-compiler/blob/d4ada10d212b5376f7f8bf49cd2fbaa275a395df/src/driver_config.ml`

当前猜测仍是：`moonc link-core` 在 native blackbox test 图中处理 package / test-package 对齐时出现内部 list 长度失配；`zstd.compress` 的 live call edge 只是当前最小、最稳定的触发器。

== 当前策略

1. #strong[记录并隔离问题]：保持本 BUG 文档与 `repro/moonbit-link-core-ice/` 同步。
2. #strong[继续开发]：在 `R8` 之前先完成上游可提交的最小复现与证据链。
3. #strong[回归策略]：每轮 MoonBit / 依赖图相关改动后，重跑当前最小 repro 与 `cmd/bundle` / `cmd/build` 的 native 命令。

== 后续动作

- 在 MoonBit 上游 issue 模板中提交 #strong[独立 repro]（含 `repro/moonbit-link-core-ice/` 命令、错误文本与编译器 permalink）。
- 进一步验证 `@zstd.decompress(...)` / 其他 zstd live call 是否同样触发，以确认是 `compress` 特定路径还是更一般的 zstd codegen/link graph 问题。
- 跟踪 MoonBit 工具链后续修复版本，待修复后恢复更多 native 全量回归。
