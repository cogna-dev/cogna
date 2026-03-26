///|
fn trim_spaces(value : String) -> String {
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
fn strip_inline_comment(value : String, marker : String) -> String {
  match value.find(marker) {
    Some(index) => value[:index].to_string()
    None => value
  }
}

///|
fn trim_quotes(value : String) -> String {
  let trimmed = trim_spaces(value)
  if trimmed.length() >= 2 &&
    trimmed.code_unit_at(0) == '"' &&
    trimmed.code_unit_at(trimmed.length() - 1) == '"' {
    trimmed[1:trimmed.length() - 1].to_string()
  } else {
    trimmed
  }
}

///|
fn purl_name(purl : String) -> String {
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
fn purl_version(purl : String) -> String? {
  match purl.find("@") {
    Some(index) if index + 1 < purl.length() => Some(purl[index + 1:].to_string())
    _ => None
  }
}

///|
fn profile_component_type(profile : String) -> String {
  match profile {
    "openapi-spec" => "application"
    "terraform-module" => "library"
    "policy-bundle" => "application"
    _ => "library"
  }
}

///|
fn root_component(config : @config.Config) -> SoftwareComponent {
  {
    id: config.purl,
    name: purl_name(config.purl),
    version: purl_version(config.purl),
    purl: Some(config.purl),
    component_type: profile_component_type(config.profile),
    scope: "root",
    evidence_path: "codeiq.yaml",
    hashes: [],
  }
}

///|
fn recursive_pattern(pattern : String) -> (String, String)? {
  let normalized = if pattern.has_prefix("./") {
    pattern[2:].to_string()
  } else {
    pattern
  }
  if normalized.has_prefix("**/*") {
    Some(("", normalized[4:].to_string()))
  } else {
    match normalized.find("/**/*") {
      Some(idx) => Some((normalized[:idx].to_string(), normalized[idx + 5:].to_string()))
      None => None
    }
  }
}

///|
fn collect_recursive(
  repo : String,
  relative_dir : String,
  suffix : String,
  out : Array[String],
) -> Result[Unit, String] {
  let dir_path = if relative_dir == "" { repo } else { "\{repo}/\{relative_dir}" }
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
      relative_path == ".codeiq" ||
      relative_path.has_prefix(".codeiq/") ||
      relative_path == "node_modules" ||
      relative_path.has_prefix("node_modules/") {
      continue
    }
    let absolute_path = "\{repo}/\{relative_path}"
    let is_dir = try? @fs.is_dir(absolute_path)
    if is_dir is Ok(true) {
      let nested = collect_recursive(repo, relative_path, suffix, out)
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
fn resolve_input_files(config : @config.Config, repo : String) -> Result[Array[String], String] {
  let files : Array[String] = []
  for i in 0..<config.inputs.include_paths.length() {
    let pattern = trim_spaces(config.inputs.include_paths[i])
    if pattern == "" {
      continue
    }
    match recursive_pattern(pattern) {
      Some((prefix, suffix)) => {
        let base = if prefix == "" { repo } else { "\{repo}/\{prefix}" }
        if @fs.path_exists(base) {
          let out = collect_recursive(repo, prefix, suffix, files)
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
fn file_component(repo : String, relative_path : String) -> Result[SoftwareComponent, String] {
  let absolute_path = "\{repo}/\{relative_path}"
  let bytes = @fs.read_file_to_bytes(absolute_path) catch {
    err => return Err("cannot read source file \{absolute_path}: \{err.to_string()}")
  }
  Ok({
    id: "component:file:\{relative_path}",
    name: relative_path,
    version: None,
    purl: None,
    component_type: "file",
    scope: "source-file",
    evidence_path: relative_path,
    hashes: [{ alg: "SHA-256", content: @sha256.sha256_hexdigest(bytes) }],
  })
}

///|
fn dependency_component(
  id : String,
  name : String,
  version : String,
  purl : String,
  evidence_path : String,
) -> SoftwareComponent {
  {
    id,
    name,
    version: Some(version),
    purl: Some(purl),
    component_type: "library",
    scope: "dependency",
    evidence_path,
    hashes: [],
  }
}

///|
fn package_json_version(value : Json) -> String? {
  match value {
    String(text) if trim_spaces(text) != "" => Some(trim_spaces(text))
    Object(object) =>
      match object.get("version") {
        Some(String(text)) if trim_spaces(text) != "" => Some(trim_spaces(text))
        _ => None
      }
    _ => None
  }
}

///|
fn append_package_json_deps(
  components : Array[SoftwareComponent],
  object : Map[String, Json],
  field : String,
  evidence_path : String,
) -> Unit {
  match object.get(field) {
    Some(Object(deps)) => {
      for name, value in deps {
        match package_json_version(value) {
          Some(version) =>
            components.push(
              dependency_component(
                "pkg:npm/\{name}@\{version}",
                name,
                version,
                "pkg:npm/\{name}@\{version}",
                evidence_path,
              ),
            )
          None => ()
        }
      }
    }
    _ => ()
  }
}

///|
fn package_json_components(repo : String) -> Result[Array[SoftwareComponent], String] {
  let path = "\{repo}/package.json"
  if !@fs.path_exists(path) {
    return Ok([])
  }
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read package.json: \{err.to_string()}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(object)) else {
    return Err("invalid json in package.json")
  }
  let components : Array[SoftwareComponent] = []
  append_package_json_deps(components, object, "dependencies", "package.json")
  append_package_json_deps(components, object, "devDependencies", "package.json")
  append_package_json_deps(components, object, "peerDependencies", "package.json")
  append_package_json_deps(components, object, "optionalDependencies", "package.json")
  Ok(components)
}

///|
fn cargo_version_from_spec(spec : String) -> String? {
  let trimmed = trim_spaces(spec)
  if trimmed == "" {
    None
  } else if trimmed.has_prefix("{") {
    match trimmed.find("version") {
      Some(index) => {
        let segment = trimmed[index + 7:].to_string()
        match segment.find("=") {
          Some(eq_index) => Some(
            trim_quotes(
              trim_spaces(strip_inline_comment(segment[eq_index + 1:].to_string(), ",")),
            ),
          )
          None => None
        }
      }
      None => None
    }
  } else {
    Some(trim_quotes(trimmed))
  }
}

///|
fn cargo_components(repo : String) -> Result[Array[SoftwareComponent], String] {
  let path = "\{repo}/Cargo.toml"
  if !@fs.path_exists(path) {
    return Ok([])
  }
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read Cargo.toml: \{err.to_string()}")
  }
  let lines = text.split("\n").to_array()
  let components : Array[SoftwareComponent] = []
  let mut section = ""
  for i in 0..<lines.length() {
    let line = trim_spaces(strip_inline_comment(lines[i].to_string(), "#"))
    if line == "" {
      continue
    }
    if line.has_prefix("[") && line.has_suffix("]") {
      section = line[1:line.length() - 1].to_string()
      continue
    }
    let is_dependency_section = section == "dependencies" ||
      section == "dev-dependencies" ||
      section == "build-dependencies"
    if !is_dependency_section {
      continue
    }
    match line.find("=") {
      Some(index) => {
        let name = trim_spaces(line[:index].to_string())
        let spec = line[index + 1:].to_string()
        match cargo_version_from_spec(spec) {
          Some(version) if name != "" && version != "" =>
            components.push(
              dependency_component(
                "pkg:cargo/\{name}@\{version}",
                name,
                version,
                "pkg:cargo/\{name}@\{version}",
                "Cargo.toml",
              ),
            )
          _ => ()
        }
      }
      None => ()
    }
  }
  Ok(components)
}

///|
fn go_mod_components(repo : String) -> Result[Array[SoftwareComponent], String] {
  let path = "\{repo}/go.mod"
  if !@fs.path_exists(path) {
    return Ok([])
  }
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read go.mod: \{err.to_string()}")
  }
  let lines = text.split("\n").to_array()
  let components : Array[SoftwareComponent] = []
  let mut in_require = false
  for i in 0..<lines.length() {
    let line = trim_spaces(strip_inline_comment(lines[i].to_string(), "//"))
    if line == "" {
      continue
    }
    if line == "require (" {
      in_require = true
      continue
    }
    if in_require && line == ")" {
      in_require = false
      continue
    }
    if line.has_prefix("require ") && !line.has_suffix("(") {
      let tokens = line.split(" ").to_array().filter(token => token != "")
      if tokens.length() >= 3 {
        let name = tokens[1].to_string()
        let version = tokens[2].to_string()
        components.push(
          dependency_component(
            "pkg:golang/\{name}@\{version}",
            name,
            version,
            "pkg:golang/\{name}@\{version}",
            "go.mod",
          ),
        )
      }
      continue
    }
    if in_require {
      let tokens = line.split(" ").to_array().filter(token => token != "")
      if tokens.length() >= 2 {
        let name = tokens[0].to_string()
        let version = tokens[1].to_string()
        components.push(
          dependency_component(
            "pkg:golang/\{name}@\{version}",
            name,
            version,
            "pkg:golang/\{name}@\{version}",
            "go.mod",
          ),
        )
      }
    }
  }
  Ok(components)
}

///|
fn dedupe_components(components : Array[SoftwareComponent]) -> Array[SoftwareComponent] {
  let deduped : Array[SoftwareComponent] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<components.length() {
    let id = components[i].id
    if !seen.contains(id) {
      seen[id] = true
      deduped.push(components[i])
    }
  }
  deduped
}

///|
pub fn collect_components(
  config : @config.Config,
  repo : String,
) -> Result[Array[SoftwareComponent], String] {
  let components : Array[SoftwareComponent] = [root_component(config)]
  let package_json_out = package_json_components(repo)
  guard package_json_out is Ok(package_json_components) else {
    return Err(package_json_out.unwrap_err())
  }
  for i in 0..<package_json_components.length() {
    components.push(package_json_components[i])
  }
  let cargo_out = cargo_components(repo)
  guard cargo_out is Ok(cargo_components) else { return Err(cargo_out.unwrap_err()) }
  for i in 0..<cargo_components.length() {
    components.push(cargo_components[i])
  }
  let go_mod_out = go_mod_components(repo)
  guard go_mod_out is Ok(go_mod_components) else {
    return Err(go_mod_out.unwrap_err())
  }
  for i in 0..<go_mod_components.length() {
    components.push(go_mod_components[i])
  }
  let input_files_out = resolve_input_files(config, repo)
  guard input_files_out is Ok(input_files) else { return Err(input_files_out.unwrap_err()) }
  for i in 0..<input_files.length() {
    let component_out = file_component(repo, input_files[i])
    guard component_out is Ok(component) else {
      return Err(component_out.unwrap_err())
    }
    components.push(component)
  }
  Ok(dedupe_components(components))
}
