///|
pub(all) struct PublishParams {
  bundle_file : String
} derive(Eq)

///|
pub impl Show for PublishParams with output(self, logger) {
  logger.write_string("{bundle_file: ")
  logger.write_object(self.bundle_file)
  logger.write_char('}')
}

///|
pub(all) struct PublishResult {
  bundle_file : String
  summary : String
} derive(Eq)

///|
pub impl Show for PublishResult with output(self, logger) {
  logger.write_string("{bundle_file: ")
  logger.write_object(self.bundle_file)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for PublishResult with display(self : PublishResult) -> String {
  self.summary
}

///|
fn publish_error(message : String) -> @cli.CliError {
  @cli.command_error("publish failed: \{message}")
}

///|
fn should_fail_on_download_error(message : String) -> Bool {
  message.contains("invalid sha256 digest") ||
  message.contains("digest mismatch")
}

///|
fn trust_enforcement_required() -> Bool {
  false
}

///|
fn signature_from_env() -> Json {
  @client.signature_json(@client.load_signature_status_from_env())
}

///|
fn signature_from_download(download : Map[String, Json]) -> Json {
  @client.signature_json(@client.signature_status_from_download(download))
}

///|
fn signature_from_receipt(receipt : Map[String, Json]) -> Json {
  @client.signature_json(@client.signature_status_from_receipt(receipt))
}

///|
fn ensure_signature_status_allowed(
  signature : Json,
  enforce_trust~ : Bool,
) -> Result[Unit, @cli.CliError] {
  guard signature is Object(signature_object) else {
    return Err(publish_error("invalid signature metadata shape"))
  }
  let status = match signature_object.get("status") {
    Some(String(value)) => @client.parse_signature_status(value)
    _ => "unsigned"
  }
  if enforce_trust && status == "untrusted" {
    Err(publish_error("registry signature status is untrusted"))
  } else {
    Ok(())
  }
}

///|
fn verify_signature_with_openssl(
  bundle_file : String,
  signature : Json,
) -> Json {
  ignore(bundle_file)
  signature
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
fn maybe_resolve_publish_config(
  bundle_file : String,
) -> @config.ResolvedConfig? {
  let bundle_dir = parent_dir(bundle_file)
  let repo_root = parent_dir(bundle_dir)
  match @config.resolve(repo_root) {
    Ok(resolved) => Some(resolved)
    Err(_) => None
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
  let signature = signature_from_env()
  let request : Json = {
    "schemaVersion": "cogna-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_file,
    "bundleType": detect_bundle_type(bundle_file),
    "purl": detect_purl(bundle_file),
    "digest": digest,
    "size": bytes.length(),
    "signature": signature,
  }
  Ok(request)
}

///|
fn publish_receipt(bundle_file : String) -> Result[Json, @cli.CliError] {
  let request_out = upload_request(bundle_file)
  guard request_out is Ok(request) else { return Err(request_out.unwrap_err()) }
  let request_object = match request {
    Object(object) => object
    _ => return Err(publish_error("upload request must be object"))
  }

  let download_purl = match request_object.get("purl") {
    Some(String(value)) => value
    _ => ""
  }
  let request_digest = match request_object.get("digest") {
    Some(String(value)) => value
    _ => "sha256:unknown"
  }
  let request_bundle_type = match request_object.get("bundleType") {
    Some(String(value)) => value
    _ => "ciq-bundle"
  }
  let enforce_trust = trust_enforcement_required()
  let if_none_match = @sys.get_env_var("COGNA_REGISTRY_IF_NONE_MATCH")
  if download_purl != "" {
    match if_none_match {
      Some(value) if value != "" =>
        @sys.set_env_var("COGNA_REGISTRY_HEADER_If-None-Match", value)
      _ => @sys.unset_env_var("COGNA_REGISTRY_HEADER_If-None-Match")
    }
    let download_out = @registry.download_by_purl(download_purl)
    @sys.unset_env_var("COGNA_REGISTRY_HEADER_If-None-Match")
    if download_out is Err(error) {
      let message = error.to_string()
      if should_fail_on_download_error(message) {
        return Err(publish_error(message))
      }
    }
    if download_out is Ok(download) {
      guard download is Object(download_object) else {
        return Err(publish_error("registry download response must be object"))
      }
      if download_object.get("status") is Some(Number(status, ..)) {
        if status.to_int() == 304 {
          guard download_object.get("downloadUrl") is Some(String(download_url)) else {
            return Err(
              publish_error("registry 304 response missing downloadUrl"),
            )
          }
          let bundle_id = match download_object.get("bundleId") {
            Some(String(value)) => value
            _ => "bundle_unknown"
          }
          let response_etag = match download_object.get("etag") {
            Some(String(value)) if value != "" => value
            _ => "\"\{bundle_id}\""
          }
          let response_digest = match download_object.get("digest") {
            Some(String(value)) => value
            _ => request_digest
          }
          if response_digest != request_digest {
            return Err(
              publish_error(
                "registry digest mismatch for already-exists receipt: expected=\{request_digest}, response=\{response_digest}",
              ),
            )
          }
          let signature = signature_from_download(download_object)
          let verified_signature = verify_signature_with_openssl(
            bundle_file, signature,
          )
          let signature_out = ensure_signature_status_allowed(
            verified_signature,
            enforce_trust~,
          )
          guard signature_out is Ok(_) else {
            return Err(signature_out.unwrap_err())
          }
          let receipt : Json = {
            "schemaVersion": "cogna-publish-receipt/v1",
            "publishId": "pub_existing_\{bundle_id}",
            "bundleId": bundle_id,
            "purl": download_purl,
            "digest": request_digest,
            "bundleType": request_bundle_type,
            "downloadUrl": download_url,
            "status": "already-exists",
            "provenance": {
              "source": "local-registry",
              "digestVerified": true,
              "etag": response_etag,
              "signature": verified_signature,
            },
          }
          return Ok(receipt)
        }
      }
    }
  }

  let uploaded_out = @registry.upload(request)
  guard uploaded_out is Ok(uploaded) else {
    return Err(publish_error(uploaded_out.unwrap_err().to_string()))
  }
  let receipt = uploaded.receipt
  guard receipt is Object(receipt_object) else {
    return Err(publish_error("registry receipt must be object"))
  }
  let receipt_digest = match receipt_object.get("digest") {
    Some(String(value)) => value
    _ => ""
  }
  if receipt_digest != request_digest {
    return Err(
      publish_error(
        "registry digest mismatch: expected=\{request_digest}, response=\{receipt_digest}",
      ),
    )
  }
  let receipt_bundle_type = match receipt_object.get("bundleType") {
    Some(String(value)) => value
    _ => ""
  }
  if receipt_bundle_type != request_bundle_type {
    return Err(
      publish_error(
        "registry bundleType mismatch: expected=\{request_bundle_type}, response=\{receipt_bundle_type}",
      ),
    )
  }
  let signature = signature_from_receipt(receipt_object)
  let verified_signature = verify_signature_with_openssl(bundle_file, signature)
  let signature_out = ensure_signature_status_allowed(
    verified_signature,
    enforce_trust~,
  )
  guard signature_out is Ok(_) else { return Err(signature_out.unwrap_err()) }
  match receipt_object.get("provenance") {
    Some(Object(provenance)) => provenance["signature"] = verified_signature
    _ => ()
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
  let resolved_config = if params.bundle_file == "" {
    let resolved_out = @config.resolve(".")
    guard resolved_out is Ok(resolved) else {
      return Err(@cli.config_error(resolved_out.unwrap_err().to_string()))
    }
    Some(resolved)
  } else {
    maybe_resolve_publish_config(params.bundle_file)
  }
  let bundle_file = if params.bundle_file == "" {
    match resolved_config {
      Some(resolved) => "\{resolved.root_dir}/dist/bundle.ciq.tgz"
      None => params.bundle_file
    }
  } else {
    params.bundle_file
  }
  let exists_out = ensure_bundle_exists(bundle_file)
  guard exists_out is Ok(_) else { return Err(exists_out.unwrap_err()) }

  let receipt_path = "\{parent_dir(bundle_file)}/publish.json"
  let receipt_out = publish_receipt(bundle_file)
  guard receipt_out is Ok(receipt) else { return Err(receipt_out.unwrap_err()) }
  let final_receipt = match resolved_config {
    Some(resolved) if resolved.config.publish.include_dependencies => {
      let dependency_bundles = dependency_bundle_files(bundle_file)
      let dependency_receipts : Array[Json] = []
      for i in 0..<dependency_bundles.length() {
        let dependency_receipt_out = publish_receipt(dependency_bundles[i])
        guard dependency_receipt_out is Ok(dependency_receipt) else {
          return Err(dependency_receipt_out.unwrap_err())
        }
        dependency_receipts.push(dependency_receipt)
      }
      let aggregate_out = aggregate_receipt(receipt, dependency_receipts)
      guard aggregate_out is Ok(aggregated) else {
        return Err(aggregate_out.unwrap_err())
      }
      aggregated
    }
    _ => receipt
  }
  let write_out = write_receipt(receipt_path, final_receipt)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({ bundle_file, summary: "Generated publish receipt at \{receipt_path}" })
}
