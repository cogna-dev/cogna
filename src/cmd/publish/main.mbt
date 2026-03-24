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
fn should_fail_on_download_error(message : String) -> Bool {
  message.contains("invalid sha256 digest") ||
  message.contains("digest mismatch")
}

///|
fn shell_escape(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn parse_signature_status(status : String) -> String {
  match status {
    "verified" => "verified"
    "untrusted" => "untrusted"
    _ => "unsigned"
  }
}

///|
fn signature_status_with_status(signature : Json, status : String) -> Json {
  guard signature is Object(signature_object) else {
    return { "status": status, "algorithm": "sha256" }
  }
  signature_object["status"] = Json::string(status)
  Json::object(signature_object)
}

///|
fn signature_from_env() -> Json {
  let status = match @sys.get_env_var("CODEIQ_SIGNATURE_STATUS") {
    Some(value) => parse_signature_status(value.trim().to_string())
    None => "unsigned"
  }
  let value = match @sys.get_env_var("CODEIQ_SIGNATURE_VALUE") {
    Some(raw) => {
      let trimmed = raw.trim().to_string()
      if trimmed == "" {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
  let signature : Map[String, Json] = {
    "status": Json::string(status),
    "algorithm": Json::string("sha256"),
  }
  match @sys.get_env_var("CODEIQ_SIGNATURE_KEY_ID") {
    Some(value) if value.trim().to_string() != "" =>
      signature["keyId"] = Json::string(value.trim().to_string())
    _ => ()
  }
  match value {
    Some(sig) => signature["value"] = Json::string(sig)
    None => ()
  }
  Json::object(signature)
}

///|
fn signature_from_download(download : Map[String, Json]) -> Json {
  match download.get("signature") {
    Some(Object(signature_object)) => Json::object(signature_object)
    _ => signature_from_env()
  }
}

///|
fn signature_from_receipt(receipt : Map[String, Json]) -> Json {
  match receipt.get("provenance") {
    Some(Object(provenance)) =>
      match provenance.get("signature") {
        Some(Object(signature_object)) => Json::object(signature_object)
        _ => signature_from_env()
      }
    _ => signature_from_env()
  }
}

///|
fn ensure_signature_status_allowed(
  signature : Json,
) -> Result[Unit, @cli.CliError] {
  guard signature is Object(signature_object) else {
    return Err(publish_error("invalid signature metadata shape"))
  }
  let status = match signature_object.get("status") {
    Some(String(value)) => parse_signature_status(value)
    _ => "unsigned"
  }
  if status == "untrusted" {
    Err(publish_error("registry signature status is untrusted"))
  } else {
    Ok(())
  }
}

///|
fn signature_value(signature : Json) -> String? {
  guard signature is Object(signature_object) else { return None }
  match signature_object.get("value") {
    Some(String(value)) if value.trim().to_string() != "" => Some(value)
    _ => None
  }
}

///|
fn signature_public_key_file() -> String? {
  match @sys.get_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE") {
    Some(raw) => {
      let trimmed = raw.trim().to_string()
      if trimmed == "" {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
fn verify_signature_with_openssl(
  bundle_file : String,
  signature : Json,
) -> Json {
  guard signature is Object(_) else { return signature }
  let status = match signature {
    Object(signature_object) =>
      match signature_object.get("status") {
        Some(String(value)) => parse_signature_status(value)
        _ => "unsigned"
      }
    _ => "unsigned"
  }
  if status != "verified" {
    return signature
  }
  let public_key = match signature_public_key_file() {
    Some(path) if @fs.path_exists(path) => path
    _ => return signature
  }
  let value = match signature_value(signature) {
    Some(sig) => sig
    None => return signature_status_with_status(signature, "untrusted")
  }
  if !@fs.path_exists(bundle_file) {
    return signature_status_with_status(signature, "untrusted")
  }
  @fs.create_dir(".codeiq") catch {
    _ => return signature_status_with_status(signature, "untrusted")
  }
  @fs.create_dir(".codeiq/registry") catch {
    _ => return signature_status_with_status(signature, "untrusted")
  }
  @fs.create_dir(".codeiq/registry/http") catch {
    _ => return signature_status_with_status(signature, "untrusted")
  }
  let b64_path = ".codeiq/registry/http/publish.signature.verify.b64"
  let bin_path = ".codeiq/registry/http/publish.signature.verify.bin"
  @fs.write_string_to_file(b64_path, value) catch {
    _ => return signature_status_with_status(signature, "untrusted")
  }
  let decode = "openssl base64 -d -A -in \{shell_escape(b64_path)} -out \{shell_escape(bin_path)}"
  let verify = "openssl dgst -sha256 -verify \{shell_escape(public_key)} -signature \{shell_escape(bin_path)} \{shell_escape(bundle_file)}"
  let (exit_code, _, _) = @shell.run_command_capture("\{decode} && \{verify}")
  if exit_code == 0 {
    signature
  } else {
    signature_status_with_status(signature, "untrusted")
  }
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
  let signature = signature_from_env()
  let request : Json = {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_file,
    "bundleType": detect_bundle_type(bundle_file),
    "purl": detect_purl(bundle_file),
    "digest": digest,
    "size": bytes.length(),
    "signature": signature,
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
  let if_none_match = @sys.get_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH")
  if download_purl != "" {
    match if_none_match {
      Some(value) if value != "" =>
        @sys.set_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match", value)
      _ => @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
    }
    let download_out = @registry.download_by_purl(download_purl)
    @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
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
          )
          guard signature_out is Ok(_) else {
            return Err(signature_out.unwrap_err())
          }
          let receipt : Json = {
            "schemaVersion": "codeiq-publish-receipt/v1",
            "publishId": "pub_existing_\{bundle_id}",
            "bundleId": bundle_id,
            "purl": download_purl,
            "digest": request_digest,
            "bundleType": request_bundle_type,
            "downloadUrl": download_url,
            "status": "already-exists",
            "provenance": {
              "source": "publish-cache",
              "digestVerified": true,
              "etag": response_etag,
              "signature": verified_signature,
            },
          }
          let valid = @schema.validate_codeiq_publish_receipt_v1(receipt)
          guard valid is Ok(_) else {
            return Err(
              publish_error(
                "registry response does not satisfy codeiq-publish-receipt/v1 schema: \{valid.unwrap_err().to_string()}",
              ),
            )
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
  let signature_out = ensure_signature_status_allowed(verified_signature)
  guard signature_out is Ok(_) else { return Err(signature_out.unwrap_err()) }
  match receipt_object.get("provenance") {
    Some(Object(provenance)) => provenance["signature"] = verified_signature
    _ => ()
  }
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
