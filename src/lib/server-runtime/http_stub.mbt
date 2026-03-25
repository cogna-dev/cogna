///|
pub fn http_request_impl(
  http_method : String,
  url : String,
  headers : Map[String, String],
  body : HttpBody,
) -> Result[HttpResult, String] {
  ignore(http_method)
  ignore(url)
  ignore(headers)
  ignore(body)
  Err("http runtime is unsupported on this target")
}

///|
pub fn serve_http_impl(
  port : Int,
  handler : (String, String, Map[String, String], Bytes) -> Result[
    HttpResponse,
    String,
  ],
) -> Result[Unit, String] {
  ignore(port)
  ignore(handler)
  Err("http runtime is unsupported on this target")
}
