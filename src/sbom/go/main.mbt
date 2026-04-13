///|
fn go_cache_root() -> String? {
  match @snapshot.env_path("GOMODCACHE") {
    Some(path) => Some(path)
    None =>
      match @snapshot.env_path("GOPATH") {
        Some(go_path) =>
          Some(@snapshot.join_path(@snapshot.join_path(go_path, "pkg"), "mod"))
        None =>
          match @snapshot.home_dir() {
            Some(home) =>
              Some(
                @snapshot.join_path(
                  @snapshot.join_path(@snapshot.join_path(home, "go"), "pkg"),
                  "mod",
                ),
              )
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
pub fn resolve_go_dependency(
  repo : String,
  module_name : String,
  version : String,
  replace_path : String?,
) -> Result[@snapshot.ResolvedDependency, String] {
  let root_path = match replace_path {
    Some(path) => {
        let resolved = @snapshot.resolve_path(repo, path)
        if !@snapshot.directory_exists(resolved) {
        return Err(
          "local Go module \{module_name} not found at \{resolved}. Run `go mod download`.",
        )
      }
      resolved
    }
    None => {
      let cache_root = match go_cache_root() {
        Some(path) if @snapshot.directory_exists(path) => path
        _ =>
          return Err(
            "Go module cache is not available for \{module_name}@\{version}. Run `go mod download`.",
          )
      }
      let candidate = @snapshot.join_path(
        cache_root,
        "\{go_escape_module_path(module_name)}@\{version}",
      )
      if !@snapshot.directory_exists(candidate) {
        return Err(
          "Go module \{module_name}@\{version} is not available locally. Run `go mod download`.",
        )
      }
      candidate
    }
  }
  @snapshot.dependency_resolution(repo, "go", module_name, version, root_path)
}
