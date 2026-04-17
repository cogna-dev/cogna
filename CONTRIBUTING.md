# Contributing to Cogna

This file is the repository-level entrypoint for contributors.

## Read first

- User docs: `docs/src/content/docs/*`
- Contributor docs: `docs/src/content/contrib/*`
- Public landing: `README.md`

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [MoonBit](https://www.moonbitlang.com) | Language toolchain | `curl -fsSL https://cli.moonbitlang.com/install/unix.sh \| bash` |
| [just](https://github.com/casey/just) | Task runner | `brew install just` / `cargo install just` |
| [act](https://github.com/nektos/act) _(optional)_ | Run GitHub Actions locally | `brew install act` |

After installing MoonBit, fetch dependencies:

```sh
moon update
```

## Quick start

```sh
just ci          # lint + format-check + unit tests + CLI build (mirrors GitHub CI)
just install-cli # install cogna to ~/.moon/bin
cogna --help
```

## Capability matrix

| Recipe | What it does | Depends on |
|--------|-------------|------------|
| `build-cli` | Compile native CLI binary (`moon build`) | — |
| `build-sdk` | Compile JS/Wasm SDK (`moon build --target js`) | — |
| `build-all` | Compile CLI + SDK | `build-cli`, `build-sdk` |
| `test-unit` | Unit tests (`moon test`) | — |
| `test-e2e` | End-to-end integration tests (`moon test src/e2e`) | — |
| `test-all` | All tests | `test-unit`, `test-e2e` |
| `check-lint` | Type-check and static analysis (`moon check`) | — |
| `check-format` | Verify formatting without changes (`moon fmt --check`) | — |
| `check-version` | Verify git tag matches `moon.mod.json` version | — |
| `check-publish` | Dry-run SDK publish (`moon publish --dry-run`) | — |
| `check-all` | All pre-release gates | `check-lint`, `check-format` |
| `check-sdk` | Typecheck + lint JS SDK (`@cogna-dev/sdk`) | — |
| `fmt` | Format source files in-place (`moon fmt`) | — |
| `fmt-sdk` | Format JS SDK source files (biome) | — |
| `install-cli` | Install `cogna` binary to local bin | `build-cli` |
| `install-vscode` | Build and install the VSCode extension | — |
| `run [ARGS...]` | Run cogna in-repo without installing | — |
| `gen-proto` | Regenerate protobuf bindings (requires `go`, `buf`) | — |
| `gen-openapi` | Regenerate API stubs from `openapi.json` (mapi ≥ 0.1.1) | — |
| `test-sdk` | Run JS SDK tests (vitest) | — |
| `release-dry` | Dry-run SDK publish to mooncakes.io | — |
| `clean` | Remove all build artifacts (`moon clean`) | — |
| `ci` | Full CI gate (mirrors GitHub Actions) | `check-lint`, `check-format`, `test-unit`, `build-cli`, `check-sdk` |
| `act-e2e` | Run Actions E2E locally via act + Docker | — |

## Dependency graph

```
ci ── check-lint
  └─ check-format
  └─ test-unit
  └─ build-cli
  └─ check-sdk

build-all ── build-cli
          └─ build-sdk

test-all ── test-unit
         └─ test-e2e

check-all ── check-lint
          └─ check-format

install-cli ── build-cli
```

## Development workflow

```sh
# Day-to-day: format and check
just fmt
just check-lint

# Before opening a PR
just ci

# Run a specific test package
moon test src/cmd/build

# Install locally and smoke-test
just install-cli
cogna init --output /tmp/smoke.yml
```

## Release workflow

Releases are triggered by pushing a semver tag. The tag must exactly match the `version` field in `moon.mod.json`.

```sh
# 1. Bump version in moon.mod.json
# 2. Verify everything passes
just check-all
just test-unit

# 3. Confirm the publish dry-run is clean
just release-dry

# 4. Tag and push — GitHub Actions handles the rest
git tag v0.2.0
git push origin v0.2.0
```

GitHub Actions (`release.yml`) will:

1. Run pre-release checks (lint, tests, version consistency, publish dry-run)
2. Build the native CLI on 5 platform runners in parallel:
   - `x86_64-linux`, `aarch64-linux`
   - `x86_64-macos`, `aarch64-macos`
   - `x86_64-windows`
3. Create a GitHub Release and attach all platform archives as download assets
4. Publish the SDK to [mooncakes.io](https://mooncakes.io) (requires `MOONCAKES_TOKEN` repository secret)

### Required secrets

| Secret | Where to get it |
|--------|-----------------|
| `MOONCAKES_TOKEN` | [mooncakes.io](https://mooncakes.io) → Account Settings → API Tokens |

## Docs commands

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

## Code conventions

- Keep implementation under `src/`; keep command implementations under `src/cmd/*`
- Keep `src/cmd/main/main.mbt` as a thin entry + dispatch only
- Keep module cohesion: related functions in one file rather than one function per file
- Avoid redundant package-name prefixes in exports (`@cli.Error` not `@cli.CliError`)

## Running the Actions E2E locally

Requires [act](https://github.com/nektos/act) and Docker:

```sh
just act-e2e
```
