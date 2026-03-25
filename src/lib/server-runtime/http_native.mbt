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
pub fn http_request_impl(
  http_method : String,
  url : String,
  headers : Map[String, String],
  body : HttpBody,
) -> Result[HttpResult, String] {
  let result : Ref[Result[HttpResult, String]?] = Ref::new(None)
  @async.run_async_main(() => {
    let value = match base_and_path(url) {
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
pub fn serve_http_impl(
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
