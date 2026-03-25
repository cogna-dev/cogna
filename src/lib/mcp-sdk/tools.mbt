///|
pub fn tools_fingerprint(tools : Array[Json]) -> String {
  ({ "tools": tools } : Json).stringify(indent=0)
}

///|
pub fn tools_state_path(dist_path? : String = "./dist") -> String {
  "\{dist_path}/mcp-tools-state.json"
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
  tool_count : Int,
) -> Result[Unit, String] {
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
pub fn sync_tools_state(
  tools : Array[Json],
  dist_path? : String = "./dist",
) -> Result[Bool, String] {
  if !@fs.path_exists(dist_path) {
    @fs.create_dir(dist_path) catch {
      err =>
        return Err("cannot create \{dist_path} directory: \{err.to_string()}")
    }
  }
  let state_path = tools_state_path(dist_path~)
  let current = tools_fingerprint(tools)
  let previous = read_tools_fingerprint(state_path)
  if previous is Some(value) && value == current {
    return Ok(false)
  }
  let write_out = write_tools_state(state_path, current, tools.length())
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  Ok(true)
}
