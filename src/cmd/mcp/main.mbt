///|
pub(all) struct McpStartParams {
  port : Int
} derive(Show, Eq)

///|
pub(all) struct McpStartResult {
  port : Int
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for McpStartResult with display(self : McpStartResult) -> String {
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
fn tool_outlines_definition() -> Json {
  {
    "name": "codeiq.query.outlines",
    "description": "List high-level outlines for a local CIQ bundle",
    "inputSchema": {
      "type": "object",
      "required": ["purl"],
      "properties": {
        "purl": { "type": "string" },
        "limit": { "type": "integer" },
        "cursor": { "type": "string" },
      },
      "additionalProperties": false,
    },
  }
}

///|
fn tool_symbol_definition() -> Json {
  {
    "name": "codeiq.query.symbol",
    "description": "Query declaration details by selector",
    "inputSchema": {
      "type": "object",
      "required": ["purl", "selector"],
      "properties": {
        "purl": { "type": "string" },
        "selector": { "type": "string" },
        "kind": { "type": "string" },
        "intent": { "type": "string" },
      },
      "additionalProperties": false,
    },
  }
}

///|
fn tool_definitions() -> Array[Json] {
  [tool_outlines_definition(), tool_symbol_definition()]
}

///|
fn initialize_result() -> Json {
  {
    "protocolVersion": "2025-11-25",
    "capabilities": { "tools": { "listChanged": false } },
    "serverInfo": { "name": "codeiq-mcp", "version": "0.1.0" },
    "instructions": "Use tools/list then tools/call with local CIQ bundle references.",
  }
}

///|
fn mcp_server_info(port : Int) -> Json {
  {
    "schemaVersion": "codeiq-mcp-descriptor/v1",
    "name": "codeiq-mcp",
    "protocolVersion": "2025-11-25",
    "transport": "stdio",
    "port": port,
    "initializeResult": initialize_result(),
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
fn request_id(request : Json) -> Json {
  guard request is Object(request_object) else { return Json::null() }
  match request_object.get("id") {
    Some(id) => id
    _ => Json::null()
  }
}

///|
fn jsonrpc_success(id : Json, result : Json) -> Json {
  { "jsonrpc": "2.0", "id": id, "result": result }
}

///|
fn jsonrpc_error(id : Json, code : Int, message : String) -> Json {
  {
    "jsonrpc": "2.0",
    "id": id,
    "error": ({ "code": code, "message": message } : Json),
  }
}

///|
fn get_required_string(
  args : Map[String, Json],
  key : String,
) -> Result[String, String] {
  match args.get(key) {
    Some(String(value)) => Ok(value)
    _ => Err("missing required string argument \{key}")
  }
}

///|
fn call_result(text : String, structured : Json, is_error : Bool) -> Json {
  {
    "content": [{ "type": "text", "text": text }],
    "structuredContent": structured,
    "isError": is_error,
  }
}

///|
fn run_outlines_tool(args : Map[String, Json]) -> Result[Json, String] {
  let purl_out = get_required_string(args, "purl")
  guard purl_out is Ok(purl) else { return Err(purl_out.unwrap_err()) }

  let outlines : Array[Json] = [
    {
      "path": "example::module::symbol",
      "kind": "function",
      "summary": "Placeholder outline from local CIQ bundle cache",
    },
  ]
  Ok(
    call_result(
      "Returned \{outlines.length()} outline(s) for \{purl}",
      { "purl": purl, "outlines": outlines, "nextCursor": Json::null() },
      false,
    ),
  )
}

///|
fn run_symbol_tool(args : Map[String, Json]) -> Result[Json, String] {
  let purl_out = get_required_string(args, "purl")
  guard purl_out is Ok(purl) else { return Err(purl_out.unwrap_err()) }
  let selector_out = get_required_string(args, "selector")
  guard selector_out is Ok(selector) else {
    return Err(selector_out.unwrap_err())
  }

  let kind = match args.get("kind") {
    Some(String(value)) => value
    _ => "symbol"
  }

  Ok(
    call_result(
      "Resolved selector \{selector} for \{purl}",
      {
        "schemaVersion": "ciq-result/v1",
        "purl": purl,
        "matches": [
          {
            "id": "decl:skeleton:\{selector}",
            "kind": kind,
            "signature": "placeholder signature",
            "location": {
              "uri": "dist/symbols.ndjson.zst",
              "startLine": 1,
              "endLine": 1,
            },
          },
        ],
      },
      false,
    ),
  )
}

///|
fn handle_tool_call(params : Json) -> Result[Json, (Int, String)] {
  guard params is Object(params_object) else {
    return Err((-32602, "tools/call params must be an object"))
  }
  guard params_object.get("name") is Some(String(name)) else {
    return Err((-32602, "tools/call missing tool name"))
  }

  let args : Map[String, Json] = match params_object.get("arguments") {
    Some(Object(arguments)) => arguments
    Some(Null) => {}
    None => {}
    _ => return Err((-32602, "tools/call arguments must be an object"))
  }

  match name {
    "codeiq.query.outlines" =>
      match run_outlines_tool(args) {
        Ok(result) => Ok(result)
        Err(message) => Err((-32602, message))
      }
    "codeiq.query.symbol" =>
      match run_symbol_tool(args) {
        Ok(result) => Ok(result)
        Err(message) => Err((-32602, message))
      }
    _ => Err((-32601, "unknown tool: \{name}"))
  }
}

///|
pub fn handle_request(request : Json) -> Json {
  let id = request_id(request)
  guard request is Object(request_object) else {
    return jsonrpc_error(id, -32600, "invalid request: expected object")
  }
  guard request_object.get("method") is Some(String(method_name)) else {
    return jsonrpc_error(id, -32600, "invalid request: missing method")
  }

  let params : Json = match request_object.get("params") {
    Some(value) => value
    _ => Json::object({})
  }

  match method_name {
    "initialize" => jsonrpc_success(id, initialize_result())
    "ping" => jsonrpc_success(id, Json::object({}))
    "tools/list" => jsonrpc_success(id, { "tools": tool_definitions() })
    "tools/call" =>
      match handle_tool_call(params) {
        Ok(result) => jsonrpc_success(id, result)
        Err((code, message)) => jsonrpc_error(id, code, message)
      }
    _ => jsonrpc_error(id, -32601, "method not found: \{method_name}")
  }
}

///|
pub fn run_start(
  params : McpStartParams,
) -> @cli.CliResult[McpStartResult, @cli.CliError] {
  let port_out = validate_port(params.port)
  guard port_out is Ok(_) else { return Err(port_out.unwrap_err()) }

  if !@fs.path_exists("./dist") {
    @fs.create_dir("./dist") catch {
      err =>
        return Err(
          mcp_error("cannot create ./dist directory: \{err.to_string()}"),
        )
    }
  }

  let info_path = "./dist/mcp-server.json"
  let write_out = write_mcp_info(info_path, mcp_server_info(params.port))
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    port: params.port,
    summary: "Generated MCP server descriptor at \{info_path} (port \{params.port})",
  })
}
