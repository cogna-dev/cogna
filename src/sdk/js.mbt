///|
pub fn build_js(req : @generated.BuildRequest) -> @generated.BuildResponse {
  ignore(req)
  { success: false }
}

///|
pub fn diff_js(req : @generated.DiffRequest) -> @generated.DiffResponse? {
  diff(req)
}

///|
pub fn fetch_packages_js(
  req : @generated.FetchPackagesRequest,
) -> @generated.FetchPackagesResponse? {
  fetch_packages(req)
}

///|
pub fn query_outlines_js(
  req : @generated.QueryOutlinesRequest,
) -> @generated.QueryOutlinesResponse? {
  query_outlines(req)
}

///|
pub fn query_js(req : @generated.QueryRequest) -> @generated.QueryResponse? {
  query(req)
}
