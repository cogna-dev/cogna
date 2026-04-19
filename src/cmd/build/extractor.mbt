///|
priv struct ExtractOutput {
  declarations_text : String
  mode : String
  fallback : Bool
  declaration_count : Int
  diagnostic_files : Int
  commit : String
}

///|
fn extractor_error(message : String) -> @cli.CliError {
  @cli.command_error("build failed: \{message}")
}

///|
fn trim_spaces(value : String) -> String {
  let mut start = 0
  let mut end = value.length()
  while start < end {
    let c = value.code_unit_at(start)
    if c == ' ' || c == '\t' || c == '\r' {
      start = start + 1
    } else {
      break
    }
  }
  while end > start {
    let c = value.code_unit_at(end - 1)
    if c == ' ' || c == '\t' || c == '\r' {
      end = end - 1
    } else {
      break
    }
  }
  value[start:end].to_string()
}

///|
fn line_before_comment(value : String) -> String {
  match value.find("//") {
    Some(idx) => value[0:idx].to_string()
    None => value
  }
}

///|
fn first_token(text : String) -> String {
  let trimmed = trim_spaces(text)
  if trimmed == "" {
    return ""
  }
  let mut end = 0
  while end < trimmed.length() {
    let c = trimmed.code_unit_at(end)
    if c == ' ' ||
      c == '\t' ||
      c == '(' ||
      c == '{' ||
      c == '[' ||
      c == ':' ||
      c == ',' ||
      c == ';' {
      break
    }
    end = end + 1
  }
  trimmed[0:end].to_string()
}

///|
fn recursive_pattern(pattern : String) -> (String, String)? {
  let normalized = if pattern.has_prefix("./") {
    pattern[2:].to_string()
  } else {
    pattern
  }
  if normalized.has_prefix("**/*") {
    let suffix = normalized[4:].to_string()
    return Some(("", suffix))
  }
  match normalized.find("/**/*") {
    Some(idx) => {
      let prefix = normalized[0:idx].to_string()
      let suffix = normalized[idx + 5:].to_string()
      Some((prefix, suffix))
    }
    None => None
  }
}

fn resolve_input_files(
  config : @config.Config,
  repo : String,
) -> Result[Array[String], @cli.CliError] {
  let package_view_out = local_package_view(repo)
  guard package_view_out is Ok(package_view) else {
    return Err(package_view_out.unwrap_err())
  }
  resolve_input_files_from_view(config, package_view)
}

///|
fn resolve_input_files_from_view(
  config : @config.Config,
  package_view : @vp.ReadonlyPackageView,
) -> Result[Array[String], @cli.CliError] {
  let available_paths = package_view.list_paths()
  let files : Array[String] = []

  for i in 0..<config.inputs.include_paths.length() {
    let pattern = trim_spaces(config.inputs.include_paths[i])
    if pattern == "" {
      continue
    }

    match recursive_pattern(pattern) {
      Some((prefix, suffix)) => {
        let normalized_prefix = if prefix == "" {
          ""
        } else {
          let prefix_out = @vp.normalize_path(prefix)
          guard prefix_out is Ok(value) else { continue }
          value
        }
        for j in 0..<available_paths.length() {
          let path = available_paths[j]
          if !@vp.path_has_prefix(path, normalized_prefix) {
            continue
          }
          if suffix == "" || path.has_suffix(suffix) {
            files.push(path)
          }
        }
      }
      None => {
        let normalized_out = @vp.normalize_path(pattern)
        guard normalized_out is Ok(normalized) else { continue }
        if package_view.exists(normalized) {
          files.push(normalized)
          continue
        }
        for j in 0..<available_paths.length() {
          let path = available_paths[j]
          if @vp.path_has_prefix(path, normalized) {
            files.push(path)
          }
        }
      }
    }
  }

  files.sort()
  let deduped : Array[String] = []
  for i in 0..<files.length() {
    if deduped.is_empty() || deduped[deduped.length() - 1] != files[i] {
      deduped.push(files[i])
    }
  }
  Ok(deduped)
}

///|
fn profile_mode(profile : String) -> (String, String) {
  match profile {
    "go-module" => ("parser-first", "gopls")
    "rust-crate" => ("parser-first", "rust-analyzer")
    "terraform-module" => ("parser-first", "hcl-parser")
    "openapi-spec" => ("parser-only", "none")
    _ => ("parser-only", "none")
  }
}

///|
fn resolve_backend_override() -> String {
  "canonical"
}

///|
fn last_code_unit_index(value : String, target : UInt16) -> Int? {
  let mut i = value.length()
  while i > 0 {
    i = i - 1
    if value.code_unit_at(i) == target {
      return Some(i)
    }
  }
  None
}

///|
fn normalize_inventory_name(profile : String, name : String) -> String {
  let trimmed = trim_spaces(name)
  if profile == "go-module" {
    match last_code_unit_index(trimmed, '.') {
      Some(idx) if idx + 1 < trimmed.length() =>
        trim_spaces(trimmed[idx + 1:].to_string())
      _ => trimmed
    }
  } else if profile == "rust-crate" {
    match trimmed.find("<") {
      Some(idx) => trim_spaces(trimmed[0:idx].to_string())
      None => trimmed
    }
  } else {
    trimmed
  }
}

///|
fn is_go_exported_name(name : String) -> Bool {
  if name == "" {
    return false
  }
  let first = name.code_unit_at(0)
  first >= 'A' && first <= 'Z'
}

///|
fn comparable_inventory_kind(kind : String) -> String? {
  match kind {
    "callable" => Some("callable")
    "function" => Some("callable")
    "method" => Some("callable")
    "struct" => Some("struct")
    "interface" => Some("interface")
    "enum" => Some("enum")
    "union" => Some("union")
    "trait" => Some("trait")
    "type_alias" => Some("type_alias")
    "const" => Some("const")
    "static" => Some("static")
    "var" => Some("var")
    "module" => Some("module")
    "macro" => Some("macro")
    _ => None
  }
}

///|
fn inventory_key(profile : String, kind : String, name : String) -> String? {
  guard comparable_inventory_kind(kind) is Some(normalized_kind) else {
    return None
  }
  let normalized_name = normalize_inventory_name(profile, name)
  if normalized_name == "" {
    return None
  }
  if profile == "go-module" && !is_go_exported_name(normalized_name) {
    return None
  }
  Some("\{normalized_kind}|\{normalized_name}")
}

///|
fn inventory_validation_path_allowed(profile : String, path : String) -> Bool {
  if path == "" {
    return true
  }
  if profile == "go-module" && path.has_suffix("_test.go") {
    return false
  }
  true
}

///|
fn profile_language(profile : String) -> String {
  match profile {
    "go-module" => "go"
    "rust-crate" => "rust"
    "terraform-module" => "terraform"
    "openapi-spec" => "openapi"
    _ => "generic"
  }
}

///|
fn enrich_declaration_metadata(record : Json) -> Unit {
  @extract.enrich_shape_metadata(record)
  match @extract.field_string(record, "language") {
    "go" => @extract_go.enrich_record(record)
    "rust" => @extract_rust.enrich_record(record)
    "terraform" => @extract_terraform.enrich_record(record)
    "openapi" => @extract_openapi.enrich_record(record)
    _ => ()
  }
}

///|
fn push_record(
  declarations : Array[Json],
  _symbols : Array[Json],
  profile : String,
  server : String,
  language : String,
  path : String,
  line_no : Int,
  kind : String,
  name : String,
  signature : String,
  docs : String,
) -> Unit {
  if name == "" {
    return
  }
  declarations.push(
    @extract.make_declaration(
      profile, server, language, path, line_no, kind, name, signature, docs,
    ),
  )
  guard @extract.last_record(declarations) is Some(record) else { return }
  enrich_declaration_metadata(record)
}

///|
fn push_simple_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  language : String,
  path : String,
  line_no : Int,
  kind : String,
  name : String,
  signature : String,
) -> Unit {
  push_record(
    declarations, symbols, profile, server, language, path, line_no, kind, name,
    signature, "",
  )
}

///|
fn collect_records(
  config : @config.Config,
  repo : String,
  files : Array[String],
  server : String,
) -> Result[(Array[Json], Array[Json]), @cli.CliError] {
  let package_view_out = local_package_view(repo)
  guard package_view_out is Ok(package_view) else {
    return Err(package_view_out.unwrap_err())
  }
  collect_records_from_view(config, package_view, files, server)
}

///|
fn collect_records_from_view(
  config : @config.Config,
  package_view : @vp.ReadonlyPackageView,
  files : Array[String],
  server : String,
) -> Result[(Array[Json], Array[Json]), @cli.CliError] {
  let declarations : Array[Json] = []
  let symbols : Array[Json] = []

  for i in 0..<files.length() {
    let relative_path = files[i]
    let content_out = package_view.read_text(relative_path)
    guard content_out is Ok(content) else {
      return Err(
        extractor_error(
          "cannot read source file \{relative_path}: \{content_out.unwrap_err()}",
        ),
      )
    }
    let lines = content.split("\n").to_array().map(line => line.to_string())
    match config.profile {
      "go-module" =>
        @extract_go.extract_file(
          declarations,
          symbols,
          config.profile,
          server,
          relative_path,
          lines,
        )
      "rust-crate" =>
        @extract_rust.extract_file(
          declarations,
          symbols,
          config.profile,
          server,
          relative_path,
          lines,
        )
      "terraform-module" =>
        @extract_terraform.extract_file(
          declarations,
          symbols,
          config.profile,
          server,
          relative_path,
          lines,
        )
      "openapi-spec" =>
        @extract_openapi.extract_file(
          declarations,
          symbols,
          config.profile,
          server,
          relative_path,
          lines,
        )
      _ => ()
    }
  }

  if config.profile == "go-module" {
    @extract_go.postprocess_declarations(declarations, config.profile)
  } else if config.profile == "rust-crate" {
    @extract_rust.postprocess_declarations(declarations, config.profile)
  }

  Ok(
    (
      @extract.sort_and_dedup(declarations, "id"),
      @extract.sort_and_dedup(symbols, "id"),
    ),
  )
}

///|
fn local_package_view(repo : String) -> Result[@vp.ReadonlyPackageView, @cli.CliError] {
  let package_out = @source.resolve_source(
    @vp.SourceSpec::LocalWorkspace({ root_dir: repo }),
  )
  guard package_out is Ok(pkg) else {
    return Err(extractor_error(package_out.unwrap_err()))
  }
  Ok(@vp.view_of(pkg))
}

///|
fn ensure_non_empty(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
) -> Unit {
  if declarations.is_empty() {
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      profile_language(profile),
      "cogna.yaml",
      1,
      "bundle",
      "bundle_root",
      "bundle_root",
    )
  }
}

///|
fn trim_newline(value : String) -> String {
  if value.has_suffix("\n") {
    value.strip_suffix("\n").unwrap_or(value).to_string()
  } else {
    value
  }
}

///|
fn resolve_git_commit(repo : String) -> String {
  let git_dir_path = "\{repo}/.git"
  if !@fs.path_exists(git_dir_path) {
    return "unknown"
  }
  let head = @fs.read_file_to_string("\{git_dir_path}/HEAD") catch {
    _ => return "unknown"
  }
  let commit = trim_spaces(trim_newline(head))
  if commit.has_prefix("ref:") {
    let ref_name = trim_spaces(commit[4:].to_string())
    let ref_value = @fs.read_file_to_string("\{git_dir_path}/\{ref_name}") catch {
      _ => return "unknown"
    }
    let resolved = trim_spaces(trim_newline(ref_value))
    if resolved == "" {
      "unknown"
    } else {
      resolved
    }
  } else {
    commit
  }
}

///|
fn extract_canonical(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let out = build_local_index_canonical(config, repo)
  guard out is Ok(sdk_out) else {
    return Err(extractor_error(out.unwrap_err()))
  }
  Ok({
    declarations_text: sdk_out.declarations_text,
    mode: sdk_out.mode,
    fallback: sdk_out.fallback,
    declaration_count: sdk_out.declaration_count,
    diagnostic_files: sdk_out.diagnostic_files,
    commit: sdk_out.commit,
  })
}

///|
/// extract_native uses the in-repo MoonBit extractor (sdk/index) directly,
/// emitting native-assisted mode metadata without any external binary dependency.
fn extract_native(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let out = build_local_index_native(config, repo)
  guard out is Ok(sdk_out) else {
    return Err(extractor_error(out.unwrap_err()))
  }
  Ok({
    declarations_text: sdk_out.declarations_text,
    mode: sdk_out.mode,
    fallback: sdk_out.fallback,
    declaration_count: sdk_out.declaration_count,
    diagnostic_files: sdk_out.diagnostic_files,
    commit: sdk_out.commit,
  })
}

///|
/// extract_build is the shared extractor entry for build.
/// Backend selection is internal and only returns canonical output metadata.
fn extract_build(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let backend = resolve_backend_override()
  let extract_out = match backend {
    "native" => extract_native(config, repo)
    _ => extract_canonical(config, repo)
  }
  guard extract_out is Ok(extract) else { return Err(extract_out.unwrap_err()) }
  Ok(extract)
}

///|
fn inventory_validation_declarations(
  profile : String,
  declarations : Array[Json]
) -> Array[Json] {
  if profile == "go-module" {
    declarations.filter(fn(decl) {
      let path = @extract.field_string(decl, "path")
      !path.has_suffix("_test.go")
    })
  } else {
    declarations
  }
}
