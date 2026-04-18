///|
fn go_cache_root() -> String? {
  match trimmed_env_path("GOMODCACHE") {
    Some(path) => Some(path)
    None => match trimmed_env_path("GOPATH") {
      Some(go_path) => Some("\{go_path}/pkg/mod")
      None => match home_dir() {
        Some(home) => Some("\{home}/go/pkg/mod")
        None => None
      }
    }
  }
}

///|
fn go_escape_module_char(char : Char) -> String {
  if char >= 'A' && char <= 'Z' {
    let lowered = Int::unsafe_to_char(char.to_int() + 32)
    "!\{lowered}"
  } else {
    "\{char}"
  }
}

///|
fn go_escape_module_path(path : String) -> String {
  let out = StringBuilder::new()
  for char in path {
    out.write_string(go_escape_module_char(char))
  }
  out.to_string()
}

///|
fn go_vendor_dir(workspace_root : String, module_path : String) -> String? {
  let candidate = "\{workspace_root}/vendor/\{module_path}"
  let dir_out = try? @fs.is_dir(candidate)
  if dir_out is Ok(true) {
    Some(candidate)
  } else {
    None
  }
}

///|
fn go_module_cache_dir(source : @vp.GoModuleSource) -> String? {
  match go_cache_root() {
    Some(path) => {
      let root_out = try? @fs.is_dir(path)
      guard root_out is Ok(true) else { return None }
      let candidate = "\{path}/\{go_escape_module_path(source.module_path)}@\{source.version}"
      let candidate_out = try? @fs.is_dir(candidate)
      if candidate_out is Ok(true) {
        Some(candidate)
      } else {
        None
      }
    }
    None => None
  }
}

///|
pub fn resolve_go_module(
  workspace_root : String,
  source : @vp.GoModuleSource,
) -> Result[@vp.VirtualPackage, String] {
  let root_dir = match go_vendor_dir(workspace_root, source.module_path) {
    Some(path) => path
    None =>
      match go_module_cache_dir(source) {
        Some(path) => path
        None =>
          return Err(
            "Go module \{source.module_path}@\{source.version} is not available locally. Run `go mod download` or `go mod vendor`.",
          )
      }
  }
  resolve_directory_package(
    root_dir,
    "gomod",
    "\{source.module_path}@\{source.version}",
    "\{source.module_path}@\{source.version}",
    ignored_local_path,
  )
}
