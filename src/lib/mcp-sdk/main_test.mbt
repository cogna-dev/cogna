///|
fn parse_json_or_fail(text : String) -> Json {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { abort("invalid json fixture") }
  value
}

///|
test "mcp-sdk serve_stdio_once returns parse error for invalid json" {
  let response = serve_stdio_once("{", _ => Json::null())
  assert_true(response.contains("-32700"))
}

///|
test "mcp-sdk stdio_output_lines emits list changed notification" {
  let outputs = stdio_output_lines("{}", _ => {
    "jsonrpc": "2.0",
    "id": 1,
    "result": { "listChanged": true },
  })
  assert_true(outputs.length() == 2)
  assert_true(outputs[0].contains("notifications/tools/list_changed"))
  assert_true(outputs[1].contains("\"listChanged\":true"))
}

///|
test "mcp-sdk stdio_output_lines suppresses response for jsonrpc notification" {
  let outputs = stdio_output_lines(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "method": "notifications/initialized",
      #|  "params": {}
      #|}
    ),
    _ => { "jsonrpc": "2.0", "id": null, "result": { "ok": true } },
  )
  assert_true(outputs.length() == 0)
}

///|
test "mcp-sdk stdio_output_lines keeps parse error responses" {
  let outputs = stdio_output_lines("{", _ => Json::null())
  assert_true(outputs.length() == 1)
  assert_true(outputs[0].contains("-32700"))
}

///|
test "mcp-sdk route_request returns invalid request error" {
  let response = route_request(Json::null(), _ => Json::null()).stringify(
    indent=2,
  )
  assert_true(response.contains("\"code\": -32600"))
}

///|
test "mcp-sdk parse_tool_call extracts name and arguments" {
  let params = parse_json_or_fail(
    (
      #|{
      #|  "name": "codeiq.query.outlines",
      #|  "arguments": {
      #|    "purl": "pkg:generic/acme/demo@0.1.0"
      #|  }
      #|}
    ),
  )
  let out = parse_tool_call(params)
  guard out is Ok((name, args)) else { fail("expected tool call to parse") }
  inspect(name, content="codeiq.query.outlines")
  let purl_out = get_required_string(args, "purl")
  guard purl_out is Ok(purl) else { fail("expected purl argument") }
  inspect(purl, content="pkg:generic/acme/demo@0.1.0")
}

///|
fn generic_tools() -> Array[Json] {
  [{ "name": "demo.echo", "inputSchema": { "type": "object" } }]
}

///|
fn sync_generic_tools() -> Result[Bool, String] {
  sync_tools_state(generic_tools())
}

///|
test "mcp-sdk handle_standard_request handles tools/list" {
  @fs.remove_file("./dist/mcp-tools-state.json") catch {
    _ => ()
  }
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 7,
      #|  "method": "tools/list",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_standard_request(
    request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Err((-32601, "not used")),
  ).stringify(indent=2)
  assert_true(response.contains("\"tools\""))
  assert_true(response.contains("\"listChanged\""))
}

///|
test "mcp-sdk handle_standard_request supports cancel request" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 17,
      #|  "method": "$/cancelRequest",
      #|  "params": {
      #|    "id": 2
      #|  }
      #|}
    ),
  )
  let response = handle_standard_request(
    request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Err((-32601, "not used")),
  ).stringify(indent=2)
  assert_true(response.contains("\"cancelled\": true"))
}

///|
test "mcp-sdk handle_standard_request supports cancel requestId field" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 18,
      #|  "method": "$/cancelRequest",
      #|  "params": {
      #|    "requestId": 2
      #|  }
      #|}
    ),
  )
  let response = handle_standard_request(
    request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Err((-32601, "not used")),
  ).stringify(indent=2)
  assert_true(response.contains("\"cancelled\": true"))
  assert_true(response.contains("\"requestId\": 2"))
}

///|
test "mcp-sdk handle_standard_request reports false cancellation for missing request id" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 19,
      #|  "method": "$/cancelRequest",
      #|  "params": {}
      #|}
    ),
  )
  let response = handle_standard_request(
    request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Err((-32601, "not used")),
  ).stringify(indent=2)
  assert_true(response.contains("\"cancelled\": false"))
}

///|
test "mcp-sdk tools/call returns cancelled when request was cancelled first" {
  let cancel_request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 77000,
      #|  "method": "$/cancelRequest",
      #|  "params": {
      #|    "requestId": 77001
      #|  }
      #|}
    ),
  )
  let cancel_response = handle_standard_request(
    cancel_request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Err((-32601, "not used")),
  ).stringify(indent=2)
  assert_true(cancel_response.contains("\"cancelled\": true"))

  let call_request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 77001,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "demo.echo",
      #|    "arguments": {
      #|      "purl": "pkg:generic/acme/demo@0.1.0"
      #|    }
      #|  }
      #|}
    ),
  )
  let response = handle_standard_request(
    call_request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Ok(call_result("ok", { "ok": true }, false)),
  ).stringify(indent=2)
  assert_true(response.contains("\"code\": -32603"))
  assert_true(response.contains("request cancelled"))
}

///|
test "mcp-sdk handle_standard_request rejects initialize cancellation" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 11,
      #|  "method": "$/cancelRequest",
      #|  "params": {
      #|    "id": 11
      #|  }
      #|}
    ),
  )
  let response = handle_standard_request(
    request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Err((-32601, "not used")),
  ).stringify(indent=2)
  assert_true(response.contains("\"code\": -32600"))
  assert_true(response.contains("cannot cancel initialize request"))
}

///|
test "mcp-sdk parse_deadline_ms supports timeoutMs" {
  let params = parse_json_or_fail(
    (
      #|{
      #|  "timeoutMs": 50
      #|}
    ),
  )
  let deadline_out = parse_deadline_ms(params, 100)
  guard deadline_out is Some(deadline) else {
    fail("deadline should be parsed")
  }
  inspect(deadline.to_int(), content="150")
}

///|
test "mcp-sdk tools/call returns deadline exceeded when deadline is in the past" {
  let request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 88001,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "demo.echo",
      #|    "deadlineMs": 1,
      #|    "arguments": {
      #|      "purl": "pkg:generic/acme/demo@0.1.0"
      #|    }
      #|  }
      #|}
    ),
  )
  let response = handle_standard_request(
    request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => Ok(call_result("ok", { "ok": true }, false)),
  ).stringify(indent=2)
  assert_true(response.contains("request deadline exceeded"))
}

///|
test "mcp-sdk runtime/context reports active requests" {
  clear_runtime_state()
  let call_request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 99001,
      #|  "method": "tools/call",
      #|  "params": {
      #|    "name": "demo.echo",
      #|    "timeoutMs": 60000,
      #|    "arguments": {
      #|      "purl": "pkg:generic/acme/demo@0.1.0"
      #|    }
      #|  }
      #|}
    ),
  )

  let snapshot_request = parse_json_or_fail(
    (
      #|{
      #|  "jsonrpc": "2.0",
      #|  "id": 99002,
      #|  "method": "runtime/context",
      #|  "params": {}
      #|}
    ),
  )

  let mut snapshot_json : Json? = None
  let _ = handle_standard_request(
    call_request,
    { "protocolVersion": "2025-11-25" },
    { "status": "ok" },
    generic_tools(),
    sync_generic_tools,
    (_, _, _) => {
      snapshot_json = Some(
        handle_standard_request(
          snapshot_request,
          { "protocolVersion": "2025-11-25" },
          { "status": "ok" },
          generic_tools(),
          sync_generic_tools,
          (_, _, _) => Err((-32601, "not used")),
        ),
      )
      Ok(call_result("ok", { "ok": true }, false))
    },
  )
  guard snapshot_json is Some(snapshot_value) else {
    fail("runtime/context snapshot should be captured")
  }
  let snapshot = snapshot_value.stringify(indent=2)
  assert_true(snapshot.contains("activeRequests"))
  assert_true(snapshot.contains("99001"))
}
