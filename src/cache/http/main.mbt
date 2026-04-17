// ── HTTP cache client using mapi ApiClient ──────────────────────────────────

///|
fn app_error_message(err : @mapi.AppError) -> String {
  match err {
    @mapi.AppError::NotFound(msg) => msg
    @mapi.AppError::BadRequest(msg) => msg
    @mapi.AppError::Unauthorized => "unauthorized"
    @mapi.AppError::Forbidden => "forbidden"
    @mapi.AppError::Internal(msg) => msg
  }
}

///|
fn make_async_transport(base_url : String) -> @generated.ApiTransport {
  {
    send: fn(req) {
      let out : Ref[Result[@mapi.ResponseEnvelope, @mapi.AppError]?] = Ref::new(
        None,
      )
      @mbasync.run_async_main(async fn() {
        let value = try {
          let client = @async_http.Client::new(base_url)
          let req_method = match req.http_method {
            @mapi.HttpMethod::Get => @async_http.RequestMethod::Get
            @mapi.HttpMethod::Put => @async_http.RequestMethod::Put
            @mapi.HttpMethod::Post => @async_http.RequestMethod::Post
            @mapi.HttpMethod::Delete => @async_http.RequestMethod::Delete
            @mapi.HttpMethod::Head => @async_http.RequestMethod::Head
            @mapi.HttpMethod::Options => @async_http.RequestMethod::Options
            @mapi.HttpMethod::Patch => @async_http.RequestMethod::Patch
          }
          let path = if req.query.is_empty() {
            req.path
          } else {
            let pairs : Array[String] = []
            for key, values in req.query {
              for value in values {
                pairs.push("\{url_encode(key)}=\{url_encode(value)}")
              }
            }
            let sep = "&"
            "\{req.path}?\{pairs.join(sep)}"
          }
          client.request(req_method, path, extra_headers=req.headers)
          match req.body {
            Some(body) => client.write(body)
            None => ()
          }
          let response = client.end_request()
          let response_body = client.read_all().binary()
          client.close()
          Ok(
            (
              {
                status: response.code,
                headers: response.headers,
                body: Some(response_body),
              } : @mapi.ResponseEnvelope
            ),
          )
        } catch {
          err =>
            Err(
              (
                @mapi.AppError::Internal(err.to_string()) : @mapi.AppError
              ),
            )
        }
        out.val = Some(value)
      })
      match out.val {
        Some(value) => value
        None =>
          Err(@mapi.AppError::Internal("async http request did not complete"))
      }
    },
  }
}

// ── URL utilities ──────────────────────────────────────────────────────────────

///|
fn hex_digit(value : Int) -> String {
  if value < 10 {
    "\{value}"
  } else {
    match value {
      10 => "A"
      11 => "B"
      12 => "C"
      13 => "D"
      14 => "E"
      _ => "F"
    }
  }
}

///|
fn url_encode(value : String) -> String {
  let bytes = @utf8.encode(value)
  let encoded = StringBuilder::new()
  for i in 0..<bytes.length() {
    let byte = bytes[i].to_int()
    let keep = (byte >= 'a'.to_int() && byte <= 'z'.to_int()) ||
      (byte >= 'A'.to_int() && byte <= 'Z'.to_int()) ||
      (byte >= '0'.to_int() && byte <= '9'.to_int()) ||
      byte == '-'.to_int() ||
      byte == '_'.to_int() ||
      byte == '.'.to_int() ||
      byte == '~'.to_int()
    if keep {
      encoded.write_char(byte.unsafe_to_char())
    } else {
      encoded.write_char('%')
      encoded.write_string(hex_digit(byte / 16))
      encoded.write_string(hex_digit(byte % 16))
    }
  }
  encoded.to_string()
}

///|
fn ascii_lower_char(char : Char) -> Char {
  if char >= 'A' && char <= 'Z' {
    Int::unsafe_to_char(char.to_int() + 32)
  } else {
    char
  }
}

///|
fn ascii_lower(text : String) -> String {
  let out = StringBuilder::new()
  for char in text {
    out.write_char(ascii_lower_char(char))
  }
  out.to_string()
}

///|
fn header_value(headers : Map[String, String], key : String) -> String? {
  let target = ascii_lower(key)
  for name, value in headers {
    if ascii_lower(name) == target {
      return Some(value)
    }
  }
  None
}

// ── Cache API using mapi ApiClient ─────────────────────────────────────────────

///|
pub fn make_client(base_url : String) -> @generated.ApiClient {
  @generated.ApiClient::new(make_async_transport(base_url))
}

///|
pub fn get(base_url : String, key : String) -> Result[@cache.CacheObject?, String] {
  let client = make_client(base_url)
  let result = client.get_object({ key, })
  match result {
    Ok(_) => {
      // The generated client doesn't return body/headers — use raw transport
      let transport = make_async_transport(base_url)
      let req : @mapi.RequestEnvelope = {
        http_method: @mapi.HttpMethod::Get,
        path: "/cache/v1/object",
        query: { "key": [key] },
        headers: {},
        body: None,
      }
      match (transport.send)(req) {
        Ok(resp) => {
          if resp.status == 404 {
            return Ok(None)
          }
          if resp.status != 200 {
            return Err("http cache get failed with status \{resp.status}")
          }
          let body = resp.body.unwrap_or(b"")
          let content_type = match header_value(resp.headers, "Content-Type") {
            Some(value) if value != "" => value
            _ => @cache.default_content_type()
          }
          let digest = match header_value(resp.headers, "X-Cogna-Digest") {
            Some(value) if value != "" => value
            _ => @sha256.sha256_hexdigest(body)
          }
          Ok(Some({ key, body, content_type, digest }))
        }
        Err(err) => Err(app_error_message(err))
      }
    }
    Err(err) => {
      match err {
        @mapi.AppError::NotFound(_) => Ok(None)
        _ => Err(app_error_message(err))
      }
    }
  }
}

///|
pub fn put(
  base_url : String,
  object : @cache.CacheObject,
) -> Result[Unit, String] {
  let transport = make_async_transport(base_url)
  let req : @mapi.RequestEnvelope = {
    http_method: @mapi.HttpMethod::Put,
    path: "/cache/v1/object",
    query: { "key": [object.key] },
    headers: {
      "Content-Type": object.content_type,
      "X-Cogna-Digest": object.digest,
    },
    body: Some(object.body),
  }
  match (transport.send)(req) {
    Ok(resp) =>
      if resp.status == 200 || resp.status == 201 {
        Ok(())
      } else {
        Err("http cache put failed with status \{resp.status}")
      }
    Err(err) => Err(app_error_message(err))
  }
}
