///|
pub fn tool_outlines_definition() -> Json {
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
    "outputSchema": {
      "type": "object",
      "required": ["purl", "outlines", "nextCursor"],
      "properties": {
        "purl": { "type": "string" },
        "limit": { "type": "integer" },
        "cursor": { "type": "string" },
        "outlines": { "type": "array" },
        "nextCursor": { "oneOf": [{ "type": "string" }, { "type": "null" }] },
      },
      "additionalProperties": true,
    },
  }
}

///|
pub fn tool_symbol_definition() -> Json {
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
    "outputSchema": {
      "type": "object",
      "required": ["schemaVersion", "purl", "source", "matches"],
      "properties": {
        "schemaVersion": { "type": "string" },
        "purl": { "type": "string" },
        "intent": { "type": "string" },
        "source": { "type": "string" },
        "matches": { "type": "array" },
      },
      "additionalProperties": true,
    },
  }
}

///|
pub fn tool_runtime_context_definition() -> Json {
  {
    "name": "codeiq.runtime.context",
    "description": "Inspect active MCP request runtime context for diagnostics",
    "inputSchema": {
      "type": "object",
      "properties": {},
      "additionalProperties": false,
    },
    "outputSchema": {
      "type": "object",
      "required": ["activeRequests"],
      "properties": { "activeRequests": { "type": "array" } },
      "additionalProperties": true,
    },
  }
}

///|
pub fn tool_definitions() -> Array[Json] {
  [
    tool_outlines_definition(),
    tool_symbol_definition(),
    tool_runtime_context_definition(),
  ]
}

///|
pub fn tools_fingerprint() -> String {
  ({ "tools": tool_definitions() } : Json).stringify(indent=0)
}

///|
pub fn tools_state_path() -> String {
  "./dist/mcp-tools-state.json"
}

///|
pub fn read_tools_fingerprint(path : String) -> String? {
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
pub fn write_tools_state(
  path : String,
  fingerprint : String,
) -> Result[Unit, String] {
  let tool_count = tool_definitions().length()
  let state : Json = {
    "schemaVersion": "codeiq-mcp-tools-state/v1",
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
pub fn sync_tools_state(dist_path? : String = "./dist") -> Result[Bool, String] {
  if !@fs.path_exists(dist_path) {
    @fs.create_dir(dist_path) catch {
      err =>
        return Err("cannot create \{dist_path} directory: \{err.to_string()}")
    }
  }
  let state_path = if dist_path == "./dist" {
    tools_state_path()
  } else {
    "\{dist_path}/mcp-tools-state.json"
  }
  let current = tools_fingerprint()
  let previous = read_tools_fingerprint(state_path)
  if previous is Some(value) && value == current {
    return Ok(false)
  }
  let write_out = write_tools_state(state_path, current)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  Ok(true)
}
