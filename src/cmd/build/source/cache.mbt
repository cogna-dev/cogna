///|
pub fn trimmed_env_path(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(raw) => {
      let value = raw.trim().to_string()
      if value == "" {
        None
      } else {
        Some(value)
      }
    }
    None => None
  }
}

///|
pub fn home_dir() -> String? {
  trimmed_env_path("HOME")
}

///|
pub fn resolve_path(workspace_root : String, child : String) -> String {
  if child == "" {
    workspace_root
  } else if child.has_prefix("/") {
    child
  } else if child.has_prefix("./") {
    "\{workspace_root}/\{child[2:].to_string()}"
  } else {
    "\{workspace_root}/\{child}"
  }
}
