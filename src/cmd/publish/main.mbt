///|
pub(all) struct PublishParams {
  bundle_file : String
} derive(Show, Eq)

///|
pub(all) struct PublishResult {
  bundle_file : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for PublishResult with display(self : PublishResult) -> String {
  self.summary
}

///|
fn publish_error(message : String) -> @cli.CliError {
  @cli.command_error("publish failed: \{message}")
}

///|
fn ensure_bundle_exists(path : String) -> Result[Unit, @cli.CliError] {
  if @fs.path_exists(path) {
    Ok(())
  } else {
    Err(publish_error("bundle file does not exist: \{path}"))
  }
}

///|
fn parent_dir(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() <= 1 {
    "."
  } else {
    let mut out = ""
    for i in 0..<(parts.length() - 1) {
      if i > 0 {
        out = "\{out}/"
      }
      out = "\{out}\{parts[i]}"
    }
    out
  }
}

///|
fn detect_bundle_type(path : String) -> String {
  let parent = parent_dir(path)
  let manifest_path = "\{parent}/manifest.json"
  if !@fs.path_exists(manifest_path) {
    return "ciq-bundle"
  }
  let manifest_text = @fs.read_file_to_string(manifest_path) catch {
    _ => return "ciq-bundle"
  }
  let parsed = try? @json.parse(manifest_text)
  guard parsed is Ok(Object(manifest)) else { return "ciq-bundle" }
  match manifest.get("schemaVersion") {
    Some(String("ciq-opa-bundle/v1")) => "ciq-opa-bundle"
    _ => "ciq-bundle"
  }
}

///|
fn detect_purl(path : String) -> String {
  let parent = parent_dir(path)
  let manifest_path = "\{parent}/manifest.json"
  if !@fs.path_exists(manifest_path) {
    return "pkg:generic/local/bundle@0"
  }
  let manifest_text = @fs.read_file_to_string(manifest_path) catch {
    _ => return "pkg:generic/local/bundle@0"
  }
  let parsed = try? @json.parse(manifest_text)
  guard parsed is Ok(Object(manifest)) else {
    return "pkg:generic/local/bundle@0"
  }
  match manifest.get("purl") {
    Some(String(purl)) if purl != "" => purl
    _ => "pkg:generic/local/bundle@0"
  }
}

///|
fn upload_request(bundle_file : String) -> Result[Json, @cli.CliError] {
  let bytes = @fs.read_file_to_bytes(bundle_file) catch {
    err =>
      return Err(
        publish_error(
          "cannot read bundle file \{bundle_file}: \{err.to_string()}",
        ),
      )
  }
  let digest = "sha256:\{@sha256.sha256_hexdigest(bytes)}"
  let request : Json = {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_file,
    "bundleType": detect_bundle_type(bundle_file),
    "purl": detect_purl(bundle_file),
    "digest": digest,
    "size": bytes.length(),
  }
  let valid = @schema.validate_codeiq_registry_upload_v1(request)
  guard valid is Ok(_) else {
    return Err(
      publish_error(
        "generated upload request does not satisfy codeiq-registry-upload/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(request)
}

///|
fn publish_receipt(bundle_file : String) -> Result[Json, @cli.CliError] {
  let request_out = upload_request(bundle_file)
  guard request_out is Ok(request) else { return Err(request_out.unwrap_err()) }
  let uploaded_out = @registry.upload_local(request)
  guard uploaded_out is Ok(uploaded) else {
    return Err(publish_error(uploaded_out.unwrap_err().to_string()))
  }
  let receipt = uploaded.receipt
  let valid = @schema.validate_codeiq_publish_receipt_v1(receipt)
  guard valid is Ok(_) else {
    return Err(
      publish_error(
        "registry response does not satisfy codeiq-publish-receipt/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(receipt)
}

///|
fn write_receipt(path : String, receipt : Json) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, receipt.stringify(indent=2)) catch {
    err =>
      return Err(
        publish_error(
          "cannot write publish receipt \{path}: \{err.to_string()}",
        ),
      )
  }
  Ok(())
}

///|
pub fn run(
  params : PublishParams,
) -> @cli.CliResult[PublishResult, @cli.CliError] {
  let exists_out = ensure_bundle_exists(params.bundle_file)
  guard exists_out is Ok(_) else { return Err(exists_out.unwrap_err()) }

  let receipt_path = "\{parent_dir(params.bundle_file)}/publish.json"
  let receipt_out = publish_receipt(params.bundle_file)
  guard receipt_out is Ok(receipt) else { return Err(receipt_out.unwrap_err()) }
  let write_out = write_receipt(receipt_path, receipt)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    bundle_file: params.bundle_file,
    summary: "Generated publish receipt at \{receipt_path}",
  })
}
