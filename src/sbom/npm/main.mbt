///|
fn npm_local_spec_path(spec : String) -> String? {
  let trimmed = @snapshot.trim_spaces(spec)
  if trimmed.has_prefix("file:") {
    Some(trimmed[5:].to_string())
  } else if trimmed.has_prefix("link:") {
    Some(trimmed[5:].to_string())
  } else if trimmed.has_prefix("./") || trimmed.has_prefix("../") {
    Some(trimmed)
  } else {
    None
  }
}

///|
fn npm_package_dir(repo : String, package_name : String) -> String {
  @snapshot.join_path(
    @snapshot.join_path(repo, "node_modules"),
    @snapshot.strip_relative_prefix(package_name),
  )
}

///|
fn pnpm_package_dir(repo : String, package_name : String) -> String? {
  let store_dir = @snapshot.join_path(
    @snapshot.join_path(repo, "node_modules"),
    ".pnpm",
  )
  if !@snapshot.directory_exists(store_dir) {
    return None
  }
  let entries = @fs.read_dir(store_dir) catch { _ => return None }
  let normalized_name = @snapshot.strip_relative_prefix(package_name)
  for i in 0..<entries.length() {
    let entry = entries[i]
      let candidate = @snapshot.join_path(
      @snapshot.join_path(@snapshot.join_path(store_dir, entry), "node_modules"),
      normalized_name,
    )
    if @snapshot.directory_exists(candidate) {
      return Some(candidate)
    }
  }
  None
}

///|
fn npm_installed_root(
  repo : String,
  package_name : String,
  spec : String,
) -> Result[(String, String), String] {
  match npm_local_spec_path(spec) {
    Some(local_path) => {
      let resolved = @snapshot.resolve_path(
        repo,
        @snapshot.strip_wrapping_quotes(local_path),
      )
      if @snapshot.directory_exists(resolved) {
        Ok((resolved, "npm"))
      } else {
        Err(
          "local npm package \{package_name} not found at \{resolved}. Run `npm ci` or `pnpm install --frozen-lockfile`.",
        )
      }
    }
    None => {
      let direct = npm_package_dir(repo, package_name)
      if @snapshot.directory_exists(direct) {
        Ok((direct, "npm"))
      } else {
        match pnpm_package_dir(repo, package_name) {
          Some(path) => Ok((path, "pnpm"))
          None =>
            Err(
              "npm package \{package_name} is not installed locally. Run `npm ci` or `pnpm install --frozen-lockfile`.",
            )
        }
      }
    }
  }
}

///|
pub fn resolve_npm_dependency(
  repo : String,
  package_name : String,
  spec : String,
) -> Result[@snapshot.ResolvedDependency, String] {
  let root_out = npm_installed_root(repo, package_name, spec)
  guard root_out is Ok((root_path, manager)) else {
    return Err(root_out.unwrap_err())
  }
  let manifest_path = @snapshot.join_path(root_path, "package.json")
  let manifest_out = @snapshot.read_json_object(manifest_path, manifest_path)
  guard manifest_out is Ok(manifest) else {
    return Err(manifest_out.unwrap_err())
  }
  let version = match @snapshot.json_string_field(manifest, "version") {
    Some(value) => value
    None =>
      return Err(
        "installed npm package \{package_name} is missing package.json version at \{manifest_path}",
      )
  }
  @snapshot.dependency_resolution(repo, manager, package_name, version, root_path)
}
