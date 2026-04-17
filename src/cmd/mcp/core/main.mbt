///|
fn mcp_error(message : String) -> @cli.CliError {
  @cli.command_error("mcp failed: \{message}")
}

///|
pub(all) struct McpServeParams {
  port : Int
} derive(Eq)

///|
pub impl Show for McpServeParams with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_char('}')
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
fn descriptor_path() -> String {
  "./dist/mcp-server.json"
}

///|
fn write_descriptor(path : String, info : Json) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, info.stringify(indent=2)) catch {
    err =>
      return Err(
        mcp_error("cannot write descriptor \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
fn cleanup_descriptor(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
pub fn mcp_path() -> String {
  "/mcp"
}

///|
pub fn base_url(port : Int) -> String {
  "http://127.0.0.1:\{port}"
}

///|
pub fn mcp_url(port : Int) -> String {
  "\{base_url(port)}\{mcp_path()}"
}

///|
pub fn tool_definitions() -> Array[Json] {
  [tool_json("fetch_packages"), tool_json("query_outlines"), tool_json("query")]
}

///|
fn tool_json(name : String) -> Json {
  match name {
    "fetch_packages" =>
      {
        "name": "fetch_packages",
        "title": "Fetch related packages",
        "description": "Return the package tree for the current project context using implicit project and SBOM context.",
        "inputSchema": { "type": "object", "properties": {} },
      }
    "query_outlines" =>
      {
        "name": "query_outlines",
        "title": "Browse public API outlines",
        "description": "Return public API outlines for a package from the current project context. Use package names from fetch_packages.",
        "inputSchema": {
          "type": "object",
          "properties": {
            "package": {
              "type": "string",
              "description": "Package name to browse. Usually selected from fetch_packages.",
            },
          },
          "required": ["package"],
        },
      }
    _ =>
      {
        "name": "query",
        "title": "Query package API",
        "description": "Search a package API by exact id, exact symbol, or fuzzy text. Exactly one of exact_id, exact_symbol, or text should be provided.",
        "inputSchema": {
          "type": "object",
          "properties": {
            "package": {
              "type": "string",
              "description": "Package name to query.",
            },
            "exact_id": {
              "type": "string",
              "description": "Exact stable declaration id to resolve.",
            },
            "exact_symbol": {
              "type": "string",
              "description": "Exact symbol or canonical path to resolve.",
            },
            "text": {
              "type": "string",
              "description": "Fuzzy text query for ranked search.",
            },
            "limit": {
              "type": "integer",
              "description": "Maximum number of matches to return.",
            },
            "cursor": {
              "type": "string",
              "description": "Pagination cursor for a follow-up query.",
            },
          },
          "required": ["package"],
        },
      }
  }
}

///|
fn tool_input_schema(name : String) -> @mcp_types.ToolInputSchema {
  match tool_json(name) {
    Object(object) =>
      match object.get("inputSchema") {
        Some(schema) => @mcp_types.ToolInputSchema::with_schema(schema)
        None => @mcp_types.ToolInputSchema::empty()
      }
    _ => @mcp_types.ToolInputSchema::empty()
  }
}

///|
fn tools_fingerprint(tools : Array[Json]) -> String {
  ({ "tools": tools } : Json).stringify(indent=0)
}

///|
pub fn tools_state_path(dist_path? : String = "./dist") -> String {
  "\{dist_path}/mcp-tools-state.json"
}

///|
fn read_tools_fingerprint(path : String) -> String? {
  if !@fs.path_exists(path) {
    return None
  }
  let text = @fs.read_file_to_string(path) catch { _ => return None }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(object)) else { return None }
  match object.get("fingerprint") {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
}

///|
fn write_tools_state(
  path : String,
  fingerprint : String,
  tool_count : Int,
) -> Result[Unit, String] {
  let state : Json = {
    "schemaVersion": "cogna-mcp-tools-state/v1",
    "fingerprint": fingerprint,
    "toolCount": tool_count,
  }
  @fs.write_string_to_file(path, state.stringify(indent=2)) catch {
    err =>
      return Err("cannot write mcp tools state \{path}: \{err.to_string()}")
  }
  Ok(())
}

///|
pub fn sync_tools_state() -> Result[Bool, @cli.CliError] {
  let dist_out = ensure_dist_dir()
  guard dist_out is Ok(_) else { return Err(dist_out.unwrap_err()) }
  let path = tools_state_path()
  let current = tools_fingerprint(tool_definitions())
  let previous = read_tools_fingerprint(path)
  if previous is Some(value) && value == current {
    return Ok(false)
  }
  let write_out = write_tools_state(path, current, tool_definitions().length())
  guard write_out is Ok(_) else {
    return Err(mcp_error(write_out.unwrap_err()))
  }
  Ok(true)
}

///|
pub fn clear_runtime_state() -> Unit {
  ()
}

///|
pub fn initialize_result() -> Json {
  {
    "protocolVersion": "2025-11-25",
    "capabilities": {
      "tools": { "listChanged": true },
      "resources": { "subscribe": true, "listChanged": true },
      "prompts": { "listChanged": true },
      "logging": {},
      "completions": {},
    },
    "serverInfo": { "name": "cogna-mcp", "version": "0.1.0" },
    "instructions": "Use standard MCP over HTTP/SSE at /mcp with local CIQ bundle references.",
  }
}

///|
fn server_info(port : Int) -> Json {
  {
    "schemaVersion": "cogna-mcp-descriptor/v1",
    "name": "cogna-mcp",
    "protocolVersion": "2025-11-25",
    "transport": "streamable-http",
    "port": port,
    "pid": Json::null(),
    "baseUrl": base_url(port),
    "mcpUrl": mcp_url(port),
    "bundleResolved": @fs.path_exists("./dist/manifest.json"),
    "initializeResult": initialize_result(),
    "tools": tool_definitions(),
  }
}

///|
fn get_required_string(args : Json?, key : String) -> Result[String, String] {
  match args {
    Some(Object(object)) =>
      match object.get(key) {
        Some(String(value)) => Ok(value)
        _ => Err("missing required string argument \{key}")
      }
    _ => Err("missing required string argument \{key}")
  }
}

///|
fn get_optional_string(args : Json?, key : String) -> String? {
  match args {
    Some(Object(object)) =>
      match object.get(key) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn get_optional_int(args : Json?, key : String) -> Int? {
  match args {
    Some(Object(object)) =>
      match object.get(key) {
        Some(Number(value, ..)) => Some(value.to_int())
        _ => None
      }
    _ => None
  }
}

///|
pub fn local_query_result() -> Json? {
  @bundle.read_local_query_result(".")
}

///|
pub fn local_sarif() -> Json? {
  @bundle.read_local_sarif(".")
}

///|
fn tool_text(text : String) -> @mcp_types.ContentBlock {
  @mcp_types.ContentBlock::Text({ text, })
}

///|
fn json_content_text(payload : Json) -> String {
  payload.stringify(indent=2)
}

///|
fn json_ok(summary : String, payload : Json) -> @mcp_types.ToolResult {
  @mcp_types.ToolResult::ok([
    tool_text(summary),
    tool_text(json_content_text(payload)),
  ])
}

///|
fn run_fetch_packages_tool(_args : Json?) -> @mcp_types.ToolResult {
  let payload = @query_core.fetch_packages_json()
  json_ok("Fetched package tree for the current project.", payload)
}

///|
fn run_query_outlines_tool(args : Json?) -> @mcp_types.ToolResult {
  let package_out = get_required_string(args, "package")
  guard package_out is Ok(pkg) else {
    return @mcp_types.ToolResult::error(package_out.unwrap_err())
  }
  let payload = @query_core.query_outlines_for_package(pkg)
  let outline_count = match payload {
    Object(obj) =>
      match obj.get("outlines") {
        Some(Array(items)) => items.length()
        _ => 0
      }
    _ => 0
  }
  json_ok(
    "Returned \{outline_count} public API outline(s) for package \{pkg}.",
    payload,
  )
}

///|
fn non_empty_selector_count(args : Json?) -> Int {
  let mut count = 0
  if get_optional_string(args, "exact_id") is Some(_) {
    count = count + 1
  }
  if get_optional_string(args, "exact_symbol") is Some(_) {
    count = count + 1
  }
  if get_optional_string(args, "text") is Some(_) {
    count = count + 1
  }
  count
}

///|
fn run_query_tool(args : Json?) -> @mcp_types.ToolResult {
  let package_out = get_required_string(args, "package")
  guard package_out is Ok(pkg) else {
    return @mcp_types.ToolResult::error(package_out.unwrap_err())
  }
  if non_empty_selector_count(args) != 1 {
    return @mcp_types.ToolResult::error(
      "exact_id, exact_symbol, and text must contain exactly one query selector.",
    )
  }
  let payload = @query_core.query_package(
    pkg,
    get_optional_string(args, "exact_id"),
    get_optional_string(args, "exact_symbol"),
    get_optional_string(args, "text"),
    get_optional_int(args, "limit"),
    get_optional_string(args, "cursor"),
  )
  let match_count = match payload {
    Object(obj) =>
      match obj.get("matches") {
        Some(Array(items)) => items.length()
        _ => 0
      }
    _ => 0
  }
  json_ok(
    "Returned \{match_count} query match(es) for package \{pkg}.",
    payload,
  )
}

///|
fn add_tools(server : @mcp_server.McpServer) -> Unit {
  server.add_tool(
    {
      name: "fetch_packages",
      description: Some(
        "Return the package tree for the current project context.",
      ),
      input_schema: tool_input_schema("fetch_packages"),
    },
    @mcp_server.ToolHandler(fn(args, _notify, _requester) {
      run_fetch_packages_tool(args)
    }),
  )
  server.add_tool(
    {
      name: "query_outlines",
      description: Some(
        "Return public API outlines for a package from the current project context.",
      ),
      input_schema: tool_input_schema("query_outlines"),
    },
    @mcp_server.ToolHandler(fn(args, _notify, _requester) {
      run_query_outlines_tool(args)
    }),
  )
  server.add_tool(
    {
      name: "query",
      description: Some(
        "Search a package by exact id, exact symbol, or fuzzy text.",
      ),
      input_schema: tool_input_schema("query"),
    },
    @mcp_server.ToolHandler(fn(args, _notify, _requester) {
      run_query_tool(args)
    }),
  )
}

///|
pub fn run_serve(
  params : McpServeParams,
) -> @cli.CliResult[Unit, @cli.CliError] {
  let port_out = validate_port(params.port)
  guard port_out is Ok(_) else { return Err(port_out.unwrap_err()) }
  let dist_out = ensure_dist_dir()
  guard dist_out is Ok(_) else { return Err(dist_out.unwrap_err()) }
  let descriptor = descriptor_path()
  let descriptor_out = write_descriptor(descriptor, server_info(params.port))
  guard descriptor_out is Ok(_) else { return Err(descriptor_out.unwrap_err()) }

  let result_ref : Ref[Result[Unit, String]?] = Ref::new(None)
  @mbasync.run_async_main(() => {
    let server = @mcp_server.McpServer::new("cogna-mcp", "0.1.0")
    add_tools(server)
    let out = try {
      server.serve(params.port)
      Ok(())
    } catch {
      err => Err(err.to_string())
    }
    result_ref.val = Some(out)
  })

  cleanup_descriptor(descriptor)
  match result_ref.val {
    Some(Ok(_)) => Ok(())
    Some(Err(message)) => Err(mcp_error(message))
    None => Err(mcp_error("standard MCP server did not produce result"))
  }
}
