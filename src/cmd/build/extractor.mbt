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
fn segment_after(value : String, marker : String) -> String? {
  match value.find(marker) {
    Some(idx) => Some(value[idx + marker.length():].to_string())
    None => None
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
  match @sys.get_env_var("COGNA_EXTRACTOR_BACKEND") {
    Some("native") => "native"
    Some("lsp") => "lsp"
    Some("canonical") => "canonical"
    Some("none") => "canonical"
    _ => "canonical"
  }
}

///|
fn resolve_validation_mode(config : @config.Config) -> String {
  match @sys.get_env_var("COGNA_EXTRACTOR_BACKEND") {
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
  if @sys.get_env_var("COGNA_TEST_FORCE_LSP_FALLBACK") is Some("true") &&
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
    if inventory_validation_path_allowed(
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
    match
      inventory_key(
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
      let details = if stderr != "" {
        trim_spaces(stderr)
      } else {
        trim_spaces(stdout)
      }
      let message_details = if details == "" {
        "command failed"
      } else {
        details
      }
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
      guard last_code_unit_index(trimmed, ' ') is Some(last_space) else {
        continue
      }
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
      let details = if stderr != "" {
        trim_spaces(stderr)
      } else {
        trim_spaces(stdout)
      }
      let message_details = if details == "" {
        "command failed"
      } else {
        details
      }
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
fn missing_inventory_keys(
  expected : Array[String],
  actual : Array[String],
) -> Array[String] {
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
    "terraform" => @extract_terraform.enrich_record(record)
    "openapi" => @extract_openapi.enrich_record(record)
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
    symbols.push(
      @extract.make_symbol(profile, path, line_no, kind, name, signature),
    )
    return
  }
  enrich_declaration_metadata(record)
  symbols.push(
    @extract.make_symbol(profile, path, line_no, kind, name, signature),
  )
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

  Ok(
    (
      @extract.sort_and_dedup(declarations, "id"),
      @extract.sort_and_dedup(symbols, "id"),
    ),
  )
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
  let force_lsp_hardfail = @sys.get_env_var("COGNA_TEST_FORCE_LSP_FALLBACK")
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
  let out = build_local_index_canonical(config, repo)
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
fn validate_with_lsp(config : @config.Config) -> Result[Unit, @cli.CliError] {
  let (_, server) = profile_mode(config.profile)
  let (server_version, probe_failed) = lsp_runtime_probe(config.profile, server)
  let force_lsp_hardfail = @sys.get_env_var("COGNA_TEST_FORCE_LSP_FALLBACK")
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
  let out = build_local_index_native(config, repo)
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
  guard extract_out is Ok(extract) else { return Err(extract_out.unwrap_err()) }
  if backend == "canonical" && resolve_validation_mode(config) == "lsp" {
    let validation_out = validate_with_lsp(config)
    guard validation_out is Ok(_) else {
      return Err(validation_out.unwrap_err())
    }
  }
  Ok(extract)
}
