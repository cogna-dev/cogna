///|
pub fn upload(
  upload_request : Json,
) -> Result[@registry_lib.UploadResult, @cli.CliError] {
  upload_local(upload_request)
}

///|
pub fn download_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  download_local_by_purl(purl)
}
