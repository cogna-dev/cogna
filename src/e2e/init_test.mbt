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
