# Architecture Constraints (must be extremely concise)

- Keep implementation code under `src/`.
- Keep all command implementations under `src/cmd/*`.
- Keep `src/cmd/main/main.mbt` as thin entry + dispatch.
- Keep e2e tests under `src/e2e/*`.

# Style Rules (must be extremely concise)

- Keep module cohesion: when a feature has only a few related functions, keep them in one file instead of splitting one function per file.
- Keep import naming concise: package exports should avoid redundant package-name prefixes (prefer `@cli.Error` over `@cli.CliError`).
- Use minimal naming: avoid repeating directory/context words in file and symbol names (e.g. `src/e2e/init_test.mbt`, not `init_e2e_test.mbt`).
- Never commit temporary files or auto-generated files; only commit intentional source/docs/test artifacts.
- After every development cycle, update the progress dashboard at `docs/src/content/docs/progress.mdx` before reporting completion.
