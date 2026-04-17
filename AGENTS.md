# Architecture Constraints (must be extremely concise)

- Keep implementation code under `src/`.
- Keep all command implementations under `src/cmd/*`.
- Keep `src/cmd/main/main.mbt` as thin entry + dispatch.
- Keep e2e tests under `src/e2e/*`.

# cogna-dev Library Rules

## HTTP Server Development
- **Always use `cogna-dev/mapi/lib` for HTTP server logic** — routes, handlers, middleware, request/response envelopes.
- **Always derive the server from `openapi.json`** — run `mapi generate` to regenerate the `generated/` layer; implement handlers in a separate `handlers/` package that mapi never overwrites.
- **Never use `moonbitlang/async` (or any native async package) directly** for HTTP server code. The `cogna-dev/mapi/lib` runtime is zero-I/O; adapt it to the host only at the outermost boundary (e.g. `moonbitlang/async/http` server bootstrap in `main.mbt`), and keep all business logic inside mapi handlers.
- HTTP handler signatures: `fn(ctx : @lib.RequestContext, input : SomeInput) -> Result[SomeResponse, @lib.AppError]`.
- Wire handlers to app via the generated `make_app(api_handlers)` call, not manual route registration.

## cogna-dev Packages in this project (`moon.mod.json` deps)

| Package | Purpose | Import alias |
|---------|---------|-------------|
| `cogna-dev/mapi/lib` | HTTP framework — App, Router, RequestEnvelope, ResponseEnvelope, middleware | `@lib` |
| `cogna-dev/x` | General utilities for cogna | `@x` |
| `cogna-dev/parkit` | Package registry / workspace tooling | `@parkit` |
| `cogna-dev/sbom` | SBOM generation and parsing | `@sbom` |
| `cogna-dev/mcp-sdk` | MCP (Model Context Protocol) SDK | `@mcp_sdk` |

## Key mapi types (quick reference)
```
@lib.HttpMethod       – Get | Post | Put | Patch | Delete | Head | Options
@lib.RequestEnvelope  – { http_method, path, query, headers, body: Bytes? }
@lib.ResponseEnvelope – { status: Int, headers, body: Bytes? }
@lib.RequestContext   – { request_id, matched_operation }
@lib.AppError         – NotFound | BadRequest | Unauthorized | Forbidden | Internal
@lib.App              – App::new(router) · app.serve(req) · app.use_middleware(m)
@lib.Router           – Router::new() · router.add(route) · router.dispatch(req)
@lib.InMemoryHost     – for unit-testing handlers without a real HTTP server
```

# Style Rules (must be extremely concise)

- Keep module cohesion: when a feature has only a few related functions, keep them in one file instead of splitting one function per file.
- Keep import naming concise: package exports should avoid redundant package-name prefixes (prefer `@cli.Error` over `@cli.CliError`).
- Use minimal naming: avoid repeating directory/context words in file and symbol names (e.g. `src/e2e/init_test.mbt`, not `init_e2e_test.mbt`).
- Never modify system-level configuration; changes must stay within the current project directory or `/tmp`.
- Never commit temporary files or auto-generated files; only commit intentional source/docs/test artifacts.
- After every development cycle, update the progress dashboard at `docs/src/content/docs/progress.mdx` before reporting completion.
- In `docs/src/content/docs/progress.mdx`, detailed execution checklist sections must keep only the current active stage; completed or future stages should be summary-only.
