///|
fn remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn clear_registry_env_vars() -> Unit {
  @sys.unset_env_var("CODEIQ_REGISTRY_BASE_URL")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_Authorization")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_X_API_KEY")
  @sys.unset_env_var("CODEIQ_SIGNATURE_STATUS")
  @sys.unset_env_var("CODEIQ_SIGNATURE_KEY_ID")
  @sys.unset_env_var("CODEIQ_SIGNATURE_VALUE")
  @sys.unset_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE")
  @sys.unset_env_var("CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP")
  @sys.unset_env_var("CODEIQ_REGISTRY_CURL_MAX_TIME")
  @sys.unset_env_var("CODEIQ_REGISTRY_CURL_RETRY")
  @sys.unset_env_var("CODEIQ_REGISTRY_CURL_CONNECT_TIMEOUT")
  @sys.unset_env_var("CODEIQ_REGISTRY_CURL_INSECURE_TLS")
  @sys.unset_env_var("CODEIQ_REGISTRY_TLS_CA_FILE")
  @sys.unset_env_var("CODEIQ_REGISTRY_TLS_CLIENT_CERT_FILE")
  @sys.unset_env_var("CODEIQ_REGISTRY_TLS_CLIENT_KEY_FILE")
}

///|
fn cleanup_registry() -> Unit {
  remove_dir_if_exists(".codeiq/registry/index")
  remove_dir_if_exists(".codeiq/registry/bundles")
  remove_dir_if_exists(".codeiq/registry/http")
  remove_dir_if_exists(".codeiq/registry")
  remove_dir_if_exists(".codeiq/cache/registry/index")
  remove_dir_if_exists(".codeiq/cache/registry/bundles")
  remove_dir_if_exists(".codeiq/cache/registry")
  remove_dir_if_exists(".codeiq/cache")
  remove_dir_if_exists(".codeiq")
  clear_registry_env_vars()
}

///|
fn dbt_cleanup_registry() -> Unit {
  cleanup_registry()
}

///|
fn bundle_fixture(repo : String) -> String {
  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle fixture") catch {
    _ => abort("failed to write bundle fixture")
  }
  bundle_path
}

///|
fn upload_request(bundle_path : String, purl : String) -> Json {
  let bytes = @fs.read_file_to_bytes(bundle_path) catch {
    _ => abort("failed to read bundle fixture")
  }
  {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_path,
    "bundleType": "ciq-bundle",
    "purl": purl,
    "digest": "sha256:\{@sha256.sha256_hexdigest(bytes)}",
    "size": bytes.length(),
  }
}

///|
fn upload_request_with_signature(
  bundle_path : String,
  purl : String,
  signature : Json,
) -> Json {
  let request = upload_request(bundle_path, purl)
  guard request is Object(request_object) else {
    abort("upload request should be object")
  }
  request_object["signature"] = signature
  Json::object(request_object)
}

///|
fn gzip_compress(payload : Bytes) -> Bytes {
  let gz = @gio.Buffer::new()
  let writer = @gzip.Writer::new(gz)
  let (_, write_out) = writer.write(@gio.Slice::new(payload.to_array()))
  guard write_out is None else { abort("failed to write gzip payload") }
  let close_out = writer.close()
  guard close_out is None else { abort("failed to close gzip payload") }
  gz.to_bytes()
}

///|
fn octal_field(value : Int, width : Int) -> String {
  let digits = value.reinterpret_as_uint().to_string(radix=8)
  if digits.length() + 1 >= width {
    digits + "\u0000"
  } else {
    let padding = String::make(width - digits.length() - 1, '0')
    padding + digits + "\u0000"
  }
}

///|
fn str_field(value : String, width : Int) -> String {
  let bytes = @utf8.encode(value)
  if bytes.length() >= width {
    let truncated = bytes[:width].to_bytes()
    @utf8.decode(truncated) catch {
      _ => value
    }
  } else {
    let padding = String::make(width - bytes.length(), '\u0000')
    value + padding
  }
}

///|
fn sum_header_bytes(header : Bytes) -> Int {
  let mut total = 0
  for i in 0..<header.length() {
    total = total + header[i].to_int()
  }
  total
}

///|
fn tar_header(name : String, size : Int) -> Bytes {
  let name_field = str_field(name, 100)
  let mode_field = octal_field(420, 8)
  let uid_field = octal_field(0, 8)
  let gid_field = octal_field(0, 8)
  let size_field = octal_field(size, 12)
  let mtime_field = octal_field(0, 12)
  let checksum_placeholder = "        "
  let type_flag = "0"
  let link_name = str_field("", 100)
  let magic = "ustar\u0000"
  let version = "00"
  let uname = str_field("", 32)
  let gname = str_field("", 32)
  let devmajor = octal_field(0, 8)
  let devminor = octal_field(0, 8)
  let prefix = str_field("", 155)
  let pad = String::make(12, '\u0000')
  let without_checksum = name_field +
    mode_field +
    uid_field +
    gid_field +
    size_field +
    mtime_field +
    checksum_placeholder +
    type_flag +
    link_name +
    magic +
    version +
    uname +
    gname +
    devmajor +
    devminor +
    prefix +
    pad
  let bytes = @utf8.encode(without_checksum)
  let checksum = sum_header_bytes(bytes)
  let checksum_field = octal_field(checksum, 8)
  let finalized = name_field +
    mode_field +
    uid_field +
    gid_field +
    size_field +
    mtime_field +
    checksum_field +
    type_flag +
    link_name +
    magic +
    version +
    uname +
    gname +
    devmajor +
    devminor +
    prefix +
    pad
  @utf8.encode(finalized)
}

///|
fn tar_entry(name : String, content : Bytes) -> Bytes {
  let header = tar_header(name, content.length())
  let payload = header.to_array()
  let content_array = content.to_array()
  for i in 0..<content_array.length() {
    payload.push(content_array[i])
  }
  let remainder = content.length() % 512
  if remainder != 0 {
    let pad = 512 - remainder
    for _ in 0..<pad {
      payload.push(b'\x00')
    }
  }
  Bytes::from_array(payload)
}

///|
fn tar_archive(entries : Array[(String, Bytes)]) -> Bytes {
  let out : Array[Byte] = []
  for i in 0..<entries.length() {
    let (name, content) = entries[i]
    let entry_bytes = tar_entry(name, content).to_array()
    for j in 0..<entry_bytes.length() {
      out.push(entry_bytes[j])
    }
  }
  for _ in 0..<1024 {
    out.push(b'\x00')
  }
  Bytes::from_array(out)
}
