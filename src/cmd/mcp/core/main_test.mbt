///|
fn remove_file_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn initialize_request() -> String {
  let text =
    #|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"cogna-test","version":"0.1.0"}}}
    #|
  text
}

///|
test "mcp core descriptor exposes standard mcp url" {
  inspect(mcp_url(3000), content="http://127.0.0.1:3000/mcp")
}

///|
test "mcp initialize result exposes protocol metadata" {
  let response = initialize_result().stringify(indent=2)
  assert_true(response.contains("\"protocolVersion\": \"2025-11-25\""))
  assert_true(response.contains("\"cogna-mcp\""))
  assert_true(response.contains("\"tools\""))
}

///|
test "mcp tool definitions align with product api surface" {
  let text = Json::array(tool_definitions()).stringify(indent=2)
  assert_true(text.contains("\"fetch_packages\""))
  assert_true(text.contains("\"query_outlines\""))
  assert_true(text.contains("\"query\""))
}

///|
test "mcp tool definitions sync to dist state" {
  remove_file_if_exists("./dist/mcp-tools-state.json")
  let out = sync_tools_state()
  guard out is Ok(changed) else { fail("sync tools state should succeed") }
  inspect(changed, content="true")
  assert_true(@fs.path_exists("./dist/mcp-tools-state.json"))
}

///|
test "mcp initialize request shape is valid json" {
  let parsed = try? @json.parse(initialize_request())
  guard parsed is Ok(Object(object)) else {
    fail("initialize request should parse")
  }
  guard object.get("method") is Some(String(method_name)) else {
    fail("initialize request should have method")
  }
  inspect(method_name, content="initialize")
}
