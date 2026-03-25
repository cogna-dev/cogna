///|
pub(all) struct BundleArtifact {
  path : String
  sha256 : String
  compression : String
} derive(Show, Eq)

///|
pub(all) struct BundleManifest {
  schema_version : String
  purl : String
  profile : String
  artifacts : Array[BundleArtifact]
} derive(Show, Eq)

///|
fn read_json(path : String) -> Result[Json, String] {
  let text = @fs.read_file_to_string(path) catch {
    _ => return Err("cannot read json \{path}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { return Err("invalid json in \{path}") }
  Ok(value)
}

///|
fn decode_utf8(bytes : Bytes, path : String) -> Result[String, String] {
  let text = @utf8.decode(bytes) catch {
    _ => return Err("invalid utf-8 bytes in \{path}")
  }
  Ok(text)
}

///|
fn validate_manifest_shape(
  path : String,
  manifest : Json,
) -> Result[String, String] {
  guard manifest is Object(object) else {
    return Err("manifest \{path} must be object")
  }
  guard object.get("schemaVersion") is Some(String(schema_version)) else {
    return Err("manifest \{path} missing schemaVersion")
  }
  let out = match schema_version {
    "ciq-bundle/v1" => @schema.validate_ciq_bundle_v1(manifest)
    "ciq-opa-bundle/v1" => @schema.validate_ciq_opa_bundle_v1(manifest)
    _ =>
      return Err(
        "manifest \{path} has unsupported schemaVersion \{schema_version}",
      )
  }
  guard out is Ok(_) else {
    return Err(
      "manifest \{path} does not satisfy \{schema_version} schema: \{out.unwrap_err().to_string()}",
    )
  }
  Ok(schema_version)
}

///|
pub fn read_manifest(path : String) -> Result[BundleManifest, String] {
  let manifest_out = read_json(path)
  guard manifest_out is Ok(manifest) else {
    return Err(manifest_out.unwrap_err())
  }

  let shape_out = validate_manifest_shape(path, manifest)
  guard shape_out is Ok(schema_version) else {
    return Err(shape_out.unwrap_err())
  }
  guard manifest is Object(object) else {
    return Err("manifest \{path} must be object")
  }
  guard object.get("purl") is Some(String(purl)) else {
    return Err("manifest \{path} missing purl")
  }
  guard object.get("profile") is Some(String(profile)) else {
    return Err("manifest \{path} missing profile")
  }
  guard object.get("artifacts") is Some(Array(items)) else {
    return Err("manifest \{path} missing artifacts")
  }

  let artifacts : Array[BundleArtifact] = []
  for i in 0..<items.length() {
    guard items[i] is Object(item) else { continue }
    guard item.get("path") is Some(String(artifact_path)) else { continue }
    guard item.get("sha256") is Some(String(sha256)) else { continue }
    guard item.get("compression") is Some(String(compression)) else { continue }
    artifacts.push({ path: artifact_path, sha256, compression })
  }

  Ok({ schema_version, purl, profile, artifacts })
}

///|
pub fn read_local_query_result(root : String) -> Json? {
  let path = "\{root}/dist/query.result.json"
  let out = read_json(path)
  match out {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
pub fn read_local_sarif(root : String) -> Json? {
  let path = "\{root}/dist/check.sarif.json"
  let out = read_json(path)
  match out {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
pub fn read_ndjson(path : String) -> Result[Array[Json], String] {
  let file_bytes = @fs.read_file_to_bytes(path) catch {
    _ => return Err("cannot read ndjson \{path}")
  }
  let text_out = decode_utf8(file_bytes, path)
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
      return Err("invalid ndjson line in \{path} at \{i + 1}")
    }
    records.push(value)
  }
  Ok(records)
}

///|
fn bundle_ndjson_path(repo : String, name : String) -> Result[String, String] {
  let plain_path = "\{repo}/dist/\{name}.ndjson"
  if @fs.path_exists(plain_path) {
    Ok(plain_path)
  } else {
    Err("cannot read ndjson \{plain_path}")
  }
}

///|
pub fn read_bundle_declarations(repo : String) -> Result[Array[Json], String] {
  let path_out = bundle_ndjson_path(repo, "declarations")
  guard path_out is Ok(path) else { return Err(path_out.unwrap_err()) }
  let records_out = read_ndjson(path)
  guard records_out is Ok(records) else { return Err(records_out.unwrap_err()) }
  for i in 0..<records.length() {
    guard records[i] is Object(record_object) else { continue }
    let should_validate = record_object.contains("shape") ||
      record_object.contains("relations") ||
      record_object.contains("language_specific")
    if should_validate {
      let valid = @schema.validate_ciq_declaration_v1(records[i])
      guard valid is Ok(_) else {
        return Err(
          "invalid declaration record at \{path} line \{i + 1}: \{valid.unwrap_err().to_string()}",
        )
      }
    }
  }
  Ok(records)
}

///|
pub fn read_bundle_symbols(repo : String) -> Result[Array[Json], String] {
  let path_out = bundle_ndjson_path(repo, "symbols")
  guard path_out is Ok(path) else { return Err(path_out.unwrap_err()) }
  read_ndjson(path)
}

///|
fn tar_field(header : Bytes, start : Int, length : Int) -> String {
  let segment = header[start:start + length]
  let mut end = segment.length()
  for i in 0..<segment.length() {
    if segment[i] == b'\x00' {
      end = i
      break
    }
  }
  let content = segment[:end]
  @utf8.decode(content) catch {
    _ => ""
  }
}

///|
fn tar_octal_field(header : Bytes, start : Int, length : Int) -> Int {
  let text = tar_field(header, start, length).trim().to_string()
  if text == "" {
    return 0
  }
  let mut value = 0
  for i in 0..<text.length() {
    let code = text[i]
    if code < '0' || code > '7' {
      continue
    }
    value = value * 8 + (code.to_int() - 48)
  }
  value
}

///|
fn parse_tar_entries(payload : Bytes) -> Result[Map[String, Bytes], String] {
  let entries : Map[String, Bytes] = {}
  let mut offset = 0
  while offset + 512 <= payload.length() {
    let header = payload[offset:offset + 512].to_bytes()
    let mut all_zero = true
    for i in 0..<512 {
      if header[i] != b'\x00' {
        all_zero = false
        break
      }
    }
    if all_zero {
      break
    }
    let name = tar_field(header, 0, 100)
    let size = tar_octal_field(header, 124, 12)
    let body_start = offset + 512
    let body_end = body_start + size
    if body_end > payload.length() {
      return Err("invalid tar archive: entry \{name} truncated")
    }
    entries[name] = payload[body_start:body_end].to_bytes()
    let padded_size = (size + 511) / 512 * 512
    offset = body_start + padded_size
  }
  Ok(entries)
}

///|
fn read_gzip_tar(path : String) -> Result[Map[String, Bytes], String] {
  let gzip_bytes = @fs.read_file_to_bytes(path) catch {
    _ => return Err("cannot read gzip tar \{path}")
  }
  let source = @gio.Buffer::from_bytes(gzip_bytes)
  let flate_reader : &@flate.Reader = source
  let reader_out = @gzip.Reader::new(flate_reader)
  guard reader_out is (reader, None) else {
    return Err("cannot open gzip reader for \{path}")
  }
  let read_out = @gio.read_all(reader)
  let close_out = reader.close()
  guard close_out is None else {
    return Err("cannot close gzip reader for \{path}")
  }
  guard read_out is (payload, None) else {
    return Err("cannot read gzip payload for \{path}")
  }
  parse_tar_entries(payload.to_bytes())
}

///|
fn write_bundle_entry(
  dist_root : String,
  name : String,
  content : Bytes,
) -> Result[Unit, String] {
  let path = "\{dist_root}/\{name}"
  @fs.write_bytes_to_file(path, content) catch {
    _ => return Err("cannot write bundle entry \{path}")
  }
  Ok(())
}

///|
pub fn materialize_bundle_tar_gz(
  bundle_path : String,
  dist_root : String,
) -> Result[Unit, String] {
  if !@fs.path_exists(bundle_path) {
    return Err("bundle path not found: \{bundle_path}")
  }
  if !@fs.path_exists(dist_root) {
    @fs.create_dir(dist_root) catch {
      _ => return Err("cannot create dist directory \{dist_root}")
    }
  }
  let entries_out = read_gzip_tar(bundle_path)
  guard entries_out is Ok(entries) else { return Err(entries_out.unwrap_err()) }

  let required = ["manifest.json", "metadata.json", "checksums.txt"]
  for i in 0..<required.length() {
    if !entries.contains(required[i]) {
      return Err("bundle missing required entry \{required[i]}")
    }
  }
  if !entries.contains("declarations.ndjson") {
    return Err("bundle missing required entry declarations.ndjson")
  }
  if !entries.contains("symbols.ndjson") {
    return Err("bundle missing required entry symbols.ndjson")
  }

  for name, content in entries {
    let write_out = write_bundle_entry(dist_root, name, content)
    guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  }
  Ok(())
}
