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
  remove_file_if_exists("\{repo}/dist/base/declarations.ndjson.zst")
  remove_file_if_exists("\{repo}/dist/base/symbols.ndjson.zst")
  remove_file_if_exists("\{repo}/dist/target/manifest.json")
  remove_file_if_exists("\{repo}/dist/target/declarations.ndjson.zst")
  remove_file_if_exists("\{repo}/dist/target/symbols.ndjson.zst")
  remove_file_if_exists("\{repo}/dist/diff.json")
  remove_dir_if_exists("\{repo}/dist/base")
  remove_dir_if_exists("\{repo}/dist/target")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
}

///|
fn write_manifest(path : String, purl : String, profile : String) -> Unit {
  let sha = @sha256.sha256_hexdigest(@utf8.encode("fixture"))
  let content : Json = {
    "schemaVersion": "ciq-bundle/v1",
    "purl": purl,
    "profile": profile,
    "declarationSchema": {
      "version": "ciq-declarations/v1",
      "format": "ndjson.zst",
      "model": "signature + shape + language_specific tagged union",
    },
    "source": {
      "repo": "https://github.com/acme/payment-api",
      "ref": "main",
      "commit": "1234567890abcdef1234567890abcdef12345678",
    },
    "artifacts": [
      {
        "path": "declarations.ndjson.zst",
        "sha256": sha,
        "compression": "zstd",
      },
    ],
  }
  @fs.write_string_to_file(path, content.stringify(indent=2)) catch {
    _ => abort("failed to write manifest fixture")
  }
}

///|
fn write_records(path : String, lines : String) -> Unit {
  let compressed = @zstd.compress(@utf8.encode(lines)) catch {
    _ => abort("failed to compress records fixture")
  }
  @fs.write_bytes_to_file(path, compressed) catch {
    _ => abort("failed to write records fixture")
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

  let base_declarations =
    #|{"id":"decl:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|{"id":"decl:payment:remove","kind":"operation","path":"openapi/payment.yaml","signature":"operation removePayment","location":{"uri":"openapi/payment.yaml","startLine":30,"endLine":40}}
    #|
  let base_symbols =
    #|{"id":"sym:payment:create","kind":"symbol","path":"openapi/payment.yaml","signature":"symbol createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":10}}
    #|
  let target_declarations =
    #|{"id":"decl:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPaymentV2","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|{"id":"decl:payment:add","kind":"operation","path":"openapi/payment.yaml","signature":"operation addPayment","location":{"uri":"openapi/payment.yaml","startLine":50,"endLine":60}}
    #|
  let target_symbols =
    #|{"id":"sym:payment:create","kind":"symbol","path":"openapi/payment.yaml","signature":"symbol createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":10}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson.zst", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson.zst", base_symbols)
  write_records(
    "\{repo}/dist/target/declarations.ndjson.zst",
    target_declarations,
  )
  write_records("\{repo}/dist/target/symbols.ndjson.zst", target_symbols)

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ declaration diff at src/cmd/diff/tmp_diff_repo/dist/diff.json",
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
  assert_true(diff_text.contains("\"kind\": \"added\""))
  assert_true(diff_text.contains("\"kind\": \"removed\""))
  assert_true(diff_text.contains("\"kind\": \"changed\""))
  assert_true(diff_text.contains("\"decl:payment:add\""))
  assert_true(diff_text.contains("\"decl:payment:remove\""))
  assert_true(diff_text.contains("\"decl:payment:create\""))

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

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("diff should fail when base manifest is missing")
  }

  let text = error.to_string()
  assert_true(text.contains("diff failed:"))
  assert_true(text.contains("base/manifest.json"))

  cleanup_tmp_repo(repo)
}

///|
test "diff includes since and test changes fields when requested" {
  let repo = "src/cmd/diff/tmp_diff_since_test_changes"
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

  let records =
    #|{"id":"decl:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  write_records("\{repo}/dist/base/declarations.ndjson.zst", records)
  write_records("\{repo}/dist/base/symbols.ndjson.zst", records)
  write_records("\{repo}/dist/target/declarations.ndjson.zst", records)
  write_records("\{repo}/dist/target/symbols.ndjson.zst", records)

  let out = run({
    repo,
    since: Some("2026-03-01T00:00:00Z"),
    include_test_changes: true,
  })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed with since and test-changes")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"since\": \"2026-03-01T00:00:00Z\""))
  assert_true(diff_text.contains("\"includeTestChanges\": true"))
  assert_true(diff_text.contains("\"testSummary\""))
  assert_true(diff_text.contains("\"testChanges\": []"))

  cleanup_tmp_repo(repo)
}

///|
test "diff computes go test changes when requested" {
  let repo = "src/cmd/diff/tmp_diff_go_test_changes"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:golang/example/demo@0.1.0",
    "go-module",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:golang/example/demo@0.2.0",
    "go-module",
  )

  let base_declarations =
    #|{"id":"decl:go-module:demo::math_test.go::TestAdd","kind":"function","name":"TestAdd","path":"math_test.go","signature":"func TestAdd(t *testing.T)","language":"go","location":{"uri":"math_test.go","startLine":12,"endLine":12}}
    #|{"id":"decl:go-module:demo::math_test.go::TestRemoved","kind":"function","name":"TestRemoved","path":"math_test.go","signature":"func TestRemoved(t *testing.T)","language":"go","location":{"uri":"math_test.go","startLine":28,"endLine":28}}
    #|
  let target_declarations =
    #|{"id":"decl:go-module:demo::math_test.go::TestAdd","kind":"function","name":"TestAdd","path":"math_test.go","signature":"func TestAdd(t *testing.T) // v2","language":"go","location":{"uri":"math_test.go","startLine":14,"endLine":14}}
    #|{"id":"decl:go-module:demo::math_test.go::TestAdded","kind":"function","name":"TestAdded","path":"math_test.go","signature":"func TestAdded(t *testing.T)","language":"go","location":{"uri":"math_test.go","startLine":40,"endLine":40}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson.zst", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson.zst", "")
  write_records(
    "\{repo}/dist/target/declarations.ndjson.zst",
    target_declarations,
  )
  write_records("\{repo}/dist/target/symbols.ndjson.zst", "")

  let out = run({
    repo,
    since: Some("2026-03-01T00:00:00Z"),
    include_test_changes: true,
  })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should compute go test changes")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"includeTestChanges\": true"))
  assert_true(diff_text.contains("\"testSummary\": {"))
  assert_true(diff_text.contains("\"added\": 1"))
  assert_true(diff_text.contains("\"modified\": 1"))
  assert_true(diff_text.contains("\"removed\": 1"))
  assert_true(
    diff_text.contains(
      "\"id\": \"test:go-module:demo::math_test.go::TestAdded\"",
    ),
  )
  assert_true(
    diff_text.contains(
      "\"id\": \"test:go-module:demo::math_test.go::TestRemoved\"",
    ),
  )
  assert_true(diff_text.contains("\"kind\": \"modified\""))

  cleanup_tmp_repo(repo)
}
