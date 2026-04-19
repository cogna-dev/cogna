///|
pub(all) struct McpStartParams {
  port : Int
  stdio : Bool
} derive(Eq)

///|
pub impl Show for McpStartParams with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_string(", stdio: ")
  logger.write_object(self.stdio)
  logger.write_char('}')
}

///|
pub(all) struct McpStartResult {
  port : Int
  summary : String
} derive(Eq)

///|
pub impl Show for McpStartResult with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub(all) struct McpStatusResult {
  status : String
  summary : String
} derive(Eq)

///|
pub impl Show for McpStatusResult with output(self, logger) {
  logger.write_string("{status: ")
  logger.write_object(self.status)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub(all) struct McpDescriptor {
  path : String
  info : Json
} derive(Eq)

///|
pub impl Show for McpDescriptor with output(self, logger) {
  logger.write_string("{path: ")
  logger.write_object(self.path)
  logger.write_string(", info: ")
  logger.write_object(self.info)
  logger.write_char('}')
}

///|
pub(all) struct McpStopResult {
  summary : String
} derive(Eq)

///|
pub impl Show for McpStopResult with output(self, logger) {
  logger.write_string("{summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

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
  @mcp_core.tools_state_path()
}

///|
fn ensure_dist_dir() -> Result[Unit, @cli.CliError] {
  if @fs.path_exists("./dist") {
    Ok(())
  } else {
    @fs.create_dir("./dist") catch {
      err =>
        return Err(
          mcp_error("cannot create ./dist directory: \{@debug.to_repr(err)}"),
        )
    }
    Ok(())
  }
}

///|
fn sync_tools_state() -> Result[Bool, @cli.CliError] {
  @mcp_core.sync_tools_state()
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
  "/tmp/cogna-mcp-\{port}"
}

///|
fn shell_quote(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn native_serve_command(port : Int) -> String {
  let run_script = "\{project_root_path()}/integrations/cli/run.sh"
  let target_dir = native_target_dir(port)
  "bash \{shell_quote(run_script)} --target native --frozen --target-dir \{shell_quote(target_dir)} -- mcp serve --port \{port}"
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
  let mcp_url = @mcp_core.mcp_url(port)
  {
    "schemaVersion": "cogna-mcp-descriptor/v1",
    "name": "cogna-mcp",
    "protocolVersion": "2025-11-25",
    "transport": "streamable-http",
    "port": port,
    "pid": pid_json(pid),
    "baseUrl": base_url,
    "mcpUrl": mcp_url,
    "command": native_serve_command(port),
    "bundleResolved": bundle_resolved,
    "initializeResult": @mcp_core.initialize_result(),
    "tools": tool_definitions(),
  }
}

///|
fn write_mcp_info(path : String, info : Json) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, info.stringify(indent=2)) catch {
    err =>
      return Err(
        mcp_error("cannot write descriptor \{path}: \{@debug.to_repr(err)}"),
      )
  }
  Ok(())
}

///|
fn read_mcp_info(path : String) -> Result[McpDescriptor, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(
        mcp_error("cannot read descriptor \{path}: \{@debug.to_repr(err)}"),
      )
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(info) else {
    return Err(mcp_error("descriptor is not valid json: \{path}"))
  }
  Ok({ path, info })
}

///|
fn descriptor_pid(info : Json) -> Int? {
  guard info is Object(object) else { return None }
  match object.get("pid") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}

///|
fn descriptor_port(info : Json) -> Int? {
  guard info is Object(object) else { return None }
  match object.get("port") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}

///|
fn descriptor_string(info : Json, field : String) -> String? {
  guard info is Object(object) else { return None }
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
}

///|
fn descriptor_mcp_url(info : Json, port : Int) -> String {
  match descriptor_string(info, "mcpUrl") {
    Some(url) => url
    None => @mcp_core.mcp_url(port)
  }
}

///|
fn wait_for_server_ready(
  url : String,
  attempts? : Int = 20,
  sleep_ms? : Int = 100,
) -> Bool {
  let payload =
    #|{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"cogna-cli","version":"0.1.0"}}}
    #|
  for _ in 0..<attempts {
    let status : Ref[Int?] = Ref::new(None)
    @mbasync.run_async_main(() => {
      try {
        let client = @http.Client::new(url)
        client.request(@http.RequestMethod::Post, "/", extra_headers={
          "Content-Type": "application/json",
        })
        client.write(payload)
        let response = client.end_request()
        client.close()
        status.val = Some(response.code)
      } catch {
        _ => ()
      }
    })
    if status.val == Some(200) {
      return true
    }
    @process.sleep_ms(sleep_ms)
  }
  false
}

///|
fn wait_for_process_boot(
  pid : Int,
  attempts? : Int = 30,
  sleep_ms? : Int = 100,
) -> Bool {
  for _ in 0..<attempts {
    if @process.is_alive(pid) {
      return true
    }
    @process.sleep_ms(sleep_ms)
  }
  false
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
    if !@process.is_alive(pid) {
      return true
    }
    @process.sleep_ms(100)
  }
  false
}

///|
fn spawn_detached_server_process(port : Int) -> Result[Int, @cli.CliError] {
  let command = native_serve_command(port)
  let spawn_out = @process.spawn_detached(command)
  guard spawn_out is Ok(pid) else {
    return Err(mcp_error(spawn_out.unwrap_err()))
  }
  Ok(pid)
}

///|
fn stop_process_if_alive(pid : Int) -> Unit {
  if @process.is_alive(pid) {
    ignore(@process.terminate(pid))
    if !wait_for_process_stop(pid) {
      ignore(@process.force_kill(pid))
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
  if !wait_for_process_boot(pid) {
    stop_process_if_alive(pid)
    return Err(mcp_error("MCP server did not stay alive after start"))
  }
  let info_path = descriptor_path()
  let write_out = write_runtime_state_with_pid(info_path, params.port, pid)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  let sync_out = sync_tools_state()
  guard sync_out is Ok(_) else { return Err(sync_out.unwrap_err()) }
  @mcp_core.clear_runtime_state()

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
    let port = descriptor_port(descriptor.info).unwrap_or(0)
    let mcp_url = descriptor_mcp_url(descriptor.info, port)
    match descriptor_pid(descriptor.info) {
      Some(pid) => {
        let healthy = wait_for_server_ready(mcp_url, attempts=50, sleep_ms=100)
        if @process.is_alive(pid) && healthy {
          Ok({
            status: "running",
            summary: "MCP server healthy at \{mcp_url} with live pid \{pid}",
          })
        } else {
          Ok({
            status: "stopped",
            summary: "MCP descriptor found at \{info_path} but server is not healthy (pid \{pid})",
          })
        }
      }
      None =>
        if wait_for_server_ready(mcp_url, attempts=1, sleep_ms=0) {
          Ok({ status: "running", summary: "MCP server healthy at \{mcp_url}" })
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
  @mcp_core.clear_runtime_state()
  if @fs.path_exists(info_path) {
    let info_out = read_mcp_info(info_path)
    guard info_out is Ok(descriptor) else { return Err(info_out.unwrap_err()) }
    match descriptor_pid(descriptor.info) {
      Some(pid) => stop_process_if_alive(pid)
      None => ()
    }
    @fs.remove_file(info_path) catch {
      err =>
        return Err(mcp_error("cannot remove \{info_path}: \{@debug.to_repr(err)}"))
    }
    if @fs.path_exists(state_path) {
      @fs.remove_file(state_path) catch {
        err =>
          return Err(
            mcp_error("cannot remove \{state_path}: \{@debug.to_repr(err)}"),
          )
      }
    }
    Ok({ summary: "Removed MCP descriptor at \{info_path}" })
  } else {
    if @fs.path_exists(state_path) {
      @fs.remove_file(state_path) catch {
        err =>
          return Err(
            mcp_error("cannot remove \{state_path}: \{@debug.to_repr(err)}"),
          )
      }
    }
    Ok({ summary: "MCP already stopped (no descriptor at \{info_path})" })
  }
}
