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
It helps you build package snapshots, compare versions, run policy checks, and query APIs from one machine.

Current scope is local-only: CLI, Local Registry, and MCP share one local bundle store.

## What you can do with CodeIQ

- Build a reusable bundle for a repo or spec
- Compare versions before release
- Run policy checks and export SARIF
- Query APIs and dependencies from CLI or MCP

## Typical flow

```text
init -> build -> diff -> check -> query -> publish
```

## Links

- User docs: https://codeiq.xaclabs.dev/docs
- User docs: https://codeiq.xaclabs.dev/docs/introduction
- Quickstart: https://codeiq.xaclabs.dev/docs/quickstart
- Contributor docs: https://codeiq.xaclabs.dev/contrib/introduction
- Progress: https://codeiq.xaclabs.dev/docs/progress
- Repo contributing guide: [`CONTRIBUTING.md`](./CONTRIBUTING.md)

For the full docs site, visit:

👉 https://codeiq.xaclabs.dev
