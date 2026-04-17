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
fn json_response_envelope(
  status : Int,
  headers : Map[String, String],
  body : Json,
) -> @mapi.ResponseEnvelope {
  if !headers.contains("Content-Type") {
    headers["Content-Type"] = "application/json"
  }
  { status, headers, body: Some(@utf8.encode(body.stringify())) }
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
fn request_path_with_query(req : @mapi.RequestEnvelope) -> String {
  if req.query.is_empty() {
    req.path
  } else {
    let pairs : Array[String] = []
    for key, values in req.query {
      if values.is_empty() {
        pairs.push(key)
      } else {
        for value in values {
          pairs.push("\{key}=\{value}")
        }
      }
    }
    if pairs.is_empty() {
      req.path
    } else {
      let query = pairs.join("&")
      "\{req.path}?\{query}"
    }
  }
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
fn parse_json_request(body : Bytes) -> Result[Json, String] {
  let text = @utf8.decode(body) catch {
    _ => return Err("http request body is not valid utf-8")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err("http request body is not valid json")
  }
  Ok(value)
}

///|
fn rewrite_download_url_for_server(body : Json, port : Int) -> Json {
  guard body is Object(body_object) else { return body }
  match @client.string_field_optional(body_object, "bundleId") {
    Some(bundle_id) =>
      body_object["downloadUrl"] = Json::string(
        server_bundle_download_url(port, bundle_id),
      )
    None => ()
  }
  body
}

///|
pub fn as_http_json_response(
  port : Int,
  response_out : Result[@client.RegistryApiResponse, @cli.CliError],
) -> Result[(Int, Map[String, String], Json), String] {
  match response_out {
    Ok(response) => {
      let response_body = rewrite_download_url_for_server(response.body, port)
      Ok((response.status, response.headers, response_body))
    }
    Err(error) => Err(error.to_string())
  }
}

///|
pub fn handle_http_request(
  http_method : String,
  path : String,
  headers : Map[String, String],
  body : Bytes,
  upload_handler : (Json) -> Result[(Int, Map[String, String], Json), String],
  versions_handler : (String) -> Result[
    (Int, Map[String, String], Json),
    String,
  ],
  bundle_detail_handler : (String) -> Result[
    (Int, Map[String, String], Json),
    String,
  ],
  bundle_download_handler : (String) -> Result[@mapi.ResponseEnvelope, String],
  resolve_handler : (String, String?) -> Result[
    (Int, Map[String, String], Json),
    String,
  ],
) -> Result[@mapi.ResponseEnvelope, String] {
  match @client.route(http_method, path) {
    Health =>
      Ok(
        json_response_envelope(200, {}, {
          "status": "ok",
          "service": "cogna-registry",
        }),
      )
    PublishBundles => {
      let request_out = parse_json_request(body)
      guard request_out is Ok(request) else {
        return Ok(
          json_response_envelope(400, {}, { "error": request_out.unwrap_err() }),
        )
      }
      match upload_handler(request) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_response_envelope(status, response_headers, response_body))
        Err(message) =>
          Ok(json_response_envelope(500, {}, { "error": message }))
      }
    }
    PackageVersions(purl) =>
      match versions_handler(purl) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_response_envelope(status, response_headers, response_body))
        Err(message) =>
          Ok(json_response_envelope(500, {}, { "error": message }))
      }
    BundleDetail(bundle_id) =>
      match bundle_detail_handler(bundle_id) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_response_envelope(status, response_headers, response_body))
        Err(message) =>
          Ok(json_response_envelope(500, {}, { "error": message }))
      }
    BundleDownload(bundle_id) =>
      match bundle_download_handler(bundle_id) {
        Ok(response) => Ok(response)
        Err(message) =>
          Ok(json_response_envelope(500, {}, { "error": message }))
      }
    ResolveByPurl(purl) => {
      let if_none_match = @client.header_value(headers, "If-None-Match")
      match resolve_handler(purl, if_none_match) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_response_envelope(status, response_headers, response_body))
        Err(message) =>
          Ok(json_response_envelope(500, {}, { "error": message }))
      }
    }
    Unknown =>
      Ok({
        status: 404,
        headers: { "Content-Type": "text/plain; charset=utf-8" },
        body: Some(@utf8.encode("not found")),
      })
  }
}

///|
fn app_response(
  port : Int,
  req : @mapi.RequestEnvelope,
) -> @mapi.ResponseEnvelope {
  let http_method = match req.http_method {
    Get => "GET"
    Post => "POST"
    Put => "PUT"
    Patch => "PATCH"
    Delete => "DELETE"
    Head => "HEAD"
    Options => "OPTIONS"
  }
  let body = req.body.unwrap_or(b"")
  match
    handle_http_request(
      http_method,
      request_path_with_query(req),
      req.headers,
      body,
      request => as_http_json_response(port, api_upload(request)),
      purl => as_http_json_response(port, registry_versions_response(purl)),
      bundle_id => {
        as_http_json_response(
          port,
          registry_bundle_detail_response(bundle_id, port),
        )
      },
      bundle_id => {
        match registry_bundle_download_http(bundle_id) {
          Ok(response) => Ok(response)
          Err(error) => Err(error.to_string())
        }
      },
      (purl, if_none_match) => {
        as_http_json_response(port, api_resolve(purl, if_none_match))
      },
    ) {
    Ok(response) => response
    Err(message) => json_response_envelope(500, {}, { "error": message })
  }
}

///|
pub fn serve_registry(port : Int) -> Result[Unit, @cli.CliError] {
  let serve_out : Ref[Result[Unit, String]?] = Ref::new(None)
  @mbasync.run_async_main(() => {
    let value = try {
      let router = @mapi.Router::new()
      router.add({
        http_method: @mapi.HttpMethod::Get,
        pattern: "/health",
        handler: (_, req, _) => app_response(port, req),
      })
      router.add({
        http_method: @mapi.HttpMethod::Post,
        pattern: "/api/v1/bundles",
        handler: (_, req, _) => app_response(port, req),
      })
      router.add({
        http_method: @mapi.HttpMethod::Get,
        pattern: "/api/v1/bundles/resolve",
        handler: (_, req, _) => app_response(port, req),
      })
      router.add({
        http_method: @mapi.HttpMethod::Get,
        pattern: "/api/v1/packages/{purl}/versions",
        handler: (_, req, _) => app_response(port, req),
      })
      router.add({
        http_method: @mapi.HttpMethod::Get,
        pattern: "/api/v1/bundles/{bundleId}",
        handler: (_, req, _) => app_response(port, req),
      })
      router.add({
        http_method: @mapi.HttpMethod::Get,
        pattern: "/api/v1/bundles/{bundleId}/download",
        handler: (_, req, _) => app_response(port, req),
      })
      let app = @mapi.App::new(router)
      let server = @http.Server::new(
        @socket.Addr::parse("127.0.0.1:\{port}"),
        reuse_addr=true,
      )
      while true {
        let (conn, _) = server.accept()
        let request = conn.read_request()
        let request_body = conn.read_all().binary()
        let method_out = request_method_from_string(
          request.meth.to_string().to_upper(),
        )
        let response = match method_out {
          Ok(http_method) =>
            app.serve({
              http_method,
              path: request_path_only(request.path),
              query: query_string_to_map(request_query_string(request.path)),
              headers: request.headers,
              body: Some(request_body),
            })
          Err(message) => json_response_envelope(405, {}, { "error": message })
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
    Some(Err(message)) => Err(registry_error(message))
    None => Err(registry_error("registry server did not produce result"))
  }
}
