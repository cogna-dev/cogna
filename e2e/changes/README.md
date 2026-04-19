# Changes E2E Fixtures

This directory contains end-to-end change fixtures for compatibility analysis.

Each ecosystem case uses the same structure:

- `old/`: base bundle artifacts (`manifest.json`, `declarations.ndjson`)
- `new/`: target bundle artifacts (`manifest.json`, `declarations.ndjson`)
- `expected/diff/diff.json`: normalized diff snapshot
- `expected/sarif/check.sarif.json`: normalized SARIF snapshot

## Cases

- `go`
- `rust`
- `terraform`
- `openapi`

## Run

From repository root:

```bash
./scripts/ci/run-changes-e2e.sh
```

Refresh snapshots:

```bash
./scripts/ci/run-changes-e2e.sh --update
```

Run a single case:

```bash
./scripts/ci/run-changes-e2e.sh --case go
```
