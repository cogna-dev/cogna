///|
fn registry_server_cleanup_runtime_state() -> Unit {
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
fn registry_server_cleanup_tmp_dir(dir : String) -> Unit {
  @e2e_shell.run_command_capture("rm -rf '\{dir}'") |> ignore
  @fs.remove_file("\{dir}/codeiq.yml") catch {
    _ => ()
  }
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
  @fs.remove_file("\{dir}/dist/publish.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/publish.json") catch {
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
fn native_registry_target_dir(port : Int) -> String {
  "/tmp/codeiq-registry-\{port}"
}

///|
fn shell_quote(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn spawn_registry_server(port : Int) -> Int {
  let run_script = "/Users/yufei/workspace/github/yufeiminds/codeiq/integrations/cli/run.sh"
  let target_dir = native_registry_target_dir(port)
  let command = "bash \{shell_quote(run_script)} --target native --frozen --target-dir \{shell_quote(target_dir)} -- registry serve --port \{port}"
  let pid_out = @e2e_shell.spawn_detached(command)
  guard pid_out is Ok(pid) else { abort("failed to spawn registry server") }
  pid
}

///|
fn wait_for_health(
  url : String,
  attempts? : Int = 20,
  sleep_ms? : Int = 100,
) -> Bool {
  for _ in 0..<attempts {
    let request_out = @e2e_shell.http_request(
      "GET",
      url,
      {},
      @e2e_shell.HttpBody::Empty,
    )
    match request_out {
      Ok(result) => if result.status == 200 { return true }
      Err(_) => ()
    }
    @e2e_shell.sleep_ms(sleep_ms)
  }
  false
}

///|
fn wait_for_registry_server(port : Int) -> Bool {
  wait_for_health(@registry_cmd.registry_health_url(port), attempts=80, sleep_ms=100)
}

///|
fn stop_registry_server(pid : Int) -> Unit {
  if @e2e_shell.is_alive(pid) {
    ignore(@e2e_shell.terminate(pid))
    for _ in 0..<40 {
      if !@e2e_shell.is_alive(pid) {
        return
      }
      @e2e_shell.sleep_ms(100)
    }
    ignore(@e2e_shell.force_kill(pid))
  }
}

///|
test "e2e registry localhost server supports publish and materialize" {
  let dir = "src/e2e/tmp_codeiq_registry_server"
  let purl = "pkg:openapi/acme/payment-api@2026.03.01"
  registry_server_cleanup_tmp_dir(dir)
  registry_server_cleanup_runtime_state()
  if !@fs.path_exists(dir) {
    @fs.create_dir(dir) catch {
      _ => abort("failed to create registry server tmp dir")
    }
  }
  let init_out = @init_cmd.run(@init_cmd.InitParams::{
    output_path: "\{dir}/codeiq.yml",
  })
  guard init_out is Ok(_) else {
    registry_server_cleanup_tmp_dir(dir)
    registry_server_cleanup_runtime_state()
    fail("init should succeed before registry server flow")
  }
  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: dir })
  guard build_out is Ok(_) else {
    registry_server_cleanup_tmp_dir(dir)
    registry_server_cleanup_runtime_state()
    fail("build should succeed before registry server flow")
  }
  let bundle_file = "\{dir}/dist/bundle.ciq.tgz"
  assert_true(@fs.path_exists(bundle_file))

  let port = 8787
  let pid = spawn_registry_server(port)
  if !wait_for_registry_server(port) {
    stop_registry_server(pid)
    registry_server_cleanup_tmp_dir(dir)
    registry_server_cleanup_runtime_state()
    fail("registry server should become healthy")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_BASE_URL", "http://127.0.0.1:\{port}")
  @sys.set_env_var("CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP", "true")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")

  let publish_out = @publish_cmd.run(@publish_cmd.PublishParams::{
    bundle_file,
  })
  guard publish_out is Ok(_) else {
    stop_registry_server(pid)
    registry_server_cleanup_tmp_dir(dir)
    registry_server_cleanup_runtime_state()
    fail("publish should succeed against localhost registry server")
  }
  let publish_receipt = @fs.read_file_to_string("\{dir}/dist/publish.json") catch {
    _ => ""
  }
  assert_true(
    publish_receipt.contains("\"status\": \"published\"") ||
      publish_receipt.contains("\"status\": \"already-exists\""),
  )

  let output_dir = "\{dir}/materialized"
  let materialize_out = @registry_cmd.run_download_bundle({ purl, output_dir })
  guard materialize_out is Ok(result) else {
    stop_registry_server(pid)
    registry_server_cleanup_tmp_dir(dir)
    registry_server_cleanup_runtime_state()
    fail("download bundle should succeed against localhost registry server")
  }
  assert_true(result.summary.contains("Downloaded and materialized bundle"))
  assert_true(@fs.path_exists("\{output_dir}/manifest.json"))
  assert_true(@fs.path_exists("\{output_dir}/metadata.json"))

  stop_registry_server(pid)
  registry_server_cleanup_tmp_dir(dir)
  registry_server_cleanup_runtime_state()
}
