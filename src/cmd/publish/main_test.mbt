///|
fn remove_file_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn cleanup_tmp_repo(repo : String) -> Unit {
  remove_file_if_exists("\{repo}/dist/bundle.ciq.tgz")
  remove_file_if_exists("\{repo}/dist/manifest.json")
  remove_file_if_exists("\{repo}/dist/publish.json")
  remove_file_if_exists(
    ".codeiq/registry/index/pkg_generic_local_bundle_0.json",
  )
  remove_dir_if_exists(".codeiq/registry/http")
  remove_dir_if_exists(".codeiq/registry/index")
  remove_dir_if_exists(".codeiq/registry/bundles")
  remove_dir_if_exists(".codeiq/registry")
  remove_dir_if_exists(".codeiq/cache/registry/index")
  remove_dir_if_exists(".codeiq/cache/registry/bundles")
  remove_dir_if_exists(".codeiq/cache/registry")
  remove_dir_if_exists(".codeiq/cache")
  remove_dir_if_exists(".codeiq")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
  @sys.unset_env_var("CODEIQ_REGISTRY_BASE_URL")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  @sys.unset_env_var("CODEIQ_SIGNATURE_STATUS")
  @sys.unset_env_var("CODEIQ_SIGNATURE_KEY_ID")
  @sys.unset_env_var("CODEIQ_SIGNATURE_VALUE")
  @sys.unset_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE")
}

///|
test "publish generates local publish receipt" {
  let repo = "src/cmd/publish/tmp_publish_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("publish should succeed")
  }

  inspect(
    result.display(),
    content="Generated publish receipt at src/cmd/publish/tmp_publish_repo/dist/publish.json",
  )

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(
    receipt.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""),
  )
  assert_true(receipt.contains("\"publishId\":"))
  assert_true(receipt.contains("\"bundleType\": \"ciq-bundle\""))
  assert_true(
    receipt.contains("\"status\": \"published\"") ||
    receipt.contains("\"status\": \"already-exists\""),
  )
  assert_true(receipt.contains("\"provenance\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish fails when bundle file is missing" {
  let repo = "src/cmd/publish/tmp_publish_missing_bundle"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let out = run({ bundle_file: "\{repo}/dist/bundle.ciq.tgz" })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("publish should fail when bundle file missing")
  }

  let text = error.to_string()
  assert_true(text.contains("publish failed:"))
  assert_true(text.contains("bundle file does not exist"))

  cleanup_tmp_repo(repo)
}

///|
test "publish returns already-exists receipt when etag matches" {
  let repo = "src/cmd/publish/tmp_publish_etag_match"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  let first_out = run({ bundle_file: bundle_path })
  guard first_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("first publish should succeed")
  }

  let first_receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("first publish receipt should exist")
      ""
    }
  }
  let parsed = try? @json.parse(first_receipt)
  guard parsed is Ok(Object(receipt_object)) else {
    cleanup_tmp_repo(repo)
    fail("first receipt should be valid json")
  }
  guard receipt_object.get("bundleId") is Some(String(bundle_id)) else {
    cleanup_tmp_repo(repo)
    fail("first receipt should contain bundleId")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH", "\"\{bundle_id}\"")
  let second_out = run({ bundle_file: bundle_path })
  @sys.unset_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH")
  guard second_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("second publish should succeed with etag")
  }

  let second_receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("second publish receipt should exist")
      ""
    }
  }
  assert_true(second_receipt.contains("\"status\": \"already-exists\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish uses remote registry stubs when base url configured" {
  let repo = "src/cmd/publish/tmp_publish_remote_registry"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 304,
      #|  "purl": "pkg:generic/local/bundle@0",
      #|  "bundleId": "bundle_sha256_remoteexisting",
      #|  "digest": "sha256:01054985999c3b8016a6f7d5d192f2da23d44f3317792222aa621a6ea6daba27",
      #|  "etag": "\"bundle_sha256_remoteexisting\"",
      #|  "downloadUrl": "https://registry.example.test/api/v1/bundles/bundle_sha256_remoteexisting/download",
      #|  "notModified": true
      #|}
    ),
  )
  @sys.set_env_var(
    "CODEIQ_REGISTRY_IF_NONE_MATCH", "\"bundle_sha256_remoteexisting\"",
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish with remote registry should succeed")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(
    receipt.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""),
  )
  assert_true(receipt.contains("\"status\": \"already-exists\""))
  assert_true(
    receipt.contains("\"bundleId\": \"bundle_sha256_remoteexisting\""),
  )
  assert_true(
    receipt.contains("\"etag\": \"\\\"bundle_sha256_remoteexisting\\\"\""),
  )
  assert_true(receipt.contains("\"provenance\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish uses provenance etag from remote receipt transform" {
  let repo = "src/cmd/publish/tmp_publish_remote_receipt_etag"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      {
        "schemaVersion": "codeiq-publish-receipt/v1",
        "publishId": "pub_remote_etag",
        "bundleId": "bundle_sha256_remoteexisting",
        "purl": "pkg:generic/local/bundle@0",
        "digest": "sha256:01054985999c3b8016a6f7d5d192f2da23d44f3317792222aa621a6ea6daba27",
        "bundleType": "ciq-bundle",
        "downloadUrl": "local://\{bundle_path}",
        "status": "already-exists",
        "provenance": {
          "source": "remote-registry",
          "digestVerified": true,
          "etag": "\"custom-receipt-etag\"",
        },
      } : Json).stringify(indent=2),
  )
  @sys.set_env_var(
    "CODEIQ_REGISTRY_IF_NONE_MATCH", "\"bundle_sha256_remoteexisting\"",
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish with remote receipt response should succeed")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"etag\": \"\\\"custom-receipt-etag\\\"\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish fails when remote receipt digest mismatched" {
  let repo = "src/cmd/publish/tmp_publish_remote_digest_mismatch"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_remote_bad",
      #|  "bundleId": "bundle_sha256_remote_bad",
      #|  "purl": "pkg:generic/local/bundle@0",
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

  let out = run({ bundle_file: bundle_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("publish should fail when remote digest mismatched")
  }
  let text = error.to_string()
  assert_true(text.contains("digest mismatch"))

  cleanup_tmp_repo(repo)
}

///|
test "publish fails when remote already-exists digest mismatched" {
  let repo = "src/cmd/publish/tmp_publish_remote_304_digest_mismatch"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 304,
      #|  "purl": "pkg:generic/local/bundle@0",
      #|  "bundleId": "bundle_sha256_remoteexisting",
      #|  "digest": "sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
      #|  "etag": "\"bundle_sha256_remoteexisting\"",
      #|  "downloadUrl": "local://src/cmd/publish/tmp_publish_remote_304_digest_mismatch/dist/bundle.ciq.tgz",
      #|  "notModified": true
      #|}
    ),
  )
  @sys.set_env_var(
    "CODEIQ_REGISTRY_IF_NONE_MATCH", "\"bundle_sha256_remoteexisting\"",
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("publish should fail for already-exists digest mismatch")
  }
  let text = error.to_string()
  assert_true(
    text.contains("registry digest mismatch for already-exists receipt"),
  )

  cleanup_tmp_repo(repo)
}

///|
test "publish fails when remote already-exists digest format invalid" {
  let repo = "src/cmd/publish/tmp_publish_remote_304_invalid_digest"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 304,
      #|  "purl": "pkg:generic/local/bundle@0",
      #|  "bundleId": "bundle_sha256_remoteexisting",
      #|  "digest": "sha256:not-a-valid-digest",
      #|  "etag": "\"bundle_sha256_remoteexisting\"",
      #|  "downloadUrl": "local://src/cmd/publish/tmp_publish_remote_304_invalid_digest/dist/bundle.ciq.tgz",
      #|  "notModified": true
      #|}
    ),
  )
  @sys.set_env_var(
    "CODEIQ_REGISTRY_IF_NONE_MATCH", "\"bundle_sha256_remoteexisting\"",
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("publish should fail for invalid already-exists digest format")
  }
  let text = error.to_string()
  assert_true(
    text.contains("invalid sha256 digest in remote download response"),
  )

  cleanup_tmp_repo(repo)
}

///|
test "publish receipt includes signature metadata from registry response" {
  let repo = "src/cmd/publish/tmp_publish_signature_metadata"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  let upload_response : Json = {
    "schemaVersion": "codeiq-publish-receipt/v1",
    "publishId": "pub_remote_sig",
    "bundleId": "bundle_sha256_remote_sig",
    "purl": "pkg:generic/local/bundle@0",
    "digest": "sha256:01054985999c3b8016a6f7d5d192f2da23d44f3317792222aa621a6ea6daba27",
    "bundleType": "ciq-bundle",
    "downloadUrl": "https://registry.example.test/api/v1/bundles/bundle_sha256_remote_sig/download",
    "status": "published",
    "provenance": {
      "source": "remote-registry",
      "digestVerified": true,
      "etag": "\"bundle_sha256_remote_sig\"",
      "signature": {
        "status": "verified",
        "algorithm": "sha256",
        "keyId": "acme-main",
        "value": "ZmFrZS1zaWduYXR1cmU=",
      },
    },
  }
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    upload_response.stringify(indent=2),
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish should succeed with verified signature metadata")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"signature\""))
  assert_true(receipt.contains("\"status\": \"verified\""))
  assert_true(receipt.contains("\"keyId\": \"acme-main\""))
  assert_true(receipt.contains("\"value\": \""))

  cleanup_tmp_repo(repo)
}

///|
test "publish downgrades verified signature without value to untrusted" {
  let repo = "src/cmd/publish/tmp_publish_verified_without_value"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE", bundle_path)
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_remote_no_sig_value",
      #|  "bundleId": "bundle_sha256_remote_no_sig_value",
      #|  "purl": "pkg:generic/local/bundle@0",
      #|  "digest": "sha256:01054985999c3b8016a6f7d5d192f2da23d44f3317792222aa621a6ea6daba27",
      #|  "bundleType": "ciq-bundle",
      #|  "downloadUrl": "https://registry.example.test/api/v1/bundles/bundle_sha256_remote_no_sig_value/download",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_remote_no_sig_value\"",
      #|    "signature": {
      #|      "status": "verified",
      #|      "algorithm": "sha256",
      #|      "keyId": "acme-main"
      #|    }
      #|  }
      #|}
    ),
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("publish should fail when verified signature has no value")
  }
  assert_true(error.to_string().contains("signature status is untrusted"))

  cleanup_tmp_repo(repo)
}

///|
test "publish allows downgraded untrusted signature for local loopback registry" {
  let repo = "src/cmd/publish/tmp_publish_local_loopback_untrusted"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE", bundle_path)
  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "http://localhost:8787")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_local_loopback_no_sig_value",
      #|  "bundleId": "bundle_sha256_local_loopback_no_sig_value",
      #|  "purl": "pkg:generic/local/bundle@0",
      #|  "digest": "sha256:01054985999c3b8016a6f7d5d192f2da23d44f3317792222aa621a6ea6daba27",
      #|  "bundleType": "ciq-bundle",
      #|  "downloadUrl": "http://localhost:8787/api/v1/bundles/bundle_sha256_local_loopback_no_sig_value/download",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_local_loopback_no_sig_value\"",
      #|    "signature": {
      #|      "status": "verified",
      #|      "algorithm": "sha256",
      #|      "keyId": "acme-main"
      #|    }
      #|  }
      #|}
    ),
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish should allow downgraded trust for local loopback registry")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"signature\""))
  assert_true(receipt.contains("\"status\": \"untrusted\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish fails when remote signature status is untrusted" {
  let repo = "src/cmd/publish/tmp_publish_untrusted_signature"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "https://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_remote_untrusted",
      #|  "bundleId": "bundle_sha256_remote_untrusted",
      #|  "purl": "pkg:generic/local/bundle@0",
      #|  "digest": "sha256:01054985999c3b8016a6f7d5d192f2da23d44f3317792222aa621a6ea6daba27",
      #|  "bundleType": "ciq-bundle",
      #|  "downloadUrl": "https://registry.example.test/api/v1/bundles/bundle_sha256_remote_untrusted/download",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_remote_untrusted\"",
      #|    "signature": {
      #|      "status": "untrusted",
      #|      "algorithm": "sha256",
      #|      "keyId": "unknown-key"
      #|    }
      #|  }
      #|}
    ),
  )

  let out = run({ bundle_file: bundle_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("publish should fail for untrusted signature")
  }
  let text = error.to_string()
  assert_true(text.contains("signature status is untrusted"))

  cleanup_tmp_repo(repo)
}
