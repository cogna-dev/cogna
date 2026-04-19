# Remote E2E Workflow 重构计划（2026-04-19）

本文定义下一轮 remote extractor e2e 的重构计划。目标不是继续把 remote case 当作“默认跳过的附属能力”留在本地手工环境里，而是把它收口成：

1. 一个**独立的 GitHub Actions workflow**；
2. 一个**显式的 prepare -> run 两阶段执行模型**；
3. 一套**对 GitHub cache 友好、对 act 可退化运行**的环境准备策略；
4. 一份能被后续工程师直接照做的执行说明、文件清单和验收标准。

---

## 1. 当前事实与问题定义

### 1.1 已经成立的事实

以下事实已经由当前代码定义，不应在本计划中被重新设计：

- remote extractor e2e 已经有独立 manifest：
  - `e2e/extractors/rust.json`
  - `e2e/extractors/go-remote.json`
  - `e2e/extractors/terraform-remote.json`
- harness 已经有独立 gate：
  - `COGNA_ENABLE_REMOTE_E2E`
  - `COGNA_ENABLE_GIT_REMOTE_E2E`
  - `COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E`
- harness 不是“联网即自动成功”，而是依赖**本地预热好的依赖/缓存/初始化状态**：
  - Cargo package 缺依赖时要求 `cargo fetch` / `cargo vendor`
  - Go module 缺依赖时要求 `go mod download` / `go mod vendor`
  - Terraform remote module / provider 缺依赖时要求 `terraform init`
- 当前本地 `act` 已用于执行 `.github/workflows/actions-e2e.yml`；
- 当前 release workflow 真实触发条件是 semver tag，而不是 `release/*` 分支。

### 1.2 当前真正的问题

当前 remote e2e 的问题不是“harness 不存在”，而是：

1. **执行入口分散**
   - harness 在 `src/e2e/extractors/*`
   - local act 入口在 `justfile` / `integrations/actions/README.md`
   - workflow 入口却仍指向旧的 `actions-e2e.yml`

2. **工作流已经过时**
   - `.github/workflows/actions-e2e.yml` 仍引用旧概念：
     - `policy-bundle`
     - `checks.policy: ../policy/dist/bundle.ciq.tgz`
     - `software-components.ndjson`
   - 这些都不再代表当前仓库 reality

3. **remote case 仍隐式依赖本地 warm state**
   - 当前 remote case 在失败时允许出现“缺少本地前置依赖”的报错；
   - 这适合作为开发期 guard，但不适合作为稳定 CI 验收模型。

4. **cache 与 act 的边界尚未写清**
   - GitHub Actions cache 可以加速 hosted runner；
   - `act` 可以复用同一 workflow 逻辑，但不应被设计为依赖 GitHub hosted cache backend。

### 1.3 本轮必须回答的问题

本计划必须收口以下问题：

1. remote e2e 的唯一正式 workflow 是什么；
2. workflow 如何拆成 prepare / run 两阶段；
3. Go / Cargo / Terraform 的环境准备各自做什么；
4. 哪些缓存可以依赖 GitHub Actions cache，哪些不该缓存；
5. `act` 如何运行同一 workflow，以及哪些能力要显式降级；
6. `release/*` 在这个方案中的职责是什么；
7. 现有过时 workflow / docs / just recipe 如何迁移。

---

## 2. 目标形态（Target Shape）

## 2.1 唯一正式入口

新增一个独立 workflow：

```text
.github/workflows/remote-e2e.yml
```

它成为 remote extractor e2e 的唯一正式自动化入口，用于：

- GitHub 上的 release-branch 验证；
- `workflow_dispatch` 手动验证；
- 本地通过 `act` 复用同一 workflow。

旧的：

```text
.github/workflows/actions-e2e.yml
```

不再继续承担 remote e2e 主入口职责。它要么：

- 被删除；
- 要么被降级为过渡/兼容 smoke workflow，并在 docs 中明确不再推荐。

## 2.2 两阶段模型

新的 remote e2e workflow 必须拆成两个逻辑阶段：

### Phase 1 — prepare-remote-e2e-env

目标：把 remote case 所需的本地前置状态显式构造出来，而不是把缺失依赖留给测试阶段随机失败。

职责：

1. checkout repo
2. setup MoonBit
3. setup Cogna
4. setup Go / Rust / Terraform toolchain
5. restore caches
6. 预热 remote case 需要的依赖
7. 输出 prepare 产物/日志，供后续 run 阶段复用

### Phase 2 — run-remote-e2e

目标：在“前置依赖已经准备好”的前提下，运行 remote extractor e2e，并把失败收口为真正的 extractor/harness 问题，而不是环境准备问题。

职责：

1. 接收 prepare 阶段的缓存/环境
2. 设置 remote e2e gate env
3. 执行 remote extractor e2e
4. 保存日志、失败输出、snapshot 证据

## 2.3 act 的定位

`act` 的目标是：

- 复用同一份 workflow 编排；
- 验证 workflow 在本地 Docker 环境下可执行；
- 尽量复用本地已有缓存/prepare 结果。

`act` **不是**本计划中的 hosted-cache 等价物。

因此本轮设计必须明确：

- GitHub hosted runner cache 与 act local cache 是两套实现；
- workflow 逻辑应统一；
- cache save/restore 行为可以按 `ACT=true` 做显式分支；
- 不能把“act 命中 GitHub cache”作为验收条件。

---

## 3. 作用范围与非目标

## 3.1 本轮范围

本轮只做：

1. remote e2e workflow 重构
2. prepare / run 两阶段拆分
3. Go / Cargo / Terraform remote source prepare 策略
4. GitHub cache 策略
5. act 本地执行入口迁移
6. docs / just / workflow 真相源对齐

## 3.2 本轮明确不做

1. 不把 remote e2e 改成默认在 `moon test` 主线里自动执行
2. 不移除现有三个 gate env 的独立控制语义
3. 不把 release workflow 从 tag 改成 `release/*`
4. 不在本轮解决所有 remote case 的 feature completeness
5. 不把 Cargo 的 `target/` 大缓存作为第一版核心方案
6. 不要求 act 与 GitHub hosted cache 达到完全一致行为

---

## 4. 当前代码与工作流的现实约束

## 4.1 harness 约束

当前 harness 的核心入口与约束：

- `src/e2e/extractors/runtime.mbt`
  - `remote_e2e_enabled()`
  - `git_remote_e2e_enabled()`
  - `rust_package_remote_e2e_enabled()`
- `src/e2e/extractors/main.mbt`
  - 当前允许因本地依赖未预热而报出“Run cargo fetch / go mod download / terraform init”类失败
- `src/e2e/extractors/main_test.mbt`
  - 当前测试只验证 remote case 默认 skip，不验证 GitHub workflow prepare 逻辑
- `src/e2e/extractors/cases.mbt`
  - remote case manifest 来源是 `./e2e/extractors/*.json`

这意味着：

- workflow 不应重写 remote case 定义；
- workflow 需要消费现有 manifest；
- prepare 逻辑最好从 manifest 出发做预热，而不是手写固定 case 列表。

## 4.2 现有 workflow 约束

当前存在的 workflow：

- `ci.yml`：main / PR 主线 CI
- `release.yml`：semver tag + workflow_dispatch
- `publish.yml`：publish 相关流程
- `actions-e2e.yml`：旧的 Actions E2E smoke workflow

其中 `actions-e2e.yml` 已过时，原因包括：

- 仍依赖 policy bundle
- 仍写入旧 `checks.policy` 形态
- 仍引用 `software-components.ndjson`
- 它覆盖的是旧 build/diff/check smoke 路径，不是新的 remote extractor e2e prepare/run 模型

因此不能继续在 `actions-e2e.yml` 上增量打补丁来承载本计划。

## 4.3 docs / act 入口约束

当前入口仍指向旧 workflow：

- `justfile` 的 `act-e2e`
- `integrations/actions/README.md`
- `CONTRIBUTING.md`
- `docs/src/content/docs/ci.mdx`

本轮如果只改 workflow 而不改这些入口，仓库会继续把开发者导向过期路径。

---

## 5. 设计决策

## 5.1 workflow 触发策略

新的 `remote-e2e.yml` 建议触发方式：

```yaml
on:
  workflow_dispatch:
  push:
    branches:
      - 'release/*'
```

说明：

- `workflow_dispatch` 用于手工重跑与调试
- `release/*` 用于发版前验证分支
- 正式 release 产物发布继续由 `release.yml` 的 semver tag 触发，不混用职责

## 5.2 cache 策略

### Go

缓存目标：

- `GOMODCACHE`
- `GOCACHE`

缓存 key 至少包含：

- OS
- Go 版本
- `go.mod` / `go.sum` 内容摘要

### Rust / Cargo

第一版优先缓存：

- `~/.cargo/registry/index`
- `~/.cargo/registry/cache`
- `~/.cargo/git/db`

第一版不把整个 `target/` 作为核心缓存对象，原因：

- 体积大
- 易失效
- save/restore 成本可能大于收益

如需进一步加速，后续再评估 `sccache` 或更细粒度编译缓存。

### Terraform

缓存目标：

- `TF_PLUGIN_CACHE_DIR`
- 必要时缓存 `.terraform/` 中受控可复用部分

同时 workflow 必须显式构造 plugin cache path，而不能依赖 runner 默认位置。

## 5.3 ACT 分支策略

workflow 中应显式支持：

- GitHub hosted runner：正常 restore/save cache
- `ACT=true`：
  - 允许 restore 本地可用缓存
  - save 可以跳过或走本地兼容逻辑
  - 不能依赖 GitHub 远端 cache service

本轮计划必须把这条约束写进 docs，而不是留给实现者猜。

## 5.4 gate 策略

保留三个 gate，不合并：

- `COGNA_ENABLE_REMOTE_E2E=true`
- `COGNA_ENABLE_GIT_REMOTE_E2E=true`
- `COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E=true`

原因：

- Cargo remote package case（尤其 aws-sdk-rust）比 Go / Terraform 更重；
- Git remote case 与 package remote case 有不同失败模式；
- 需要分别控制 rollout 与定位问题。

---

## 6. 分阶段执行计划

## Phase A — 盘点并冻结现状

目标：在改 workflow 前，先把当前 remote e2e 相关的入口、约束、过时点全部冻结，避免边改边漂移。

必做：

1. 盘点当前 harness 与 manifest：
   - `src/e2e/extractors/runtime.mbt`
   - `src/e2e/extractors/main.mbt`
   - `src/e2e/extractors/main_test.mbt`
   - `src/e2e/extractors/cases.mbt`
   - `e2e/extractors/*.json`
2. 盘点当前 workflow / act 入口：
   - `.github/workflows/actions-e2e.yml`
   - `justfile`
   - `integrations/actions/README.md`
   - `CONTRIBUTING.md`
   - `docs/src/content/docs/ci.mdx`
3. 明确 `actions-e2e.yml` 中哪些逻辑已过时，哪些 composite action 仍可复用。

完成标准：

- 有一份明确文件清单；
- 过时点被列为待迁移项；
- 新 workflow 的职责边界已经写进 `spec/plan.md`。

## Phase B — 建立 dedicated remote-e2e workflow

目标：新增 `remote-e2e.yml`，成为唯一正式 remote e2e workflow。

必做：

1. 新增：
   - `.github/workflows/remote-e2e.yml`
2. 配置触发：
   - `workflow_dispatch`
   - `push.branches: ['release/*']`
3. workflow 顶层定义 prepare/run 两阶段 job
4. 复用现有 composite actions：
   - `integrations/actions/setup-cogna`
   - `integrations/actions/run-cogna`（如适合）

完成标准：

- 新 workflow 文件存在且可读；
- 旧 workflow 不再是 remote e2e 的推荐入口；
- release tag workflow 职责不被污染。

## Phase C — 显式化环境准备（prepare）

目标：把 remote case 所依赖的 warm state 从“失败提示”升级为“显式 prepare 步骤”。

必做：

1. 新增脚本（建议）：
   - `scripts/ci/prepare-remote-e2e.sh`
   - `scripts/ci/run-remote-e2e.sh`
2. `prepare-remote-e2e.sh` 至少完成：
   - 解析 `e2e/extractors/*.json`
   - 分类 remote case：go / rust-cargo / terraform / git
   - 为 Go 执行 module download / vendor 预热
   - 为 Cargo 执行 fetch / vendor 预热
   - 为 Terraform 执行 init / provider plugin 预热
3. 将 prepare 阶段输出日志与失败信息 artifacts 化。

完成标准：

- remote case 需要的依赖准备步骤已经独立于 test 阶段；
- run 阶段不再以“未执行 cargo fetch / terraform init”作为常态失败路径；
- prepare 日志可用于定位环境瓶颈。

## Phase D — 接入缓存并定义 key

目标：让 prepare 阶段尽量命中 cache，降低 aws-sdk-rust 等大依赖树的重复安装成本。

必做：

1. 为 Go 定义 cache 路径与 key
2. 为 Cargo 定义 cache 路径与 key
3. 为 Terraform 定义 plugin cache 路径与 key
4. 将 restore 与 save 拆开，避免失败 job 盲写坏缓存
5. 明确 `ACT=true` 下的 cache 行为分支

完成标准：

- cache key 方案写入 workflow 或脚本注释；
- hosted runner 的 prepare 阶段可以复用缓存；
- `act` 不因缺失 GitHub cache backend 而失败。

## Phase E — 迁移 act / docs / contributor 入口

目标：让开发者入口统一指向新的 remote e2e workflow。

必做：

1. 更新 `justfile`
   - `act-e2e` 改为运行 `remote-e2e.yml`
2. 更新 `integrations/actions/README.md`
3. 更新 `CONTRIBUTING.md`
4. 更新 `docs/src/content/docs/ci.mdx`
   - 明确 remote e2e 的正式 workflow
   - 明确 `release/*` 与 tag release 的职责区别
   - 明确 `act` 的缓存限制

完成标准：

- 本地开发者不再被导向旧 `actions-e2e.yml`；
- CI docs 与真实 workflow 保持一致；
- release/* 示例与真实仓库策略不再冲突。

## Phase F — 收口验证与删除旧路径

目标：验证新 workflow 成立，并清理旧 workflow 残留。

必做：

1. 本地 `act` 跑通新 workflow 的最小路径
2. GitHub 上通过 `workflow_dispatch` 跑通
3. 在 `release/*` 分支触发至少一次 hosted runner 验证
4. 决定 `actions-e2e.yml` 的最终去留：
   - 删除；或
   - 明确降级为非 remote-e2e smoke workflow
5. 搜索并清理所有仍把 remote e2e 指向旧 workflow 的引用

完成标准：

- 新 workflow 已成为正式入口；
- old path 不再是推荐路径；
- docs / just / README / workflow 真相源一致。

---

## 7. 文件级改动清单

## 7.1 workflow

- 新增：`.github/workflows/remote-e2e.yml`
- 修改或删除：`.github/workflows/actions-e2e.yml`

## 7.2 scripts

- 新增：`scripts/ci/prepare-remote-e2e.sh`
- 新增：`scripts/ci/run-remote-e2e.sh`

## 7.3 harness / test（按需）

- `src/e2e/extractors/main.mbt`
- `src/e2e/extractors/main_test.mbt`
- `src/e2e/extractors/runtime.mbt`

这里只允许做与 workflow 对齐有关的最小修改，例如：

- 调整 failure expectation
- 调整错误信息
- 增补 prepare 成功后的断言逻辑

不在本轮大改 extractor 实现本身。

## 7.4 act / docs

- `justfile`
- `integrations/actions/README.md`
- `CONTRIBUTING.md`
- `docs/src/content/docs/ci.mdx`

## 7.5 spec

- `spec/plan.md`
- `spec/compitable.md`

`spec/compitable.md` 需要补充：

- remote case 的正式 workflow 路径
- prepare/run 证据来源
- aws-sdk-rust remote case 的执行状态与瓶颈说明

---

## 8. 风险与关键决策

## 8.1 风险：Cargo cache 很重，缓存不当反而更慢

影响：

- `aws-sdk-rust` 依赖树大，若直接缓存笨重产物，save/restore 可能比重新 fetch 更慢。

决策：

- 第一版优先缓存 Cargo registry/git；
- 不把 `target/` 当作第一优先级缓存；
- 先以 prepare 阶段日志确认真正瓶颈位置，再决定是否引入更重方案。

## 8.2 风险：act 与 GitHub hosted runner 行为不一致

影响：

- 如果把 hosted cache 命中当作本地验收条件，act 将产生误导性失败。

决策：

- 只要求 act 复用 workflow 编排；
- 不要求 act 命中 GitHub hosted cache；
- 显式记录 `ACT=true` 下的降级行为。

## 8.3 风险：旧 workflow / docs 持续误导开发者

影响：

- 即使新 workflow 存在，开发者仍可能继续跑 `actions-e2e.yml`，导致在旧模型上浪费时间。

决策：

- act 入口、README、CONTRIBUTING、CI docs 必须和 workflow 一起迁移；
- 不允许将这些入口留到“后续再改”。

## 8.4 风险：`release/*` 与 tag release 语义冲突

影响：

- 如果直接修改 `release.yml` 承担 remote e2e，会混淆“发布产物”和“发布前验证”。

决策：

- `release.yml` 保持 tag 触发；
- `remote-e2e.yml` 负责 `release/*` 验证；
- docs 中写清两者区别。

---

## 9. 验证与验收标准

## 9.1 workflow 级验证

至少完成：

```bash
act workflow_dispatch -W .github/workflows/remote-e2e.yml --container-architecture linux/amd64
```

以及 GitHub 上：

- 手动触发一次 `workflow_dispatch`
- 在 `release/*` 分支上触发一次 hosted runner 执行

## 9.2 文本与入口验证

```bash
rg "actions-e2e.yml|act-e2e|release/\*|policy-bundle|software-components\.ndjson" .github integrations docs CONTRIBUTING.md justfile spec
```

要求：

- remote e2e 推荐入口不再指向旧 `actions-e2e.yml`
- active docs / just / README 不再把旧 workflow 当正式入口
- 新 workflow 不再出现 `policy-bundle`
- 新 workflow 不再依赖 `software-components.ndjson`

## 9.3 prepare/run 验证

要求：

- prepare 阶段失败时，能明确区分是 Go / Cargo / Terraform 哪一路依赖预热失败；
- run 阶段失败时，不再把“未执行 cargo fetch / terraform init”作为预期常态；
- aws-sdk-rust 的 Cargo prepare 耗时可被单独观察。

## 9.4 仓库真相源验证

要求：

- `spec/plan.md`、`spec/compitable.md`、`docs/src/content/docs/ci.mdx`、`justfile`、`integrations/actions/README.md` 对 remote e2e 入口的描述一致；
- `release.yml` 与 `remote-e2e.yml` 的职责边界清晰；
- 三个 env gate 的语义保留。

---

## 10. 实施顺序（必须按序）

1. 先写清并提交新 `spec/plan.md`
2. 再新增 `remote-e2e.yml`
3. 再抽出 prepare/run 脚本
4. 再接缓存
5. 再迁 act / docs / just / README 入口
6. 最后清理旧 `actions-e2e.yml`

不得反过来先改 docs 再决定 workflow 形态，也不得继续在旧 workflow 上临时修补并把它留成长期入口。

---

## 11. 一句话摘要

本轮不是继续跳过 remote e2e，而是把它正式收口成一个可缓存、可复用、可用 act 本地复现的专用 workflow：先 prepare 环境，再 run 远端 case，并同时迁移 workflow、act 入口、docs 与 spec 真相源。
