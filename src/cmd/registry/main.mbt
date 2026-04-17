///|
pub(all) struct RegistryUploadParams {
  upload_request_file : String
} derive(Eq)

///|
pub impl Show for RegistryUploadParams with output(self, logger) {
  logger.write_string("{upload_request_file: ")
  logger.write_object(self.upload_request_file)
  logger.write_char('}')
}

///|
pub(all) struct RegistryDownloadParams {
  purl : String
} derive(Eq)

///|
pub impl Show for RegistryDownloadParams with output(self, logger) {
  logger.write_string("{purl: ")
  logger.write_object(self.purl)
  logger.write_char('}')
}

///|
pub(all) struct RegistryDownloadBundleParams {
  purl : String
  output_dir : String
} derive(Eq)

///|
pub impl Show for RegistryDownloadBundleParams with output(self, logger) {
  logger.write_string("{purl: ")
  logger.write_object(self.purl)
  logger.write_string(", output_dir: ")
  logger.write_object(self.output_dir)
  logger.write_char('}')
}

///|
pub(all) struct RegistryServeParams {
  port : Int
} derive(Eq)

///|
pub impl Show for RegistryServeParams with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_char('}')
}

///|
pub(all) struct RegistryStatusResult {
  status : String
  summary : String
} derive(Eq)

///|
pub impl Show for RegistryStatusResult with output(self, logger) {
  logger.write_string("{status: ")
  logger.write_object(self.status)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub(all) struct RegistryUploadCliResult {
  upload_request_file : String
  receipt : Json
  summary : String
} derive(Eq)

///|
pub impl Show for RegistryUploadCliResult with output(self, logger) {
  logger.write_string("{upload_request_file: ")
  logger.write_object(self.upload_request_file)
  logger.write_string(", receipt: ")
  logger.write_object(self.receipt)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub(all) struct RegistryDownloadCliResult {
  purl : String
  response : Json
  summary : String
} derive(Eq)

///|
pub impl Show for RegistryDownloadCliResult with output(self, logger) {
  logger.write_string("{purl: ")
  logger.write_object(self.purl)
  logger.write_string(", response: ")
  logger.write_object(self.response)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub(all) struct RegistryDownloadBundleCliResult {
  purl : String
  bundle_file : String
  output_dir : String
  summary : String
} derive(Eq)

///|
pub impl Show for RegistryDownloadBundleCliResult with output(self, logger) {
  logger.write_string("{purl: ")
  logger.write_object(self.purl)
  logger.write_string(", bundle_file: ")
  logger.write_object(self.bundle_file)
  logger.write_string(", output_dir: ")
  logger.write_object(self.output_dir)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub(all) struct RegistryServeResult {
  port : Int
  summary : String
} derive(Eq)

///|
pub impl Show for RegistryServeResult with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
struct RegistryDescriptor {
  path : String
  info : Json
} derive(Eq)

///|
pub impl Show for RegistryDescriptor with output(self, logger) {
  logger.write_string("{path: ")
  logger.write_object(self.path)
  logger.write_string(", info: ")
  logger.write_object(self.info)
  logger.write_char('}')
}

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
pub impl @cli.Display for RegistryServeResult with display(
  self : RegistryServeResult,
) -> String {
  self.summary
}

///|
pub impl @cli.Display for RegistryStatusResult with display(
  self : RegistryStatusResult,
) -> String {
  self.summary
}

///|
fn registry_error(message : String) -> @cli.CliError {
  @cli.command_error("registry failed: \{message}")
}

// Re-export public API from src/registry for consumers that import cmd/registry.
// Tests in main_test.mbt call these directly.

///|
pub fn upload_local(
  upload_request : Json,
) -> Result[@client.UploadResult, @cli.CliError] {
  @registry_impl.upload_local(upload_request)
}

///|
pub fn download_local_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  @registry_impl.download_local_by_purl(purl)
}

///|
pub fn download_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  @registry_impl.download_by_purl(purl)
}

///|
pub fn upload(
  upload_request : Json,
) -> Result[@client.UploadResult, @cli.CliError] {
  @registry_impl.upload(upload_request)
}

///|
pub fn api_upload(
  upload_request : Json,
) -> Result[@client.RegistryApiResponse, @cli.CliError] {
  @registry_impl.api_upload(upload_request)
}

///|
pub fn api_resolve(
  purl : String,
  if_none_match : String?,
) -> Result[@client.RegistryApiResponse, @cli.CliError] {
  @registry_impl.api_resolve(purl, if_none_match)
}

///|
pub fn ensure_sha256_digest(
  digest : String,
  context : String,
) -> Result[Unit, @cli.CliError] {
  @registry_impl.ensure_sha256_digest(digest, context)
}

///|
pub fn registry_health_path() -> String {
  @client.health_path()
}

///|
pub fn registry_server_base_url(port : Int) -> String {
  @registry_impl.registry_server_base_url(port)
}

///|
pub fn registry_health_url(port : Int) -> String {
  join_url(registry_server_base_url(port), registry_health_path())
}

///|
fn registry_descriptor_path() -> String {
  "./dist/registry-server.json"
}

///|
fn ensure_dist_dir() -> Result[Unit, @cli.CliError] {
  if @fs.path_exists("./dist") {
    Ok(())
  } else {
    @fs.create_dir("./dist") catch {
      err =>
        return Err(
          registry_error("cannot create ./dist directory: \{err.to_string()}"),
        )
    }
    Ok(())
  }
}

///|
fn registry_server_info(port : Int) -> Json {
  {
    "schemaVersion": "cogna-registry-descriptor/v1",
    "name": "cogna-registry",
    "transport": "http",
    "port": port,
    "pid": Json::null(),
    "baseUrl": registry_server_base_url(port),
    "healthUrl": registry_health_url(port),
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
fn write_registry_info(
  path : String,
  info : Json,
) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, info.stringify(indent=2)) catch {
    err =>
      return Err(
        registry_error("cannot write descriptor \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
fn read_registry_info(
  path : String,
) -> Result[RegistryDescriptor, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(
        registry_error("cannot read descriptor \{path}: \{err.to_string()}"),
      )
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(info) else {
    return Err(registry_error("descriptor is not valid json: \{path}"))
  }
  Ok({ path, info })
}

///|
fn cleanup_descriptor(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn descriptor_port(info : Json) -> Int? {
  guard info is Object(object) else { return None }
  match object.get("port") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}

///|
fn descriptor_string(info : Json, field : String) -> String? {
  guard info is Object(object) else { return None }
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
}

///|
fn descriptor_health_url(info : Json, port : Int) -> String {
  match descriptor_string(info, "healthUrl") {
    Some(url) => url
    None => registry_health_url(port)
  }
}

///|
fn wait_for_health(
  url : String,
  attempts? : Int = 20,
  sleep_ms? : Int = 100,
) -> Bool {
  for _ in 0..<attempts {
    let request_out = @client.http_request(
      "GET",
      url,
      {},
      @client.HttpBody::Empty,
    )
    match request_out {
      Ok(result) => if result.status == 200 { return true }
      Err(_) => ()
    }
    @process.sleep_ms(sleep_ms)
  }
  false
}

///|
pub fn run_serve(
  params : RegistryServeParams,
) -> @cli.CliResult[RegistryServeResult, @cli.CliError] {
  if params.port <= 0 || params.port > 65535 {
    return Err(registry_error("port must be in range 1..65535"))
  }
  let dist_out = ensure_dist_dir()
  guard dist_out is Ok(_) else { return Err(dist_out.unwrap_err()) }
  let descriptor_path = registry_descriptor_path()
  let write_out = write_registry_info(
    descriptor_path,
    registry_server_info(params.port),
  )
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }
  let serve_out = @registry_impl.serve_registry(params.port)
  guard serve_out is Ok(_) else {
    cleanup_descriptor(descriptor_path)
    return Err(serve_out.unwrap_err())
  }
  cleanup_descriptor(descriptor_path)
  Ok({
    port: params.port,
    summary: "Serving registry API at \{registry_server_base_url(params.port)}",
  })
}

///|
pub fn run_status() -> @cli.CliResult[RegistryStatusResult, @cli.CliError] {
  let info_path = registry_descriptor_path()
  if !@fs.path_exists(info_path) {
    return Ok({
      status: "stopped",
      summary: "Registry descriptor not found (expected \{info_path})",
    })
  }
  let info_out = read_registry_info(info_path)
  guard info_out is Ok(descriptor) else { return Err(info_out.unwrap_err()) }
  let port = descriptor_port(descriptor.info).unwrap_or(0)
  let health_url = descriptor_health_url(descriptor.info, port)
  if wait_for_health(health_url, attempts=1, sleep_ms=0) {
    Ok({
      status: "running",
      summary: "Registry server healthy at \{health_url}",
    })
  } else {
    Ok({
      status: "stopped",
      summary: "Registry descriptor found at \{info_path} but server is not healthy",
    })
  }
}

///|
pub fn run_upload_local(
  params : RegistryUploadParams,
) -> @cli.CliResult[RegistryUploadCliResult, @cli.CliError] {
  let request_out = @registry_impl.read_json_file(params.upload_request_file)
  guard request_out is Ok(request) else { return Err(request_out.unwrap_err()) }

  let upload_out = upload_local(request)
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
  let download_out = download_local_by_purl(params.purl)
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
  guard response_object.get("downloadUrl") is Some(String(download_url)) else {
    return Err(registry_error("missing required string field downloadUrl"))
  }
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
