///|
pub(all) enum HttpBody {
  Empty
  Text(String)
  Json(Json)
  Binary(Bytes)
} derive(Eq)

///|
pub impl Show for HttpBody with output(self, logger) {
  match self {
    Empty => logger.write_string("Empty")
    Text(text) => {
      logger.write_string("Text(")
      logger.write_object(text)
      logger.write_char(')')
    }
    Json(payload) => {
      logger.write_string("Json(")
      logger.write_object(payload)
      logger.write_char(')')
    }
    Binary(bytes) => {
      logger.write_string("Binary(")
      logger.write_object(bytes)
      logger.write_char(')')
    }
  }
}

///|
pub(all) struct HttpResponse {
  status : Int
  headers : Map[String, String]
  body : HttpBody
} derive(Eq)

///|
pub impl Show for HttpResponse with output(self, logger) {
  logger.write_string("{status: ")
  logger.write_object(self.status)
  logger.write_string(", headers: ")
  logger.write_object(self.headers)
  logger.write_string(", body: ")
  logger.write_object(self.body)
  logger.write_char('}')
}

///|
pub(all) struct HttpResult {
  status : Int
  headers : Map[String, String]
  body : Bytes
} derive(Eq)

///|
pub impl Show for HttpResult with output(self, logger) {
  logger.write_string("{status: ")
  logger.write_object(self.status)
  logger.write_string(", headers: ")
  logger.write_object(self.headers)
  logger.write_string(", body: ")
  logger.write_object(self.body)
  logger.write_char('}')
}

///|
pub fn json_response(
  status : Int,
  body : Json,
  headers? : Map[String, String] = {},
) -> HttpResponse {
  let response_headers = headers
  if !response_headers.contains("Content-Type") {
    response_headers["Content-Type"] = "application/json"
  }
  { status, headers: response_headers, body: Json(body) }
}

///|
pub fn text_response(
  status : Int,
  body : String,
  headers? : Map[String, String] = {},
) -> HttpResponse {
  let response_headers = headers
  if !response_headers.contains("Content-Type") {
    response_headers["Content-Type"] = "text/plain; charset=utf-8"
  }
  { status, headers: response_headers, body: Text(body) }
}

///|
fn unsupported_http_runtime_message() -> String {
  let timer : @async.Timer? = None
  ignore(timer)
  ignore(@http.unimplemented)
  ignore(@socket.unimplemented)
  "http runtime is unsupported on this target"
}

///|
pub fn http_request(
  http_method : String,
  url : String,
  headers : Map[String, String],
  body : HttpBody,
) -> Result[HttpResult, String] {
  ignore(http_method)
  ignore(url)
  ignore(headers)
  ignore(body)
  Err(unsupported_http_runtime_message())
}

///|
pub fn serve_http(
  port : Int,
  handler : (String, String, Map[String, String], Bytes) -> Result[
    HttpResponse,
    String,
  ],
) -> Result[Unit, String] {
  ignore(port)
  ignore(handler)
  Err(unsupported_http_runtime_message())
}
