// Thin SDK wrappers over src/core implementations.
// All business logic lives in @core; this file only converts proto types and delegates.

///|
/// Build: establish queryable context for the current project.
pub fn build(req : BuildRequest) -> BuildResponse {
  ignore(req)
  { success: @core.build() }
}

///|
/// Diff: compare current project against a baseline.
pub fn diff(req : DiffRequest) -> DiffResponse? {
  let include_test = match req.include_test_changes {
    Some(v) => v
    None => false
  }
  let j = @core.diff(req.base, req.target, include_test)
  DiffResponse::from_json(j)
}

///|
/// FetchPackages: return the package tree for the current project.
pub fn fetch_packages(req : FetchPackagesRequest) -> FetchPackagesResponse? {
  ignore(req)
  let j = @core.fetch_packages()
  FetchPackagesResponse::from_json(j)
}

///|
/// QueryOutlines: return public API outlines for the given package.
pub fn query_outlines(req : QueryOutlinesRequest) -> QueryOutlinesResponse? {
  let j = @core.query_outlines_for_package(req.package)
  QueryOutlinesResponse::from_json(j)
}

///|
/// Query: exact or fuzzy search over a package's public API.
pub fn query(req : QueryRequest) -> QueryResponse? {
  let j = @core.query_package(
    req.package,
    req.exact_id,
    req.exact_symbol,
    req.text,
    req.limit,
    req.cursor,
  )
  QueryResponse::from_json(j)
}
