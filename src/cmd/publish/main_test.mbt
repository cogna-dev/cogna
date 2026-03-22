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
  remove_dir_if_exists(".codeiq/registry/index")
  remove_dir_if_exists(".codeiq/registry/bundles")
  remove_dir_if_exists(".codeiq/registry")
  remove_dir_if_exists(".codeiq")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
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
