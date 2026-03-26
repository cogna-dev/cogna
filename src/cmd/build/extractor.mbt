///|
priv struct ExtractOutput {
  declarations_text : String
  symbols_text : String
  mode : String
  server : String
  version : String
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
fn declaration_id(profile : String, path : String, name : String) -> String {
  let canonical = canonical_name(profile, path, name)
  "decl:\{profile}:\{canonical}"
}

///|
fn append_relation(record : Json, kind : String, target : String) -> Unit {
  guard record is Object(record_object) else { return }
  match record_object.get("relations") {
    Some(Array(relations)) => push_unique_relation(relations, kind, target)
    _ => ()
  }
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
  guard record_object.get("language_specific") is Some(Object(language_specific)) else {
    return
  }
  let providers_object : Map[String, Json] = {}
  providers_object["terraform"] = Json::array(
    providers.map(info => terraform_provider_json(info)),
  )
  language_specific["providers"] = Json::object(providers_object)
}

///|
fn last_record(records : Array[Json]) -> Json? {
  if records.is_empty() {
    None
  } else {
    Some(records[records.length() - 1])
  }
}

///|
fn ensure_shape_object(record : Json) -> Map[String, Json]? {
  guard record is Object(record_object) else { return None }
  match record_object.get("shape") {
    Some(Object(shape)) => Some(shape)
    _ => None
  }
}

///|
fn ensure_language_specific_profile(
  record : Json,
  profile_key : String,
) -> Map[String, Json]? {
  guard record is Object(record_object) else { return None }
  guard record_object.get("language_specific") is Some(Object(language_specific)) else {
    return None
  }
  match language_specific.get(profile_key) {
    Some(Object(profile_object)) => Some(profile_object)
    _ => {
      let profile_object : Map[String, Json] = {}
      language_specific[profile_key] = Json::object(profile_object)
      Some(profile_object)
    }
  }
}

///|
fn set_shape_string(record : Json, key : String, value : String) -> Unit {
  if value == "" {
    return
  }
  guard ensure_shape_object(record) is Some(shape) else { return }
  shape[key] = Json::string(value)
}

///|
fn set_shape_string_array(record : Json, key : String, values : Array[String]) -> Unit {
  if values.is_empty() {
    return
  }
  guard ensure_shape_object(record) is Some(shape) else { return }
  shape[key] = Json::array(values.map(Json::string))
}

///|
fn put_shape_string_array(record : Json, key : String, values : Array[String]) -> Unit {
  guard ensure_shape_object(record) is Some(shape) else { return }
  shape[key] = Json::array(values.map(Json::string))
}

///|
fn set_language_specific_string(
  record : Json,
  profile_key : String,
  key : String,
  value : String,
) -> Unit {
  if value == "" {
    return
  }
  guard ensure_language_specific_profile(record, profile_key) is Some(profile_object) else {
    return
  }
  profile_object[key] = Json::string(value)
}

///|
fn set_language_specific_bool(
  record : Json,
  profile_key : String,
  key : String,
  value : Bool,
) -> Unit {
  guard ensure_language_specific_profile(record, profile_key) is Some(profile_object) else {
    return
  }
  profile_object[key] = Json::boolean(value)
}

///|
fn set_language_specific_string_array(
  record : Json,
  profile_key : String,
  key : String,
  values : Array[String],
) -> Unit {
  if values.is_empty() {
    return
  }
  guard ensure_language_specific_profile(record, profile_key) is Some(profile_object) else {
    return
  }
  profile_object[key] = Json::array(values.map(Json::string))
}

///|
fn shape_string(record : Json, key : String) -> String {
  guard ensure_shape_object(record) is Some(shape) else { return "" }
  match shape.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
fn language_specific_profile_string(
  record : Json,
  profile_key : String,
  key : String,
) -> String {
  guard record is Object(record_object) else { return "" }
  guard record_object.get("language_specific") is Some(Object(language_specific)) else {
    return ""
  }
  guard language_specific.get(profile_key) is Some(Object(profile_object)) else {
    return ""
  }
  match profile_object.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
fn language_specific_profile_bool(
  record : Json,
  profile_key : String,
  key : String,
) -> Bool? {
  guard record is Object(record_object) else { return None }
  guard record_object.get("language_specific") is Some(Object(language_specific)) else {
    return None
  }
  guard language_specific.get(profile_key) is Some(Object(profile_object)) else {
    return None
  }
  match profile_object.get(key) {
    Some(value) => parse_bool_literal(value.stringify())
    _ => None
  }
}

///|
fn set_record_relations(record : Json, relations : Array[Json]) -> Unit {
  guard record is Object(record_object) else { return }
  record_object["relations"] = Json::array(relations)
}

///|
fn filter_record_relations(record : Json, removed_kinds : Array[String]) -> Array[Json] {
  let filtered : Array[Json] = []
  guard record is Object(record_object) else { return filtered }
  guard record_object.get("relations") is Some(Array(relations)) else {
    return filtered
  }
  for i in 0..<relations.length() {
    guard relations[i] is Object(relation_object) else { continue }
    let kind = match relation_object.get("kind") {
      Some(String(value)) => value
      _ => ""
    }
    let mut removed = false
    for j in 0..<removed_kinds.length() {
      if kind == removed_kinds[j] {
        removed = true
        break
      }
    }
    if !removed {
      filtered.push(relations[i])
    }
  }
  filtered
}

///|
fn append_unique_string(values : Array[String], value : String) -> Unit {
  let trimmed = trim_spaces(value)
  if trimmed == "" {
    return
  }
  for i in 0..<values.length() {
    if values[i] == trimmed {
      return
    }
  }
  values.push(trimmed)
}

///|
fn contains_string(values : Array[String], target : String) -> Bool {
  for i in 0..<values.length() {
    if values[i] == target {
      return true
    }
  }
  false
}

///|
fn matching_delimiter_index(
  value : String,
  start : Int,
  open_char : UInt16,
  close_char : UInt16,
) -> Int? {
  let mut depth = 0
  for i in start..<value.length() {
    let c = value.code_unit_at(i)
    if c == open_char {
      depth = depth + 1
    } else if c == close_char {
      depth = depth - 1
      if depth == 0 {
        return Some(i)
      }
    }
  }
  None
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
    } else if c == delimiter && paren == 0 && bracket == 0 && brace == 0 && angle == 0 {
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
fn starts_with_any(value : String, prefixes : Array[String]) -> Bool {
  for i in 0..<prefixes.length() {
    if value.has_prefix(prefixes[i]) {
      return true
    }
  }
  false
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
    "go-module" => ("lsp-assisted", "gopls")
    "rust-crate" => ("lsp-assisted", "rust-analyzer")
    "terraform-module" => ("parser-first", "hcl-parser")
    "openapi-spec" => ("parser-only", "none")
    "policy-bundle" => ("policy-bundle", "opa")
    _ => ("parser-only", "none")
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
  let (exit_code, stdout, stderr) = @shell.run_command_capture(command)
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
fn declaration_shape(kind : String, signature : String) -> Json {
  let form = if signature.contains("(") && signature.contains(")") {
    "callable"
  } else {
    "symbol"
  }
  { "kind": kind, "subkind": kind, "form": form, "signature": signature }
}

///|
fn signature_type_params(signature : String) -> Array[String] {
  match signature.find("[") {
    Some(open_idx) => {
      let equals_idx = signature.find("=").unwrap_or(signature.length())
      let paren_idx = signature.find("(").unwrap_or(signature.length())
      if open_idx > equals_idx || open_idx > paren_idx {
        return []
      }
      match matching_delimiter_index(signature, open_idx, '[', ']') {
        Some(close_idx) if close_idx > open_idx + 1 =>
          split_top_level(signature[open_idx + 1:close_idx].to_string(), ',')
          .map(part => first_token(part))
          |> unique_trimmed_strings
        _ => []
      }
    }
    None => {
      match signature.find("<") {
        Some(open_idx) => {
          let equals_idx = signature.find("=").unwrap_or(signature.length())
          let paren_idx = signature.find("(").unwrap_or(signature.length())
          if open_idx > equals_idx || open_idx > paren_idx {
            return []
          }
          match matching_delimiter_index(signature, open_idx, '<', '>') {
            Some(close_idx) if close_idx > open_idx + 1 =>
              split_top_level(signature[open_idx + 1:close_idx].to_string(), ',')
              .map(part => first_token(part))
              |> unique_trimmed_strings
            _ => []
          }
        }
        None => []
      }
    }
  }
}

///|
fn signature_param_types(signature : String) -> Array[String] {
  match signature.find("(") {
    Some(open_idx) =>
      match matching_delimiter_index(signature, open_idx, '(', ')') {
        Some(close_idx) if close_idx > open_idx + 1 => {
          let body = signature[open_idx + 1:close_idx].to_string()
          if trim_spaces(body) == "" {
            []
          } else {
            split_top_level(body, ',')
            .map(part => {
              let candidate = trim_spaces(part)
              if candidate == "" {
                ""
              } else {
                match candidate.find(":") {
                  Some(idx) => candidate[idx + 1:].to_string() |> trim_spaces
                  None =>
                    match candidate.find(" ") {
                      Some(idx) => candidate[idx + 1:].to_string() |> trim_spaces
                      None => candidate
                    }
                }
              }
            })
            |> unique_trimmed_strings
          }
        }
        _ => []
      }
    None => []
  }
}

///|
fn signature_return_types(signature : String) -> Array[String] {
  let ret = parse_return_type(signature)
  if ret == "" {
    []
  } else {
    unique_trimmed_strings([ret])
  }
}

///|
fn enrich_shape_metadata(record : Json) -> Unit {
  let kind = field_string(record, "kind")
  let name = field_string(record, "name")
  let signature = field_string(record, "signature")
  if signature == "" {
    return
  }
  if kind == "method" ||
    kind == "field" ||
    kind == "embedded_field" ||
    kind == "associated_type" ||
    kind == "associated_const" ||
    kind == "associated_fn" {
    match name.find(".") {
      Some(idx) if idx > 0 =>
        set_shape_string(record, "owner", name[0:idx].to_string() |> trim_spaces)
      _ =>
        match name.find("::") {
          Some(idx) if idx > 0 =>
            set_shape_string(record, "owner", name[0:idx].to_string() |> trim_spaces)
          _ => ()
        }
    }
  }
  if kind == "function" ||
    kind == "method" ||
    kind == "associated_fn" ||
    kind == "struct" ||
    kind == "interface" ||
    kind == "trait" ||
    kind == "impl" {
    set_shape_string_array(record, "type_params", signature_type_params(signature))
  }
  if kind == "function" || kind == "method" || kind == "associated_fn" {
    set_shape_string_array(record, "parameters", signature_param_types(signature))
    set_shape_string_array(record, "returns", signature_return_types(signature))
  }
}

///|
fn parse_first_param(signature : String) -> String {
  match signature.find("(") {
    Some(open_idx) =>
      match signature.find(")") {
        Some(close_idx) if close_idx > open_idx + 1 => {
          let body = signature[open_idx + 1:close_idx].to_string()
            |> trim_spaces
          if body == "" {
            ""
          } else {
            let first = body.split(",").to_array()[0].to_string() |> trim_spaces
            match first.find(" ") {
              Some(space_idx) if space_idx > 0 =>
                first[space_idx + 1:].to_string() |> trim_spaces
              _ => first
            }
          }
        }
        _ => ""
      }
    _ => ""
  }
}

///|
fn parse_return_type(signature : String) -> String {
  match signature.find(")") {
    Some(close_idx) => {
      let tail = signature[close_idx + 1:].to_string() |> trim_spaces
      if tail.has_prefix("{") || tail == "" {
        return ""
      }
      if tail.has_prefix("->") {
        return tail[2:].to_string() |> trim_spaces |> strip_braces
      }
      if tail.has_prefix("(") ||
        tail.has_prefix("[") ||
        tail.has_prefix("*") ||
        tail.has_prefix("&") ||
        tail.has_prefix("string") ||
        tail.has_prefix("int") ||
        tail.has_prefix("bool") ||
        tail.has_prefix("float") ||
        tail.has_prefix("byte") ||
        tail.has_prefix("char") {
        return strip_braces(tail)
      }
      ""
    }
    _ => ""
  }
}

///|
fn push_unique_relation(
  relations : Array[Json],
  kind : String,
  target : String,
) -> Unit {
  if kind == "" || target == "" {
    return
  }
  let candidate = "\{kind}::\{target}"
  for i in 0..<relations.length() {
    guard relations[i] is Object(object) else { continue }
    let existing_kind = match object.get("kind") {
      Some(String(value)) => value
      _ => ""
    }
    let existing_target = match object.get("target") {
      Some(String(value)) => value
      _ => ""
    }
    if "\{existing_kind}::\{existing_target}" == candidate {
      return
    }
  }
  relations.push({ "kind": kind, "target": target })
}

///|
fn declaration_relations_v2(
  profile : String,
  path : String,
  kind : String,
  name : String,
  signature : String,
) -> Array[Json] {
  let relations : Array[Json] = []
  push_unique_relation(relations, "declared_in", "file:\{path}")

  if kind == "struct" ||
    kind == "enum" ||
    kind == "interface" ||
    kind == "trait" ||
    kind == "module" ||
    kind == "resource" ||
    kind == "schema" {
    push_unique_relation(relations, "contains", "decl:\{profile}::\{name}")
    push_unique_relation(relations, "has_member", "decl:\{profile}::\{name}")
  }

  if kind == "function" ||
    kind == "method" ||
    kind == "associated_fn" ||
    kind == "operation" {
    let first_param = parse_first_param(signature)
    if first_param != "" {
      push_unique_relation(
        relations,
        "has_parameter",
        "type:\{profile}::\{first_param}",
      )
      push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{first_param}",
      )
    }
    let ret = parse_return_type(signature)
    if ret != "" {
      push_unique_relation(relations, "returns", "type:\{profile}::\{ret}")
      push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{ret}",
      )
    }
  }

  if kind == "impl" {
    if signature.contains(" for ") {
      let parts = signature.split(" for ").to_array()
      if parts.length() >= 2 {
        let trait_name = parts[0]
          .to_string()
          .strip_prefix("impl")
          .unwrap_or(parts[0].to_string())
          .to_string()
          |> trim_spaces
        let target_type = parts[1].to_string() |> strip_braces |> trim_spaces
        if trait_name != "" && target_type != "" {
          push_unique_relation(
            relations,
            "implements",
            "type:\{profile}::\{trait_name}",
          )
          push_unique_relation(
            relations,
            "references_type",
            "type:\{profile}::\{target_type}",
          )
        }
      }
    } else {
      let target = signature
        .strip_prefix("impl")
        .unwrap_or(signature)
        .to_string()
        |> strip_braces
        |> trim_spaces
      if target != "" {
        push_unique_relation(
          relations,
          "references_type",
          "type:\{profile}::\{target}",
        )
      }
    }
  }

  if kind == "reference" {
    let reference_target = normalize_reference_target(signature)
    if reference_target != "" {
      push_unique_relation(relations, "references_type", reference_target)
    }
  }

  if kind == "meta_for_each" || kind == "meta_depends_on" {
    let parts = signature.split("=").to_array()
    let target = if parts.length() >= 2 {
      parts[1].to_string() |> trim_spaces
    } else {
      ""
    }
    if target != "" {
      push_unique_relation(relations, "references_type", target)
    }
  }

  relations
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
fn canonical_name(profile : String, path : String, name : String) -> String {
  let scoped = path.replace(old="/", new="::")
  "\{profile}::\{scoped}::\{name}"
}

///|
fn make_declaration(
  profile : String,
  server : String,
  language : String,
  path : String,
  line_no : Int,
  kind : String,
  name : String,
  signature : String,
  docs : String,
) -> Json {
  let canonical = canonical_name(profile, path, name)
  {
    "id": "decl:\{profile}:\{canonical}",
    "kind": kind,
    "name": name,
    "canonical_name": canonical,
    "path": path,
    "signature": signature,
    "shape": declaration_shape(kind, signature),
    "visibility": "public",
    "docs": docs,
    "baselineRole": "baseline",
    "language": language,
    "source_refs": [{ "uri": path, "startLine": line_no, "endLine": line_no }],
    "relations": declaration_relations_v2(profile, path, kind, name, signature),
    "location": { "uri": path, "startLine": line_no, "endLine": line_no },
    "language_specific": { "profile": profile, "server": server },
  }
}

///|
fn enrich_declaration_metadata(record : Json) -> Unit {
  enrich_shape_metadata(record)
  match field_string(record, "language") {
    "go" => enrich_go_record(record)
    "rust" => enrich_rust_record(record)
    "terraform" => enrich_terraform_record(record)
    "openapi" => enrich_openapi_record(record)
    _ => ()
  }
}

///|
fn make_symbol(
  profile : String,
  path : String,
  line_no : Int,
  kind : String,
  name : String,
  signature : String,
) -> Json {
  let canonical = canonical_name(profile, path, name)
  {
    "id": "sym:\{profile}:\{canonical}",
    "path": "\{path}:\{line_no}",
    "kind": kind,
    "name": name,
    "summary": signature,
    "owner": path,
    "location": { "uri": path, "startLine": line_no, "endLine": line_no },
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
    make_declaration(
      profile, server, language, path, line_no, kind, name, signature, docs,
    ),
  )
  guard last_record(declarations) is Some(record) else {
    symbols.push(make_symbol(profile, path, line_no, kind, name, signature))
    return
  }
  enrich_declaration_metadata(record)
  symbols.push(make_symbol(profile, path, line_no, kind, name, signature))
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
fn go_names(segment : String) -> Array[String] {
  let lhs = match segment.find("=") {
    Some(idx) => segment[0:idx].to_string()
    None => segment
  }
  let normalized = strip_braces(lhs)
  let names : Array[String] = []
  let pieces = normalized.split(",").to_array()
  for i in 0..<pieces.length() {
    let name = first_token(pieces[i].to_string())
    if name != "" && name != "_" {
      names.push(name)
    }
  }
  names
}

///|
fn push_go_records(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  kind : String,
  names : Array[String],
  signature : String,
  docs : String,
) -> Unit {
  for i in 0..<names.length() {
    push_record(
      declarations,
      symbols,
      profile,
      server,
      "go",
      path,
      line_no,
      kind,
      names[i],
      signature,
      docs,
    )
  }
}

///|
fn go_import_name(clean_line : String) -> String {
  let parts = quoted_parts(clean_line)
  if parts.length() == 0 {
    return ""
  }
  let import_path = parts[0]
  let tail = trim_spaces(clean_line[7:].to_string())
  let import_alias = first_token(tail)
  if import_alias == "" || import_alias.has_prefix("\"") {
    import_path
  } else {
    "\{import_alias} \{import_path}"
  }
}

///|
fn strip_go_tag(line : String) -> String {
  match line.find("`") {
    Some(idx) => line[0:idx].to_string() |> trim_spaces
    None => line
  }
}

///|
fn go_type_name(signature : String) -> String {
  let body = signature
    .strip_prefix("type ")
    .unwrap_or(signature)
    .to_string()
    |> trim_spaces
  let plain = match body.find("=") {
    Some(idx) => body[0:idx].to_string() |> trim_spaces
    None => body
  }
  let base = match plain.find("[") {
    Some(idx) => plain[0:idx].to_string()
    None => first_token(plain)
  }
  trim_spaces(base)
}

///|
fn go_method_param_types(signature : String) -> Array[String] {
  let rest = signature.strip_prefix("func ").unwrap_or(signature).to_string()
  if !rest.has_prefix("(") {
    return signature_param_types(signature)
  }
  match matching_delimiter_index(rest, 0, '(', ')') {
    Some(close_idx) if close_idx + 1 < rest.length() =>
      signature_param_types(rest[close_idx + 1:].to_string() |> trim_spaces)
    _ => signature_param_types(signature)
  }
}

///|
fn go_return_types_after_params(value : String) -> Array[String] {
  let tail = strip_braces(trim_spaces(value))
  if tail == "" {
    return []
  }
  if tail.has_prefix("(") {
    return match matching_delimiter_index(tail, 0, '(', ')') {
      Some(close_idx) if close_idx > 1 =>
        split_top_level(tail[1:close_idx].to_string(), ',') |> unique_trimmed_strings
      _ => []
    }
  }
  unique_trimmed_strings([tail])
}

///|
fn go_function_return_types(signature : String) -> Array[String] {
  match signature.find("(") {
    Some(open_idx) =>
      match matching_delimiter_index(signature, open_idx, '(', ')') {
        Some(close_idx) if close_idx + 1 < signature.length() =>
          go_return_types_after_params(signature[close_idx + 1:].to_string())
        _ => []
      }
    None => []
  }
}

///|
fn go_method_return_types(signature : String) -> Array[String] {
  let rest = signature.strip_prefix("func ").unwrap_or(signature).to_string()
  if !rest.has_prefix("(") {
    return go_function_return_types(signature)
  }
  match matching_delimiter_index(rest, 0, '(', ')') {
    Some(close_idx) if close_idx + 1 < rest.length() =>
      go_function_return_types(rest[close_idx + 1:].to_string() |> trim_spaces)
    _ => go_function_return_types(signature)
  }
}

///|
fn go_receiver_parts(signature : String) -> (String, Bool) {
  let rest = signature.strip_prefix("func ").unwrap_or(signature).to_string()
  if !rest.has_prefix("(") {
    return ("", false)
  }
  match matching_delimiter_index(rest, 0, '(', ')') {
    Some(close_idx) if close_idx > 1 => {
      let receiver = trim_spaces(rest[1:close_idx].to_string())
      let pointer = receiver.contains("*")
      let base = match receiver.find("*") {
        Some(idx) => receiver[idx + 1:].to_string()
        None => receiver
      }
      let name = match base.find(" ") {
        Some(idx) => base[idx + 1:].to_string()
        None => base
      }
      let trimmed = match name.find("[") {
        Some(idx) => name[0:idx].to_string()
        None => name
      }
      (trim_spaces(trimmed), pointer)
    }
    _ => ("", false)
  }
}

///|
fn normalize_go_type_reference(value : String) -> String {
  let trimmed = strip_braces(trim_spaces(value))
  if trimmed == "" {
    return ""
  }
  if trimmed.has_prefix("*") {
    return normalize_go_type_reference(trimmed[1:].to_string())
  }
  trimmed
}

///|
fn enrich_go_record(record : Json) -> Unit {
  let kind = field_string(record, "kind")
  let name = field_string(record, "name")
  let signature = field_string(record, "signature")
  let type_params = signature_type_params(signature)
  set_language_specific_string_array(record, "go", "typeParams", type_params)
  if kind == "struct" || kind == "interface" {
    let owner = go_type_name(signature)
    set_shape_string(record, "owner", owner)
    set_language_specific_string(record, "go", "owner", owner)
  }
  if kind == "field" || kind == "embedded_field" {
    match name.find(".") {
      Some(idx) if idx > 0 => {
        let owner = name[0:idx].to_string()
        set_shape_string(record, "owner", owner)
        set_language_specific_string(record, "go", "owner", owner)
      }
      _ => ()
    }
    let field_type = if kind == "embedded_field" {
      signature
    } else {
      match signature.find(" ") {
        Some(idx) => signature[idx + 1:].to_string() |> trim_spaces
        None => ""
      }
    }
    set_language_specific_string(record, "go", "fieldType", field_type)
    if kind == "embedded_field" {
      set_language_specific_bool(record, "go", "embedded", true)
    }
  }
  if kind == "import" {
    let quoted = quoted_parts(signature)
    if !quoted.is_empty() {
      set_language_specific_string(record, "go", "importPath", quoted[0])
    }
    let import_name = name
    match import_name.find(" ") {
      Some(idx) if idx > 0 =>
        set_language_specific_string(
          record,
          "go",
          "importAlias",
          import_name[0:idx].to_string() |> trim_spaces,
        )
      _ => ()
    }
  }
  if kind == "method" {
    let (receiver, pointer) = go_receiver_parts(signature)
    set_language_specific_string(record, "go", "receiver", receiver)
    set_language_specific_bool(record, "go", "pointerReceiver", pointer)
    set_shape_string(record, "owner", receiver)
    set_language_specific_string(record, "go", "owner", receiver)
    put_shape_string_array(record, "parameters", go_method_param_types(signature))
    put_shape_string_array(record, "returns", go_method_return_types(signature))
  }
}

///|
fn append_relation_to_record_by_id(
  declarations : Array[Json],
  id : String,
  kind : String,
  target : String,
) -> Unit {
  if id == "" || kind == "" || target == "" {
    return
  }
  for i in 0..<declarations.length() {
    if field_string(declarations[i], "id") == id {
      append_relation(declarations[i], kind, target)
      return
    }
  }
}

///|
fn collect_go_embedding_index(
  declarations : Array[Json],
) -> Map[String, Array[(String, Bool)]] {
  let embeddings : Map[String, Array[(String, Bool)]] = {}
  for i in 0..<declarations.length() {
    if field_string(declarations[i], "language") != "go" ||
      field_string(declarations[i], "kind") != "embedded_field" {
      continue
    }
    let owner = shape_string(declarations[i], "owner")
    let field_type = language_specific_profile_string(
      declarations[i],
      "go",
      "fieldType",
    )
    let target = normalize_go_type_reference(field_type)
    let is_pointer = field_type.has_prefix("*")
    if owner == "" || target == "" {
      continue
    }
    match embeddings.get(owner) {
      Some(entries) => entries.push((target, is_pointer))
      None => embeddings[owner] = [(target, is_pointer)]
    }
  }
  embeddings
}

///|
fn go_method_set_types(
  owner : String,
  pointer_receiver : Bool,
  embeddings : Map[String, Array[(String, Bool)]],
) -> Array[String] {
  let method_sets : Array[String] = []
  if owner == "" {
    return method_sets
  }
  if pointer_receiver {
    append_unique_string(method_sets, "*\{owner}")
  } else {
    append_unique_string(method_sets, owner)
    append_unique_string(method_sets, "*\{owner}")
  }
  let mut changed = true
  while changed {
    changed = false
    for embedder, embedded_types in embeddings {
      let before = method_sets.length()
      for i in 0..<embedded_types.length() {
        let (embedded_type, embedded_pointer) = embedded_types[i]
        let has_value = contains_string(method_sets, embedded_type)
        let has_pointer = contains_string(method_sets, "*\{embedded_type}")
        if embedded_pointer {
          if has_value || has_pointer {
            append_unique_string(method_sets, embedder)
            append_unique_string(method_sets, "*\{embedder}")
          }
        } else {
          if has_value {
            append_unique_string(method_sets, embedder)
          }
          if has_value || has_pointer {
            append_unique_string(method_sets, "*\{embedder}")
          }
        }
      }
      if method_sets.length() != before {
        changed = true
      }
    }
  }
  method_sets
}

///|
fn rewrite_go_relations(record : Json, profile : String) -> Unit {
  let kind = field_string(record, "kind")
  let signature = field_string(record, "signature")
  if kind == "function" || kind == "method" {
    let relations = filter_record_relations(
      record,
      ["has_parameter", "returns", "references_type"],
    )
    let param_types = if kind == "method" {
      go_method_param_types(signature)
    } else {
      signature_param_types(signature)
    }
    for i in 0..<param_types.length() {
      let ty = normalize_go_type_reference(param_types[i])
      if ty == "" {
        continue
      }
      push_unique_relation(relations, "has_parameter", "type:\{profile}::\{ty}")
      push_unique_relation(relations, "references_type", "type:\{profile}::\{ty}")
    }
    let return_types = if kind == "method" {
      go_method_return_types(signature)
    } else {
      go_function_return_types(signature)
    }
    for i in 0..<return_types.length() {
      let ty = normalize_go_type_reference(return_types[i])
      if ty == "" {
        continue
      }
      push_unique_relation(relations, "returns", "type:\{profile}::\{ty}")
      push_unique_relation(relations, "references_type", "type:\{profile}::\{ty}")
    }
    set_record_relations(record, relations)
    return
  }
  if kind == "field" || kind == "embedded_field" {
    let relations = filter_record_relations(record, ["references_type"])
    let field_type = language_specific_profile_string(record, "go", "fieldType")
    let ty = normalize_go_type_reference(field_type)
    if ty != "" {
      push_unique_relation(relations, "references_type", "type:\{profile}::\{ty}")
    }
    set_record_relations(record, relations)
  }
}

///|
fn postprocess_go_declarations(
  declarations : Array[Json],
  profile : String,
) -> Unit {
  let type_ids : Map[String, String] = {}
  for i in 0..<declarations.length() {
    if field_string(declarations[i], "language") != "go" {
      continue
    }
    let kind = field_string(declarations[i], "kind")
    if kind == "struct" || kind == "interface" || kind == "type" {
      let name = field_string(declarations[i], "name")
      let id = field_string(declarations[i], "id")
      if name != "" && id != "" {
        type_ids[name] = id
      }
    }
  }

  let embeddings = collect_go_embedding_index(declarations)
  for i in 0..<declarations.length() {
    if field_string(declarations[i], "language") != "go" {
      continue
    }
    rewrite_go_relations(declarations[i], profile)
  }

  for i in 0..<declarations.length() {
    if field_string(declarations[i], "language") != "go" {
      continue
    }
    let kind = field_string(declarations[i], "kind")
    let id = field_string(declarations[i], "id")
    if kind == "field" || kind == "embedded_field" || kind == "method" {
      let owner = shape_string(declarations[i], "owner")
      match type_ids.get(owner) {
        Some(owner_id) => append_relation_to_record_by_id(
          declarations,
          owner_id,
          "has_member",
          id,
        )
        None => ()
      }
    }
    if kind == "method" {
      let owner = shape_string(declarations[i], "owner")
      let pointer_receiver = language_specific_profile_bool(
        declarations[i],
        "go",
        "pointerReceiver",
      ).unwrap_or(false)
      let method_set_types = go_method_set_types(owner, pointer_receiver, embeddings)
      set_language_specific_string_array(
        declarations[i],
        "go",
        "methodSetTypes",
        method_set_types,
      )
      for j in 0..<method_set_types.length() {
        let owner_type = normalize_go_type_reference(method_set_types[j])
        match type_ids.get(owner_type) {
          Some(owner_id) => append_relation_to_record_by_id(
            declarations,
            owner_id,
            "has_member",
            id,
          )
          None => ()
        }
      }
    }
  }
}

///|
fn go_struct_name(line : String, grouped~ : Bool) -> String {
  let source = if grouped {
    line
  } else {
    line.strip_prefix("type ").unwrap_or(line).to_string()
  }
  first_token(source)
}

///|
fn extract_go_struct_field(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  owner : String,
  line : String,
  docs : String,
) -> Unit {
  let clean = line_before_comment(line) |> trim_spaces |> strip_go_tag
  if clean == "" || clean == "{" || clean == "}" {
    return
  }

  let is_embedded = !clean.contains(" ") && !clean.contains("\t")
  let raw_name = if is_embedded { clean } else { first_token(clean) }
  let name = raw_name.strip_prefix("*").unwrap_or(raw_name).to_string()
  if name == "" {
    return
  }

  push_record(
    declarations,
    symbols,
    profile,
    server,
    "go",
    path,
    line_no,
    if is_embedded {
      "embedded_field"
    } else {
      "field"
    },
    "\{owner}.\{name}",
    clean,
    docs,
  )
  guard last_record(declarations) is Some(record) else { return }
  enrich_go_record(record)
}

///|
fn extract_go_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  line : String,
  docs : String,
) -> Unit {
  let clean_line = line_before_comment(line) |> trim_spaces
  if clean_line == "" {
    return
  }

  if clean_line.has_prefix("type ") {
    let rest = clean_line[5:].to_string()
    let type_name = first_token(rest)
    if rest.contains("=") {
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "type_alias",
        type_name, clean_line, docs,
      )
      guard last_record(declarations) is Some(record) else { return }
      enrich_go_record(record)
    } else if rest.contains("struct") {
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "struct", type_name,
        clean_line, docs,
      )
      guard last_record(declarations) is Some(record) else { return }
      enrich_go_record(record)
    } else if rest.contains("interface") {
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "interface",
        type_name, clean_line, docs,
      )
      guard last_record(declarations) is Some(record) else { return }
      enrich_go_record(record)
    } else {
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "type", type_name,
        clean_line, docs,
      )
      guard last_record(declarations) is Some(record) else { return }
      enrich_go_record(record)
    }
    return
  }

  if clean_line.has_prefix("package ") {
    let name = first_token(clean_line[8:].to_string())
    push_record(
      declarations, symbols, profile, server, "go", path, line_no, "package", name,
      clean_line, docs,
    )
    return
  }

  if clean_line.has_prefix("import ") {
    let name = go_import_name(clean_line)
    push_record(
      declarations, symbols, profile, server, "go", path, line_no, "import", name,
      clean_line, docs,
    )
    guard last_record(declarations) is Some(record) else { return }
    enrich_go_record(record)
    return
  }

  if clean_line.has_prefix("func ") {
    let mut rest = clean_line[5:].to_string()
    let kind = if rest.has_prefix("(") {
      match rest.find(") ") {
        Some(idx) => {
          rest = rest[idx + 2:].to_string()
          "method"
        }
        None => "method"
      }
    } else {
      "function"
    }
    let name = token_before(rest, "(")
    push_record(
      declarations, symbols, profile, server, "go", path, line_no, kind, name, clean_line,
      docs,
    )
    guard last_record(declarations) is Some(record) else { return }
    enrich_go_record(record)
    return
  }

  if clean_line.has_prefix("const ") {
    let names = go_names(clean_line[6:].to_string())
    push_go_records(
      declarations, symbols, profile, server, path, line_no, "const", names, clean_line,
      docs,
    )
    return
  }

  if clean_line.has_prefix("var ") {
    let names = go_names(clean_line[4:].to_string())
    push_go_records(
      declarations, symbols, profile, server, path, line_no, "var", names, clean_line,
      docs,
    )
  }
}

///|
fn extract_go_file(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
) -> Unit {
  let mut pending_doc = ""
  let mut pending_doc_line = 0
  let mut group_kind = ""
  let mut group_scope_depth = 0
  let mut active_struct = ""
  let mut active_struct_depth = 0

  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_spaces(lines[i].to_string())

    if line.has_prefix("//") {
      let piece = line.strip_prefix("//").unwrap_or(line).to_string()
        |> trim_spaces
      pending_doc = if pending_doc == "" {
        piece
      } else {
        "\{pending_doc}\n\{piece}"
      }
      pending_doc_line = line_no
      continue
    }
    if line == "" {
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    if line == ")" {
      group_kind = ""
      group_scope_depth = 0
      active_struct = ""
      active_struct_depth = 0
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    if line.has_prefix("const (") || line == "const(" {
      group_kind = "const"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }
    if line.has_prefix("var (") || line == "var(" {
      group_kind = "var"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }
    if line.has_prefix("type (") || line == "type(" {
      group_kind = "type"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }
    if line.has_prefix("import (") || line == "import(" {
      group_kind = "import"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    if group_kind != "" {
      let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
        pending_doc
      } else {
        ""
      }
      if active_struct != "" && active_struct_depth > 0 {
        extract_go_struct_field(
          declarations, symbols, profile, server, path, line_no, active_struct, line,
          docs,
        )
      }
      let group_line = strip_braces(line)
      if group_scope_depth == 0 && group_line != "" {
        let synthetic = "\{group_kind} \{group_line}"
        extract_go_record(
          declarations, symbols, profile, server, path, line_no, synthetic, docs,
        )
        if group_kind == "type" &&
          line.contains("struct") &&
          line.has_suffix("{") {
          active_struct = go_struct_name(group_line, grouped=true)
          active_struct_depth = 0
        }
      }
      for c in line {
        if c == '{' {
          group_scope_depth = group_scope_depth + 1
          if active_struct != "" {
            active_struct_depth = active_struct_depth + 1
          }
        } else if c == '}' && group_scope_depth > 0 {
          group_scope_depth = group_scope_depth - 1
          if active_struct != "" {
            active_struct_depth = active_struct_depth - 1
            if active_struct_depth <= 0 {
              active_struct = ""
              active_struct_depth = 0
            }
          }
        }
      }
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    let declaration_prefixes = [
      "package ", "import ", "type ", "func ", "const ", "var ",
    ]
    let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
      pending_doc
    } else {
      ""
    }
    if active_struct != "" && active_struct_depth > 0 {
      extract_go_struct_field(
        declarations, symbols, profile, server, path, line_no, active_struct, line,
        docs,
      )
    }
    if starts_with_any(line, declaration_prefixes) {
      extract_go_record(
        declarations, symbols, profile, server, path, line_no, line, docs,
      )
      if line.has_prefix("type ") &&
        line.contains("struct") &&
        line.has_suffix("{") {
        active_struct = go_struct_name(line, grouped=false)
        active_struct_depth = 0
      }
      pending_doc = ""
      pending_doc_line = 0
    }
    for c in line {
      if c == '{' {
        if active_struct != "" {
          active_struct_depth = active_struct_depth + 1
        }
      } else if c == '}' {
        if active_struct != "" {
          active_struct_depth = active_struct_depth - 1
          if active_struct_depth <= 0 {
            active_struct = ""
            active_struct_depth = 0
          }
        }
      }
    }
  }
}

///|
fn rust_type_name(signature : String, prefix : String) -> String {
  let body = signature.strip_prefix(prefix).unwrap_or(signature).to_string() |> trim_spaces
  let base = match body.find("<") {
    Some(idx) => body[0:idx].to_string()
    None => token_before(body, " ")
  }
  trim_spaces(base)
}

///|
fn rust_where_clause(signature : String) -> String {
  match signature.find(" where ") {
    Some(idx) => signature[idx + 7:].to_string() |> trim_spaces |> strip_braces
    None => ""
  }
}

///|
fn rust_strip_leading_generics(value : String) -> String {
  let trimmed = trim_spaces(value)
  if !trimmed.has_prefix("<") {
    return trimmed
  }
  match matching_delimiter_index(trimmed, 0, '<', '>') {
    Some(close_idx) if close_idx + 1 < trimmed.length() =>
      trim_spaces(trimmed[close_idx + 1:].to_string())
    Some(_) => ""
    None => trimmed
  }
}

///|
fn rust_decl_name(text : String) -> String {
  let trimmed = trim_spaces(text)
  if trimmed == "" {
    return ""
  }
  let mut end = 0
  while end < trimmed.length() {
    let c = trimmed.code_unit_at(end)
    if c == '<' {
      match matching_delimiter_index(trimmed, end, '<', '>') {
        Some(close_idx) => {
          end = close_idx + 1
          continue
        }
        None => break
      }
    }
    if c == ' ' ||
      c == '\t' ||
      c == '{' ||
      c == '(' ||
      c == '=' ||
      c == ':' ||
      c == ';' {
      break
    }
    end = end + 1
  }
  trim_spaces(trimmed[0:end].to_string())
}

///|
fn rust_strip_decl_modifiers(value : String) -> String {
  let mut out = trim_spaces(value)
  let mut changed = true
  while changed {
    changed = false
    if out.has_prefix("unsafe ") {
      out = trim_spaces(out[7:].to_string())
      changed = true
      continue
    }
    if out.has_prefix("async ") {
      out = trim_spaces(out[6:].to_string())
      changed = true
      continue
    }
    if out.has_prefix("extern ") {
      let rest = trim_spaces(out[7:].to_string())
      if rest.has_prefix("\"") {
        match rest[1:].find("\"") {
          Some(close_idx) => {
            out = trim_spaces(rest[close_idx + 2:].to_string())
            changed = true
            continue
          }
          None => {
            out = rest
            changed = true
            continue
          }
        }
      }
      out = rest
      changed = true
      continue
    }
  }
  out
}

///|
fn rust_signature_type_params(signature : String) -> Array[String] {
  match signature.find("<") {
    Some(open_idx) => {
      let equals_idx = signature.find("=").unwrap_or(signature.length())
      let paren_idx = signature.find("(").unwrap_or(signature.length())
      if open_idx > equals_idx || open_idx > paren_idx {
        return []
      }
      match matching_delimiter_index(signature, open_idx, '<', '>') {
        Some(close_idx) if close_idx > open_idx + 1 =>
          split_top_level(signature[open_idx + 1:close_idx].to_string(), ',')
          |> unique_trimmed_strings
        _ => []
      }
    }
    None => []
  }
}

///|
fn rust_multiline_clause(lines : Array[String], start_idx : Int) -> String {
  let parts : Array[String] = []
  let mut saw_where = false
  for i in (start_idx + 1)..<lines.length() {
    let clean = trim_spaces(line_before_comment(lines[i].to_string()))
    if clean == "" {
      continue
    }
    if clean.has_prefix("where") {
      saw_where = true
      let clause = clean.strip_prefix("where").unwrap_or(clean).to_string() |> trim_spaces |> strip_braces
      if clause != "" {
        parts.push(clause)
      }
      if clean.has_suffix("{") || clean.has_suffix(";") {
        break
      }
      continue
    }
    if !saw_where {
      break
    }
    let clause = strip_braces(clean)
    if clause != "" {
      parts.push(clause)
    }
    if clean.has_suffix("{") || clean.has_suffix(";") {
      break
    }
  }
  if parts.is_empty() {
    ""
  } else {
    parts.join(", ")
  }
}

///|
fn rust_impl_targets(signature : String) -> (String, String) {
  let trimmed = signature.strip_prefix("impl").unwrap_or(signature).to_string() |> trim_spaces
  let normalized = strip_braces(trimmed)
  match normalized.find(" for ") {
    Some(idx) => {
      let trait_target = normalized[0:idx].to_string() |> trim_spaces
      let impl_target = normalized[idx + 5:].to_string() |> trim_spaces
      (trait_target, impl_target)
    }
    None => ("", normalized)
  }
}

///|
fn rust_is_unsafe(signature : String) -> Bool {
  let clean = trim_spaces(line_before_comment(signature))
  clean.has_prefix("unsafe ") || clean.contains(" unsafe ")
}

///|
fn rust_extern_abi(signature : String) -> String {
  let clean = trim_spaces(line_before_comment(signature))
  if !clean.contains("extern") {
    return ""
  }
  let quoted = quoted_parts(clean)
  if !quoted.is_empty() {
    return quoted[0]
  }
  if clean.contains("extern fn") || clean.contains("extern unsafe fn") {
    return "C"
  }
  ""
}

///|
fn rust_normalize_owner_key(value : String) -> String {
  let trimmed = line_before_comment(value) |> trim_spaces |> strip_braces
  if trimmed == "" {
    return ""
  }
  let without_where = match trimmed.find(" where ") {
    Some(idx) => trimmed[0:idx].to_string() |> trim_spaces
    None => trimmed
  }
  rust_strip_leading_generics(without_where) |> trim_spaces
}

///|
fn rust_record_type_params(record : Json) -> Array[String] {
  let kind = field_string(record, "kind")
  let name = field_string(record, "name")
  let signature = field_string(record, "signature")
  if kind == "impl" || kind == "struct" || kind == "trait" || kind == "enum" ||
    kind == "union" || kind == "type_alias" || kind == "function" {
    return rust_signature_type_params(signature)
  }
  if kind == "associated_type" || kind == "associated_const" || kind == "associated_fn" {
    match name.find("<") {
      Some(_) => {
        let owner = match name.find("::") {
          Some(idx) if idx > 0 => name[0:idx].to_string()
          _ => name
        }
        return match owner.find("<") {
          Some(open_idx) =>
            match matching_delimiter_index(owner, open_idx, '<', '>') {
              Some(close_idx) if close_idx > open_idx + 1 =>
                split_top_level(owner[open_idx + 1:close_idx].to_string(), ',')
                .map(part => first_token(part))
                |> unique_trimmed_strings
              _ => []
            }
          None => []
        }
      }
      None => return []
    }
  }
  match name.find("<") {
    Some(open_idx) =>
      match matching_delimiter_index(name, open_idx, '<', '>') {
        Some(close_idx) if close_idx > open_idx + 1 =>
          split_top_level(name[open_idx + 1:close_idx].to_string(), ',')
          .map(part => first_token(part))
          |> unique_trimmed_strings
        _ => []
      }
    None => []
  }
}

///|
fn enrich_rust_record(record : Json) -> Unit {
  let kind = field_string(record, "kind")
  let name = field_string(record, "name")
  let signature = field_string(record, "signature")
  let type_params = rust_record_type_params(record)
  set_shape_string_array(record, "type_params", type_params)
  set_language_specific_string_array(record, "rust", "typeParams", type_params)
  let where_clause = rust_where_clause(signature)
  set_language_specific_string(record, "rust", "whereClause", where_clause)
  if rust_is_unsafe(signature) {
    set_language_specific_bool(record, "rust", "unsafe", true)
  }
  let extern_abi = rust_extern_abi(signature)
  set_language_specific_string(record, "rust", "externAbi", extern_abi)
  if kind == "struct" {
    let owner = rust_type_name(signature, "pub struct ")
    set_shape_string(record, "owner", owner)
    set_language_specific_string(record, "rust", "owner", owner)
  } else if kind == "trait" {
    let owner = rust_type_name(signature, "pub trait ")
    set_shape_string(record, "owner", owner)
    set_language_specific_string(record, "rust", "owner", owner)
  } else if kind == "impl" {
    let (trait_target, impl_target) = rust_impl_targets(signature)
    set_language_specific_string(record, "rust", "traitTarget", trait_target)
    set_language_specific_string(record, "rust", "implTarget", impl_target)
    set_shape_string(record, "owner", impl_target)
  } else if kind == "associated_type" ||
    kind == "associated_const" ||
    kind == "associated_fn" {
    let owner = match name.find("::") {
      Some(idx) if idx > 0 => name[0:idx].to_string()
      _ => ""
    }
    set_shape_string(record, "owner", owner)
    set_language_specific_string(record, "rust", "owner", owner)
    set_language_specific_bool(record, "rust", "associated", true)
    if owner != "" {
      set_language_specific_string(record, "rust", "traitTarget", owner)
    }
  }
}

///|
fn set_rust_multiline_clause(record : Json, lines : Array[String], line_no : Int) -> Unit {
  if rust_where_clause(field_string(record, "signature")) != "" {
    return
  }
  set_language_specific_string(
    record,
    "rust",
    "whereClause",
    rust_multiline_clause(lines, line_no - 1),
  )
}

///|
fn rust_append_type_relation(
  relations : Array[Json],
  profile : String,
  value : String,
) -> Unit {
  let normalized = rust_normalize_owner_key(value)
  if normalized == "" {
    return
  }
  push_unique_relation(relations, "references_type", "type:\{profile}::\{normalized}")
}

///|
fn rewrite_rust_relations(record : Json, profile : String) -> Unit {
  let kind = field_string(record, "kind")
  let signature = field_string(record, "signature")
  if kind == "function" || kind == "associated_fn" {
    let relations = filter_record_relations(
      record,
      ["has_parameter", "returns", "references_type"],
    )
    let param_types = signature_param_types(signature)
    for i in 0..<param_types.length() {
      let ty = trim_spaces(param_types[i])
      if ty == "" {
        continue
      }
      push_unique_relation(relations, "has_parameter", "type:\{profile}::\{ty}")
      push_unique_relation(relations, "references_type", "type:\{profile}::\{ty}")
    }
    let return_types = signature_return_types(signature)
    for i in 0..<return_types.length() {
      let ty = trim_spaces(return_types[i])
      if ty == "" {
        continue
      }
      push_unique_relation(relations, "returns", "type:\{profile}::\{ty}")
      push_unique_relation(relations, "references_type", "type:\{profile}::\{ty}")
    }
    rust_append_type_relation(
      relations,
      profile,
      language_specific_profile_string(record, "rust", "owner"),
    )
    rust_append_type_relation(
      relations,
      profile,
      language_specific_profile_string(record, "rust", "traitTarget"),
    )
    rust_append_type_relation(
      relations,
      profile,
      language_specific_profile_string(record, "rust", "implTarget"),
    )
    set_record_relations(record, relations)
    return
  }
  if kind == "impl" {
    let relations = filter_record_relations(record, ["implements", "references_type"])
    let trait_target = rust_normalize_owner_key(
      language_specific_profile_string(record, "rust", "traitTarget"),
    )
    let impl_target = rust_normalize_owner_key(
      language_specific_profile_string(record, "rust", "implTarget"),
    )
    if trait_target != "" {
      push_unique_relation(relations, "implements", "type:\{profile}::\{trait_target}")
      push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{trait_target}",
      )
    }
    if impl_target != "" {
      push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{impl_target}",
      )
    }
    set_record_relations(record, relations)
    return
  }
  if kind == "associated_type" || kind == "associated_const" || kind == "const" ||
    kind == "type_alias" {
    let relations = filter_record_relations(record, ["references_type"])
    rust_append_type_relation(
      relations,
      profile,
      language_specific_profile_string(record, "rust", "owner"),
    )
    rust_append_type_relation(
      relations,
      profile,
      language_specific_profile_string(record, "rust", "traitTarget"),
    )
    rust_append_type_relation(
      relations,
      profile,
      language_specific_profile_string(record, "rust", "implTarget"),
    )
    set_record_relations(record, relations)
  }
}

///|
fn postprocess_rust_declarations(
  declarations : Array[Json],
  profile : String,
) -> Unit {
  let type_ids : Map[String, String] = {}
  for i in 0..<declarations.length() {
    if field_string(declarations[i], "language") != "rust" {
      continue
    }
    let kind = field_string(declarations[i], "kind")
    if kind == "struct" || kind == "enum" || kind == "union" || kind == "trait" ||
      kind == "type_alias" {
      let name = rust_normalize_owner_key(field_string(declarations[i], "name"))
      let id = field_string(declarations[i], "id")
      if name != "" && id != "" {
        type_ids[name] = id
      }
    }
  }

  for i in 0..<declarations.length() {
    if field_string(declarations[i], "language") != "rust" {
      continue
    }
    rewrite_rust_relations(declarations[i], profile)
  }

  for i in 0..<declarations.length() {
    if field_string(declarations[i], "language") != "rust" {
      continue
    }
    let kind = field_string(declarations[i], "kind")
    let id = field_string(declarations[i], "id")
    let owner = rust_normalize_owner_key(
      language_specific_profile_string(declarations[i], "rust", "owner"),
    )
    if (kind == "associated_type" || kind == "associated_const" ||
      kind == "associated_fn" || kind == "function" || kind == "const" ||
      kind == "type_alias") && owner != "" {
      match type_ids.get(owner) {
        Some(owner_id) => append_relation_to_record_by_id(
          declarations,
          owner_id,
          "has_member",
          id,
        )
        None => ()
      }
    }
    if kind == "impl" {
      let trait_target = rust_normalize_owner_key(
        language_specific_profile_string(declarations[i], "rust", "traitTarget"),
      )
      let impl_target = rust_normalize_owner_key(
        language_specific_profile_string(declarations[i], "rust", "implTarget"),
      )
      if trait_target != "" && impl_target != "" {
        match type_ids.get(impl_target) {
          Some(type_id) => append_relation_to_record_by_id(
            declarations,
            type_id,
            "implements",
            "type:\{profile}::\{trait_target}",
          )
          None => ()
        }
      }
    }
  }
}

///|
fn extract_rust_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
  line_no : Int,
  line : String,
  docs : String,
  active_impl_target : String,
  active_impl_trait : String,
) -> Unit {
  let clean = line_before_comment(line) |> trim_spaces
  if clean == "" {
    return
  }

  let mut normalized = clean
  let mut vis = "public"
  if normalized.has_prefix("pub(crate) ") {
    vis = "pub(crate)"
    normalized = normalized[11:].to_string()
  } else if normalized.has_prefix("pub(super) ") {
    vis = "pub(super)"
    normalized = normalized[11:].to_string()
  } else if normalized.has_prefix("pub(in ") {
    vis = "pub(in)"
    match normalized.find(") ") {
      Some(idx) => normalized = normalized[idx + 2:].to_string()
      None => ()
    }
  } else if normalized.has_prefix("pub ") {
    normalized = normalized[4:].to_string()
  } else {
    return
  }

  let kind_source = rust_strip_decl_modifiers(normalized)
  let (kind, name) = if kind_source.has_prefix("fn ") {
    ("function", token_before(kind_source[3:].to_string(), "("))
  } else if kind_source.has_prefix("struct ") {
    ("struct", rust_decl_name(kind_source[7:].to_string()))
  } else if kind_source.has_prefix("enum ") {
    ("enum", rust_decl_name(kind_source[5:].to_string()))
  } else if kind_source.has_prefix("union ") {
    ("union", rust_decl_name(kind_source[6:].to_string()))
  } else if kind_source.has_prefix("trait ") {
    ("trait", rust_decl_name(kind_source[6:].to_string()))
  } else if kind_source.has_prefix("type ") {
    ("type_alias", rust_decl_name(kind_source[5:].to_string()))
  } else if kind_source.has_prefix("const ") {
    ("const", token_before(kind_source[6:].to_string(), ":"))
  } else if kind_source.has_prefix("static ") {
    ("static", token_before(kind_source[7:].to_string(), ":"))
  } else if kind_source.has_prefix("mod ") {
    ("module", token_before(kind_source[4:].to_string(), "{"))
  } else if kind_source.has_prefix("use ") {
    ("use", strip_braces(kind_source[4:].to_string()))
  } else if kind_source.has_prefix("macro ") {
    ("macro", token_before(kind_source[6:].to_string(), "{"))
  } else {
    ("", "")
  }

  if name == "" || kind == "" {
    return
  }

  let signature = if vis == "public" { clean } else { "\{clean} // \{vis}" }
  push_record(
    declarations, symbols, profile, server, "rust", path, line_no, kind, name, signature,
    docs,
  )
  guard last_record(declarations) is Some(record) else { return }
  enrich_rust_record(record)
  set_rust_multiline_clause(record, lines, line_no)
  if active_impl_target != "" &&
    (kind == "function" || kind == "const" || kind == "type_alias") {
    set_shape_string(record, "owner", active_impl_target)
    set_language_specific_string(record, "rust", "owner", active_impl_target)
    set_language_specific_string(record, "rust", "implTarget", active_impl_target)
    if active_impl_trait != "" {
      set_language_specific_string(record, "rust", "traitTarget", active_impl_trait)
    }
  }
}

///|
fn extract_rust_file(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
) -> Unit {
  let mut pending_doc = ""
  let mut pending_doc_line = 0
  let mut pending_deprecated = ""
  let mut pending_macro_export = false
  let mut active_trait = ""
  let mut active_trait_depth = 0
  let mut pending_trait = ""
  let mut active_impl_target = ""
  let mut active_impl_trait = ""
  let mut active_impl_depth = 0
  let mut pending_impl_target = ""
  let mut pending_impl_trait = ""

  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_spaces(lines[i].to_string())

    if line.has_prefix("///") {
      let piece = line.strip_prefix("///").unwrap_or(line).to_string()
        |> trim_spaces
      pending_doc = if pending_doc == "" {
        piece
      } else {
        "\{pending_doc}\n\{piece}"
      }
      pending_doc_line = line_no
      continue
    }
    if line.has_prefix("#[deprecated") {
      pending_deprecated = "Deprecated"
      continue
    }
    if line.has_prefix("#[macro_export") {
      pending_macro_export = true
      continue
    }
    if line == "" {
      pending_doc = ""
      pending_doc_line = 0
      pending_deprecated = ""
      continue
    }

    let clean = line_before_comment(line) |> trim_spaces
    if pending_macro_export && clean.has_prefix("macro_rules!") {
      let macro_name = token_before(clean[12:].to_string(), "{")
      let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
        pending_doc
      } else {
        ""
      }
      let docs_with_attrs = if pending_deprecated == "" {
        docs
      } else if docs == "" {
        pending_deprecated
      } else {
        "\{docs}\n\{pending_deprecated}"
      }
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "macro", macro_name,
        clean, docs_with_attrs,
      )
      guard last_record(declarations) is Some(record) else {
        pending_doc = ""
        pending_doc_line = 0
        pending_deprecated = ""
        pending_macro_export = false
        continue
      }
      enrich_rust_record(record)
      pending_doc = ""
      pending_doc_line = 0
      pending_deprecated = ""
      pending_macro_export = false
      continue
    }

    if active_trait != "" &&
      !clean.has_prefix("#") &&
      clean != "{" &&
      clean != "}" {
      let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
        pending_doc
      } else {
        ""
      }
      let docs_with_attrs = if pending_deprecated == "" {
        docs
      } else if docs == "" {
        pending_deprecated
      } else {
        "\{docs}\n\{pending_deprecated}"
      }
      if clean.has_prefix("type ") {
        let name = token_before(clean[5:].to_string(), ":")
        push_record(
          declarations,
          symbols,
          profile,
          server,
          "rust",
          path,
          line_no,
          "associated_type",
          "\{active_trait}::\{name}",
          clean,
          docs_with_attrs,
        )
        guard last_record(declarations) is Some(record) else {
          pending_doc = ""
          pending_doc_line = 0
          pending_deprecated = ""
          continue
        }
        enrich_rust_record(record)
      } else if clean.has_prefix("const ") {
        let name = token_before(clean[6:].to_string(), ":")
        push_record(
          declarations,
          symbols,
          profile,
          server,
          "rust",
          path,
          line_no,
          "associated_const",
          "\{active_trait}::\{name}",
          clean,
          docs_with_attrs,
        )
        guard last_record(declarations) is Some(record) else {
          pending_doc = ""
          pending_doc_line = 0
          pending_deprecated = ""
          continue
        }
        enrich_rust_record(record)
      } else if clean.has_prefix("fn ") {
        let name = token_before(clean[3:].to_string(), "(")
        push_record(
          declarations,
          symbols,
          profile,
          server,
          "rust",
          path,
          line_no,
          "associated_fn",
          "\{active_trait}::\{name}",
          clean,
          docs_with_attrs,
        )
        guard last_record(declarations) is Some(record) else {
          pending_doc = ""
          pending_doc_line = 0
          pending_deprecated = ""
          continue
        }
        enrich_rust_record(record)
      }
      pending_doc = ""
      pending_doc_line = 0
      pending_deprecated = ""
    }

    let impl_source = rust_strip_decl_modifiers(clean)
    if impl_source.has_prefix("impl ") || impl_source.has_prefix("impl<") {
      let name = clean.strip_prefix("impl").unwrap_or(clean).to_string()
        |> trim_spaces
        |> strip_braces
      push_simple_record(
        declarations, symbols, profile, server, "rust", path, line_no, "impl", name,
        clean,
      )
      match last_record(declarations) {
        Some(record) => enrich_rust_record(record)
        None => ()
      }
      let (impl_trait, impl_target) = rust_impl_targets(impl_source)
      pending_impl_trait = rust_normalize_owner_key(impl_trait)
      pending_impl_target = rust_normalize_owner_key(impl_target)
      if clean.has_suffix("{") {
        active_impl_target = pending_impl_target
        active_impl_trait = pending_impl_trait
        pending_impl_target = ""
        pending_impl_trait = ""
        active_impl_depth = 0
      }
    }

    let mut vis_normalized = clean
    let mut trait_visible = false
    if vis_normalized.has_prefix("pub(crate) ") {
      vis_normalized = vis_normalized[11:].to_string()
      trait_visible = true
    } else if vis_normalized.has_prefix("pub(super) ") {
      vis_normalized = vis_normalized[11:].to_string()
      trait_visible = true
    } else if vis_normalized.has_prefix("pub(in ") {
      trait_visible = true
      match vis_normalized.find(") ") {
        Some(idx) => vis_normalized = vis_normalized[idx + 2:].to_string()
        None => ()
      }
    } else if vis_normalized.has_prefix("pub ") {
      trait_visible = true
      vis_normalized = vis_normalized[4:].to_string()
    }
    let trait_source = rust_strip_decl_modifiers(vis_normalized)
    if trait_visible && trait_source.has_prefix("trait ") {
      pending_trait = rust_decl_name(trait_source[6:].to_string())
      if clean.has_suffix("{") {
        active_trait = pending_trait
        pending_trait = ""
        active_trait_depth = 0
      }
    }
    if pending_impl_target != "" && clean.has_suffix("{") {
      active_impl_target = pending_impl_target
      active_impl_trait = pending_impl_trait
      pending_impl_target = ""
      pending_impl_trait = ""
      active_impl_depth = 0
    }
    if pending_trait != "" && clean.has_suffix("{") {
      active_trait = pending_trait
      pending_trait = ""
      active_trait_depth = 0
    }

    let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
      pending_doc
    } else {
      ""
    }
    let docs_with_attrs = if pending_deprecated == "" {
      docs
    } else if docs == "" {
      pending_deprecated
    } else {
      "\{docs}\n\{pending_deprecated}"
    }
    extract_rust_record(
      declarations,
      symbols,
      profile,
      server,
      path,
      lines,
      line_no,
      line,
      docs_with_attrs,
      active_impl_target,
      active_impl_trait,
    )

    for c in clean {
      if c == '{' {
        if active_trait != "" {
          active_trait_depth = active_trait_depth + 1
        }
        if active_impl_target != "" {
          active_impl_depth = active_impl_depth + 1
        }
      } else if c == '}' {
        if active_trait != "" {
          active_trait_depth = active_trait_depth - 1
          if active_trait_depth <= 0 {
            active_trait = ""
            active_trait_depth = 0
          }
        }
        if active_impl_target != "" {
          active_impl_depth = active_impl_depth - 1
          if active_impl_depth <= 0 {
            active_impl_target = ""
            active_impl_trait = ""
            active_impl_depth = 0
          }
        }
      }
    }

    pending_doc = ""
    pending_doc_line = 0
    pending_deprecated = ""
    pending_macro_export = false
  }
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
    match last_record(declarations) {
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
    (clean.has_prefix("prevent_destroy ") || clean.has_prefix("prevent_destroy=")) {
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
    (clean.has_prefix("create_before_destroy ") || clean.has_prefix("create_before_destroy=")) {
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
    (active_block.has_prefix("resource.") ||
      active_block.has_prefix("data.") ||
      active_block.has_prefix("provider.")) {
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
    Some(idx) => (
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
    None => {
      name: provider_name,
      source: "",
      version: "",
      provider_alias,
    }
  }
}

///|
fn terraform_language_record_name(active_block : String) -> String {
  match active_block.find(".") {
    Some(idx) if idx + 1 < active_block.length() => active_block[idx + 1:].to_string()
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
  let decl_id = declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) => {
      guard ensure_language_specific_profile(declarations[idx], "terraform") is Some(terraform) else {
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
  let decl_id = declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) => {
      guard ensure_language_specific_profile(declarations[idx], "openapi") is Some(openapi) else {
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
  let decl_id = declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) => append_relation(declarations[idx], kind, relation_target)
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
      split_top_level(trimmed, ',')
      .map(part => trim_quotes(trim_spaces(part)))
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
    let trimmed = body.strip_prefix("{").unwrap_or(body).to_string() |> trim_spaces
    let inner = trimmed.strip_suffix("}").unwrap_or(trimmed).to_string() |> trim_spaces
    let refs : Array[String] = []
    if inner == "" {
      return refs
    }
    for entry in split_top_level(inner, ',') {
      match segment_after(entry, "=") {
        Some(provider_ref) =>
          append_unique_string(refs, trim_quotes(trim_spaces(provider_ref)))
        None => ()
      }
    }
    refs
  }
}

///|
fn terraform_depends_on_values(clean : String) -> Array[String] {
  segment_after(clean, "=")
  .map(terraform_list_values)
  .unwrap_or([])
}

///|
fn enrich_terraform_record(record : Json) -> Unit {
  let kind = field_string(record, "kind")
  let name = field_string(record, "name")
  let signature = field_string(record, "signature")
  if kind == "module" {
    set_shape_string(record, "owner", name)
  }
  if kind == "type_constraint" {
    let ty = segment_after(signature, "=")
      .map(part => trim_spaces(part))
      .unwrap_or("")
    set_shape_string_array(record, "returns", if ty == "" { [] } else { [ty] })
  }
}

///|
fn find_declaration_index(
  declarations : Array[Json],
  id : String,
  start : Int,
) -> Int? {
  for i in start..<declarations.length() {
    if field_string(declarations[i], "id") == id {
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
  let required_decl_id = declaration_id(profile, path, "required_providers")
  let provider_decl_ids : Map[String, String] = {}

  match find_declaration_index(declarations, required_decl_id, declaration_start) {
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
    let decl_id = declaration_id(profile, path, block.name)
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
          match ensure_language_specific_profile(declarations[idx], "terraform") {
            Some(terraform) => terraform["providerRef"] = Json::string("\{block.name}.\{provider_alias}")
            None => ()
          }
        }
        if required_providers.get(block.name) is Some(_) {
          append_relation(declarations[idx], "provided_by", required_decl_id)
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
    let decl_id = declaration_id(profile, path, block.name)
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) =>
        set_language_specific_bool(
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
    let provider_refs = terraform_provider_map_refs(terraform_attr_value(block, "providers"))
    if provider_refs.is_empty() {
      continue
    }
    let decl_id = declaration_id(profile, path, block.name)
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        let providers : Array[TerraformProviderInfo] = []
        for j in 0..<provider_refs.length() {
          let provider_ref = provider_refs[j]
          let (provider_name, provider_alias) = terraform_provider_ref_parts(provider_ref)
          if provider_name == "" {
            continue
          }
          let info = terraform_provider_info(
            provider_name,
            provider_alias,
            required_providers,
          )
          providers.push(info)
          let provider_decl_id = provider_decl_ids.get(provider_name).unwrap_or(
            declaration_id(profile, path, provider_name),
          )
          append_relation(declarations[idx], "uses_provider", provider_decl_id)
          if j == 0 {
            set_language_specific_string(
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
    let decl_id = declaration_id(profile, path, block.name)
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
      provider_name,
      provider_alias,
      required_providers,
    )
    let provider_decl_id = provider_decl_ids.get(provider_name).unwrap_or(
      declaration_id(profile, path, provider_name),
    )
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        set_terraform_providers(declarations[idx], [info])
        let provider_ref = if provider_alias == "" {
          provider_name
        } else {
          "\{provider_name}.\{provider_alias}"
        }
        set_language_specific_string(
          declarations[idx],
          "terraform",
          "providerRef",
          provider_ref,
        )
        append_relation(declarations[idx], "uses_provider", provider_decl_id)
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
    match last_record(declarations) {
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
      declarations,
      symbols,
      profile,
      server,
      path,
      line_no,
      line,
      active_block,
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
          append_unique_string(media_types, media_type)
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
    if in_components && line != "" && indent <= components_indent && line != "components:" {
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
      append_unique_string(status_codes, openapi_line_key(line))
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
      let status_media_types = openapi_media_types_in_range(lines, i + 1, status_end)
      for media_type in status_media_types {
        append_unique_string(media_types, media_type)
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
          Some(response_media_types) => {
            for media_type in response_media_types {
              append_unique_string(media_types, media_type)
            }
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
      append_unique_string(refs, normalize_reference_target(line))
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
  let kind = field_string(record, "kind")
  let name = field_string(record, "name")
  if kind == "operation" {
    match name.find(" ") {
      Some(idx) if idx > 0 =>
        set_language_specific_string(
          record,
          "openapi",
          "httpMethod",
          name[0:idx].to_string() |> trim_spaces,
        )
      _ => ()
    }
  }
  if kind == "reference" {
    set_language_specific_string(record, "openapi", "ref", name)
  }
  if kind == "security_scheme" {
    set_language_specific_string(record, "openapi", "securitySchemeName", name)
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
  let component_response_media_types = collect_openapi_component_response_media_types(lines)
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
      match last_record(declarations) {
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
        match last_record(declarations) {
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
        match last_record(declarations) {
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
        match last_record(declarations) {
          Some(record) => enrich_openapi_record(record)
          None => ()
        }
        let block_end = openapi_block_end(lines, i, indent)
        for j in (i + 1)..<block_end {
          let child_raw = lines[j].to_string()
          let child_line = trim_spaces(child_raw)
          if leading_spaces(child_raw) != indent + 2 || !child_line.has_prefix("- name:") {
            continue
          }
          let parameter_name = openapi_value_after_colon(child_line[1:].to_string())
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
          match last_record(declarations) {
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
            declaration_id(profile, path, parameter_name),
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
      match last_record(declarations) {
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
      match last_record(declarations) {
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
        lines,
        i,
        indent,
        component_response_media_types,
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
      match last_record(declarations) {
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
      match last_record(declarations) {
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
      match last_record(declarations) {
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
      match last_record(declarations) {
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
      match last_record(declarations) {
        Some(record) => enrich_openapi_record(record)
        None => ()
      }
      let callback_expression = openapi_callback_expression_in_block(lines, i, indent)
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
      match last_record(declarations) {
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
        match last_record(declarations) {
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
      match last_record(declarations) {
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
fn field_string(record : Json, key : String) -> String {
  guard record is Object(object) else { return "" }
  match object.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
fn sort_and_dedup(records : Array[Json], key : String) -> Array[Json] {
  records.sort_by((a, b) => field_string(a, key).compare(field_string(b, key)))
  let deduped : Array[Json] = []
  for i in 0..<records.length() {
    let value = records[i]
    if deduped.is_empty() ||
      field_string(deduped[deduped.length() - 1], key) !=
      field_string(value, key) {
      deduped.push(value)
    }
  }
  deduped
}

///|
fn to_ndjson(records : Array[Json]) -> String {
  if records.is_empty() {
    return ""
  }
  records.map(record => record.stringify()).join("\n") + "\n"
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
        extract_go_file(
          declarations,
          symbols,
          config.profile,
          server,
          relative_path,
          lines,
        )
      "rust-crate" =>
        extract_rust_file(
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
    postprocess_go_declarations(declarations, config.profile)
  } else if config.profile == "rust-crate" {
    postprocess_rust_declarations(declarations, config.profile)
  }

  Ok((sort_and_dedup(declarations, "id"), sort_and_dedup(symbols, "id")))
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

  let (mode, server) = profile_mode(config.profile)
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
  let records_out = collect_records(config, repo, files, server)
  guard records_out is Ok((declarations, symbols)) else {
    return Err(records_out.unwrap_err())
  }

  ensure_non_empty(declarations, symbols, config.profile, server)
  let final_declarations = sort_and_dedup(declarations, "id")
  let final_symbols = sort_and_dedup(symbols, "id")

  Ok({
    declarations_text: to_ndjson(final_declarations),
    symbols_text: to_ndjson(final_symbols),
    mode,
    server,
    version: "\{server_version} | baseline-v2",
    fallback,
    declaration_count: final_declarations.length(),
    symbol_count: final_symbols.length(),
    diagnostic_files: 0,
    commit: resolve_git_commit(repo),
  })
}
