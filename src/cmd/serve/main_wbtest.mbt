///|
fn health_response(
  resolved : @config.ResolvedConfig,
  port : Int,
) -> @mapi.ResponseEnvelope {
  let app = build_app(resolved, port)
  app.serve({
    http_method: @mapi.HttpMethod::Get,
    path: "/health",
    query: {},
    headers: {},
    body: None,
  })
}

///|
fn app_response(
  resolved : @config.ResolvedConfig,
  port : Int,
  req : @mapi.RequestEnvelope,
) -> @mapi.ResponseEnvelope {
  let app = build_app(resolved, port)
  app.serve(req)
}

///|
fn ensure_tree_removed(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  let is_dir = try? @fs.is_dir(path)
  if is_dir is Ok(true) {
    let entries = @fs.read_dir(path) catch { _ => [] }
    for i in 0..<entries.length() {
      ensure_tree_removed("\{path}/\{entries[i]}")
    }
    @fs.remove_dir(path) catch {
      _ => ()
    }
  } else {
    @fs.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
fn test_resolved_config(store_dir : String) -> @config.ResolvedConfig {
  {
    path: "./cogna.yml",
    root_dir: ".",
    config: {
      schema_version: "ciq-config/v2",
      profile: "openapi-spec",
      validation: "none",
      purl: "pkg:openapi/acme/payment-api@2026.03.01",
      source: { repo: "https://github.com/acme/payment-api", source_ref: "main" },
      inputs: { include_paths: ["openapi/**/*.yaml"] },
      checks: { format: "sarif", policy: "./dist/policy.ciq.tgz" },
      diff: { since: None, include_test_changes: false },
      sbom: {
        format: "spdx",
        dependency_bundles: true,
        require_local_packages: true,
      },
      cache: {
        type_: "local",
        local_store: { store_dir: store_dir },
        http: { base_url: "", timeout_ms: 10000 },
      },
      mcp: { port: 3000 },
    },
  }
}

///|
fn request(
  http_method : @mapi.HttpMethod,
  path : String,
  query : Map[String, Array[String]],
  headers : Map[String, String],
  body : Bytes,
) -> @mapi.RequestEnvelope {
  { http_method, path, query, headers, body: Some(body) }
}

///|
test "serve health response reports cache proxy backend" {
  let response = health_response(test_resolved_config("/tmp/cogna-serve-health"), 8787)
  inspect(response.status, content="200")
  let body = @cache.bytes_to_string(response.body.unwrap_or(b""))
  assert_true(body.contains("\"status\":\"ok\""))
  assert_true(body.contains("\"service\":\"cogna-cache-proxy\""))
  assert_true(body.contains("\"backend\":\"local\""))
  assert_true(body.contains("\"port\":8787"))
}

///|
test "serve cache object endpoint requires key" {
  let response = app_response(
    test_resolved_config("/tmp/cogna-serve-missing-key"),
    8787,
    request(@mapi.HttpMethod::Get, "/cache/v1/object", {}, {}, b""),
  )
  inspect(response.status, content="400")
  assert_true(
    @cache.bytes_to_string(response.body.unwrap_or(b"")).contains("query parameter 'key' is required"),
  )
}

///|
test "serve cache object put then get uses local backend" {
  let store_dir = "/tmp/cogna-serve-local-store"
  ensure_tree_removed(store_dir)
  let resolved = test_resolved_config(store_dir)

  let put_response = app_response(
    resolved,
    8787,
    request(
      @mapi.HttpMethod::Put,
      "/cache/v1/object",
      { "key": ["blob/test"] },
      { "Content-Type": "text/plain" },
      @utf8.encode("hello cache"),
    ),
  )
  inspect(put_response.status, content="201")
  assert_true(
    @cache.bytes_to_string(put_response.body.unwrap_or(b"")).contains("\"status\":\"stored\""),
  )

  let get_response = app_response(
    resolved,
    8787,
    request(
      @mapi.HttpMethod::Get,
      "/cache/v1/object",
      { "key": ["blob/test"] },
      {},
      b"",
    ),
  )
  inspect(get_response.status, content="200")
  inspect(get_response.headers["Content-Type"], content="text/plain")
  inspect(@cache.bytes_to_string(get_response.body.unwrap_or(b"")), content="hello cache")

  ensure_tree_removed(store_dir)
}

///|
test "serve cache object get returns 404 on miss" {
  let store_dir = "/tmp/cogna-serve-local-miss"
  ensure_tree_removed(store_dir)
  let response = app_response(
    test_resolved_config(store_dir),
    8787,
    request(
      @mapi.HttpMethod::Get,
      "/cache/v1/object",
      { "key": ["blob/missing"] },
      {},
      b"",
    ),
  )
  inspect(response.status, content="404")
  assert_true(
    @cache.bytes_to_string(response.body.unwrap_or(b"")).contains("cache object not found"),
  )
  ensure_tree_removed(store_dir)
}
