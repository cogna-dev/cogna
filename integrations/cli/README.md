# CodeIQ CLI integration entrypoints

This directory contains integration-facing wrappers for the repository CLI.

- `install.sh` / `install.ps1` install the `src/cmd/main` MoonBit package and expose it as `codeiq`
- `run.sh` runs the in-repo CLI through `moon run` while keeping the canonical implementation under `src/`

The actual MoonBit command parsing and dispatch remain in `src/cmd/main`.
