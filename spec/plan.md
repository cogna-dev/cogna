# Local-first 主流程收口计划（2026-04-19）

本文是当前阶段唯一有效的执行计划，目标只有四件事：

1. 收口 `init -> build -> diff -> check` 主流程；
2. 明确 policy 只属于 `init/check`，不进入 extractor / build / diff；
3. 以本地 workspace 与本地 e2e 为当前验收基线；
4. 删除旧进度页面与所有过期叙事，避免后续继续被旧设计误导。

---

## 1. 当前阶段的边界

### 1.1 只做 local-first

当前主产品边界是：

- 当前工作目录 `.`；
- `cogna.yml`；
- `.cogna/`；
- `dist/`；
- 本机已安装好的工具与本地文件系统。

当前阶段不把 remote cache、remote package source、remote repo acceptance 当成完成标准。

### 1.2 policy 不属于 extractor / build / diff

policy 的正确职责是：

- `init`：把内置 policy materialize 到当前项目的 `./.cogna/policies/`；
- `check`：把 `checks.policy` 指向的目录直接传给 `opa eval --bundle ...`；
- docs：把 policy 说明成 check 输入，而不是一种 build profile。

明确禁止：

- 把 Rego 当 extractor 输入抽 declaration；
- 把 policy 当 `build` / `diff` 主流程的一种 profile；
- 继续扩写“未来会有 `src/extractors/policy`”之类表述。

### 1.3 remote e2e 先跳过

当前阶段 remote e2e：

- 保留现有 env gate；
- 默认不执行；
- 不作为当前阶段完成标准；
- 只在矩阵里记录为 deferred / skipped。

当前验收只看：

- 本地命令主流程；
- 本地 extractor e2e；
- 相关单元测试与构建验证。

---

## 2. 当前真实工作流

### 2.1 `cogna init`

职责：

1. 生成 `cogna.yml`；
2. 写入默认 `checks.policy: ./.cogna/policies`；
3. 将内置 policy 复制到 `./.cogna/policies/compat.rego`。

完成后，用户无需再构建单独的 policy bundle 仓库。

### 2.2 `cogna build`

职责：

- 读取当前 repo 的源码 / 规格文件；
- 提取 declarations；
- 生成 `dist/manifest.json`、`dist/declarations.ndjson`、`dist/metadata.json`、`dist/checksums.txt`、`dist/bundle.ciq.tgz`；
- 生成当前 workspace 的 `.cogna/sbom.spdx.json`。

明确不做：

- policy bundle 生成；
- OPA bundle 生成；
- policy catalog 产物生成。

### 2.3 `cogna diff`

职责：

- 对比 `dist/base` 与 `dist/target`；
- 生成 `dist/diff.json`。

明确不做：

- policy 输入解析；
- policy bundle 消费；
- policy declaration extraction。

### 2.4 `cogna check`

职责：

- 读取 `dist/diff.json`；
- 读取 `checks.policy` 指向的 policy 目录；
- 调用 `opa eval --bundle <policy-dir> --input <diff-input>`；
- 输出 `dist/check.sarif.json`。

---

## 3. 文档真相源调整

### 3.1 删除旧进度页面

当前阶段不再维护旧进度页面。

必须执行：

- 删除用户文档与贡献者文档中的旧进度页面源文件；
- 删除 README、导航、spec 中对旧进度页面的引用；
- 不再使用“唯一进度真相源”这类表述。

### 3.2 policy 文档叙事改写

后续所有文档必须统一成下面的说法：

- 支持的代码/规格 profile 只有：Go / Rust / Terraform / OpenAPI；
- policy 是 check 的输入目录，不是 profile；
- 内置 policy 会在 `init` 时 materialize 到 `.cogna/policies`；
- 自定义 policy 的方式是编辑该目录下的 `.rego` 文件。

---

## 4. 当前阶段任务分解

### Phase A — truth reset

必做：

1. 重写 `spec/plan.md`；
2. 重写 `spec/todo.md`；
3. 修正 `spec/compitable.md`；
4. 删除 progress 页面与引用；
5. 清除把 policy 当主流程制品的旧叙事。

完成标准：

- `spec/` 与 `docs/` 中不再出现 progress 真相源叙事；
- `spec/` 与 `docs/` 中不再把 policy 写成 build/extractor profile。

### Phase B — command behavior alignment

必做：

1. `init` materialize `.cogna/policies`；
2. `check` 直接消费 policy 目录；
3. 删除 build/extractor 中的 policy 特判；
4. 收紧 config profile 枚举，只保留当前四类代码/规格 profile。

完成标准：

- 新生成配置默认指向 `./.cogna/policies`；
- build 不再产出 `opa-bundle.tar.gz` / `policy.rules.json`；
- extractor 不再处理 `.rego`。

### Phase C — local e2e stabilization

必做：

1. 保持 `src/e2e/extractors/*` 默认在本地 case 下可执行；
2. 将 remote case 继续保留为 env-gated skip；
3. 以 local example snapshots 作为当前验收证据。

完成标准：

- 本地 e2e 在默认环境下可跑；
- remote e2e 不影响当前阶段通过判定。

---

## 5. 当前阶段不做什么

以下内容全部明确延后：

- remote e2e 扩容；
- git remote acceptance 收口；
- cargo 大体量 package remote acceptance 常态化；
- 再次扩写 cache-first / registry / desktop 大计划；
- 任何新的 policy extractor 设计。

---

## 6. 受影响文件

### 必改 spec/docs

- `spec/plan.md`
- `spec/compitable.md`
- `spec/todo.md`
- `spec/desktop.md`
- `spec/proposal.typ`
- `README.md`
- `docs/src/lib/navigation.ts`
- `docs/src/content/docs/{introduction,quickstart,build-indexes,cli,config,indexing,providers}.mdx`
- `docs/src/content/contrib/introduction.mdx`

### 必改命令/配置代码

- `src/cmd/init/{config,fs,main}.mbt`
- `src/cmd/check/main.mbt`
- `src/cmd/build/{extractor,local_index,pipeline}.mbt`
- `src/core/config/{defaults,validate}.mbt`

### 必审测试

- `src/cmd/build/main_test.mbt`
- `src/cmd/check/main_test.mbt`
- `src/core/bundle/reader_test.mbt`
- `src/sdk/sdk_test.mbt`
- `src/cmd/build/snapshot_test.mbt`

---

## 7. 验证要求

至少完成：

```bash
moon check --target native src/cmd/init src/cmd/check src/cmd/build src/core/config
moon test --target native src/cmd/init src/cmd/check src/cmd/build
moon test --target native src/e2e/extractors
moon build --target native
```

并补充文本验证：

- 旧进度页面源文件已删除；
- README / 导航 / docs / spec 不再引用旧进度页面；
- docs/spec 只把 policy 描述为 `init/check` 使用的目录；
- code 不再把 policy 当 extractor/build profile；
- remote e2e 只保留 skip/deferred 说明。

---

## 8. 一句话摘要

当前阶段只做一件事：把 Cogna 收口成一个可靠的 local-first `init -> build -> diff -> check` 工具，其中 policy 只在 `init/check` 出现，本地 e2e 是当前唯一主验收线，所有旧进度页与旧策略 profile 的过期叙事全部删除。
