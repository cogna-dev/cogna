///|
priv struct ExtractOutput {
  declarations_text : String
  symbols_text : String
  mode : String
  fallback : Bool
  declaration_count : Int
  symbol_count : Int
  diagnostic_files : Int
  commit : String
}

///|
priv struct TerraformProviderInfo {
  name : String
  source : String
  version : String
  provider_alias : String
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
fn trim_quotes(value : String) -> String {
  let trimmed = trim_spaces(value)
  if trimmed.length() >= 2 &&
    (
      (
        trimmed.code_unit_at(0) == '"' &&
        trimmed.code_unit_at(trimmed.length() - 1) == '"'
      ) ||
      (
        trimmed.code_unit_at(0) == '\'' &&
        trimmed.code_unit_at(trimmed.length() - 1) == '\''
      )
    ) {
    trimmed[1:trimmed.length() - 1].to_string()
  } else {
    trimmed
  }
}

///|
fn terraform_provider_json(info : TerraformProviderInfo) -> Json {
  let object : Map[String, Json] = { "name": Json::string(info.name) }
  if info.source != "" {
    object["source"] = Json::string(info.source)
  }
  if info.version != "" {
    object["version"] = Json::string(info.version)
  }
  if info.provider_alias != "" {
    object["alias"] = Json::string(info.provider_alias)
  }
  Json::object(object)
}

///|
fn set_terraform_providers(
  record : Json,
  providers : Array[TerraformProviderInfo],
) -> Unit {
  if providers.is_empty() {
    return
  }
  guard record is Object(record_object) else { return }
  guard record_object.get("language_specific")
    is Some(Object(language_specific)) else {
    return
  }
  let providers_object : Map[String, Json] = {}
  providers_object["terraform"] = Json::array(
    providers.map(info => terraform_provider_json(info)),
  )
  language_specific["providers"] = Json::object(providers_object)
}

fn split_top_level(value : String, delimiter : UInt16) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  let mut paren = 0
  let mut bracket = 0
  let mut brace = 0
  let mut angle = 0
  for i in 0..<value.length() {
    let c = value.code_unit_at(i)
    if c == '(' {
      paren = paren + 1
    } else if c == ')' {
      if paren > 0 {
        paren = paren - 1
      }
    } else if c == '[' {
      bracket = bracket + 1
    } else if c == ']' {
      if bracket > 0 {
        bracket = bracket - 1
      }
    } else if c == '{' {
      brace = brace + 1
    } else if c == '}' {
      if brace > 0 {
        brace = brace - 1
      }
    } else if c == '<' {
      angle = angle + 1
    } else if c == '>' {
      if angle > 0 {
        angle = angle - 1
      }
    } else if c == delimiter &&
      paren == 0 &&
      bracket == 0 &&
      brace == 0 &&
      angle == 0 {
      parts.push(value[start:i].to_string())
      start = i + 1
    }
  }
  parts.push(value[start:].to_string())
  parts
}

///|
fn unique_trimmed_strings(values : Array[String]) -> Array[String] {
  let unique : Array[String] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<values.length() {
    let value = trim_spaces(values[i])
    if value == "" || seen.contains(value) {
      continue
    }
    seen[value] = true
    unique.push(value)
  }
  unique
}

///|
fn parse_bool_literal(value : String) -> Bool? {
  match trim_quotes(trim_spaces(value)) {
    "true" => Some(true)
    "false" => Some(false)
    _ => None
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
fn token_before(value : String, marker : String) -> String {
  match value.find(marker) {
    Some(idx) => first_token(value[0:idx].to_string())
    None => first_token(value)
  }
}

///|
fn segment_after(value : String, marker : String) -> String? {
  match value.find(marker) {
    Some(idx) => Some(value[idx + marker.length():].to_string())
    None => None
  }
}

///|
fn normalize_reference_target(value : String) -> String {
  segment_after(value, "$ref:")
  .map(target => trim_quotes(trim_spaces(target)))
  .unwrap_or(value |> trim_spaces |> trim_quotes)
}

///|
fn strip_braces(value : String) -> String {
  let mut out = trim_spaces(value)
  if out.has_suffix("{") {
    out = out.strip_suffix("{").unwrap_or(out).to_string() |> trim_spaces
  }
  if out.has_suffix("}") {
    out = out.strip_suffix("}").unwrap_or(out).to_string() |> trim_spaces
  }
  if out.has_suffix(";") {
    out = out.strip_suffix(";").unwrap_or(out).to_string() |> trim_spaces
  }
  out
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

///|
fn collect_recursive(
  repo : String,
  relative_dir : String,
  suffix : String,
  out : Array[String],
) -> Result[Unit, @cli.CliError] {
  let dir_path = if relative_dir == "" {
    repo
  } else {
    "\{repo}/\{relative_dir}"
  }
  let entries = @fs.read_dir(dir_path) catch {
    err =>
      return Err(
        extractor_error("cannot read directory \{dir_path}: \{err.to_string()}"),
      )
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
      relative_path.contains("/.git/") {
      continue
    }

    let absolute_path = "\{repo}/\{relative_path}"
    let dir_out = try? @fs.is_dir(absolute_path)
    if dir_out is Ok(true) {
      let nested = collect_recursive(repo, relative_path, suffix, out)
      guard nested is Ok(_) else { return Err(nested.unwrap_err()) }
      continue
    }

    let file_out = try? @fs.is_file(absolute_path)
    if file_out is Ok(true) {
      if suffix == "" || relative_path.has_suffix(suffix) {
        out.push(relative_path)
      }
    }
  }

  Ok(())
}

///|
fn resolve_input_files(
  config : @config.Config,
  repo : String,
) -> Result[Array[String], @cli.CliError] {
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
        if !@fs.path_exists(absolute) {
          continue
        }

        let dir_out = try? @fs.is_dir(absolute)
        if dir_out is Ok(true) {
          let out = collect_recursive(repo, normalized, "", files)
          guard out is Ok(_) else { return Err(out.unwrap_err()) }
        } else {
          files.push(normalized)
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
fn quoted_parts(line : String) -> Array[String] {
  let parts : Array[String] = []
  let mut start = -1
  for i in 0..<line.length() {
    if line.code_unit_at(i) == '"' {
      if start < 0 {
        start = i + 1
      } else {
        parts.push(line[start:i].to_string())
        start = -1
      }
    }
  }
  parts
}

///|
fn leading_spaces(line : String) -> Int {
  let mut count = 0
  while count < line.length() && line.code_unit_at(count) == ' ' {
    count = count + 1
  }
  count
}

///|
fn profile_mode(profile : String) -> (String, String) {
  match profile {
    "go-module" => ("parser-first", "gopls")
    "rust-crate" => ("parser-first", "rust-analyzer")
    "terraform-module" => ("parser-first", "hcl-parser")
    "openapi-spec" => ("parser-only", "none")
    "policy-bundle" => ("policy-bundle", "opa")
    _ => ("parser-only", "none")
  }
}

///|
fn resolve_backend_override() -> String {
  match @sys.get_env_var("CODEIQ_EXTRACTOR_BACKEND") {
    Some("native") => "native"
    Some("lsp") => "lsp"
    Some("canonical") => "canonical"
    Some("none") => "canonical"
    _ => "canonical"
  }
}

///|
fn resolve_validation_mode(config : @config.Config) -> String {
  match @sys.get_env_var("CODEIQ_EXTRACTOR_BACKEND") {
    Some("lsp") => "lsp"
    Some("native") => "none"
    Some("none") => "none"
    _ => config.validation
  }
}

///|
fn shell_escape(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn lsp_probe(server : String, version_arg : String) -> (String, Bool) {
  if server == "none" || server == "opa" {
    return ("none", false)
  }
  let command = "\{shell_escape(server)} \{version_arg}"
  let (exit_code, stdout, stderr) = @build_shell.run_command_capture(command)
  if exit_code != 0 {
    let details = if stderr != "" { stderr } else { stdout }
    let normalized = trim_spaces(details)
    let final_details = if normalized == "" {
      "command exited with \{exit_code}"
    } else {
      normalized
    }
    return ("missing:\{final_details}", true)
  }
  let text = trim_spaces(stdout)
  if text == "" {
    ("available", false)
  } else {
    (text, false)
  }
}

///|
fn lsp_runtime_probe(
  profile : String,
  configured_server : String,
) -> (String, Bool) {
  if @sys.get_env_var("CODEIQ_TEST_FORCE_LSP_FALLBACK") is Some("true") &&
    (profile == "go-module" || profile == "rust-crate") {
    return ("missing:forced-by-test", true)
  }
  match profile {
    "go-module" => lsp_probe(configured_server, "version")
    "rust-crate" => lsp_probe(configured_server, "--version")
    _ => ("none", false)
  }
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
fn substring_between(
  value : String,
  start_marker : String,
  end_marker : String,
) -> String? {
  match segment_after(value, start_marker) {
    Some(rest) =>
      match rest.find(end_marker) {
        Some(idx) => Some(rest[0:idx].to_string())
        None => None
      }
    None => None
  }
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
fn inventory_validation_declarations(
  profile : String,
  declarations : Array[Json],
) -> Array[Json] {
  let filtered : Array[Json] = []
  for i in 0..<declarations.length() {
    if
      inventory_validation_path_allowed(
        profile,
        @extract.field_string(declarations[i], "path"),
      ) {
      filtered.push(declarations[i])
    }
  }
  filtered
}

///|
fn inventory_keys_from_declarations(
  profile : String,
  declarations : Array[Json],
) -> Array[String] {
  let keys : Array[String] = []
  for i in 0..<declarations.length() {
    match inventory_key(
      profile,
      @extract.field_string(declarations[i], "kind"),
      @extract.field_string(declarations[i], "name"),
    ) {
      Some(key) => @extract.append_unique_string(keys, key)
      None => ()
    }
  }
  keys.sort()
  keys
}

///|
fn go_symbol_kind(kind : String) -> String? {
  match kind {
    "Function" => Some("callable")
    "Method" => Some("callable")
    "Struct" => Some("struct")
    "Interface" => Some("interface")
    "Constant" => Some("const")
    "Variable" => Some("var")
    "Class" => Some("type_alias")
    _ => None
  }
}

///|
fn rust_symbol_kind(kind : String) -> String? {
  match kind {
    "Function" => Some("callable")
    "Method" => Some("callable")
    "Struct" => Some("struct")
    "Enum" => Some("enum")
    "Union" => Some("union")
    "Trait" => Some("trait")
    "TypeAlias" => Some("type_alias")
    "Const" => Some("const")
    "Static" => Some("static")
    "Module" => Some("module")
    "Macro" => Some("macro")
    _ => None
  }
}

///|
fn collect_go_lsp_inventory(
  profile : String,
  files : Array[String],
  repo : String,
) -> Result[Array[String], @cli.CliError] {
  let keys : Array[String] = []
  for i in 0..<files.length() {
    let relative_path = files[i]
    if !relative_path.has_suffix(".go") {
      continue
    }
    let absolute_path = "\{repo}/\{relative_path}"
    let command = "gopls symbols \{shell_escape(absolute_path)}"
    let (exit_code, stdout, stderr) = @build_shell.run_command_capture(command)
    if exit_code != 0 {
      let details = if stderr != "" { trim_spaces(stderr) } else { trim_spaces(stdout) }
      let message_details = if details == "" { "command failed" } else { details }
      return Err(
        extractor_error(
          "gopls symbols failed for \{relative_path}: \{message_details}",
        ),
      )
    }
    for raw_line in stdout.split("\n") {
      let line = raw_line.to_string()
      if line.has_prefix("\t") {
        continue
      }
      let trimmed = trim_spaces(line)
      if trimmed == "" {
        continue
      }
      guard last_code_unit_index(trimmed, ' ') is Some(last_space) else { continue }
      let before_range = trimmed[0:last_space].to_string()
      guard last_code_unit_index(before_range, ' ') is Some(kind_space) else {
        continue
      }
      let raw_name = trim_spaces(before_range[0:kind_space].to_string())
      let raw_kind = trim_spaces(before_range[kind_space + 1:].to_string())
        match go_symbol_kind(raw_kind) {
          Some(kind) =>
            match inventory_key(profile, kind, raw_name) {
              Some(key) => @extract.append_unique_string(keys, key)
              None => ()
            }
          None => ()
      }
    }
  }
  keys.sort()
  Ok(keys)
}

///|
fn collect_rust_lsp_inventory(
  profile : String,
  files : Array[String],
  repo : String,
) -> Result[Array[String], @cli.CliError] {
  let keys : Array[String] = []
  for i in 0..<files.length() {
    let relative_path = files[i]
    if !relative_path.has_suffix(".rs") {
      continue
    }
    let absolute_path = "\{repo}/\{relative_path}"
    let command = "rust-analyzer symbols < \{shell_escape(absolute_path)}"
    let (exit_code, stdout, stderr) = @build_shell.run_command_capture(command)
    if exit_code != 0 {
      let details = if stderr != "" { trim_spaces(stderr) } else { trim_spaces(stdout) }
      let message_details = if details == "" { "command failed" } else { details }
      return Err(
        extractor_error(
          "rust-analyzer symbols failed for \{relative_path}: \{message_details}",
        ),
      )
    }
    for raw_line in stdout.split("\n") {
      let line = trim_spaces(raw_line.to_string())
      if line == "" {
        continue
      }
      guard substring_between(line, "label: \"", "\"") is Some(raw_name) else {
        continue
      }
      guard substring_between(line, "kind: SymbolKind(", ")") is Some(raw_kind) else {
        continue
      }
      match rust_symbol_kind(raw_kind) {
        Some(kind) =>
          match inventory_key(profile, kind, raw_name) {
            Some(key) => @extract.append_unique_string(keys, key)
            None => ()
          }
        None => ()
      }
    }
  }
  keys.sort()
  Ok(keys)
}

///|
fn collect_lsp_inventory(
  config : @config.Config,
  repo : String,
  files : Array[String],
) -> Result[Array[String], @cli.CliError] {
  match config.profile {
    "go-module" => collect_go_lsp_inventory(config.profile, files, repo)
    "rust-crate" => collect_rust_lsp_inventory(config.profile, files, repo)
    _ => Ok([])
  }
}

///|
fn missing_inventory_keys(expected : Array[String], actual : Array[String]) -> Array[String] {
  let actual_set : Map[String, Bool] = {}
  for i in 0..<actual.length() {
    actual_set[actual[i]] = true
  }
  let missing : Array[String] = []
  for i in 0..<expected.length() {
    if !actual_set.contains(expected[i]) {
      missing.push(expected[i])
    }
  }
  missing
}

///|
fn validate_backend_inventory(
  profile : String,
  backend : String,
  inventory_keys : Array[String],
  declarations : Array[Json],
) -> Result[Unit, @cli.CliError] {
  let canonical_keys = inventory_keys_from_declarations(
    profile,
    inventory_validation_declarations(profile, declarations),
  )
  let missing = missing_inventory_keys(canonical_keys, inventory_keys)
  if missing.is_empty() {
    return Ok(())
  }
  let sample = if missing.length() > 6 {
    missing.view(end=6).to_array().join(", ") + ", ..."
  } else {
    missing.join(", ")
  }
  Err(
    extractor_error(
      "\{backend} inventory missed canonical API items for profile '\{profile}': \{sample}",
    ),
  )
}

///|
fn profile_language(profile : String) -> String {
  match profile {
    "go-module" => "go"
    "rust-crate" => "rust"
    "terraform-module" => "terraform"
    "openapi-spec" => "openapi"
    "policy-bundle" => "rego"
    _ => "generic"
  }
}

///|
fn enrich_declaration_metadata(record : Json) -> Unit {
  @extract.enrich_shape_metadata(record)
  match @extract.field_string(record, "language") {
    "go" => @extract_go.enrich_record(record)
    "rust" => @extract_rust.enrich_record(record)
    "terraform" => enrich_terraform_record(record)
    "openapi" => enrich_openapi_record(record)
    _ => ()
  }
}

///|
fn push_record(
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
  guard @extract.last_record(declarations) is Some(record) else {
    symbols.push(@extract.make_symbol(profile, path, line_no, kind, name, signature))
    return
  }
  enrich_declaration_metadata(record)
  symbols.push(@extract.make_symbol(profile, path, line_no, kind, name, signature))
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
fn terraform_kind_name(line : String) -> (String, String) {
  if line.has_prefix("resource ") {
    let parts = quoted_parts(line)
    if parts.length() >= 2 {
      return ("resource", "\{parts[0]}.\{parts[1]}")
    }
  }
  if line.has_prefix("data ") {
    let parts = quoted_parts(line)
    if parts.length() >= 2 {
      return ("data", "\{parts[0]}.\{parts[1]}")
    }
  }
  if line.has_prefix("variable ") {
    let parts = quoted_parts(line)
    if parts.length() >= 1 {
      return ("variable", parts[0])
    }
  }
  if line.has_prefix("output ") {
    let parts = quoted_parts(line)
    if parts.length() >= 1 {
      return ("output", parts[0])
    }
  }
  if line.has_prefix("module ") {
    let parts = quoted_parts(line)
    if parts.length() >= 1 {
      return ("module", parts[0])
    }
  }
  if line.has_prefix("provider ") {
    let parts = quoted_parts(line)
    if parts.length() >= 1 {
      return ("provider", parts[0])
    }
  }
  if line.has_prefix("locals") && line.has_suffix("{") {
    return ("locals", "locals")
  }
  if line.has_prefix("dynamic ") {
    let parts = quoted_parts(line)
    if parts.length() >= 1 {
      return ("dynamic", parts[0])
    }
  }
  if line.has_prefix("check ") {
    let parts = quoted_parts(line)
    if parts.length() >= 1 {
      return ("check", parts[0])
    }
  }
  if line.has_prefix("terraform") && line.has_suffix("{") {
    return ("terraform", "terraform")
  }
  ("", "")
}

///|
fn scan_terraform_attributes(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  line : String,
  active_block : String,
  declaration_start : Int,
) -> Unit {
  let clean = trim_spaces(line)
  if clean == "" {
    return
  }
  let target_name = terraform_language_record_name(active_block)

  if clean.has_prefix("type ") || clean.has_prefix("type=") {
    let ty = segment_after(clean, "=")
      .map(part => strip_braces(part))
      .unwrap_or(strip_braces(clean[4:].to_string()))
    let name = if active_block == "" { "type" } else { "\{active_block}.type" }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      "type_constraint",
      name,
      "type = \{ty}",
    )
      match @extract.last_record(declarations) {
        Some(record) => enrich_terraform_record(record)
        None => ()
      }
  }

  if clean.has_prefix("validation") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "validation"
    } else {
      "\{active_block}.validation"
    }
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "validation",
      name, clean,
    )
  }

  if clean.has_prefix("precondition") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "precondition"
    } else {
      "\{active_block}.precondition"
    }
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "precondition",
      name, clean,
    )
  }

  if clean.has_prefix("postcondition") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "postcondition"
    } else {
      "\{active_block}.postcondition"
    }
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "postcondition",
      name, clean,
    )
  }

  if clean.has_prefix("count ") || clean.has_prefix("count=") {
    let name = if active_block == "" {
      "count"
    } else {
      "\{active_block}.count"
    }
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "meta_count",
      name, clean,
    )
  }

  if clean.has_prefix("for_each ") || clean.has_prefix("for_each=") {
    let name = if active_block == "" {
      "for_each"
    } else {
      "\{active_block}.for_each"
    }
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "meta_for_each",
      name, clean,
    )
  }

  if clean.has_prefix("depends_on ") || clean.has_prefix("depends_on=") {
    let name = if active_block == "" {
      "depends_on"
    } else {
      "\{active_block}.depends_on"
    }
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "meta_depends_on",
      name, clean,
    )
    set_terraform_metadata(
      declarations,
      profile,
      path,
      declaration_start,
      target_name,
      "dependsOn",
      Json::array(terraform_depends_on_values(clean).map(Json::string)),
    )
  }

  if clean.has_prefix("lifecycle") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "lifecycle"
    } else {
      "\{active_block}.lifecycle"
    }
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "lifecycle",
      name, clean,
    )
  }

  if clean.has_prefix("required_providers") && clean.has_suffix("{") {
    push_simple_record(
      declarations, symbols, profile, server, "terraform", path, line_no, "required_providers",
      "required_providers", clean,
    )
  }

  if clean.has_prefix("sensitive ") || clean.has_prefix("sensitive=") {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_terraform_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "sensitive",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if clean.has_prefix("required ") || clean.has_prefix("required=") {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_terraform_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "required",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if active_block.has_prefix("resource.") &&
    (
      clean.has_prefix("prevent_destroy ") ||
      clean.has_prefix("prevent_destroy=")
    ) {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_terraform_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "preventDestroy",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if active_block.has_prefix("resource.") &&
    (
      clean.has_prefix("create_before_destroy ") ||
      clean.has_prefix("create_before_destroy=")
    ) {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_terraform_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "createBeforeDestroy",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if active_block.has_prefix("resource.") &&
    (clean.has_prefix("ignore_changes ") || clean.has_prefix("ignore_changes=")) {
    match segment_after(clean, "=") {
      Some(value) =>
        set_terraform_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          target_name,
          "ignoreChanges",
          Json::array(terraform_list_values(value).map(Json::string)),
        )
      None => ()
    }
  }

  if (clean.has_prefix("source ") || clean.has_prefix("source=")) &&
    active_block.has_prefix("module.") {
    match segment_after(clean, "=") {
      Some(value) =>
        set_terraform_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          target_name,
          "moduleSource",
          Json::string(trim_quotes(trim_spaces(value))),
        )
      None => ()
    }
  }

  if (clean.has_prefix("provider ") || clean.has_prefix("provider=")) &&
    (
      active_block.has_prefix("resource.") ||
      active_block.has_prefix("data.") ||
      active_block.has_prefix("provider.")
    ) {
    match segment_after(clean, "=") {
      Some(value) =>
        set_terraform_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          target_name,
          "providerRef",
          Json::string(trim_quotes(trim_spaces(value))),
        )
      None => ()
    }
  }
}

///|
fn terraform_provider_attr(block : @hcl.HclBlock, name : String) -> String {
  for i in 0..<block.attrs.length() {
    let attr = block.attrs[i]
    if attr.name == name {
      return trim_quotes(trim_spaces(attr.value))
    }
  }
  ""
}

///|
fn terraform_attr_value(block : @hcl.HclBlock, name : String) -> String {
  for i in 0..<block.attrs.length() {
    let attr = block.attrs[i]
    if attr.name == name {
      return trim_spaces(attr.value)
    }
  }
  ""
}

///|
fn terraform_provider_ref_parts(value : String) -> (String, String) {
  let trimmed = trim_quotes(trim_spaces(value))
  match trimmed.find(".") {
    Some(idx) =>
      (
        trimmed[0:idx].to_string() |> trim_spaces,
        trimmed[idx + 1:].to_string() |> trim_spaces,
      )
    None => (trimmed, "")
  }
}

///|
fn terraform_default_provider_name(name : String) -> String {
  let head = match name.find(".") {
    Some(idx) => name[0:idx].to_string()
    None => name
  }
  match head.find("_") {
    Some(idx) => head[0:idx].to_string()
    None => head
  }
}

///|
fn terraform_provider_info(
  provider_name : String,
  provider_alias : String,
  required_providers : Map[String, TerraformProviderInfo],
) -> TerraformProviderInfo {
  match required_providers.get(provider_name) {
    Some(info) => {
      let resolved_alias = if provider_alias != "" {
        provider_alias
      } else {
        info.provider_alias
      }
      {
        name: info.name,
        source: info.source,
        version: info.version,
        provider_alias: resolved_alias,
      }
    }
    None => { name: provider_name, source: "", version: "", provider_alias }
  }
}

///|
fn terraform_language_record_name(active_block : String) -> String {
  match active_block.find(".") {
    Some(idx) if idx + 1 < active_block.length() =>
      active_block[idx + 1:].to_string()
    _ => active_block
  }
}

///|
fn set_terraform_metadata(
  declarations : Array[Json],
  profile : String,
  path : String,
  declaration_start : Int,
  target_name : String,
  key : String,
  value : Json,
) -> Unit {
  if target_name == "" {
    return
  }
  let decl_id = @extract.declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) => {
      guard @extract.ensure_language_specific_profile(declarations[idx], "terraform")
        is Some(terraform) else {
        return
      }
      terraform[key] = value
    }
    None => ()
  }
}

///|
fn set_openapi_metadata(
  declarations : Array[Json],
  profile : String,
  path : String,
  declaration_start : Int,
  target_name : String,
  key : String,
  value : Json,
) -> Unit {
  if target_name == "" {
    return
  }
  let decl_id = @extract.declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) => {
      guard @extract.ensure_language_specific_profile(declarations[idx], "openapi")
        is Some(openapi) else {
        return
      }
      openapi[key] = value
    }
    None => ()
  }
}

///|
fn append_openapi_relation(
  declarations : Array[Json],
  profile : String,
  path : String,
  declaration_start : Int,
  target_name : String,
  kind : String,
  relation_target : String,
) -> Unit {
  if target_name == "" || kind == "" || relation_target == "" {
    return
  }
  let decl_id = @extract.declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) => @extract.append_relation(declarations[idx], kind, relation_target)
    None => ()
  }
}

///|
fn terraform_list_values(value : String) -> Array[String] {
  let body = trim_spaces(value)
  if body == "" {
    []
  } else {
    let trimmed = if body.has_prefix("[") && body.has_suffix("]") {
      body[1:body.length() - 1].to_string() |> trim_spaces
    } else {
      body
    }
    if trimmed == "" {
      []
    } else {
      split_top_level(trimmed, ',').map(part => trim_quotes(trim_spaces(part)))
      |> unique_trimmed_strings
    }
  }
}

///|
fn terraform_provider_map_refs(value : String) -> Array[String] {
  let body = trim_spaces(value)
  if body == "" {
    []
  } else {
    let trimmed = body.strip_prefix("{").unwrap_or(body).to_string()
      |> trim_spaces
    let inner = trimmed.strip_suffix("}").unwrap_or(trimmed).to_string()
      |> trim_spaces
    let refs : Array[String] = []
    if inner == "" {
      return refs
    }
    for entry in split_top_level(inner, ',') {
      match segment_after(entry, "=") {
        Some(provider_ref) =>
          @extract.append_unique_string(refs, trim_quotes(trim_spaces(provider_ref)))
        None => ()
      }
    }
    refs
  }
}

///|
fn terraform_depends_on_values(clean : String) -> Array[String] {
  segment_after(clean, "=").map(terraform_list_values).unwrap_or([])
}

///|
fn enrich_terraform_record(record : Json) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let name = @extract.field_string(record, "name")
  let signature = @extract.field_string(record, "signature")
  if kind == "module" {
    @extract.set_shape_string(record, "owner", name)
  }
  if kind == "type_constraint" {
    let ty = segment_after(signature, "=")
      .map(part => trim_spaces(part))
      .unwrap_or("")
    @extract.set_shape_string_array(record, "returns", if ty == "" { [] } else { [ty] })
  }
}

///|
fn find_declaration_index(
  declarations : Array[Json],
  id : String,
  start : Int,
) -> Int? {
  for i in start..<declarations.length() {
    if @extract.field_string(declarations[i], "id") == id {
      return Some(i)
    }
  }
  None
}

///|
fn collect_required_providers(
  lines : Array[String],
) -> Map[String, TerraformProviderInfo] {
  let providers : Map[String, TerraformProviderInfo] = {}
  let mut terraform_depth = 0
  let mut required_depth = 0
  let mut current_provider = ""
  let mut current_source = ""
  let mut current_version = ""

  for i in 0..<lines.length() {
    let line = trim_spaces(line_before_comment(lines[i].to_string()))
    if line == "" {
      continue
    }

    let terraform_starts = line.has_prefix("terraform") && line.has_suffix("{")
    let required_starts = terraform_depth > 0 &&
      current_provider == "" &&
      line.has_prefix("required_providers") &&
      line.has_suffix("{")
    let provider_starts = required_depth > 0 &&
      current_provider == "" &&
      line.has_suffix("{") &&
      line.contains("=")

    if provider_starts {
      let provider_name = token_before(line, "=")
      if provider_name != "" {
        current_provider = provider_name
        current_source = ""
        current_version = ""
      }
    } else if current_provider != "" {
      if line.has_prefix("source") {
        current_source = segment_after(line, "=")
          .map(part => trim_quotes(trim_spaces(part)))
          .unwrap_or("")
      } else if line.has_prefix("version") {
        current_version = segment_after(line, "=")
          .map(part => trim_quotes(trim_spaces(part)))
          .unwrap_or("")
      }
    }

    if line == "}" {
      if current_provider != "" {
        providers[current_provider] = {
          name: current_provider,
          source: current_source,
          version: current_version,
          provider_alias: "",
        }
        current_provider = ""
        current_source = ""
        current_version = ""
      } else if required_depth > 0 {
        required_depth = required_depth - 1
      } else if terraform_depth > 0 {
        terraform_depth = terraform_depth - 1
      }
      continue
    }

    if terraform_starts {
      terraform_depth = terraform_depth + 1
      continue
    }
    if required_starts {
      required_depth = required_depth + 1
      continue
    }
  }

  providers
}

///|
fn enrich_terraform_declarations(
  declarations : Array[Json],
  profile : String,
  path : String,
  declaration_start : Int,
  hcl_file : @hcl.HclFile,
  required_providers : Map[String, TerraformProviderInfo],
) -> Unit {
  let required_decl_id = @extract.declaration_id(profile, path, "required_providers")
  let provider_decl_ids : Map[String, String] = {}

  match
    find_declaration_index(declarations, required_decl_id, declaration_start) {
    Some(idx) => {
      let providers : Array[TerraformProviderInfo] = []
      for name, info in required_providers {
        ignore(name)
        providers.push(info)
      }
      providers.sort_by((a, b) => a.name.compare(b.name))
      set_terraform_providers(declarations[idx], providers)
    }
    None => ()
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "provider" {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    provider_decl_ids[block.name] = decl_id
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        let provider_alias = terraform_provider_attr(block, "alias")
        let info = terraform_provider_info(
          block.name,
          provider_alias,
          required_providers,
        )
        set_terraform_providers(declarations[idx], [info])
        if provider_alias != "" {
          match
            @extract.ensure_language_specific_profile(declarations[idx], "terraform") {
            Some(terraform) =>
              terraform["providerRef"] = Json::string(
                "\{block.name}.\{provider_alias}",
              )
            None => ()
          }
        }
        if required_providers.get(block.name) is Some(_) {
          @extract.append_relation(declarations[idx], "provided_by", required_decl_id)
        }
      }
      None => ()
    }
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "variable" {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) =>
        @extract.set_language_specific_bool(
          declarations[idx],
          "terraform",
          "required",
          terraform_attr_value(block, "default") == "",
        )
      None => ()
    }
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "module" {
      continue
    }
    let provider_refs = terraform_provider_map_refs(
      terraform_attr_value(block, "providers"),
    )
    if provider_refs.is_empty() {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        let providers : Array[TerraformProviderInfo] = []
        for j in 0..<provider_refs.length() {
          let provider_ref = provider_refs[j]
          let (provider_name, provider_alias) = terraform_provider_ref_parts(
            provider_ref,
          )
          if provider_name == "" {
            continue
          }
          let info = terraform_provider_info(
            provider_name, provider_alias, required_providers,
          )
          providers.push(info)
          let provider_decl_id = provider_decl_ids
            .get(provider_name)
            .unwrap_or(@extract.declaration_id(profile, path, provider_name))
          @extract.append_relation(declarations[idx], "uses_provider", provider_decl_id)
          if j == 0 {
            @extract.set_language_specific_string(
              declarations[idx],
              "terraform",
              "providerRef",
              provider_ref,
            )
          }
        }
        set_terraform_providers(declarations[idx], providers)
      }
      None => ()
    }
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "resource" && block.kind != "data" {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    let explicit_provider = terraform_provider_attr(block, "provider")
    let (provider_name, provider_alias) = if explicit_provider != "" {
      terraform_provider_ref_parts(explicit_provider)
    } else {
      (terraform_default_provider_name(block.name), "")
    }
    if provider_name == "" {
      continue
    }
    let info = terraform_provider_info(
      provider_name, provider_alias, required_providers,
    )
    let provider_decl_id = provider_decl_ids
      .get(provider_name)
      .unwrap_or(@extract.declaration_id(profile, path, provider_name))
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        set_terraform_providers(declarations[idx], [info])
        let provider_ref = if provider_alias == "" {
          provider_name
        } else {
          "\{provider_name}.\{provider_alias}"
        }
        @extract.set_language_specific_string(
          declarations[idx],
          "terraform",
          "providerRef",
          provider_ref,
        )
        @extract.append_relation(declarations[idx], "uses_provider", provider_decl_id)
      }
      None => ()
    }
  }
}

///|
fn extract_terraform_file(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
) -> Unit {
  let declaration_start = declarations.length()
  // Phase 1: emit block-level declaration records via lib/hcl parser.
  let hcl_file = @hcl.parse_hcl_file(lines)
  for block in hcl_file.blocks {
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      block.line_no,
      block.kind,
      block.name,
      block.signature,
    )
    match @extract.last_record(declarations) {
      Some(record) => enrich_terraform_record(record)
      None => ()
    }
  }

  // Phase 2: scan attribute-level records using the original line-by-line pass,
  // keeping active_block context identical to the previous implementation.
  let mut active_block = ""
  let block_stack : Array[String] = []

  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_spaces(lines[i].to_string())

    if line.has_suffix("{") {
      let (kind, name) = terraform_kind_name(line)
      let next_active = if kind == "" {
        active_block
      } else {
        "\{kind}.\{name}"
      }
      block_stack.push(next_active)
      active_block = next_active
      if kind != "" {
        // Block-level declarations are already emitted by the lib/hcl parser path.
        continue
      }
    }

    if line == "}" {
      if !block_stack.is_empty() {
        ignore(block_stack.pop())
      }
      active_block = if block_stack.is_empty() {
        ""
      } else {
        block_stack[block_stack.length() - 1]
      }
      continue
    }

    scan_terraform_attributes(
      declarations, symbols, profile, server, path, line_no, line, active_block,
      declaration_start,
    )
  }

  enrich_terraform_declarations(
    declarations,
    profile,
    path,
    declaration_start,
    hcl_file,
    collect_required_providers(lines),
  )
}

///|
fn openapi_operation(line : String) -> String {
  match line {
    "get:" => "GET"
    "post:" => "POST"
    "put:" => "PUT"
    "delete:" => "DELETE"
    "patch:" => "PATCH"
    "head:" => "HEAD"
    "options:" => "OPTIONS"
    "trace:" => "TRACE"
    _ => ""
  }
}

///|
fn openapi_component_kind(section : String) -> String {
  match section {
    "schemas" => "schema"
    "parameters" => "parameter"
    "responses" => "response"
    "requestBodies" => "requestBody"
    "headers" => "header"
    "securitySchemes" => "security_scheme"
    "links" => "link"
    "callbacks" => "callback"
    "pathItems" => "path_item"
    "webhooks" => "webhook"
    _ => "component"
  }
}

///|
fn openapi_component_signature(section : String, name : String) -> String {
  if section == "" {
    "component \{name}"
  } else {
    "\{section} \{name}"
  }
}

///|
fn openapi_block_end(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Int {
  for i in (start_index + 1)..<lines.length() {
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    if line == "" {
      continue
    }
    if leading_spaces(raw_line) <= start_indent {
      return i
    }
  }
  lines.length()
}

///|
fn openapi_line_key(line : String) -> String {
  trim_quotes(trim_spaces(line.strip_suffix(":").unwrap_or(line).to_string()))
}

///|
fn openapi_value_after_colon(line : String) -> String {
  match line.find(":") {
    Some(idx) => trim_quotes(trim_spaces(line[idx + 1:].to_string()))
    None => ""
  }
}

///|
fn openapi_required_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Bool? {
  let end_index = openapi_block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = trim_spaces(lines[i].to_string())
    if line.has_prefix("required:") {
      return parse_bool_literal(openapi_value_after_colon(line))
    }
  }
  None
}

///|
fn openapi_parameter_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> String {
  let end_index = openapi_block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = trim_spaces(lines[i].to_string())
    if line.has_prefix("in:") {
      return openapi_value_after_colon(line)
    }
  }
  ""
}

///|
fn openapi_media_types_in_range(
  lines : Array[String],
  start_index : Int,
  end_index : Int,
) -> Array[String] {
  let media_types : Array[String] = []
  let mut content_indent = -1
  for i in start_index..<end_index {
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    if line == "" {
      continue
    }
    let indent = leading_spaces(raw_line)
    if line == "content:" {
      content_indent = indent
      continue
    }
    if content_indent >= 0 {
      if indent <= content_indent {
        content_indent = -1
      } else if indent == content_indent + 2 && line.has_suffix(":") {
        let media_type = openapi_line_key(line)
        if media_type.contains("/") {
          @extract.append_unique_string(media_types, media_type)
        }
      }
    }
  }
  media_types
}

///|
fn openapi_media_types_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Array[String] {
  openapi_media_types_in_range(
    lines,
    start_index + 1,
    openapi_block_end(lines, start_index, start_indent),
  )
}

///|
fn openapi_component_response_name(ref_target : String) -> String {
  let prefix = "#/components/responses/"
  if ref_target.has_prefix(prefix) {
    ref_target[prefix.length():].to_string()
  } else {
    ""
  }
}

///|
fn collect_openapi_component_response_media_types(
  lines : Array[String],
) -> Map[String, Array[String]] {
  let responses : Map[String, Array[String]] = {}
  let mut in_components = false
  let mut components_indent = -1
  let mut in_responses = false
  let mut responses_indent = -1
  for i in 0..<lines.length() {
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    let indent = leading_spaces(raw_line)
    if line == "components:" {
      in_components = true
      components_indent = indent
      in_responses = false
      continue
    }
    if in_components &&
      line != "" &&
      indent <= components_indent &&
      line != "components:" {
      in_components = false
      in_responses = false
    }
    if !in_components {
      continue
    }
    if indent == components_indent + 2 && line.has_suffix(":") {
      let section = openapi_line_key(line)
      in_responses = section == "responses"
      responses_indent = indent
      continue
    }
    if in_responses && indent == responses_indent + 2 && line.has_suffix(":") {
      let name = openapi_line_key(line)
      responses[name] = openapi_media_types_in_block(lines, i, indent)
    }
  }
  responses
}

///|
fn openapi_status_codes_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Array[String] {
  let status_codes : Array[String] = []
  let end_index = openapi_block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    if line == "" {
      continue
    }
    if leading_spaces(raw_line) == start_indent + 2 && line.has_suffix(":") {
      @extract.append_unique_string(status_codes, openapi_line_key(line))
    }
  }
  status_codes
}

///|
fn openapi_response_media_types_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
  component_response_media_types : Map[String, Array[String]],
) -> Array[String] {
  let media_types : Array[String] = []
  let end_index = openapi_block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    if line == "" {
      continue
    }
    let indent = leading_spaces(raw_line)
    if indent == start_indent + 2 && line.has_suffix(":") {
      let status_end = openapi_block_end(lines, i, indent)
      let status_media_types = openapi_media_types_in_range(
        lines,
        i + 1,
        status_end,
      )
      for media_type in status_media_types {
        @extract.append_unique_string(media_types, media_type)
      }
      for j in (i + 1)..<status_end {
        let status_line = trim_spaces(lines[j].to_string())
        if !status_line.contains("$ref:") {
          continue
        }
        let response_name = openapi_component_response_name(
          normalize_reference_target(status_line),
        )
        if response_name == "" {
          continue
        }
        match component_response_media_types.get(response_name) {
          Some(response_media_types) =>
            for media_type in response_media_types {
              @extract.append_unique_string(media_types, media_type)
            }
          None => ()
        }
      }
    }
  }
  media_types
}

///|
fn openapi_callback_expression_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> String {
  let end_index = openapi_block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    if line == "" || !line.has_suffix(":") {
      continue
    }
    let key = openapi_line_key(line)
    if key.has_prefix("{") {
      return key
    }
  }
  ""
}

///|
fn openapi_member_refs_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Array[String] {
  let refs : Array[String] = []
  let end_index = openapi_block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = trim_spaces(lines[i].to_string())
    if line.contains("$ref:") {
      @extract.append_unique_string(refs, normalize_reference_target(line))
    }
  }
  refs
}

///|
fn openapi_discriminator_property_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> String {
  let end_index = openapi_block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = trim_spaces(lines[i].to_string())
    if line.has_prefix("propertyName:") {
      return openapi_value_after_colon(line)
    }
  }
  ""
}

///|
fn openapi_discriminator_mapping_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Map[String, String] {
  let mapping : Map[String, String] = {}
  let end_index = openapi_block_end(lines, start_index, start_indent)
  let mut mapping_indent = -1
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    if line == "" {
      continue
    }
    let indent = leading_spaces(raw_line)
    if line == "mapping:" {
      mapping_indent = indent
      continue
    }
    if mapping_indent >= 0 {
      if indent <= mapping_indent {
        mapping_indent = -1
      } else if indent == mapping_indent + 2 && line.contains(":") {
        mapping[token_before(line, ":")] = openapi_value_after_colon(line)
      }
    }
  }
  mapping
}

///|
fn openapi_string_map_json(mapping : Map[String, String]) -> Json {
  let object : Map[String, Json] = {}
  for key, value in mapping {
    if value != "" {
      object[key] = Json::string(value)
    }
  }
  Json::object(object)
}

///|
fn enrich_openapi_record(record : Json) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let name = @extract.field_string(record, "name")
  if kind == "operation" {
    match name.find(" ") {
      Some(idx) if idx > 0 =>
        @extract.set_language_specific_string(
          record,
          "openapi",
          "httpMethod",
          name[0:idx].to_string() |> trim_spaces,
        )
      _ => ()
    }
  }
  if kind == "reference" {
    @extract.set_language_specific_string(record, "openapi", "ref", name)
  }
  if kind == "security_scheme" {
    @extract.set_language_specific_string(record, "openapi", "securitySchemeName", name)
  }
}

///|
fn extract_openapi_file(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
) -> Unit {
  let declaration_start = declarations.length()
  let component_response_media_types = collect_openapi_component_response_media_types(
    lines,
  )
  let mut in_paths = false
  let mut in_webhooks = false
  let mut current_path = ""
  let mut in_components = false
  let mut components_indent = -1
  let mut current_component_section = ""
  let mut current_component_name = ""
  let mut current_operation = ""
  let mut active_callback_expression = ""
  let mut active_callback_expression_indent = -1

  for i in 0..<lines.length() {
    let line_no = i + 1
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    let indent = leading_spaces(raw_line)

    if active_callback_expression != "" &&
      indent <= active_callback_expression_indent &&
      !openapi_line_key(line).has_prefix("{") {
      active_callback_expression = ""
      active_callback_expression_indent = -1
    }

    if line == "paths:" {
      in_paths = true
      in_webhooks = false
      in_components = false
      continue
    }
    if line == "components:" {
      in_paths = false
      in_webhooks = false
      in_components = true
      components_indent = indent
      current_component_section = ""
      current_component_name = ""
      continue
    }
    if line == "webhooks:" {
      in_paths = false
      in_components = false
      in_webhooks = true
      current_path = ""
      current_operation = ""
      active_callback_expression = ""
      active_callback_expression_indent = -1
      continue
    }

    if line.has_suffix(":") {
      let key = openapi_line_key(line)
      if key.has_prefix("{") {
        active_callback_expression = key
        active_callback_expression_indent = indent
      }
    }

    if indent == 0 &&
      line.has_suffix(":") &&
      line != "paths:" &&
      line != "components:" &&
      line != "webhooks:" {
      in_paths = false
      in_webhooks = false
      in_components = false
      current_component_section = ""
      current_component_name = ""
      current_path = ""
      current_operation = ""
    }

    if in_components &&
      indent <= components_indent &&
      !(line == "components:" || line == "webhooks:") {
      in_components = false
      current_component_section = ""
      current_component_name = ""
    }

    if in_components && indent == components_indent + 2 && line.has_suffix(":") {
      current_component_section = line
        .strip_suffix(":")
        .unwrap_or(line)
        .to_string()
      current_component_name = ""
      continue
    }

    if in_paths && indent == 2 && line.has_prefix("/") && line.has_suffix(":") {
      match line.strip_suffix(":") {
        Some(value) => current_path = value.to_string()
        None => current_path = line
      }
      current_operation = ""
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "path",
        current_path,
        "path \{current_path}",
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      continue
    }
    if in_webhooks &&
      indent == 2 &&
      line.has_suffix(":") &&
      openapi_operation(line) == "" {
      match line.strip_suffix(":") {
        Some(value) => current_path = value.to_string()
        None => current_path = line
      }
      current_operation = ""
      continue
    }

    if (in_paths || in_webhooks) && indent == 4 {
      let http_method = openapi_operation(line)
      if http_method != "" {
        let name = "\{http_method} \{current_path}"
        current_operation = name
        push_simple_record(
          declarations, symbols, profile, server, "openapi", path, line_no, "operation",
          name, name,
        )
        match @extract.last_record(declarations) {
          Some(record) => enrich_openapi_record(record)
          None => ()
        }
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "httpMethod",
          Json::string(http_method),
        )
      }
    }

    if in_components &&
      current_component_section != "" &&
      line.has_suffix(":") &&
      indent == components_indent + 4 {
      let name = line.strip_suffix(":").unwrap_or(line).to_string()
      if name != "properties" && name != "required" {
        current_component_name = name
        let kind = openapi_component_kind(current_component_section)
        push_simple_record(
          declarations,
          symbols,
          profile,
          server,
          "openapi",
          path,
          line_no,
          kind,
          name,
          openapi_component_signature(current_component_section, name),
        )
        match @extract.last_record(declarations) {
          Some(record) => enrich_openapi_record(record)
          None => ()
        }
        if kind == "parameter" {
          let parameter_in = openapi_parameter_in_block(lines, i, indent)
          if parameter_in != "" {
            set_openapi_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              name,
              "parameterIn",
              Json::string(parameter_in),
            )
          }
          match openapi_required_in_block(lines, i, indent) {
            Some(required) =>
              set_openapi_metadata(
                declarations,
                profile,
                path,
                declaration_start,
                name,
                "required",
                Json::boolean(required),
              )
            None => ()
          }
        }
        if kind == "requestBody" {
          match openapi_required_in_block(lines, i, indent) {
            Some(required) =>
              set_openapi_metadata(
                declarations,
                profile,
                path,
                declaration_start,
                name,
                "required",
                Json::boolean(required),
              )
            None => ()
          }
          let media_types = openapi_media_types_in_block(lines, i, indent)
          if !media_types.is_empty() {
            set_openapi_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              name,
              "mediaTypes",
              Json::array(media_types.map(Json::string)),
            )
          }
        }
        if kind == "response" {
          let media_types = openapi_media_types_in_block(lines, i, indent)
          if !media_types.is_empty() {
            set_openapi_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              name,
              "mediaTypes",
              Json::array(media_types.map(Json::string)),
            )
          }
        }
        if kind == "security_scheme" {
          let block_end = openapi_block_end(lines, i, indent)
          for j in (i + 1)..<block_end {
            let child_raw = lines[j].to_string()
            let child_line = trim_spaces(child_raw)
            if child_line.has_prefix("type:") {
              let value = openapi_value_after_colon(child_line)
              if value != "" {
                set_openapi_metadata(
                  declarations,
                  profile,
                  path,
                  declaration_start,
                  name,
                  "securitySchemeType",
                  Json::string(value),
                )
              }
            } else if child_line.has_prefix("in:") {
              let value = openapi_value_after_colon(child_line)
              if value != "" {
                set_openapi_metadata(
                  declarations,
                  profile,
                  path,
                  declaration_start,
                  name,
                  "securitySchemeIn",
                  Json::string(value),
                )
              }
            } else if child_line.has_prefix("name:") {
              let value = openapi_value_after_colon(child_line)
              if value != "" {
                set_openapi_metadata(
                  declarations,
                  profile,
                  path,
                  declaration_start,
                  name,
                  "securitySchemeName",
                  Json::string(value),
                )
              }
            }
          }
        }
      }
    }

    if (in_paths || in_webhooks) && line.has_prefix("parameters:") {
      let scope = if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      if scope != "" {
        push_simple_record(
          declarations,
          symbols,
          profile,
          server,
          "openapi",
          path,
          line_no,
          "parameters",
          scope,
          "parameters \{scope}",
        )
        match @extract.last_record(declarations) {
          Some(record) => enrich_openapi_record(record)
          None => ()
        }
        let block_end = openapi_block_end(lines, i, indent)
        for j in (i + 1)..<block_end {
          let child_raw = lines[j].to_string()
          let child_line = trim_spaces(child_raw)
          if leading_spaces(child_raw) != indent + 2 ||
            !child_line.has_prefix("- name:") {
            continue
          }
          let parameter_name = openapi_value_after_colon(
            child_line[1:].to_string(),
          )
          if parameter_name == "" {
            continue
          }
          push_simple_record(
            declarations,
            symbols,
            profile,
            server,
            "openapi",
            path,
            j + 1,
            "parameter",
            parameter_name,
            "parameters \{parameter_name}",
          )
          match @extract.last_record(declarations) {
            Some(record) => enrich_openapi_record(record)
            None => ()
          }
          let parameter_in = openapi_parameter_in_block(lines, j, indent + 2)
          if parameter_in != "" {
            set_openapi_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              parameter_name,
              "parameterIn",
              Json::string(parameter_in),
            )
          }
          let required = match openapi_required_in_block(lines, j, indent + 2) {
            Some(value) => Some(value)
            None => if parameter_in == "path" { Some(true) } else { None }
          }
          match required {
            Some(value) =>
              set_openapi_metadata(
                declarations,
                profile,
                path,
                declaration_start,
                parameter_name,
                "required",
                Json::boolean(value),
              )
            None => ()
          }
          append_openapi_relation(
            declarations,
            profile,
            path,
            declaration_start,
            scope,
            "has_parameter",
            @extract.declaration_id(profile, path, parameter_name),
          )
        }
      }
    }

    if (in_paths || in_webhooks) &&
      line.has_prefix("requestBody:") &&
      current_operation != "" {
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "requestBody",
        current_operation,
        "requestBody \{current_operation}",
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      match openapi_required_in_block(lines, i, indent) {
        Some(required) =>
          set_openapi_metadata(
            declarations,
            profile,
            path,
            declaration_start,
            current_operation,
            "required",
            Json::boolean(required),
          )
        None => ()
      }
      let media_types = openapi_media_types_in_block(lines, i, indent)
      if !media_types.is_empty() {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          current_operation,
          "mediaTypes",
          Json::array(media_types.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks) &&
      line == "responses:" &&
      current_operation != "" {
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "responses",
        current_operation,
        "responses \{current_operation}",
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      let status_codes = openapi_status_codes_in_block(lines, i, indent)
      if !status_codes.is_empty() {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          current_operation,
          "statusCodes",
          Json::array(status_codes.map(Json::string)),
        )
      }
      let media_types = openapi_response_media_types_in_block(
        lines, i, indent, component_response_media_types,
      )
      if !media_types.is_empty() {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          current_operation,
          "mediaTypes",
          Json::array(media_types.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks || in_components) && line.contains("allOf:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" { "allOf" } else { "\{scope}.allOf" }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "allOf",
        name, line,
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      let member_refs = openapi_member_refs_in_block(lines, i, indent)
      if !member_refs.is_empty() {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "memberRefs",
          Json::array(member_refs.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks || in_components) && line.contains("oneOf:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" { "oneOf" } else { "\{scope}.oneOf" }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "oneOf",
        name, line,
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      let member_refs = openapi_member_refs_in_block(lines, i, indent)
      if !member_refs.is_empty() {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "memberRefs",
          Json::array(member_refs.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks || in_components) && line.contains("anyOf:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" { "anyOf" } else { "\{scope}.anyOf" }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "anyOf",
        name, line,
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      let member_refs = openapi_member_refs_in_block(lines, i, indent)
      if !member_refs.is_empty() {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "memberRefs",
          Json::array(member_refs.map(Json::string)),
        )
      }
    }

    if line.has_prefix("discriminator:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "discriminator",
        if scope == "" {
          "discriminator"
        } else {
          "\{scope}.discriminator"
        },
        line,
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      set_openapi_metadata(
        declarations,
        profile,
        path,
        declaration_start,
        if scope == "" {
          "discriminator"
        } else {
          "\{scope}.discriminator"
        },
        "discriminatorProperty",
        Json::string(openapi_discriminator_property_in_block(lines, i, indent)),
      )
      let mapping = openapi_discriminator_mapping_in_block(lines, i, indent)
      if !mapping.is_empty() {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          if scope == "" {
            "discriminator"
          } else {
            "\{scope}.discriminator"
          },
          "discriminatorMapping",
          openapi_string_map_json(mapping),
        )
      }
    }

    if line.has_prefix("security:") {
      let scope = if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "security",
        if scope == "" {
          "security"
        } else {
          scope
        },
        line,
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      let callback_expression = openapi_callback_expression_in_block(
        lines, i, indent,
      )
      if callback_expression != "" {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          if scope == "" {
            "callbacks"
          } else {
            scope
          },
          "callbackExpression",
          Json::string(callback_expression),
        )
      }
    }

    if line.has_prefix("callbacks:") {
      let scope = if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "callbacks",
        if scope == "" {
          "callbacks"
        } else {
          scope
        },
        line,
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
    }

    if line.contains("$ref:") {
      let ref_target = normalize_reference_target(line)
      if ref_target != "" {
        push_simple_record(
          declarations, symbols, profile, server, "openapi", path, line_no, "reference",
          ref_target, line,
        )
        match @extract.last_record(declarations) {
          Some(record) => enrich_openapi_record(record)
          None => ()
        }
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          ref_target,
          "ref",
          Json::string(ref_target),
        )
      }
    }

    if line.has_prefix("operationId:") {
      let name = trim_spaces(line[12:].to_string())
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "operation",
        name,
        "operation \{name}",
      )
      match @extract.last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      set_openapi_metadata(
        declarations,
        profile,
        path,
        declaration_start,
        name,
        "operationId",
        Json::string(name),
      )
      if active_callback_expression != "" {
        set_openapi_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "callbackExpression",
          Json::string(active_callback_expression),
        )
      }
      current_operation = name
    }
  }
}

///|
fn extract_policy_file(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
) -> Unit {
  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_spaces(line_before_comment(lines[i]))
    if line == "" {
      continue
    }
    if line.has_prefix("package ") {
      let package_name = trim_spaces(line[8:].to_string())
      push_simple_record(
        declarations, symbols, profile, server, "rego", path, line_no, "package",
        package_name, "package \\{package_name}",
      )
      continue
    }
    if line.contains(" if ") && line.contains("{") {
      let rule_name = first_token(line)
      if rule_name != "" {
        push_simple_record(
          declarations, symbols, profile, server, "rego", path, line_no, "policy_rule",
          rule_name, line,
        )
      }
      continue
    }
    if line.contains(":=") {
      let rule_name = first_token(line)
      if rule_name != "" {
        push_simple_record(
          declarations, symbols, profile, server, "rego", path, line_no, "policy_rule",
          rule_name, line,
        )
      }
    }
  }
}

///|
fn collect_records(
  config : @config.Config,
  repo : String,
  files : Array[String],
  server : String,
) -> Result[(Array[Json], Array[Json]), @cli.CliError] {
  let declarations : Array[Json] = []
  let symbols : Array[Json] = []

  for i in 0..<files.length() {
    let relative_path = files[i]
    let absolute_path = "\{repo}/\{relative_path}"
    let content = @fs.read_file_to_string(absolute_path) catch {
      err =>
        return Err(
          extractor_error(
            "cannot read source file \{absolute_path}: \{err.to_string()}",
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
        extract_terraform_file(
          declarations,
          symbols,
          config.profile,
          server,
          relative_path,
          lines,
        )
      "openapi-spec" =>
        extract_openapi_file(
          declarations,
          symbols,
          config.profile,
          server,
          relative_path,
          lines,
        )
      "policy-bundle" =>
        extract_policy_file(
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

  Ok((
    @extract.sort_and_dedup(declarations, "id"),
    @extract.sort_and_dedup(symbols, "id"),
  ))
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
      "codeiq.yaml",
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
fn extract_lsp_baseline(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let files_out = resolve_input_files(config, repo)
  guard files_out is Ok(files) else { return Err(files_out.unwrap_err()) }

  let (_, server) = profile_mode(config.profile)
  let mode = match config.profile {
    "go-module" => "lsp-assisted"
    "rust-crate" => "lsp-assisted"
    _ => "parser-first"
  }
  let (server_version, probe_failed) = lsp_runtime_probe(config.profile, server)
  let force_lsp_hardfail = @sys.get_env_var("CODEIQ_TEST_FORCE_LSP_FALLBACK")
    is Some("true")
  if probe_failed &&
    (config.profile == "go-module" || config.profile == "rust-crate") &&
    force_lsp_hardfail {
    return Err(
      extractor_error(
        "LSP server '\{server}' is required for profile '\{config.profile}' but could not be started: \{server_version}",
      ),
    )
  }
  let fallback = probe_failed
  let inventory_out = if probe_failed {
    Ok([])
  } else {
    collect_lsp_inventory(config, repo, files)
  }
  guard inventory_out is Ok(inventory_keys) else {
    return Err(inventory_out.unwrap_err())
  }
  let records_out = collect_records(config, repo, files, server)
  guard records_out is Ok((declarations, symbols)) else {
    return Err(records_out.unwrap_err())
  }

  ensure_non_empty(declarations, symbols, config.profile, server)
  let final_declarations = @extract.sort_and_dedup(declarations, "id")
  let final_symbols = @extract.sort_and_dedup(symbols, "id")
  if !fallback {
    let inventory_check = validate_backend_inventory(
      config.profile,
      "lsp",
      inventory_keys,
      final_declarations,
    )
    guard inventory_check is Ok(_) else {
      return Err(inventory_check.unwrap_err())
    }
  }

  Ok({
    declarations_text: @extract.to_ndjson(final_declarations),
    symbols_text: @extract.to_ndjson(final_symbols),
    mode,
    fallback,
    declaration_count: final_declarations.length(),
    symbol_count: final_symbols.length(),
    diagnostic_files: 0,
    commit: resolve_git_commit(repo),
  })
}

///|
fn extract_canonical(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let out = @sdk_index.build_local_index_canonical(config, repo)
  guard out is Ok(sdk_out) else {
    return Err(extractor_error(out.unwrap_err()))
  }
  Ok({
    declarations_text: sdk_out.declarations_text,
    symbols_text: sdk_out.symbols_text,
    mode: sdk_out.mode,
    fallback: sdk_out.fallback,
    declaration_count: sdk_out.declaration_count,
    symbol_count: sdk_out.symbol_count,
    diagnostic_files: sdk_out.diagnostic_files,
    commit: sdk_out.commit,
  })
}

///|
fn validate_with_lsp(
  config : @config.Config,
) -> Result[Unit, @cli.CliError] {
  let (_, server) = profile_mode(config.profile)
  let (server_version, probe_failed) = lsp_runtime_probe(config.profile, server)
  let force_lsp_hardfail = @sys.get_env_var("CODEIQ_TEST_FORCE_LSP_FALLBACK")
    is Some("true")
  if probe_failed &&
    (config.profile == "go-module" || config.profile == "rust-crate") &&
    force_lsp_hardfail {
    return Err(
      extractor_error(
        "LSP server '\{server}' is required for profile '\{config.profile}' but could not be started: \{server_version}",
      ),
    )
  }
  Ok(())
}

///|
/// extract_native uses the in-repo MoonBit extractor (sdk/index) directly,
/// emitting native-assisted mode metadata without any external binary dependency.
fn extract_native(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let out = @sdk_index.build_local_index_native(config, repo)
  guard out is Ok(sdk_out) else {
    return Err(extractor_error(out.unwrap_err()))
  }
  Ok({
    declarations_text: sdk_out.declarations_text,
    symbols_text: sdk_out.symbols_text,
    mode: sdk_out.mode,
    fallback: sdk_out.fallback,
    declaration_count: sdk_out.declaration_count,
    symbol_count: sdk_out.symbol_count,
    diagnostic_files: sdk_out.diagnostic_files,
    commit: sdk_out.commit,
  })
}

///|
/// extract_build is the shared extractor entry for build.
/// S3 keeps backend selection internal and only returns canonical output metadata.
fn extract_build(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let backend = resolve_backend_override()
  let extract_out = match backend {
    "native" => extract_native(config, repo)
    "lsp" => extract_lsp_baseline(config, repo)
    _ => extract_canonical(config, repo)
  }
  guard extract_out is Ok(extract) else {
    return Err(extract_out.unwrap_err())
  }
  if backend == "canonical" && resolve_validation_mode(config) == "lsp" {
    let validation_out = validate_with_lsp(config)
    guard validation_out is Ok(_) else { return Err(validation_out.unwrap_err()) }
  }
  Ok(extract)
}
