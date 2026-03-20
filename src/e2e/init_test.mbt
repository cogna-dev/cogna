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
  assert_true(metadata.contains("\"status\": \"skeleton\""))
  let checksums = @fs.read_file_to_string("\{dir}/dist/checksums.txt")
  assert_true(checksums.contains("manifest.json  placeholder"))

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
  @fs.write_string_to_file("\{dir}/dist/base/manifest.json", manifest)
  let target_manifest = manifest.replace(
    old="pkg:openapi/acme/payment-api@2026.03.01",
    new="pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.write_string_to_file("\{dir}/dist/target/manifest.json", target_manifest)

  let diff_out = @diff_cmd.run(@diff_cmd.DiffParams::{ repo: dir })
  guard diff_out is Ok(result) else {
    cleanup_tmp_dir(dir)
    fail("diff should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ diff skeleton at src/e2e/tmp_codeiq_e2e_diff/dist/diff.json",
  )

  let diff_json = @fs.read_file_to_string("\{dir}/dist/diff.json")
  assert_true(diff_json.contains("\"schemaVersion\": \"ciq-diff/v1\""))
  assert_true(diff_json.contains("\"id\": \"manifest:purl\""))

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
  @fs.write_string_to_file("\{dir}/dist/base/manifest.json", manifest)
  let target_manifest = manifest.replace(
    old="pkg:openapi/acme/payment-api@2026.03.01",
    new="pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.write_string_to_file("\{dir}/dist/target/manifest.json", target_manifest)

  let diff_out = @diff_cmd.run(@diff_cmd.DiffParams::{ repo: dir })
  guard diff_out is Ok(_) else {
    cleanup_tmp_dir(dir)
    fail("diff should succeed before check")
  }

  let policy_path = "\{dir}/dist/policy.ciq.tgz"
  @fs.write_string_to_file(policy_path, "policy placeholder")
  let check_out = @check_cmd.run(@check_cmd.CheckParams::{
    diff_file: "\{dir}/dist/diff.json",
    policy_bundle: policy_path,
  })
  guard check_out is Ok(result) else {
    cleanup_tmp_dir(dir)
    fail("check should succeed")
  }

  inspect(
    result.display(),
    content="Generated SARIF report at src/e2e/tmp_codeiq_e2e_check/dist/check.sarif.json",
  )

  let sarif = @fs.read_file_to_string("\{dir}/dist/check.sarif.json")
  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(sarif.contains("\"ruleId\": \"compat.changed\""))

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
