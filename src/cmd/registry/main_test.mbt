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
  assert_true(
    response_text.contains("local://.codeiq/cache/registry/bundles/"),
  )

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry upload_local writes bundle and index into shared cache store" {
  let repo = "src/cmd/registry/tmp_registry_shared_store"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@1.0.0"
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

  assert_true(uploaded.stored_bundle_path.contains(".codeiq/cache/registry/bundles/"))
  assert_true(@fs.path_exists(uploaded.stored_bundle_path))
  assert_true(
    @fs.path_exists(".codeiq/cache/registry/index/pkg_generic_acme_demo_1.0.0.json"),
  )

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
test "registry upload_local preserves verified signature value without trust downgrade" {
  let repo = "src/cmd/registry/tmp_registry_signature_preserved"
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
  let out = upload_local(request)
  guard out is Ok(uploaded) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed")
  }
  let text = uploaded.receipt.stringify(indent=2)
  assert_true(text.contains("\"status\": \"verified\""))
  assert_true(text.contains("\"keyId\": \"acme-main\""))
  assert_true(text.contains("\"value\": \"ZmFrZS1zaWduYXR1cmU=\""))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "registry download_by_purl propagates signature metadata from local receipt" {
  let repo = "src/cmd/registry/tmp_registry_signature_download"
  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
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
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed")
  }

  let out = download_by_purl(purl)
  guard out is Ok(response) else {
    cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("download_by_purl should succeed")
  }
  let text = response.stringify(indent=2)
  assert_true(text.contains("\"signature\""))
  assert_true(text.contains("\"status\": \"untrusted\""))
  assert_true(text.contains("\"keyId\": \"unknown-key\""))

  cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}
