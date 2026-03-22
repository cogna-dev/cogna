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
pub fn read_manifest(path : String) -> Result[BundleManifest, String] {
  let manifest_out = read_json(path)
  guard manifest_out is Ok(manifest) else {
    return Err(manifest_out.unwrap_err())
  }

  let shape_out = @schema.validate_ciq_bundle_v1(manifest)
  guard shape_out is Ok(_) else {
    return Err(
      "manifest \{path} does not satisfy ciq-bundle/v1 schema: \{shape_out.unwrap_err().to_string()}",
    )
  }

  guard manifest is Object(object) else {
    return Err("manifest \{path} must be object")
  }
  guard object.get("schemaVersion") is Some(String(schema_version)) else {
    return Err("manifest \{path} missing schemaVersion")
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
  let text_out = if path.has_suffix(".zst") {
    let decompressed = @zstd.decompress(file_bytes) catch {
      _ => return Err("cannot decompress ndjson \{path}")
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
      return Err("invalid ndjson line in \{path} at \{i + 1}")
    }
    records.push(value)
  }
  Ok(records)
}

///|
pub fn read_bundle_declarations(repo : String) -> Result[Array[Json], String] {
  read_ndjson("\{repo}/dist/declarations.ndjson.zst")
}

///|
pub fn read_bundle_symbols(repo : String) -> Result[Array[Json], String] {
  read_ndjson("\{repo}/dist/symbols.ndjson.zst")
}
