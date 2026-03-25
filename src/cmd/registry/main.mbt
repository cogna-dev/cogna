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
pub(all) struct RegistryServeParams {
  port : Int
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
pub(all) struct RegistryServeResult {
  port : Int
  summary : String
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
pub impl @cli.Display for RegistryServeResult with display(
  self : RegistryServeResult,
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
) -> Result[@registry_lib.UploadResult, @cli.CliError] {
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
) -> Result[@registry_lib.UploadResult, @cli.CliError] {
  @registry_impl.upload(upload_request)
}

///|
pub fn api_upload(
  upload_request : Json,
) -> Result[@registry_lib.RegistryApiResponse, @cli.CliError] {
  @registry_impl.api_upload(upload_request)
}

///|
pub fn api_resolve(
  purl : String,
  if_none_match : String?,
) -> Result[@registry_lib.RegistryApiResponse, @cli.CliError] {
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
  @registry_lib.health_path()
}

///|
pub fn registry_server_base_url(port : Int) -> String {
  @registry_impl.registry_server_base_url(port)
}

///|
pub fn registry_health_url(port : Int) -> String {
  @server_runtime.join_url(
    registry_server_base_url(port),
    registry_health_path(),
  )
}

///|
pub fn run_serve(
  params : RegistryServeParams,
) -> @cli.CliResult[RegistryServeResult, @cli.CliError] {
  if params.port <= 0 || params.port > 65535 {
    return Err(registry_error("port must be in range 1..65535"))
  }
  let serve_out = @registry_impl.serve_registry(params.port)
  guard serve_out is Ok(_) else { return Err(serve_out.unwrap_err()) }
  Ok({
    port: params.port,
    summary: "Serving registry API at \{registry_server_base_url(params.port)}",
  })
}

///|
pub fn run_upload_local(
  params : RegistryUploadParams,
) -> @cli.CliResult[RegistryUploadCliResult, @cli.CliError] {
  let request_out = @registry_impl.read_json_file(params.upload_request_file)
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
