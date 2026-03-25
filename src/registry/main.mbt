///|
fn use_inproc_registry() -> Bool {
  match @registry_lib.registry_base_url() {
    Some(base_url) =>
      @registry_lib.normalize_base_url(base_url) == "inproc://registry"
    None => false
  }
}

///|
pub fn upload(
  upload_request : Json,
) -> Result[@registry_lib.UploadResult, @cli.CliError] {
  if use_inproc_registry() {
    upload_local(upload_request)
  } else if @registry_lib.remote_registry_enabled() {
    @registry_lib.upload_remote(upload_request)
  } else {
    upload_local(upload_request)
  }
}

///|
pub fn download_by_purl(purl : String) -> Result[Json, @cli.CliError] {
  if use_inproc_registry() {
    download_local_by_purl(purl)
  } else if @registry_lib.remote_registry_enabled() {
    @registry_lib.download_remote_by_purl(purl)
  } else {
    download_local_by_purl(purl)
  }
}
