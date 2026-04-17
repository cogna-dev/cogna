///|
pub fn upload(
  upload_request : Json,
) -> Result[@client.UploadResult, @cli.CliError] {
  if @client.remote_registry_enabled() {
    @client.upload_remote(upload_request)
  } else {
    upload_local(upload_request)
  }
}

///|
pub fn download_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  if @client.remote_registry_enabled() {
    @client.download_remote_by_purl(purl)
  } else {
    download_local_by_purl(purl)
  }
}
