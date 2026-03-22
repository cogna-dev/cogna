///|
pub(all) struct UploadResult {
  receipt : Json
  stored_bundle_path : String
} derive(Show, Eq)

///|
fn registry_error(message : String) -> @cli.CliError {
  @cli.command_error("registry failed: \{message}")
}

///|
fn string_field(
  object : Map[String, Json],
  field : String,
) -> Result[String, @cli.CliError] {
  match object.get(field) {
    Some(String(value)) if value != "" => Ok(value)
    _ => Err(registry_error("missing required string field \{field}"))
  }
}

///|
fn int_field(
  object : Map[String, Json],
  field : String,
) -> Result[Int, @cli.CliError] {
  match object.get(field) {
    Some(Number(value, ..)) => Ok(value.to_int())
    _ => Err(registry_error("missing required integer field \{field}"))
  }
}

///|
fn ensure_dir(path : String) -> Result[Unit, @cli.CliError] {
  if @fs.path_exists(path) {
    Ok(())
  } else {
    @fs.create_dir(path) catch {
      err =>
        return Err(
          registry_error("cannot create directory \{path}: \{err.to_string()}"),
        )
    }
    Ok(())
  }
}

///|
fn digest_to_bundle_id(digest : String) -> String {
  let normalized = digest.replace_all(old=":", new="_")
  "bundle_\{normalized}"
}

///|
fn parse_upload(
  upload_request : Json,
) -> Result[(String, String, String, String, Int), @cli.CliError] {
  guard upload_request is Object(object) else {
    return Err(registry_error("upload request must be a JSON object"))
  }
  let bundle_file_out = string_field(object, "bundleFile")
  guard bundle_file_out is Ok(bundle_file) else {
    return Err(bundle_file_out.unwrap_err())
  }
  let bundle_type_out = string_field(object, "bundleType")
  guard bundle_type_out is Ok(bundle_type) else {
    return Err(bundle_type_out.unwrap_err())
  }
  let purl_out = string_field(object, "purl")
  guard purl_out is Ok(purl) else { return Err(purl_out.unwrap_err()) }
  let digest_out = string_field(object, "digest")
  guard digest_out is Ok(digest) else { return Err(digest_out.unwrap_err()) }
  let size_out = int_field(object, "size")
  guard size_out is Ok(size) else { return Err(size_out.unwrap_err()) }
  Ok((bundle_file, bundle_type, purl, digest, size))
}

///|
pub fn upload_local(
  upload_request : Json,
) -> Result[UploadResult, @cli.CliError] {
  let upload_valid = @schema.validate_codeiq_registry_upload_v1(upload_request)
  guard upload_valid is Ok(_) else {
    return Err(
      registry_error(
        "upload request does not satisfy codeiq-registry-upload/v1 schema: \{upload_valid.unwrap_err().to_string()}",
      ),
    )
  }

  let parsed_out = parse_upload(upload_request)
  guard parsed_out is Ok((bundle_file, bundle_type, purl, digest, size)) else {
    return Err(parsed_out.unwrap_err())
  }

  if !@fs.path_exists(bundle_file) {
    return Err(registry_error("bundle file does not exist: \{bundle_file}"))
  }
  let bundle_bytes = @fs.read_file_to_bytes(bundle_file) catch {
    err =>
      return Err(
        registry_error(
          "cannot read bundle file \{bundle_file}: \{err.to_string()}",
        ),
      )
  }

  let computed_digest = "sha256:\{@sha256.sha256_hexdigest(bundle_bytes)}"
  if computed_digest != digest {
    return Err(
      registry_error(
        "digest mismatch: request=\{digest}, computed=\{computed_digest}",
      ),
    )
  }
  if bundle_bytes.length() != size {
    return Err(
      registry_error(
        "size mismatch: request=\{size}, computed=\{bundle_bytes.length()}",
      ),
    )
  }

  let root = ".codeiq/registry"
  let bundles_dir = "\{root}/bundles"
  let index_dir = "\{root}/index"
  let root_out = ensure_dir(".codeiq")
  guard root_out is Ok(_) else { return Err(root_out.unwrap_err()) }
  let registry_out = ensure_dir(root)
  guard registry_out is Ok(_) else { return Err(registry_out.unwrap_err()) }
  let bundles_out = ensure_dir(bundles_dir)
  guard bundles_out is Ok(_) else { return Err(bundles_out.unwrap_err()) }
  let index_out = ensure_dir(index_dir)
  guard index_out is Ok(_) else { return Err(index_out.unwrap_err()) }

  let bundle_id = digest_to_bundle_id(digest)
  let stored_bundle_path = "\{bundles_dir}/\{bundle_id}.ciq.tgz"
  let already_exists = @fs.path_exists(stored_bundle_path)
  if !already_exists {
    @fs.write_bytes_to_file(stored_bundle_path, bundle_bytes) catch {
      err =>
        return Err(
          registry_error(
            "cannot write stored bundle \{stored_bundle_path}: \{err.to_string()}",
          ),
        )
    }
  }

  let status = if already_exists { "already-exists" } else { "published" }
  let publish_id = if already_exists {
    "pub_existing_\{bundle_id}"
  } else {
    "pub_\{bundle_id}"
  }
  let receipt : Json = {
    "schemaVersion": "codeiq-publish-receipt/v1",
    "publishId": publish_id,
    "bundleId": bundle_id,
    "purl": purl,
    "digest": digest,
    "bundleType": bundle_type,
    "downloadUrl": "local://\{stored_bundle_path}",
    "status": status,
  }

  let receipt_valid = @schema.validate_codeiq_publish_receipt_v1(receipt)
  guard receipt_valid is Ok(_) else {
    return Err(
      registry_error(
        "generated receipt does not satisfy codeiq-publish-receipt/v1 schema: \{receipt_valid.unwrap_err().to_string()}",
      ),
    )
  }

  let purl_key = purl
    .replace_all(old="/", new="_")
    .replace_all(old=":", new="_")
    .replace_all(old="@", new="_")
  let index_entry_path = "\{index_dir}/\{purl_key}.json"
  @fs.write_string_to_file(index_entry_path, receipt.stringify(indent=2)) catch {
    err =>
      return Err(
        registry_error(
          "cannot write registry index \{index_entry_path}: \{err.to_string()}",
        ),
      )
  }

  Ok({ receipt, stored_bundle_path })
}
