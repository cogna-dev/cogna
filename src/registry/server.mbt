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
fn json_api_response(
  status : Int,
  headers : Map[String, String],
  body : Json,
) -> @registry_runtime.HttpResponse {
  @registry_runtime.json_response(status, body, headers~)
}

///|
fn rewrite_download_url_for_server(body : Json, port : Int) -> Json {
  guard body is Object(body_object) else { return body }
  match @registry_lib.string_field_optional(body_object, "bundleId") {
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
  response_out : Result[@registry_lib.RegistryApiResponse, @cli.CliError],
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
  bundle_download_handler : (String) -> Result[
    @registry_runtime.HttpResponse,
    String,
  ],
  resolve_handler : (String, String?) -> Result[
    (Int, Map[String, String], Json),
    String,
  ],
) -> Result[@registry_runtime.HttpResponse, String] {
  match @registry_lib.route(http_method, path) {
    Health =>
      Ok(
        @registry_runtime.json_response(200, {
          "status": "ok",
          "service": "codeiq-registry",
        }),
      )
    PublishBundles => {
      let request_out = parse_json_request(body)
      guard request_out is Ok(request) else {
        return Ok(
          @registry_runtime.json_response(400, {
            "error": request_out.unwrap_err(),
          }),
        )
      }
      match upload_handler(request) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_api_response(status, response_headers, response_body))
        Err(message) =>
          Ok(@registry_runtime.json_response(500, { "error": message }))
      }
    }
    PackageVersions(purl) =>
      match versions_handler(purl) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_api_response(status, response_headers, response_body))
        Err(message) =>
          Ok(@registry_runtime.json_response(500, { "error": message }))
      }
    BundleDetail(bundle_id) =>
      match bundle_detail_handler(bundle_id) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_api_response(status, response_headers, response_body))
        Err(message) =>
          Ok(@registry_runtime.json_response(500, { "error": message }))
      }
    BundleDownload(bundle_id) =>
      match bundle_download_handler(bundle_id) {
        Ok(response) => Ok(response)
        Err(message) =>
          Ok(@registry_runtime.json_response(500, { "error": message }))
      }
    ResolveByPurl(purl) => {
      let if_none_match = @registry_lib.header_value(headers, "If-None-Match")
      match resolve_handler(purl, if_none_match) {
        Ok((status, response_headers, response_body)) =>
          Ok(json_api_response(status, response_headers, response_body))
        Err(message) =>
          Ok(@registry_runtime.json_response(500, { "error": message }))
      }
    }
    Unknown => Ok(@registry_runtime.text_response(404, "not found"))
  }
}

///|
pub fn serve_registry(port : Int) -> Result[Unit, @cli.CliError] {
  let serve_out = @registry_runtime.serve_http(port, (
    http_method,
    path,
    headers,
    body,
  ) => {
    handle_http_request(
      http_method,
      path,
      headers,
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
    )
  })
  guard serve_out is Ok(_) else {
    return Err(registry_error(serve_out.unwrap_err()))
  }
  Ok(())
}
