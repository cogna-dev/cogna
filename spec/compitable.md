# Extractor / Source / Surface 兼容性矩阵（持续增补）

本文是 `spec/plan.md` Phase 6 的落地矩阵，必须同时覆盖两层内容：

1. **source type / surface matrix**（LocalWorkspace、CargoPackage、GoModule、TerraformPackage、GitRepo，以及 native build / native diff / readonly SDK query/fetch / acceptance coverage）；
2. **各语言 extractor 的语法特性兼容性**（feature-level evidence）。

目标有三个：

1. 在真正跑 `src/e2e/extractors/*` 之前，先给出一份可执行的 repo-proven 基线；
2. 在每一次 `e2e/extractors` 实测后，持续升级/回写通过项与缺口项；
3. 把 skip 与 unsupported 项沉淀成可追溯台账，避免“口头兼容”。

> 这是一份 living document。任何新的 real-world case，只要暴露了新的语法特性、resolver 缺口、错误分类或 skip 理由，都必须同步回写本文件。

---

## 1. Source / Surface 兼容性矩阵（Phase 6 必填）

### 1.1 Source type 支持情况

| Source Type | Status | 当前证据 | 备注 / 后续动作 |
|---|---:|---|---|
| LocalWorkspace | ✅ repo-proven | `src/core/virtual_package/types.mbt`, `src/cmd/build/source/local.mbt`, `src/cmd/build/source/main_test.mbt` (`local source resolver builds readonly package...`) | 作为主工作流持续维护 |
| CargoPackage | ✅ repo-proven | `src/cmd/build/source/cargo.mbt`, `src/cmd/build/source/main_test.mbt`（vendor 优先、registry fallback、missing guidance） | real-world e2e 依赖本机 `cargo fetch`/`cargo vendor` |
| GoModule | ✅ repo-proven | `src/cmd/build/source/gomod.mbt`, `src/cmd/build/source/main_test.mbt`（vendor 优先、cache fallback、escaped path） | real-world e2e 依赖本机 `go mod download`/`go mod vendor` |
| TerraformPackage | ✅ repo-proven | `src/cmd/build/source/terraform.mbt`, `src/cmd/build/source/main_test.mbt`（module/provider initialized guidance） | provider 以 lockfile identity 为准，binary 不做源码解析 |
| GitRepo | 🟡 repo-proven | `src/cmd/build/source/git.mbt`, `src/cmd/build/source/main_test.mbt`（clone local repository） | `src/e2e/extractors/runtime.mbt` 已支持 git source，默认由 `COGNA_ENABLE_GIT_REMOTE_E2E` 控制是否执行远端 case |

### 1.2 Surface 支持情况

| Surface | Status | 当前证据 | 备注 / 后续动作 |
|---|---:|---|---|
| native build | ✅ repo-proven | `src/cmd/build/pipeline.mbt`, `src/cmd/build/main_test.mbt` | bundle contract 已去除 `software-components.ndjson` |
| native diff | ✅ repo-proven | `src/cmd/diff/pipeline.mbt`, `src/cmd/diff/main_test.mbt` | dependency compare 走 SPDX transient derive |
| readonly SDK query/fetch | ✅ repo-proven | `src/sdk/js.mbt`, `src/sdk/moon.pkg`, `src/sdk/query.mbt`, `src/sdk/sdk_test.mbt` | 仅保留 query/fetch/parse helpers |
| Desktop build/diff path | ✅ repo-proven | `integrations/desktop/src/main/sdk.ts`（通过 CLI `build` / `diff`） | IPC channel 名称仍为 `sdk:*`，语义上已不走 SDK runtime |
| acceptance coverage | ✅ e2e-proven | `src/e2e/extractors/main_test.mbt`, `src/e2e/extractors/main.mbt`, `e2e/extractors/{rust,go,openapi,terraform}.json`, `e2e/extractors/*/*/snapshots/cogna/*` | 本地 examples 驱动的多语言 e2e snapshots 已落地；远端 package/repo case 保留为环境依赖 case |

---

## 2. 记录原则

### 1.1 这份文件记录什么

本文件只记录：

- extractor 是否识别某种**语法结构 / 声明结构**；
- 识别后是否产出稳定 declaration；
- diff / metadata 是否对该语法特性有额外语义；
- 哪些特性仅完成预研、哪些已通过 e2e 证明、哪些在真实仓库中失败过。

本文件不记录：

- resolver 下载协议；
- CLI / SDK surface；
- bundle artifact contract；
- cache / remote transport 设计。

这些内容应分别留在 `spec/plan.md` 与相关实现文档中。

### 1.2 状态定义

- `✅ e2e-proven`：已在真实 `e2e/extractors` case 中跑通，有 case 证据
- `🟡 repo-proven`：仓库内 extractor / snapshot / diff / reader tests 已覆盖，但还没有 real-world e2e 证据
- `🟠 observed-gap`：已在 real-world case 或 review 中观察到缺口，需要补实现或明确 skip
- `⏭ skipped`：当前明确跳过，但需保留原因与后续动作
- `❌ unsupported`：当前不支持，也不准备在本轮实现

### 1.3 证据字段要求

每一行至少要能追溯到以下证据之一：

- extractor 实现文件 / 函数
- 仓库内 test 名称
- snapshot baseline 路径
- real-world e2e case id

不允许把“猜测可支持”写成 `✅ e2e-proven`。

### 1.4 acceptance 证据清单

若某个 feature 要升级为 `✅ e2e-proven`，至少应能关联到以下 acceptance 产物：

- `declarations.ndjson`
- `manifest.json`
- `metadata.json`
- `checksums.txt`

并满足：

- `declarations.ndjson` 非空；
- 每行是合法 JSON；
- 至少能定位到对应 case 的 snapshot 路径或日志位置。

---

## 3. 更新工作流（必须执行）

### 2.1 当前基线阶段

当前 `src/e2e/extractors/*` harness 已经落地，因此这份矩阵的维护基线改为：

- local examples + snapshot evidence 是当前主验收线；
- repo tests / snapshot tests 继续作为 `🟡 repo-proven` 的补充证据；
- 如果某个语言特性只有代码意图、没有 case/snapshot 证据，宁可不写，或写成 `⏭ skipped` / `🟠 observed-gap`。

### 2.2 e2e 运行阶段

每次跑 `src/e2e/extractors/*` 后，必须执行以下动作：

1. 把本次 case 实际触发到的语法特性补记到对应语言表；
2. 若某个特性第一次被真实仓库证明成功：`🟡 repo-proven -> ✅ e2e-proven`；
3. 若某个特性在真实仓库中失败：新增或更新为 `🟠 observed-gap`；
4. 在“Case 证据台账”中追加 case id、snapshot 路径、失败/skip 原因；
5. 若新 case 暴露出此前表中没有的语法结构，必须新增对应 feature row。

### 2.3 当前 harness 与证据入口

当前仓库里，`src/e2e/extractors/*` harness 已经作为真实入口存在，因此当前证据来源是：

- `e2e/extractors/*.json`：machine-readable case manifest；
- `src/e2e/extractors/*`：local/package/git source harness 与 skip gating 实现；
- `e2e/extractors/*/*/snapshots/cogna/*`：当前 local examples 与 deferred remote cases 的 snapshot 证据；
- `src/cmd/build/snapshot_test.mbt`：补充性的 repo snapshot baseline。

也就是说：feature baseline 不再停留在“等待 harness 落地”的过渡状态，而是以**已落地的 local harness + snapshot evidence**为当前基线。

若需要刷新 snapshot，当前参考命令：

```bash
COGNA_UPDATE_SNAPSHOTS=true moon test --target native src/cmd/build/snapshot_test.mbt
```

### 2.4 更新触发器

以下任一情况出现时，必须更新本文件：

- 新增 extractor 语法规则
- 新增 snapshot fixture
- 新增 diff rule / richer metadata rule
- 新增 real-world e2e case
- 某个 case 失败并确认是语法兼容性问题
- 某个特性从 skip / gap 变成已支持

---

## 4. 证据来源（当前仓库基线）

当前可直接作为预研证据的仓库内来源：

- Rust extractor：`src/extractors/rust/main.mbt`
- Go extractor：`src/extractors/go/main.mbt`
- Terraform extractor：`src/extractors/terraform/main.mbt`
- OpenAPI extractor：`src/extractors/openapi/main.mbt`
- Snapshot baseline tests：`src/cmd/build/snapshot_test.mbt`
- Diff richer metadata tests：`src/cmd/diff/main_test.mbt`
- Bundle reader richer declaration tests：`src/core/bundle/reader_test.mbt`
- Extract subpackage enrichment tests：`src/core/extract/subpackages_test.mbt`
- 现有 e2e manifest：`e2e/extractors/{rust,go,openapi,terraform,go-remote,terraform-remote}.json`

说明：

- `src/e2e/extractors/*` harness 已落地并支持 local/package/git 多 source；
- 当前仍保留部分 `🟡 repo-proven` 行用于记录“需真实远端样本或更复杂语法样本”的能力；
- 只有当真实 case 进入 `e2e/extractors` 并留下 case/snapshot 证据后，才允许升级成 `✅ e2e-proven`。

---

## 5. Rust 语法兼容性矩阵

当前预研基线主要来自：

- `src/extractors/rust/main.mbt`
- `src/core/extract/subpackages_test.mbt`
- `src/cmd/build/snapshot_test.mbt` 的 rust baseline
- `src/cmd/diff/main_test.mbt` 的 richer rust metadata tests
- `src/core/bundle/reader_test.mbt` 的 richer rust ndjson test

| Feature | Status | 当前证据 | 备注 / 后续更新点 |
|---|---:|---|---|
| free functions | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | local rust example 已实测通过 |
| public/private visibility | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `pub` / `pub(crate)` use 项已进入 e2e |
| structs / enums / traits | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `ApiItem` / `Status` / `Service` 已进入 e2e |
| impl blocks | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | inherent impl + trait impl 已进入 e2e |
| associated functions | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `Service::call` 已进入 e2e |
| associated consts | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `Service::VERSION` 已进入 e2e |
| associated types | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `Service::Output` 已进入 e2e |
| generics / type params | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `ApiItem<T>` / const generics 样例已进入 e2e |
| where clauses | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `ApiItem<T>` 与 impl 的 `where T: Clone` 已进入 e2e |
| async functions | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `load_value` async fn 已进入 e2e |
| unsafe functions | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `dangerous` 样例已进入 e2e |
| extern ABI functions | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `c_add` 样例已进入 e2e |
| macro exports / `macro_rules!` | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `make_status` 样例已进入 e2e |
| doc comments (`///`) | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `ApiItem<T>` 文档注释路径已进入 e2e |
| deprecated attributes | ✅ e2e-proven | `e2e/extractors/rust/rust-local-example/snapshots/cogna/declarations.ndjson` | `ApiItem<T>` 的 deprecated 元信息已进入 e2e |
| test-only items / cfg-gated items | ⏭ skipped | 未见明确 extractor 规则 | 如 real-world case 暴露再拆分 |
| proc macros / derive macro expansion semantics | ❌ unsupported | 未见 parser / semantic expansion 逻辑 | 当前只做文本级 declaration extraction |

---

## 6. Go 语法兼容性矩阵

当前预研基线主要来自：

- `src/extractors/go/main.mbt`
- `src/core/extract/subpackages_test.mbt`
- `src/cmd/build/snapshot_test.mbt` 的 go baseline
- `src/cmd/diff/main_test.mbt` 中 generic richer shape tests

| Feature | Status | 当前证据 | 备注 / 后续更新点 |
|---|---:|---|---|
| package declarations | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | go local example 已实测通过 |
| imports | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | normal/alias/blank/dot import 已进入 e2e |
| const / var declarations | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | grouped const/var 样例已进入 e2e |
| grouped declarations (`const (...)`, `var (...)`, `type (...)`, `import (...)`) | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | grouped declarations 样例已进入 e2e |
| type declarations | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | type alias + named struct/interface 已进入 e2e |
| structs | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `Greeter` / `Box[T]` 已进入 e2e |
| struct fields | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `Greeter.Prefix` / `Box.Value` 已进入 e2e |
| embedded fields | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `Box.Greeter` 已进入 e2e |
| interfaces | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `PayloadReader` / `Composite` 已进入 e2e |
| free functions | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `Hello` / `MapValue` / `NewGreeter` 已进入 e2e |
| methods | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | pointer/value receiver 样例已进入 e2e |
| pointer receivers | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `(*Greeter).Greet` 样例已进入 e2e |
| generics / type params | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `Box[T]` / `MapValue[T,U]` 样例已进入 e2e |
| named / tuple-like returns | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | `Read() (Message, error)` 与函数返回类型已进入 e2e |
| comments as docs | ✅ e2e-proven | `e2e/extractors/go/go-local-example/snapshots/cogna/declarations.ndjson` | interface/function 上方注释路径已进入 e2e |
| build tags / file-level constraints | ⏭ skipped | 未见显式 extractor 规则 | 若 real-world case 暴露再补 |
| cgo constructs | ⏭ skipped | 未见专门规则 | 当前先不单列支持 |

---

## 7. Terraform 语法兼容性矩阵

当前预研基线主要来自：

- `src/extractors/terraform/main.mbt`
- `src/cmd/build/snapshot_test.mbt` 的 terraform baseline
- `src/cmd/diff/main_test.mbt` 的 terraform richer metadata tests
- `src/core/bundle/reader_test.mbt` 的 richer terraform ndjson test

| Feature | Status | 当前证据 | 备注 / 后续更新点 |
|---|---:|---|---|
| `terraform` block | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | `required_providers` 结构已进入 e2e |
| `provider` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | provider requirements / alias 相关记录已进入 e2e |
| `resource` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | terraform local example 已实测通过 |
| `data` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | `depends_on = [data.aws_caller_identity.current]` 关联已进入 e2e |
| `variable` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | required/sensitive/validation 样例已进入 e2e |
| `output` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | output+depends_on 样例已进入 e2e |
| `module` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | local module + providers 样例已进入 e2e |
| `locals` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | `local.base_tags` 表达式样例已进入 e2e |
| `check` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | check/assert 语义相关记录已进入 e2e |
| `dynamic` blocks | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | `dynamic ingress` 样例已进入 e2e |
| provider requirements / versions | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | required_providers 版本约束样例已进入 e2e |
| provider aliases | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | aliased provider 场景已进入 e2e |
| `depends_on` | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | module/resource/output depends_on 已进入 e2e |
| lifecycle: `prevent_destroy` | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | lifecycle block 已进入 e2e |
| lifecycle: `create_before_destroy` | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | lifecycle block 已进入 e2e |
| lifecycle: `ignore_changes` | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | lifecycle block 已进入 e2e |
| attribute / expression parsing via HCL AST | ✅ e2e-proven | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/declarations.ndjson` | type/object/expression 解析结果已进入 e2e |
| `for_each` / `count` semantics | ⏭ skipped | 未见明确特性级 rule | 如 e2e 暴露再拆分 |
| deep module graph / cross-file resolution | ⏭ skipped | 当前文档只记录 declaration extraction，不承诺 full semantic graph | 后续按 case 增补 |

---

## 8. OpenAPI 语法兼容性矩阵

当前预研基线主要来自：

- `src/extractors/openapi/main.mbt`
- `src/cmd/build/snapshot_test.mbt` 的 openapi baseline
- `src/cmd/diff/main_test.mbt` 的 openapi richer metadata tests
- `src/core/bundle/reader_test.mbt` 的 richer openapi ndjson test

| Feature | Status | 当前证据 | 备注 / 后续更新点 |
|---|---:|---|---|
| `paths` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | openapi local example 已实测通过 |
| operations / HTTP methods | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | GET/POST operations 样例已进入 e2e |
| `components.schemas` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | oneOf/anyOf/discriminator schemas 样例已进入 e2e |
| `components.parameters` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | RequestId / paymentId 参数样例已进入 e2e |
| `components.responses` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | NotFound response 样例已进入 e2e |
| `components.requestBodies` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | PaymentRequest / callback requestBody 已进入 e2e |
| `components.headers` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | `CorrelationId` header component 已进入 e2e |
| `components.securitySchemes` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | ApiKeyAuth / OAuth2 已进入 e2e |
| `callbacks` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | callback expression 样例已进入 e2e |
| `webhooks` | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | webhook path 样例已进入 e2e |
| `$ref` references | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | components/internal/external `$ref` 已进入 e2e |
| discriminator mapping | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | discriminator declaration 已进入 e2e |
| status codes | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | `200/201/404` response status 路径已进入 e2e |
| media types | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | `application/json` content 样例已进入 e2e |
| parameter requiredness | ✅ e2e-proven | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/declarations.ndjson` | required path/body 参数样例已进入 e2e |
| YAML anchors / advanced schema composition | ⏭ skipped | 未见明确 extractor 规则 | 如真实 case 出现再拆分 |

---

## 9. Policy / Rego 使用边界

policy 当前不属于 extractor 兼容性矩阵。

本仓库当前约定是：

| Capability | Status | 当前证据 | 备注 |
|---|---:|---|---|
| `init` materializes built-in policy into workspace | 🟡 repo-proven | `src/cmd/init/*` | 当前阶段的正确入口是 `./.cogna/policies` |
| `check` evaluates policy directory via OPA bundle input | ✅ repo-proven | `src/cmd/check/main.mbt`, `src/cmd/check/main_test.mbt` | policy 目录直接作为 `opa eval --bundle ...` 输入 |
| policy in extractor/build/diff mainline | ⛔ not-supported | 本阶段显式禁止 | 不再维护任何策略 profile，也不再规划 `src/extractors/policy` |

---

## 10. Real-world e2e Case 证据台账

本节必须随着 `src/e2e/extractors/*` 执行持续追加，不能只停留在设计基线。

建议字段：

| Case ID | Language | Source | Status | 触发到的 feature rows | Snapshot / 证据 | Notes |
|---|---|---|---:|---|---|---|
| `rust-local-example` | rust | local workspace | ✅ e2e-proven | free functions / generics / unsafe / extern ABI / macro_rules | `e2e/extractors/rust/rust-local-example/snapshots/cogna/*` | 基于 `e2e/examples/rust-crate/full/repo` |
| `go-local-example` | go | local workspace | ✅ e2e-proven | package decl / grouped decl / methods / pointer receiver / generics | `e2e/extractors/go/go-local-example/snapshots/cogna/*` | 基于 `e2e/examples/go-module/full/repo` |
| `openapi-local-example` | openapi | local workspace | ✅ e2e-proven | paths / operations / schemas / callbacks / webhooks | `e2e/extractors/openapi/openapi-local-example/snapshots/cogna/*` | 基于 `e2e/examples/openapi-spec/full/repo` |
| `terraform-local-example` | terraform | local workspace | ✅ e2e-proven | resource / variable / module / dynamic block | `e2e/extractors/terraform/terraform-local-example/snapshots/cogna/*` | 基于 `e2e/examples/terraform-module/full/repo` |
| `go-module-remote-example` | go | module cache | ⏭ skipped | imports / interfaces / functions / generics / comments as docs | `e2e/extractors/go/go-module-remote-example/snapshots/cogna/*` | 当前阶段 deferred；仅在 `COGNA_ENABLE_REMOTE_E2E=true` 时执行 |
| `terraform-module-remote-example` | terraform | terraform modules cache | ⏭ skipped | required_providers / for_each / count / depends_on / type constraints | `e2e/extractors/terraform/terraform-module-remote-example/snapshots/cogna/*` | 当前阶段 deferred；仅在 `COGNA_ENABLE_REMOTE_E2E=true` 时执行 |
| `rust:aws-sdk-dynamodb@1.110.0` | rust | cargo | ⏭ skipped | _待补_ | `e2e/extractors/rust.json` | 当前阶段 deferred；仅在 `COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E=true` 时执行 |
| `rust:aws-config@1.8.15` | rust | cargo | ⏭ skipped | _待补_ | `e2e/extractors/rust.json` | 当前阶段 deferred；仅在 `COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E=true` 时执行 |
| `rust:https://github.com/awslabs/aws-sdk-rust@main` | rust | git | ⏭ skipped | _待补_ | `e2e/extractors/rust.json` | 当前阶段 deferred；仅在 `COGNA_ENABLE_GIT_REMOTE_E2E=true` 时执行 |

remote case 的后续执行入口统一为：

- `.github/workflows/remote-e2e.yml`
- `scripts/ci/prepare-remote-e2e.sh`
- `scripts/ci/run-remote-e2e.sh`

执行证据优先记录：

- workflow run URL
- `remote-e2e-prepare-logs` artifact
- `remote-e2e-artifacts` artifact

aws-sdk-rust 相关 case 的主要观察指标：

- Cargo prepare 阶段耗时
- `cargo fetch` 是否命中缓存
- run 阶段是否仍出现“not available locally”类错误

后续每新增一个 case，必须至少补：

- case id
- language
- source type
- 实际命中的 feature rows
- snapshot 路径 / 失败日志位置
- 若失败：明确写出是 parser gap、normalization gap、resolver gap 还是预期 skip

---

## 11. 发现缺口时的记录格式

当 real-world case 暴露缺口时，不要只写一句“失败”。至少记录成下面这种结构：

| Language | Feature | Status | First Seen In | Symptom | Next Action |
|---|---|---:|---|---|---|
| rust | macro exports with nested attrs | 🟠 observed-gap | `rust:case-id` | declaration 丢失 / metadata 不完整 | 新增 fixture + 补 extractor rule |
| go | embedded interface chains | 🟠 observed-gap | `go:case-id` | owner / relation 不稳定 | 加 snapshot + richer diff check |
| terraform | dynamic block nested attrs | 🟠 observed-gap | `terraform:case-id` | attribute flattening 不完整 | 增加 parser normalization |

---

## 12. 本文件的强制更新规则

1. 任何新的 `e2e/extractors` case，都必须检查是否需要新增或更新 feature row；
2. 任何 feature 从 `🟡 repo-proven` 升级到 `✅ e2e-proven`，必须附带 case id 或 snapshot 证据；
3. 任何 skip / unsupported，都必须写明原因，不能只写“暂不支持”；
4. 不允许把“仓库内 unit/snapshot 覆盖”伪装成“真实仓库已兼容”；
5. 若 real-world case 暴露新语法结构，但当前矩阵里没有对应 feature，必须先补 feature row，再补实现；
6. 若 `spec/plan.md` 中新增语言或 extractor，本文件必须同步新增对应章节。
