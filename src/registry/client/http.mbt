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
  @mbasync.run_async_main(() => {
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
