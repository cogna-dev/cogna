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
fn status_reason(status : Int) -> String {
  match status {
    200 => "OK"
    201 => "Created"
    202 => "Accepted"
    204 => "No Content"
    304 => "Not Modified"
    400 => "Bad Request"
    404 => "Not Found"
    405 => "Method Not Allowed"
    409 => "Conflict"
    500 => "Internal Server Error"
    503 => "Service Unavailable"
    _ => "OK"
  }
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
pub fn binary_response(
  status : Int,
  body : Bytes,
  headers? : Map[String, String] = {},
) -> HttpResponse {
  let response_headers = headers
  if !response_headers.contains("Content-Type") {
    response_headers["Content-Type"] = "application/octet-stream"
  }
  { status, headers: response_headers, body: Binary(body) }
}

///|
fn split_url(url : String) -> Result[(String, String), String] {
  let scheme_index = url.find("://")
  guard scheme_index is Some(index) else {
    return Err("url must include scheme: \{url}")
  }
  let host_start = index + 3
  let path_index = url[host_start:].to_string().find("/")
  match path_index {
    Some(relative) => {
      let absolute = host_start + relative
      Ok((url[:absolute].to_string(), url[absolute:].to_string()))
    }
    None => Ok((url, "/"))
  }
}

///|
pub fn json_body(result : HttpResult) -> Result[Json, String] {
  let text = @utf8.decode(result.body) catch {
    _ => return Err("http response body is not valid utf-8")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err("http response body is not valid json")
  }
  Ok(value)
}

///|
pub fn text_body(result : HttpResult) -> Result[String, String] {
  let text = @utf8.decode(result.body) catch {
    _ => return Err("http response body is not valid utf-8")
  }
  Ok(text)
}

///|
fn request_method(http_method : String) -> Result[@http.RequestMethod, String] {
  match http_method.to_upper() {
    "GET" => Ok(@http.RequestMethod::Get)
    "POST" => Ok(@http.RequestMethod::Post)
    "PUT" => Ok(@http.RequestMethod::Put)
    "DELETE" => Ok(@http.RequestMethod::Delete)
    "HEAD" => Ok(@http.RequestMethod::Head)
    "OPTIONS" => Ok(@http.RequestMethod::Options)
    "PATCH" => Ok(@http.RequestMethod::Patch)
    _ => Err("unsupported http method: \{http_method}")
  }
}

///|
pub fn http_request(
  http_method : String,
  url : String,
  headers : Map[String, String],
  body : HttpBody,
) -> Result[HttpResult, String] {
  let result : Ref[Result[HttpResult, String]?] = Ref::new(None)
  @async.run_async_main(() => {
    let value = match split_url(url) {
      Ok((base_url, path)) =>
        match request_method(http_method) {
          Ok(method_value) =>
            try {
              let client = @http.Client::new(base_url)
              client.request(method_value, path, extra_headers=headers)
              match body {
                Empty => ()
                Text(text) => client.write(text)
                Json(payload) => client.write(payload)
                Binary(bytes) => client.write(bytes)
              }
              let response = client.end_request()
              let response_body = client.read_all().binary()
              client.close()
              let result_value : HttpResult = {
                status: response.code,
                headers: response.headers,
                body: response_body,
              }
              Ok(result_value)
            } catch {
              err => Err(err.to_string())
            }
          Err(message) => Err(message)
        }
      Err(message) => Err(message)
    }
    result.val = Some(value)
  })
  match result.val {
    Some(value) => value
    None => Err("async http request did not produce result")
  }
}

///|
pub fn serve_http(
  port : Int,
  handler : (String, String, Map[String, String], Bytes) -> Result[
    HttpResponse,
    String,
  ],
) -> Result[Unit, String] {
  let result : Ref[Result[Unit, String]?] = Ref::new(None)
  @async.run_async_main(() => {
    let value = try {
      let server = @http.Server::new(
        @socket.Addr::parse("127.0.0.1:\{port}"),
        reuse_addr=true,
      )
      for i = 0; ; i = i + 1 {
        let (conn, _) = server.accept()
        let request = conn.read_request()
        let request_body = conn.read_all().binary()
        let response = match
          handler(
            request.meth.to_string().to_upper(),
            request.path,
            request.headers,
            request_body,
          ) {
          Ok(value) => value
          Err(message) => json_response(500, { "error": message })
        }
        conn.send_response(
          response.status,
          status_reason(response.status),
          extra_headers=response.headers,
        )
        match response.body {
          Empty => ()
          Text(text) => conn.write(text)
          Json(payload) => conn.write(payload)
          Binary(bytes) => conn.write(bytes)
        }
        conn.end_response()
        ignore(i)
      }
      Ok(())
    } catch {
      err => Err(err.to_string())
    }
    result.val = Some(value)
  })
  match result.val {
    Some(value) => value
    None => Ok(())
  }
}
