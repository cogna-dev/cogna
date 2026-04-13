# e2e package

End-to-end coverage for the local CodeIQ workflow.

This package intentionally exercises the user-facing command loop and local runtime slices:

- `init -> build -> diff -> check -> query -> publish`
- local registry flows and localhost registry server flows
- extractor parity and benchmark smoke coverage
- shell/runtime adapters used only by e2e tests

Fixture snapshots under `examples/*/snapshots/codeiq/*` are canonical test baselines, not disposable generated noise.

Native-only shell and localhost registry flows now live under `src/e2e/native/`,
while portable e2e coverage stays in the top-level `src/e2e/` package.
