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
  remove_file_if_exists("\{repo}/dist/diff.json")
  remove_file_if_exists("\{repo}/dist/check.sarif.json")
  remove_file_if_exists("\{repo}/dist/policy.ciq.tgz")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
}

///|
fn write_diff(path : String, base_purl : String, target_purl : String) -> Unit {
  let content : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": base_purl,
    "targetPurl": target_purl,
    "summary": { "added": 0, "removed": 0, "changed": 1, "deprecated": 0 },
    "changes": [
      {
        "kind": "changed",
        "id": "manifest:purl",
        "path": "manifest.purl",
        "level": "warning",
      },
    ],
  }
  @fs.write_string_to_file(path, content.stringify(indent=2)) catch {
    _ => abort("failed to write diff fixture")
  }
}

///|
test "check generates sarif from diff and policy" {
  let repo = "src/cmd/check/tmp_check_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policy.ciq.tgz"
  write_diff(
    diff_path, "pkg:openapi/acme/payment-api@2026.03.01", "pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.write_string_to_file(policy_path, "policy placeholder") catch {
    _ => abort("failed to write policy fixture")
  }

  let out = run({ diff_file: diff_path, policy_bundle: policy_path })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed")
  }

  inspect(
    result.display(),
    content="Generated SARIF report at src/cmd/check/tmp_check_repo/dist/check.sarif.json",
  )

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }
  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(sarif.contains("\"name\": \"codeiq-check\""))
  assert_true(sarif.contains("\"ruleId\": \"compat.changed\""))

  cleanup_tmp_repo(repo)
}

///|
test "check fails when policy bundle is missing" {
  let repo = "src/cmd/check/tmp_check_missing_policy"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  write_diff(
    diff_path, "pkg:openapi/acme/payment-api@2026.03.01", "pkg:openapi/acme/payment-api@2026.04.01",
  )

  let out = run({
    diff_file: diff_path,
    policy_bundle: "\{repo}/dist/policy.ciq.tgz",
  })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("check should fail when policy is missing")
  }

  let text = error.to_string()
  assert_true(text.contains("check failed:"))
  assert_true(text.contains("missing policy bundle file"))

  cleanup_tmp_repo(repo)
}
