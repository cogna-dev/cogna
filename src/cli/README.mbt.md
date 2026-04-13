# cli package

Shared CLI-facing presentation and error helpers for CodeIQ commands.

This package intentionally contains:

- the ASCII banner
- terminal logger helpers
- shared CLI error constructors
- display/result helpers for command return types

Command parsing and dispatch stay in `src/cmd/main`.

## Example

```mbt check
///|
test "cli banner contains the project name" {
  assert_true(!banner().is_empty())
}
```
