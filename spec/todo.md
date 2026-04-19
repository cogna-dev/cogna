# 当前收尾待办（2026-04-19）

本文只记录当前阶段仍值得继续收尾的事项；主流程改造、旧进度页面删除与本地 e2e 验收线收口已经完成。

---

## P0 — 归档文档防歧义

### 1. 历史申报书仍保留大量归档术语

**现象**

- `spec/proposal.typ` 是历史申报材料，内部仍保留当时的 registry / CIQ OPA Bundle 扩展叙事；
- 如果没有醒目标记，后续搜索时仍可能把它误当成当前事实来源。

**完成标准**

- 归档声明明确说明当前事实来源；
- 关键章节补充“仅作历史归档，不代表当前实现”的提示；
- 当前实现仍以 `spec/plan.md` 与 `docs/src/content/docs/*` 为准。

---

## P1 — 生成产物同步

### 2. Node SDK runtime 必须与当前 MoonBit 源同步

**现象**

- `dist/runtime/*` 与 `integrations/sdk/node/src/runtime/*` 属于生成产物；
- 只要 config default 或 profile 枚举变化，就必须重新生成，避免旧逻辑残留。

**完成标准**

- repo 根的 `dist/runtime/*` 与 Node SDK 的 `src/runtime/*` 已重新生成；
- 生成产物中的默认 policy 目录与当前实现一致；
- 不再残留旧策略 profile 分支。

---

## P2 — 最终收口验证

### 3. 当前阶段只保留本地验收证据

**现象**

- 当前实现已经回到 local-first 主流程，但仍需要一组明确、可重复的收口证据，避免后续回退。

**完成标准**

- 本地 tests / build / docs build 全部通过；
- remote e2e 仍保持 env-gated skip，不作为当前阶段门槛；
- 关键 spec/docs/code 搜索结果与当前主流程一致。

---

## 建议执行顺序

1. 先给历史归档补足防歧义提示；
2. 再确认生成产物与当前 MoonBit 源一致；
3. 最后跑本地 tests / build / docs build 作为收口证据。
