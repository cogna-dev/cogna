///|
fn parent_dir(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() <= 1 {
    "."
  } else {
    let mut out = ""
    for i in 0..<(parts.length() - 1) {
      if i > 0 {
        out = "\{out}/"
      }
      out = "\{out}\{parts[i]}"
    }
    if out == "" {
      "."
    } else {
      out
    }
  }
}

///|
fn ensure_dir(path : String) -> Unit raise @fs.IOError {
  if !@fs.path_exists(path) {
    @fs.create_dir(path)
  }
}

///|
fn ensure_nested_dir(path : String) -> Unit raise @fs.IOError {
  let parts = path.split("/").to_array()
  let mut current = if path.has_prefix("/") { "/" } else { "" }
  for i in 0..<parts.length() {
    let segment = parts[i].to_string()
    if segment == "" || segment == "." {
      continue
    }
    current = if current == "" || current == "/" {
      if current == "/" {
        "/\{segment}"
      } else {
        segment
      }
    } else {
      "\{current}/\{segment}"
    }
    ensure_dir(current)
  }
}

///|
fn policy_dir_for_config(path : String) -> String {
  let root = parent_dir(path)
  if root == "." {
    "./.cogna/policies"
  } else {
    "\{root}/.cogna/policies"
  }
}

///|
pub fn write_config(path : String) -> String raise @fs.IOError {
  @fs.write_string_to_file(path, default_config_yaml())
  let policy_dir = policy_dir_for_config(path)
  ensure_nested_dir(policy_dir)
  let builtin_policy = @policy.builtin_rego_text()
  @fs.write_string_to_file("\{policy_dir}/compat.rego", builtin_policy)
  policy_dir
}
