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
  @mcp_sdk.tool_definitions()
}

///|
pub fn sync_tools_state() -> Result[Bool, @cli.CliError] {
  let out = @mcp_sdk.sync_tools_state()
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
  guard params is Object(params_object) else {
    return Err((-32602, "tools/call params must be an object"))
  }
  guard params_object.get("name") is Some(String(name)) else {
    return Err((-32602, "tools/call missing tool name"))
  }
  if name == "codeiq.runtime.context" {
    match run_runtime_context_tool() {
      Ok(result) => Ok(result)
      Err(message) => Err((-32603, message))
    }
  } else {
    @mcp_sdk.dispatch_tool_call(
      params,
      context,
      (args, request_context) => {
        run_outlines_tool_with_context(args, request_context, cancelled)
      },
      (args, request_context) => {
        run_symbol_tool_with_context(args, request_context, cancelled)
      },
    )
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
pub fn run_serve(params : McpServeParams) -> @cli.CliResult[Unit, @cli.CliError] {
  let port_out = validate_port(params.port)
  guard port_out is Ok(_) else { return Err(port_out.unwrap_err()) }
  let dist_out = ensure_dist_dir()
  guard dist_out is Ok(_) else { return Err(dist_out.unwrap_err()) }
  let sync_out = sync_tools_state()
  guard sync_out is Ok(_) else { return Err(sync_out.unwrap_err()) }
  @mcp_sdk.clear_runtime_state()
  run_stdio_repl()
  Ok(())
}
