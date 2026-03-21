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
      c == ',' {
      break
    }
    end = end + 1
  }
  trimmed[0:end].to_string()
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
    "terraform-module" => ("parser-first + lsp-supplement", "terraform-ls")
    "openapi-spec" => ("parser-only", "none")
    _ => ("parser-only", "none")
  }
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
) -> Json {
  let canonical = canonical_name(profile, path, name)
  {
    "id": "decl:\{profile}:\{canonical}",
    "kind": kind,
    "name": name,
    "canonical_name": canonical,
    "path": path,
    "signature": signature,
    "shape": { "kind": kind },
    "visibility": "public",
    "docs": "",
    "baselineRole": "baseline",
    "language": language,
    "source_refs": [{ "uri": path, "startLine": line_no, "endLine": line_no }],
    "relations": [],
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
) -> Unit {
  if name == "" {
    return
  }
  declarations.push(
    make_declaration(
      profile, server, language, path, line_no, kind, name, signature,
    ),
  )
  symbols.push(make_symbol(profile, path, line_no, kind, name, signature))
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
  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_spaces(lines[i].to_string())
    if line.has_prefix("type ") {
      let name = first_token(line[5:].to_string())
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "type", name,
        line,
      )
    } else if line.has_prefix("func ") {
      let mut rest = line[5:].to_string()
      if rest.has_prefix("(") {
        match rest.find(") ") {
          Some(idx) => rest = rest[idx + 2:].to_string()
          None => ()
        }
      }
      let name = first_token(rest)
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "function",
        name, line,
      )
    } else if line.has_prefix("const ") {
      let name = first_token(line[6:].to_string())
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "const", name,
        line,
      )
    } else if line.has_prefix("var ") {
      let name = first_token(line[4:].to_string())
      push_record(
        declarations, symbols, profile, server, "go", path, line_no, "var", name,
        line,
      )
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
  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_spaces(lines[i].to_string())
    if line.has_prefix("pub fn ") {
      let name = first_token(line[7:].to_string())
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "function",
        name, line,
      )
    } else if line.has_prefix("pub struct ") {
      let name = first_token(line[11:].to_string())
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "struct",
        name, line,
      )
    } else if line.has_prefix("pub enum ") {
      let name = first_token(line[9:].to_string())
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "enum", name,
        line,
      )
    } else if line.has_prefix("pub trait ") {
      let name = first_token(line[10:].to_string())
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "trait", name,
        line,
      )
    } else if line.has_prefix("pub type ") {
      let name = first_token(line[9:].to_string())
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "type", name,
        line,
      )
    } else if line.has_prefix("pub const ") {
      let name = first_token(line[10:].to_string())
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "const", name,
        line,
      )
    } else if line.has_prefix("pub mod ") {
      let name = first_token(line[8:].to_string())
      push_record(
        declarations, symbols, profile, server, "rust", path, line_no, "module",
        name, line,
      )
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
  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_spaces(lines[i].to_string())
    if line.has_prefix("resource ") {
      let parts = quoted_parts(line)
      if parts.length() >= 2 {
        let name = "\{parts[0]}.\{parts[1]}"
        push_record(
          declarations, symbols, profile, server, "terraform", path, line_no, "resource",
          name, line,
        )
      }
    } else if line.has_prefix("data ") {
      let parts = quoted_parts(line)
      if parts.length() >= 2 {
        let name = "\{parts[0]}.\{parts[1]}"
        push_record(
          declarations, symbols, profile, server, "terraform", path, line_no, "data",
          name, line,
        )
      }
    } else if line.has_prefix("variable ") {
      let parts = quoted_parts(line)
      if parts.length() >= 1 {
        push_record(
          declarations,
          symbols,
          profile,
          server,
          "terraform",
          path,
          line_no,
          "variable",
          parts[0],
          line,
        )
      }
    } else if line.has_prefix("output ") {
      let parts = quoted_parts(line)
      if parts.length() >= 1 {
        push_record(
          declarations,
          symbols,
          profile,
          server,
          "terraform",
          path,
          line_no,
          "output",
          parts[0],
          line,
        )
      }
    } else if line.has_prefix("module ") {
      let parts = quoted_parts(line)
      if parts.length() >= 1 {
        push_record(
          declarations,
          symbols,
          profile,
          server,
          "terraform",
          path,
          line_no,
          "module",
          parts[0],
          line,
        )
      }
    } else if line.has_prefix("provider ") {
      let parts = quoted_parts(line)
      if parts.length() >= 1 {
        push_record(
          declarations,
          symbols,
          profile,
          server,
          "terraform",
          path,
          line_no,
          "provider",
          parts[0],
          line,
        )
      }
    } else if line.has_prefix("locals") && line.has_suffix("{") {
      push_record(
        declarations, symbols, profile, server, "terraform", path, line_no, "locals",
        "locals", line,
      )
    }
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
  let mut current_path = ""
  let mut in_schemas = false
  let mut schemas_indent = -1

  for i in 0..<lines.length() {
    let line_no = i + 1
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)
    let indent = leading_spaces(raw_line)

    if line == "paths:" {
      in_paths = true
      continue
    }
    if line == "components:" {
      in_paths = false
    }

    if in_paths && indent == 2 && line.has_prefix("/") && line.has_suffix(":") {
      match line.strip_suffix(":") {
        Some(value) => current_path = value.to_string()
        None => current_path = line
      }
      continue
    }

    if in_paths && indent == 4 {
      let kind = match line {
        "get:" => Some("GET")
        "post:" => Some("POST")
        "put:" => Some("PUT")
        "delete:" => Some("DELETE")
        "patch:" => Some("PATCH")
        _ => None
      }
      if kind is Some(http_method) {
        let name = "\{http_method} \{current_path}"
        push_record(
          declarations, symbols, profile, server, "openapi", path, line_no, "operation",
          name, name,
        )
      }
    }

    if line == "schemas:" && indent >= 2 {
      in_schemas = true
      schemas_indent = indent
      continue
    }

    if in_schemas {
      if indent <= schemas_indent {
        in_schemas = false
      } else if indent == schemas_indent + 2 && line.has_suffix(":") {
        match line.strip_suffix(":") {
          Some(name) => {
            let schema_name = name.to_string()
            if schema_name != "properties" && schema_name != "required" {
              push_record(
                declarations,
                symbols,
                profile,
                server,
                "openapi",
                path,
                line_no,
                "schema",
                schema_name,
                "schema \{schema_name}",
              )
            }
          }
          None => ()
        }
      }
    }

    if line.has_prefix("operationId:") {
      let name = trim_spaces(line[12:].to_string())
      push_record(
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
    push_record(
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
fn extract_lsp_baseline(
  config : @config.Config,
  repo : String,
) -> Result[ExtractOutput, @cli.CliError] {
  let files_out = resolve_input_files(config, repo)
  guard files_out is Ok(files) else { return Err(files_out.unwrap_err()) }

  let (mode, server) = profile_mode(config.profile)
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
    version: "baseline-v1",
    fallback: false,
    declaration_count: final_declarations.length(),
    symbol_count: final_symbols.length(),
    diagnostic_files: 0,
    commit: "unknown",
  })
}
