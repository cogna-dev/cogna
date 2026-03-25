///|
fn remove_file_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
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
test "mcp tools list response matches schema" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 20,
      #|  "method": "tools/list",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_request(request)
  guard response is Object(response_object) else {
    fail("response should be object")
  }
  guard response_object.get("result") is Some(Object(result_object)) else {
    fail("tools/list response should contain result object")
  }
  guard result_object.get("tools") is Some(Array(tools)) else {
    fail("tools/list response should contain tools array")
  }
  assert_true(tools.length() == 3)
}

///|
test "mcp tools list includes listChanged flag" {
  remove_file_if_exists("./dist/mcp-tools-state.json")

  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 30,
      #|  "method": "tools/list",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"listChanged\": true"))

  let response2 = handle_request(request).stringify(indent=2)
  assert_true(response2.contains("\"listChanged\": false"))
}

///|
test "mcp stdio output lines include server-initiated list_changed notification" {
  remove_file_if_exists("./dist/mcp-tools-state.json")
  let outputs = @mcp_sdk.stdio_output_lines(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 33,
      #|  "method": "tools/list",
      #|  "params": {}
      #|}
    ),
    handle_request,
  )
  assert_true(outputs.length() == 2)
  assert_true(outputs[0].contains("notifications/tools/list_changed"))
  assert_true(outputs[1].contains("\"listChanged\":true"))
}

///|
test "mcp tools list_changed reports changed state" {
  remove_file_if_exists("./dist/mcp-tools-state.json")

  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 31,
      #|  "method": "tools/list_changed",
      #|  "params": {}
      #|}
    ),
  )
  let first = handle_request(request).stringify(indent=2)
  assert_true(first.contains("\"changed\": true"))
  assert_true(first.contains("notifications/tools/list_changed"))

  let second = handle_request(request).stringify(indent=2)
  assert_true(second.contains("\"changed\": false"))
}

///|
test "mcp notifications methods are accepted" {
  let init_notification = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "method": "notifications/initialized",
      #|  "params": {}
      #|}
    ),
  )
  let cancel_notification = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "method": "notifications/cancelled",
      #|  "params": {}
      #|}
    ),
  )
  let init_response = handle_request(init_notification).stringify(indent=2)
  let cancel_response = handle_request(cancel_notification).stringify(indent=2)
  assert_true(init_response.contains("\"ok\": true"))
  assert_true(cancel_response.contains("\"ok\": true"))
}

///|
test "mcp cancel request method is accepted" {
  let cancel_request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 45,
      #|  "method": "$/cancelRequest",
      #|  "params": {
      #|    "id": 7
      #|  }
      #|}
    ),
  )
  let response = handle_request(cancel_request).stringify(indent=2)
  assert_true(response.contains("\"cancelled\": true"))
}

///|
test "mcp tools call returns structured content" {
  @fs.create_dir("./dist") catch {
    _ => ()
  }
  let declarations =
    #|{"id":"decl:payment:create","kind":"operation","path":"payment::create","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  @fs.write_string_to_file("./dist/declarations.ndjson", declarations) catch {
    _ => fail("failed to write declaration fixture")
  }

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
  assert_true(response.contains("\"source\": \"bundle\""))
  assert_true(response.contains("\"decl:payment:create\""))

  @fs.remove_file("./dist/declarations.ndjson") catch {
    _ => ()
  }
}

///|
test "mcp tools call uses local query result when available" {
  @fs.create_dir("./dist") catch {
    _ => ()
  }
  let local_result =
    #|{
    #|  "schemaVersion": "ciq-result/v1",
    #|  "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    #|  "matches": [
    #|    {
    #|      "id": "decl:local:payment::create",
    #|      "kind": "operation",
    #|      "signature": "POST /payment/create",
    #|      "location": {"uri": "openapi/payment.yaml", "startLine": 10, "endLine": 22}
    #|    }
    #|  ]
    #|}
  @fs.write_string_to_file("./dist/query.result.json", local_result) catch {
    _ => fail("failed to write local query result fixture")
  }

  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 23,
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
  assert_true(response.contains("\"schemaVersion\": \"ciq-result/v1\""))
  assert_true(response.contains("\"source\": \"bundle\""))
  assert_true(response.contains("\"matches\": []"))

  @fs.remove_file("./dist/query.result.json") catch {
    _ => ()
  }
}

///|
test "mcp stdio once handles parse error" {
  let response = serve_stdio_once("{")
  assert_true(response.contains("-32700"))
}

///|
test "mcp ping reports local artifact availability" {
  @fs.create_dir("./dist") catch {
    _ => ()
  }
  @fs.write_string_to_file("./dist/check.sarif.json", "{}") catch {
    _ => fail("failed to write local sarif fixture")
  }

  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 24,
      #|  "method": "ping",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"status\": \"ok\""))
  assert_true(response.contains("\"sarif\": true"))

  @fs.remove_file("./dist/check.sarif.json") catch {
    _ => ()
  }
}

///|
test "mcp tools call outlines accepts limit and cursor" {
  @fs.create_dir("./dist") catch {
    _ => ()
  }
  let declarations =
    #|{"id":"decl:1","kind":"operation","path":"openapi/payment.yaml","signature":"operation listPayments","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|{"id":"decl:2","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":21,"endLine":30}}
    #|
  @fs.write_string_to_file("./dist/declarations.ndjson", declarations) catch {
    _ => fail("failed to write declaration fixture")
  }

  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 21,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "codeiq.query.outlines",
      #|    "arguments": {
      #|      "purl": "pkg:openapi/acme/payment-api@2026.04.01",
      #|      "limit": 1,
      #|      "cursor": "cursor:1"
      #|    }
      #|  }
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"Returned 1 outline\""))
  assert_true(response.contains("\"limit\": 1"))

  @fs.remove_file("./dist/declarations.ndjson") catch {
    _ => ()
  }
}

///|
test "mcp tools call reports missing required argument" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 22,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "codeiq.query.symbol",
      #|    "arguments": {
      #|      "purl": "pkg:openapi/acme/payment-api@2026.04.01"
      #|    }
      #|  }
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"code\": -32602"))
  assert_true(response.contains("missing required string argument selector"))
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

///|
test "mcp tools call runtime context returns activeRequests" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 90,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "codeiq.runtime.context",
      #|    "arguments": {}
      #|  }
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("\"isError\": false"))
  assert_true(response.contains("activeRequests"))
}

///|
test "mcp tools call returns deadline exceeded for past deadline" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 91,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "codeiq.query.outlines",
      #|    "deadlineMs": 1,
      #|    "arguments": {
      #|      "purl": "pkg:openapi/acme/payment-api@2026.04.01"
      #|    }
      #|  }
      #|}
    ),
  )
  let response = handle_request(request).stringify(indent=2)
  assert_true(response.contains("request deadline exceeded"))
}

///|
test "mcp runtime context state can be cleared" {
  let set_request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 92,
      #|  "method": "$\/cancelRequest",
      #|  "params": {
      #|    "requestId": 1001
      #|  }
      #|}
    ),
  )
  let _ = handle_request(set_request)
  @mcp_sdk.clear_runtime_state()
  let context_request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 93,
      #|  "method": "runtime/context",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_request(context_request).stringify(indent=2)
  assert_true(response.contains("\"activeRequests\": []"))
}
