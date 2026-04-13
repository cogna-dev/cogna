///|
pub fn upload(
  upload_request : Json,
) -> Result[@registry_lib.UploadResult, @cli.CliError] {
  if @registry_lib.remote_registry_enabled() {
    @registry_lib.upload_remote(upload_request)
  } else {
    upload_local(upload_request)
  }
}

///|
pub fn download_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  if @registry_lib.remote_registry_enabled() {
    @registry_lib.download_remote_by_purl(purl)
  } else {
    download_local_by_purl(purl)
  }
}
