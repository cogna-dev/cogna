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
