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
  @sys.unset_env_var("CODEIQ_OPA_EVAL_JSON")
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
fn write_enriched_diff(
  path : String,
  base_purl : String,
  target_purl : String,
) -> Unit {
  // A diff that already contains semanticDiff in a changed entry (as produced by R13 diff)
  let content : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": base_purl,
    "targetPurl": target_purl,
    "summary": { "added": 0, "removed": 0, "changed": 1, "deprecated": 0 },
    "changes": [
      {
        "kind": "changed",
        "id": "decl:go-module:main.go::Greet",
        "path": "main.go",
        "level": "warning",
        "before": "func Greet(name string)",
        "after": "func Greet(name string) string",
        "semanticDiff": {
          "changedFields": ["shape"],
          "shapeDiff": {
            "before": { "kind": "function", "parameters": ["string"] },
            "after": {
              "kind": "function",
              "parameters": ["string"],
              "returns": ["string"],
            },
          },
        },
      },
    ],
  }
  @fs.write_string_to_file(path, content.stringify(indent=2)) catch {
    _ => abort("failed to write enriched diff fixture")
  }
}

///|
fn write_semantic_category_diff(
  path : String,
  base_purl : String,
  target_purl : String,
) -> Unit {
  // A diff with semanticCategory and beforeRecord for R13-2 OPA input shaping
  // and R13-3 SARIF location + message enrichment
  let content : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": base_purl,
    "targetPurl": target_purl,
    "summary": { "added": 0, "removed": 0, "changed": 1, "deprecated": 0 },
    "changes": [
      {
        "kind": "changed",
        "id": "decl:rust:src/lib.rs::process",
        "path": "src/lib.rs",
        "level": "breaking",
        "semanticCategory": "rust-became-unsafe",
        "before": "fn process()",
        "after": "unsafe fn process()",
        "beforeRecord": {
          "id": "decl:rust:src/lib.rs::process",
          "location": { "file": "src/lib.rs", "line": 12 },
        },
        "afterRecord": {
          "id": "decl:rust:src/lib.rs::process",
          "location": { "file": "src/lib.rs", "line": 12 },
        },
      },
    ],
  }
  @fs.write_string_to_file(path, content.stringify(indent=2)) catch {
    _ => abort("failed to write semantic-category diff fixture")
  }
}

///|
test "check handles enriched diff with semanticDiff and emits valid sarif" {
  let repo = "src/cmd/check/tmp_check_enriched"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policy.ciq.tgz"
  write_enriched_diff(
    diff_path,
    "pkg:golang/example/demo@0.1.0",
    "pkg:golang/example/demo@0.2.0",
  )
  @fs.write_string_to_file(policy_path, "policy placeholder") catch {
    _ => abort("failed to write policy fixture")
  }
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
      #|              "rule_id": "compat.shape-breaking-change",
      #|              "level": "error",
      #|              "message": "Shape change adds return type: breaking for callers",
      #|              "path": "main.go",
      #|              "docs": "https://example.dev/policy/compat.shape-breaking-change"
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )

  let out = run({ diff_file: diff_path, policy_bundle: policy_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed with enriched diff")
  }

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }

  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(sarif.contains("\"ruleId\": \"compat.changed\""))
  assert_true(
    sarif.contains("\"ruleId\": \"compat.shape-breaking-change\"") ||
    sarif.contains("\"ruleId\":\"compat.shape-breaking-change\""),
  )
  assert_true(sarif.contains("Shape change adds return type"))
  assert_true(sarif.contains("\"source\": \"opa-policy\""))
  // R13-3: semanticDiff present in enriched diff means semanticCategory flows
  // through; since write_enriched_diff does not set semanticCategory the message
  // should just use the plain format (no brackets), verifying the code path works
  assert_true(sarif.contains("Detected changed change for main.go"))

  cleanup_tmp_repo(repo)
}

///|
test "check emits semantic message and precise location when semanticCategory and beforeRecord are present" {
  let repo = "src/cmd/check/tmp_check_semantic_cat"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policy.ciq.tgz"
  write_semantic_category_diff(
    diff_path,
    "pkg:cargo/acme/mylib@1.0.0",
    "pkg:cargo/acme/mylib@1.1.0",
  )
  @fs.write_string_to_file(policy_path, "policy placeholder") catch {
    _ => abort("failed to write policy fixture")
  }
  // No OPA policy results — just validate SARIF from diff enrichment
  @sys.set_env_var(
    "CODEIQ_OPA_EVAL_JSON",
    (
      #|{"result":[{"expressions":[{"value":[]}]}]}
    ),
  )

  let out = run({ diff_file: diff_path, policy_bundle: policy_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed with semantic-category diff")
  }

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }

  // R13-3: semantic message includes semanticCategory in brackets
  assert_true(sarif.contains("[rust-became-unsafe]"))
  // R13-3: location uri comes from beforeRecord.location.file
  assert_true(sarif.contains("\"uri\": \"src/lib.rs\""))
  // R13-3: location line comes from beforeRecord.location.line
  assert_true(sarif.contains("\"startLine\": 12"))
  // R13-3: level maps breaking → error
  assert_true(sarif.contains("\"level\": \"error\""))

  cleanup_tmp_repo(repo)
}

///|
test "check prefers uri and startLine from real diff records" {
  let repo = "src/cmd/check/tmp_check_real_location"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policy.ciq.tgz"
  let content : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": "pkg:golang/example/demo@0.1.0",
    "targetPurl": "pkg:golang/example/demo@0.2.0",
    "summary": { "added": 0, "removed": 0, "changed": 1, "deprecated": 0 },
    "changes": [
      {
        "kind": "changed",
        "id": "decl:go-module:demo::main.go::Greet",
        "path": "main.go",
        "level": "warning",
        "semanticCategory": "go-pointer-receiver-changed",
        "beforeRecord": {
          "id": "decl:go-module:demo::main.go::Greet",
          "location": { "uri": "main.go", "startLine": 58, "endLine": 58 },
        },
        "afterRecord": {
          "id": "decl:go-module:demo::main.go::Greet",
          "location": { "uri": "main.go", "startLine": 58, "endLine": 58 },
        },
      },
    ],
  }
  @fs.write_string_to_file(diff_path, content.stringify(indent=2)) catch {
    _ => abort("failed to write real-location diff fixture")
  }
  @fs.write_string_to_file(policy_path, "policy placeholder") catch {
    _ => abort("failed to write policy fixture")
  }
  @sys.set_env_var(
    "CODEIQ_OPA_EVAL_JSON",
    (
      #|{"result":[{"expressions":[{"value":[]}]}]}
    ),
  )

  let out = run({ diff_file: diff_path, policy_bundle: policy_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed with real diff record location")
  }

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }

  assert_true(sarif.contains("\"uri\": \"main.go\"") || sarif.contains("\"uri\":\"main.go\""))
  assert_true(sarif.contains("\"startLine\": 58") || sarif.contains("\"startLine\":58"))
  assert_true(sarif.contains("[go-pointer-receiver-changed]"))

  cleanup_tmp_repo(repo)
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
      #|              "rule_id": "compat.removed-public-api",
      #|              "level": "error",
      #|              "message": "Public API removal blocked by policy",
      #|              "path": "manifest.purl",
      #|              "docs": "https://example.dev/policy/compat.removed-public-api"
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )

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
  assert_true(sarif.contains("\"ruleId\": \"compat.removed-public-api\""))
  assert_true(sarif.contains("Public API removal blocked by policy"))
  assert_true(sarif.contains("\"fullDescription\""))
  assert_true(sarif.contains("\"helpUri\""))
  assert_true(
    sarif.contains("https://example.dev/policy/compat.removed-public-api"),
  )
  assert_true(sarif.contains("\"source\": \"opa-policy\""))

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

///|
test "check fails when opa output env json is invalid" {
  let repo = "src/cmd/check/tmp_check_invalid_opa_json"
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
  @sys.set_env_var("CODEIQ_OPA_EVAL_JSON", "{")

  let out = run({ diff_file: diff_path, policy_bundle: policy_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("check should fail when CODEIQ_OPA_EVAL_JSON is invalid")
  }

  let text = error.to_string()
  assert_true(text.contains("check failed:"))
  assert_true(text.contains("invalid json in CODEIQ_OPA_EVAL_JSON"))

  cleanup_tmp_repo(repo)
}
