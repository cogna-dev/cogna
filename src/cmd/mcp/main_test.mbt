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
fn cleanup_test_state() -> Unit {
  remove_file_if_exists("./dist/mcp-server.json")
  remove_file_if_exists("./dist/mcp-tools-state.json")
  remove_dir_if_exists("./dist")
}

///|
test "mcp start writes server descriptor" {
  cleanup_test_state()

  let result = run_start({ port: 8080, stdio: false })
  guard result is Ok(ok) else {
    cleanup_test_state()
    fail("mcp start should succeed")
  }
  assert_true(ok.display().contains("Started MCP server"))
  assert_true(ok.display().contains("pid "))

  let content = @fs.read_file_to_string("./dist/mcp-server.json") catch {
    _ => {
      cleanup_test_state()
      fail("mcp descriptor should exist")
      ""
    }
  }
  assert_true(content.contains("\"name\": \"codeiq-mcp\""))
  assert_true(content.contains("\"protocolVersion\": \"2025-11-25\""))
  assert_true(content.contains("\"bundleResolved\""))
  assert_true(content.contains("\"listChanged\": true"))
  assert_true(content.contains("\"initializeResult\""))
  assert_true(content.contains("\"codeiq.query.outlines\""))
  assert_true(content.contains("\"codeiq.query.symbol\""))
  assert_true(content.contains("\"transport\": \"http\""))
  assert_true(content.contains("\"rpcUrl\": \"http://127.0.0.1:8080/rpc\""))
  assert_true(
    content.contains("\"healthUrl\": \"http://127.0.0.1:8080/health\""),
  )
  assert_true(content.contains("\"pid\":"))
  assert_true(@fs.path_exists("./dist/mcp-tools-state.json"))

  ignore(run_stop())
  cleanup_test_state()
}

///|
test "mcp start rejects invalid port" {
  let out = run_start({ port: 70000, stdio: false })
  guard out is Err(error) else {
    fail("mcp start should fail for invalid port")
  }

  let text = error.to_string()
  assert_true(text.contains("mcp failed:"))
  assert_true(text.contains("port must be in range 1..65535"))
}

///|
test "mcp start accepts deprecated stdio flag" {
  let out = run_start({ port: 3000, stdio: true })
  guard out is Ok(result) else {
    fail("mcp start with stdio=true should still start the server")
  }
  assert_true(result.display().contains("Started MCP server"))
  ignore(run_stop())
}

///|
test "mcp status reports stopped when descriptor missing" {
  @fs.remove_file("./dist/mcp-server.json") catch {
    _ => ()
  }
  let out = run_status()
  guard out is Ok(result) else { fail("mcp status should succeed") }
  assert_true(result.display().contains("not found"))
}

///|
test "mcp status reports running for live pid descriptor" {
  let start_out = run_start({ port: 3010, stdio: false })
  guard start_out is Ok(_) else { fail("mcp start should succeed") }
  let out = run_status()
  guard out is Ok(result) else { fail("mcp status should succeed") }
  assert_true(result.display().contains("healthy"))
  ignore(run_stop())
}

///|
test "mcp status reports running for serve-written descriptor" {
  @fs.create_dir("./dist") catch {
    _ => ()
  }
  let descriptor : Json = {
    "schemaVersion": "codeiq-mcp-descriptor/v1",
    "name": "codeiq-mcp",
    "protocolVersion": "2025-11-25",
    "transport": "http",
    "port": 65534,
    "pid": null,
    "baseUrl": "http://127.0.0.1:65534",
    "rpcUrl": "http://127.0.0.1:65534/rpc",
    "healthUrl": "http://127.0.0.1:65534/health",
  }
  @fs.write_string_to_file(
    "./dist/mcp-server.json",
    descriptor.stringify(indent=2),
  ) catch {
    _ => fail("failed to write descriptor fixture")
  }
  let out = run_status()
  guard out is Ok(result) else { fail("mcp status should succeed") }
  inspect(result.status, content="stopped")
  assert_true(result.display().contains("descriptor found"))
  @fs.remove_file("./dist/mcp-server.json") catch {
    _ => ()
  }
}

///|
test "mcp stop removes descriptor when present" {
  let start_out = run_start({ port: 3020, stdio: false })
  guard start_out is Ok(_) else { fail("mcp start should succeed") }

  let out = run_stop()
  guard out is Ok(result) else { fail("mcp stop should succeed") }
  assert_true(result.display().contains("Removed MCP descriptor"))
  assert_true(!@fs.path_exists("./dist/mcp-server.json"))
  assert_true(!@fs.path_exists("./dist/mcp-tools-state.json"))
}
