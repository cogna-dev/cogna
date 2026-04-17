///|
priv struct BuildSoftwareComponent {
  id : String
  name : String
  version : String?
  purl : String?
  scope : String
  evidence_path : String
  pkg : @sbom_types.Package?
}

///|
priv struct BuildSbomArtifacts {
  components_ndjson : String
  spdx_json : String
}

///|
priv struct BuildSbomScanResult {
  components : Array[BuildSoftwareComponent]
  sbom : @sbom_types.Sbom
}

///|
fn build_sbom_string_json(value : String?) -> Json {
  match value {
    Some(text) => Json::string(text)
    None => Json::null()
  }
}

///|
fn ecosystem_from_purl(purl : String?) -> String {
  match purl {
    Some(p) => {
      let trimmed = if p.has_prefix("pkg:") { p[4:].to_string() } else { p }
      match trimmed.find("/") {
        Some(idx) => trimmed[0:idx].to_string()
        None =>
          match trimmed.find("@") {
            Some(idx) => trimmed[0:idx].to_string()
            None => trimmed
          }
      }
    }
    None => ""
  }
}

///|
fn build_component_record_json(component : BuildSoftwareComponent) -> Json {
  let eco = ecosystem_from_purl(component.purl)
  let record : Map[String, Json] = {
    "name": component.name,
    "scope": component.scope,
    "version": build_sbom_string_json(component.version),
    "purl": build_sbom_string_json(component.purl),
  }
  if eco != "" {
    record["ecosystem"] = Json::string(eco)
  }
  Json::object(record)
}

///|
fn build_components_ndjson(
  components : Array[BuildSoftwareComponent],
) -> String {
  let lines : Array[String] = []
  for i in 0..<components.length() {
    lines.push(build_component_record_json(components[i]).stringify())
  }
  if lines.is_empty() {
    ""
  } else {
    lines.join("\n") + "\n"
  }
}

///|
fn build_sbom_artifacts(scan : BuildSbomScanResult) -> BuildSbomArtifacts {
  {
    components_ndjson: build_components_ndjson(scan.components),
    spdx_json: @ext_sbom.export_spdx(scan.sbom),
  }
}

///|
fn sbom_trim_spaces(value : String) -> String {
  let mut start = 0
  let mut end = value.length()
  while start < end {
    let c = value.code_unit_at(start)
    if c == ' ' || c == '\t' || c == '\r' {
      start += 1
    } else {
      break
    }
  }
  while end > start {
    let c = value.code_unit_at(end - 1)
    if c == ' ' || c == '\t' || c == '\r' {
      end -= 1
    } else {
      break
    }
  }
  value[start:end].to_string()
}

///|
fn sbom_purl_name(purl : String) -> String {
  let without_version = match purl.find("@") {
    Some(index) => purl[:index].to_string()
    None => purl
  }
  let segments = without_version.split("/").to_array()
  if segments.is_empty() {
    purl
  } else {
    segments[segments.length() - 1].to_string()
  }
}

///|
fn sbom_purl_version(purl : String) -> String? {
  match purl.find("@") {
    Some(index) if index + 1 < purl.length() =>
      Some(purl[index + 1:].to_string())
    _ => None
  }
}

///|
fn build_root_component(config : @config.Config) -> BuildSoftwareComponent {
  {
    id: config.purl,
    name: sbom_purl_name(config.purl),
    version: sbom_purl_version(config.purl),
    purl: Some(config.purl),
    scope: "local",
    evidence_path: "cogna.yml",
    pkg: None,
  }
}

///|
fn sbom_recursive_pattern(pattern : String) -> (String, String)? {
  let normalized = if pattern.has_prefix("./") {
    pattern[2:].to_string()
  } else {
    pattern
  }
  if normalized.has_prefix("**/*") {
    Some(("", normalized[4:].to_string()))
  } else {
    match normalized.find("/**/*") {
      Some(idx) =>
        Some((normalized[:idx].to_string(), normalized[idx + 5:].to_string()))
      None => None
    }
  }
}

///|
fn sbom_collect_recursive(
  repo : String,
  relative_dir : String,
  suffix : String,
  out : Array[String],
) -> Result[Unit, String] {
  let dir_path = if relative_dir == "" {
    repo
  } else {
    "\{repo}/\{relative_dir}"
  }
  let entries = @fs.read_dir(dir_path) catch {
    err => return Err("cannot read directory \{dir_path}: \{err.to_string()}")
  }
  entries.sort()
  for i in 0..<entries.length() {
    let entry = entries[i]
    let relative_path = if relative_dir == "" {
      entry
    } else {
      "\{relative_dir}/\{entry}"
    }
    if relative_path == "dist" ||
      relative_path.has_prefix("dist/") ||
      relative_path == ".git" ||
      relative_path.has_prefix(".git/") ||
      relative_path == ".cogna" ||
      relative_path.has_prefix(".cogna/") ||
      relative_path == "node_modules" ||
      relative_path.has_prefix("node_modules/") {
      continue
    }
    let absolute_path = "\{repo}/\{relative_path}"
    let is_dir = try? @fs.is_dir(absolute_path)
    if is_dir is Ok(true) {
      let nested = sbom_collect_recursive(repo, relative_path, suffix, out)
      guard nested is Ok(_) else { return Err(nested.unwrap_err()) }
      continue
    }
    let is_file = try? @fs.is_file(absolute_path)
    if is_file is Ok(true) && (suffix == "" || relative_path.has_suffix(suffix)) {
      out.push(relative_path)
    }
  }
  Ok(())
}

///|
fn build_resolve_input_files(
  config : @config.Config,
  repo : String,
) -> Result[Array[String], String] {
  let files : Array[String] = []
  for i in 0..<config.inputs.include_paths.length() {
    let pattern = sbom_trim_spaces(config.inputs.include_paths[i])
    if pattern == "" {
      continue
    }
    match sbom_recursive_pattern(pattern) {
      Some((prefix, suffix)) => {
        let base = if prefix == "" { repo } else { "\{repo}/\{prefix}" }
        if @fs.path_exists(base) {
          let out = sbom_collect_recursive(repo, prefix, suffix, files)
          guard out is Ok(_) else { return Err(out.unwrap_err()) }
        }
      }
      None => {
        let normalized = if pattern.has_prefix("./") {
          pattern[2:].to_string()
        } else {
          pattern
        }
        let absolute = "\{repo}/\{normalized}"
        if @fs.path_exists(absolute) {
          files.push(normalized)
        }
      }
    }
  }
  files.sort()
  Ok(files)
}

///|
fn build_file_component(
  _repo : String,
  relative_path : String,
) -> Result[BuildSoftwareComponent, String] {
  Ok({
    id: "component:file:\{relative_path}",
    name: relative_path,
    version: None,
    purl: None,
    scope: "source-file",
    evidence_path: relative_path,
    pkg: None,
  })
}

///|
fn build_dependency_component(
  pkg : @sbom_types.Package,
  evidence_path : String,
) -> BuildSoftwareComponent {
  {
    id: pkg.id(),
    name: pkg.name,
    version: Some(pkg.version()),
    purl: Some(pkg.to_purl()),
    scope: pkg.group.to_string(),
    evidence_path,
    pkg: Some(pkg),
  }
}

///|
fn build_fallback_evidence_path(pkg_type : String) -> String {
  match pkg_type {
    "npm" => "package.json"
    "cargo" => "Cargo.toml"
    "golang" => "go.mod"
    "terraform" => ".terraform.lock.hcl"
    _ => "."
  }
}

///|
fn build_append_unique_component(
  out : Array[BuildSoftwareComponent],
  seen : Map[String, Bool],
  component : BuildSoftwareComponent,
) -> Unit {
  if seen.contains(component.id) {
    return
  }
  seen[component.id] = true
  out.push(component)
}

///|
fn build_append_unique_package(
  sbom : @sbom_types.Sbom,
  seen : Map[String, Bool],
  pkg : @sbom_types.Package,
) -> Unit {
  let id = pkg.id()
  if seen.contains(id) {
    return
  }
  seen[id] = true
  sbom.add_package(pkg)
}

///|
fn build_npm_local_spec_path(spec : String) -> String? {
  let trimmed = sbom_trim_spaces(spec)
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
fn build_npm_package_dir(repo : String, package_name : String) -> String {
  @sbom_snapshot.join_path(
    @sbom_snapshot.join_path(repo, "node_modules"),
    @sbom_snapshot.strip_relative_prefix(package_name),
  )
}

///|
fn build_pnpm_package_dir(repo : String, package_name : String) -> String? {
  let store_dir = @sbom_snapshot.join_path(
    @sbom_snapshot.join_path(repo, "node_modules"),
    ".pnpm",
  )
  if !@sbom_snapshot.directory_exists(store_dir) {
    return None
  }
  let entries = @fs.read_dir(store_dir) catch { _ => return None }
  let normalized_name = @sbom_snapshot.strip_relative_prefix(package_name)
  for i in 0..<entries.length() {
    let entry = entries[i]
    let candidate = @sbom_snapshot.join_path(
      @sbom_snapshot.join_path(
        @sbom_snapshot.join_path(store_dir, entry),
        "node_modules",
      ),
      normalized_name,
    )
    if @sbom_snapshot.directory_exists(candidate) {
      return Some(candidate)
    }
  }
  None
}

///|
fn build_npm_installed_root(
  repo : String,
  package_name : String,
  spec : String,
) -> Result[(String, String), String] {
  match build_npm_local_spec_path(spec) {
    Some(local_path) => {
      let resolved = @sbom_snapshot.resolve_path(
        repo,
        @sbom_snapshot.strip_wrapping_quotes(local_path),
      )
      if @sbom_snapshot.directory_exists(resolved) {
        Ok((resolved, "npm"))
      } else {
        Err(
          "local npm package \{package_name} not found at \{resolved}. Run `npm ci` or `pnpm install --frozen-lockfile`.",
        )
      }
    }
    None => {
      let direct = build_npm_package_dir(repo, package_name)
      if @sbom_snapshot.directory_exists(direct) {
        Ok((direct, "npm"))
      } else {
        match build_pnpm_package_dir(repo, package_name) {
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
fn build_resolve_npm_dependency(
  repo : String,
  package_name : String,
  spec : String,
) -> Result[@sbom_snapshot.ResolvedDependency, String] {
  let root_out = build_npm_installed_root(repo, package_name, spec)
  guard root_out is Ok((root_path, manager)) else {
    return Err(root_out.unwrap_err())
  }
  let manifest_path = @sbom_snapshot.join_path(root_path, "package.json")
  let manifest_out = @sbom_snapshot.read_json_object(
    manifest_path, manifest_path,
  )
  guard manifest_out is Ok(manifest) else {
    return Err(manifest_out.unwrap_err())
  }
  let version = match @sbom_snapshot.json_string_field(manifest, "version") {
    Some(value) => value
    None =>
      return Err(
        "installed npm package \{package_name} is missing package.json version at \{manifest_path}",
      )
  }
  @sbom_snapshot.dependency_resolution(
    repo, manager, package_name, version, root_path,
  )
}

///|
fn build_package_json_version(value : Json) -> String? {
  match value {
    String(text) if sbom_trim_spaces(text) != "" => Some(sbom_trim_spaces(text))
    Object(object) =>
      match object.get("version") {
        Some(String(text)) if sbom_trim_spaces(text) != "" =>
          Some(sbom_trim_spaces(text))
        _ => None
      }
    _ => None
  }
}

///|
fn build_npm_group_for_field(field : String) -> @sbom_types.DependencyGroup {
  match field {
    "devDependencies" => @sbom_types.DependencyGroup::Dev
    "optionalDependencies" => @sbom_types.DependencyGroup::Optional
    _ => @sbom_types.DependencyGroup::Runtime
  }
}

///|
fn build_append_package_json_deps(
  components : Array[BuildSoftwareComponent],
  packages : Array[@sbom_types.Package],
  object : Map[String, Json],
  field : String,
  repo : String,
  require_local_packages : Bool,
  seen : Map[String, Bool],
) -> Result[Unit, String] {
  match object.get(field) {
    Some(Object(deps)) =>
      for name, value in deps {
        match build_package_json_version(value) {
          Some(version_spec) => {
            let group = build_npm_group_for_field(field)
            let resolved_out = build_resolve_npm_dependency(
              repo, name, version_spec,
            )
            if resolved_out is Ok(resolved) {
              let pkg0 = @sbom_types.Package::with_version(
                name,
                resolved.version,
                "npm",
              )
              let pkg1 = pkg0.set_group(group)
              let pkg2 = match build_npm_local_spec_path(version_spec) {
                Some(local_path) =>
                  pkg1.set_source(
                    @sbom_types.DependencySource::Path(
                      @sbom_snapshot.display_path(
                        repo,
                        @sbom_snapshot.resolve_path(
                          repo,
                          @sbom_snapshot.strip_wrapping_quotes(local_path),
                        ),
                      ),
                    ),
                  )
                None =>
                  pkg1.set_source(@sbom_types.DependencySource::Registry(None))
              }
              let pkg = pkg2.set_checksum(resolved.content_digest)
              packages.push(pkg)
              build_append_unique_component(
                components,
                seen,
                build_dependency_component(
                  pkg,
                  resolved.evidence_path,
                ),
              )
            } else if require_local_packages {
              return Err(resolved_out.unwrap_err())
            } else {
              let pkg0 = @sbom_types.Package::with_version(
                name, version_spec, "npm",
              )
              let pkg1 = pkg0.set_group(group)
              let pkg = match build_npm_local_spec_path(version_spec) {
                Some(local_path) =>
                  pkg1.set_source(
                    @sbom_types.DependencySource::Path(
                      @sbom_snapshot.strip_wrapping_quotes(local_path),
                    ),
                  )
                None =>
                  pkg1.set_source(@sbom_types.DependencySource::Registry(None))
              }
              packages.push(pkg)
              build_append_unique_component(
                components,
                seen,
                build_dependency_component(pkg, "package.json", []),
              )
            }
          }
          None => ()
        }
      }
    _ => ()
  }
  Ok(())
}

///|
fn build_scan_npm_components(
  config : @config.Config,
  repo : String,
  components : Array[BuildSoftwareComponent],
  packages : Array[@sbom_types.Package],
  seen : Map[String, Bool],
) -> Result[Unit, String] {
  let path = "\{repo}/package.json"
  if !@fs.path_exists(path) {
    return Ok(())
  }
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read package.json: \{err.to_string()}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(object)) else {
    return Err("invalid json in package.json")
  }
  let dep_out = build_append_package_json_deps(
    components,
    packages,
    object,
    "dependencies",
    repo,
    config.sbom.require_local_packages,
    seen,
  )
  guard dep_out is Ok(_) else { return Err(dep_out.unwrap_err()) }
  let dev_out = build_append_package_json_deps(
    components,
    packages,
    object,
    "devDependencies",
    repo,
    config.sbom.require_local_packages,
    seen,
  )
  guard dev_out is Ok(_) else { return Err(dev_out.unwrap_err()) }
  let peer_out = build_append_package_json_deps(
    components,
    packages,
    object,
    "peerDependencies",
    repo,
    config.sbom.require_local_packages,
    seen,
  )
  guard peer_out is Ok(_) else { return Err(peer_out.unwrap_err()) }
  let optional_out = build_append_package_json_deps(
    components,
    packages,
    object,
    "optionalDependencies",
    repo,
    config.sbom.require_local_packages,
    seen,
  )
  guard optional_out is Ok(_) else { return Err(optional_out.unwrap_err()) }
  Ok(())
}

///|
fn build_cargo_home_dir() -> String? {
  match @sbom_snapshot.env_path("CARGO_HOME") {
    Some(path) => Some(path)
    None =>
      match @sbom_snapshot.home_dir() {
        Some(home) => Some(@sbom_snapshot.join_path(home, ".cargo"))
        None => None
      }
  }
}

///|
fn build_cargo_registry_dir(name : String, version : String) -> String? {
  match build_cargo_home_dir() {
    Some(home) => {
      let registry_root = @sbom_snapshot.join_path(
        @sbom_snapshot.join_path(home, "registry"),
        "src",
      )
      if !@sbom_snapshot.directory_exists(registry_root) {
        return None
      }
      let registries = @fs.read_dir(registry_root) catch { _ => return None }
      for i in 0..<registries.length() {
        let candidate = @sbom_snapshot.join_path(
          @sbom_snapshot.join_path(registry_root, registries[i]),
          "\{name}-\{version}",
        )
        if @sbom_snapshot.directory_exists(candidate) {
          return Some(candidate)
        }
      }
      None
    }
    None => None
  }
}

///|
fn build_cargo_vendor_dir(
  repo : String,
  name : String,
  version : String,
) -> String? {
  let vendor_root = @sbom_snapshot.join_path(repo, "vendor")
  if !@sbom_snapshot.directory_exists(vendor_root) {
    return None
  }
  let exact = @sbom_snapshot.join_path(vendor_root, name)
  if @sbom_snapshot.directory_exists(exact) {
    return Some(exact)
  }
  let versioned = @sbom_snapshot.join_path(vendor_root, "\{name}-\{version}")
  if @sbom_snapshot.directory_exists(versioned) {
    return Some(versioned)
  }
  None
}

///|
fn build_go_cache_root() -> String? {
  match @sbom_snapshot.env_path("GOMODCACHE") {
    Some(path) => Some(path)
    None =>
      match @sbom_snapshot.env_path("GOPATH") {
        Some(go_path) =>
          Some(
            @sbom_snapshot.join_path(
              @sbom_snapshot.join_path(go_path, "pkg"),
              "mod",
            ),
          )
        None =>
          match @sbom_snapshot.home_dir() {
            Some(home) =>
              Some(
                @sbom_snapshot.join_path(
                  @sbom_snapshot.join_path(
                    @sbom_snapshot.join_path(home, "go"),
                    "pkg",
                  ),
                  "mod",
                ),
              )
            None => None
          }
      }
  }
}

///|
fn build_go_escape_module_char(char : Char) -> String {
  if char >= 'A' && char <= 'Z' {
    let lowered = Int::unsafe_to_char(char.to_int() + 32)
    "!\{lowered}"
  } else {
    "\{char}"
  }
}

///|
fn build_go_escape_module_path(path : String) -> String {
  let out = StringBuilder::new()
  for char in path {
    out.write_string(build_go_escape_module_char(char))
  }
  out.to_string()
}

///|
fn build_go_module_cache_dir(pkg : @sbom_types.Package) -> String? {
  match build_go_cache_root() {
    Some(path) if @sbom_snapshot.directory_exists(path) => {
      let module_path = match pkg.ns {
        Some(ns) => "\{ns}/\{pkg.name}"
        None => pkg.name
      }
      let candidate = @sbom_snapshot.join_path(
        path,
        "\{build_go_escape_module_path(module_path)}@\{pkg.version()}",
      )
      if @sbom_snapshot.directory_exists(candidate) {
        Some(candidate)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn build_component_from_root(
  repo : String,
  pkg : @sbom_types.Package,
  root_path : String,
) -> Result[BuildSoftwareComponent, String] {
  let snapshot_out = @sbom_snapshot.snapshot_files(root_path)
  guard snapshot_out is Ok(_files) else { return Err(snapshot_out.unwrap_err()) }
  Ok(
    build_dependency_component(
      pkg,
      @sbom_snapshot.display_path(repo, root_path),
    ),
  )
}

///|
fn build_resolve_package_component(
  repo : String,
  pkg : @sbom_types.Package,
  require_local_packages : Bool,
) -> Result[BuildSoftwareComponent, String] {
  let resolved = match pkg.pkg_type {
    "cargo" =>
      match pkg.source {
        @sbom_types.DependencySource::Path(path) =>
          build_component_from_root(
            repo,
            pkg,
            @sbom_snapshot.resolve_path(repo, path),
          )
        @sbom_types.DependencySource::Workspace =>
          Ok(build_dependency_component(pkg, ".", []))
        _ =>
          match build_cargo_vendor_dir(repo, pkg.name, pkg.version()) {
            Some(path) => build_component_from_root(repo, pkg, path)
            None =>
              match build_cargo_registry_dir(pkg.name, pkg.version()) {
                Some(path) => build_component_from_root(repo, pkg, path)
                None =>
                  Err(
                    "Cargo dependency \{pkg.name}@\{pkg.version()} is not available locally. Run `cargo fetch` or `cargo vendor`.",
                  )
              }
          }
      }
    "golang" =>
      match pkg.source {
        @sbom_types.DependencySource::Path(path) =>
          build_component_from_root(
            repo,
            pkg,
            @sbom_snapshot.resolve_path(repo, path),
          )
        @sbom_types.DependencySource::Workspace =>
          Ok(build_dependency_component(pkg, ".", []))
        _ =>
          match build_go_module_cache_dir(pkg) {
            Some(path) => build_component_from_root(repo, pkg, path)
            None =>
              Err(
                "Go module \{pkg.to_purl()} is not available locally. Run `go mod download`.",
              )
          }
      }
    "terraform" =>
      Ok(
        build_dependency_component(
          pkg,
          build_fallback_evidence_path(pkg.pkg_type),
          [],
        ),
      )
    _ =>
      Ok(
        build_dependency_component(
          pkg,
          build_fallback_evidence_path(pkg.pkg_type),
          [],
        ),
      )
  }
  if resolved is Ok(component) {
    Ok(component)
  } else if require_local_packages {
    Err(resolved.unwrap_err())
  } else {
    Ok(
      build_dependency_component(
        pkg,
        build_fallback_evidence_path(pkg.pkg_type),
        [],
      ),
    )
  }
}

///|
fn build_read_optional_file(path : String) -> Result[String?, String] {
  if !@fs.path_exists(path) {
    return Ok(None)
  }
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read \{path}: \{err.to_string()}")
  }
  Ok(Some(text))
}

///|
fn build_read_required_file(path : String) -> Result[String, String] {
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read \{path}: \{err.to_string()}")
  }
  Ok(text)
}

///|
fn build_collect_terraform_files(
  repo : String,
) -> Result[Array[(String, String)], String] {
  let paths : Array[String] = []
  let collect_out = sbom_collect_recursive(repo, "", ".tf", paths)
  guard collect_out is Ok(_) else { return Err(collect_out.unwrap_err()) }
  let files : Array[(String, String)] = []
  for i in 0..<paths.length() {
    let path = paths[i]
    let text = @fs.read_file_to_string("\{repo}/\{path}") catch {
      err => return Err("cannot read \{repo}/\{path}: \{err.to_string()}")
    }
    files.push((path, text))
  }
  Ok(files)
}

///|
fn build_collect_external_packages(
  repo : String,
) -> Result[Array[@sbom_types.Package], String] {
  let packages : Array[@sbom_types.Package] = []
  let cargo_path = "\{repo}/Cargo.toml"
  if @fs.path_exists(cargo_path) {
    let cargo_toml = build_read_required_file(cargo_path)
    guard cargo_toml is Ok(content) else { return Err(cargo_toml.unwrap_err()) }
    let cargo_lock = build_read_optional_file("\{repo}/Cargo.lock")
    guard cargo_lock is Ok(lock_content) else {
      return Err(cargo_lock.unwrap_err())
    }
    let project = @ext_sbom.scan_cargo(repo, content, lock_content)
    for pkg in project.all_packages() {
      packages.push(pkg)
    }
  }
  let go_mod_path = "\{repo}/go.mod"
  if @fs.path_exists(go_mod_path) {
    let go_mod = build_read_required_file(go_mod_path)
    guard go_mod is Ok(content) else { return Err(go_mod.unwrap_err()) }
    let go_sum = build_read_optional_file("\{repo}/go.sum")
    guard go_sum is Ok(sum_content) else { return Err(go_sum.unwrap_err()) }
    let project = @ext_sbom.scan_go(repo, content, sum_content)
    for pkg in project.all_packages() {
      packages.push(pkg)
    }
  }
  let terraform_files_out = build_collect_terraform_files(repo)
  guard terraform_files_out is Ok(terraform_files) else {
    return Err(terraform_files_out.unwrap_err())
  }
  let terraform_lock_path = "\{repo}/.terraform.lock.hcl"
  if !terraform_files.is_empty() || @fs.path_exists(terraform_lock_path) {
    let lock_content = build_read_optional_file(terraform_lock_path)
    guard lock_content is Ok(lock_text) else {
      return Err(lock_content.unwrap_err())
    }
    let project = @ext_sbom.scan_terraform(repo, terraform_files, lock_text)
    for pkg in project.all_packages() {
      packages.push(pkg)
    }
  }
  Ok(packages)
}

///|
fn collect_sbom_components(
  config : @config.Config,
  repo : String,
) -> Result[BuildSbomScanResult, String] {
  let components : Array[BuildSoftwareComponent] = []
  let packages : Array[@sbom_types.Package] = []
  let seen_components : Map[String, Bool] = {}
  build_append_unique_component(
    components,
    seen_components,
    build_root_component(config),
  )

  let npm_out = build_scan_npm_components(
    config, repo, components, packages, seen_components,
  )
  guard npm_out is Ok(_) else { return Err(npm_out.unwrap_err()) }

  let ext_packages_out = build_collect_external_packages(repo)
  guard ext_packages_out is Ok(ext_packages) else {
    return Err(ext_packages_out.unwrap_err())
  }
  for i in 0..<ext_packages.length() {
    let pkg = ext_packages[i]
    packages.push(pkg)
    let component_out = build_resolve_package_component(
      repo,
      pkg,
      config.sbom.require_local_packages,
    )
    guard component_out is Ok(component) else {
      return Err(component_out.unwrap_err())
    }
    build_append_unique_component(components, seen_components, component)
  }

  let input_files_out = build_resolve_input_files(config, repo)
  guard input_files_out is Ok(input_files) else {
    return Err(input_files_out.unwrap_err())
  }
  for i in 0..<input_files.length() {
    let component_out = build_file_component(repo, input_files[i])
    guard component_out is Ok(component) else {
      return Err(component_out.unwrap_err())
    }
    build_append_unique_component(components, seen_components, component)
  }

  let sbom = @sbom_types.Sbom::new(
    sbom_purl_name(config.purl),
    match sbom_purl_version(config.purl) {
      Some(version) => version
      None => "0.0.0"
    },
  )
  let seen_packages : Map[String, Bool] = {}
  for i in 0..<packages.length() {
    build_append_unique_package(sbom, seen_packages, packages[i])
  }
  Ok({ components, sbom })
}
