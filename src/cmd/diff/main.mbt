///|
pub(all) struct DiffParams {
  repo : String
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
    return Err(diff_error("invalid manifest json in \{path}"))
  }
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
fn detect_manifest_changes(
  base_manifest : Json,
  target_manifest : Json,
) -> Array[Json] {
  let changes : Array[Json] = []

  let base_purl = get_field_string(base_manifest, "purl", "base")
  let target_purl = get_field_string(target_manifest, "purl", "target")
  if base_purl is Ok(base_value) &&
    target_purl is Ok(target_value) &&
    base_value != target_value {
    changes.push({
      "kind": "changed",
      "id": "manifest:purl",
      "path": "manifest.purl",
      "level": "warning",
      "before": base_value,
      "after": target_value,
    })
  }

  let base_profile = get_field_string(base_manifest, "profile", "base")
  let target_profile = get_field_string(target_manifest, "profile", "target")
  if base_profile is Ok(base_value) &&
    target_profile is Ok(target_value) &&
    base_value != target_value {
    changes.push({
      "kind": "changed",
      "id": "manifest:profile",
      "path": "manifest.profile",
      "level": "warning",
      "before": base_value,
      "after": target_value,
    })
  }

  changes
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
fn diff_json(base_manifest : Json, target_manifest : Json) -> Json {
  let changes = detect_manifest_changes(base_manifest, target_manifest)
  {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": field_or_unknown(base_manifest, "purl", "base"),
    "targetPurl": field_or_unknown(target_manifest, "purl", "target"),
    "summary": {
      "added": 0,
      "removed": 0,
      "changed": changes.length(),
      "deprecated": 0,
    },
    "changes": changes,
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

  let diff = diff_json(base_manifest, target_manifest)
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
    summary: "Generated CIQ diff skeleton at \{output_path}",
  })
}
