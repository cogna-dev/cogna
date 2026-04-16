# Proto / Policy Review Notes

## 2026-04-15

- `common.proto` 已按当前 review 改为 `bundle.proto`，并把只在单一接口语义下成立的结构移回对应接口文件，避免共享文件继续膨胀成杂项容器。
- `policy bundle` 不再作为对外 proto contract 的一部分；Bundle 现在只表示普通源码/规格 bundle，不再承载 `ciq-opa-bundle/v1`、`opa-bundle.tar.gz` 或 `policy.rules.json`。
- 后续 policy 架构目标：`check` 只从当前仓库代码读取 policy 实现与规则元数据，不再把 policy 打包、上传或发布到 bundle 中。
- 这意味着后续实现需要继续把当前代码中的 `profile: policy-bundle`、`ciq-opa-bundle/v1`、`opa-bundle.tar.gz`、`policy.rules.json`、相关 schema/test/docs 逐步迁出或降级为内部实现细节，而不是继续作为公开产物 contract。
