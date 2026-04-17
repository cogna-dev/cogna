///|
/// Build: establish queryable context for the current project.
pub fn build(req : @generated.BuildRequest) -> @generated.BuildResponse {
  ignore(req)
  let resolved_out = @config.resolve(".")
  guard resolved_out is Ok(resolved) else { return { success: false } }
  let dist_dir = "\{resolved.root_dir}/dist"
  if !@fs.path_exists(dist_dir) {
    ignore(@fs.create_dir(dist_dir) catch { _ => return { success: false } })
  }
  let marker : Json = {
    "schemaVersion": "cogna-sdk-build/v1",
    "status": "ready",
    "repo": resolved.root_dir,
  }
  ignore(
    @fs.write_string_to_file(
      "\{dist_dir}/sdk-build.json",
      marker.stringify(indent=2),
    ) catch { _ => return { success: false } },
  )
  { success: true }
}
