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
  remove_file_if_exists("\{repo}/cogna.yaml")
  remove_file_if_exists("\{repo}/dist/manifest.json")
  remove_file_if_exists("\{repo}/dist/declarations.ndjson")
  remove_file_if_exists("\{repo}/dist/metadata.json")
  remove_file_if_exists("\{repo}/dist/checksums.txt")
  @sys.unset_env_var("COGNA_OPA_EVAL_JSON")
  remove_dir_if_exists("\{repo}/dist/policies")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
}

///|
fn tmp_check_repo(name : String) -> String {
  "/tmp/cogna-check-\{name}"
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
          "findings": [{ "code": "go-signature-changed" }],
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
fn write_findings_diff(
  path : String,
  base_purl : String,
  target_purl : String,
) -> Unit {
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
        "before": "fn process()",
        "after": "unsafe fn process()",
        "semanticDiff": { "findings": [{ "code": "rust-became-unsafe" }] },
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
    _ => abort("failed to write findings diff fixture")
  }
}

///|
test "check handles enriched diff with semanticDiff and emits valid sarif" {
  let repo = tmp_check_repo("enriched")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
  write_enriched_diff(
    diff_path, "pkg:golang/example/demo@0.1.0", "pkg:golang/example/demo@0.2.0",
  )
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  @sys.set_env_var(
    "COGNA_OPA_EVAL_JSON",
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

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
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
  assert_true(
    sarif.contains(
      "Detected changed change for main.go (decl:go-module:main.go::Greet) [go-signature-changed]",
    ),
  )

  cleanup_tmp_repo(repo)
}

///|
test "check emits semantic message and precise location when findings and beforeRecord are present" {
  let repo = tmp_check_repo("semantic-cat")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
  write_findings_diff(
    diff_path, "pkg:cargo/acme/mylib@1.0.0", "pkg:cargo/acme/mylib@1.1.0",
  )
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  // No OPA policy results — just validate SARIF from diff enrichment
  @sys.set_env_var(
    "COGNA_OPA_EVAL_JSON",
    (
      #|{"result":[{"expressions":[{"value":[]}]}]}
    ),
  )

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed with findings diff")
  }

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }

  assert_true(sarif.contains("[rust-became-unsafe]"))
  assert_true(sarif.contains("\"uri\": \"src/lib.rs\""))
  assert_true(sarif.contains("\"startLine\": 12"))
  assert_true(sarif.contains("\"level\": \"error\""))

  cleanup_tmp_repo(repo)
}

///|
test "check prefers uri and startLine from real diff records" {
  let repo = tmp_check_repo("real-location")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
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
        "semanticDiff": {
          "findings": [{ "code": "go-pointer-receiver-changed" }],
        },
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
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  @sys.set_env_var(
    "COGNA_OPA_EVAL_JSON",
    (
      #|{"result":[{"expressions":[{"value":[]}]}]}
    ),
  )

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
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

  assert_true(
    sarif.contains("\"uri\": \"main.go\"") ||
    sarif.contains("\"uri\":\"main.go\""),
  )
  assert_true(
    sarif.contains("\"startLine\": 58") || sarif.contains("\"startLine\":58"),
  )
  assert_true(sarif.contains("[go-pointer-receiver-changed]"))

  cleanup_tmp_repo(repo)
}

///|
test "check generates sarif from diff and policy" {
  let repo = tmp_check_repo("repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
  write_diff(
    diff_path, "pkg:openapi/acme/payment-api@2026.03.01", "pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  @sys.set_env_var(
    "COGNA_OPA_EVAL_JSON",
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
      #|              "message": "Public API removal blocked by policy",
      #|              "path": "manifest.purl",
      #|              "docs": "https://example.dev/policy/compat.core.removed-declaration"
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed")
  }

  inspect(
    result.display(),
    content="Generated SARIF report at /tmp/cogna-check-repo/dist/check.sarif.json",
  )

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }
  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(sarif.contains("\"name\": \"cogna-check\""))
  assert_true(sarif.contains("\"ruleId\": \"compat.changed\""))
  assert_true(sarif.contains("\"ruleId\": \"compat.core.removed-declaration\""))
  assert_true(sarif.contains("Public API removal blocked by policy"))
  assert_true(sarif.contains("\"fullDescription\""))
  assert_true(sarif.contains("\"helpUri\""))
  assert_true(
    sarif.contains("https://example.dev/policy/compat.core.removed-declaration"),
  )
  assert_true(sarif.contains("\"source\": \"opa-policy\""))

  cleanup_tmp_repo(repo)
}

///|
test "check routes componentDiff changes to componentChanges with richer evidence" {
  let repo = tmp_check_repo("component-evidence")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
  let content : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": "pkg:npm/acme/sdk@1.0.0",
    "targetPurl": "pkg:npm/acme/sdk@2.0.0",
    "summary": { "added": 0, "removed": 0, "changed": 1, "deprecated": 0 },
    "changes": [
      {
        "kind": "changed",
        "id": "component:npm/acme/sdk",
        "path": "package.json",
        "level": "warning",
        "componentDiff": {
          "upgradeKind": "version-upgrade",
          "beforeVersion": "1.0.0",
          "afterVersion": "2.0.0",
          "beforePurl": "pkg:npm/acme/sdk@1.0.0",
          "afterPurl": "pkg:npm/acme/sdk@2.0.0",
        },
      },
    ],
  }
  @fs.write_string_to_file(diff_path, content.stringify(indent=2)) catch {
    _ => abort("failed to write component diff fixture")
  }
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  @sys.set_env_var(
    "COGNA_OPA_EVAL_JSON",
    (
      #|{
      #|  "result": [
      #|    {
      #|      "expressions": [
      #|        {
      #|          "value": [
      #|            {
      #|              "rule_id": "compat.component.version-upgrade",
      #|              "level": "warning",
      #|              "message": "Software component version changed.",
      #|              "path": "package.json",
      #|              "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-component-version-upgrade"
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed with component diff")
  }

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }

  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(
    sarif.contains("\"ruleId\": \"compat.component.version-upgrade\"") ||
    sarif.contains("\"ruleId\":\"compat.component.version-upgrade\""),
  )
  assert_true(sarif.contains("Software component version changed"))
  assert_true(sarif.contains("\"source\": \"opa-policy\""))

  cleanup_tmp_repo(repo)
}

///|
test "check emits two sarif results when one change has two finding codes" {
  let repo = tmp_check_repo("multi-finding")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
  let content : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": "pkg:cargo/tokio@1.42.0",
    "targetPurl": "pkg:cargo/tokio@1.43.0",
    "summary": { "added": 0, "removed": 0, "changed": 1, "deprecated": 0 },
    "changes": [
      {
        "kind": "changed",
        "id": "decl:rust:src/lib.rs::Mutex::lock",
        "path": "src/lib.rs",
        "level": "breaking",
        "before": "fn lock(&self)",
        "after": "unsafe fn lock(&self) -> Guard",
        "semanticDiff": {
          "findings": [
            { "code": "rust-became-unsafe" },
            { "code": "rust-signature-changed" },
          ],
        },
        "beforeRecord": {
          "id": "decl:rust:src/lib.rs::Mutex::lock",
          "location": { "file": "src/lib.rs", "line": 42 },
        },
        "afterRecord": {
          "id": "decl:rust:src/lib.rs::Mutex::lock",
          "location": { "file": "src/lib.rs", "line": 42 },
        },
      },
    ],
  }
  @fs.write_string_to_file(diff_path, content.stringify(indent=2)) catch {
    _ => abort("failed to write multi-finding diff fixture")
  }
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  // Two deny results from one change — both findings fire
  @sys.set_env_var(
    "COGNA_OPA_EVAL_JSON",
    (
      #|{
      #|  "result": [
      #|    {
      #|      "expressions": [
      #|        {
      #|          "value": [
      #|            {
      #|              "rule_id": "compat.rust.became-unsafe",
      #|              "level": "error",
      #|              "message": "Rust public item became unsafe.",
      #|              "path": "src/lib.rs",
      #|              "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-became-unsafe"
      #|            },
      #|            {
      #|              "rule_id": "compat.rust.signature-changed",
      #|              "level": "warning",
      #|              "message": "Rust public signature changed.",
      #|              "path": "src/lib.rs",
      #|              "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-signature-changed"
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed with multi-finding diff")
  }

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }

  assert_true(sarif.contains("\"version\": \"2.1.0\""))
  assert_true(
    sarif.contains("\"ruleId\": \"compat.rust.became-unsafe\"") ||
    sarif.contains("\"ruleId\":\"compat.rust.became-unsafe\""),
  )
  assert_true(
    sarif.contains("\"ruleId\": \"compat.rust.signature-changed\"") ||
    sarif.contains("\"ruleId\":\"compat.rust.signature-changed\""),
  )
  assert_true(sarif.contains("Rust public item became unsafe"))
  assert_true(sarif.contains("Rust public signature changed"))
  // Both should reference the precise source location
  assert_true(
    sarif.contains("\"uri\": \"src/lib.rs\"") ||
    sarif.contains("\"uri\":\"src/lib.rs\""),
  )
  assert_true(
    sarif.contains("\"startLine\": 42") || sarif.contains("\"startLine\":42"),
  )

  cleanup_tmp_repo(repo)
}

///|
test "check fails when policies directory is missing" {
  let repo = tmp_check_repo("missing-policy")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  write_diff(
    diff_path, "pkg:openapi/acme/payment-api@2026.03.01", "pkg:openapi/acme/payment-api@2026.04.01",
  )

  let out = run({ diff_file: diff_path, policies_dir: "\{repo}/dist/policies" })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("check should fail when policies directory is missing")
  }

  let text = error.to_string()
  assert_true(text.contains("check failed:"))
  assert_true(text.contains("missing policies directory"))

  cleanup_tmp_repo(repo)
}

///|
test "check fails when opa output env json is invalid" {
  let repo = tmp_check_repo("invalid-opa-json")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
  write_diff(
    diff_path, "pkg:openapi/acme/payment-api@2026.03.01", "pkg:openapi/acme/payment-api@2026.04.01",
  )
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  @sys.set_env_var("COGNA_OPA_EVAL_JSON", "{")

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("check should fail when COGNA_OPA_EVAL_JSON is invalid")
  }

  let text = error.to_string()
  assert_true(text.contains("check failed:"))
  assert_true(text.contains("invalid json in COGNA_OPA_EVAL_JSON"))

  cleanup_tmp_repo(repo)
}

///|
test "check merges policy catalog rules into sarif driver metadata" {
  let repo = tmp_check_repo("catalog-merge")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let diff_path = "\{repo}/dist/diff.json"
  let policy_path = "\{repo}/dist/policies"
  @fs.create_dir(policy_path) catch {
    _ => abort("failed to create policies dir")
  }
  let content : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": "pkg:cargo/tokio@1.42.0",
    "targetPurl": "pkg:cargo/tokio@1.43.0",
    "summary": { "added": 0, "removed": 0, "changed": 1, "deprecated": 0 },
    "changes": [
      {
        "kind": "changed",
        "id": "decl:rust:src/lib.rs::Mutex::lock",
        "path": "src/lib.rs",
        "level": "breaking",
        "before": "fn lock(&self)",
        "after": "unsafe fn lock(&self) -> Guard",
        "semanticDiff": {
          "findings": [
            { "code": "rust-became-unsafe" },
            { "code": "rust-signature-changed" },
          ],
        },
        "beforeRecord": {
          "id": "decl:rust:src/lib.rs::Mutex::lock",
          "location": { "uri": "src/lib.rs", "startLine": 42, "endLine": 42 },
        },
        "afterRecord": {
          "id": "decl:rust:src/lib.rs::Mutex::lock",
          "location": { "uri": "src/lib.rs", "startLine": 42, "endLine": 42 },
        },
      },
    ],
  }
  @fs.write_string_to_file(diff_path, content.stringify(indent=2)) catch {
    _ => abort("failed to write catalog merge diff fixture")
  }
  @sys.set_env_var(
    "COGNA_OPA_EVAL_JSON",
    (
      #|{
      #|  "result": [
      #|    {
      #|      "expressions": [
      #|        {
      #|          "value": [
      #|            {
      #|              "rule_id": "compat.rust.became-unsafe",
      #|              "level": "error",
      #|              "message": "Rust public item became unsafe.",
      #|              "path": "src/lib.rs",
      #|              "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-became-unsafe"
      #|            },
      #|            {
      #|              "rule_id": "compat.rust.signature-changed",
      #|              "level": "warning",
      #|              "message": "Rust public signature changed.",
      #|              "path": "src/lib.rs",
      #|              "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-signature-changed"
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )

  let out = run({ diff_file: diff_path, policies_dir: policy_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("check should succeed with catalog merge")
  }

  let sarif = @fs.read_file_to_string("\{repo}/dist/check.sarif.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("sarif output should exist")
      ""
    }
  }
  assert_true(sarif.contains("\"ruleId\": \"compat.rust.became-unsafe\""))
  assert_true(sarif.contains("\"ruleId\": \"compat.rust.signature-changed\""))
  assert_true(sarif.contains("\"id\": \"compat.core.removed-declaration\""))
  assert_true(sarif.contains("\"id\": \"compat.component.version-upgrade\""))
  assert_true(
    sarif.contains("\"id\": \"compat.terraform.input-became-required\"") ||
    sarif.contains("\"id\":\"compat.terraform.input-became-required\""),
  )
  assert_true(
    sarif.contains("\"id\": \"compat.terraform.output-removed\"") ||
    sarif.contains("\"id\":\"compat.terraform.output-removed\""),
  )
  assert_true(
    sarif.contains("\"id\": \"compat.openapi.response-status-removed\"") ||
    sarif.contains("\"id\":\"compat.openapi.response-status-removed\""),
  )
  assert_true(
    sarif.contains("\"id\": \"compat.openapi.response-schema-narrowed\"") ||
    sarif.contains("\"id\":\"compat.openapi.response-schema-narrowed\""),
  )
  assert_true(
    sarif.contains(
      "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-signature-changed",
    ),
  )

  cleanup_tmp_repo(repo)
}
