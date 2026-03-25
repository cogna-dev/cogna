///|
pub(all) struct RegistryUploadParams {
  upload_request_file : String
} derive(Show, Eq)

///|
pub(all) struct RegistryDownloadParams {
  purl : String
} derive(Show, Eq)

///|
pub(all) struct RegistryDownloadBundleParams {
  purl : String
  output_dir : String
} derive(Show, Eq)

///|
pub(all) struct RegistryUploadCliResult {
  upload_request_file : String
  receipt : Json
  summary : String
} derive(Show, Eq)

///|
pub(all) struct RegistryDownloadCliResult {
  purl : String
  response : Json
  summary : String
} derive(Show, Eq)

///|
pub(all) struct RegistryDownloadBundleCliResult {
  purl : String
  bundle_file : String
  output_dir : String
  summary : String
} derive(Show, Eq)

///|
pub(all) struct RegistryApiResponse {
  status : Int
  headers : Map[String, String]
  body : Json
} derive(Show, Eq)

///|
pub impl @cli.Display for RegistryUploadCliResult with display(
  self : RegistryUploadCliResult,
) -> String {
  self.summary
}

///|
pub impl @cli.Display for RegistryDownloadCliResult with display(
  self : RegistryDownloadCliResult,
) -> String {
  self.summary
}

///|
pub impl @cli.Display for RegistryDownloadBundleCliResult with display(
  self : RegistryDownloadBundleCliResult,
) -> String {
  self.summary
}

///|
pub(all) struct UploadResult {
  receipt : Json
  stored_bundle_path : String
  etag : String
} derive(Show, Eq)

///|
pub(all) struct SignatureStatus {
  status : String
  algorithm : String
  key_id : String?
  value : String?
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
fn index_key(purl : String) -> String {
  purl
  .replace_all(old="/", new="_")
  .replace_all(old=":", new="_")
  .replace_all(old="@", new="_")
}

///|
fn read_header_env(key : String) -> String? {
  @sys.get_env_var("CODEIQ_REGISTRY_HEADER_\{key}")
}

///|
fn shell_escape(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn signature_status_with_status(
  signature : SignatureStatus,
  status : String,
) -> SignatureStatus {
  {
    status,
    algorithm: signature.algorithm,
    key_id: signature.key_id,
    value: signature.value,
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
fn verify_signature_for_bundle_file(
  bundle_file : String,
  signature : SignatureStatus,
) -> SignatureStatus {
  if signature.status != "verified" {
    return signature
  }
  let public_key = match signature_public_key_file() {
    Some(path) if @fs.path_exists(path) => path
    _ => return signature
  }
  let value = match signature.value {
    Some(raw) if raw.trim().to_string() != "" => raw
    _ => return signature_status_with_status(signature, "untrusted")
  }
  if !@fs.path_exists(bundle_file) {
    return signature_status_with_status(signature, "untrusted")
  }
  let out_root = ensure_dir(".codeiq")
  guard out_root is Ok(_) else {
    return signature_status_with_status(signature, "untrusted")
  }
  let out_registry = ensure_dir(".codeiq/registry")
  guard out_registry is Ok(_) else {
    return signature_status_with_status(signature, "untrusted")
  }
  let out_http = ensure_dir(http_tmp_dir())
  guard out_http is Ok(_) else {
    return signature_status_with_status(signature, "untrusted")
  }
  let b64_path = "\{http_tmp_dir()}/signature.verify.b64"
  let bin_path = "\{http_tmp_dir()}/signature.verify.bin"
  @fs.write_string_to_file(b64_path, value) catch {
    _ => return signature_status_with_status(signature, "untrusted")
  }
  let decode = "openssl base64 -d -A -in \{shell_escape(b64_path)} -out \{shell_escape(bin_path)}"
  let verify = "openssl dgst -sha256 -verify \{shell_escape(public_key)} -signature \{shell_escape(bin_path)} \{shell_escape(bundle_file)}"
  let command = "\{decode} && \{verify}"
  let (exit_code, _, _) = @shell.run_command_capture(command)
  if exit_code == 0 {
    signature
  } else {
    signature_status_with_status(signature, "untrusted")
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
fn registry_base_url() -> String? {
  match @sys.get_env_var("CODEIQ_REGISTRY_BASE_URL") {
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
fn normalize_base_url(url : String) -> String {
  if url.has_suffix("/") {
    url[:url.length() - 1].to_string()
  } else {
    url
  }
}

///|
fn local_registry_base_url(url : String) -> Bool {
  let normalized = normalize_base_url(url)
  normalized == "inproc://registry" ||
  normalized.has_prefix("http://localhost") ||
  normalized.has_prefix("https://localhost") ||
  normalized.has_prefix("http://127.0.0.1") ||
  normalized.has_prefix("https://127.0.0.1") ||
  normalized.has_prefix("http://[::1]") ||
  normalized.has_prefix("https://[::1]")
}

///|
fn remote_registry_enabled() -> Bool {
  registry_base_url() is Some(_)
}

///|
fn inproc_registry_enabled(base_url : String) -> Bool {
  base_url == "inproc://registry"
}

///|
fn cache_root() -> String {
  ".codeiq/cache/registry"
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
  ".codeiq/registry/http"
}

///|
fn ensure_remote_dirs() -> Result[Unit, @cli.CliError] {
  let out_root = ensure_dir(".codeiq")
  guard out_root is Ok(_) else { return Err(out_root.unwrap_err()) }
  let out_cache = ensure_dir(".codeiq/cache")
  guard out_cache is Ok(_) else { return Err(out_cache.unwrap_err()) }
  let out_registry_cache = ensure_dir(cache_root())
  guard out_registry_cache is Ok(_) else {
    return Err(out_registry_cache.unwrap_err())
  }
  let out_index = ensure_dir(cache_index_dir())
  guard out_index is Ok(_) else { return Err(out_index.unwrap_err()) }
  let out_bundles = ensure_dir(cache_bundles_dir())
  guard out_bundles is Ok(_) else { return Err(out_bundles.unwrap_err()) }
  let out_registry = ensure_dir(".codeiq/registry")
  guard out_registry is Ok(_) else { return Err(out_registry.unwrap_err()) }
  let out_http = ensure_dir(http_tmp_dir())
  guard out_http is Ok(_) else { return Err(out_http.unwrap_err()) }
  Ok(())
}

///|
fn parse_http_status(status_text : String) -> Result[Int, @cli.CliError] {
  let parsed = try? @json.parse(status_text.trim().to_string())
  guard parsed is Ok(Number(value, ..)) else {
    return Err(registry_error("invalid http status output: \{status_text}"))
  }
  Ok(value.to_int())
}

///|
fn ascii_lower_char(char : Char) -> Char {
  if char >= 'A' && char <= 'Z' {
    Int::unsafe_to_char(char.to_int() + 32)
  } else {
    char
  }
}

///|
fn ascii_lower(text : String) -> String {
  let out = StringBuilder::new()
  for char in text {
    out.write_char(ascii_lower_char(char))
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
      let normalized = ascii_lower(value)
      normalized == "1" || normalized == "true" || normalized == "yes" ||
      normalized == "on"
    }
    None => false
  }
}

///|
fn env_positive_int(name : String, fallback : Int) -> Int {
  match trimmed_env_var(name) {
    Some(value) =>
      match parse_decimal_int(value) {
        Some(parsed) if parsed > 0 => parsed
        _ => fallback
      }
    None => fallback
  }
}

///|
fn optional_existing_file_env(
  name : String,
) -> Result[String?, @cli.CliError] {
  match trimmed_env_var(name) {
    Some(path) =>
      if @fs.path_exists(path) {
        Ok(Some(path))
      } else {
        Err(registry_error("configured file does not exist for \{name}: \{path}"))
      }
    None => Ok(None)
  }
}

///|
fn insecure_remote_http_allowed() -> Bool {
  env_bool("CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP")
}

///|
fn ensure_secure_remote_url(
  url : String,
  context : String,
) -> Result[Unit, @cli.CliError] {
  if url.has_prefix("http://") && !local_registry_base_url(url) &&
    !insecure_remote_http_allowed() {
    Err(
      registry_error(
        "\{context} requires https or CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP=true: \{url}",
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn header_name_from_env_key(key : String) -> String? {
  let prefix = "CODEIQ_REGISTRY_HEADER_"
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
fn collect_registry_header_flags() -> String {
  let mut flags = ""
  for key, value in @sys.get_env_vars() {
    match header_name_from_env_key(key) {
      Some(name) if value.trim().to_string() != "" => {
        let header = "\{name}: \{value.trim().to_string()}"
        flags = "\{flags} -H \{shell_escape(header)}"
      }
      _ => ()
    }
  }
  flags
}

///|
fn remote_curl_transport_flags() -> Result[String, @cli.CliError] {
  let max_time = env_positive_int("CODEIQ_REGISTRY_CURL_MAX_TIME", 30)
  let retry_count = env_positive_int("CODEIQ_REGISTRY_CURL_RETRY", 2)
  let connect_timeout = env_positive_int(
    "CODEIQ_REGISTRY_CURL_CONNECT_TIMEOUT",
    10,
  )
  let mut flags =
    " --fail --max-time \{max_time} --connect-timeout \{connect_timeout} --retry \{retry_count} --retry-delay 1"
  if env_bool("CODEIQ_REGISTRY_CURL_INSECURE_TLS") {
    flags = "\{flags} -k"
  }
  let ca_file_out = optional_existing_file_env("CODEIQ_REGISTRY_TLS_CA_FILE")
  guard ca_file_out is Ok(ca_file) else { return Err(ca_file_out.unwrap_err()) }
  match ca_file {
    Some(path) => flags = "\{flags} --cacert \{shell_escape(path)}"
    None => ()
  }
  let cert_file_out = optional_existing_file_env(
    "CODEIQ_REGISTRY_TLS_CLIENT_CERT_FILE",
  )
  guard cert_file_out is Ok(cert_file) else {
    return Err(cert_file_out.unwrap_err())
  }
  match cert_file {
    Some(path) => flags = "\{flags} --cert \{shell_escape(path)}"
    None => ()
  }
  let key_file_out = optional_existing_file_env(
    "CODEIQ_REGISTRY_TLS_CLIENT_KEY_FILE",
  )
  guard key_file_out is Ok(key_file) else {
    return Err(key_file_out.unwrap_err())
  }
  match key_file {
    Some(path) => flags = "\{flags} --key \{shell_escape(path)}"
    None => ()
  }
  Ok("\{flags}\{collect_registry_header_flags()}")
}

///|
fn build_remote_upload_command(
  endpoint : String,
  request_path : String,
) -> Result[String, @cli.CliError] {
  let secure_out = ensure_secure_remote_url(endpoint, "remote registry endpoint")
  guard secure_out is Ok(_) else { return Err(secure_out.unwrap_err()) }
  let flags_out = remote_curl_transport_flags()
  guard flags_out is Ok(flags) else { return Err(flags_out.unwrap_err()) }
  Ok(
    "curl -sS -L -X POST\{flags} \{shell_escape(endpoint)} -H 'Content-Type: application/json' -H 'Accept: application/json' --data-binary @\{shell_escape(request_path)}",
  )
}

///|
fn build_remote_resolve_command(
  endpoint : String,
  purl : String,
  if_none_match : String?,
) -> Result[String, @cli.CliError] {
  let secure_out = ensure_secure_remote_url(endpoint, "remote registry endpoint")
  guard secure_out is Ok(_) else { return Err(secure_out.unwrap_err()) }
  let flags_out = remote_curl_transport_flags()
  guard flags_out is Ok(flags) else { return Err(flags_out.unwrap_err()) }
  let query_arg = shell_escape("purl=\{purl}")
  let mut command =
    "curl -sS -L -G\{flags} \{shell_escape(endpoint)} -H 'Accept: application/json' --data-urlencode \{query_arg}"
  match if_none_match {
    Some(value) => {
      let header = "If-None-Match: \{value}"
      command = "\{command} -H \{shell_escape(header)}"
    }
    None => ()
  }
  Ok(command)
}

///|
fn build_remote_bundle_download_command(
  download_url : String,
) -> Result[String, @cli.CliError] {
  let secure_out = ensure_secure_remote_url(download_url, "remote bundle download url")
  guard secure_out is Ok(_) else { return Err(secure_out.unwrap_err()) }
  let flags_out = remote_curl_transport_flags()
  guard flags_out is Ok(flags) else { return Err(flags_out.unwrap_err()) }
  Ok(
    "curl -sS -L\{flags} \{shell_escape(download_url)} -H 'Accept: application/octet-stream'",
  )
}

///|
fn ensure_remote_transport_policy(base_url : String) -> Result[Unit, @cli.CliError] {
  let base_url_out = ensure_secure_remote_url(base_url, "remote registry endpoint")
  guard base_url_out is Ok(_) else { return Err(base_url_out.unwrap_err()) }
  let flags_out = remote_curl_transport_flags()
  guard flags_out is Ok(_) else { return Err(flags_out.unwrap_err()) }
  Ok(())
}

///|
fn parse_http_headers(header_text : String) -> Map[String, String] {
  let headers : Map[String, String] = {}
  let normalized = header_text.replace_all(old="\r\n", new="\n")
  let lines = normalized.split("\n").to_array()
  for i in 0..<lines.length() {
    let line = lines[i].to_string()
    if line.has_prefix("HTTP/") {
      headers.clear()
      continue
    }
    let trimmed = line.trim().to_string()
    if trimmed == "" {
      continue
    }
    let mut split_index = -1
    for j in 0..<line.length() {
      if line[j] == ':' {
        split_index = j
        break
      }
    }
    if split_index <= 0 {
      continue
    }
    let name = line[:split_index].trim().to_string()
    let value = line[split_index + 1:].trim().to_string()
    if name != "" {
      headers[name] = value
    }
  }
  headers
}

///|
fn header_value(headers : Map[String, String], key : String) -> String? {
  let target = ascii_lower(key)
  for name, value in headers {
    if ascii_lower(name) == target {
      return Some(value)
    }
  }
  None
}

///|
fn parse_decimal_int(text : String) -> Int? {
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
    value = value * 10 + (code.to_int() - 48)
  }
  Some(value)
}

///|
fn run_curl_to_file(
  command_without_output : String,
  body_path : String,
) -> Result[(Int, String, Map[String, String]), @cli.CliError] {
  let headers_path = "\{body_path}.headers"
  let command = "\{command_without_output} -D \{shell_escape(headers_path)} -o \{shell_escape(body_path)} -w '%{http_code}'"
  let (exit_code, stdout, stderr) = @shell.run_command_capture(command)
  if exit_code != 0 {
    let details = if stderr != "" { stderr } else { stdout }
    return Err(
      registry_error(
        "curl failed (exit \{exit_code}): \{details.trim().to_string()}",
      ),
    )
  }
  let status_out = parse_http_status(stdout)
  guard status_out is Ok(status) else { return Err(status_out.unwrap_err()) }
  let body = @fs.read_file_to_string(body_path) catch {
    err =>
      return Err(
        registry_error(
          "cannot read http response body \{body_path}: \{err.to_string()}",
        ),
      )
  }
  let headers_text = @fs.read_file_to_string(headers_path) catch {
    err =>
      return Err(
        registry_error(
          "cannot read http response headers \{headers_path}: \{err.to_string()}",
        ),
      )
  }
  Ok((status, body, parse_http_headers(headers_text)))
}

///|
fn run_curl_status_to_file(
  command_without_output : String,
  body_path : String,
) -> Result[(Int, Map[String, String]), @cli.CliError] {
  let headers_path = "\{body_path}.headers"
  let command = "\{command_without_output} -D \{shell_escape(headers_path)} -o \{shell_escape(body_path)} -w '%{http_code}'"
  let (exit_code, stdout, stderr) = @shell.run_command_capture(command)
  if exit_code != 0 {
    let details = if stderr != "" { stderr } else { stdout }
    return Err(
      registry_error(
        "curl failed (exit \{exit_code}): \{details.trim().to_string()}",
      ),
    )
  }
  let status_out = parse_http_status(stdout)
  guard status_out is Ok(status) else { return Err(status_out.unwrap_err()) }
  let headers_text = @fs.read_file_to_string(headers_path) catch {
    err =>
      return Err(
        registry_error(
          "cannot read http response headers \{headers_path}: \{err.to_string()}",
        ),
      )
  }
  Ok((status, parse_http_headers(headers_text)))
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
  "\{cache_index_dir()}/\{index_key(purl)}.json"
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
fn resolved_if_none_match_header(purl : String) -> String? {
  match read_header_env("If-None-Match") {
    Some(value) if value != "" => Some(value)
    _ =>
      match maybe_read_cached_download(purl) {
        Some(Object(cached_object)) =>
          match cached_object.get("etag") {
            Some(String(value)) if value != "" => Some(value)
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
  let out = string_field(object, field)
  guard out is Ok(value) else { return Err(out.unwrap_err()) }
  Ok(value)
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
    "schemaVersion": "codeiq-registry-download/v1",
    "status": 304,
    "purl": purl,
    "bundleId": bundle_id,
    "digest": digest,
    "etag": etag,
    "downloadUrl": download_url,
    "notModified": true,
    "signature": signature_json(signature),
  }
  let valid = @schema.validate_codeiq_registry_download_v1(response)
  guard valid is Ok(_) else {
    return Err(
      registry_error(
        "generated cached 304 response does not satisfy codeiq-registry-download/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(response)
}

///|
fn maybe_transform_receipt_to_download(
  purl : String,
  body_json : Json,
) -> Result[Json, @cli.CliError] {
  let direct_valid = @schema.validate_codeiq_registry_download_v1(body_json)
  if direct_valid is Ok(_) {
    return Ok(body_json)
  }
  let receipt_valid = @schema.validate_codeiq_publish_receipt_v1(body_json)
  guard receipt_valid is Ok(_) else {
    return Err(
      registry_error(
        "remote response does not satisfy download or receipt schema",
      ),
    )
  }
  guard body_json is Object(receipt) else {
    return Err(registry_error("publish receipt response must be object"))
  }
  let bundle_id_out = string_field(receipt, "bundleId")
  guard bundle_id_out is Ok(bundle_id) else {
    return Err(bundle_id_out.unwrap_err())
  }
  let digest_out = string_field(receipt, "digest")
  guard digest_out is Ok(digest) else { return Err(digest_out.unwrap_err()) }
  let digest_valid_out = ensure_sha256_digest(digest, "remote receipt response")
  guard digest_valid_out is Ok(_) else {
    return Err(digest_valid_out.unwrap_err())
  }
  let download_url_out = string_field(receipt, "downloadUrl")
  guard download_url_out is Ok(download_url) else {
    return Err(download_url_out.unwrap_err())
  }
  let receipt_status = match receipt.get("status") {
    Some(String("already-exists")) => 304
    _ => 200
  }
  let resolved_etag = receipt_etag(receipt, "\"\{bundle_id}\"")
  let signature = signature_status_from_receipt(receipt)
  let response : Json = {
    "schemaVersion": "codeiq-registry-download/v1",
    "status": receipt_status,
    "purl": purl,
    "bundleId": bundle_id,
    "digest": digest,
    "etag": resolved_etag,
    "downloadUrl": download_url,
    "notModified": receipt_status == 304,
    "signature": signature_json(signature),
  }
  let valid = @schema.validate_codeiq_registry_download_v1(response)
  guard valid is Ok(_) else {
    return Err(
      registry_error(
        "transformed receipt does not satisfy codeiq-registry-download/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(response)
}

///|
fn signature_status_from_upload_request(
  object : Map[String, Json],
) -> SignatureStatus {
  match object.get("signature") {
    Some(Object(signature_object)) =>
      signature_status_from_download({
        "signature": Json::object(signature_object),
      })
    _ => load_signature_status_from_env()
  }
}

///|
fn maybe_cache_bundle_download(
  purl : String,
  download : Json,
) -> Result[Json, @cli.CliError] {
  guard download is Object(download_object) else {
    return Err(registry_error("registry download response must be object"))
  }
  let purl_out = string_field(download_object, "purl")
  guard purl_out is Ok(download_purl) else { return Err(purl_out.unwrap_err()) }
  if download_purl != purl {
    return Err(
      registry_error(
        "remote download purl mismatch: expected=\{purl}, response=\{download_purl}",
      ),
    )
  }
  let bundle_id_out = string_field(download_object, "bundleId")
  guard bundle_id_out is Ok(bundle_id) else {
    return Err(bundle_id_out.unwrap_err())
  }
  let digest_out = string_field(download_object, "digest")
  guard digest_out is Ok(expected_digest) else {
    return Err(digest_out.unwrap_err())
  }
  let digest_valid_out = ensure_sha256_digest(
    expected_digest, "remote download response",
  )
  guard digest_valid_out is Ok(_) else {
    return Err(digest_valid_out.unwrap_err())
  }
  let etag_out = string_field(download_object, "etag")
  guard etag_out is Ok(etag) else { return Err(etag_out.unwrap_err()) }
  let download_url_out = string_field(download_object, "downloadUrl")
  guard download_url_out is Ok(download_url) else {
    return Err(download_url_out.unwrap_err())
  }
  let status = match download_object.get("status") {
    Some(Number(value, ..)) => value.to_int()
    _ => 200
  }
  let signature = signature_status_from_download(download_object)

  if status == 304 {
    download_object["signature"] = signature_json(signature)
    let valid_304 = @schema.validate_codeiq_registry_download_v1(download)
    guard valid_304 is Ok(_) else {
      return Err(
        registry_error(
          "304 remote download response does not satisfy codeiq-registry-download/v1 schema: \{valid_304.unwrap_err().to_string()}",
        ),
      )
    }
    return Ok(download)
  }

  let declared_length = match download_object.get("contentLength") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
  let mut effective_etag = etag
  let cached_bundle_path = "\{cache_bundles_dir()}/\{bundle_id}.ciq.tgz"
  let http_body_path = "\{http_tmp_dir()}/bundle-download.bin"
  let bundle_bytes_out = if download_url.has_prefix("http://") ||
    download_url.has_prefix("https://") {
    let command_out = build_remote_bundle_download_command(download_url)
    guard command_out is Ok(command) else {
      return Err(command_out.unwrap_err())
    }
    let status_out = run_curl_status_to_file(command, http_body_path)
    guard status_out is Ok((code, download_headers)) else {
      return Err(status_out.unwrap_err())
    }
    if code != 200 {
      return Err(
        registry_error(
          "remote bundle download failed with http status \{code} for \{download_url}",
        ),
      )
    }
    match header_value(download_headers, "ETag") {
      Some(value) if value != "" => effective_etag = value
      _ => ()
    }
    let length_out = if declared_length is Some(value) {
      Some(value)
    } else {
      match header_value(download_headers, "Content-Length") {
        Some(value) => parse_decimal_int(value)
        None => None
      }
    }
    if length_out is Some(length) {
      download_object["contentLength"] = Json::number(
        length.to_double(),
        repr="\{length}",
      )
    }
    @fs.read_file_to_bytes(http_body_path) catch {
      err =>
        return Err(
          registry_error(
            "cannot read downloaded bundle body \{http_body_path}: \{err.to_string()}",
          ),
        )
    }
  } else if download_url.has_prefix("local://") {
    let local_path = download_url[8:].to_string()
    @fs.read_file_to_bytes(local_path) catch {
      err =>
        return Err(
          registry_error(
            "cannot read local remote bundle \{local_path}: \{err.to_string()}",
          ),
        )
    }
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
  let resolved_signature = verify_signature_for_bundle_file(
    cached_bundle_path, signature,
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

  let valid = @schema.validate_codeiq_registry_download_v1(download)
  guard valid is Ok(_) else {
    return Err(
      registry_error(
        "cached remote download response does not satisfy codeiq-registry-download/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(download)
}

///|
fn maybe_transform_download_to_receipt(
  upload_request : Json,
  body_json : Json,
) -> Result[Json, @cli.CliError] {
  let parsed_out = parse_upload(upload_request)
  guard parsed_out
    is Ok((_, expected_bundle_type, expected_purl, expected_digest, _, _)) else {
    return Err(parsed_out.unwrap_err())
  }

  let receipt_valid = @schema.validate_codeiq_publish_receipt_v1(body_json)
  if receipt_valid is Ok(_) {
    guard body_json is Object(receipt_object) else {
      return Err(registry_error("publish receipt response must be object"))
    }
    let purl_out = string_field(receipt_object, "purl")
    guard purl_out is Ok(receipt_purl) else {
      return Err(purl_out.unwrap_err())
    }
    if receipt_purl != expected_purl {
      return Err(
        registry_error(
          "remote receipt purl mismatch: expected=\{expected_purl}, response=\{receipt_purl}",
        ),
      )
    }
    let digest_out = string_field(receipt_object, "digest")
    guard digest_out is Ok(receipt_digest) else {
      return Err(digest_out.unwrap_err())
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
    let bundle_type_out = string_field(receipt_object, "bundleType")
    guard bundle_type_out is Ok(receipt_bundle_type) else {
      return Err(bundle_type_out.unwrap_err())
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

  let download_valid = @schema.validate_codeiq_registry_download_v1(body_json)
  guard download_valid is Ok(_) else {
    return Err(
      registry_error(
        "remote upload response does not satisfy receipt or download schema",
      ),
    )
  }
  guard body_json is Object(download_object) else {
    return Err(registry_error("registry download response must be object"))
  }
  let bundle_id_out = string_field(download_object, "bundleId")
  guard bundle_id_out is Ok(bundle_id) else {
    return Err(bundle_id_out.unwrap_err())
  }
  let download_url_out = string_field(download_object, "downloadUrl")
  guard download_url_out is Ok(download_url) else {
    return Err(download_url_out.unwrap_err())
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
    "schemaVersion": "codeiq-publish-receipt/v1",
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
  let valid = @schema.validate_codeiq_publish_receipt_v1(receipt)
  guard valid is Ok(_) else {
    return Err(
      registry_error(
        "transformed download response does not satisfy codeiq-publish-receipt/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
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
  let purl_out = string_field(receipt_object, "purl")
  guard purl_out is Ok(purl) else { return Err(purl_out.unwrap_err()) }
  let bundle_id_out = string_field(receipt_object, "bundleId")
  guard bundle_id_out is Ok(bundle_id) else {
    return Err(bundle_id_out.unwrap_err())
  }
  let digest_out = string_field(receipt_object, "digest")
  guard digest_out is Ok(digest) else { return Err(digest_out.unwrap_err()) }
  let download_url_out = string_field(receipt_object, "downloadUrl")
  guard download_url_out is Ok(download_url) else {
    return Err(download_url_out.unwrap_err())
  }
  let signature = signature_status_from_receipt(receipt_object)

  let download : Json = {
    "schemaVersion": "codeiq-registry-download/v1",
    "status": 200,
    "purl": purl,
    "bundleId": bundle_id,
    "digest": digest,
    "etag": etag,
    "downloadUrl": download_url,
    "notModified": false,
    "signature": signature_json(signature),
  }
  let valid = @schema.validate_codeiq_registry_download_v1(download)
  guard valid is Ok(_) else {
    return Err(
      registry_error(
        "generated cache download response does not satisfy codeiq-registry-download/v1 schema: \{valid.unwrap_err().to_string()}",
      ),
    )
  }
  let write_out = write_cached_download(purl, download)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  let etag_out = write_etag("\{cache_bundles_dir()}/\{bundle_id}.etag", etag)
  guard etag_out is Ok(_) else { return Err(etag_out.unwrap_err()) }
  Ok(())
}

///|
fn upload_remote(upload_request : Json) -> Result[UploadResult, @cli.CliError] {
  let ensure_out = ensure_remote_dirs()
  guard ensure_out is Ok(_) else { return Err(ensure_out.unwrap_err()) }

  let base_url_out = registry_base_url()
  guard base_url_out is Some(base_url) else {
    return Err(registry_error("remote registry base url is not configured"))
  }
  let normalized_base_url = normalize_base_url(base_url)
  let transport_out = ensure_remote_transport_policy(normalized_base_url)
  guard transport_out is Ok(_) else { return Err(transport_out.unwrap_err()) }

  let response_json_out = if inproc_registry_enabled(normalized_base_url) {
    let api_out = api_upload(upload_request)
    guard api_out is Ok(api_response) else { return Err(api_out.unwrap_err()) }
    if api_response.status != 200 && api_response.status != 201 {
      return Err(
        registry_error(
          "inproc registry upload failed with http status \{api_response.status}: \{api_response.body.stringify(indent=2)}",
        ),
      )
    }
    Ok(api_response.body)
  } else {
    match @sys.get_env_var("CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON") {
      Some(raw) =>
        parse_json_text(raw, "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
      None => {
        let request_path = "\{http_tmp_dir()}/upload-request.json"
        let write_out = write_string_atomic(
          request_path,
          upload_request.stringify(indent=2),
        )
        guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
        let body_path = "\{http_tmp_dir()}/upload-response.json"
        let endpoint = "\{normalized_base_url}/api/v1/bundles"
        let command_out = build_remote_upload_command(endpoint, request_path)
        guard command_out is Ok(command) else {
          return Err(command_out.unwrap_err())
        }
        let http_out = run_curl_to_file(command, body_path)
        guard http_out is Ok((status, body, _)) else {
          return Err(http_out.unwrap_err())
        }
        if status != 200 && status != 201 {
          return Err(
            registry_error(
              "remote registry upload failed with http status \{status}: \{body.trim().to_string()}",
            ),
          )
        }
        parse_json_text(body, "remote registry upload response")
      }
    }
  }
  guard response_json_out is Ok(response_json) else {
    return Err(response_json_out.unwrap_err())
  }

  let receipt_out = maybe_transform_download_to_receipt(
    upload_request, response_json,
  )
  guard receipt_out is Ok(receipt) else { return Err(receipt_out.unwrap_err()) }
  guard receipt is Object(receipt_object) else {
    return Err(registry_error("remote publish receipt must be object"))
  }
  let bundle_id_out = string_field(receipt_object, "bundleId")
  guard bundle_id_out is Ok(bundle_id) else {
    return Err(bundle_id_out.unwrap_err())
  }
  let download_url_out = string_field(receipt_object, "downloadUrl")
  guard download_url_out is Ok(download_url) else {
    return Err(download_url_out.unwrap_err())
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
fn download_remote_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  let ensure_out = ensure_remote_dirs()
  guard ensure_out is Ok(_) else { return Err(ensure_out.unwrap_err()) }

  let base_url_out = registry_base_url()
  guard base_url_out is Some(base_url) else {
    return Err(registry_error("remote registry base url is not configured"))
  }
  let normalized_base_url = normalize_base_url(base_url)
  let transport_out = ensure_remote_transport_policy(normalized_base_url)
  guard transport_out is Ok(_) else { return Err(transport_out.unwrap_err()) }

  if inproc_registry_enabled(normalized_base_url) {
    let if_none_match = resolved_if_none_match_header(purl)
    let api_out = api_resolve(purl, if_none_match)
    guard api_out is Ok(api_response) else { return Err(api_out.unwrap_err()) }
    let transformed_out = maybe_transform_receipt_to_download(
      purl,
      api_response.body,
    )
    guard transformed_out is Ok(download) else {
      return Err(transformed_out.unwrap_err())
    }
    let cached_out = maybe_cache_bundle_download(purl, download)
    guard cached_out is Ok(cached) else { return Err(cached_out.unwrap_err()) }
    return Ok(cached)
  }

  match @sys.get_env_var("CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON") {
    Some(raw) => {
      let parsed_out = parse_json_text(
        raw, "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
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
      let body_path = "\{http_tmp_dir()}/download-response.json"
      let endpoint = "\{normalized_base_url}/api/v1/bundles/resolve"
      let if_none_match = resolved_if_none_match_header(purl)
      let command_out = build_remote_resolve_command(
        endpoint,
        purl,
        if_none_match,
      )
      guard command_out is Ok(command) else {
        return Err(command_out.unwrap_err())
      }
      let http_out = run_curl_to_file(command, body_path)
      guard http_out is Ok((status, body, _)) else {
        return Err(http_out.unwrap_err())
      }
      if status == 304 {
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
        if status != 200 {
          return Err(
            registry_error(
              "remote registry download failed with http status \{status}: \{body.trim().to_string()}",
            ),
          )
        }
        let parsed_out = parse_json_text(
          body, "remote registry download response",
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
    }
  }
}

///|
pub fn download_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  if remote_registry_enabled() {
    download_remote_by_purl(purl)
  } else {
    download_local_by_purl(purl)
  }
}

///|
pub fn upload(upload_request : Json) -> Result[UploadResult, @cli.CliError] {
  if remote_registry_enabled() {
    upload_remote(upload_request)
  } else {
    upload_local(upload_request)
  }
}

///|
fn write_etag(path : String, etag : String) -> Result[Unit, @cli.CliError] {
  let write_out = write_string_atomic(path, etag)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  Ok(())
}

///|
fn read_etag(path : String) -> String? {
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
fn read_json_file(path : String) -> Result[Json, @cli.CliError] {
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
fn download_local_by_purl_with_if_none_match(
  purl : String,
  if_none_match : String?,
) -> Result[Json, @cli.CliError] {
  let root = ".codeiq/registry"
  let index_dir = "\{root}/index"
  let bundles_dir = "\{root}/bundles"
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
  let signature = signature_status_from_receipt(receipt)

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
      "signature": signature_json(signature),
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
    "signature": signature_json(signature),
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
) -> Result[RegistryApiResponse, @cli.CliError] {
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
fn parse_upload(
  upload_request : Json,
) -> Result[
  (String, String, String, String, Int, SignatureStatus),
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
  let signature = signature_status_from_upload_request(object)
  Ok((bundle_file, bundle_type, purl, digest, size, signature))
}

///|
fn receipt_provenance(
  source : String,
  digest_verified : Bool,
  etag : String,
  signature : SignatureStatus,
) -> Json {
  {
    "source": source,
    "digestVerified": digest_verified,
    "etag": etag,
    "signature": signature_json(signature),
  }
}

///|
fn string_field_optional(object : Map[String, Json], field : String) -> String? {
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
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
fn load_signature_status_from_env() -> SignatureStatus {
  let status = match @sys.get_env_var("CODEIQ_SIGNATURE_STATUS") {
    Some(value) => parse_signature_status(value.trim().to_string())
    None => "unsigned"
  }
  let key_id = match @sys.get_env_var("CODEIQ_SIGNATURE_KEY_ID") {
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
  { status, algorithm: "sha256", key_id, value }
}

///|
fn signature_json(signature : SignatureStatus) -> Json {
  let object : Map[String, Json] = {
    "status": Json::string(signature.status),
    "algorithm": Json::string(signature.algorithm),
  }
  match signature.key_id {
    Some(value) => object["keyId"] = Json::string(value)
    None => ()
  }
  match signature.value {
    Some(value) => object["value"] = Json::string(value)
    None => ()
  }
  Json::object(object)
}

///|
fn signature_status_from_download(
  download : Map[String, Json],
) -> SignatureStatus {
  match download.get("signature") {
    Some(Object(signature_object)) => {
      let status = match string_field_optional(signature_object, "status") {
        Some(value) => parse_signature_status(value)
        None => "unsigned"
      }
      let algorithm = match
        string_field_optional(signature_object, "algorithm") {
        Some(value) => value
        None => "sha256"
      }
      let key_id = string_field_optional(signature_object, "keyId")
      let value = string_field_optional(signature_object, "value")
      { status, algorithm, key_id, value }
    }
    _ => load_signature_status_from_env()
  }
}

///|
fn signature_status_from_receipt(
  receipt : Map[String, Json],
) -> SignatureStatus {
  match receipt.get("provenance") {
    Some(Object(provenance)) =>
      match provenance.get("signature") {
        Some(Object(signature_object)) => {
          let status = match string_field_optional(signature_object, "status") {
            Some(value) => parse_signature_status(value)
            None => "unsigned"
          }
          let algorithm = match
            string_field_optional(signature_object, "algorithm") {
            Some(value) => value
            None => "sha256"
          }
          let key_id = string_field_optional(signature_object, "keyId")
          let value = string_field_optional(signature_object, "value")
          { status, algorithm, key_id, value }
        }
        _ => load_signature_status_from_env()
      }
    _ => load_signature_status_from_env()
  }
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
pub fn api_upload(
  upload_request : Json,
) -> Result[RegistryApiResponse, @cli.CliError] {
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

///|
pub fn run_upload_local(
  params : RegistryUploadParams,
) -> @cli.CliResult[RegistryUploadCliResult, @cli.CliError] {
  let request_out = read_json_file(params.upload_request_file)
  guard request_out is Ok(request) else { return Err(request_out.unwrap_err()) }

  let upload_out = upload(request)
  guard upload_out is Ok(uploaded) else { return Err(upload_out.unwrap_err()) }

  Ok({
    upload_request_file: params.upload_request_file,
    receipt: uploaded.receipt,
    summary: "Uploaded bundle from \{params.upload_request_file}",
  })
}

///|
pub fn run_download_local(
  params : RegistryDownloadParams,
) -> @cli.CliResult[RegistryDownloadCliResult, @cli.CliError] {
  let download_out = download_by_purl(params.purl)
  guard download_out is Ok(response) else {
    return Err(download_out.unwrap_err())
  }

  Ok({
    purl: params.purl,
    response,
    summary: "Resolved registry metadata for \{params.purl}",
  })
}

///|
fn response_bundle_path(response : Json) -> Result[String, @cli.CliError] {
  guard response is Object(response_object) else {
    return Err(registry_error("registry response must be object"))
  }
  let url_out = string_field(response_object, "downloadUrl")
  guard url_out is Ok(download_url) else { return Err(url_out.unwrap_err()) }
  if !download_url.has_prefix("local://") {
    return Err(
      registry_error(
        "bundle download is not materialized locally: \{download_url}",
      ),
    )
  }
  Ok(download_url[8:].to_string())
}

///|
pub fn run_download_bundle(
  params : RegistryDownloadBundleParams,
) -> @cli.CliResult[RegistryDownloadBundleCliResult, @cli.CliError] {
  let download_out = download_by_purl(params.purl)
  guard download_out is Ok(response) else {
    return Err(download_out.unwrap_err())
  }
  let bundle_path_out = response_bundle_path(response)
  guard bundle_path_out is Ok(bundle_path) else {
    return Err(bundle_path_out.unwrap_err())
  }
  let materialize_out = @bundle.materialize_bundle_tar_gz(
    bundle_path,
    params.output_dir,
  )
  guard materialize_out is Ok(_) else {
    return Err(
      registry_error(
        "cannot materialize bundle into \{params.output_dir}: \{materialize_out.unwrap_err()}",
      ),
    )
  }

  Ok({
    purl: params.purl,
    bundle_file: bundle_path,
    output_dir: params.output_dir,
    summary: "Downloaded and materialized bundle for \{params.purl} into \{params.output_dir}",
  })
}
