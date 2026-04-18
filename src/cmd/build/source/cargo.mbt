///|
fn cargo_home_dir() -> String? {
  match trimmed_env_path("CARGO_HOME") {
    Some(path) => Some(path)
    None => match home_dir() {
      Some(home) => Some("\{home}/.cargo")
      None => None
    }
  }
}

///|
fn cargo_registry_dir(name : String, version : String) -> String? {
  match cargo_home_dir() {
    Some(home) => {
      let registry_root = "\{home}/registry/src"
      if !@fs.path_exists(registry_root) {
        return None
      }
      let entries = @fs.read_dir(registry_root) catch { _ => return None }
      for i in 0..<entries.length() {
        let candidate = "\{registry_root}/\{entries[i]}/\{name}-\{version}"
        let dir_out = try? @fs.is_dir(candidate)
        if dir_out is Ok(true) {
          return Some(candidate)
        }
      }
      None
    }
    None => None
  }
}

///|
fn cargo_vendor_dir(workspace_root : String, name : String, version : String) -> String? {
  let vendor_root = "\{workspace_root}/vendor"
  let vendor_out = try? @fs.is_dir(vendor_root)
  guard vendor_out is Ok(true) else { return None }
  let exact = "\{vendor_root}/\{name}"
  let exact_out = try? @fs.is_dir(exact)
  if exact_out is Ok(true) {
    return Some(exact)
  }
  let versioned = "\{vendor_root}/\{name}-\{version}"
  let versioned_out = try? @fs.is_dir(versioned)
  if versioned_out is Ok(true) {
    return Some(versioned)
  }
  None
}

///|
fn ignored_cargo_path(relative_path : String) -> Bool {
  ignored_local_path(relative_path) ||
  relative_path == "target" ||
  relative_path.has_prefix("target/")
}

///|
pub fn resolve_cargo_package(
  workspace_root : String,
  source : @vp.CargoPackageSource,
) -> Result[@vp.VirtualPackage, String] {
  let root_dir = match cargo_vendor_dir(workspace_root, source.name, source.version) {
    Some(path) => path
    None =>
      match cargo_registry_dir(source.name, source.version) {
        Some(path) => path
        None =>
          return Err(
            "Cargo dependency \{source.name}@\{source.version} is not available locally. Run `cargo fetch` or `cargo vendor`.",
          )
      }
  }
  resolve_directory_package(
    root_dir,
    "cargo",
    "\{source.name}@\{source.version}",
    "\{source.name}@\{source.version}",
    ignored_cargo_path,
  )
}
