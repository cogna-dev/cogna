///|
fn cargo_inline_string(spec : String, key : String) -> String? {
  let trimmed = @snapshot.trim_spaces(spec)
  if !trimmed.has_prefix("{") {
    return None
  }
  match trimmed.find(key) {
    Some(index) => {
      let segment = trimmed[index + key.length():].to_string()
      match segment.find("=") {
        Some(eq_index) => {
          let raw = segment[eq_index + 1:].to_string()
          let before_comma = match raw.find(",") {
            Some(comma_index) => raw[:comma_index].to_string()
            None => raw
          }
          let before_brace = match before_comma.find("}") {
            Some(brace_index) => before_comma[:brace_index].to_string()
            None => before_comma
          }
          let value = @snapshot.strip_wrapping_quotes(before_brace)
          if value == "" {
            None
          } else {
            Some(value)
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn cargo_lock_versions(repo : String) -> Result[Map[String, String], String] {
  let lock_path = @snapshot.join_path(repo, "Cargo.lock")
  if !@fs.path_exists(lock_path) {
    return Ok({})
  }
  let text = @fs.read_file_to_string(lock_path) catch {
    err => return Err("cannot read Cargo.lock: \{err.to_string()}")
  }
  let versions : Map[String, String] = {}
  let mut current_name : String? = None
  let mut current_version : String? = None
  let lines = text.split("\n").to_array()
  for i in 0..<lines.length() {
    let line = @snapshot.trim_spaces(lines[i].to_string())
    if line == "[[package]]" {
      if current_name is Some(name) &&
        current_version is Some(version) &&
        !versions.contains(name) {
        versions[name] = version
      }
      current_name = None
      current_version = None
      continue
    }
    if line.has_prefix("name =") {
      current_name = Some(@snapshot.strip_wrapping_quotes(line[6:].to_string()))
      continue
    }
    if line.has_prefix("version =") {
      current_version = Some(@snapshot.strip_wrapping_quotes(line[9:].to_string()))
    }
  }
  if current_name is Some(name) &&
    current_version is Some(version) &&
    !versions.contains(name) {
    versions[name] = version
  }
  Ok(versions)
}

///|
pub fn cargo_locked_versions(repo : String) -> Result[Map[String, String], String] {
  cargo_lock_versions(repo)
}

///|
fn cargo_home_dir() -> String? {
  match @snapshot.env_path("CARGO_HOME") {
    Some(path) => Some(path)
    None =>
      match @snapshot.home_dir() {
        Some(home) => Some(@snapshot.join_path(home, ".cargo"))
        None => None
      }
  }
}

///|
fn cargo_registry_dir(name : String, version : String) -> String? {
  match cargo_home_dir() {
    Some(home) => {
      let registry_root = @snapshot.join_path(
        @snapshot.join_path(home, "registry"),
        "src",
      )
      if !@snapshot.directory_exists(registry_root) {
        return None
      }
      let registries = @fs.read_dir(registry_root) catch { _ => return None }
      for i in 0..<registries.length() {
        let candidate = @snapshot.join_path(
          @snapshot.join_path(registry_root, registries[i]),
          "\{name}-\{version}",
        )
        if @snapshot.directory_exists(candidate) {
          return Some(candidate)
        }
      }
      None
    }
    None => None
  }
}

///|
fn cargo_vendor_dir(repo : String, name : String, version : String) -> String? {
  let vendor_root = @snapshot.join_path(repo, "vendor")
  if !@snapshot.directory_exists(vendor_root) {
    return None
  }
  let exact = @snapshot.join_path(vendor_root, name)
  if @snapshot.directory_exists(exact) {
    return Some(exact)
  }
  let versioned = @snapshot.join_path(vendor_root, "\{name}-\{version}")
  if @snapshot.directory_exists(versioned) {
    return Some(versioned)
  }
  None
}

///|
fn cargo_manifest_version(root_path : String) -> String? {
  let manifest_path = @snapshot.join_path(root_path, "Cargo.toml")
  if !@fs.path_exists(manifest_path) {
    return None
  }
  let text = @fs.read_file_to_string(manifest_path) catch { _ => return None }
  let lines = text.split("\n").to_array()
  let mut in_package = false
  for i in 0..<lines.length() {
    let line = @snapshot.trim_spaces(lines[i].to_string())
    if line == "" || line.has_prefix("#") {
      continue
    }
    if line.has_prefix("[") && line.has_suffix("]") {
      in_package = line == "[package]"
      continue
    }
    if in_package && line.has_prefix("version") {
      match line.find("=") {
        Some(eq_index) =>
          return Some(@snapshot.strip_wrapping_quotes(line[eq_index + 1:].to_string()))
        None => return None
      }
    }
  }
  None
}

///|
pub fn resolve_cargo_dependency(
  repo : String,
  name : String,
  spec : String,
  locked_version : String?,
) -> Result[@snapshot.ResolvedDependency, String] {
  match cargo_inline_string(spec, "path") {
    Some(local_path) => {
      let root_path = @snapshot.resolve_path(repo, local_path)
      if !@snapshot.directory_exists(root_path) {
        return Err(
          "local Cargo dependency \{name} not found at \{root_path}. Run `cargo fetch` or `cargo vendor`.",
        )
      }
      let version = match cargo_manifest_version(root_path) {
        Some(value) if value != "" => value
        _ =>
          match locked_version {
            Some(value) => value
            None => "0.0.0"
          }
      }
      return @snapshot.dependency_resolution(repo, "cargo", name, version, root_path)
    }
    None => ()
  }

  let version = match locked_version {
    Some(value) if value != "" => value
    _ =>
      match cargo_inline_string(spec, "version") {
        Some(value) if value != "" => value
        _ =>
          return Err(
            "Cargo dependency \{name} is missing a resolved version. Run `cargo fetch` or `cargo vendor`.",
          )
      }
  }
  let root_path = match cargo_vendor_dir(repo, name, version) {
    Some(path) => path
    None =>
      match cargo_registry_dir(name, version) {
        Some(path) => path
        None =>
          return Err(
            "Cargo dependency \{name}@\{version} is not available locally. Run `cargo fetch` or `cargo vendor`.",
          )
      }
  }
  @snapshot.dependency_resolution(repo, "cargo", name, version, root_path)
}
