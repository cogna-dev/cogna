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
  @mcp_core.tool_definitions()
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
  let out = @mcp_sdk.sync_tools_state(tool_definitions())
  guard out is Ok(changed) else { return Err(mcp_error(out.unwrap_err())) }
  Ok(changed)
}

///|
fn descriptor_path() -> String {
  "./dist/mcp-server.json"
}

///|
fn project_root_path() -> String {
  @env.current_dir().unwrap_or(".")
}

///|
fn native_target_dir(port : Int) -> String {
  "/tmp/codeiq-mcp-\{port}"
}

///|
fn shell_quote(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn native_serve_command(port : Int) -> String {
  let manifest_path = "\{project_root_path()}/moon.mod.json"
  let target_dir = native_target_dir(port)
  "moon run --target native --frozen --target-dir \{shell_quote(target_dir)} --manifest-path \{shell_quote(manifest_path)} src/cmd/main -- mcp serve --port \{port}"
}

///|
fn pid_json(pid : Int?) -> Json {
  match pid {
    Some(value) => Json::number(value.to_double(), repr="\{value}")
    None => Json::null()
  }
}

///|
fn mcp_server_info(port : Int, pid? : Int) -> Json {
  let bundle_resolved = @fs.path_exists("./dist/manifest.json")
  let base_url = @mcp_core.base_url(port)
  let rpc_url = @mcp_core.rpc_url(port)
  let health_url = @mcp_core.health_url(port)
  {
    "schemaVersion": "codeiq-mcp-descriptor/v1",
    "name": "codeiq-mcp",
    "protocolVersion": "2025-11-25",
    "transport": "http",
    "port": port,
    "pid": pid_json(pid),
    "baseUrl": base_url,
    "rpcUrl": rpc_url,
    "healthUrl": health_url,
    "command": native_serve_command(port),
    "bundleResolved": bundle_resolved,
    "initializeResult": @mcp_core.initialize_result(),
    "tools": tool_definitions(),
  }
}

///|
fn write_mcp_info(path : String, info : Json) -> Result[Unit, @cli.CliError] {
  let out = @server_runtime.write_descriptor(path, info)
  guard out is Ok(_) else { return Err(mcp_error(out.unwrap_err())) }
  Ok(())
}

///|
fn read_mcp_info(path : String) -> Result[McpDescriptor, @cli.CliError] {
  let out = @server_runtime.read_descriptor(path)
  guard out is Ok(descriptor) else { return Err(mcp_error(out.unwrap_err())) }
  Ok({ path: descriptor.path, info: descriptor.info })
}

///|
fn descriptor_pid(info : Json) -> Int? {
  @server_runtime.descriptor_pid(info)
}

///|
fn descriptor_health_url(info : Json, port : Int) -> String {
  match @server_runtime.descriptor_string(info, "healthUrl") {
    Some(url) => url
    None => @mcp_core.health_url(port)
  }
}

///|
fn write_runtime_state_with_pid(
  path : String,
  port : Int,
  pid : Int,
) -> Result[Unit, @cli.CliError] {
  write_mcp_info(path, mcp_server_info(port, pid~))
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
fn spawn_detached_server_process(port : Int) -> Result[Int, @cli.CliError] {
  let command = native_serve_command(port)
  let spawn_out = @shell.spawn_detached(command)
  guard spawn_out is Ok(pid) else {
    return Err(mcp_error(spawn_out.unwrap_err()))
  }
  Ok(pid)
}

///|
fn wait_for_server_health(port : Int, pid : Int) -> Bool {
  let health_url = @mcp_core.health_url(port)
  for _ in 0..<200 {
    if @server_runtime.wait_for_health(health_url, attempts=1, sleep_ms=0) {
      return true
    }
    if !@shell.is_alive(pid) {
      return false
    }
    @shell.sleep_ms(100)
  }
  false
}

///|
fn stop_process_if_alive(pid : Int) -> Unit {
  if @shell.is_alive(pid) {
    ignore(@shell.terminate(pid))
    if !wait_for_process_stop(pid) {
      ignore(@shell.force_kill(pid))
      ignore(wait_for_process_stop(pid))
    }
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

  ignore(params.stdio)

  let pid_out = spawn_detached_server_process(params.port)
  guard pid_out is Ok(pid) else { return Err(pid_out.unwrap_err()) }
  if !wait_for_server_health(params.port, pid) {
    stop_process_if_alive(pid)
    return Err(mcp_error("MCP server did not become healthy in time"))
  }
  let info_path = descriptor_path()
  let write_out = write_runtime_state_with_pid(info_path, params.port, pid)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  let sync_out = sync_tools_state()
  guard sync_out is Ok(_) else { return Err(sync_out.unwrap_err()) }
  @mcp_sdk.clear_runtime_state()

  Ok({
    port: params.port,
    summary: "Started MCP server with descriptor at \{info_path} (port \{params.port}, pid \{pid})",
  })
}

///|
pub fn run_status() -> @cli.CliResult[McpStatusResult, @cli.CliError] {
  let info_path = descriptor_path()
  if @fs.path_exists(info_path) {
    let info_out = read_mcp_info(info_path)
    guard info_out is Ok(descriptor) else { return Err(info_out.unwrap_err()) }
    let port = @server_runtime.descriptor_port(descriptor.info).unwrap_or(0)
    let health_url = descriptor_health_url(descriptor.info, port)
    let healthy = @server_runtime.wait_for_health(
      health_url,
      attempts=1,
      sleep_ms=0,
    )
    match descriptor_pid(descriptor.info) {
      Some(pid) =>
        if @shell.is_alive(pid) && healthy {
          Ok({
            status: "running",
            summary: "MCP server healthy at \{health_url} with live pid \{pid}",
          })
        } else {
          Ok({
            status: "stopped",
            summary: "MCP descriptor found at \{info_path} but server is not healthy (pid \{pid})",
          })
        }
      None =>
        if healthy {
          Ok({
            status: "running",
            summary: "MCP server healthy at \{health_url}",
          })
        } else {
          Ok({
            status: "stopped",
            summary: "MCP descriptor found at \{info_path} but server is not healthy",
          })
        }
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
      Some(pid) => stop_process_if_alive(pid)
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
