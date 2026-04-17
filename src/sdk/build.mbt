///|
/// Build: establish queryable context for the current project.
pub fn build(req : @generated.BuildRequest) -> @generated.BuildResponse {
  ignore(req)
  let resolved_out = @config.resolve(".")
  guard resolved_out is Ok(resolved) else { return { success: false } }
  let build_out = @build.run({ repo: resolved.root_dir })
  { success: build_out is Ok(_) }
}
