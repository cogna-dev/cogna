///|
pub(all) enum HttpBody {
  Empty
  Text(String)
  Json(Json)
  Binary(Bytes)
} derive(Show, Eq)

///|
pub(all) struct HttpResponse {
  status : Int
  headers : Map[String, String]
  body : HttpBody
} derive(Show, Eq)

///|
pub(all) struct HttpResult {
  status : Int
  headers : Map[String, String]
  body : Bytes
} derive(Show, Eq)

///|
pub(all) struct ServiceDescriptor {
  path : String
  info : Json
} derive(Show, Eq)

///|
pub fn status_reason(status : Int) -> String {
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
pub fn empty_response(
  status : Int,
  headers? : Map[String, String] = {},
) -> HttpResponse {
  { status, headers, body: Empty }
}

///|
pub fn write_descriptor(path : String, info : Json) -> Result[Unit, String] {
  @fs.write_string_to_file(path, info.stringify(indent=2)) catch {
    err => return Err("cannot write descriptor \{path}: \{err.to_string()}")
  }
  Ok(())
}

///|
pub fn read_descriptor(path : String) -> Result[ServiceDescriptor, String] {
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read descriptor \{path}: \{err.to_string()}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(info) else {
    return Err("descriptor is not valid json: \{path}")
  }
  Ok({ path, info })
}

///|
pub fn descriptor_pid(info : Json) -> Int? {
  guard info is Object(object) else { return None }
  match object.get("pid") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}

///|
pub fn descriptor_port(info : Json) -> Int? {
  guard info is Object(object) else { return None }
  match object.get("port") {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}

///|
pub fn descriptor_string(info : Json, field : String) -> String? {
  guard info is Object(object) else { return None }
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
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
pub fn join_url(base_url : String, path : String) -> String {
  if path == "" || path == "/" {
    return base_url
  }
  if base_url.has_suffix("/") && path.has_prefix("/") {
    base_url[:base_url.length() - 1].to_string() + path
  } else if !base_url.has_suffix("/") && !path.has_prefix("/") {
    "\{base_url}/\{path}"
  } else {
    base_url + path
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
pub fn wait_for_health(
  url : String,
  attempts? : Int = 20,
  sleep_ms? : Int = 100,
) -> Bool {
  for _ in 0..<attempts {
    let request_out = http_request("GET", url, {}, Empty)
    match request_out {
      Ok(result) => if result.status == 200 { return true }
      Err(_) => ()
    }
    @shell.sleep_ms(sleep_ms)
  }
  false
}

///|
pub fn base_and_path(url : String) -> Result[(String, String), String] {
  split_url(url)
}

///|
pub fn http_request(
  http_method : String,
  url : String,
  headers : Map[String, String],
  body : HttpBody,
) -> Result[HttpResult, String] {
  http_request_impl(http_method, url, headers, body)
}

///|
pub fn serve_http(
  port : Int,
  handler : (String, String, Map[String, String], Bytes) -> Result[
    HttpResponse,
    String,
  ],
) -> Result[Unit, String] {
  serve_http_impl(port, handler)
}
