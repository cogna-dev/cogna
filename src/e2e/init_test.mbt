///|
fn cleanup_tmp_dir(dir : String) -> Unit {
  @fs.remove_file("\{dir}/codeiq.yaml") catch {
    _ => ()
  }
  @fs.remove_dir(dir) catch {
    _ => ()
  }
}

///|
test "e2e init writes config to tmp directory" {
  let dir = "src/e2e/tmp_codeiq_e2e_init"
  cleanup_tmp_dir(dir)
  @fs.create_dir(dir)

  let output_path = "\{dir}/codeiq.yaml"
  let result = @init_cmd.run(@init_cmd.InitParams::{ output_path, })
  guard result is Ok(ok) else { fail("init should succeed") }
  inspect(
    ok.display(),
    content="Generated CIQ config at src/e2e/tmp_codeiq_e2e_init/codeiq.yaml",
  )

  let content = @fs.read_file_to_string(output_path)
  assert_true(content.has_prefix("schemaVersion: ciq-config/v1"))

  cleanup_tmp_dir(dir)
}

///|
test "e2e banner contains codeiq ascii" {
  let banner = @main_cmd.banner()
  assert_true(banner.contains("____"))
}

///|
test "e2e build creates dist skeleton from init config" {
  let dir = "src/e2e/tmp_codeiq_e2e_build"
  cleanup_tmp_dir(dir)
  @fs.create_dir(dir)

  let output_path = "\{dir}/codeiq.yaml"
  let init_out = @init_cmd.run(@init_cmd.InitParams::{ output_path, })
  guard init_out is Ok(_) else {
    cleanup_tmp_dir(dir)
    fail("init should succeed before build")
  }

  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: dir })
  guard build_out is Ok(result) else {
    cleanup_tmp_dir(dir)
    fail("build should succeed with init config")
  }

  inspect(
    result.display(),
    content="Generated CIQ bundle skeleton at src/e2e/tmp_codeiq_e2e_build/dist",
  )

  let manifest = @fs.read_file_to_string("\{dir}/dist/manifest.json")
  assert_true(manifest.contains("\"schemaVersion\": \"ciq-bundle/v1\""))
  let metadata = @fs.read_file_to_string("\{dir}/dist/metadata.json")
  assert_true(metadata.contains("\"status\": \"completed\""))
  assert_true(metadata.contains("\"extractor\""))
  let checksums = @fs.read_file_to_string("\{dir}/dist/checksums.txt")
  assert_true(checksums.contains("manifest.json  "))

  @fs.remove_file("\{dir}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/declarations.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/symbols.ndjson.zst") catch {
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
  @fs.remove_dir("\{dir}/dist") catch {
    _ => ()
  }
  cleanup_tmp_dir(dir)
}

///|
test "e2e diff generates output from base and target manifests" {
  let dir = "src/e2e/tmp_codeiq_e2e_diff"
  cleanup_tmp_dir(dir)
  @fs.create_dir(dir)

  let output_path = "\{dir}/codeiq.yaml"
  let init_out = @init_cmd.run(@init_cmd.InitParams::{ output_path, })
  guard init_out is Ok(_) else {
    cleanup_tmp_dir(dir)
    fail("init should succeed before build")
  }

  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: dir })
  guard build_out is Ok(_) else {
    cleanup_tmp_dir(dir)
    fail("build should succeed before diff")
  }

  @fs.create_dir("\{dir}/dist/base")
  @fs.create_dir("\{dir}/dist/target")
  let manifest = @fs.read_file_to_string("\{dir}/dist/manifest.json")
  let declarations = @fs.read_file_to_bytes(
    "\{dir}/dist/declarations.ndjson.zst",
  )
  let symbols = @fs.read_file_to_bytes("\{dir}/dist/symbols.ndjson.zst")
  @fs.write_string_to_file("\{dir}/dist/base/manifest.json", manifest)
  @fs.write_bytes_to_file(
    "\{dir}/dist/base/declarations.ndjson.zst",
    declarations,
  )
  @fs.write_bytes_to_file("\{dir}/dist/base/symbols.ndjson.zst", symbols)
  let target_manifest = manifest.replace(
    old="pkg:openapi/acme/payment-api@2026.03.01",
    new="pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.write_string_to_file("\{dir}/dist/target/manifest.json", target_manifest)
  @fs.write_bytes_to_file(
    "\{dir}/dist/target/declarations.ndjson.zst",
    declarations,
  )
  @fs.write_bytes_to_file("\{dir}/dist/target/symbols.ndjson.zst", symbols)

  let diff_out = @diff_cmd.run(@diff_cmd.DiffParams::{
    repo: dir,
    since: None,
    include_test_changes: false,
  })
  guard diff_out is Ok(result) else {
    cleanup_tmp_dir(dir)
    fail("diff should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ declaration diff at src/e2e/tmp_codeiq_e2e_diff/dist/diff.json",
  )

  let diff_json = @fs.read_file_to_string("\{dir}/dist/diff.json")
  assert_true(diff_json.contains("\"schemaVersion\": \"ciq-diff/v1\""))
  assert_true(diff_json.contains("\"schemaVersion\": \"ciq-diff/v1\""))

  @fs.remove_file("\{dir}/dist/base/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/target/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/diff.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist/base") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist/target") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/declarations.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/symbols.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist") catch {
    _ => ()
  }
  cleanup_tmp_dir(dir)
}

///|
test "e2e check generates sarif from diff and policy bundle" {
  let dir = "src/e2e/tmp_codeiq_e2e_check"
  cleanup_tmp_dir(dir)
  @fs.create_dir(dir)

  let output_path = "\{dir}/codeiq.yaml"
  let init_out = @init_cmd.run(@init_cmd.InitParams::{ output_path, })
  guard init_out is Ok(_) else {
    cleanup_tmp_dir(dir)
    fail("init should succeed before check flow")
  }

  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: dir })
  guard build_out is Ok(_) else {
    cleanup_tmp_dir(dir)
    fail("build should succeed before check flow")
  }

  @fs.create_dir("\{dir}/dist/base")
  @fs.create_dir("\{dir}/dist/target")
  let manifest = @fs.read_file_to_string("\{dir}/dist/manifest.json")
  let declarations = @fs.read_file_to_bytes(
    "\{dir}/dist/declarations.ndjson.zst",
  )
  let symbols = @fs.read_file_to_bytes("\{dir}/dist/symbols.ndjson.zst")
  @fs.write_string_to_file("\{dir}/dist/base/manifest.json", manifest)
  @fs.write_bytes_to_file(
    "\{dir}/dist/base/declarations.ndjson.zst",
    declarations,
  )
  @fs.write_bytes_to_file("\{dir}/dist/base/symbols.ndjson.zst", symbols)
  let target_manifest = manifest.replace(
    old="pkg:openapi/acme/payment-api@2026.03.01",
    new="pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.write_string_to_file("\{dir}/dist/target/manifest.json", target_manifest)
  @fs.write_bytes_to_file(
    "\{dir}/dist/target/declarations.ndjson.zst",
    declarations,
  )
  @fs.write_bytes_to_file("\{dir}/dist/target/symbols.ndjson.zst", symbols)

  let diff_out = @diff_cmd.run(@diff_cmd.DiffParams::{
    repo: dir,
    since: None,
    include_test_changes: false,
  })
  guard diff_out is Ok(_) else {
    cleanup_tmp_dir(dir)
    fail("diff should succeed before check")
  }

  let policy_path = "\{dir}/dist/policy.ciq.tgz"
  @fs.write_string_to_file(policy_path, "policy placeholder")
  @sys.set_env_var("CODEIQ_OPA_EVAL_JSON", "{\"result\":[]}")
  let check_out = @check_cmd.run(@check_cmd.CheckParams::{
    diff_file: "\{dir}/dist/diff.json",
    policy_bundle: policy_path,
  })
  guard check_out is Ok(result) else {
    @sys.unset_env_var("CODEIQ_OPA_EVAL_JSON")
    cleanup_tmp_dir(dir)
    fail("check should succeed")
  }
  @sys.unset_env_var("CODEIQ_OPA_EVAL_JSON")

  inspect(
    result.display(),
    content="Generated SARIF report at src/e2e/tmp_codeiq_e2e_check/dist/check.sarif.json",
  )

  let sarif = @fs.read_file_to_string("\{dir}/dist/check.sarif.json")
  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(sarif.contains("\"results\": []"))

  @fs.remove_file("\{dir}/dist/base/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/target/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/diff.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/check.sarif.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/policy.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist/base") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist/target") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/declarations.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/symbols.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist") catch {
    _ => ()
  }
  cleanup_tmp_dir(dir)
}

///|
test "e2e query generates result from local query file" {
  let dir = "src/e2e/tmp_codeiq_e2e_query"
  cleanup_tmp_dir(dir)
  @fs.create_dir(dir)

  let query_path = "\{dir}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "payment::create", "kind": "operation" },
    "intent": "upgrade",
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2))

  let query_out = @query_cmd.run(@query_cmd.QueryParams::{
    query_file: query_path,
  })
  guard query_out is Ok(result) else {
    cleanup_tmp_dir(dir)
    fail("query should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ result at src/e2e/tmp_codeiq_e2e_query/query.result.json",
  )

  let result_json = @fs.read_file_to_string("\{dir}/query.result.json")
  assert_true(result_json.contains("\"schemaVersion\": \"ciq-result/v1\""))
  assert_true(result_json.contains("\"matches\": []"))

  @fs.remove_file("\{dir}/query.json") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/query.result.json") catch {
    _ => ()
  }
  cleanup_tmp_dir(dir)
}

///|
test "e2e publish generates publish receipt from local bundle" {
  let dir = "src/e2e/tmp_codeiq_e2e_publish"
  cleanup_tmp_dir(dir)
  @fs.create_dir(dir)

  @fs.create_dir("\{dir}/dist")
  let bundle_file = "\{dir}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_file, "bundle placeholder")

  let publish_out = @publish_cmd.run(@publish_cmd.PublishParams::{
    bundle_file,
  })
  guard publish_out is Ok(result) else {
    cleanup_tmp_dir(dir)
    fail("publish should succeed")
  }

  inspect(
    result.display(),
    content="Generated publish receipt at src/e2e/tmp_codeiq_e2e_publish/dist/publish.json",
  )

  let receipt = @fs.read_file_to_string("\{dir}/dist/publish.json")
  assert_true(
    receipt.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""),
  )
  assert_true(receipt.contains("\"publishId\":"))
  assert_true(receipt.contains("\"bundleType\": \"ciq-bundle\""))

  @fs.remove_file("\{dir}/dist/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_file("\{dir}/dist/publish.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{dir}/dist") catch {
    _ => ()
  }
  cleanup_tmp_dir(dir)
}

///|
