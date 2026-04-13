///|
test "registry download returns 304 when etag matches" {
  let repo = tmp_registry_repo("etag")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.1.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(uploaded) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("upload_local should succeed")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match", uploaded.etag)
  let download_out = download_local_by_purl(purl)
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  guard download_out is Ok(download) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("download should succeed")
  }

  let json_text = download.stringify(indent=2)
  assert_true(json_text.contains("\"status\": 304"))
  assert_true(json_text.contains("\"notModified\": true"))
  assert_true(json_text.contains("\"etag\": \"\\\"bundle_"))

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry download returns 200 when etag mismatched" {
  let repo = tmp_registry_repo("download")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.2.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(_) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("upload_local should succeed")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match", "\"other-etag\"")
  let download_out = download_local_by_purl(purl)
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  guard download_out is Ok(download) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("download should succeed")
  }

  let json_text = download.stringify(indent=2)
  assert_true(json_text.contains("\"status\": 200"))
  assert_true(json_text.contains("\"notModified\": false"))
  assert_true(json_text.contains("\"contentLength\""))

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry run_upload_local reads request file and returns receipt" {
  let repo = tmp_registry_repo("cli-upload")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.3.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let request_path = "\{repo}/upload.json"
  let write_out = try? @fs.write_string_to_file(
    request_path,
    request.stringify(indent=2),
  )
  guard write_out is Ok(_) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("failed to write upload request fixture")
  }

  let run_out = run_upload_local({ upload_request_file: request_path })
  guard run_out is Ok(result) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("run_upload_local should succeed")
  }

  assert_true(result.summary.contains("Uploaded bundle from"))
  let receipt_text = result.receipt.stringify(indent=2)
  assert_true(
    receipt_text.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""),
  )
  assert_true(
    receipt_text.contains("\"purl\": \"pkg:generic/acme/demo@0.3.0\""),
  )
  assert_true(receipt_text.contains("\"provenance\""))

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry run_download_local returns response for purl" {
  let repo = tmp_registry_repo("cli-download")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.4.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(_) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("upload_local should succeed before download")
  }

  let run_out = run_download_local({ purl, })
  guard run_out is Ok(result) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("run_download_local should succeed")
  }

  assert_true(result.summary.contains("Resolved registry metadata"))
  let response_text = result.response.stringify(indent=2)
  assert_true(response_text.contains("\"status\": 200"))
  assert_true(
    response_text.contains("\"purl\": \"pkg:generic/acme/demo@0.4.0\""),
  )
  assert_true(response_text.contains("local://.codeiq/cache/registry/bundles/"))

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry status reports stopped when descriptor missing" {
  @fs.remove_file("./dist/registry-server.json") catch {
    _ => ()
  }
  let out = run_status()
  guard out is Ok(result) else { fail("registry status should succeed") }
  inspect(result.status, content="stopped")
  assert_true(result.summary.contains("not found"))
}

///|
test "registry upload_local writes bundle and index into shared cache store" {
  let repo = tmp_registry_repo("shared-store")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @sys.set_env_var(
    "CODEIQ_REGISTRY_STORE_DIR", tmp_registry_store_root(),
  )
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@1.0.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(uploaded) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("upload_local should succeed")
  }

  assert_true(
    uploaded.stored_bundle_path.contains(
      "\{tmp_registry_store_root()}/bundles/",
    ),
  )
  assert_true(@fs.path_exists(uploaded.stored_bundle_path))
  assert_true(
    @fs.path_exists(
      "\{tmp_registry_store_root()}/index/pkg_generic_acme_demo_1.0.0.json",
    ),
  )

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry local store root prefers env then config then default" {
  let repo = tmp_registry_repo("config-store")
  let config =
    #|schemaVersion: ciq-config/v2
    #|profile: openapi-spec
    #|purl: pkg:openapi/acme/payment-api@2026.03.01
    #|source:
    #|  repo: https://github.com/acme/payment-api
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - openapi/**/*.yaml
    #|checks:
    #|  format: sarif
    #|  policy: ./dist/policy.ciq.tgz
    #|diff:
    #|  includeTestChanges: false
    #|sbom:
    #|  format: spdx
    #|  dependencyBundles: true
    #|  requireLocalPackages: true
    #|publish:
    #|  includeDependencies: true
    #|registry:
    #|  port: 8787
    #|  storeDir: custom-registry
    #|mcp:
    #|  port: 3000
    #|
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  let config_out = try? @fs.write_string_to_file("\{repo}/codeiq.yml", config)
  guard config_out is Ok(_) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("failed to write config")
  }

  let default_root = @registry_lib.resolved_local_store_root(
    tmp_registry_repo("no-config"),
  )
  inspect(default_root, content=".codeiq/cache/registry")

  @sys.set_env_var(
    "CODEIQ_REGISTRY_STORE_DIR", tmp_registry_store_root(),
  )
  inspect(
    @registry_lib.resolved_local_store_root(repo),
    content="/tmp/codeiq-registry-store",
  )
  @sys.unset_env_var("CODEIQ_REGISTRY_STORE_DIR")

  let config_root = @registry_lib.resolved_local_store_root(repo)
  inspect(
    config_root,
    content="/tmp/codeiq-registry-config-store/custom-registry",
  )

  cleanup_registry()
  @fs.remove_file("\{repo}/codeiq.yml") catch {
    _ => ()
  }
  remove_dir_if_exists(repo)
}

///|
test "registry api_upload and api_resolve return status and etag headers" {
  let repo = tmp_registry_repo("api-roundtrip")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@4.4.4"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)

  let first_out = api_upload(request)
  guard first_out is Ok(first_response) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("api_upload should succeed")
  }
  inspect(first_response.status, content="201")
  let etag = match first_response.headers.get("ETag") {
    Some(value) => value
    None => {
      cleanup_registry()
      remove_dir_if_exists(repo)
      fail("api_upload should include ETag header")
      ""
    }
  }

  let resolve_out = api_resolve(purl, None)
  guard resolve_out is Ok(resolve_response) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("api_resolve should succeed without if-none-match")
  }
  inspect(resolve_response.status, content="200")
  let resolve_text = resolve_response.body.stringify(indent=2)
  assert_true(resolve_text.contains("\"status\": 200"))

  let resolve_304_out = api_resolve(purl, Some(etag))
  guard resolve_304_out is Ok(resolve_304_response) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("api_resolve should succeed with matching if-none-match")
  }
  inspect(resolve_304_response.status, content="304")
  let resolve_304_text = resolve_304_response.body.stringify(indent=2)
  assert_true(resolve_304_text.contains("\"status\": 304"))

  let second_out = api_upload(request)
  guard second_out is Ok(second_response) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("api_upload should succeed for already-exists")
  }
  inspect(second_response.status, content="200")

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry upload_local includes signature metadata from env" {
  let repo = tmp_registry_repo("signature-upload")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@4.4.2"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  @sys.set_env_var("CODEIQ_SIGNATURE_STATUS", "verified")
  @sys.set_env_var("CODEIQ_SIGNATURE_KEY_ID", "acme-main")
  let out = upload_local(request)
  guard out is Ok(uploaded) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("upload_local should succeed")
  }
  let text = uploaded.receipt.stringify(indent=2)
  assert_true(text.contains("\"signature\""))
  assert_true(text.contains("\"status\": \"verified\""))
  assert_true(text.contains("\"keyId\": \"acme-main\""))

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry upload_local preserves verified signature value without trust downgrade" {
  let repo = tmp_registry_repo("signature-preserved")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@4.4.5"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request_with_signature(bundle_path, purl, {
    "status": "verified",
    "algorithm": "sha256",
    "keyId": "acme-main",
    "value": "ZmFrZS1zaWduYXR1cmU=",
  })
  let out = upload_local(request)
  guard out is Ok(uploaded) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("upload_local should succeed")
  }
  let text = uploaded.receipt.stringify(indent=2)
  assert_true(text.contains("\"status\": \"verified\""))
  assert_true(text.contains("\"keyId\": \"acme-main\""))
  assert_true(text.contains("\"value\": \"ZmFrZS1zaWduYXR1cmU=\""))

  cleanup_registry()
  remove_dir_if_exists(repo)
}

///|
test "registry download_by_purl propagates signature metadata from local receipt" {
  let repo = tmp_registry_repo("signature-download")
  cleanup_registry()
  remove_dir_if_exists(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@4.4.1"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request_with_signature(bundle_path, purl, {
    "status": "untrusted",
    "algorithm": "sha256",
    "keyId": "unknown-key",
  })
  let upload_out = upload_local(request)
  guard upload_out is Ok(_) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("upload_local should succeed")
  }

  let out = download_by_purl(purl)
  guard out is Ok(response) else {
    cleanup_registry()
    remove_dir_if_exists(repo)
    fail("download_by_purl should succeed")
  }
  let text = response.stringify(indent=2)
  assert_true(text.contains("\"signature\""))
  assert_true(text.contains("\"status\": \"untrusted\""))
  assert_true(text.contains("\"keyId\": \"unknown-key\""))

  cleanup_registry()
  remove_dir_if_exists(repo)
}
