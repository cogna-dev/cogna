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
fn cleanup_output(root : String) -> Unit {
  remove_file_if_exists("\{root}/policies.mdx")
  remove_file_if_exists("\{root}/policies/generated/rust/signature-changed.mdx")
  remove_dir_if_exists("\{root}/policies/generated/core")
  remove_dir_if_exists("\{root}/policies/generated/go")
  remove_dir_if_exists("\{root}/policies/generated/rust")
  remove_dir_if_exists("\{root}/policies/generated/terraform")
  remove_dir_if_exists("\{root}/policies/generated/openapi")
  remove_dir_if_exists("\{root}/policies/generated/component")
  remove_dir_if_exists("\{root}/policies/generated")
  remove_dir_if_exists("\{root}/policies")
  remove_dir_if_exists(root)
}

///|
test "policy docs generator writes index and per-rule pages" {
  let root = "src/scripts/gendoc/tmp_docs_output"
  cleanup_output(root)

  let out = run({
    output_dir: "\{root}/policies/generated",
    index_file: "\{root}/policies.mdx",
  })
  guard out is Ok(result) else {
    cleanup_output(root)
    fail("policy docs generator should succeed")
  }

  inspect(
    result.display(),
    content="Generated built-in policy docs at src/scripts/gendoc/tmp_docs_output/policies.mdx and src/scripts/gendoc/tmp_docs_output/policies/generated",
  )

  let index_text = @fs.read_file_to_string("\{root}/policies.mdx") catch {
    _ => {
      cleanup_output(root)
      fail("policy docs index should exist")
      ""
    }
  }
  assert_true(index_text.contains("内置策略规则"))
  assert_true(index_text.contains("compat.go.signature-changed"))
  assert_true(index_text.contains("/docs/policies/generated/rust/signature-changed"))

  let rule_text = @fs.read_file_to_string(
    "\{root}/policies/generated/rust/signature-changed.mdx",
  ) catch {
    _ => {
      cleanup_output(root)
      fail("per-rule policy page should exist")
      ""
    }
  }
  assert_true(rule_text.contains("compat.rust.signature-changed"))
  assert_true(
    rule_text.contains(
      "https://codeiq.xaclabs.dev/docs/policies/generated/rust/signature-changed",
    ),
  )
  assert_true(rule_text.contains("Rust public signature changed."))

  cleanup_output(root)
}
