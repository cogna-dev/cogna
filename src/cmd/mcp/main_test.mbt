///|
fn remove_file_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn cleanup_tmp_dir(dir : String) -> Unit {
  remove_file_if_exists("\{dir}/dist/mcp-server.json")
  remove_dir_if_exists("\{dir}/dist")
  remove_dir_if_exists(dir)
}

///|
test "mcp start writes server descriptor" {
  let dir = "src/cmd/mcp/tmp_mcp_start"
  cleanup_tmp_dir(dir)
  @fs.create_dir(dir)

  let result = run_start({ port: 8080 })
  guard result is Ok(ok) else {
    cleanup_tmp_dir(dir)
    fail("mcp start should succeed")
  }
  inspect(
    ok.display(),
    content="Generated MCP server descriptor at ./dist/mcp-server.json (port 8080)",
  )

  let content = @fs.read_file_to_string("./dist/mcp-server.json") catch {
    _ => {
      cleanup_tmp_dir(dir)
      fail("mcp descriptor should exist")
      ""
    }
  }
  assert_true(content.contains("\"name\": \"codeiq-mcp\""))
  assert_true(content.contains("\"protocolVersion\": \"2025-11-25\""))
  assert_true(content.contains("\"initializeResult\""))
  assert_true(content.contains("\"codeiq.query.outlines\""))
  assert_true(content.contains("\"codeiq.query.symbol\""))

  remove_file_if_exists("./dist/mcp-server.json")
  cleanup_tmp_dir(dir)
}

///|
test "mcp start rejects invalid port" {
  let out = run_start({ port: 70000 })
  guard out is Err(error) else {
    fail("mcp start should fail for invalid port")
  }

  let text = error.to_string()
  assert_true(text.contains("mcp failed:"))
  assert_true(text.contains("port must be in range 1..65535"))
}

///|
fn parse_json_or_fail(text : String) -> Json {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { abort("invalid json in test") }
  value
}

///|
test "mcp initialize request returns protocol metadata" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 1,
      #|  "method": "initialize",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"protocolVersion\": \"2025-11-25\""))
  assert_true(response.contains("\"codeiq-mcp\""))
}

///|
test "mcp tools list includes outlines and symbol" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 2,
      #|  "method": "tools/list",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"tools\""))
  assert_true(response.contains("\"codeiq.query.outlines\""))
  assert_true(response.contains("\"codeiq.query.symbol\""))
}

///|
test "mcp tools call returns structured content" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 3,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "codeiq.query.symbol",
      #|    "arguments": {
      #|      "purl": "pkg:openapi/acme/payment-api@2026.04.01",
      #|      "selector": "payment::create",
      #|      "kind": "operation"
      #|    }
      #|  }
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"isError\": false"))
  assert_true(response.contains("\"schemaVersion\": \"ciq-result/v1\""))
  assert_true(response.contains("\"decl:skeleton:payment::create\""))
}

///|
test "mcp tools call unknown tool returns jsonrpc error" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 4,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "codeiq.query.unknown",
      #|    "arguments": {}
      #|  }
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"code\": -32601"))
  assert_true(response.contains("unknown tool"))
}
