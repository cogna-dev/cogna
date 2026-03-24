///|
pub(all) struct MethodContext {
  id : Json
  method_name : String
  params : Json
}

///|
pub fn route_request(
  request : Json,
  on_method : (MethodContext) -> Json,
) -> Json {
  let extracted = extract_method(request)
  guard extracted is Ok((id, method_name, params)) else {
    let (err_id, code, message) = extracted.unwrap_err()
    return error_response(err_id, code, message)
  }
  on_method({ id, method_name, params })
}
