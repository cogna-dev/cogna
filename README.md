<div align="center">
  
# Cogna

![Build](https://img.shields.io/github/actions/workflow/status/cogna-dev/cogna/ci.yml?branch=main&label=build)
![Coverage](https://img.shields.io/codecov/c/github/cogna-dev/cogna?label=coverage)
![MoonBit](https://img.shields.io/badge/language-MoonBit-6f42c1)

</div>

> IMPORTANT: We are currently focusing on [ParKit: The Parser Toolkit via MoonBit](https://github.com/cogna-dev/parkit) and [AnaKit: The analysis engine on Code Property Graph](https://github.com/cogna-dev/anakit). Therefore, this application has been archived until we complete the infrastructure for code parsing and analysis.

Cogna is a declaration-focused CLI for API and third-party dependency governance.
It helps you build package snapshots, compare versions, run policy checks, and query APIs from one machine.

Current scope is local-first: CLI, local cache, cache proxy, and MCP share one workspace-centered bundle store.

## What you can do with Cogna

- Build a reusable bundle for a repo or spec
- Compare versions before release
- Run policy checks and export SARIF
- Query APIs and dependencies from SDK / Desktop / MCP

## Typical flow

```text
init -> build -> diff -> check
```

## Links

- User docs: https://cogna.xaclabs.dev/docs
- User docs: https://cogna.xaclabs.dev/docs/introduction
- Quickstart: https://cogna.xaclabs.dev/docs/quickstart
- Contributor docs: https://cogna.xaclabs.dev/contrib/introduction
- Repo contributing guide: [`CONTRIBUTING.md`](./CONTRIBUTING.md)

For the full docs site, visit:

👉 https://cogna.xaclabs.dev
