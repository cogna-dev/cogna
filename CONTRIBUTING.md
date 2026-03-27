# Contributing to CodeIQ

This file is the repository-level entrypoint for contributors.

## Read first

- User docs: `docs/src/content/docs/*`
- Contributor docs: `docs/src/content/contrib/*`
- Public landing: `README.md`

## Common commands

### Main workspace

```bash
moon check
moon test
```

### Docs site

```bash
cd docs
pnpm dev
pnpm build
```

## Documentation split

- User docs should stay usage-first and avoid internal implementation details.
- Contributor docs should contain architecture boundaries, planning notes, proposal reconciliation, and maintenance guidance.
- Keep `README.md` concise and link outward instead of embedding internal design rationale.

## Current docs IA

- Top navigation: 快速开始 / 用户文档 / 贡献者文档 / 开发进度 / GitHub
- User docs: organized by Tutorials / How-to / Reference / Explanation
- Contributor docs: architecture, progress, maintenance guidance
