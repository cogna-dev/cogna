///|
fn remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn cleanup_registry() -> Unit {
  remove_dir_if_exists(".codeiq/registry/index")
  remove_dir_if_exists(".codeiq/registry/bundles")
  remove_dir_if_exists(".codeiq/registry/http")
  remove_dir_if_exists(".codeiq/registry")
  remove_dir_if_exists(".codeiq/cache/registry/index")
  remove_dir_if_exists(".codeiq/cache/registry/bundles")
  remove_dir_if_exists(".codeiq/cache/registry")
  remove_dir_if_exists(".codeiq/cache")
  remove_dir_if_exists(".codeiq")
  @sys.unset_env_var("CODEIQ_REGISTRY_BASE_URL")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  @sys.unset_env_var("CODEIQ_SIGNATURE_STATUS")
  @sys.unset_env_var("CODEIQ_SIGNATURE_KEY_ID")
  @sys.unset_env_var("CODEIQ_SIGNATURE_VALUE")
  @sys.unset_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE")
}

///|
fn bundle_fixture(repo : String) -> String {
  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle fixture") catch {
    _ => abort("failed to write bundle fixture")
  }
  bundle_path
}

///|
fn upload_request(bundle_path : String, purl : String) -> Json {
  let bytes = @fs.read_file_to_bytes(bundle_path) catch {
    _ => abort("failed to read bundle fixture")
  }
  {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_path,
    "bundleType": "ciq-bundle",
    "purl": purl,
    "digest": "sha256:\{@sha256.sha256_hexdigest(bytes)}",
    "size": bytes.length(),
  }
}

///|
fn upload_request_with_signature(
  bundle_path : String,
  purl : String,
  signature : Json,
) -> Json {
  let request = upload_request(bundle_path, purl)
  guard request is Object(request_object) else {
    abort("upload request should be object")
  }
  request_object["signature"] = signature
  Json::object(request_object)
}

///|
test "registry download returns 304 when etag matches" {
  let repo = "src/cmd/registry/tmp_registry_etag"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.1.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(uploaded) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match", uploaded.etag)
  let download_out = download_local_by_purl(purl)
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  guard download_out is Ok(download) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("download should succeed")
  }

  let json_text = download.stringify(indent=2)
  assert_true(json_text.contains("\"status\": 304"))
  assert_true(json_text.contains("\"notModified\": true"))
  assert_true(json_text.contains("\"etag\": \"\\\"bundle_"))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry download returns 200 when etag mismatched" {
  let repo = "src/cmd/registry/tmp_registry_download"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.2.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(_) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match", "\"other-etag\"")
  let download_out = download_local_by_purl(purl)
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  guard download_out is Ok(download) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("download should succeed")
  }

  let json_text = download.stringify(indent=2)
  assert_true(json_text.contains("\"status\": 200"))
  assert_true(json_text.contains("\"notModified\": false"))
  assert_true(json_text.contains("\"contentLength\""))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry run_upload_local reads request file and returns receipt" {
  let repo = "src/cmd/registry/tmp_registry_cli_upload"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
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
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("failed to write upload request fixture")
  }

  let run_out = run_upload_local({ upload_request_file: request_path })
  guard run_out is Ok(result) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
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
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry run_download_local returns response for purl" {
  let repo = "src/cmd/registry/tmp_registry_cli_download"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.4.0"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(_) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed before download")
  }

  let run_out = run_download_local({ purl, })
  guard run_out is Ok(result) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("run_download_local should succeed")
  }

  assert_true(result.summary.contains("Resolved registry metadata"))
  let response_text = result.response.stringify(indent=2)
  assert_true(response_text.contains("\"status\": 200"))
  assert_true(
    response_text.contains("\"purl\": \"pkg:generic/acme/demo@0.4.0\""),
  )

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry download_by_purl transforms remote receipt response" {
  cleanup_registry()
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @fs.create_dir(".codeiq") catch {
    _ => ()
  }
  @fs.create_dir(".codeiq/cache") catch {
    _ => ()
  }
  @fs.create_dir(".codeiq/cache/registry") catch {
    _ => ()
  }
  @fs.create_dir(".codeiq/cache/registry/bundles") catch {
    _ => ()
  }
  @fs.write_string_to_file(
    ".codeiq/cache/registry/bundles/bundle_sha256_remote1.ciq.tgz", "bundle fixture",
  ) catch {
    _ => abort("failed to write remote cache fixture")
  }
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_remote_1",
      #|  "bundleId": "bundle_sha256_remote1",
      #|  "purl": "pkg:generic/acme/demo@9.9.9",
      #|  "digest": "sha256:f6e327339b5a5695efb777ad14d77cffcf3ff7002dba36c63bc95ed9a2470584",
      #|  "bundleType": "ciq-bundle",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_remote1.ciq.tgz",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_remote1\""
      #|  }
      #|}
    ),
  )

  let out = download_by_purl("pkg:generic/acme/demo@9.9.9")
  guard out is Ok(response) else {
    cleanup_registry()
    fail("remote download should succeed")
  }
  let text = response.stringify(indent=2)
  assert_true(
    text.contains("\"schemaVersion\": \"codeiq-registry-download/v1\""),
  )
  assert_true(text.contains("\"status\": 200"))
  assert_true(text.contains("\"bundleId\": \"bundle_sha256_remote1\""))
  assert_true(text.contains("\"etag\": \"\\\"bundle_sha256_remote1\\\"\""))
  assert_true(text.contains("\"notModified\": false"))

  cleanup_registry()
}

///|
test "registry download_by_purl preserves receipt provenance etag" {
  let repo = "src/cmd/registry/tmp_registry_remote_receipt_etag"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  let bundle_path = bundle_fixture(repo)
  let bytes = @fs.read_file_to_bytes(bundle_path) catch {
    _ => abort("failed to read bundle fixture")
  }
  let digest = "sha256:\{@sha256.sha256_hexdigest(bytes)}"
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      {
        "schemaVersion": "codeiq-publish-receipt/v1",
        "publishId": "pub_remote_etag",
        "bundleId": "bundle_sha256_remote_etag",
        "purl": "pkg:generic/acme/demo@9.9.8",
        "digest": digest,
        "bundleType": "ciq-bundle",
        "downloadUrl": "local://\{bundle_path}",
        "status": "published",
        "provenance": {
          "source": "remote-registry",
          "digestVerified": true,
          "etag": "\"custom-etag\"",
        },
      } : Json).stringify(indent=2),
  )

  let out = download_by_purl("pkg:generic/acme/demo@9.9.8")
  guard out is Ok(response) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("remote download should succeed")
  }
  let text = response.stringify(indent=2)
  assert_true(text.contains("\"etag\": \"\\\"custom-etag\\\"\""))
  let etag_text = @fs.read_file_to_string(
    ".codeiq/cache/registry/bundles/bundle_sha256_remote_etag.etag",
  ) catch {
    _ => ""
  }
  inspect(etag_text.trim().to_string(), content="\"custom-etag\"")

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry upload transforms remote download response" {
  let repo = "src/cmd/registry/tmp_registry_remote_upload"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@8.8.8"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 200,
      #|  "purl": "pkg:generic/acme/demo@8.8.8",
      #|  "bundleId": "bundle_sha256_remote2",
      #|  "digest": "sha256:f6e327339b5a5695efb777ad14d77cffcf3ff7002dba36c63bc95ed9a2470584",
      #|  "etag": "\"bundle_sha256_remote2\"",
      #|  "downloadUrl": "local://src/cmd/registry/tmp_registry_remote_upload/dist/bundle.ciq.tgz",
      #|  "notModified": false
      #|}
    ),
  )

  let out = upload(request)
  guard out is Ok(uploaded) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("remote upload should succeed")
  }
  let text = uploaded.receipt.stringify(indent=2)
  assert_true(text.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""))
  assert_true(text.contains("\"bundleId\": \"bundle_sha256_remote2\""))
  assert_true(text.contains("\"status\": \"published\""))
  assert_true(text.contains("\"etag\": \"\\\"bundle_sha256_remote2\\\"\""))
  assert_true(text.contains("\"provenance\""))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry upload uses receipt provenance etag when response etag missing" {
  let repo = "src/cmd/registry/tmp_registry_remote_upload_receipt_etag"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@8.8.7"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  guard request is Object(request_object) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    abort("request must be object")
  }
  let expected_digest = match request_object.get("digest") {
    Some(String(value)) => value
    _ => abort("request digest missing")
  }
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      {
        "schemaVersion": "codeiq-publish-receipt/v1",
        "publishId": "pub_remote_receipt_etag",
        "bundleId": "bundle_sha256_remote_receipt_etag",
        "purl": purl,
        "digest": expected_digest,
        "bundleType": "ciq-bundle",
        "downloadUrl": "https://registry.example.test/api/v1/bundles/bundle_sha256_remote_receipt_etag/download",
        "status": "published",
        "provenance": {
          "source": "remote-registry",
          "digestVerified": true,
          "etag": "\"receipt-etag\"",
        },
      } : Json).stringify(indent=2),
  )

  let out = upload(request)
  guard out is Ok(uploaded) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("remote upload should succeed")
  }
  inspect(uploaded.etag, content="\"receipt-etag\"")

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry remote download fails on digest mismatch" {
  let repo = "src/cmd/registry/tmp_registry_remote_digest_mismatch"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = bundle_fixture(repo)
  let bundle_bytes = @fs.read_file_to_bytes(bundle_path) catch {
    _ => abort("failed to read bundle fixture")
  }
  let computed_digest = "sha256:\{@sha256.sha256_hexdigest(bundle_bytes)}"
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 200,
      #|  "purl": "pkg:generic/acme/demo@7.7.7",
      #|  "bundleId": "bundle_sha256_remote3",
      #|  "digest": "sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      #|  "etag": "\"bundle_sha256_remote3\"",
      #|  "downloadUrl": "local://src/cmd/registry/tmp_registry_remote_digest_mismatch/dist/bundle.ciq.tgz",
      #|  "notModified": false,
      #|  "contentLength": 14
      #|}
    ),
  )

  let out = download_by_purl("pkg:generic/acme/demo@7.7.7")
  guard out is Err(error) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("remote download should fail for digest mismatch")
  }
  let text = error.to_string()
  assert_true(text.contains("download digest mismatch"))
  assert_true(text.contains(computed_digest))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry remote upload fails when receipt digest mismatched" {
  let repo = "src/cmd/registry/tmp_registry_remote_upload_digest_mismatch"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@6.6.6"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  guard request is Object(request_object) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    abort("request must be object")
  }
  let expected_digest = match request_object.get("digest") {
    Some(String(value)) => value
    _ => abort("request digest missing")
  }
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_remote_bad",
      #|  "bundleId": "bundle_sha256_remote_bad",
      #|  "purl": "pkg:generic/acme/demo@6.6.6",
      #|  "digest": "sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      #|  "bundleType": "ciq-bundle",
      #|  "downloadUrl": "https://registry.example.test/api/v1/bundles/bundle_sha256_remote_bad/download",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_remote_bad\""
      #|  }
      #|}
    ),
  )

  let out = upload(request)
  guard out is Err(error) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("remote upload should fail for digest mismatch")
  }
  let text = error.to_string()
  assert_true(text.contains("remote receipt digest mismatch"))
  assert_true(text.contains(expected_digest))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry upload_local rejects invalid digest format" {
  let repo = "src/cmd/registry/tmp_registry_invalid_upload_digest"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, "pkg:generic/acme/demo@5.5.5")
  guard request is Object(request_object) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    abort("request must be object")
  }
  request_object["digest"] = Json::string("sha256:not-a-valid-digest")

  let out = upload_local(request)
  guard out is Err(error) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should fail for invalid digest format")
  }
  let text = error.to_string()
  assert_true(text.contains("invalid sha256 digest in upload request"))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry download_by_purl rejects invalid remote digest format" {
  cleanup_registry()
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 200,
      #|  "purl": "pkg:generic/acme/demo@5.5.4",
      #|  "bundleId": "bundle_sha256_remote_invalid_digest",
      #|  "digest": "sha256:not-a-valid-digest",
      #|  "etag": "\"bundle_sha256_remote_invalid_digest\"",
      #|  "downloadUrl": "local://nowhere.ciq.tgz",
      #|  "notModified": false
      #|}
    ),
  )

  let out = download_by_purl("pkg:generic/acme/demo@5.5.4")
  guard out is Err(error) else {
    cleanup_registry()
    fail("download_by_purl should fail for invalid remote digest format")
  }
  let text = error.to_string()
  assert_true(
    text.contains("invalid sha256 digest in remote download response"),
  )

  cleanup_registry()
}

///|
test "registry upload rejects invalid remote receipt digest format" {
  let repo = "src/cmd/registry/tmp_registry_invalid_remote_receipt_digest"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@5.5.3"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_remote_invalid_digest",
      #|  "bundleId": "bundle_sha256_remote_invalid_digest",
      #|  "purl": "pkg:generic/acme/demo@5.5.3",
      #|  "digest": "sha256:not-a-valid-digest",
      #|  "bundleType": "ciq-bundle",
      #|  "downloadUrl": "https://registry.example.test/api/v1/bundles/bundle_sha256_remote_invalid_digest/download",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_remote_invalid_digest\""
      #|  }
      #|}
    ),
  )

  let out = upload(request)
  guard out is Err(error) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload should fail for invalid remote receipt digest format")
  }
  let text = error.to_string()
  assert_true(text.contains("invalid sha256 digest in remote receipt response"))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry api_upload and api_resolve return status and etag headers" {
  let repo = "src/cmd/registry/tmp_registry_api_roundtrip"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@4.4.4"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)

  let first_out = api_upload(request)
  guard first_out is Ok(first_response) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("api_upload should succeed")
  }
  inspect(first_response.status, content="201")
  let etag = match first_response.headers.get("ETag") {
    Some(value) => value
    None => {
      cleanup_registry()
      @fs.remove_dir(repo) catch {
        _ => ()
      }
      fail("api_upload should include ETag header")
      ""
    }
  }

  let resolve_out = api_resolve(purl, None)
  guard resolve_out is Ok(resolve_response) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("api_resolve should succeed without if-none-match")
  }
  inspect(resolve_response.status, content="200")
  let resolve_text = resolve_response.body.stringify(indent=2)
  assert_true(resolve_text.contains("\"status\": 200"))

  let resolve_304_out = api_resolve(purl, Some(etag))
  guard resolve_304_out is Ok(resolve_304_response) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("api_resolve should succeed with matching if-none-match")
  }
  inspect(resolve_304_response.status, content="304")
  let resolve_304_text = resolve_304_response.body.stringify(indent=2)
  assert_true(resolve_304_text.contains("\"status\": 304"))

  let second_out = api_upload(request)
  guard second_out is Ok(second_response) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("api_upload should succeed for already-exists")
  }
  inspect(second_response.status, content="200")

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry remote inproc mode resolves via local api" {
  let repo = "src/cmd/registry/tmp_registry_inproc_remote"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@4.4.3"
  let bundle_path = bundle_fixture(repo)
  let request = upload_request(bundle_path, purl)
  let upload_out = upload_local(request)
  guard upload_out is Ok(_) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should seed registry for inproc mode")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "inproc://registry")
  let out = download_by_purl(purl)
  guard out is Ok(response) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("download_by_purl should succeed in inproc mode")
  }
  let text = response.stringify(indent=2)
  assert_true(
    text.contains("\"schemaVersion\": \"codeiq-registry-download/v1\""),
  )
  assert_true(text.contains("\"status\": 200"))
  assert_true(text.contains("\"purl\": \"pkg:generic/acme/demo@4.4.3\""))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry upload_local includes signature metadata from env" {
  let repo = "src/cmd/registry/tmp_registry_signature_upload"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
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
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed")
  }
  let text = uploaded.receipt.stringify(indent=2)
  assert_true(text.contains("\"signature\""))
  assert_true(text.contains("\"status\": \"verified\""))
  assert_true(text.contains("\"keyId\": \"acme-main\""))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry upload_local marks verified-without-key as untrusted" {
  let repo = "src/cmd/registry/tmp_registry_signature_invalid"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
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
  @sys.set_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE", bundle_path)
  let out = upload_local(request)
  guard out is Ok(uploaded) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed with downgraded trust")
  }
  let text = uploaded.receipt.stringify(indent=2)
  assert_true(text.contains("\"status\": \"untrusted\""))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry download_by_purl propagates signature metadata from remote download" {
  cleanup_registry()
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 200,
      #|  "purl": "pkg:generic/acme/demo@4.4.1",
      #|  "bundleId": "bundle_sha256_remote_sig",
      #|  "digest": "sha256:f6e327339b5a5695efb777ad14d77cffcf3ff7002dba36c63bc95ed9a2470584",
      #|  "etag": "\"bundle_sha256_remote_sig\"",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_remote_sig.ciq.tgz",
      #|  "notModified": false,
      #|  "signature": {
      #|    "status": "untrusted",
      #|    "algorithm": "sha256",
      #|    "keyId": "unknown-key"
      #|  }
      #|}
    ),
  )
  @fs.create_dir(".codeiq") catch {
    _ => ()
  }
  @fs.create_dir(".codeiq/cache") catch {
    _ => ()
  }
  @fs.create_dir(".codeiq/cache/registry") catch {
    _ => ()
  }
  @fs.create_dir(".codeiq/cache/registry/bundles") catch {
    _ => ()
  }
  @fs.write_string_to_file(
    ".codeiq/cache/registry/bundles/bundle_sha256_remote_sig.ciq.tgz", "bundle fixture",
  ) catch {
    _ => abort("failed to write remote signature cache fixture")
  }

  let out = download_by_purl("pkg:generic/acme/demo@4.4.1")
  guard out is Ok(response) else {
    cleanup_registry()
    fail("download_by_purl should succeed")
  }
  let text = response.stringify(indent=2)
  assert_true(text.contains("\"signature\""))
  assert_true(text.contains("\"status\": \"untrusted\""))
  assert_true(text.contains("\"keyId\": \"unknown-key\""))

  cleanup_registry()
}
