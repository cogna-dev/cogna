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
fn detect_profile(root_dir : String) -> String {
  if @fs.path_exists("\{root_dir}/go.mod") {
    return "go-module"
  }
  if @fs.path_exists("\{root_dir}/Cargo.toml") {
    return "rust-crate"
  }
  if @fs.path_exists("\{root_dir}/main.tf") || @fs.path_exists("\{root_dir}/.terraform.lock.hcl") {
    return "terraform-module"
  }

  let entries = @fs.read_dir(root_dir) catch { _ => [] }
  let mut has_tf = false
  let mut has_openapi = false
  for i in 0..<entries.length() {
    let name = entries[i]
    if name.has_suffix(".tf") {
      has_tf = true
    }
    if name.has_suffix(".yaml") || name.has_suffix(".yml") {
      has_openapi = true
    }
  }

  if has_tf {
    return "terraform-module"
  }
  if @fs.path_exists("\{root_dir}/openapi") || has_openapi {
    return "openapi-spec"
  }

  "openapi-spec"
}

///|
pub fn write_config(path : String) -> String raise @fs.IOError {
  let root = parent_dir(path)
  let profile = detect_profile(root)
  @fs.write_string_to_file(path, default_config_yaml_for_profile(profile))
  let policy_dir = policy_dir_for_config(path)
  ensure_nested_dir(policy_dir)
  let builtin_policy = @policy.builtin_rego_text()
  @fs.write_string_to_file("\{policy_dir}/compat.rego", builtin_policy)
  policy_dir
}
