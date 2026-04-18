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
| GitRepo | 🟡 repo-proven | `src/cmd/build/source/git.mbt`, `src/cmd/build/source/main_test.mbt`（clone local repository） | `src/e2e/extractors/runtime.mbt` 默认将 git case 标记为 skipped，待后续开启 |

### 1.2 Surface 支持情况

| Surface | Status | 当前证据 | 备注 / 后续动作 |
|---|---:|---|---|
| native build | ✅ repo-proven | `src/cmd/build/pipeline.mbt`, `src/cmd/build/main_test.mbt` | bundle contract 已去除 `software-components.ndjson` |
| native diff | ✅ repo-proven | `src/cmd/diff/pipeline.mbt`, `src/cmd/diff/main_test.mbt` | dependency compare 走 SPDX transient derive |
| readonly SDK query/fetch | ✅ repo-proven | `src/sdk/js.mbt`, `src/sdk/moon.pkg`, `src/sdk/query.mbt`, `src/sdk/sdk_test.mbt` | 仅保留 query/fetch/parse helpers |
| Desktop build/diff path | ✅ repo-proven | `integrations/desktop/src/main/sdk.ts`（通过 CLI `build` / `diff`） | IPC channel 名称仍为 `sdk:*`，语义上已不走 SDK runtime |
| acceptance coverage | 🟡 in-progress | `src/e2e/extractors/main_test.mbt`, `src/e2e/extractors/main.mbt`, `e2e/extractors/rust.json` | Rust case manifest 已接入；需持续补真实 pass/skip 台账 |

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

### 2.1 初始预研阶段

在还没有完整 `e2e/extractors` harness 之前：

- 先根据 `src/extractors/*`、`src/cmd/build/snapshot_test.mbt`、`src/cmd/diff/main_test.mbt`、`src/core/bundle/reader_test.mbt` 填出 `🟡 repo-proven` 基线；
- 如果某个语言特性只在代码里看得到意图，但没有测试/样例证据，宁可不写，或写成 `⏭ skipped` / `🟠 observed-gap`。

### 2.2 e2e 运行阶段

每次跑 `src/e2e/extractors/*` 后，必须执行以下动作：

1. 把本次 case 实际触发到的语法特性补记到对应语言表；
2. 若某个特性第一次被真实仓库证明成功：`🟡 repo-proven -> ✅ e2e-proven`；
3. 若某个特性在真实仓库中失败：新增或更新为 `🟠 observed-gap`；
4. 在“Case 证据台账”中追加 case id、snapshot 路径、失败/skip 原因；
5. 若新 case 暴露出此前表中没有的语法结构，必须新增对应 feature row。

### 2.3 在正式 e2e harness 完成前的当前做法

当前仓库里还没有完整落地的 `src/e2e/extractors/*` harness，因此在过渡阶段：

- `e2e/extractors/*.json` 是 machine-readable case manifest；
- `src/cmd/build/snapshot_test.mbt` 是当前可复用的 snapshot 证据入口；
- 在真正的 e2e harness 落地前，feature baseline 先以 repo tests + snapshot evidence 维持。

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
- 现有 e2e manifest：`e2e/extractors/rust.json`

说明：

- 当前仓库里还没有完整提交的 `src/e2e/extractors/*` harness 实现；
- 因此本文件中的 `🟡 repo-proven` 主要来自 extractor 实现、snapshot tests、diff tests、reader tests；
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
| free functions | 🟡 repo-proven | `src/extractors/rust/main.mbt:732+` | baseline 已覆盖；等待 real-world e2e |
| public/private visibility | 🟡 repo-proven | `src/extractors/rust/main.mbt:707`, `893+` | signature 已编码可见性 |
| structs / enums / traits | 🟡 repo-proven | `decl_name`, `strip_decl_modifiers`, `extract_file` | 需 real-world case 验证更复杂 trait body |
| impl blocks | 🟡 repo-proven | `impl_targets`, `extract_file`, `subpackages_test.mbt` | 已有 impl metadata enrichment 证据 |
| associated functions | 🟡 repo-proven | `extract_file` 中 `associated_fn` | 需 e2e 验证 trait impl 组合 |
| associated consts | 🟡 repo-proven | `extract_file` 中 `associated_const` | 需 real-world case |
| associated types | 🟡 repo-proven | `extract_file` 中 `associated_type` | 需 real-world case |
| generics / type params | 🟡 repo-proven | `signature_type_params`, `decl_name`, `normalize_owner_key` | 已见 type param parsing 逻辑 |
| where clauses | 🟡 repo-proven | `where_clause`, `multiline_clause` | 需 e2e 验证 multiline where |
| async functions | 🟡 repo-proven | `strip_decl_modifiers` | 当前从 signature 归一化；等待 e2e |
| unsafe functions | 🟡 repo-proven | `is_unsafe`, `diff marks rust declarations changed...` | diff 已有 breaking rule 证据 |
| extern ABI functions | 🟡 repo-proven | `extern_abi`, `bundle reader accepts richer rust declaration ndjson` | `extern "C"` 已有 reader 证据 |
| macro exports / `macro_rules!` | 🟡 repo-proven | `#[macro_export]`, `macro_rules!` branch in `extract_file` | 需 real-world macro-heavy crate |
| doc comments (`///`) | 🟡 repo-proven | `extract_file` pending_doc logic | 仍需 e2e 样本 |
| deprecated attributes | 🟡 repo-proven | `#[deprecated]` handling in `extract_file` | 需 e2e 样本 |
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
| package declarations | 🟡 repo-proven | `extract_file` declaration prefixes | 需 e2e 多 package 样本 |
| imports | 🟡 repo-proven | `extract_record`, `enrich_record` 中 `importPath` / `importAlias` | alias import 已有字段 |
| const / var declarations | 🟡 repo-proven | `extract_file` group handling + `extract_record` | 包括 grouped declarations |
| grouped declarations (`const (...)`, `var (...)`, `type (...)`, `import (...)`) | 🟡 repo-proven | `group_kind` / `group_scope_depth` | 需要 e2e 验证复杂 group formatting |
| type declarations | 🟡 repo-proven | `type_name`, `extract_record` | 包括 type alias / named types |
| structs | 🟡 repo-proven | `active_struct`, `struct_name`, `extract_struct_field` | baseline 已覆盖；等待 e2e |
| struct fields | 🟡 repo-proven | `extract_struct_field` | 需 real-world anonymous field 样本 |
| embedded fields | 🟡 repo-proven | `embedded_field`, `collect_embedding_index` | 已有 embedding enrichment 逻辑 |
| interfaces | 🟡 repo-proven | `enrich_record` for `interface` | 需 e2e 验证 embedded interfaces |
| free functions | 🟡 repo-proven | `extract_record` + `function_return_types` | baseline 已覆盖 |
| methods | 🟡 repo-proven | `receiver_parts`, `method_param_types`, `subpackages_test.mbt` | receiver metadata 已有 test |
| pointer receivers | 🟡 repo-proven | `receiver_parts` + `pointerReceiver` flag | 需 e2e 样本 |
| generics / type params | 🟡 repo-proven | `type_name` + `signature_type_params` in enrich path | 需真实泛型 Go case |
| named / tuple-like returns | 🟡 repo-proven | `return_types_after_params`, `function_return_types` | 已有 return extraction 逻辑 |
| comments as docs | 🟡 repo-proven | `//` pending_doc handling | 需 e2e 样本 |
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
| `terraform` block | 🟡 repo-proven | `hcl_block_name`, `parse_hcl_file` | 需 real-world module e2e |
| `provider` blocks | 🟡 repo-proven | `hcl_block_name`, `collect_required_providers`, `uses_provider` relation | provider alias 已有逻辑 |
| `resource` blocks | 🟡 repo-proven | `hcl_block_name`, `extract_file` | baseline 已覆盖 |
| `data` blocks | 🟡 repo-proven | `hcl_block_name` | 需 e2e 样本 |
| `variable` blocks | 🟡 repo-proven | `hcl_block_name`, `diff marks terraform variables becoming required...` | required flag 已有 diff 规则 |
| `output` blocks | 🟡 repo-proven | `hcl_block_name`, `terraform-output-removed` diff test | output removal 已有 diff 证据 |
| `module` blocks | 🟡 repo-proven | `hcl_block_name` includes `module` | 需 real-world nested module cases |
| `locals` blocks | 🟡 repo-proven | `hcl_block_name` | 需 e2e 样本 |
| `check` blocks | 🟡 repo-proven | `hcl_block_name` includes `check` | 当前仅结构识别 |
| `dynamic` blocks | 🟡 repo-proven | `hcl_block_name` includes `dynamic` | 需 e2e 验证 deeper attrs |
| provider requirements / versions | 🟡 repo-proven | `collect_required_providers`, `providers.terraform` reader test | `source` / `version` / `alias` 均有 evidence |
| provider aliases | 🟡 repo-proven | `TerraformProviderInfo.provider_alias`, `providerRef` | diff / reader 已验证 |
| `depends_on` | 🟡 repo-proven | terraform reader test includes `dependsOn` | 需 e2e |
| lifecycle: `prevent_destroy` | 🟡 repo-proven | `terraform-prevent-destroy-added` diff test | richer metadata 已覆盖 |
| lifecycle: `create_before_destroy` | 🟡 repo-proven | `terraform-create-before-destroy-added` diff test | richer metadata 已覆盖 |
| lifecycle: `ignore_changes` | 🟡 repo-proven | `terraform-ignore-changes-expanded` diff test | richer metadata 已覆盖 |
| attribute / expression parsing via HCL AST | 🟡 repo-proven | `@hcl.parse`, `expression_to_text` | 真实复杂表达式仍待 e2e |
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
| `paths` | 🟡 repo-proven | `extract_file` handles `paths:` and path records | baseline 已覆盖 |
| operations / HTTP methods | 🟡 repo-proven | `operation(line)`, `httpMethod` metadata | reader / diff 均有证据 |
| `components.schemas` | 🟡 repo-proven | `component_kind("schemas")` | 需 e2e 样本 |
| `components.parameters` | 🟡 repo-proven | `component_kind("parameters")`, `parameterIn`, `required` | richer metadata path 已有 |
| `components.responses` | 🟡 repo-proven | `component_response_media_types` | 需 e2e 更复杂 media types |
| `components.requestBodies` | 🟡 repo-proven | `component_kind("requestBodies")` | 需 e2e |
| `components.headers` | 🟡 repo-proven | `component_kind("headers")` | 需 e2e |
| `components.securitySchemes` | 🟡 repo-proven | `security_scheme` kind, `securitySchemeName` | 需 e2e |
| `callbacks` | 🟡 repo-proven | `active_callback_expression`, reader test `callbackExpression` | 已有 explicit metadata |
| `webhooks` | 🟡 repo-proven | `in_webhooks`, `component_kind("webhooks")` | 需 e2e |
| `$ref` references | 🟡 repo-proven | `normalize_reference_target`, `ref` metadata | ref extraction 已有代码 |
| discriminator mapping | 🟡 repo-proven | reader test includes `discriminatorMapping` | 需 e2e |
| status codes | 🟡 repo-proven | `diff marks openapi deeper status...` | diff 已覆盖 narrowing / status changes |
| media types | 🟡 repo-proven | reader test `mediaTypes`, component response collection | richer metadata 已覆盖 |
| parameter requiredness | 🟡 repo-proven | `required` metadata setting | 需 e2e |
| YAML anchors / advanced schema composition | ⏭ skipped | 未见明确 extractor 规则 | 如真实 case 出现再拆分 |

---

## 9. Policy / Rego 兼容性记录

当前仓库有 policy-bundle build tests，但还没有与 `src/extractors/*` 对齐的独立语法兼容性矩阵基础。

因此本轮先记录为：

| Feature Group | Status | 当前证据 | 备注 |
|---|---:|---|---|
| builtin policy bundle assembly | 🟡 repo-proven | `src/cmd/build/main_test.mbt` policy-bundle tests | 当前是 build 规则，不是 extractor 语法矩阵 |
| custom rego file ordering / validation | 🟡 repo-proven | `build reads custom rego files...`, duplicate / missing metadata tests | 如后续增加独立 rego extractor，再拆出细化表 |
| rego syntax declarations matrix | ⏭ skipped | 尚无 `src/extractors/policy` | 等真正 extractor 出现后再立表 |

---

## 10. Real-world e2e Case 证据台账

本节必须随着 `src/e2e/extractors/*` 执行持续追加，不能只停留在设计基线。

建议字段：

| Case ID | Language | Source | Status | 触发到的 feature rows | Snapshot / 证据 | Notes |
|---|---|---|---:|---|---|---|
| `rust:aws-sdk-dynamodb@1.110.0` | rust | cargo | _pending_ | _待补_ | `e2e/extractors/rust.json` | 首批 real-world cargo case |
| `rust:aws-config@1.8.15` | rust | cargo | _pending_ | _待补_ | `e2e/extractors/rust.json` | 首批 real-world cargo case |
| `rust:https://github.com/awslabs/aws-sdk-rust` | rust | git | _pending_ | _待补_ | `e2e/extractors/rust.json` | 首批 real-world git case |

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
