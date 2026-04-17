///|
fn write_build_error(repo : String, message : String) -> Unit {
  ignore(@fs.write_string_to_file("\{repo}/sdk-build.error.log", message) catch {
    _ => ()
  })
}

///|
/// Build: establish queryable context for the current project.
pub fn build(req : @generated.BuildRequest) -> @generated.BuildResponse {
  ignore(req)
  let resolved_out = @config.resolve(".")
  guard resolved_out is Ok(resolved) else { return { success: false } }
  let dist_dir = "\{resolved.root_dir}/dist"
  if !@fs.path_exists(dist_dir) {
    ignore(@fs.create_dir(dist_dir) catch {
      err => {
        write_build_error(
          resolved.root_dir,
          "sdk build failed: cannot create dist dir \{dist_dir}: \{err.to_string()}",
        )
        return { success: false }
      }
    })
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
    ) catch {
      err => {
        write_build_error(
          resolved.root_dir,
          "sdk build failed: cannot write marker file \{dist_dir}/sdk-build.json: \{err.to_string()}",
        )
        return { success: false }
      }
    },
  )
  { success: true }
}
