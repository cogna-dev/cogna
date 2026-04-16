# MoonBit JS target 的 `.d.ts` 能否替代 proto 作为 TS SDK contract？

本文回答一个非常具体的问题：

> 对于 CodeIQ 计划中的 TS SDK，原生 MoonBit 导出到 JS target 时附带的 `.d.ts`，能否**完全代替** proto 在方案中的定位？

结论先行：

> **不能完全代替。**
>
> MoonBit JS target 导出的 `.d.ts` 很适合作为 **Node / TypeScript 消费层的静态类型视图**，也能显著降低手写 wrapper types 的维护成本；但它**不能替代** proto 在以下几类职责上的作用：
>
> - 语言无关的数据契约
> - schema / wire / JSON 兼容性演进检查
> - 运行时验证与 `schemaVersion` 约束
> - 面向多语言生成的单一 truth source
> - 对 `oneof`、field number、`Struct` / `NullValue` 等语义的稳定跨语言表达

更准确地说：

- **可以替代的部分**：TS SDK 对外暴露的很多手写 `.d.ts` 类型层；
- **不能替代的部分**：proto 作为公共 contract / codegen source / compatibility source of truth 的角色。

---

## 1. 调研范围

本次调研同时看了两类证据：

1. **仓库内现实证据**
   - 当前 MoonBit JS target、Node SDK、schema/proto、测试与校验链路到底怎么工作；
2. **外部参考**
   - TypeScript 官方对 `.d.ts` 的定义；
   - Protobuf / Buf 官方对 proto 作为 contract 与兼容性检查基础的定义；
   - MoonBit / 社区工具对 `.d.ts` 与 `.mbti` 的定位。

---

## 2. 先给判断

## 2.1 如果问题是“TS 用户能不能直接消费 MoonBit 生成的 `.d.ts`？”

答案是：**可以，而且很有价值。**

MoonBit JS target 导出的 `.d.ts` 可以直接改善：

- TS 编辑器补全
- API 类型提示
- npm package 的 `types` 输出
- 减少手写 wrapper `.d.ts`

## 2.2 如果问题是“`.d.ts` 能不能成为整个系统唯一 contract source of truth？”

答案是：**不能。**

因为 `.d.ts` 只能描述 **TypeScript 世界里的静态类型视图**，而 proto 在这个方案中的职责远不止“给 TS 看类型”。

proto 还承担：

- 语言中立的数据模型定义
- 兼容性演进基线
- 运行时 schema 验证源
- 双端/多端代码生成输入
- JSON / binary / future transport 的语义锚点

这些都不是 `.d.ts` 擅长或能稳定覆盖的范围。

---

## 3. 仓库内证据

## 3.1 当前 Node SDK 的 `.d.ts` 不是 MoonBit contract truth source，而是发布 wrapper artifact

Node SDK 构建脚本：

文件：`integrations/sdk/node/scripts/build.mjs`

关键事实：

1. 先执行：

```js
run('moon', ['build', 'src/sdk/contracts', 'src/sdk/query', 'src/sdk/index', '--target', 'js', '--release'], repoRoot)
```

2. 然后从 `_build/js/release/build` 搬运 MoonBit 生成的 JS：

```js
stageMoonBitModule('sdk/contracts/contracts.js', 'contracts.js')
stageMoonBitModule('sdk/query/query.js', 'query.js')
stageMoonBitModule('sdk/index/index.js', 'index.js')
```

3. 再复制 Node 侧 wrapper 文件与 `.d.ts`：

```js
'types.d.ts',
'contracts.d.ts',
'index-api.d.ts',
'query.d.ts',
'index.d.ts',
```

这说明当前仓库里：

- MoonBit JS 输出是运行时实现来源；
- `.d.ts` 是 **Node wrapper 发布物的一部分**；
- `.d.ts` 不是系统契约唯一真相源。

## 3.2 当前 `.d.ts` 还是手写/包装层，不是自动从统一 schema 派生出来的稳定 contract

文件：`integrations/sdk/node/src/types.d.ts`

可以看到里面是手写的：

- `JsonPrimitive`
- `JsonObject`
- `DeclarationRecord`
- `SymbolRecord`
- `CiqQueryV1`
- `CiqResultV1`

例如：

```ts
export interface CiqQueryV1 extends JsonObject {
  schemaVersion: 'ciq-query/v1'
  purl: string
  selector: CiqQuerySelector
  repo?: string
  intent?: string
}
```

这说明当前 `.d.ts`：

- 是对 JSON contract 的 TS 视图；
- 但它本身并没有替代底层 schema；
- 它更像“消费层类型镜像”，而不是“规范层定义”。

## 3.3 当前 repo 的真实 contract 仍然显式依赖 schema / proto，而不是 `.d.ts`

### 证据 A：schema package 明确声明自己是 contract source of truth

文件：`src/schema/README.mbt.md`

原文：

```md
JSON-schema contracts and validators for CodeIQ bundle, diff, query, registry, and SARIF artifacts.
...
It centralizes artifact contracts so commands and tests can share one source of truth.
```

这已经写得非常明确：

> 当前仓库把 **schema** 当作 commands/tests 的 contract source of truth。

不是 `.d.ts`。

### 证据 B：MoonBit SDK contracts 暴露的是 schema 与 validate，不是 `.d.ts` 本身

文件：`src/sdk/contracts/main.mbt`

暴露函数包括：

- `ciq_bundle_v1_schema()`
- `ciq_query_v1_schema()`
- `ciq_result_v1_schema()`
- `validate_ciq_bundle_v1()`
- `validate_ciq_query_v1()`
- `validate_ciq_result_v1()`

以及 JSON 版本：

- `ciq_bundle_v1_schema_json()`
- `validate_ciq_bundle_v1_json()`

这说明 SDK 当前最核心的 contract surface 之一，是：

> **把 schema/validator 暴露给 JS/TS 使用。**

`.d.ts` 只描述 TS 看见的形状；它并不承担这些运行时验证职责。

### 证据 C：运行时和测试都依赖 schemaVersion + schema validation

文件：`src/sdk/query/main.mbt`

```mbt
pub fn validate_query_shape(query : Json, query_file : String) -> Result[Unit, String] {
  let out = @schema.validate_ciq_query_v1(query)
  ...
}
```

文件：`src/cmd/query/main_test.mbt`

```mbt
test "query fails when schemaVersion is invalid" {
  ...
  "schemaVersion": "ciq-query/v0",
  ...
  assert_true(text.contains("ciq-query/v1 schema"))
}
```

这证明当前系统关心的是：

- `schemaVersion` 是否合法
- 输入/输出 JSON 是否满足 schema

而不是“TS 编译器是否接受 `.d.ts`”。

## 3.4 proto 还承载 `.d.ts` 里没有的跨语言语义

文件：`proto/xaclabs/codeiq/v1/query.proto`

可见：

- `oneof kind`
- `bytes`
- `int64`
- `google.protobuf.Struct`
- `google.protobuf.NullValue`

例如：

```proto
message QueryValue {
  oneof kind {
    google.protobuf.NullValue null_value = 1;
    bool bool_value = 2;
    int64 int64_value = 3;
    double double_value = 4;
    string string_value = 5;
    bytes bytes_value = 6;
    google.protobuf.Struct json_value = 7;
  }
}
```

文件：`proto/xaclabs/codeiq/v1/bundle.proto`

```proto
message DeclarationSchema {
  string version = 1;
  string format = 2;
  string model = 3;
  google.protobuf.Struct schema = 4;
}
```

这些都说明 proto 承载的是：

- message 级结构定义
- protobuf 特有语义（field number / oneof / enum / wire/json）
- future cross-language generator 的输入

而 `.d.ts` 无法自然承担这些职责。

## 3.5 仓库已经显式把 proto 用于兼容性约束

文件：`buf.yaml`

```yaml
breaking:
  use:
    - WIRE_JSON
```

这代表当前 proto contract 已被纳入 Buf breaking policy，用于检查：

- wire 兼容性
- JSON 兼容性

而 `.d.ts` 没有等价机制去表达 protobuf field number、wire-safe / wire-unsafe change、JSON name 演进规则。

---

## 4. 外部证据

## 4.1 MoonBit 官方/社区现实：JS target 的 `.d.ts` 是正式产物，但仍是 TS 定向产物

MoonBit 侧的外部证据说明两件事：

1. JS target 生成 `.d.ts` 是正式支持能力，不是偶然副产物；
2. MoonBit 生态里更接近“权威接口文件”的其实是 `.mbti`，而 `.d.ts` 更像面向 JS/TS 的投影层。

### 证据 A：MoonBit JS target 默认生成 `.d.ts`

MoonBit 官方文章《MoonBit JS FFI》明确写到，JS 构建产物包含：

- `.js`
- `.js.map`
- `.d.ts`

并且 MoonBit 编译器源码中有 `emit_dts` 开关，以及 `-no-dts` 选项，说明 `.d.ts` emission 是编译器一等能力。

这证明：

> MoonBit 生成 `.d.ts` 这件事本身是真实、稳定、值得利用的。

### 证据 B：MoonBit 的接口真相源更接近 `.mbti`

MoonBit 文档与生态工具都显示：

- `moon info` 会生成 `.mbti`
- 社区工具 `mbts` 支持 `.mbti -> .d.ts`

也就是说，MoonBit 自己的接口抽象更偏向：

> MoonBit source -> `.mbti` -> `.d.ts`

这意味着 `.d.ts` 更接近**语言投影结果**，而不是跨语言 contract 本体。

### 小结

所以我们的判断不是“MoonBit `.d.ts` 不重要”，而是：

- 对 TS SDK 来说，MoonBit `.d.ts` 很重要；
- 但对跨语言 contract 来说，它仍然是 target-specific artifact。

## 4.2 TypeScript 官方：`.d.ts` 只有类型信息，不包含运行时实现

TypeScript 官方文档：

- https://www.typescriptlang.org/docs/handbook/2/type-declarations.html

核心结论：

> `.d.ts` files are declaration files that contain only type information.

也就是：

- `.d.ts` 用于 typechecking
- 不产生 `.js`
- 不提供运行时行为

这直接说明：

> `.d.ts` 可以服务 TS 静态体验，但不能单独承担运行时 contract / validation / compatibility source 的角色。

## 4.3 TypeScript 官方：`.d.ts` 的定位是“描述 JS 模块的形状”

TypeScript 文档：

- https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html
- https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html

它的核心语境是：

- 给 JS library 提供 TS 类型描述
- 作为 npm package 的 typing publishing artifact

这是一种**消费层声明文件**定位，而不是语言无关 schema 定义语言。

## 4.4 Protobuf 官方：proto 是 language-neutral / platform-neutral 的结构化数据契约

Protobuf 官方：

- https://protobuf.dev/overview/

核心定义：

> Protocol Buffers are a language-neutral, platform-neutral extensible mechanism for serializing structured data.

proto 的职责天然包括：

- 多语言共享
- 结构化序列化
- 代码生成输入
- schema evolution

这正是 `.d.ts` 做不到的部分。

## 4.5 Protobuf 官方实践：schema producer 应发布 `.proto`，而不是只发布 generated sources

Protobuf 官方关于 schema producer 的设计文档有一个非常关键的建议：

> 发布 `.proto` 文件，而不是只发布 generated sources。

原因也很直接：

- generated code 与 runtime/编译器版本可能漂移
- schema producer 应暴露语言中立的原始定义

这点和当前问题高度相关：

> 即便 MoonBit 能生成 `.d.ts`，官方 protobuf 生态仍然更鼓励把 `.proto` 作为发布与演进的锚点，而不是把某个 target 的生成物抬升成唯一 contract。

## 4.6 Google APIs 这类大规模实践：`.proto` 是多语言 SDK 的共同真相源

Google APIs 仓库长期把 `.proto` 作为公共接口定义，并用同一份 IDL 驱动：

- REST / RPC 接口定义
- 多语言客户端生成
- 文档与其它工件生成

这类案例最能说明问题：

- 当系统只服务 TS 用户时，`.d.ts` 很够用；
- 当系统要服务多语言消费者时，真正稳定的锚点仍然是语言中立 IDL，而不是某个语言 target 的声明文件。

## 4.7 Buf 官方：proto schema 可以做 breaking change detection

Buf 官方：

- https://buf.build/docs/breaking/
- https://buf.build/docs/breaking/rules/

Buf 明确把 schema 的 breaking 分成：

- `FILE`
- `PACKAGE`
- `WIRE_JSON`
- `WIRE`

特别是：

- generated source code breakage
- wire / JSON encoding breakage

这些能力都建立在 `.proto` schema 上，而不是 `.d.ts`。

## 4.8 MoonBit / 社区工具的现实更接近“`.d.ts` 是 JS/TS 辅助层”

在 MoonBit 社区工具里，`.d.ts` 常见定位是：

- 给 JS/TS 消费 MoonBit 导出时提供类型提示
- 或者把 `.mbti` / `.d.ts` 互转，用于 JS FFI bindings

参考：

- `mbts`：https://jsr.io/@mizchi/mbts
- `mizchi/js.mbt`：https://github.com/mizchi/js.mbt
- `mizchi/npm_typed.mbt`：https://github.com/mizchi/npm_typed.mbt

这些项目非常有价值，但它们解决的问题更偏向：

- JS/TS 与 MoonBit FFI 对接
- 让 MoonBit 在 JS 生态里拥有更好的类型体验

而不是“用 `.d.ts` 取代 protobuf 作为跨语言 contract”。

---

## 5. 从职责上拆解：`.d.ts` 能做什么，不能做什么

## 5.1 `.d.ts` 能做的

### A. 作为 TS SDK 发布产物

适合：

- npm 包对外 `types`
- IDE 补全与类型检查
- 减少手写 `types.d.ts`

### B. 描述 MoonBit 导出的 JS API 形状

适合：

- 函数签名
- struct/interface 形状
- option / union 的 TS 表达

### C. 作为“最后一公里”的 TS 体验层

适合：

- Node TypeScript 消费者
- VSCode / tsserver
- package 发布时的 developer experience

## 5.2 `.d.ts` 做不到或不适合做的

### A. 不能做语言无关 contract

`.d.ts` 是 TypeScript 世界里的声明文件。

它天然不适合直接服务：

- MoonBit
- Rust
- Go
- Python
- future non-TS consumers

### B. 不能表达 protobuf 演进规则

`.d.ts` 不知道：

- field number
- reserved number/name
- wire compatibility
- `json_name`
- unknown field behavior

因此不能替代 proto + Buf 的 breaking policy。

### C. 不能做运行时 schema validation

`.d.ts` 是 compile-time artifact。

它不能直接回答：

- 输入 JSON 是否满足 `ciq-query/v1`
- `schemaVersion` 是否合法
- 某个 registry response 是否缺少必填字段

而当前 repo 明确依赖这些能力。

### D. 不能成为多语言 codegen 的统一源

如果让 `.d.ts` 成为主真相源，会立即遇到两个问题：

1. MoonBit 端从哪里生成？
2. future 非 TS 语言从哪里生成？

这会把 contract 锚点锁死在 TS 生态里。

### E. 不能自然保留文档/注释/反射/协议元数据

即便 `.d.ts` 能保留部分注释，也不能自然承担：

- protoc / buf plugin input
- message/service descriptor
- future reflection / catalog / transport 元数据

---

## 6. 结合 CodeIQ 当前计划，最合理的定位是什么？

最合理的定位是：

> **proto 继续做 contract source of truth；MoonBit JS target 的 `.d.ts` 做 TS SDK 的消费层投影。**

也就是：

### proto 负责

- 用户侧 API message / rpc 定义
- 语言中立的数据模型
- Buf lint / breaking
- 多端 generator 输入
- 未来 binary / transport / doc tooling 的锚点

### MoonBit-generated `.d.ts` 负责

- TS 用户看到的最终类型提示
- MoonBit JS export 的 npm 消费体验
- 替代当前 Node SDK 大量手写 `.d.ts`

### JSON schema / validators 负责

- 当前 repo 仍然存在的运行时 JSON contract 校验
- `schemaVersion` 错误检测
- 本地 CLI / SDK 输入输出 validation

这三者不是互斥关系，而是三层：

1. **proto**：上层语言中立 contract
2. **schema/validator**：当前运行时验证层
3. **MoonBit `.d.ts`**：TS 消费层类型投影

补充一点：

- 如果未来我们决定让 Node SDK 尽量直接消费 MoonBit JS target 的 `.d.ts`，这依然是一个**非常值得做**的优化；
- 但这个优化的目标应该是“减少手写 TS 类型层”，而不是“替换 proto 作为 contract truth source”。

---

## 7. 对原问题的最终回答

## 7.1 简答版

**不能完全代替。**

MoonBit 导出的 `.d.ts` 可以大幅替代 **TS SDK 手写类型包装**，但不能替代 proto 作为：

- 语言中立 contract
- compatibility / evolution 基线
- code generation input
- runtime schema/serialization 语义锚点

## 7.2 更精确的工程建议

推荐采用下面的职责分层：

### 建议方案

1. **保留 proto 作为唯一 contract truth source**
2. 用 `codeiq-proto-gen` 从 proto 生成：
   - MoonBit 数据类型
   - Node TS 数据类型
3. 再让 MoonBit JS target 自动产出的 `.d.ts`，或由生成器输出的 TS declarations，作为 npm SDK 最终对外类型层
4. 若未来 MoonBit 官方 `.d.ts` 质量足够高，可以优先复用它来替代手写 wrapper `.d.ts`，但仍不改变 proto 的真相源地位

### 不建议方案

不建议把：

> “MoonBit JS target 的 `.d.ts`”

直接升级为整个系统唯一 contract 源。

因为那会导致：

- contract 被 TypeScript 生态绑死
- 丢失 Buf/proto 的 breaking / evolution 能力
- 丢失语言无关描述能力
- 运行时 validation 仍需额外 schema，最终反而出现“双份真相源”

---

## 8. 最终结论

最终判断是：

> **MoonBit JS target 所附带的 `.d.ts` 不能完全代替 proto 在本方案中的定位。**

最优实践不是“二选一”，而是：

- **proto** 负责 contract
- **MoonBit-generated `.d.ts`** 负责 TS SDK DX

如果只看 TS SDK 这一层，`.d.ts` 很有希望替代当前大量手写类型；
但如果看整个系统的 contract/source-of-truth 设计，proto 仍然不可替代。

---

## 9. 参考资料

### 仓库内证据

- `integrations/sdk/node/scripts/build.mjs`
- `integrations/sdk/node/src/types.d.ts`
- `integrations/sdk/node/src/index.d.ts`
- `integrations/sdk/node/README.md`
- `src/sdk/contracts/main.mbt`
- `src/sdk/query/main.mbt`
- `src/schema/README.mbt.md`
- `src/schema/contracts.mbt`
- `src/cmd/query/main_test.mbt`
- `proto/xaclabs/codeiq/v1/bundle.proto`
- `proto/xaclabs/codeiq/v1/query.proto`
- `buf.yaml`

### 外部参考

- MoonBit JS FFI（说明 JS target 会生成 `.d.ts`）
  - https://www.moonbitlang.com/pearls/moonbit-jsffi
- MoonBit compiler `emit_dts` 配置
  - https://github.com/moonbitlang/moonbit-compiler/blob/d4ada10d212b5376f7f8bf49cd2fbaa275a395df/src/driver_config.ml
- MoonBit `moon info` / `.mbti` 文档
  - https://github.com/moonbitlang/moonbit-docs/blob/main/next/toolchain/moon/commands.md
- TypeScript Type Declarations
  - https://www.typescriptlang.org/docs/handbook/2/type-declarations.html
- TypeScript Declaration Files Introduction
  - https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html
- TypeScript Publishing Declaration Files
  - https://www.typescriptlang.org/docs/handbook/declaration-files/publishing.html
- Protocol Buffers Overview
  - https://protobuf.dev/overview/
- Protocol Buffers schema producer guidance（发布 `.proto`，而不是只发布 generated sources）
  - https://github.com/protocolbuffers/protobuf/blob/f32e44132022b85189b167df4f91e6d1302262e1/docs/design/editions/protobuf-editions-for-schema-producers.md
- Google APIs repository（`.proto` 作为多语言接口定义）
  - https://github.com/googleapis/googleapis/blob/2193a2bfcecb92b92aad7a4d81baa428cafd7dfd/README.md
- Protocol Buffers Overview (Google)
  - https://developers.google.com/protocol-buffers/docs/overview
- Buf Breaking Change Detection
  - https://buf.build/docs/breaking/
- Buf Breaking Rules
  - https://buf.build/docs/breaking/rules/
- MoonBit / community `.d.ts` / `.mbti` tooling参考
  - https://jsr.io/@mizchi/mbts
  - https://github.com/mizchi/js.mbt
  - https://github.com/mizchi/npm_typed.mbt
