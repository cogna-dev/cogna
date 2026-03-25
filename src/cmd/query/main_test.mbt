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
  remove_file_if_exists("\{repo}/query.json")
  remove_file_if_exists("\{repo}/query.result.json")
  remove_file_if_exists("\{repo}/dist/declarations.ndjson")
  remove_file_if_exists("\{repo}/dist/symbols.ndjson")
  remove_file_if_exists("\{repo}/dist/manifest.json")
  remove_file_if_exists("\{repo}/dist/metadata.json")
  remove_file_if_exists("\{repo}/dist/checksums.txt")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
}

///|
fn write_query(path : String) -> Unit {
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "payment::create", "kind": "operation" },
    "intent": "upgrade",
  }
  @fs.write_string_to_file(path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }
}

///|
test "query generates ciq result from query file" {
  let repo = "src/cmd/query/tmp_query_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let query_path = "\{repo}/query.json"
  write_query(query_path)

  let out = run({ query_file: query_path })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ result at src/cmd/query/tmp_query_repo/query.result.json",
  )

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("\"schemaVersion\": \"ciq-result/v1\""))
  assert_true(
    result_json.contains(
      "\"purl\": \"pkg:openapi/acme/payment-api@2026.04.01\"",
    ),
  )
  assert_true(result_json.contains("\"matches\": []"))

  cleanup_tmp_repo(repo)
}

///|
test "query uses local declarations when repo is provided" {
  let repo = "src/cmd/query/tmp_query_repo_with_bundle"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "openapi/payment.yaml", "kind": "operation" },
    "intent": "upgrade",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }

  let declarations =
    #|{"id":"decl:openapi:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write declarations fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("operation createPayment"))
  assert_true(result_json.contains("decl:openapi:payment:create"))

  cleanup_tmp_repo(repo)
}

///|
test "query uses symbols when declaration kind does not match" {
  let repo = "src/cmd/query/tmp_query_repo_symbols"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "openapi/payment.yaml", "kind": "symbol" },
    "intent": "lookup",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }

  let declarations =
    #|{"id":"decl:openapi:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  let symbols =
    #|{"id":"sym:openapi:payment:create","kind":"symbol","path":"openapi/payment.yaml","signature":"symbol createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":10}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write declarations fixture")
  }
  @fs.write_string_to_file("\{repo}/dist/symbols.ndjson", symbols) catch {
    _ => abort("failed to write symbols fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("symbol createPayment"))
  assert_true(result_json.contains("sym:openapi:payment:create"))

  cleanup_tmp_repo(repo)
}

///|
test "query fails when schemaVersion is invalid" {
  let repo = "src/cmd/query/tmp_query_bad_schema"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let query_path = "\{repo}/query.json"
  let bad_query : Json = {
    "schemaVersion": "ciq-query/v0",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "payment::create", "kind": "operation" },
  }
  @fs.write_string_to_file(query_path, bad_query.stringify(indent=2)) catch {
    _ => abort("failed to write bad query fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("query should fail for invalid schemaVersion")
  }

  let text = error.to_string()
  assert_true(text.contains("query failed:"))
  assert_true(text.contains("ciq-query/v1 schema"))

  cleanup_tmp_repo(repo)
}
