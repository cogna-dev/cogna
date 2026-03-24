///|
fn mcp_remove_file_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
test "e2e mcp detached lifecycle covers start status stop" {
  mcp_remove_file_if_exists("./dist/mcp-server.json")
  mcp_remove_file_if_exists("./dist/mcp-tools-state.json")

  let stop_before = @mcp_cmd.run_stop()
  ignore(stop_before)

  let start_out = @mcp_cmd.run_start({ port: 3050, stdio: false })
  guard start_out is Ok(started) else {
    fail("mcp start should succeed")
  }
  assert_true(started.display().contains("pid "))

  let status_out = @mcp_cmd.run_status()
  guard status_out is Ok(status) else {
    ignore(@mcp_cmd.run_stop())
    fail("mcp status should succeed")
  }
  inspect(status.status, content="running")
  assert_true(status.summary.contains("live pid"))

  let stop_out = @mcp_cmd.run_stop()
  guard stop_out is Ok(stopped) else {
    fail("mcp stop should succeed")
  }
  assert_true(stopped.summary.contains("Removed MCP descriptor"))

  let stopped_status_out = @mcp_cmd.run_status()
  guard stopped_status_out is Ok(stopped_status) else {
    fail("mcp status after stop should succeed")
  }
  inspect(stopped_status.status, content="stopped")
}
