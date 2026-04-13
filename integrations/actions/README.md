# CodeIQ GitHub Actions

This repository ships three local composite actions:

- `./integrations/actions/setup-moonbit`
- `./integrations/actions/setup-codeiq`
- `./integrations/actions/run-codeiq`

## Local e2e verification with act

```bash
act workflow_dispatch -W .github/workflows/actions-e2e.yml --container-architecture linux/amd64
```

`run-codeiq` prepares the same SARIF payload for both environments. On GitHub runners it uploads that payload through the Code Scanning REST API; when `ACT=true`, it captures the payload to a local file instead so local `act` runs remain deterministic.
