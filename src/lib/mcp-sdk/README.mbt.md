# mcp-sdk library

Reusable JSON-RPC and stdio helpers for building MCP-compatible MoonBit packages.

This package intentionally contains **generic** capabilities only:

- Request routing (`route_request`, `MethodContext`)
- Standard response helpers (`success_response`, `error_response`, `call_result`)
- Stdio request handling (`serve_stdio_once`, `run_stdio_repl`, `stdio_output_lines`)
- Tool-state and runtime helpers (`sync_tools_state`, `RequestContext`, deadline / cancellation helpers)

CodeIQ-specific tool wiring should stay in the owning MCP package.

## Example

```mbt check
///|
test "mcp-sdk routes a JSON-RPC request" {
  let request : Json = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "demo.echo",
    "params": { "message": "hello" },
  }
  let response = route_request(request, fn(ctx) {
    success_response(ctx.id, {
      "method": ctx.method_name,
      "ok": true,
    })
  }).stringify(indent=2)
  assert_true(response.contains("\"demo.echo\""))
  assert_true(response.contains("\"ok\": true"))
}
```
