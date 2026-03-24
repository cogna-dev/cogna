///|
pub fn request_id(request : Json) -> Json {
  guard request is Object(request_object) else { return Json::null() }
  match request_object.get("id") {
    Some(id) => id
    _ => Json::null()
  }
}

///|
pub fn success_response(id : Json, result : Json) -> Json {
  { "jsonrpc": "2.0", "id": id, "result": result }
}

///|
pub fn error_response(id : Json, code : Int, message : String) -> Json {
  {
    "jsonrpc": "2.0",
    "id": id,
    "error": ({ "code": code, "message": message } : Json),
  }
}

///|
pub fn internal_error(id : Json, message : String) -> Json {
  error_response(id, -32603, message)
}

///|
pub fn extract_method(
  request : Json,
) -> Result[(Json, String, Json), (Json, Int, String)] {
  let id = request_id(request)
  guard request is Object(request_object) else {
    return Err((id, -32600, "invalid request: expected object"))
  }
  guard request_object.get("method") is Some(String(method_name)) else {
    return Err((id, -32600, "invalid request: missing method"))
  }
  let params : Json = match request_object.get("params") {
    Some(value) => value
    _ => Json::object({})
  }
  Ok((id, method_name, params))
}

///|
pub fn call_result(text : String, structured : Json, is_error : Bool) -> Json {
  {
    "content": [{ "type": "text", "text": text }],
    "structuredContent": structured,
    "isError": is_error,
  }
}
