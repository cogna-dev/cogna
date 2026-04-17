///|
pub(all) struct ServeParams {
  port : Int
} derive(Eq)

///|
pub impl Show for ServeParams with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_char('}')
}

///|
pub(all) struct ServeResult {
  port : Int
  summary : String
} derive(Eq)

///|
pub impl Show for ServeResult with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for ServeResult with display(self : ServeResult) -> String {
  self.summary
}

///|
fn serve_error(message : String) -> @cli.CliError {
  @cli.command_error("serve failed: \{message}")
}

///|
fn request_method_from_string(
  http_method : String,
) -> Result[@mapi.HttpMethod, String] {
  match http_method.to_upper() {
    "GET" => Ok(@mapi.HttpMethod::Get)
    "POST" => Ok(@mapi.HttpMethod::Post)
    "PUT" => Ok(@mapi.HttpMethod::Put)
    "DELETE" => Ok(@mapi.HttpMethod::Delete)
    "HEAD" => Ok(@mapi.HttpMethod::Head)
    "OPTIONS" => Ok(@mapi.HttpMethod::Options)
    "PATCH" => Ok(@mapi.HttpMethod::Patch)
    _ => Err("unsupported http method: \{http_method}")
  }
}

///|
fn status_reason(status : Int) -> String {
  match status {
    200 => "OK"
    201 => "Created"
    204 => "No Content"
    400 => "Bad Request"
    404 => "Not Found"
    405 => "Method Not Allowed"
    500 => "Internal Server Error"
    503 => "Service Unavailable"
    _ => "OK"
  }
}

///|
fn json_response(status : Int, body : Json) -> @mapi.ResponseEnvelope {
  {
    status,
    headers: { "Content-Type": "application/json" },
    body: Some(@utf8.encode(body.stringify())),
  }
}

///|
fn query_string_to_map(query : String) -> Map[String, Array[String]] {
  let query_map : Map[String, Array[String]] = {}
  if query == "" {
    return query_map
  }
  for pair in query.split("&") {
    if pair == "" {
      continue
    }
    let parts = pair.split("=").to_array()
    let key = parts[0].to_string()
    if key == "" {
      continue
    }
    let value = if parts.length() >= 2 { parts[1].to_string() } else { "" }
    match query_map.get(key) {
      Some(values) => values.push(value)
      None => query_map[key] = [value]
    }
  }
  query_map
}

///|
fn request_path_only(path : String) -> String {
  match path.find("?") {
    Some(index) => path[:index].to_string()
    None => path
  }
}

///|
fn request_query_string(path : String) -> String {
  match path.find("?") {
    Some(index) => path[index + 1:].to_string()
    None => ""
  }
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
fn hex_value(code : UInt16) -> Int? {
  if code >= '0' && code <= '9' {
    Some(code.to_int() - '0')
  } else if code >= 'A' && code <= 'F' {
    Some(code.to_int() - 'A' + 10)
  } else if code >= 'a' && code <= 'f' {
    Some(code.to_int() - 'a' + 10)
  } else {
    None
  }
}

///|
fn url_decode(value : String) -> Result[String, String] {
  let out : Array[Byte] = []
  let mut i = 0
  while i < value.length() {
    let code = value[i]
    if code == '%' {
      if i + 2 >= value.length() {
        return Err("invalid percent-encoding: \{value}")
      }
      let hi = hex_value(value[i + 1]).unwrap_or(-1)
      let lo = hex_value(value[i + 2]).unwrap_or(-1)
      if hi < 0 || lo < 0 {
        return Err("invalid percent-encoding: \{value}")
      }
      out.push((hi * 16 + lo).to_byte())
      i += 3
    } else {
      out.push(code.to_int().to_byte())
      i += 1
    }
  }
  let decoded = @utf8.decode(Bytes::from_array(out)) catch {
    _ => return Err("invalid utf-8 in decoded url")
  }
  Ok(decoded)
}

///|
fn query_value(req : @mapi.RequestEnvelope, key : String) -> String? {
  match req.query.get(key) {
    Some(values) if values.length() > 0 => {
      match url_decode(values[0]) {
        Ok(value) => Some(value)
        Err(_) => None
      }
    }
    _ => None
  }
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

///|
fn resolved_local_store_dir(resolved : @config.ResolvedConfig) -> String {
  @config.resolve_project_path(
    resolved.root_dir,
    resolved.config.cache.local_store.store_dir,
  )
}

///|
fn backend_get(
  resolved : @config.ResolvedConfig,
  key : String,
) -> Result[@cache.CacheObject?, String] {
  match resolved.config.cache.type_ {
    "local" => @local_cache.get(resolved_local_store_dir(resolved), key)
    "http" => @http_cache.get(resolved.config.cache.http.base_url, key)
    other => Err("unsupported cache backend: \{other}")
  }
}

///|
fn backend_put(
  resolved : @config.ResolvedConfig,
  object : @cache.CacheObject,
) -> Result[Unit, String] {
  match resolved.config.cache.type_ {
    "local" => {
      let out = @local_cache.put(
        resolved_local_store_dir(resolved),
        object.key,
        object.body,
        content_type=object.content_type,
      )
      guard out is Ok(_) else { return Err(out.unwrap_err()) }
      Ok(())
    }
    "http" => @http_cache.put(resolved.config.cache.http.base_url, object)
    other => Err("unsupported cache backend: \{other}")
  }
}

// ── Custom route handlers (since generated router doesn't wire typed handlers) ──

///|
fn build_app(
  resolved : @config.ResolvedConfig,
  port : Int,
) -> @mapi.App {
  let router = @mapi.Router::new()
  router.add({
    http_method: @mapi.HttpMethod::Get,
    pattern: "/health",
    handler: fn(_ctx, _req, _params) {
      json_response(200, {
        "status": "ok",
        "service": "cogna-cache-proxy",
        "backend": resolved.config.cache.type_,
        "port": port,
      })
    },
  })
  router.add({
    http_method: @mapi.HttpMethod::Get,
    pattern: "/cache/v1/object",
    handler: fn(_ctx, req, _params) {
      let key = query_value(req, "key")
      guard key is Some(cache_key) && cache_key != "" else {
        return json_response(400, { "error": "query parameter 'key' is required" })
      }
      let out = backend_get(resolved, cache_key)
      guard out is Ok(cached) else {
        return json_response(500, { "error": out.unwrap_err() })
      }
      match cached {
        Some(object) => {
          let headers : Map[String, String] = {
            "Content-Type": object.content_type,
            "X-Cogna-Digest": object.digest,
          }
          { status: 200, headers, body: Some(object.body) }
        }
        None => json_response(404, { "error": "cache object not found" })
      }
    },
  })
  router.add({
    http_method: @mapi.HttpMethod::Put,
    pattern: "/cache/v1/object",
    handler: fn(_ctx, req, _params) {
      let key = query_value(req, "key")
      guard key is Some(cache_key) && cache_key != "" else {
        return json_response(400, { "error": "query parameter 'key' is required" })
      }
      let body = req.body.unwrap_or(b"")
      let content_type = match header_value(req.headers, "Content-Type") {
        Some(value) if value != "" => value
        _ => @cache.default_content_type()
      }
      let digest = match header_value(req.headers, "X-Cogna-Digest") {
        Some(value) if value != "" => value
        _ => @sha256.sha256_hexdigest(body)
      }
      let object : @cache.CacheObject = { key: cache_key, body, content_type, digest }
      let out = backend_put(resolved, object)
      guard out is Ok(_) else {
        return json_response(500, { "error": out.unwrap_err() })
      }
      json_response(201, {
        "status": "stored",
        "key": cache_key,
        "digest": digest,
      })
    },
  })
  @mapi.App::new(router)
}

// ── Test helpers ────────────────────────────────────────────────────────────────

// ── Server bootstrap ────────────────────────────────────────────────────────────

///|
fn serve_http(resolved : @config.ResolvedConfig, port : Int) -> Result[Unit, @cli.CliError] {
  let serve_out : Ref[Result[Unit, String]?] = Ref::new(None)
  @mbasync.run_async_main(() => {
    let value = try {
      let app = build_app(resolved, port)
      let server = @http.Server::new(
        @socket.Addr::parse("127.0.0.1:\{port}"),
        reuse_addr=true,
      )
      while true {
        let (conn, _) = server.accept()
        let request = conn.read_request()
        let request_body = conn.read_all().binary()
        let method_out = request_method_from_string(@debug.to_string(request.meth).to_upper())
        let response = match method_out {
          Ok(http_method) =>
            app.serve({
              http_method,
              path: request_path_only(request.path),
              query: query_string_to_map(request_query_string(request.path)),
              headers: request.headers,
              body: Some(request_body),
            })
          Err(message) => json_response(405, { "error": message })
        }
        conn.send_response(
          response.status,
          status_reason(response.status),
          extra_headers=response.headers,
        )
        match response.body {
          Some(bytes) => conn.write(bytes)
          None => ()
        }
        conn.end_response()
      }
      Ok(())
    } catch {
      err => Err(err.to_string())
    }
    serve_out.val = Some(value)
  })
  match serve_out.val {
    Some(Ok(_)) => Ok(())
    Some(Err(message)) => Err(serve_error(message))
    None => Err(serve_error("cache proxy did not produce result"))
  }
}

///|
pub fn run(params : ServeParams) -> @cli.CliResult[ServeResult, @cli.CliError] {
  if params.port <= 0 || params.port > 65535 {
    return Err(serve_error("port must be in range 1..65535"))
  }
  let resolved_out = @config.resolve(".")
  guard resolved_out is Ok(resolved) else {
    return Err(@cli.config_error(resolved_out.unwrap_err().to_string()))
  }
  let store_dir = resolved_local_store_dir(resolved)
  let serve_out = serve_http(resolved, params.port)
  guard serve_out is Ok(_) else { return Err(serve_out.unwrap_err()) }
  Ok({
    port: params.port,
    summary: "Serving cache proxy for backend \{resolved.config.cache.type_} on port \{params.port}; local store root is \{store_dir}",
  })
}
