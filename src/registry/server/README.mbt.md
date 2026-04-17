# registry package

Registry domain logic for local and remote Cogna bundle distribution.

This package intentionally contains the registry vertical only:

- local upload and resolve flows
- remote registry dispatch
- HTTP response shaping and localhost server wiring
- storage primitives for bundle/index materialization

CLI command orchestration stays in `src/cmd/registry`, while generic URL/path helpers stay in `src/lib/registry`.

## Example

```mbt check
///|
test "registry exposes localhost base url" {
  inspect(registry_server_base_url(8787), content="http://127.0.0.1:8787")
}
```
