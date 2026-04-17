///|
/// Output from building a local index.
pub struct LocalIndexOutput {
  /// NDJSON text of all declarations.
  declarations_text : String
  /// Extraction mode identifier (e.g. "parser-first", "native-assisted").
  mode : String
  /// Whether LSP fell back to parser-only mode.
  fallback : Bool
  /// Number of declaration records.
  declaration_count : Int
  /// Number of files with diagnostics (always 0 in SDK path).
  diagnostic_files : Int
  /// Git commit hash resolved from repo, or "unknown".
  commit : String
}

///|
/// Build a local index using canonical (parser-first) extraction.
/// Does not require any external LSP binary.
pub fn build_local_index_canonical(
  config : @config.Config,
  repo : String,
) -> Result[LocalIndexOutput, String] {
  extract_canonical_inner(config, repo)
}

///|
/// Build a local index using native-assisted extraction.
/// Uses the in-repo MoonBit extractor directly without any external binary.
pub fn build_local_index_native(
  config : @config.Config,
  repo : String,
) -> Result[LocalIndexOutput, String] {
  extract_native_inner(config, repo)
}

///|
/// Load NDJSON records from a local index dist/ directory.
/// Returns all declarations, symbols, and software-components records.
pub fn load_local_index(repo : String) -> Array[Json] {
  let records : Array[Json] = []
  let names = ["declarations", "software-components"]
  for name in names {
    let path = "\{repo}/dist/\{name}.ndjson"
    if !@fs.path_exists(path) {
      continue
    }
    let bytes = @fs.read_file_to_bytes(path) catch { _ => continue }
    let text = try? @utf8.decode(bytes)
    guard text is Ok(text_value) else { continue }
    if text_value == "" {
      continue
    }
    for raw_line in text_value.split("\n") {
      let line = raw_line.to_string().trim().to_string()
      if line == "" {
        continue
      }
      let parsed = try? @json.parse(line)
      guard parsed is Ok(value) else { continue }
      records.push(value)
    }
  }
  records
}

///|
fn sdk_local_index_config(
  repo : String,
  profile : String,
  purl : String,
  include_paths : Array[String],
) -> @config.Config {
  let defaults = @config.default_config()
  {
    schema_version: defaults.schema_version,
    profile,
    validation: "none",
    purl,
    source: { repo, source_ref: defaults.source.source_ref },
    inputs: { include_paths, },
    checks: defaults.checks,
    diff: defaults.diff,
    sbom: defaults.sbom,
    cache: defaults.cache,
    mcp: defaults.mcp,
  }
}

///|
fn local_index_output_json(output : LocalIndexOutput) -> Json {
  {
    "declarationsText": output.declarations_text,
    "mode": output.mode,
    "fallback": output.fallback,
    "declarationCount": output.declaration_count,
    "diagnosticFiles": output.diagnostic_files,
    "commit": output.commit,
  }
}

///|
pub fn build_local_index_native_json(
  repo : String,
  profile : String,
  purl : String,
  include_paths : Array[String],
) -> Result[String, String] {
  let config = sdk_local_index_config(repo, profile, purl, include_paths)
  match build_local_index_native(config, repo) {
    Ok(output) => Ok(local_index_output_json(output).stringify())
    Err(message) => Err(message)
  }
}

///|
fn profile_mode_native(profile : String) -> (String, String) {
  match profile {
    "go-module" => ("native-assisted", "gopls")
    "rust-crate" => ("native-assisted", "rust-analyzer")
    "terraform-module" => ("parser-first", "hcl-parser")
    "openapi-spec" => ("parser-only", "none")
    "policy-bundle" => ("policy-bundle", "opa")
    _ => ("parser-only", "none")
  }
}

///|
fn extract_canonical_inner(
  config : @config.Config,
  repo : String,
) -> Result[LocalIndexOutput, String] {
  let files_out = resolve_input_files(config, repo)
  guard files_out is Ok(files) else {
    return Err(files_out.unwrap_err().to_string())
  }
  let (mode, server) = profile_mode(config.profile)
  let records_out = collect_records(config, repo, files, server)
  guard records_out is Ok((declarations, symbols)) else {
    return Err(records_out.unwrap_err().to_string())
  }
  ensure_non_empty(declarations, symbols, config.profile, server)
  let final_declarations = @extract.sort_and_dedup(declarations, "id")
  let _ = @extract.sort_and_dedup(symbols, "id")
  Ok({
    declarations_text: @extract.to_ndjson(final_declarations),
    mode,
    fallback: false,
    declaration_count: final_declarations.length(),
    diagnostic_files: 0,
    commit: resolve_git_commit(repo),
  })
}

///|
fn extract_native_inner(
  config : @config.Config,
  repo : String,
) -> Result[LocalIndexOutput, String] {
  let files_out = resolve_input_files(config, repo)
  guard files_out is Ok(files) else {
    return Err(files_out.unwrap_err().to_string())
  }
  let (mode, server) = profile_mode_native(config.profile)
  let records_out = collect_records(config, repo, files, server)
  guard records_out is Ok((declarations, symbols)) else {
    return Err(records_out.unwrap_err().to_string())
  }
  ensure_non_empty(declarations, symbols, config.profile, server)
  let final_declarations = @extract.sort_and_dedup(declarations, "id")
  let _ = @extract.sort_and_dedup(symbols, "id")
  Ok({
    declarations_text: @extract.to_ndjson(final_declarations),
    mode,
    fallback: false,
    declaration_count: final_declarations.length(),
    diagnostic_files: 0,
    commit: resolve_git_commit(repo),
  })
}
