///|
fn registry_error(message : String) -> @cli.CliError {
  @cli.command_error("registry failed: \{message}")
}

///|
fn ascii_lower_char_client(char : Char) -> Char {
  if char >= 'A' && char <= 'Z' {
    Int::unsafe_to_char(char.to_int() + 32)
  } else {
    char
  }
}

///|
fn ascii_lower_client(text : String) -> String {
  let out = StringBuilder::new()
  for char in text {
    out.write_char(ascii_lower_char_client(char))
  }
  out.to_string()
}

///|
fn trimmed_env_var(name : String) -> String? {
  match @sys.get_env_var(name) {
    Some(value) => {
      let trimmed = value.trim().to_string()
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
fn env_bool(name : String) -> Bool {
  match trimmed_env_var(name) {
    Some(value) => {
      let normalized = ascii_lower_client(value)
      normalized == "1" ||
      normalized == "true" ||
      normalized == "yes" ||
      normalized == "on"
    }
    None => false
  }
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
fn insecure_remote_http_allowed() -> Bool {
  env_bool("COGNA_REGISTRY_ALLOW_INSECURE_HTTP")
}

///|
fn ensure_secure_remote_url(
  url : String,
  context : String,
) -> Result[Unit, @cli.CliError] {
  if url.has_prefix("http://") &&
    !local_registry_base_url(url) &&
    !insecure_remote_http_allowed() {
    Err(
      registry_error(
        "\{context} requires https or COGNA_REGISTRY_ALLOW_INSECURE_HTTP=true: \{url}",
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn unsupported_async_transport_envs() -> Array[String] {
  [
    "COGNA_REGISTRY_CURL_MAX_TIME", "COGNA_REGISTRY_CURL_RETRY", "COGNA_REGISTRY_CURL_CONNECT_TIMEOUT",
    "COGNA_REGISTRY_CURL_INSECURE_TLS", "COGNA_REGISTRY_TLS_CA_FILE", "COGNA_REGISTRY_TLS_CLIENT_CERT_FILE",
    "COGNA_REGISTRY_TLS_CLIENT_KEY_FILE",
  ]
}

///|
fn ensure_async_transport_envs_supported() -> Result[Unit, @cli.CliError] {
  let configured : Array[String] = []
  let names = unsupported_async_transport_envs()
  for i in 0..<names.length() {
    let name = names[i]
    match trimmed_env_var(name) {
      Some(_) => configured.push(name)
      None => ()
    }
  }
  if configured.length() == 0 {
    Ok(())
  } else {
    let configured_text = configured.join(", ")
    Err(
      registry_error(
        "async registry transport does not support env vars: \{configured_text}",
      ),
    )
  }
}

///|
fn header_name_from_env_key(key : String) -> String? {
  let prefix = "COGNA_REGISTRY_HEADER_"
  if !key.has_prefix(prefix) {
    return None
  }
  let suffix = key[prefix.length():].to_string()
  if suffix == "" || suffix == "If-None-Match" {
    None
  } else {
    Some(suffix.replace_all(old="_", new="-"))
  }
}

///|
fn collect_registry_headers() -> Map[String, String] {
  let headers : Map[String, String] = {}
  for key, value in @sys.get_env_vars() {
    match header_name_from_env_key(key) {
      Some(name) => {
        let trimmed = value.trim().to_string()
        if trimmed != "" {
          headers[name] = trimmed
        }
      }
      None => ()
    }
  }
  headers
}

///|
fn ensure_remote_transport_policy(
  base_url : String,
) -> Result[Unit, @cli.CliError] {
  let base_url_out = ensure_secure_remote_url(
    base_url, "remote registry endpoint",
  )
  guard base_url_out is Ok(_) else { return Err(base_url_out.unwrap_err()) }
  let env_out = ensure_async_transport_envs_supported()
  guard env_out is Ok(_) else { return Err(env_out.unwrap_err()) }
  Ok(())
}

///|
fn cache_root() -> String {
  local_store_root()
}

///|
fn cache_index_dir() -> String {
  "\{cache_root()}/index"
}

///|
fn cache_bundles_dir() -> String {
  "\{cache_root()}/bundles"
}

///|
fn http_tmp_dir() -> String {
  ".cogna/registry/http"
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
fn write_string_atomic(
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
fn write_bytes_atomic(
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
fn write_etag(path : String, etag : String) -> Result[Unit, @cli.CliError] {
  let write_out = write_string_atomic(path, etag)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  Ok(())
}

///|
fn ensure_remote_dirs() -> Result[Unit, @cli.CliError] {
  let out_root = ensure_dir(".cogna")
  guard out_root is Ok(_) else { return Err(out_root.unwrap_err()) }
  let out_cache = ensure_dir(".cogna/cache")
  guard out_cache is Ok(_) else { return Err(out_cache.unwrap_err()) }
  let out_registry_cache = ensure_dir(cache_root())
  guard out_registry_cache is Ok(_) else {
    return Err(out_registry_cache.unwrap_err())
  }
  let out_index = ensure_dir(cache_index_dir())
  guard out_index is Ok(_) else { return Err(out_index.unwrap_err()) }
  let out_bundles = ensure_dir(cache_bundles_dir())
  guard out_bundles is Ok(_) else { return Err(out_bundles.unwrap_err()) }
  let out_registry = ensure_dir(".cogna/registry")
  guard out_registry is Ok(_) else { return Err(out_registry.unwrap_err()) }
  let out_http = ensure_dir(http_tmp_dir())
  guard out_http is Ok(_) else { return Err(out_http.unwrap_err()) }
  Ok(())
}

///|
fn parse_json_text(
  text : String,
  context : String,
) -> Result[Json, @cli.CliError] {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(registry_error("invalid json in \{context}"))
  }
  Ok(value)
}

///|
fn cache_index_path_for_purl(purl : String) -> String {
  let key = purl
    .replace_all(old="/", new="_")
    .replace_all(old=":", new="_")
    .replace_all(old="@", new="_")
  "\{cache_index_dir()}/\{key}.json"
}

///|
fn maybe_read_cached_download(purl : String) -> Json? {
  let cache_path = cache_index_path_for_purl(purl)
  if !@fs.path_exists(cache_path) {
    return None
  }
  let text = @fs.read_file_to_string(cache_path) catch { _ => return None }
  let parsed = try? @json.parse(text)
  match parsed {
    Ok(value) => Some(value)
    Err(_) => None
  }
}

///|
fn write_cached_download(
  purl : String,
  response : Json,
) -> Result[Unit, @cli.CliError] {
  let path = cache_index_path_for_purl(purl)
  let write_out = write_string_atomic(path, response.stringify(indent=2))
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  Ok(())
}

///|
fn read_header_env(key : String) -> String? {
  @sys.get_env_var("COGNA_REGISTRY_HEADER_\{key}")
}

///|
fn resolved_if_none_match_header(purl : String) -> String? {
  match read_header_env("If-None-Match") {
    Some(value) if value != "" => Some(value)
    _ =>
      match maybe_read_cached_download(purl) {
        Some(Object(cached_object)) =>
          match cached_object.get("downloadUrl") {
            Some(String(download_url)) if download_url.has_prefix("local://") =>
              match cached_object.get("etag") {
                Some(String(value)) if value != "" => Some(value)
                _ => None
              }
            _ => None
          }
        _ => None
      }
  }
}

///|
fn response_string_field(
  response : Json,
  field : String,
) -> Result[String, @cli.CliError] {
  guard response is Object(object) else {
    return Err(registry_error("registry response must be object"))
  }
  match object.get(field) {
    Some(String(value)) if value != "" => Ok(value)
    _ => Err(registry_error("missing required string field \{field}"))
  }
}

///|
fn receipt_etag(receipt : Map[String, Json], fallback : String) -> String {
  match receipt.get("provenance") {
    Some(Object(provenance)) =>
      match provenance.get("etag") {
        Some(String(value)) if value != "" => value
        _ => fallback
      }
    _ => fallback
  }
}

///|
fn not_modified_from_cached(
  purl : String,
  cached : Json,
) -> Result[Json, @cli.CliError] {
  let bundle_id_out = response_string_field(cached, "bundleId")
  guard bundle_id_out is Ok(bundle_id) else {
    return Err(bundle_id_out.unwrap_err())
  }
  let digest_out = response_string_field(cached, "digest")
  guard digest_out is Ok(digest) else { return Err(digest_out.unwrap_err()) }
  let etag_out = response_string_field(cached, "etag")
  guard etag_out is Ok(etag) else { return Err(etag_out.unwrap_err()) }
  let download_url_out = response_string_field(cached, "downloadUrl")
  guard download_url_out is Ok(download_url) else {
    return Err(download_url_out.unwrap_err())
  }
  let signature = match cached {
    Object(cached_object) => signature_status_from_download(cached_object)
    _ => load_signature_status_from_env()
  }
  let response : Json = {
    "schemaVersion": "cogna-registry-download/v1",
    "status": 304,
    "purl": purl,
    "bundleId": bundle_id,
    "digest": digest,
    "etag": etag,
    "downloadUrl": download_url,
    "notModified": true,
    "signature": signature_json(signature),
  }
  Ok(response)
}

///|
fn ensure_sha256_digest(
  digest : String,
  context : String,
) -> Result[Unit, @cli.CliError] {
  if !digest.has_prefix("sha256:") {
    return Err(registry_error("invalid sha256 digest in \{context}: \{digest}"))
  }
  let hex = digest[7:].to_string()
  if hex.length() != 64 {
    return Err(registry_error("invalid sha256 digest in \{context}: \{digest}"))
  }
  for i in 0..<hex.length() {
    let code = hex[i]
    let valid = (code >= '0' && code <= '9') ||
      (code >= 'a' && code <= 'f') ||
      (code >= 'A' && code <= 'F')
    if !valid {
      return Err(
        registry_error("invalid sha256 digest in \{context}: \{digest}"),
      )
    }
  }
  Ok(())
}

///|
fn has_non_empty_string_field(value : Json, field : String) -> Bool {
  match value {
    Object(object) =>
      match object.get(field) {
        Some(String(text)) => text != ""
        _ => false
      }
    _ => false
  }
}

///|
fn is_registry_download_json(value : Json) -> Bool {
  if !has_non_empty_string_field(value, "bundleId") ||
    !has_non_empty_string_field(value, "digest") ||
    !has_non_empty_string_field(value, "downloadUrl") {
    return false
  }
  match value {
    Object(object) => {
      let has_status = match object.get("status") {
        Some(Number(_, ..)) => true
        _ => false
      }
      let has_content_length = match object.get("contentLength") {
        Some(Number(_, ..)) => true
        _ => false
      }
      has_non_empty_string_field(value, "etag") ||
      has_non_empty_string_field(value, "purl") ||
      has_status ||
      has_content_length
    }
    _ => false
  }
}

///|
fn is_publish_receipt_json(value : Json) -> Bool {
  has_non_empty_string_field(value, "publishId") &&
  has_non_empty_string_field(value, "bundleId") &&
  has_non_empty_string_field(value, "purl") &&
  has_non_empty_string_field(value, "digest") &&
  has_non_empty_string_field(value, "bundleType") &&
  has_non_empty_string_field(value, "downloadUrl")
}

///|
fn maybe_transform_receipt_to_download(
  purl : String,
  body_json : Json,
) -> Result[Json, @cli.CliError] {
  if is_registry_download_json(body_json) {
    return Ok(body_json)
  }
  guard body_json is Object(receipt) else {
    return Err(registry_error("publish receipt response must be object"))
  }
  guard receipt.get("bundleId") is Some(String(bundle_id)) && bundle_id != "" else {
    return Err(registry_error("missing required string field bundleId"))
  }
  guard receipt.get("digest") is Some(String(digest)) && digest != "" else {
    return Err(registry_error("missing required string field digest"))
  }
  let digest_valid_out = ensure_sha256_digest(digest, "remote receipt response")
  guard digest_valid_out is Ok(_) else {
    return Err(digest_valid_out.unwrap_err())
  }
  guard receipt.get("downloadUrl") is Some(String(download_url)) &&
    download_url != "" else {
    return Err(registry_error("missing required string field downloadUrl"))
  }
  let receipt_status = match receipt.get("status") {
    Some(String("already-exists")) => 304
    _ => 200
  }
  let resolved_etag = receipt_etag(receipt, "\"\{bundle_id}\"")
  let signature = signature_status_from_receipt(receipt)
  let response : Json = {
    "schemaVersion": "cogna-registry-download/v1",
    "status": receipt_status,
    "purl": purl,
    "bundleId": bundle_id,
    "digest": digest,
    "etag": resolved_etag,
    "downloadUrl": download_url,
    "notModified": receipt_status == 304,
    "signature": signature_json(signature),
  }
  Ok(response)
}

///|
fn receipt_from_download_response(
  upload_request : Json,
  body_json : Json,
) -> Result[Json, @cli.CliError] {
  guard upload_request is Object(request_object) else {
    return Err(registry_error("upload request must be a JSON object"))
  }
  guard request_object.get("bundleType") is Some(String(expected_bundle_type)) else {
    return Err(registry_error("missing required string field bundleType"))
  }
  guard request_object.get("purl") is Some(String(expected_purl)) else {
    return Err(registry_error("missing required string field purl"))
  }
  guard request_object.get("digest") is Some(String(expected_digest)) else {
    return Err(registry_error("missing required string field digest"))
  }

  if is_publish_receipt_json(body_json) {
    guard body_json is Object(receipt_object) else {
      return Err(registry_error("publish receipt response must be object"))
    }
    guard receipt_object.get("purl") is Some(String(receipt_purl)) else {
      return Err(registry_error("missing required string field purl"))
    }
    if receipt_purl != expected_purl {
      return Err(
        registry_error(
          "remote receipt purl mismatch: expected=\{expected_purl}, response=\{receipt_purl}",
        ),
      )
    }
    guard receipt_object.get("digest") is Some(String(receipt_digest)) else {
      return Err(registry_error("missing required string field digest"))
    }
    let digest_valid_out = ensure_sha256_digest(
      receipt_digest, "remote receipt response",
    )
    guard digest_valid_out is Ok(_) else {
      return Err(digest_valid_out.unwrap_err())
    }
    if receipt_digest != expected_digest {
      return Err(
        registry_error(
          "remote receipt digest mismatch: expected=\{expected_digest}, response=\{receipt_digest}",
        ),
      )
    }
    guard receipt_object.get("bundleType") is Some(String(receipt_bundle_type)) else {
      return Err(registry_error("missing required string field bundleType"))
    }
    if receipt_bundle_type != expected_bundle_type {
      return Err(
        registry_error(
          "remote receipt bundleType mismatch: expected=\{expected_bundle_type}, response=\{receipt_bundle_type}",
        ),
      )
    }
    let signature = signature_status_from_receipt(receipt_object)
    match receipt_object.get("provenance") {
      Some(Object(provenance)) =>
        provenance["signature"] = signature_json(signature)
      _ => ()
    }
    return Ok(body_json)
  }
  guard body_json is Object(download_object) else {
    return Err(registry_error("registry download response must be object"))
  }
  guard download_object.get("bundleId") is Some(String(bundle_id)) else {
    return Err(registry_error("missing required string field bundleId"))
  }
  guard download_object.get("downloadUrl") is Some(String(download_url)) else {
    return Err(registry_error("missing required string field downloadUrl"))
  }
  let resolved_etag = match download_object.get("etag") {
    Some(String(value)) if value != "" => value
    _ => "\"\{bundle_id}\""
  }
  let status = match download_object.get("status") {
    Some(Number(value, ..)) if value.to_int() == 304 => "already-exists"
    _ => "published"
  }
  let signature = signature_status_from_download(download_object)
  let publish_id = if status == "already-exists" {
    "pub_existing_\{bundle_id}"
  } else {
    "pub_\{bundle_id}"
  }
  let receipt : Json = {
    "schemaVersion": "cogna-publish-receipt/v1",
    "publishId": publish_id,
    "bundleId": bundle_id,
    "purl": expected_purl,
    "digest": expected_digest,
    "bundleType": expected_bundle_type,
    "downloadUrl": download_url,
    "status": status,
    "provenance": {
      "source": "remote-registry",
      "digestVerified": true,
      "etag": resolved_etag,
      "signature": signature_json(signature),
    },
  }
  Ok(receipt)
}

///|
fn cache_receipt_as_download(
  receipt : Json,
  etag : String,
) -> Result[Unit, @cli.CliError] {
  guard receipt is Object(receipt_object) else {
    return Err(registry_error("publish receipt must be object"))
  }
  guard receipt_object.get("purl") is Some(String(purl)) else {
    return Err(registry_error("missing required string field purl"))
  }
  guard receipt_object.get("bundleId") is Some(String(bundle_id)) else {
    return Err(registry_error("missing required string field bundleId"))
  }
  guard receipt_object.get("digest") is Some(String(digest)) else {
    return Err(registry_error("missing required string field digest"))
  }
  guard receipt_object.get("downloadUrl") is Some(String(download_url)) else {
    return Err(registry_error("missing required string field downloadUrl"))
  }
  let signature = signature_status_from_receipt(receipt_object)

  let download : Json = {
    "schemaVersion": "cogna-registry-download/v1",
    "status": 200,
    "purl": purl,
    "bundleId": bundle_id,
    "digest": digest,
    "etag": etag,
    "downloadUrl": download_url,
    "notModified": false,
    "signature": signature_json(signature),
  }
  let write_out = write_cached_download(purl, download)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  let etag_out = write_etag("\{cache_bundles_dir()}/\{bundle_id}.etag", etag)
  guard etag_out is Ok(_) else { return Err(etag_out.unwrap_err()) }
  Ok(())
}

///|
fn request_headers(if_none_match? : String? = None) -> Map[String, String] {
  let headers = collect_registry_headers()
  headers["Accept"] = "application/json"
  match if_none_match {
    Some(value) if value != "" => headers["If-None-Match"] = value
    _ => ()
  }
  headers
}

///|
fn json_request(
  http_method : String,
  url : String,
  headers : Map[String, String],
  body : HttpBody,
) -> Result[HttpResult, @cli.CliError] {
  let request_out = http_request(http_method, url, headers, body)
  guard request_out is Ok(result) else {
    return Err(registry_error(request_out.unwrap_err()))
  }
  Ok(result)
}

///|
fn effective_download_length(
  declared_length : Int?,
  headers : Map[String, String],
) -> Int? {
  match declared_length {
    Some(value) => Some(value)
    None =>
      match header_value(headers, "Content-Length") {
        Some(value) =>
          match parse_content_length(value) {
            Some(length) if length >= 0 => Some(length)
            _ => None
          }
        None => None
      }
  }
}

///|
fn parse_content_length(text : String) -> Int? {
  let trimmed = text.trim().to_string()
  if trimmed == "" {
    return None
  }
  let mut value = 0
  for i in 0..<trimmed.length() {
    let code = trimmed[i]
    if code < '0' || code > '9' {
      return None
    }
    value = value * 10 + (code.to_int() - '0'.to_int())
  }
  Some(value)
}

///|
fn maybe_cache_bundle_download(
  purl : String,
  download : Json,
) -> Result[Json, @cli.CliError] {
  guard download is Object(download_object) else {
    return Err(registry_error("registry download response must be object"))
  }
  guard download_object.get("purl") is Some(String(download_purl)) else {
    return Err(registry_error("missing required string field purl"))
  }
  if download_purl != purl {
    return Err(
      registry_error(
        "remote download purl mismatch: expected=\{purl}, response=\{download_purl}",
      ),
    )
  }
  guard download_object.get("bundleId") is Some(String(bundle_id)) else {
    return Err(registry_error("missing required string field bundleId"))
  }
  guard download_object.get("digest") is Some(String(expected_digest)) else {
    return Err(registry_error("missing required string field digest"))
  }
  let digest_valid_out = ensure_sha256_digest(
    expected_digest, "remote download response",
  )
  guard digest_valid_out is Ok(_) else {
    return Err(digest_valid_out.unwrap_err())
  }
  guard download_object.get("etag") is Some(String(etag)) else {
    return Err(registry_error("missing required string field etag"))
  }
  guard download_object.get("downloadUrl") is Some(String(download_url)) else {
    return Err(registry_error("missing required string field downloadUrl"))
  }
  let status = match download_object.get("status") {
    Some(Number(value, ..)) => value.to_int()
    _ => 200
  }
  let signature = signature_status_from_download(download_object)

  if status == 304 {
    download_object["signature"] = signature_json(signature)
    return Ok(download)
  }

  let declared_length = match download_object.get("contentLength") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
  let mut effective_etag = etag
  let cached_bundle_path = "\{cache_bundles_dir()}/\{bundle_id}.ciq.tgz"
  let bundle_bytes_out = if download_url.has_prefix("http://") ||
    download_url.has_prefix("https://") {
    let secure_out = ensure_secure_remote_url(
      download_url, "remote bundle download url",
    )
    guard secure_out is Ok(_) else { return Err(secure_out.unwrap_err()) }
    let headers = collect_registry_headers()
    headers["Accept"] = "application/octet-stream"
    let request_out = json_request(
      "GET",
      download_url,
      headers,
      HttpBody::Empty,
    )
    guard request_out is Ok(result) else {
      return Err(request_out.unwrap_err())
    }
    if result.status != 200 {
      let text = text_body(result).unwrap_or("")
      return Err(
        registry_error(
          "remote bundle download failed with http status \{result.status} for \{download_url}: \{text.trim().to_string()}",
        ),
      )
    }
    match header_value(result.headers, "ETag") {
      Some(value) if value != "" => effective_etag = value
      _ => ()
    }
    match effective_download_length(declared_length, result.headers) {
      Some(length) =>
        download_object["contentLength"] = Json::number(
          length.to_double(),
          repr="\{length}",
        )
      None => ()
    }
    result.body
  } else if download_url.has_prefix("local://") {
    let local_path = download_url[8:].to_string()
    let local_bytes = @fs.read_file_to_bytes(local_path) catch {
      err =>
        return Err(
          registry_error(
            "cannot read local remote bundle \{local_path}: \{err.to_string()}",
          ),
        )
    }
    local_bytes
  } else {
    return Err(
      registry_error(
        "unsupported download url scheme in remote response: \{download_url}",
      ),
    )
  }
  let computed_digest = "sha256:\{@sha256.sha256_hexdigest(bundle_bytes_out)}"
  if computed_digest != expected_digest {
    return Err(
      registry_error(
        "download digest mismatch: expected=\{expected_digest}, computed=\{computed_digest}",
      ),
    )
  }
  let expected_length = match download_object.get("contentLength") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
  match expected_length {
    Some(expected_len) =>
      if bundle_bytes_out.length() != expected_len {
        return Err(
          registry_error(
            "download size mismatch: expected=\{expected_len}, computed=\{bundle_bytes_out.length()}",
          ),
        )
      }
    None => ()
  }
  let write_bundle_out = write_bytes_atomic(
    cached_bundle_path, bundle_bytes_out,
  )
  guard write_bundle_out is Ok(_) else {
    return Err(write_bundle_out.unwrap_err())
  }
  let resolved_signature = verify_signature_for_file(
    cached_bundle_path, signature, "signature.verify",
  )
  download_object["downloadUrl"] = Json::string("local://\{cached_bundle_path}")
  download_object["etag"] = Json::string(effective_etag)
  download_object["contentLength"] = Json::number(
    bundle_bytes_out.length().to_double(),
    repr="\{bundle_bytes_out.length()}",
  )
  download_object["status"] = Json::number(200.0, repr="200")
  download_object["notModified"] = Json::boolean(false)
  download_object["signature"] = signature_json(resolved_signature)

  let etag_out = write_etag(
    "\{cache_bundles_dir()}/\{bundle_id}.etag",
    effective_etag,
  )
  guard etag_out is Ok(_) else { return Err(etag_out.unwrap_err()) }
  let cache_out = write_cached_download(purl, download)
  guard cache_out is Ok(_) else { return Err(cache_out.unwrap_err()) }
  Ok(download)
}

///|
pub fn upload_remote(
  upload_request : Json,
) -> Result[UploadResult, @cli.CliError] {
  let ensure_out = ensure_remote_dirs()
  guard ensure_out is Ok(_) else { return Err(ensure_out.unwrap_err()) }

  let base_url_out = registry_base_url()
  guard base_url_out is Some(base_url) else {
    return Err(registry_error("remote registry base url is not configured"))
  }
  let normalized_base_url = normalize_base_url(base_url)
  let transport_out = ensure_remote_transport_policy(normalized_base_url)
  guard transport_out is Ok(_) else { return Err(transport_out.unwrap_err()) }

  let response_json_out = match
    @sys.get_env_var("COGNA_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON") {
    Some(raw) =>
      parse_json_text(raw, "COGNA_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
    None => {
      let endpoint = join_url(normalized_base_url, upload_path())
      let headers = request_headers()
      headers["Content-Type"] = "application/json"
      let request_out = json_request(
        "POST",
        endpoint,
        headers,
        HttpBody::Json(upload_request),
      )
      guard request_out is Ok(result) else {
        return Err(request_out.unwrap_err())
      }
      if result.status != 200 && result.status != 201 {
        let message = text_body(result).unwrap_or("")
        return Err(
          registry_error(
            "remote registry upload failed with http status \{result.status}: \{message.trim().to_string()}",
          ),
        )
      }
      let json_out = json_body(result)
      guard json_out is Ok(value) else {
        return Err(registry_error(json_out.unwrap_err()))
      }
      Ok(value)
    }
  }
  guard response_json_out is Ok(response_json) else {
    return Err(response_json_out.unwrap_err())
  }

  let receipt_out = receipt_from_download_response(
    upload_request, response_json,
  )
  guard receipt_out is Ok(receipt) else { return Err(receipt_out.unwrap_err()) }
  guard receipt is Object(receipt_object) else {
    return Err(registry_error("remote publish receipt must be object"))
  }
  guard receipt_object.get("bundleId") is Some(String(bundle_id)) else {
    return Err(registry_error("missing required string field bundleId"))
  }
  guard receipt_object.get("downloadUrl") is Some(String(download_url)) else {
    return Err(registry_error("missing required string field downloadUrl"))
  }
  let mut etag = if response_json is Object(remote_object) {
    match remote_object.get("etag") {
      Some(String(value)) if value != "" => value
      _ => "\"\{bundle_id}\""
    }
  } else {
    "\"\{bundle_id}\""
  }
  if etag == "\"\{bundle_id}\"" {
    etag = receipt_etag(receipt_object, etag)
  }

  let cache_out = cache_receipt_as_download(receipt, etag)
  guard cache_out is Ok(_) else { return Err(cache_out.unwrap_err()) }

  Ok({ receipt, stored_bundle_path: download_url, etag })
}

///|
pub fn download_remote_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  let ensure_out = ensure_remote_dirs()
  guard ensure_out is Ok(_) else { return Err(ensure_out.unwrap_err()) }

  let base_url_out = registry_base_url()
  guard base_url_out is Some(base_url) else {
    return Err(registry_error("remote registry base url is not configured"))
  }
  let normalized_base_url = normalize_base_url(base_url)
  let transport_out = ensure_remote_transport_policy(normalized_base_url)
  guard transport_out is Ok(_) else { return Err(transport_out.unwrap_err()) }

  match @sys.get_env_var("COGNA_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON") {
    Some(raw) => {
      let parsed_out = parse_json_text(
        raw, "COGNA_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
      )
      guard parsed_out is Ok(parsed) else {
        return Err(parsed_out.unwrap_err())
      }
      let transformed_out = maybe_transform_receipt_to_download(purl, parsed)
      guard transformed_out is Ok(download) else {
        return Err(transformed_out.unwrap_err())
      }
      let cached_out = maybe_cache_bundle_download(purl, download)
      guard cached_out is Ok(cached) else {
        return Err(cached_out.unwrap_err())
      }
      Ok(cached)
    }
    None => {
      let endpoint = join_url(normalized_base_url, resolve_path(purl))
      let request_out = json_request(
        "GET",
        endpoint,
        request_headers(if_none_match=resolved_if_none_match_header(purl)),
        HttpBody::Empty,
      )
      guard request_out is Ok(result) else {
        return Err(request_out.unwrap_err())
      }
      if result.status == 304 {
        let cached = maybe_read_cached_download(purl)
        guard cached is Some(cached_response) else {
          return Err(
            registry_error(
              "remote registry returned 304 but no cached download entry exists for purl: \{purl}",
            ),
          )
        }
        let not_modified_out = not_modified_from_cached(purl, cached_response)
        guard not_modified_out is Ok(not_modified) else {
          return Err(not_modified_out.unwrap_err())
        }
        Ok(not_modified)
      } else {
        if result.status != 200 {
          let message = text_body(result).unwrap_or("")
          return Err(
            registry_error(
              "remote registry download failed with http status \{result.status}: \{message.trim().to_string()}",
            ),
          )
        }
        let parsed_out = json_body(result)
        guard parsed_out is Ok(parsed) else {
          return Err(registry_error(parsed_out.unwrap_err()))
        }
        let transformed_out = maybe_transform_receipt_to_download(purl, parsed)
        guard transformed_out is Ok(download) else {
          return Err(transformed_out.unwrap_err())
        }
        let cached_out = maybe_cache_bundle_download(purl, download)
        guard cached_out is Ok(cached) else {
          return Err(cached_out.unwrap_err())
        }
        Ok(cached)
      }
    }
  }
}
