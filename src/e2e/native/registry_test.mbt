///|
fn registry_cleanup_tmp_dir(dir : String) -> Unit {
  @e2e_shell.run_command_capture("rm -rf '\{dir}'") |> ignore
  @fs.remove_file("\{dir}/codeiq.yml") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/codeiq.yaml") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/publish.json") catch {
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
  @fs.remove_file("\{dir}/dist/software-components.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/sbom.spdx.json") catch {
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
  @fs.remove_file("\{dir}/materialized/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/materialized/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/materialized/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/materialized/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/materialized/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/materialized") catch {
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
  @fs.remove_dir("src/e2e/tmp_registry_store/index") catch {
    _ => ()
  }
  @fs.remove_dir("src/e2e/tmp_registry_store/bundles") catch {
    _ => ()
  }
  @fs.remove_dir("src/e2e/tmp_registry_store") catch {
    _ => ()
  }
  @fs.remove_dir(".codeiq") catch {
    _ => ()
  }
  @sys.unset_env_var("CODEIQ_REGISTRY_STORE_DIR")
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
fn registry_upload_request(path : String, bundle_file : String, purl : String) -> Json {
  let bytes = @fs.read_file_to_bytes(bundle_file) catch {
    _ => abort("failed to read bundle fixture")
  }
  let upload_request : Json = {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_file,
    "bundleType": "ciq-bundle",
    "purl": purl,
    "digest": "sha256:\{@sha256.sha256_hexdigest(bytes)}",
    "size": bytes.length(),
  }
  @fs.write_string_to_file(path, upload_request.stringify(indent=2)) catch {
    _ => abort("failed to write upload request fixture")
  }
  upload_request
}

///|
test "e2e registry flow supports upload download publish and materialize" {
  let dir = "src/e2e/tmp_codeiq_registry"
  let purl = "pkg:generic/acme/demo@0.3.0"
  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
  @fs.create_dir(dir)

  let output_path = "\{dir}/codeiq.yaml"
  let init_out = @init_cmd.run(@init_cmd.InitParams::{ output_path, })
  guard init_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("init should succeed before registry e2e flow")
  }

  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: dir })
  guard build_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("build should succeed before registry e2e flow")
  }

  let bundle_file = "\{dir}/dist/bundle.ciq.tgz"
  assert_true(@fs.path_exists(bundle_file))

  let upload_request_file = "\{dir}/dist/upload.json"
  ignore(registry_upload_request(upload_request_file, bundle_file, purl))
  let upload_out = @registry_cmd.run_upload_local({ upload_request_file, })
  guard upload_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("registry upload should succeed")
  }

  let download_out = @registry_cmd.run_download_local({ purl, })
  guard download_out is Ok(download) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("registry download should succeed")
  }
  let download_text = download.response.stringify(indent=2)
  assert_true(download_text.contains("\"status\": 200"))

  let publish_out = @publish_cmd.run(@publish_cmd.PublishParams::{
    bundle_file,
  })
  guard publish_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("publish should succeed against local registry store")
  }
  let publish_receipt = @fs.read_file_to_string("\{dir}/dist/publish.json") catch {
    _ => ""
  }
  assert_true(publish_receipt.contains("\"status\": \"published\"") || publish_receipt.contains("\"status\": \"already-exists\""))

  let output_dir = "\{dir}/materialized"
  let materialize_out = @registry_cmd.run_download_bundle({ purl, output_dir })
  guard materialize_out is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("registry bundle materialization should succeed")
  }
  assert_true(@fs.path_exists("\{output_dir}/manifest.json"))
  assert_true(@fs.path_exists("\{output_dir}/declarations.ndjson"))
  assert_true(@fs.path_exists("\{output_dir}/symbols.ndjson"))
  assert_true(@fs.path_exists("\{output_dir}/metadata.json"))
  assert_true(@fs.path_exists("\{output_dir}/checksums.txt"))

  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
}

///|
test "registry publish blocks insecure http unless explicitly allowed" {
  let dir = "src/e2e/tmp_codeiq_registry_remote"
  let bundle_file = "\{dir}/dist/bundle.ciq.tgz"
  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
  @fs.create_dir(dir)
  @fs.create_dir("\{dir}/dist")
  @fs.write_string_to_file(bundle_file, "bundle fixture") catch {
    _ => abort("failed to write remote bundle fixture")
  }
  let bundle_bytes = @fs.read_file_to_bytes(bundle_file) catch {
    _ => abort("failed to read remote bundle fixture")
  }
  let digest = "sha256:\{@sha256.sha256_hexdigest(bundle_bytes)}"
  let upload_request : Json = {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_file,
    "bundleType": "ciq-bundle",
    "purl": "pkg:generic/acme/demo@0.9.0",
    "digest": digest,
    "size": bundle_bytes.length(),
  }
  @fs.write_string_to_file(
    "\{dir}/dist/upload.json",
    upload_request.stringify(indent=2),
  ) catch {
    _ => abort("failed to write remote upload request")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "http://registry.example.test")
  let remote_upload_response : Json = {
    "schemaVersion": "codeiq-publish-receipt/v1",
    "publishId": "pub_remote_demo",
    "bundleId": "bundle_demo",
    "purl": "pkg:generic/local/bundle@0",
    "digest": digest,
    "bundleType": "ciq-bundle",
    "downloadUrl": "http://registry.example.test/api/v1/bundles/bundle_demo/download",
    "status": "published",
    "provenance": {
      "source": "remote-registry",
      "digestVerified": true,
      "etag": "\"bundle_demo\"",
      "signature": { "status": "unsigned", "algorithm": "sha256" },
    },
  }
  @sys.set_env_var(
    "CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON",
    remote_upload_response.stringify(indent=2),
  )
  let blocked = @publish_cmd.run(@publish_cmd.PublishParams::{ bundle_file, })
  guard blocked is Err(error) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("publish should reject insecure http by default")
  }
  assert_true(error.message.contains("requires https or CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP=true"))

  @sys.set_env_var("CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP", "true")
  let allowed = @publish_cmd.run(@publish_cmd.PublishParams::{ bundle_file, })
  guard allowed is Ok(_) else {
    registry_cleanup_tmp_dir(dir)
    registry_cleanup_runtime_state()
    fail("publish should allow insecure http when opted in")
  }

  registry_cleanup_tmp_dir(dir)
  registry_cleanup_runtime_state()
}
