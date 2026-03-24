///|
pub(all) struct McpStartParams {
  port : Int
  stdio : Bool
} derive(Show, Eq)

///|
pub(all) struct McpStartResult {
  port : Int
  summary : String
} derive(Show, Eq)

///|
pub(all) struct McpStatusResult {
  status : String
  summary : String
} derive(Show, Eq)

///|
pub(all) struct McpDescriptor {
  path : String
  info : Json
} derive(Show, Eq)

///|
pub(all) struct McpStopResult {
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for McpStartResult with display(self : McpStartResult) -> String {
  self.summary
}

///|
pub impl @cli.Display for McpStatusResult with display(self : McpStatusResult) -> String {
  self.summary
}

///|
pub impl @cli.Display for McpStopResult with display(self : McpStopResult) -> String {
  self.summary
}

///|
fn mcp_error(message : String) -> @cli.CliError {
  @cli.command_error("mcp failed: \{message}")
}

///|
fn validate_port(port : Int) -> Result[Unit, @cli.CliError] {
  if port <= 0 || port > 65535 {
    Err(mcp_error("port must be in range 1..65535"))
  } else {
    Ok(())
  }
}

///|
fn tool_definitions() -> Array[Json] {
  @mcp_sdk.tool_definitions()
}

///|
fn tools_state_path() -> String {
  @mcp_sdk.tools_state_path()
}

///|
fn ensure_dist_dir() -> Result[Unit, @cli.CliError] {
  if @fs.path_exists("./dist") {
    Ok(())
  } else {
    @fs.create_dir("./dist") catch {
      err =>
        return Err(
          mcp_error("cannot create ./dist directory: \{err.to_string()}"),
        )
    }
    Ok(())
  }
}

///|
fn sync_tools_state() -> Result[Bool, @cli.CliError] {
  let out = @mcp_sdk.sync_tools_state()
  guard out is Ok(changed) else { return Err(mcp_error(out.unwrap_err())) }
  Ok(changed)
}

///|
fn descriptor_path() -> String {
  "./dist/mcp-server.json"
}

///|
fn pid_json(pid : Int?) -> Json {
  match pid {
    Some(value) => Json::number(value.to_double(), repr="\{value}")
    None => Json::null()
  }
}

///|
fn mcp_server_info(port : Int, stdio~ : Bool = true, pid? : Int) -> Json {
  let bundle_resolved = @fs.path_exists("./dist/manifest.json")
  {
    "schemaVersion": "codeiq-mcp-descriptor/v1",
    "name": "codeiq-mcp",
    "protocolVersion": "2025-11-25",
    "transport": if stdio { "stdio" } else { "detached-stdio" },
    "port": port,
    "pid": pid_json(pid),
    "command": if stdio { "stdio-inline" } else { "moon run src/cmd/main --" },
    "bundleResolved": bundle_resolved,
    "initializeResult": @mcp_core.initialize_result(),
    "tools": tool_definitions(),
  }
}

///|
fn write_mcp_info(path : String, info : Json) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, info.stringify(indent=2)) catch {
    err =>
      return Err(mcp_error("cannot write mcp info \{path}: \{err.to_string()}"))
  }
  Ok(())
}

///|
fn read_mcp_info(path : String) -> Result[McpDescriptor, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(mcp_error("cannot read mcp info \{path}: \{err.to_string()}"))
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(info) else {
    return Err(mcp_error("mcp descriptor is not valid json"))
  }
  Ok({ path, info })
}

///|
fn descriptor_pid(info : Json) -> Int? {
  guard info is Object(info_object) else { return None }
  match info_object.get("pid") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}

///|
fn write_runtime_state_with_pid(path : String, port : Int, pid : Int) -> Result[Unit, @cli.CliError] {
  write_mcp_info(path, mcp_server_info(port, stdio=false, pid=pid))
}

///|
fn wait_for_process_start(pid : Int) -> Bool {
  for _ in 0..<10 {
    if @shell.is_alive(pid) {
      return true
    }
    @shell.sleep_ms(100)
  }
  false
}

///|
fn wait_for_process_stop(pid : Int) -> Bool {
  for _ in 0..<20 {
    if !@shell.is_alive(pid) {
      return true
    }
    @shell.sleep_ms(100)
  }
  false
}

///|
fn spawn_detached_stdio_process(port : Int) -> Result[Int, @cli.CliError] {
  let command = "moon run src/cmd/main -- mcp serve --port \{port}"
  let spawn_out = @shell.spawn_detached(command)
  guard spawn_out is Ok(pid) else {
    return Err(mcp_error(spawn_out.unwrap_err()))
  }
  if wait_for_process_start(pid) {
    Ok(pid)
  } else {
    Err(mcp_error("detached MCP process did not start in time"))
  }
}

///|
pub fn run_start(
  params : McpStartParams,
) -> @cli.CliResult[McpStartResult, @cli.CliError] {
  let port_out = validate_port(params.port)
  guard port_out is Ok(_) else { return Err(port_out.unwrap_err()) }

  let dist_out = ensure_dist_dir()
  guard dist_out is Ok(_) else { return Err(dist_out.unwrap_err()) }

  if params.stdio {
    return Err(
      mcp_error(
        "inline stdio mode moved to `codeiq mcp serve`; use `codeiq mcp start --stdio false` for detached mode",
      ),
    )
  }

  let pid_out = spawn_detached_stdio_process(params.port)
  guard pid_out is Ok(pid) else { return Err(pid_out.unwrap_err()) }
  let info_path = descriptor_path()
  let write_out = write_runtime_state_with_pid(info_path, params.port, pid)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  let sync_out = sync_tools_state()
  guard sync_out is Ok(_) else { return Err(sync_out.unwrap_err()) }
  @mcp_sdk.clear_runtime_state()

  Ok({
    port: params.port,
    summary: "Started MCP detached stdio process with descriptor at \{info_path} (port \{params.port}, pid \{pid})",
  })
}

///|
pub fn run_status() -> @cli.CliResult[McpStatusResult, @cli.CliError] {
  let info_path = descriptor_path()
  if @fs.path_exists(info_path) {
    let info_out = read_mcp_info(info_path)
    guard info_out is Ok(descriptor) else { return Err(info_out.unwrap_err()) }
    match descriptor_pid(descriptor.info) {
      Some(pid) =>
        if @shell.is_alive(pid) {
          Ok({
            status: "running",
            summary: "MCP descriptor found at \{info_path} with live pid \{pid}",
          })
        } else {
          Ok({
            status: "stopped",
            summary: "MCP descriptor found at \{info_path} but pid \{pid} is not running",
          })
        }
      None => Ok({ status: "running", summary: "MCP descriptor found at \{info_path}" })
    }
  } else {
    Ok({
      status: "stopped",
      summary: "MCP descriptor not found (expected \{info_path})",
    })
  }
}

///|
pub fn run_stop() -> @cli.CliResult[McpStopResult, @cli.CliError] {
  let info_path = descriptor_path()
  let state_path = tools_state_path()
  @mcp_sdk.clear_runtime_state()
  if @fs.path_exists(info_path) {
    let info_out = read_mcp_info(info_path)
    guard info_out is Ok(descriptor) else { return Err(info_out.unwrap_err()) }
    match descriptor_pid(descriptor.info) {
      Some(pid) => {
        if @shell.is_alive(pid) {
          ignore(@shell.terminate(pid))
          if !wait_for_process_stop(pid) {
            ignore(@shell.force_kill(pid))
            ignore(wait_for_process_stop(pid))
          }
        }
      }
      None => ()
    }
    @fs.remove_file(info_path) catch {
      err =>
        return Err(mcp_error("cannot remove \{info_path}: \{err.to_string()}"))
    }
    if @fs.path_exists(state_path) {
      @fs.remove_file(state_path) catch {
        err =>
          return Err(
            mcp_error("cannot remove \{state_path}: \{err.to_string()}"),
          )
      }
    }
    Ok({ summary: "Removed MCP descriptor at \{info_path}" })
  } else {
    if @fs.path_exists(state_path) {
      @fs.remove_file(state_path) catch {
        err =>
          return Err(
            mcp_error("cannot remove \{state_path}: \{err.to_string()}"),
          )
      }
    }
    Ok({ summary: "MCP already stopped (no descriptor at \{info_path})" })
  }
}
