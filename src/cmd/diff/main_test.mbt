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
  remove_file_if_exists("\{repo}/dist/base/manifest.json")
  remove_file_if_exists("\{repo}/dist/target/manifest.json")
  remove_file_if_exists("\{repo}/dist/diff.json")
  remove_dir_if_exists("\{repo}/dist/base")
  remove_dir_if_exists("\{repo}/dist/target")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
}

///|
fn write_manifest(path : String, purl : String, profile : String) -> Unit {
  let content : Json = {
    "schemaVersion": "ciq-bundle/v1",
    "purl": purl,
    "profile": profile,
  }
  @fs.write_string_to_file(path, content.stringify(indent=2)) catch {
    _ => abort("failed to write manifest fixture")
  }
}

///|
test "diff generates skeleton diff output" {
  let repo = "src/cmd/diff/tmp_diff_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:openapi/acme/payment-api@2026.03.01",
    "openapi-spec",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )

  let out = run({ repo, })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ diff skeleton at src/cmd/diff/tmp_diff_repo/dist/diff.json",
  )

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"schemaVersion\": \"ciq-diff/v1\""))
  assert_true(
    diff_text.contains(
      "\"basePurl\": \"pkg:openapi/acme/payment-api@2026.03.01\"",
    ),
  )
  assert_true(
    diff_text.contains(
      "\"targetPurl\": \"pkg:openapi/acme/payment-api@2026.04.01\"",
    ),
  )
  assert_true(diff_text.contains("\"id\": \"manifest:purl\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff fails when base manifest is missing" {
  let repo = "src/cmd/diff/tmp_diff_missing_base"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/target")
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )

  let out = run({ repo, })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("diff should fail when base manifest is missing")
  }

  let text = error.to_string()
  assert_true(text.contains("diff failed:"))
  assert_true(text.contains("base/manifest.json"))

  cleanup_tmp_repo(repo)
}
