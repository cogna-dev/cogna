///|
fn registry_cleanup_tmp_dir(dir : String) -> Unit {
  @fs.remove_file("\{dir}/codeiq.yaml") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/upload.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/publish.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(dir) catch {
    _ => ()
  }
}

///|
fn registry_cleanup_runtime_state() -> Unit {
  @fs.remove_dir(".codeiq/registry/index") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq/registry/bundles") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq/registry/http") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq/registry") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq/cache/registry/index") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq/cache/registry/bundles") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq/cache/registry") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq/cache") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq") catch {
    _ => ()
  }
  @sys.unset_env_var("CODEIQ_REGISTRY_BASE_URL")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  @sys.unset_env_var("CODEIQ_SIGNATURE_STATUS")
  @sys.unset_env_var("CODEIQ_SIGNATURE_KEY_ID")
  @sys.unset_env_var("CODEIQ_SIGNATURE_VALUE")
  @sys.unset_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE")
  @sys.unset_env_var("CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP")
}

///|
fn write_registry_upload_request(bundle_file : String) -> String {
  let bytes = @fs.read_file_to_bytes(bundle_file) catch {
    _ => abort("failed to read bundle fixture")
  }
  let upload_request : Json = {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_file,
    "bundleType": "ciq-bundle",
    "purl": "pkg:openapi/acme/payment-api@2026.03.01",
    "digest": "sha256:\{@sha256.sha256_hexdigest(bytes)}",
    "size": bytes.length(),
  }
  let path = bundle_file.replace_all(old="bundle.ciq.tgz", new="upload.json")
  @fs.write_string_to_file(path, upload_request.stringify(indent=2)) catch {
    _ => abort("failed to write upload request fixture")
  }
  path
}

///|
test "e2e registry loop covers upload resolve publish and materialize" {
  let dir = "src/e2e/tmp_codeiq_e2e_registry"
  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
  @fs.create_dir(dir)

  let output_path = "\{dir}/codeiq.yaml"
  let init_out = @init_cmd.run(@init_cmd.InitParams::{ output_path })
  guard init_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("init should succeed before registry loop")
  }

  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: dir })
  guard build_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("build should succeed before registry loop")
  }

  let bundle_file = "\{dir}/dist/bundle.ciq.tgz"
  assert_true(@fs.path_exists(bundle_file))
  let upload_request_file = write_registry_upload_request(bundle_file)

  let upload_out = @registry_cmd.run_upload_local({ upload_request_file, })
  guard upload_out is Ok(uploaded) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("registry upload-local should succeed")
  }
  let upload_receipt = uploaded.receipt.stringify(indent=2)
  assert_true(upload_receipt.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""))
  assert_true(upload_receipt.contains("\"status\": \"published\""))

  let download_out = @registry_cmd.run_download_local({
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
  })
  guard download_out is Ok(downloaded) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("registry download-local should succeed")
  }
  let download_response = downloaded.response.stringify(indent=2)
  assert_true(download_response.contains("\"schemaVersion\": \"codeiq-registry-download/v1\""))
  assert_true(download_response.contains("\"status\": 200"))

  let publish_out = @publish_cmd.run(@publish_cmd.PublishParams::{ bundle_file })
  guard publish_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("publish should succeed in registry loop")
  }
  let publish_receipt = @fs.read_file_to_string("\{dir}/dist/publish.json") catch {
    _ => ""
  }
  assert_true(publish_receipt.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""))
  assert_true(
    publish_receipt.contains("\"status\": \"published\"") ||
    publish_receipt.contains("\"status\": \"already-exists\""),
  )

  let output_dir = "\{dir}/materialized"
  let materialize_out = @registry_cmd.run_download_bundle({
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
    output_dir,
  })
  guard materialize_out is Ok(result) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("registry download should materialize bundle")
  }
  assert_true(result.summary.contains("Downloaded and materialized bundle"))
  assert_true(@fs.path_exists("\{output_dir}/manifest.json"))
  assert_true(@fs.path_exists("\{output_dir}/declarations.ndjson"))
  assert_true(@fs.path_exists("\{output_dir}/symbols.ndjson"))
  assert_true(@fs.path_exists("\{output_dir}/metadata.json"))
  assert_true(@fs.path_exists("\{output_dir}/checksums.txt"))

  @fs.remove_file("\{output_dir}/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{output_dir}/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{output_dir}/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{output_dir}/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{output_dir}/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_dir(output_dir) catch {
    _ => ()
  }
  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
}

///|
test "e2e registry remote http requires explicit insecure opt-in" {
  let dir = "src/e2e/tmp_codeiq_e2e_registry_remote_http"
  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
  @fs.create_dir(dir)

  let bundle_file = "\{dir}/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_file, "bundle fixture") catch {
    _ => abort("failed to write bundle fixture")
  }
  let bundle_bytes = @fs.read_file_to_bytes(bundle_file) catch {
    _ => abort("failed to read bundle fixture")
  }
  let digest = "sha256:\{@sha256.sha256_hexdigest(bundle_bytes)}"
  let remote_upload_receipt : Json = {
    "schemaVersion": "codeiq-publish-receipt/v1",
    "publishId": "pub_remote_http_gate",
    "bundleId": "bundle_sha256_remote_http_gate",
    "purl": "pkg:generic/local/bundle@0",
    "digest": digest,
    "bundleType": "ciq-bundle",
    "downloadUrl": "http://registry.example.test/api/v1/bundles/bundle_sha256_remote_http_gate/download",
    "status": "published",
    "provenance": {
      "source": "remote-registry",
      "digestVerified": true,
      "etag": "\"bundle_sha256_remote_http_gate\"",
    },
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "http://registry.example.test")
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    remote_upload_receipt.stringify(indent=2),
  )

  let blocked = @publish_cmd.run(@publish_cmd.PublishParams::{ bundle_file })
  guard blocked is Err(error) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("publish should reject insecure remote http by default")
  }
  assert_true(
    error
    .to_string()
    .contains("requires https or CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP=true"),
  )

  @sys.set_env_var("CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP", "true")
  let allowed = @publish_cmd.run(@publish_cmd.PublishParams::{ bundle_file })
  guard allowed is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("publish should allow insecure remote http when enabled")
  }

  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
}
