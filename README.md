<div align="center">

<pre>
  ____          _      ___ ____
 / ___|___   __| | ___|_ _/ ___|
| |   / _ \ / _` |/ _ \| | |  _
| |__| (_) | (_| |  __/| | |_| |
 \____\___/ \__,_|\___|___\____|
</pre>

# CodeIQ

![Build](https://img.shields.io/github/actions/workflow/status/yufeiminds/codeiq/ci.yml?branch=main&label=build)
![Coverage](https://img.shields.io/codecov/c/github/yufeiminds/codeiq?label=coverage)
![MoonBit](https://img.shields.io/badge/language-MoonBit-6f42c1)

</div>

CodeIQ is a declaration-focused CLI for API and third-party dependency governance.
It extracts interface contracts, computes diffs, and prepares structured artifacts for policy checks and downstream automation.

Current product scope is single-machine only: CLI, Local Registry, and MCP share one local bundle store, and bundles now include declaration facts plus SBOM artifacts.

## Project Scope

- Focus on public declarations and contracts rather than implementation-level linting.
- Provide a unified workflow for `init`, `build`, `diff`, `check`, `query`, and `publish`.
- Keep CLI entry thin and route command logic to cohesive modules under `src/`.

## Current Highlights

- **Init command available**: `init` generates baseline CIQ config metadata.
- **Modular layout**: command modules are organized by directory for cohesion.
- **In-process testability**: command entry functions are callable from e2e tests.
- **Shared CLI framework**: `src/cli` now provides common result, logging, and error handling.
- **Shared config module**: `src/config` now provides typed config defaults, loading, and validation.
- **Shared utilities**: `src/utils` now provides archive-like payload helpers and checksum helpers.

## Workflow Overview

Typical flow: `init -> build -> diff -> check -> query/publish`.

For full product documentation and roadmap details, visit:

👉 https://codeiq.xaclabs.dev
