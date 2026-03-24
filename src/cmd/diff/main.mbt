///|
pub(all) struct DiffParams {
  repo : String
  since : String?
  include_test_changes : Bool
} derive(Show, Eq)

///|
pub(all) struct DiffResult {
  repo : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for DiffResult with display(self : DiffResult) -> String {
  self.summary
}

///|
fn diff_error(message : String) -> @cli.CliError {
  @cli.command_error("diff failed: \{message}")
}

///|
fn read_manifest(path : String) -> Result[Json, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(diff_error("cannot read manifest \{path}: \{err.to_string()}"))
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(diff_error("invalid manifest json in \\{path}"))
  }
  Ok(value)
}

///|
fn decode_utf8(bytes : Bytes, path : String) -> Result[String, @cli.CliError] {
  let text = @utf8.decode(bytes) catch {
    _ => return Err(diff_error("invalid utf-8 bytes in \{path}"))
  }
  Ok(text)
}

///|
fn read_ndjson(path : String) -> Result[Array[Json], @cli.CliError] {
  let file_bytes = @fs.read_file_to_bytes(path) catch {
    _ => return Err(diff_error("cannot read ndjson \{path}"))
  }
  let text_out = if path.has_suffix(".zst") {
    let decompressed = @zstd.decompress(file_bytes) catch {
      _ => return Err(diff_error("cannot decompress ndjson \{path}"))
    }
    decode_utf8(decompressed, path)
  } else {
    decode_utf8(file_bytes, path)
  }
  guard text_out is Ok(text) else { return Err(text_out.unwrap_err()) }
  if text == "" {
    return Ok([])
  }

  let lines = text.split("\n").to_array()
  let records : Array[Json] = []
  for i in 0..<lines.length() {
    let line = lines[i].to_string().trim().to_string()
    if line == "" {
      continue
    }
    let parsed = try? @json.parse(line)
    guard parsed is Ok(value) else {
      return Err(diff_error("invalid ndjson line in \{path} at \{i + 1}"))
    }
    records.push(value)
  }
  Ok(records)
}

///|
fn validate_manifest_shape(
  manifest : Json,
  path : String,
) -> Result[Unit, @cli.CliError] {
  let out = @schema.validate_ciq_bundle_v1(manifest)
  guard out is Ok(_) else {
    return Err(
      diff_error(
        "manifest \{path} does not satisfy ciq-bundle/v1 schema: \{out.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(())
}

///|
fn get_field_string(
  manifest : Json,
  field_name : String,
  path : String,
) -> Result[String, @cli.CliError] {
  guard manifest is Object(object) else {
    return Err(diff_error("manifest \{path} must be a JSON object"))
  }
  guard object.get(field_name) is Some(String(value)) else {
    return Err(
      diff_error("manifest \{path} missing string field \{field_name}"),
    )
  }
  Ok(value)
}

///|
fn record_string(record : Json, field : String) -> String? {
  guard record is Object(object) else { return None }
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
}

///|
fn record_bool(record : Json, field : String) -> Bool {
  guard record is Object(object) else { return false }
  match object.get(field) {
    Some(True) => true
    _ => false
  }
}

///|
fn artifact_records(root : String) -> Result[Array[Json], @cli.CliError] {
  let decl_path_zst = "\{root}/declarations.ndjson.zst"
  let decl_path_plain = "\{root}/declarations.ndjson"
  let decl_out = if @fs.path_exists(decl_path_zst) {
    read_ndjson(decl_path_zst)
  } else if @fs.path_exists(decl_path_plain) {
    read_ndjson(decl_path_plain)
  } else {
    Err(diff_error("cannot read ndjson \{decl_path_zst}"))
  }
  guard decl_out is Ok(declarations) else {
    return Err(decl_out.unwrap_err())
  }

  let symbol_path_zst = "\{root}/symbols.ndjson.zst"
  let symbol_path_plain = "\{root}/symbols.ndjson"
  let symbol_out = if @fs.path_exists(symbol_path_zst) {
    read_ndjson(symbol_path_zst)
  } else if @fs.path_exists(symbol_path_plain) {
    read_ndjson(symbol_path_plain)
  } else {
    Err(diff_error("cannot read ndjson \{symbol_path_zst}"))
  }
  guard symbol_out is Ok(symbols) else {
    return Err(symbol_out.unwrap_err())
  }

  let records : Array[Json] = []
  for i in 0..<declarations.length() {
    records.push(declarations[i])
  }
  for i in 0..<symbols.length() {
    records.push(symbols[i])
  }
  Ok(records)
}

///|
fn record_index(records : Array[Json]) -> Map[String, Json] {
  let index : Map[String, Json] = {}
  for i in 0..<records.length() {
    let id = record_string(records[i], "id")
    guard id is Some(key) else { continue }
    index[key] = records[i]
  }
  index
}

///|
fn record_path(record : Json) -> String {
  match record_string(record, "path") {
    Some(value) => value
    None => "unknown"
  }
}

///|
fn record_location(record : Json, path_fallback : String) -> Json {
  guard record is Object(object) else {
    return { "uri": path_fallback, "startLine": 1, "endLine": 1 }
  }
  match object.get("location") {
    Some(Object(location_object)) => {
      let uri = match location_object.get("uri") {
        Some(String(value)) if value != "" => value
        _ => path_fallback
      }
      let start_line = match location_object.get("startLine") {
        Some(Number(value, ..)) => value.to_int()
        _ => 1
      }
      let end_line = match location_object.get("endLine") {
        Some(Number(value, ..)) => value.to_int()
        _ => start_line
      }
      { "uri": uri, "startLine": start_line, "endLine": end_line }
    }
    _ => { "uri": path_fallback, "startLine": 1, "endLine": 1 }
  }
}

///|
fn location_key(record : Json) -> String {
  let fallback = record_path(record)
  let location = record_location(record, fallback)
  guard location is Object(location_object) else { return fallback }
  let uri = match location_object.get("uri") {
    Some(String(value)) if value != "" => value
    _ => fallback
  }
  let start_line = match location_object.get("startLine") {
    Some(Number(value, ..)) => value.to_int()
    _ => 1
  }
  let end_line = match location_object.get("endLine") {
    Some(Number(value, ..)) => value.to_int()
    _ => start_line
  }
  "\{uri}:\{start_line}:\{end_line}"
}

///|
fn record_language(record : Json) -> String {
  match record_string(record, "language") {
    Some(value) if value != "" => value
    _ => {
      let path = record_path(record)
      if path.has_suffix(".go") {
        "go"
      } else if path.has_suffix(".rs") {
        "rust"
      } else {
        let id = record_string(record, "id").unwrap_or("")
        if id.contains("go-module") {
          "go"
        } else if id.contains("rust-crate") {
          "rust"
        } else {
          "unknown"
        }
      }
    }
  }
}

///|
fn is_go_test_name(name : String) -> Bool {
  name.has_prefix("Test") ||
  name.has_prefix("Benchmark") ||
  name.has_prefix("Fuzz") ||
  name.has_prefix("Example")
}

///|
fn is_go_test_signature(signature : String) -> Bool {
  signature.has_prefix("func Test") ||
  signature.has_prefix("func Benchmark") ||
  signature.has_prefix("func Fuzz") ||
  signature.has_prefix("func Example")
}

///|
fn is_rust_test_signature(signature : String) -> Bool {
  signature.contains("#[test]") || signature.contains("# [test]")
}

///|
fn is_rust_test_name(name : String) -> Bool {
  name.has_prefix("test_") || name.has_suffix("_test")
}

///|
fn is_test_record(record : Json) -> Bool {
  let id = record_string(record, "id").unwrap_or("")
  if !id.has_prefix("decl:") {
    return false
  }
  let path = record_path(record)
  let signature = record_string(record, "signature").unwrap_or("")
  let name = record_string(record, "name").unwrap_or("")
  match record_language(record) {
    "go" =>
      path.has_suffix("_test.go") ||
      is_go_test_signature(signature) ||
      is_go_test_name(name)
    "rust" =>
      path.has_prefix("tests/") ||
      path.contains("/tests/") ||
      path.has_suffix("_test.rs") ||
      is_rust_test_signature(signature) ||
      is_rust_test_name(name)
    _ => false
  }
}

///|
fn test_change_id(record : Json) -> String {
  let id = record_string(record, "id").unwrap_or("")
  if id.has_prefix("decl:") {
    "test:\{id[5:].to_string()}"
  } else if id.has_prefix("sym:") {
    "test:\{id[4:].to_string()}"
  } else {
    "test:\{id}"
  }
}

///|
fn test_change_path(record : Json) -> String {
  match record_string(record, "canonical_name") {
    Some(value) => value
    None => record_path(record)
  }
}

///|
fn test_change_record(kind : String, record : Json) -> Json {
  let fallback = record_path(record)
  {
    "kind": kind,
    "language": record_language(record),
    "id": test_change_id(record),
    "path": test_change_path(record),
    "signature": record_string(record, "signature").unwrap_or("unknown"),
    "location": record_location(record, fallback),
  }
}

///|
fn test_change_sort_key(change : Json) -> String {
  guard change is Object(change_object) else { return "" }
  match change_object.get("id") {
    Some(String(id)) => id
    _ => ""
  }
}

///|
fn test_record_index(records : Array[Json]) -> Map[String, Json] {
  let index : Map[String, Json] = {}
  for i in 0..<records.length() {
    let record = records[i]
    if !is_test_record(record) {
      continue
    }
    let key = test_change_id(record)
    if key != "" && key != "test:" {
      index[key] = record
    }
  }
  index
}

///|
fn has_test_change(base : Json, target : Json) -> Bool {
  if has_shape_change(base, target) {
    return true
  }
  location_key(base) != location_key(target)
}

///|
fn test_changes(
  base_records : Array[Json],
  target_records : Array[Json],
) -> Array[Json] {
  let changes : Array[Json] = []
  let base_index = test_record_index(base_records)
  let target_index = test_record_index(target_records)

  for id, target in target_index {
    match base_index.get(id) {
      Some(base) =>
        if has_test_change(base, target) {
          changes.push(test_change_record("modified", target))
        }
      None => changes.push(test_change_record("added", target))
    }
  }

  for id, base in base_index {
    if !target_index.contains(id) {
      changes.push(test_change_record("removed", base))
    }
  }

  changes.sort_by((a, b) => {
    test_change_sort_key(a).compare(test_change_sort_key(b))
  })
  changes
}

///|
fn has_shape_change(base : Json, target : Json) -> Bool {
  let base_signature = record_string(base, "signature")
  let target_signature = record_string(target, "signature")
  if base_signature != target_signature {
    return true
  }
  let base_kind = record_string(base, "kind")
  let target_kind = record_string(target, "kind")
  if base_kind != target_kind {
    return true
  }
  let base_path = record_string(base, "path")
  let target_path = record_string(target, "path")
  base_path != target_path
}

///|
fn declaration_changes(
  base_records : Array[Json],
  target_records : Array[Json],
) -> Array[Json] {
  let changes : Array[Json] = []
  let base_index = record_index(base_records)
  let target_index = record_index(target_records)

  for id, target in target_index {
    match base_index.get(id) {
      Some(base) => {
        if has_shape_change(base, target) {
          changes.push({
            "kind": "changed",
            "id": id,
            "path": record_path(target),
            "level": "warning",
            "before": record_string(base, "signature").unwrap_or("unknown"),
            "after": record_string(target, "signature").unwrap_or("unknown"),
          })
        }
        if record_bool(target, "deprecated") && !record_bool(base, "deprecated") {
          changes.push({
            "kind": "deprecated",
            "id": id,
            "path": record_path(target),
            "level": "warning",
          })
        }
      }
      None =>
        changes.push({
          "kind": "added",
          "id": id,
          "path": record_path(target),
          "level": "note",
        })
    }
  }

  for id, base in base_index {
    if !target_index.contains(id) {
      changes.push({
        "kind": "removed",
        "id": id,
        "path": record_path(base),
        "level": "breaking",
      })
    }
  }

  changes
}

///|
fn count_changes(changes : Array[Json], kind : String) -> Int {
  let mut count = 0
  for i in 0..<changes.length() {
    guard changes[i] is Object(change) else { continue }
    match change.get("kind") {
      Some(String(change_kind)) if change_kind == kind => count = count + 1
      _ => ()
    }
  }
  count
}

///|
fn field_or_unknown(
  manifest : Json,
  field_name : String,
  path : String,
) -> String {
  match get_field_string(manifest, field_name, path) {
    Ok(value) => value
    Err(_) => "unknown"
  }
}

///|
fn write_diff(path : String, diff : Json) -> Result[Unit, @cli.CliError] {
  let serialized = diff.stringify(indent=2)
  @fs.write_string_to_file(path, serialized) catch {
    err =>
      return Err(
        diff_error("cannot write diff file \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
pub fn run(params : DiffParams) -> @cli.CliResult[DiffResult, @cli.CliError] {
  let base_manifest_path = "\{params.repo}/dist/base/manifest.json"
  let target_manifest_path = "\{params.repo}/dist/target/manifest.json"
  let output_path = "\{params.repo}/dist/diff.json"

  let base_manifest_out = read_manifest(base_manifest_path)
  guard base_manifest_out is Ok(base_manifest) else {
    return Err(base_manifest_out.unwrap_err())
  }
  let base_schema_out = validate_manifest_shape(
    base_manifest, base_manifest_path,
  )
  guard base_schema_out is Ok(_) else {
    return Err(base_schema_out.unwrap_err())
  }

  let target_manifest_out = read_manifest(target_manifest_path)
  guard target_manifest_out is Ok(target_manifest) else {
    return Err(target_manifest_out.unwrap_err())
  }
  let target_schema_out = validate_manifest_shape(
    target_manifest, target_manifest_path,
  )
  guard target_schema_out is Ok(_) else {
    return Err(target_schema_out.unwrap_err())
  }

  let base_records_out = artifact_records("\{params.repo}/dist/base")
  guard base_records_out is Ok(base_records) else {
    return Err(base_records_out.unwrap_err())
  }
  let target_records_out = artifact_records("\{params.repo}/dist/target")
  guard target_records_out is Ok(target_records) else {
    return Err(target_records_out.unwrap_err())
  }

  let changes = declaration_changes(base_records, target_records)
  let diff : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": field_or_unknown(base_manifest, "purl", "base"),
    "targetPurl": field_or_unknown(target_manifest, "purl", "target"),
    "summary": {
      "added": count_changes(changes, "added"),
      "removed": count_changes(changes, "removed"),
      "changed": count_changes(changes, "changed"),
      "deprecated": count_changes(changes, "deprecated"),
    },
    "changes": changes,
  }
  guard diff is Object(diff_object) else {
    return Err(diff_error("generated diff must be a JSON object"))
  }
  if params.since is Some(since) {
    diff_object["since"] = Json::string(since)
  }
  if params.include_test_changes {
    let all_test_changes = test_changes(base_records, target_records)
    diff_object["includeTestChanges"] = true
    diff_object["testSummary"] = {
      "added": count_changes(all_test_changes, "added"),
      "modified": count_changes(all_test_changes, "modified"),
      "removed": count_changes(all_test_changes, "removed"),
    }
    diff_object["testChanges"] = Json::array(all_test_changes)
  }
  let diff_schema_out = @schema.validate_ciq_diff_v1(diff)
  guard diff_schema_out is Ok(_) else {
    return Err(
      diff_error(
        "generated diff does not satisfy ciq-diff/v1 schema: \{diff_schema_out.unwrap_err().to_string()}",
      ),
    )
  }

  let write_out = write_diff(output_path, diff)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    repo: params.repo,
    summary: "Generated CIQ declaration diff at \{output_path}",
  })
}
