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
fn is_hex_code(code : UInt16) -> Bool {
  (code >= 48 && code <= 57) ||
  (code >= 97 && code <= 102) ||
  (code >= 65 && code <= 70)
}

///|
fn is_sha256_digest(digest : String) -> Bool {
  if !digest.has_prefix("sha256:") {
    return false
  }
  let hex = digest[7:].to_string()
  if hex.length() != 64 {
    return false
  }
  for i in 0..<hex.length() {
    if !is_hex_code(hex[i]) {
      return false
    }
  }
  true
}

///|
pub fn ensure_sha256_digest(
  digest : String,
  context : String,
) -> Result[Unit, @cli.CliError] {
  if is_sha256_digest(digest) {
    Ok(())
  } else {
    Err(registry_error("invalid sha256 digest in \{context}: \{digest}"))
  }
}

///|
pub fn ensure_dir(path : String) -> Result[Unit, @cli.CliError] {
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
fn index_key(purl : String) -> String {
  purl
  .replace_all(old="/", new="_")
  .replace_all(old=":", new="_")
  .replace_all(old="@", new="_")
}

///|
fn purl_version(purl : String) -> String? {
  let mut at_index = -1
  for i in 0..<purl.length() {
    if purl[i] == '@' {
      at_index = i
    }
  }
  if at_index < 0 || at_index + 1 >= purl.length() {
    None
  } else {
    Some(purl[at_index + 1:].to_string())
  }
}

///|
fn lock_dir_path(path : String) -> String {
  "\{path}.lockdir"
}

///|
fn[T] with_lock(
  path : String,
  action : () -> Result[T, @cli.CliError],
) -> Result[T, @cli.CliError] {
  let lock_dir = lock_dir_path(path)
  @fs.create_dir(lock_dir) catch {
    err =>
      return Err(
        registry_error(
          "cannot acquire registry lock \{lock_dir}: \{err.to_string()}",
        ),
      )
  }
  let action_result = action()
  match action_result {
    Ok(value) => {
      @fs.remove_dir(lock_dir) catch {
        err =>
          return Err(
            registry_error(
              "cannot release registry lock \{lock_dir}: \{err.to_string()}",
            ),
          )
      }
      Ok(value)
    }
    Err(err) => {
      @fs.remove_dir(lock_dir) catch {
        _ => ()
      }
      Err(err)
    }
  }
}

///|
pub fn write_string_atomic(
  path : String,
  content : String,
) -> Result[Unit, @cli.CliError] {
  with_lock(path, () => {
    @fs.write_string_to_file(path, content) catch {
      err =>
        return Err(
          registry_error("cannot write file \{path}: \{err.to_string()}"),
        )
    }
    Ok(())
  })
}

///|
pub fn write_bytes_atomic(
  path : String,
  content : Bytes,
) -> Result[Unit, @cli.CliError] {
  with_lock(path, () => {
    @fs.write_bytes_to_file(path, content) catch {
      err =>
        return Err(
          registry_error("cannot write file \{path}: \{err.to_string()}"),
        )
    }
    Ok(())
  })
}

///|
pub fn write_etag(path : String, etag : String) -> Result[Unit, @cli.CliError] {
  let write_out = write_string_atomic(path, etag)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  Ok(())
}

///|
pub fn read_etag(path : String) -> String? {
  if !@fs.path_exists(path) {
    return None
  }
  let out = @fs.read_file_to_string(path) catch { _ => return None }
  let trimmed = out.trim().to_string()
  if trimmed == "" {
    None
  } else {
    Some(trimmed)
  }
}

///|
pub fn read_json_file(path : String) -> Result[Json, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(
        registry_error("cannot read json file \{path}: \{err.to_string()}"),
      )
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(registry_error("invalid json in file: \{path}"))
  }
  Ok(value)
}

///|
fn read_registry_index_object(
  purl : String,
) -> Result[Map[String, Json]?, @cli.CliError] {
  let index_path = "\{@registry_lib.local_store_index_dir()}/\{index_key(purl)}.json"
  if !@fs.path_exists(index_path) {
    return Ok(None)
  }
  let index_out = read_json_file(index_path)
  guard index_out is Ok(index_json) else { return Err(index_out.unwrap_err()) }
  guard index_json is Object(index_object) else {
    return Err(
      registry_error("registry index entry must be object: \{index_path}"),
    )
  }
  Ok(Some(index_object))
}

///|
fn find_registry_index_by_bundle_id(
  bundle_id : String,
) -> Result[Map[String, Json]?, @cli.CliError] {
  let index_dir = @registry_lib.local_store_index_dir()
  if !@fs.path_exists(index_dir) {
    return Ok(None)
  }
  let entries = @fs.read_dir(index_dir) catch {
    err =>
      return Err(
        registry_error(
          "cannot read registry index directory \{index_dir}: \{err.to_string()}",
        ),
      )
  }
  entries.sort()
  for i in 0..<entries.length() {
    let entry = entries[i]
    if !entry.has_suffix(".json") {
      continue
    }
    let entry_path = "\{index_dir}/\{entry}"
    let receipt_out = read_json_file(entry_path)
    guard receipt_out is Ok(receipt_json) else {
      return Err(receipt_out.unwrap_err())
    }
    guard receipt_json is Object(receipt_object) else {
      return Err(
        registry_error("registry index entry must be object: \{entry_path}"),
      )
    }
    match @registry_lib.string_field_optional(receipt_object, "bundleId") {
      Some(candidate) if candidate == bundle_id =>
        return Ok(Some(receipt_object))
      _ => ()
    }
  }
  Ok(None)
}

///|
pub fn bundle_path_for_bundle_id(
  bundle_id : String,
) -> Result[String, @cli.CliError] {
  let path = "\{@registry_lib.local_store_bundles_dir()}/\{bundle_id}.ciq.tgz"
  if @fs.path_exists(path) {
    Ok(path)
  } else {
    Err(registry_error("stored bundle not found: \{path}"))
  }
}

///|
pub fn registry_server_base_url(port : Int) -> String {
  "http://127.0.0.1:\{port}"
}

///|
fn join_url(base_url : String, path : String) -> String {
  if path == "" || path == "/" {
    return base_url
  }
  if base_url.has_suffix("/") && path.has_prefix("/") {
    base_url[:base_url.length() - 1].to_string() + path
  } else if !base_url.has_suffix("/") && !path.has_prefix("/") {
    "\{base_url}/\{path}"
  } else {
    base_url + path
  }
}

///|
fn server_bundle_download_url(port : Int, bundle_id : String) -> String {
  join_url(registry_server_base_url(port), @registry_lib.bundle_download_path(bundle_id))
}

///|
pub fn registry_versions_response(
  purl : String,
) -> Result[@registry_lib.RegistryApiResponse, @cli.CliError] {
  let versions : Array[Json] = []
  let index_out = read_registry_index_object(purl)
  guard index_out is Ok(index_object) else {
    return Err(index_out.unwrap_err())
  }
  match index_object {
    Some(index) => {
      let bundle_id = @registry_lib.string_field_optional(index, "bundleId")
      let digest = @registry_lib.string_field_optional(index, "digest")
      let bundle_type = @registry_lib.string_field_optional(index, "bundleType")
      let version = purl_version(purl)
      if bundle_id is Some(resolved_bundle_id) &&
        digest is Some(resolved_digest) &&
        bundle_type is Some(resolved_bundle_type) &&
        version is Some(resolved_version) {
        let tags : Array[Json] = [Json::string(resolved_version)]
        versions.push({
          "version": resolved_version,
          "bundleId": resolved_bundle_id,
          "digest": resolved_digest,
          "bundleType": resolved_bundle_type,
          "tags": Json::array(tags),
        })
      }
    }
    None => ()
  }
  let body : Json = {
    "schemaVersion": "codeiq-registry-package-versions/v1",
    "purl": purl,
    "versions": Json::array(versions),
  }
  Ok({ status: 200, headers: {}, body })
}

///|
pub fn registry_bundle_detail_response(
  bundle_id : String,
  port : Int,
) -> Result[@registry_lib.RegistryApiResponse, @cli.CliError] {
  let bundle_path_out = bundle_path_for_bundle_id(bundle_id)
  guard bundle_path_out is Ok(_) else {
    let body : Json = {
      "schemaVersion": "codeiq-registry-bundle-detail/v1",
      "bundleId": bundle_id,
      "status": 404,
      "message": "bundle detail not found in local registry",
    }
    return Ok({ status: 404, headers: {}, body })
  }
  let receipt_out = find_registry_index_by_bundle_id(bundle_id)
  guard receipt_out is Ok(receipt) else { return Err(receipt_out.unwrap_err()) }
  let etag = read_etag(
    "\{@registry_lib.local_store_bundles_dir()}/\{bundle_id}.etag",
  ).unwrap_or("\"\{bundle_id}\"")
  let body : Map[String, Json] = {
    "schemaVersion": Json::string("codeiq-registry-bundle-detail/v1"),
    "bundleId": Json::string(bundle_id),
    "status": Json::number(200.0, repr="200"),
    "downloadUrl": Json::string(server_bundle_download_url(port, bundle_id)),
    "etag": Json::string(etag),
  }
  match receipt {
    Some(index) => {
      match @registry_lib.string_field_optional(index, "purl") {
        Some(value) => body["purl"] = Json::string(value)
        None => ()
      }
      match @registry_lib.string_field_optional(index, "digest") {
        Some(value) => body["digest"] = Json::string(value)
        None => ()
      }
      match @registry_lib.string_field_optional(index, "bundleType") {
        Some(value) => body["bundleType"] = Json::string(value)
        None => ()
      }
    }
    None => ()
  }
  Ok({ status: 200, headers: { "ETag": etag }, body: Json::object(body) })
}

///|
pub fn registry_bundle_download_http(
  bundle_id : String,
) -> Result[@registry_runtime.HttpResponse, @cli.CliError] {
  let path_out = bundle_path_for_bundle_id(bundle_id)
  guard path_out is Ok(path) else { return Err(path_out.unwrap_err()) }
  let bytes = @fs.read_file_to_bytes(path) catch {
    err =>
      return Err(
        registry_error("cannot read stored bundle \{path}: \{err.to_string()}"),
      )
  }
  let headers : Map[String, String] = {
    "Content-Type": "application/octet-stream",
    "Content-Length": "\{bytes.length()}",
  }
  let etag = read_etag(
    "\{@registry_lib.local_store_bundles_dir()}/\{bundle_id}.etag",
  ).unwrap_or("\"\{bundle_id}\"")
  headers["ETag"] = etag
  Ok(@registry_runtime.binary_response(200, bytes, headers~))
}

///|
fn receipt_provenance(
  source : String,
  digest_verified : Bool,
  etag : String,
  signature : @registry_lib.SignatureStatus,
) -> Json {
  {
    "source": source,
    "digestVerified": digest_verified,
    "etag": etag,
    "signature": @registry_lib.signature_json(signature),
  }
}

///|
fn parse_upload(
  upload_request : Json,
) -> Result[
  (String, String, String, String, Int, @registry_lib.SignatureStatus),
  @cli.CliError,
] {
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
  let digest_valid_out = ensure_sha256_digest(digest, "upload request")
  guard digest_valid_out is Ok(_) else {
    return Err(digest_valid_out.unwrap_err())
  }
  let size_out = int_field(object, "size")
  guard size_out is Ok(size) else { return Err(size_out.unwrap_err()) }
  let signature = @registry_lib.signature_status_from_upload_request(object)
  Ok((bundle_file, bundle_type, purl, digest, size, signature))
}

///|
fn verify_signature_for_bundle_file(
  bundle_file : String,
  signature : @registry_lib.SignatureStatus,
) -> @registry_lib.SignatureStatus {
  @registry_lib.verify_signature_for_file(
    bundle_file, signature, "signature.verify",
  )
}

///|
pub fn upload_local(
  upload_request : Json,
) -> Result[@registry_lib.UploadResult, @cli.CliError] {
  let upload_valid = @schema.validate_codeiq_registry_upload_v1(upload_request)
  guard upload_valid is Ok(_) else {
    return Err(
      registry_error(
        "upload request does not satisfy codeiq-registry-upload/v1 schema: \{upload_valid.unwrap_err().to_string()}",
      ),
    )
  }

  let parsed_out = parse_upload(upload_request)
  guard parsed_out
    is Ok((bundle_file, bundle_type, purl, digest, size, request_signature)) else {
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

  let root = @registry_lib.local_store_root()
  let bundles_dir = @registry_lib.local_store_bundles_dir()
  let index_dir = @registry_lib.local_store_index_dir()
  let root_out = ensure_dir(".codeiq")
  guard root_out is Ok(_) else { return Err(root_out.unwrap_err()) }
  let cache_out = ensure_dir(".codeiq/cache")
  guard cache_out is Ok(_) else { return Err(cache_out.unwrap_err()) }
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
    let write_out = write_bytes_atomic(stored_bundle_path, bundle_bytes)
    guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  }

  let status = if already_exists { "already-exists" } else { "published" }
  let publish_id = if already_exists {
    "pub_existing_\{bundle_id}"
  } else {
    "pub_\{bundle_id}"
  }
  let etag = "\"\{bundle_id}\""
  let resolved_signature = verify_signature_for_bundle_file(
    stored_bundle_path, request_signature,
  )
  let receipt : Json = {
    "schemaVersion": "codeiq-publish-receipt/v1",
    "publishId": publish_id,
    "bundleId": bundle_id,
    "purl": purl,
    "digest": digest,
    "bundleType": bundle_type,
    "downloadUrl": "local://\{stored_bundle_path}",
    "status": status,
    "provenance": receipt_provenance(
      "local-registry", true, etag, resolved_signature,
    ),
  }

  let receipt_valid = @schema.validate_codeiq_publish_receipt_v1(receipt)
  guard receipt_valid is Ok(_) else {
    return Err(
      registry_error(
        "generated receipt does not satisfy codeiq-publish-receipt/v1 schema: \{receipt_valid.unwrap_err().to_string()}",
      ),
    )
  }

  let purl_key = index_key(purl)
  let index_entry_path = "\{index_dir}/\{purl_key}.json"
  let write_index_out = write_string_atomic(
    index_entry_path,
    receipt.stringify(indent=2),
  )
  guard write_index_out is Ok(_) else {
    return Err(write_index_out.unwrap_err())
  }

  let etag_path = "\{bundles_dir}/\{bundle_id}.etag"
  let etag_out = write_etag(etag_path, etag)
  guard etag_out is Ok(_) else { return Err(etag_out.unwrap_err()) }

  Ok({ receipt, stored_bundle_path, etag })
}

///|
fn read_header_env(key : String) -> String? {
  @sys.get_env_var("CODEIQ_REGISTRY_HEADER_\{key}")
}

///|
pub fn download_local_by_purl_with_if_none_match(
  purl : String,
  if_none_match : String?,
) -> Result[Json, @cli.CliError] {
  let index_dir = @registry_lib.local_store_index_dir()
  let bundles_dir = @registry_lib.local_store_bundles_dir()
  let key = index_key(purl)
  let index_path = "\{index_dir}/\{key}.json"
  if !@fs.path_exists(index_path) {
    return Err(registry_error("bundle index not found for purl: \{purl}"))
  }

  let index_text = @fs.read_file_to_string(index_path) catch {
    err =>
      return Err(
        registry_error(
          "cannot read bundle index \{index_path}: \{err.to_string()}",
        ),
      )
  }
  let parsed = try? @json.parse(index_text)
  guard parsed is Ok(Object(receipt)) else {
    return Err(registry_error("invalid registry index json: \{index_path}"))
  }
  let bundle_id_out = string_field(receipt, "bundleId")
  guard bundle_id_out is Ok(bundle_id) else {
    return Err(bundle_id_out.unwrap_err())
  }
  let digest_out = string_field(receipt, "digest")
  guard digest_out is Ok(digest) else { return Err(digest_out.unwrap_err()) }
  let signature = @registry_lib.signature_status_from_receipt(receipt)

  let stored_bundle_path = "\{bundles_dir}/\{bundle_id}.ciq.tgz"
  if !@fs.path_exists(stored_bundle_path) {
    return Err(registry_error("stored bundle not found: \{stored_bundle_path}"))
  }

  let etag_path = "\{bundles_dir}/\{bundle_id}.etag"
  let stored_etag = read_etag(etag_path).unwrap_or("\"\{bundle_id}\"")
  let not_modified = match if_none_match {
    Some(value) => value.trim().to_string() == stored_etag
    None => false
  }
  if not_modified {
    let response : Json = {
      "schemaVersion": "codeiq-registry-download/v1",
      "status": 304,
      "purl": purl,
      "bundleId": bundle_id,
      "digest": digest,
      "etag": stored_etag,
      "downloadUrl": "local://\{stored_bundle_path}",
      "notModified": true,
      "signature": @registry_lib.signature_json(signature),
    }
    let valid = @schema.validate_codeiq_registry_download_v1(response)
    guard valid is Ok(_) else {
      return Err(
        registry_error(
          "generated download response does not satisfy codeiq-registry-download/v1 schema: \{valid.unwrap_err().to_string()}",
        ),
      )
    }
    return Ok(response)
  }

  let bytes = @fs.read_file_to_bytes(stored_bundle_path) catch {
    err =>
      return Err(
        registry_error(
          "cannot read stored bundle \{stored_bundle_path}: \{err.to_string()}",
        ),
      )
  }

  let response : Json = {
    "schemaVersion": "codeiq-registry-download/v1",
    "status": 200,
    "purl": purl,
    "bundleId": bundle_id,
    "digest": digest,
    "etag": stored_etag,
    "downloadUrl": "local://\{stored_bundle_path}",
    "contentLength": bytes.length(),
    "notModified": false,
    "signature": @registry_lib.signature_json(signature),
  }
  let valid = @schema.validate_codeiq_registry_download_v1(response)
  guard valid is Ok(_) else {
    return Err(
      registry_error(
        "generated download response does not satisfy codeiq-registry-download/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(response)
}

///|
pub fn download_local_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  download_local_by_purl_with_if_none_match(
    purl,
    read_header_env("If-None-Match"),
  )
}

///|
pub fn api_resolve(
  purl : String,
  if_none_match : String?,
) -> Result[@registry_lib.RegistryApiResponse, @cli.CliError] {
  let out = download_local_by_purl_with_if_none_match(purl, if_none_match)
  guard out is Ok(body) else { return Err(out.unwrap_err()) }
  guard body is Object(body_object) else {
    return Err(registry_error("registry api resolve response must be object"))
  }
  let status = match body_object.get("status") {
    Some(Number(value, ..)) => value.to_int()
    _ => 200
  }
  let etag = match body_object.get("etag") {
    Some(String(value)) if value != "" => value
    _ => ""
  }
  let headers : Map[String, String] = {}
  if etag != "" {
    headers["ETag"] = etag
  }
  Ok({ status, headers, body })
}

///|
pub fn api_upload(
  upload_request : Json,
) -> Result[@registry_lib.RegistryApiResponse, @cli.CliError] {
  let upload_out = upload_local(upload_request)
  guard upload_out is Ok(uploaded) else { return Err(upload_out.unwrap_err()) }
  let status = if uploaded.receipt
    .stringify(indent=2)
    .contains("\"status\": \"already-exists\"") {
    200
  } else {
    201
  }
  let headers : Map[String, String] = { "ETag": uploaded.etag }
  Ok({ status, headers, body: uploaded.receipt })
}
