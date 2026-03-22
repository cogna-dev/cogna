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
  let out = @bundle.read_manifest(path)
  guard out is Ok(manifest) else { return Err(diff_error(out.unwrap_err())) }
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(diff_error("cannot read manifest \{path}: \{err.to_string()}"))
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(diff_error("invalid manifest json in \\{path}"))
  }
  ignore(manifest)
  Ok(value)
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
  let decl_path = "\{root}/declarations.ndjson.zst"
  let decl_out = @bundle.read_ndjson(decl_path)
  guard decl_out is Ok(declarations) else {
    return Err(diff_error(decl_out.unwrap_err()))
  }
  let symbol_path = "\{root}/symbols.ndjson.zst"
  let symbol_out = @bundle.read_ndjson(symbol_path)
  guard symbol_out is Ok(symbols) else {
    return Err(diff_error(symbol_out.unwrap_err()))
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
    diff_object["includeTestChanges"] = true
    diff_object["testSummary"] = { "added": 0, "modified": 0, "removed": 0 }
    diff_object["testChanges"] = []
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
