///|
fn remove_dir_tree_if_exists(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  let is_dir_out = try? @fs.is_dir(path)
  match is_dir_out {
    Ok(true) => {
      let entries = @fs.read_dir(path) catch {
        _ => []
      }
      for entry in entries {
        remove_dir_tree_if_exists("\{path}/\{entry}")
      }
      @fs.remove_dir(path) catch {
        _ => ()
      }
    }
    _ => @fs.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
fn cleanup_lsp_e2e(path : String) -> Unit {
  remove_dir_tree_if_exists(path)
}

///|
fn write_openapi_repo(path : String) -> Unit {
  @fs.create_dir(path) catch {
    _ => abort("failed to create lsp e2e repo")
  }
  @fs.create_dir("\{path}/openapi") catch {
    _ => abort("failed to create lsp e2e openapi dir")
  }
  let spec = @fs.read_file_to_string(
    "examples/openapi-spec/full/repo/openapi/payment.yaml",
  ) catch {
    _ => abort("failed to read openapi fixture")
  }
  @fs.write_string_to_file("\{path}/openapi/payment.yaml", spec) catch {
    _ => abort("failed to write openapi fixture")
  }
}

///|
fn write_openapi_config(path : String) -> Unit {
  let content =
    #|schemaVersion: ciq-config/v1
    #|profile: openapi-spec
    #|purl: pkg:openapi/acme/payment-api@2026.03.01
    #|source:
    #|  repo: https://github.com/acme/payment-api
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - openapi/**/*.yaml
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  @fs.write_string_to_file("\{path}/codeiq.yaml", content) catch {
    _ => abort("failed to write openapi config")
  }
}

///|
fn cleanup_review_runtime_state() -> Unit {
  @fs.remove_file("./dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("./dist/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("./dist/query.result.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/check.sarif.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/mcp-server.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/mcp-tools-state.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/opa-bundle.tar.gz") catch {
    _ => ()
  }
  @fs.remove_file("./dist/policy.rules.json") catch {
    _ => ()
  }
}

///|
fn write_review_base_and_target(path : String) -> Unit {
  @fs.create_dir("\{path}/dist/base") catch {
    _ => abort("failed to create review base dir")
  }
  @fs.create_dir("\{path}/dist/target") catch {
    _ => abort("failed to create review target dir")
  }
  let manifest = @fs.read_file_to_string("\{path}/dist/manifest.json") catch {
    _ => abort("failed to read review manifest")
  }
  let declarations = @fs.read_file_to_bytes("\{path}/dist/declarations.ndjson") catch {
    _ => abort("failed to read review declarations")
  }
  let symbols = @fs.read_file_to_bytes("\{path}/dist/symbols.ndjson") catch {
    _ => abort("failed to read review symbols")
  }
  @fs.write_string_to_file("\{path}/dist/base/manifest.json", manifest) catch {
    _ => abort("failed to write review base manifest")
  }
  @fs.write_bytes_to_file("\{path}/dist/base/declarations.ndjson", declarations) catch {
    _ => abort("failed to write review base declarations")
  }
  @fs.write_bytes_to_file("\{path}/dist/base/symbols.ndjson", symbols) catch {
    _ => abort("failed to write review base symbols")
  }
  let target_manifest = manifest.replace(
    old="pkg:openapi/acme/payment-api@2026.03.01",
    new="pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.write_string_to_file("\{path}/dist/target/manifest.json", target_manifest) catch {
    _ => abort("failed to write review target manifest")
  }
  @fs.write_bytes_to_file(
    "\{path}/dist/target/declarations.ndjson",
    declarations,
  ) catch {
    _ => abort("failed to write review target declarations")
  }
  @fs.write_bytes_to_file("\{path}/dist/target/symbols.ndjson", symbols) catch {
    _ => abort("failed to write review target symbols")
  }
}

///|
fn write_review_policy_bundle(path : String) -> String {
  let policy_path = "\{path}/dist/policy.ciq.tgz"
  @fs.write_string_to_file(policy_path, "policy placeholder") catch {
    _ => abort("failed to write review policy bundle")
  }
  policy_path
}

///|
fn write_review_query(path : String) -> String {
  let query_path = "\{path}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.03.01",
    "selector": { "path": "openapi/payment.yaml", "kind": "operation" },
    "intent": "review",
    "repo": path,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write review query")
  }
  query_path
}

///|
fn copy_review_runtime_artifacts(path : String) -> Unit {
  @fs.create_dir("./dist") catch {
    _ => ()
  }
  let manifest = @fs.read_file_to_string("\{path}/dist/manifest.json") catch {
    _ => abort("failed to read runtime manifest")
  }
  let declarations = @fs.read_file_to_bytes("\{path}/dist/declarations.ndjson") catch {
    _ => abort("failed to read runtime declarations")
  }
  let symbols = @fs.read_file_to_bytes("\{path}/dist/symbols.ndjson") catch {
    _ => abort("failed to read runtime symbols")
  }
  let result = @fs.read_file_to_string("\{path}/query.result.json") catch {
    _ => abort("failed to read runtime query result")
  }
  let sarif = @fs.read_file_to_string("\{path}/dist/check.sarif.json") catch {
    _ => abort("failed to read runtime sarif")
  }
  @fs.write_string_to_file("./dist/manifest.json", manifest) catch {
    _ => abort("failed to copy runtime manifest")
  }
  @fs.write_bytes_to_file("./dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to copy runtime declarations")
  }
  @fs.write_bytes_to_file("./dist/symbols.ndjson", symbols) catch {
    _ => abort("failed to copy runtime symbols")
  }
  @fs.write_string_to_file("./dist/query.result.json", result) catch {
    _ => abort("failed to copy runtime query result")
  }
  @fs.write_string_to_file("./dist/check.sarif.json", sarif) catch {
    _ => abort("failed to copy runtime sarif")
  }
}

///|
test "e2e review loop covers bundle diff check query and mcp consumption" {
  let path = "src/e2e/tmp_codeiq_e2e_review"
  cleanup_lsp_e2e(path)
  cleanup_review_runtime_state()
  write_openapi_repo(path)
  write_openapi_config(path)

  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: path })
  guard build_out is Ok(_) else {
    cleanup_lsp_e2e(path)
    cleanup_review_runtime_state()
    fail("build should succeed in review loop")
  }
  assert_true(@fs.path_exists("\{path}/dist/bundle.ciq.tgz"))

  write_review_base_and_target(path)

  let diff_out = @diff_cmd.run(@diff_cmd.DiffParams::{
    repo: path,
    since: Some("2026-03-01T00:00:00Z"),
    include_test_changes: false,
  })
  guard diff_out is Ok(_) else {
    cleanup_lsp_e2e(path)
    cleanup_review_runtime_state()
    fail("diff should succeed in review loop")
  }
  let diff_json = @fs.read_file_to_string("\{path}/dist/diff.json") catch {
    _ => ""
  }
  assert_true(diff_json.contains("\"schemaVersion\": \"ciq-diff/v1\""))

  let policy_path = write_review_policy_bundle(path)
  @sys.set_env_var(
    "CODEIQ_OPA_EVAL_JSON",
    (
      #|{
      #|  "result": [
      #|    {
      #|      "expressions": [
      #|        {
      #|          "value": [
      #|            {
      #|              "rule_id": "compat.core.removed-declaration",
      #|              "level": "error",
      #|              "message": "Review requires compatibility approval",
      #|              "path": "manifest.purl"
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )
  let check_out = @check_cmd.run(@check_cmd.CheckParams::{
    diff_file: "\{path}/dist/diff.json",
    policy_bundle: policy_path,
  })
  @sys.unset_env_var("CODEIQ_OPA_EVAL_JSON")
  guard check_out is Ok(_) else {
    cleanup_lsp_e2e(path)
    cleanup_review_runtime_state()
    fail("check should succeed in review loop")
  }
  let sarif = @fs.read_file_to_string("\{path}/dist/check.sarif.json") catch {
    _ => ""
  }
  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(sarif.contains("compat.core.removed-declaration"))

  let query_path = write_review_query(path)
  let query_out = @query_cmd.run(@query_cmd.QueryParams::{
    query_file: query_path,
  })
  guard query_out is Ok(_) else {
    cleanup_lsp_e2e(path)
    cleanup_review_runtime_state()
    fail("query should succeed in review loop")
  }
  let query_result = @fs.read_file_to_string("\{path}/query.result.json") catch {
    _ => ""
  }
  assert_true(query_result.contains("\"schemaVersion\": \"ciq-result/v1\""))
  assert_true(query_result.contains("\"kind\": \"operation\""))
  assert_true(query_result.contains("openapi/payment.yaml"))

  copy_review_runtime_artifacts(path)

  let ping_request : Json = {
    "jsonrpc": "2.0",
    "id": 200,
    "method": "ping",
    "params": {},
  }
  let ping_response = @mcp_core.handle_request(ping_request).stringify(indent=2)
  assert_true(ping_response.contains("\"queryResult\": true"))
  assert_true(ping_response.contains("\"sarif\": true"))

  let outlines_request : Json = {
    "jsonrpc": "2.0",
    "id": 201,
    "method": "tools/call",
    "params": {
      "name": "codeiq.query.outlines",
      "arguments": {
        "purl": "pkg:openapi/acme/payment-api@2026.03.01",
        "limit": 5,
      },
    },
  }
  let outlines_response = @mcp_core.handle_request(outlines_request).stringify(
    indent=2,
  )
  assert_true(outlines_response.contains("\"outlines\""))
  assert_true(outlines_response.contains("openapi/payment.yaml"))

  let symbol_request : Json = {
    "jsonrpc": "2.0",
    "id": 202,
    "method": "tools/call",
    "params": {
      "name": "codeiq.query.symbol",
      "arguments": {
        "purl": "pkg:openapi/acme/payment-api@2026.03.01",
        "selector": "openapi/payment.yaml",
        "kind": "operation",
        "intent": "review",
      },
    },
  }
  let symbol_response = @mcp_core.handle_request(symbol_request).stringify(
    indent=2,
  )
  assert_true(symbol_response.contains("\"isError\": false"))
  assert_true(symbol_response.contains("\"schemaVersion\": \"ciq-result/v1\""))
  assert_true(symbol_response.contains("\"source\": \"bundle\""))
  assert_true(symbol_response.contains("\"matches\":"))

  cleanup_lsp_e2e(path)
  cleanup_review_runtime_state()
}
