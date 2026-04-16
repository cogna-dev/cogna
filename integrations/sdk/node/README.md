# @codeiq/sdk

Node package wrapper for the CodeIQ MoonBit SDK surface.

## Scope

- local schema validation
- local index build/load
- local query execution

This package does not include CLI-only features such as diff, registry, publish, MCP, or host-assisted LSP validation.

## Build

```bash
pnpm --filter @codeiq/sdk build
```

The build script compiles MoonBit SDK packages for the JS backend, compiles generated proto TypeScript modules, and stages publishable files under `dist/`.

Generated proto DTOs and JSON helpers are published from the `@codeiq/sdk/generated` subpath.
