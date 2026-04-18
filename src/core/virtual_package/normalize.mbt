///|
fn normalized_separators(path : String) -> String {
  path.replace_all(old="\\", new="/")
}

///|
pub fn trim_relative_prefix(path : String) -> String {
  let mut out = normalized_separators(path).trim().to_string()
  while out.has_prefix("./") {
    out = out[2:].to_string()
  }
  if out == "." {
    ""
  } else {
    out
  }
}

///|
pub fn normalize_path(path : String) -> Result[String, String] {
  let trimmed = trim_relative_prefix(path)
  if trimmed == "" {
    return Err("path must not be empty")
  }
  if trimmed.has_prefix("/") {
    return Err("path must be relative: \{path}")
  }
  let parts = trimmed.split("/").to_array()
  let normalized : Array[String] = []
  for i in 0..<parts.length() {
    let part = parts[i].to_string()
    if part == "" || part == "." {
      continue
    }
    if part == ".." {
      return Err("path must not escape package root: \{path}")
    }
    normalized.push(part)
  }
  if normalized.is_empty() {
    return Err("path must not be empty")
  }
  Ok(normalized.join("/"))
}

///|
pub fn path_has_prefix(path : String, prefix : String) -> Bool {
  if prefix == "" {
    return true
  }
  path == prefix || path.has_prefix("\{prefix}/")
}

///|
pub fn strip_root_prefix(path : String, root_prefix : String) -> Result[String, String] {
  let path_out = normalize_path(path)
  guard path_out is Ok(normalized_path) else { return Err(path_out.unwrap_err()) }
  let prefix_out = normalize_path(root_prefix)
  guard prefix_out is Ok(normalized_prefix) else {
    return Err(prefix_out.unwrap_err())
  }
  if normalized_path == normalized_prefix {
    return Err("path points to package root: \{path}")
  }
  if !path_has_prefix(normalized_path, normalized_prefix) {
    return Err("path is not under root prefix \{normalized_prefix}: \{path}")
  }
  Ok(normalized_path[normalized_prefix.length() + 1:].to_string())
}

///|
pub fn first_path_segment(path : String) -> String {
  let normalized_out = normalize_path(path)
  guard normalized_out is Ok(normalized) else { return "" }
  match normalized.find("/") {
    Some(idx) => normalized[0:idx].to_string()
    None => normalized
  }
}
