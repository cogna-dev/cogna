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
  let raw_name = if is_embedded {
    clean
  } else {
    first_token(clean)
  }
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
    if is_embedded { "embedded_field" } else { "field" },
    "\{owner}.\{name}",
    clean,
    docs,
  )
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
    } else if rest.contains("struct") {
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "struct", type_name,
        clean_line, docs,
      )
    } else if rest.contains("interface") {
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "interface",
        type_name, clean_line, docs,
      )
    } else {
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "type", type_name,
        clean_line, docs,
      )
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
          declarations,
          symbols,
          profile,
          server,
          path,
          line_no,
          active_struct,
          line,
          docs,
        )
      }
      let group_line = strip_braces(line)
      if group_scope_depth == 0 && group_line != "" {
        let synthetic = "\{group_kind} \{group_line}"
        extract_go_record(
          declarations, symbols, profile, server, path, line_no, synthetic, docs,
        )
        if group_kind == "type" && line.contains("struct") && line.has_suffix("{") {
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
        declarations,
        symbols,
        profile,
        server,
        path,
        line_no,
        active_struct,
        line,
        docs,
      )
    }
    if starts_with_any(line, declaration_prefixes) {
      extract_go_record(
        declarations, symbols, profile, server, path, line_no, line, docs,
      )
      if line.has_prefix("type ") && line.contains("struct") && line.has_suffix("{") {
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
fn extract_rust_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  line : String,
  docs : String,
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

  let (kind, name) = if normalized.has_prefix("fn ") {
    ("function", token_before(normalized[3:].to_string(), "("))
  } else if normalized.has_prefix("struct ") {
    ("struct", first_token(normalized[7:].to_string()))
  } else if normalized.has_prefix("enum ") {
    ("enum", first_token(normalized[5:].to_string()))
  } else if normalized.has_prefix("union ") {
    ("union", first_token(normalized[6:].to_string()))
  } else if normalized.has_prefix("trait ") {
    ("trait", first_token(normalized[6:].to_string()))
  } else if normalized.has_prefix("type ") {
    ("type_alias", token_before(normalized[5:].to_string(), "="))
  } else if normalized.has_prefix("const ") {
    ("const", token_before(normalized[6:].to_string(), ":"))
  } else if normalized.has_prefix("static ") {
    ("static", token_before(normalized[7:].to_string(), ":"))
  } else if normalized.has_prefix("mod ") {
    ("module", token_before(normalized[4:].to_string(), "{"))
  } else if normalized.has_prefix("use ") {
    ("use", strip_braces(normalized[4:].to_string()))
  } else if normalized.has_prefix("macro ") {
    ("macro", token_before(normalized[6:].to_string(), "{"))
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
      }
      pending_doc = ""
      pending_doc_line = 0
      pending_deprecated = ""
    }

    if clean.has_prefix("impl ") || clean.has_prefix("impl<") {
      let name = clean.strip_prefix("impl").unwrap_or(clean).to_string()
        |> trim_spaces
        |> strip_braces
      push_simple_record(
        declarations, symbols, profile, server, "rust", path, line_no, "impl", name,
        clean,
      )
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
    if trait_visible && vis_normalized.has_prefix("trait ") {
      pending_trait = first_token(vis_normalized[6:].to_string())
      if clean.has_suffix("{") {
        active_trait = pending_trait
        pending_trait = ""
        active_trait_depth = 0
      }
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
      declarations, symbols, profile, server, path, line_no, line, docs_with_attrs,
    )

    for c in clean {
      if c == '{' {
        if active_trait != "" {
          active_trait_depth = active_trait_depth + 1
        }
      } else if c == '}' {
        if active_trait != "" {
          active_trait_depth = active_trait_depth - 1
          if active_trait_depth <= 0 {
            active_trait = ""
            active_trait_depth = 0
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
) -> Unit {
  let clean = trim_spaces(line)
  if clean == "" {
    return
  }

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
    )
  }
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
fn extract_openapi_file(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
) -> Unit {
  let mut in_paths = false
  let mut in_webhooks = false
  let mut current_path = ""
  let mut in_components = false
  let mut components_indent = -1
  let mut current_component_section = ""
  let mut current_component_name = ""
  let mut current_operation = ""

  for i in 0..<lines.length() {
    let line_no = i + 1
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    let indent = leading_spaces(raw_line)

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
      continue
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
    }

    if line.contains("$ref:") {
      let ref_target = normalize_reference_target(line)
      if ref_target != "" {
        push_simple_record(
          declarations, symbols, profile, server, "openapi", path, line_no, "reference",
          ref_target, line,
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
