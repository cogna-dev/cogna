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
