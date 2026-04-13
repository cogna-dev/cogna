///|
pub(all) struct RegistryApiResponse {
  status : Int
  headers : Map[String, String]
  body : Json
} derive(Eq)

///|
pub impl Show for RegistryApiResponse with output(self, logger) {
  logger.write_string("{status: ")
  logger.write_object(self.status)
  logger.write_string(", headers: ")
  logger.write_object(self.headers)
  logger.write_string(", body: ")
  logger.write_object(self.body)
  logger.write_char('}')
}

///|
pub(all) struct UploadResult {
  receipt : Json
  stored_bundle_path : String
  etag : String
} derive(Eq)

///|
pub impl Show for UploadResult with output(self, logger) {
  logger.write_string("{receipt: ")
  logger.write_object(self.receipt)
  logger.write_string(", stored_bundle_path: ")
  logger.write_object(self.stored_bundle_path)
  logger.write_string(", etag: ")
  logger.write_object(self.etag)
  logger.write_char('}')
}

///|
pub(all) struct SignatureStatus {
  status : String
  algorithm : String
  key_id : String?
  value : String?
} derive(Eq)

///|
pub impl Show for SignatureStatus with output(self, logger) {
  logger.write_string("{status: ")
  logger.write_object(self.status)
  logger.write_string(", algorithm: ")
  logger.write_object(self.algorithm)
  logger.write_string(", key_id: ")
  logger.write_object(self.key_id)
  logger.write_string(", value: ")
  logger.write_object(self.value)
  logger.write_char('}')
}

///|
pub(all) enum RegistryRoute {
  Health
  PublishBundles
  PackageVersions(String)
  BundleDetail(String)
  BundleDownload(String)
  ResolveByPurl(String)
  Unknown
} derive(Eq)

///|
pub impl Show for RegistryRoute with output(self, logger) {
  match self {
    Health => logger.write_string("Health")
    PublishBundles => logger.write_string("PublishBundles")
    PackageVersions(purl) => {
      logger.write_string("PackageVersions(")
      logger.write_object(purl)
      logger.write_char(')')
    }
    BundleDetail(bundle_id) => {
      logger.write_string("BundleDetail(")
      logger.write_object(bundle_id)
      logger.write_char(')')
    }
    BundleDownload(bundle_id) => {
      logger.write_string("BundleDownload(")
      logger.write_object(bundle_id)
      logger.write_char(')')
    }
    ResolveByPurl(purl) => {
      logger.write_string("ResolveByPurl(")
      logger.write_object(purl)
      logger.write_char(')')
    }
    Unknown => logger.write_string("Unknown")
  }
}

///|
fn trimmed_env_var_registry(name : String) -> String? {
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
fn config_store_dir(root_dir : String) -> String? {
  let resolved_out = @config.resolve(root_dir)
  guard resolved_out is Ok(resolved) else { return None }
  let configured = resolved.config.registry.store_dir.trim().to_string()
  if configured == "" {
    None
  } else {
    Some(@config.resolve_project_path(resolved.root_dir, configured))
  }
}

///|
pub fn resolved_local_store_root(root_dir : String) -> String {
  match trimmed_env_var_registry("CODEIQ_REGISTRY_STORE_DIR") {
    Some(value) => value
    None =>
      match config_store_dir(root_dir) {
        Some(path) => path
        None => ".codeiq/cache/registry"
      }
  }
}

///|
pub fn local_store_root() -> String {
  resolved_local_store_root(@env.current_dir().unwrap_or("."))
}

///|
pub fn local_store_index_dir() -> String {
  "\{local_store_root()}/index"
}

///|
pub fn local_store_bundles_dir() -> String {
  "\{local_store_root()}/bundles"
}

///|
pub fn registry_base_url() -> String? {
  trimmed_env_var_registry("CODEIQ_REGISTRY_BASE_URL")
}

///|
pub fn normalize_base_url(url : String) -> String {
  if url.has_suffix("/") {
    url[:url.length() - 1].to_string()
  } else {
    url
  }
}

///|
pub fn local_registry_base_url(url : String) -> Bool {
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
pub fn remote_registry_enabled() -> Bool {
  registry_base_url() is Some(_)
}

///|
pub fn parse_signature_status(status : String) -> String {
  match status {
    "verified" => "verified"
    "untrusted" => "untrusted"
    _ => "unsigned"
  }
}

///|
pub fn signature_status_with_status(
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
pub fn string_field_optional(
  object : Map[String, Json],
  field : String,
) -> String? {
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
}

///|
pub fn signature_public_key_file() -> String? {
  trimmed_env_var_registry("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE")
}

///|
pub fn load_signature_status_from_env() -> SignatureStatus {
  let status = match trimmed_env_var_registry("CODEIQ_SIGNATURE_STATUS") {
    Some(value) => parse_signature_status(value)
    None => "unsigned"
  }
  let key_id = trimmed_env_var_registry("CODEIQ_SIGNATURE_KEY_ID")
  let value = trimmed_env_var_registry("CODEIQ_SIGNATURE_VALUE")
  { status, algorithm: "sha256", key_id, value }
}

///|
pub fn signature_json(signature : SignatureStatus) -> Json {
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
pub fn signature_status_from_download(
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
pub fn signature_status_from_receipt(
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
pub fn signature_status_from_upload_request(
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
pub fn verify_signature_for_file(
  bundle_file : String,
  signature : SignatureStatus,
  temp_prefix : String,
) -> SignatureStatus {
  ignore(bundle_file)
  ignore(temp_prefix)
  signature
}

///|
fn hex_digit(value : Int) -> String {
  if value < 10 {
    "\{value}"
  } else {
    match value {
      10 => "A"
      11 => "B"
      12 => "C"
      13 => "D"
      14 => "E"
      _ => "F"
    }
  }
}

///|
pub fn url_encode(value : String) -> String {
  let bytes = @utf8.encode(value)
  let encoded = StringBuilder::new()
  for i in 0..<bytes.length() {
    let byte = bytes[i].to_int()
    let keep = (byte >= 'a'.to_int() && byte <= 'z'.to_int()) ||
      (byte >= 'A'.to_int() && byte <= 'Z'.to_int()) ||
      (byte >= '0'.to_int() && byte <= '9'.to_int()) ||
      byte == '-'.to_int() ||
      byte == '_'.to_int() ||
      byte == '.'.to_int() ||
      byte == '~'.to_int()
    if keep {
      encoded.write_char(byte.unsafe_to_char())
    } else {
      encoded.write_char('%')
      encoded.write_string(hex_digit(byte / 16))
      encoded.write_string(hex_digit(byte % 16))
    }
  }
  encoded.to_string()
}

///|
fn hex_value(code : UInt16) -> Int? {
  if code >= '0' && code <= '9' {
    Some(code.to_int() - '0')
  } else if code >= 'A' && code <= 'F' {
    Some(code.to_int() - 'A' + 10)
  } else if code >= 'a' && code <= 'f' {
    Some(code.to_int() - 'a' + 10)
  } else {
    None
  }
}

///|
pub fn url_decode(value : String) -> Result[String, String] {
  let out : Array[Byte] = []
  let mut i = 0
  while i < value.length() {
    let code = value[i]
    if code == '%' {
      if i + 2 >= value.length() {
        return Err("invalid percent-encoding: \{value}")
      }
      let hi = hex_value(value[i + 1]).unwrap_or(-1)
      let lo = hex_value(value[i + 2]).unwrap_or(-1)
      if hi < 0 || lo < 0 {
        return Err("invalid percent-encoding: \{value}")
      }
      out.push((hi * 16 + lo).to_byte())
      i += 3
    } else {
      out.push(code.to_int().to_byte())
      i += 1
    }
  }
  let decoded = @utf8.decode(Bytes::from_array(out)) catch {
    _ => return Err("invalid utf-8 in decoded url")
  }
  Ok(decoded)
}

///|
fn strip_query(path : String) -> String {
  match path.find("?") {
    Some(index) => path[:index].to_string()
    None => path
  }
}

///|
pub fn query_value(path : String, key : String) -> String? {
  let query_index = path.find("?")
  guard query_index is Some(index) else { return None }
  let query = path[index + 1:].to_string()
  let pairs = query.split("&").to_array()
  for i in 0..<pairs.length() {
    let pair = pairs[i].to_string()
    let split = pair.split("=").to_array()
    if split.length() == 2 && split[0] == key {
      match url_decode(split[1].to_string()) {
        Ok(value) => return Some(value)
        Err(_) => return None
      }
    }
  }
  None
}

///|
pub fn route(http_method : String, path : String) -> RegistryRoute {
  let normalized_method = http_method.to_upper()
  let clean_path = strip_query(path)
  if normalized_method == "GET" && clean_path == "/health" {
    return Health
  }
  if normalized_method == "POST" && clean_path == "/api/v1/bundles" {
    return PublishBundles
  }
  if normalized_method == "GET" && clean_path == "/api/v1/bundles/resolve" {
    match query_value(path, "purl") {
      Some(purl) => return ResolveByPurl(purl)
      None => return Unknown
    }
  }
  let segments_view = clean_path.split("/").to_array()
  let segments : Array[String] = []
  for i in 0..<segments_view.length() {
    segments.push(segments_view[i].to_string())
  }
  if segments.length() == 6 &&
    segments[1] == "api" &&
    segments[2] == "v1" &&
    segments[3] == "packages" &&
    segments[5] == "versions" {
    match url_decode(segments[4]) {
      Ok(purl) => return PackageVersions(purl)
      Err(_) => return Unknown
    }
  }
  if segments.length() == 5 &&
    segments[1] == "api" &&
    segments[2] == "v1" &&
    segments[3] == "bundles" {
    return BundleDetail(segments[4])
  }
  if segments.length() == 6 &&
    segments[1] == "api" &&
    segments[2] == "v1" &&
    segments[3] == "bundles" &&
    segments[5] == "download" {
    return BundleDownload(segments[4])
  }
  Unknown
}

///|
pub fn upload_path() -> String {
  "/api/v1/bundles"
}

///|
pub fn versions_path(purl : String) -> String {
  "/api/v1/packages/\{url_encode(purl)}/versions"
}

///|
pub fn bundle_detail_path(bundle_id : String) -> String {
  "/api/v1/bundles/\{bundle_id}"
}

///|
pub fn bundle_download_path(bundle_id : String) -> String {
  "/api/v1/bundles/\{bundle_id}/download"
}

///|
pub fn resolve_path(purl : String) -> String {
  "/api/v1/bundles/resolve?purl=\{url_encode(purl)}"
}

///|
pub fn health_path() -> String {
  "/health"
}

///|
fn ascii_lower_char_registry(char : Char) -> Char {
  if char >= 'A' && char <= 'Z' {
    Int::unsafe_to_char(char.to_int() + 32)
  } else {
    char
  }
}

///|
fn ascii_lower_registry(text : String) -> String {
  let out = StringBuilder::new()
  for char in text {
    out.write_char(ascii_lower_char_registry(char))
  }
  out.to_string()
}

///|
pub fn header_value(headers : Map[String, String], key : String) -> String? {
  let target = ascii_lower_registry(key)
  for name, value in headers {
    if ascii_lower_registry(name) == target {
      return Some(value)
    }
  }
  None
}
