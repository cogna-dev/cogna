///|
pub fn build_js(req : BuildRequest) -> BuildResponse {
  build(req)
}

///|
pub fn diff_js(req : DiffRequest) -> DiffResponse? {
  diff(req)
}

///|
pub fn fetch_packages_js(req : FetchPackagesRequest) -> FetchPackagesResponse? {
  fetch_packages(req)
}

///|
pub fn query_outlines_js(req : QueryOutlinesRequest) -> QueryOutlinesResponse? {
  query_outlines(req)
}

///|
pub fn query_js(req : QueryRequest) -> QueryResponse? {
  query(req)
}
