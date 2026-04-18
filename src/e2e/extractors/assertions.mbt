///|
fn read_file_bytes(path : String) -> Result[Bytes, String] {
  let bytes = @fs.read_file_to_bytes(path) catch {
    err => return Err("cannot read file \{path}: \{err.to_string()}")
  }
  Ok(bytes)
}

///|
fn ensure_file(path : String) -> Result[Unit, String] {
  if !@fs.path_exists(path) {
    return Err("required file missing: \{path}")
  }
  let file_out = try? @fs.is_file(path)
  guard file_out is Ok(true) else {
    return Err("required path is not a file: \{path}")
  }
  Ok(())
}

///|
fn parse_json_file(path : String) -> Result[Json, String] {
  let bytes_out = read_file_bytes(path)
  guard bytes_out is Ok(bytes) else { return Err(bytes_out.unwrap_err()) }
  let text = @utf8.decode(bytes) catch {
    _ => return Err("invalid utf-8 in \{path}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { return Err("invalid json in \{path}") }
  Ok(value)
}

///|
fn validate_declarations(path : String) -> Result[Unit, String] {
  let bytes_out = read_file_bytes(path)
  guard bytes_out is Ok(bytes) else { return Err(bytes_out.unwrap_err()) }
  let text = @utf8.decode(bytes) catch {
    _ => return Err("invalid utf-8 in \{path}")
  }
  if text.trim().to_string() == "" {
    return Err("declarations.ndjson is empty")
  }
  let lines = text.split("\n").to_array()
  let mut count = 0
  for i in 0..<lines.length() {
    let line = lines[i].to_string().trim().to_string()
    if line == "" {
      continue
    }
    let parsed = try? @json.parse(line)
    guard parsed is Ok(value) else {
      return Err("invalid ndjson line in \{path} at \{i + 1}")
    }
    guard value is Object(record) else {
      return Err("declaration line is not object at \{path}:\{i + 1}")
    }
    guard record.get("id") is Some(String(_)) else {
      return Err("declaration missing id at \{path}:\{i + 1}")
    }
    guard record.get("kind") is Some(String(_)) else {
      return Err("declaration missing kind at \{path}:\{i + 1}")
    }
    guard record.get("symbol") is Some(String(_)) else {
      return Err("declaration missing symbol at \{path}:\{i + 1}")
    }
    guard record.get("signature") is Some(String(_)) else {
      return Err("declaration missing signature at \{path}:\{i + 1}")
    }
    count += 1
  }
  if count == 0 {
    return Err("declarations.ndjson has no records")
  }
  Ok(())
}

///|
fn checksum_map(path : String) -> Result[Map[String, String], String] {
  let bytes_out = read_file_bytes(path)
  guard bytes_out is Ok(bytes) else { return Err(bytes_out.unwrap_err()) }
  let text = @utf8.decode(bytes) catch {
    _ => return Err("invalid utf-8 in \{path}")
  }
  let map : Map[String, String] = {}
  let lines = text.split("\n").to_array()
  for i in 0..<lines.length() {
    let line = lines[i].to_string().trim().to_string()
    if line == "" {
      continue
    }
    let split_idx = line.find("  ")
    guard split_idx is Some(idx) else {
      return Err("invalid checksums format at \{path}:\{i + 1}")
    }
    let name = line[:idx].to_string().trim().to_string()
    let digest = line[idx + 2:].to_string().trim().to_string()
    if name == "" || digest == "" {
      return Err("invalid checksum entry at \{path}:\{i + 1}")
    }
    map[name] = digest
  }
  Ok(map)
}

///|
fn verify_checksum(
  checksums : Map[String, String],
  root : String,
  relative_path : String,
) -> Result[Unit, String] {
  guard checksums.get(relative_path) is Some(expected) else {
    return Err("checksums.txt missing entry for \{relative_path}")
  }
  let file_path = "\{root}/\{relative_path}"
  let bytes_out = read_file_bytes(file_path)
  guard bytes_out is Ok(bytes) else { return Err(bytes_out.unwrap_err()) }
  let actual = @sha256.sha256_hexdigest(bytes)
  if actual != expected {
    return Err(
      "checksum mismatch for \{relative_path}: expected \{expected}, got \{actual}",
    )
  }
  Ok(())
}

///|
pub fn assert_snapshot_artifacts(snapshot_dir : String) -> Result[Unit, String] {
  let declarations_path = "\{snapshot_dir}/declarations.ndjson"
  let manifest_path = "\{snapshot_dir}/manifest.json"
  let metadata_path = "\{snapshot_dir}/metadata.json"
  let checksums_path = "\{snapshot_dir}/checksums.txt"

  let required = [declarations_path, manifest_path, metadata_path, checksums_path]
  for i in 0..<required.length() {
    let out = ensure_file(required[i])
    guard out is Ok(_) else { return Err(out.unwrap_err()) }
  }

  let decl_out = validate_declarations(declarations_path)
  guard decl_out is Ok(_) else { return Err(decl_out.unwrap_err()) }

  let manifest_out = parse_json_file(manifest_path)
  guard manifest_out is Ok(manifest) else { return Err(manifest_out.unwrap_err()) }
  guard manifest is Object(manifest_obj) else {
    return Err("manifest.json must be an object")
  }
  guard manifest_obj.get("schemaVersion") is Some(String("ciq-bundle/v1")) else {
    return Err("manifest.json schemaVersion must be ciq-bundle/v1")
  }

  let metadata_out = parse_json_file(metadata_path)
  guard metadata_out is Ok(metadata) else { return Err(metadata_out.unwrap_err()) }
  guard metadata is Object(metadata_obj) else {
    return Err("metadata.json must be an object")
  }
  guard metadata_obj.get("schemaVersion") is Some(String("ciq-metadata/v1")) else {
    return Err("metadata.json schemaVersion must be ciq-metadata/v1")
  }

  let checksums_out = checksum_map(checksums_path)
  guard checksums_out is Ok(checksums) else {
    return Err(checksums_out.unwrap_err())
  }

  let decl_checksum_out = verify_checksum(
    checksums,
    snapshot_dir,
    "declarations.ndjson",
  )
  guard decl_checksum_out is Ok(_) else { return Err(decl_checksum_out.unwrap_err()) }
  let manifest_checksum_out = verify_checksum(checksums, snapshot_dir, "manifest.json")
  guard manifest_checksum_out is Ok(_) else {
    return Err(manifest_checksum_out.unwrap_err())
  }
  let metadata_checksum_out = verify_checksum(checksums, snapshot_dir, "metadata.json")
  guard metadata_checksum_out is Ok(_) else {
    return Err(metadata_checksum_out.unwrap_err())
  }

  Ok(())
}
