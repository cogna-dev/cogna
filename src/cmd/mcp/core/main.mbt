///|
fn mcp_error(message : String) -> @cli.CliError {
  @cli.command_error("mcp failed: \{message}")
}

///|
pub(all) struct McpServeParams {
  port : Int
} derive(Show, Eq)

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
pub fn tool_definitions() -> Array[Json] {
  [
    {
      "name": "codeiq.query.outlines",
      "title": "Browse public outlines",
      "description": "Return public declaration outlines for a bundle PURL.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "purl": { "type": "string", "description": "Bundle package URL." },
          "limit": {
            "type": "integer",
            "description": "Maximum outline rows to return.",
          },
          "cursor": {
            "type": "string",
            "description": "Pagination cursor from a previous outlines call.",
          },
        },
        "required": ["purl"],
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "purl": { "type": "string" },
          "limit": { "type": "integer" },
          "cursor": { "type": ["string", "null"] },
          "outlines": { "type": "array" },
          "nextCursor": { "type": ["string", "null"] },
          "runtime": { "type": "object" },
        },
        "required": ["purl", "outlines", "runtime"],
      },
    },
    {
      "name": "codeiq.query.symbol",
      "title": "Resolve declaration details",
      "description": "Return structured declaration details for a selector within a bundle.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "purl": { "type": "string", "description": "Bundle package URL." },
          "selector": {
            "type": "string",
            "description": "Canonical declaration selector or path.",
          },
          "kind": {
            "type": "string",
            "description": "Optional declaration kind hint.",
          },
          "intent": {
            "type": "string",
            "description": "Caller intent label for downstream consumers.",
          },
        },
        "required": ["purl", "selector"],
      },
      "outputSchema": {
        "type": "object",
        "properties": {
          "schemaVersion": { "type": "string" },
          "purl": { "type": "string" },
          "intent": { "type": "string" },
          "source": { "type": "string" },
          "matches": { "type": "array" },
          "runtime": { "type": "object" },
        },
        "required": ["schemaVersion", "purl", "source", "matches", "runtime"],
      },
    },
    {
      "name": "codeiq.runtime.context",
      "title": "Inspect runtime context",
      "description": "Return the in-memory MCP runtime request snapshot.",
      "inputSchema": { "type": "object", "properties": {} },
      "outputSchema": {
        "type": "object",
        "properties": { "activeRequests": { "type": "array" } },
        "required": ["activeRequests"],
      },
    },
  ]
}

///|
pub fn sync_tools_state() -> Result[Bool, @cli.CliError] {
  let out = @mcp_sdk.sync_tools_state(tool_definitions())
  guard out is Ok(changed) else { return Err(mcp_error(out.unwrap_err())) }
  Ok(changed)
}

///|
fn sync_tools_state_text() -> Result[Bool, String] {
  let out = sync_tools_state()
  guard out is Ok(changed) else { return Err(out.unwrap_err().to_string()) }
  Ok(changed)
}

///|
pub fn initialize_result() -> Json {
  {
    "protocolVersion": "2025-11-25",
    "capabilities": { "tools": { "listChanged": true } },
    "serverInfo": { "name": "codeiq-mcp", "version": "0.1.0" },
    "instructions": "Use tools/list then tools/call with local CIQ bundle references.",
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
fn query_repo_by_purl(purl : String) -> String {
  let purl_key = purl
    .replace_all(old=":", new="_")
    .replace_all(old="/", new="_")
    .replace_all(old="@", new="_")
  let cache_dir = ".codeiq/cache/mcp/\{purl_key}"
  if @fs.path_exists("\{cache_dir}/manifest.json") {
    return cache_dir
  }
  let cwd = @env.current_dir().unwrap_or(".")
  let manifest_path = "\{cwd}/dist/manifest.json"
  if @fs.path_exists(manifest_path) {
    let manifest_text = @fs.read_file_to_string(manifest_path) catch { _ => "" }
    let manifest_out = try? @json.parse(manifest_text)
    if manifest_out is Ok(Object(manifest)) {
      match manifest.get("purl") {
        Some(String(found)) if found == purl => return cwd
        _ => ()
      }
    }
  }
  cwd
}

///|
fn run_outlines_tool_with_context(
  args : Map[String, Json],
  context : @mcp_sdk.RequestContext,
  cancelled : () -> Bool,
) -> Result[Json, String] {
  if cancelled() {
    return Err("request cancelled")
  }
  let purl_out = @mcp_sdk.get_required_string(args, "purl")
  guard purl_out is Ok(purl) else { return Err(purl_out.unwrap_err()) }

  let limit = match @mcp_sdk.get_optional_int(args, "limit") {
    Some(value) => value
    None => 20
  }
  let cursor = @mcp_sdk.get_optional_string(args, "cursor")
  let repo = query_repo_by_purl(purl)
  let outlines_out = @query_cmd.query_outlines_with_cancel(
    repo, purl, limit, cursor, cancelled,
  )
  guard outlines_out is Ok((outlines, next_cursor_str)) else {
    return Err(outlines_out.unwrap_err())
  }
  if cancelled() {
    return Err("request cancelled")
  }
  let next_cursor : Json = match next_cursor_str {
    Some(value) => Json::string(value)
    None => Json::null()
  }
  let cursor_text = match cursor {
    Some(value) => value
    None => ""
  }

  let deadline_ms : Json = match context.deadline_ms {
    Some(value) =>
      Json::number(value.to_int().to_double(), repr="\{value.to_int()}")
    None => Json::null()
  }

  Ok(
    @mcp_sdk.call_result(
      "Returned \{outlines.length()} outline(s) for \{purl}",
      {
        "purl": purl,
        "limit": limit,
        "cursor": cursor_text,
        "outlines": outlines,
        "nextCursor": next_cursor,
        "runtime": {
          "requestId": context.request_id,
          "startedAtMs": context.started_at_ms.to_int(),
          "deadlineMs": deadline_ms,
        },
      },
      false,
    ),
  )
}

///|
fn run_symbol_tool_with_context(
  args : Map[String, Json],
  context : @mcp_sdk.RequestContext,
  cancelled : () -> Bool,
) -> Result[Json, String] {
  if cancelled() {
    return Err("request cancelled")
  }
  let purl_out = @mcp_sdk.get_required_string(args, "purl")
  guard purl_out is Ok(purl) else { return Err(purl_out.unwrap_err()) }
  let selector_out = @mcp_sdk.get_required_string(args, "selector")
  guard selector_out is Ok(selector) else {
    return Err(selector_out.unwrap_err())
  }

  let kind = match args.get("kind") {
    Some(String(value)) => value
    _ => "symbol"
  }
  let intent = match args.get("intent") {
    Some(String(value)) => value
    _ => "lookup"
  }

  let repo = query_repo_by_purl(purl)
  let matches_out = @query_cmd.query_matches_with_cancel(
    repo, selector, kind, cancelled,
  )
  guard matches_out is Ok(matches) else { return Err(matches_out.unwrap_err()) }
  if cancelled() {
    return Err("request cancelled")
  }
  let deadline_ms : Json = match context.deadline_ms {
    Some(value) =>
      Json::number(value.to_int().to_double(), repr="\{value.to_int()}")
    None => Json::null()
  }
  let structured : Json = {
    "schemaVersion": "ciq-result/v1",
    "purl": purl,
    "intent": intent,
    "source": "bundle",
    "matches": matches,
    "runtime": {
      "requestId": context.request_id,
      "startedAtMs": context.started_at_ms.to_int(),
      "deadlineMs": deadline_ms,
    },
  }
  Ok(
    @mcp_sdk.call_result(
      "Resolved selector \{selector} for \{purl} with \{matches.length()} match(es)",
      structured,
      false,
    ),
  )
}

///|
fn run_runtime_context_tool() -> Result[Json, String] {
  Ok(
    @mcp_sdk.call_result(
      "Returned MCP runtime context snapshot",
      @mcp_sdk.runtime_context_snapshot(),
      false,
    ),
  )
}

///|
fn handle_tool_call(
  params : Json,
  context : @mcp_sdk.RequestContext,
  cancelled : () -> Bool,
) -> Result[Json, (Int, String)] {
  let parsed_out = @mcp_sdk.parse_tool_call(params)
  guard parsed_out is Ok((name, args)) else {
    return Err(parsed_out.unwrap_err())
  }
  match name {
    "codeiq.query.outlines" =>
      match run_outlines_tool_with_context(args, context, cancelled) {
        Ok(result) => Ok(result)
        Err(message) => Err((-32603, message))
      }
    "codeiq.query.symbol" =>
      match run_symbol_tool_with_context(args, context, cancelled) {
        Ok(result) => Ok(result)
        Err(message) => Err((-32603, message))
      }
    "codeiq.runtime.context" =>
      match run_runtime_context_tool() {
        Ok(result) => Ok(result)
        Err(message) => Err((-32603, message))
      }
    _ => Err((-32601, "unknown tool: \{name}"))
  }
}

///|
pub fn handle_request(request : Json) -> Json {
  @mcp_sdk.handle_standard_request(
    request,
    initialize_result(),
    {
      "status": "ok",
      "localArtifacts": {
        "queryResult": local_query_result() is Some(_),
        "sarif": local_sarif() is Some(_),
      },
    },
    tool_definitions(),
    sync_tools_state_text,
    handle_tool_call,
  )
}

///|
pub fn serve_stdio_once(line : String) -> String {
  @mcp_sdk.serve_stdio_once(line, handle_request)
}

///|
pub fn run_stdio_repl() -> Unit {
  @mcp_sdk.run_stdio_repl(handle_request)
}

///|
pub fn health_path() -> String {
  "/health"
}

///|
pub fn rpc_path() -> String {
  "/rpc"
}

///|
pub fn base_url(port : Int) -> String {
  "http://127.0.0.1:\{port}"
}

///|
pub fn health_url(port : Int) -> String {
  @server_runtime.join_url(base_url(port), health_path())
}

///|
pub fn rpc_url(port : Int) -> String {
  @server_runtime.join_url(base_url(port), rpc_path())
}

///|
fn parse_http_request(body : Bytes) -> Result[Json, String] {
  let text = @utf8.decode(body) catch {
    _ => return Err("http request body is not valid utf-8")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(request) else {
    return Err("http request body is not valid json")
  }
  Ok(request)
}

///|
pub fn handle_http_request(
  http_method : String,
  path : String,
  headers : Map[String, String],
  body : Bytes,
) -> Result[@server_runtime.HttpResponse, String] {
  ignore(headers)
  match path {
    "/health" =>
      if http_method == "GET" {
        Ok(
          @server_runtime.json_response(200, {
            "status": "ok",
            "name": "codeiq-mcp",
            "protocolVersion": "2025-11-25",
          }),
        )
      } else {
        Ok(@server_runtime.text_response(405, "method not allowed"))
      }
    "/rpc" =>
      if http_method == "POST" {
        let request_out = parse_http_request(body)
        guard request_out is Ok(request) else {
          return Ok(
            @server_runtime.json_response(
              400,
              @mcp_sdk.error_response(
                Json::null(),
                -32700,
                request_out.unwrap_err(),
              ),
            ),
          )
        }
        Ok(@server_runtime.json_response(200, handle_request(request)))
      } else {
        Ok(@server_runtime.text_response(405, "method not allowed"))
      }
    _ => Ok(@server_runtime.text_response(404, "not found"))
  }
}

///|
pub fn run_serve(
  params : McpServeParams,
) -> @cli.CliResult[Unit, @cli.CliError] {
  let port_out = validate_port(params.port)
  guard port_out is Ok(_) else { return Err(port_out.unwrap_err()) }
  let dist_out = ensure_dist_dir()
  guard dist_out is Ok(_) else { return Err(dist_out.unwrap_err()) }
  let sync_out = sync_tools_state()
  guard sync_out is Ok(_) else { return Err(sync_out.unwrap_err()) }
  @mcp_sdk.clear_runtime_state()
  let serve_out = @server_runtime.serve_http(params.port, handle_http_request)
  guard serve_out is Ok(_) else {
    return Err(mcp_error(serve_out.unwrap_err()))
  }
  Ok(())
}
