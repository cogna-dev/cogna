///|
test "mcp core initialize exposes protocol version" {
  let request : Json = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {},
  }
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"protocolVersion\": \"2025-11-25\""))
  assert_true(response.contains("\"codeiq-mcp\""))
}

///|
test "mcp core stdio once returns parse error" {
  let response = serve_stdio_once("{")
  assert_true(response.contains("-32700"))
}
