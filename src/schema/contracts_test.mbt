///|
fn must_parse_json_contract(text : String) -> Json {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { abort("json parse failed") }
  value
}

///|
test "ciq-bundle schema validates minimal bundle" {
  let bundle = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-bundle/v1",
      #|  "purl": "pkg:openapi/acme/payment-api@2026.03.01",
      #|  "profile": "openapi-spec",
      #|  "declarationSchema": {
      #|    "version": "ciq-declarations/v1",
      #|    "format": "ndjson",
      #|    "model": "signature + shape + language_specific tagged union",
      #|    "schema": {
      #|      "type": "object",
      #|      "required": ["id"],
      #|      "properties": {"id": {"type": "string"}}
      #|    }
      #|  },
      #|  "source": {
      #|    "repo": "https://github.com/acme/payment-api",
      #|    "ref": "main",
      #|    "commit": "1234567890abcdef1234567890abcdef12345678"
      #|  },
      #|  "artifacts": [
      #|    {"path":"declarations.ndjson","sha256":"abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd","compression":"none"}
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_bundle_v1(bundle) is Ok(_) else {
    fail("bundle should satisfy ciq-bundle/v1 schema")
  }
}

///|
test "ciq-diff schema rejects unknown schemaVersion" {
  let diff = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-diff/v0",
      #|  "basePurl": "pkg:openapi/acme/payment-api@2026.03.01",
      #|  "targetPurl": "pkg:openapi/acme/payment-api@2026.04.01",
      #|  "summary": {"added":0,"removed":0,"changed":1,"deprecated":0},
      #|  "changes": []
      #|}
    ),
  )
  let out = validate_ciq_diff_v1(diff)
  guard out is Err(error) else {
    fail("diff with wrong schemaVersion should fail")
  }
  assert_true(error.to_string().contains("value does not match const"))
}

///|
test "ciq-diff schema validates test summary and test changes" {
  let diff = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-diff/v1",
      #|  "basePurl": "pkg:golang/example/demo@0.1.0",
      #|  "targetPurl": "pkg:golang/example/demo@0.2.0",
      #|  "summary": {"added":0,"removed":0,"changed":0,"deprecated":0},
      #|  "changes": [],
      #|  "includeTestChanges": true,
      #|  "testSummary": {"added": 1, "modified": 1, "removed": 0},
      #|  "testChanges": [
      #|    {
      #|      "kind": "modified",
      #|      "language": "go",
      #|      "id": "test:go-module:demo::math_test.go::TestAdd",
      #|      "path": "go-module:demo::math_test.go::TestAdd",
      #|      "signature": "func TestAdd(t *testing.T)",
      #|      "location": {"uri":"math_test.go","startLine":12,"endLine":12},
      #|      "tracking": {"traceabilityKey": "demo::math::Add", "externalIds": ["TMS-1001"]}
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_diff_v1(diff) is Ok(_) else {
    fail("ciq-diff with test changes should satisfy schema")
  }
}

///|
test "ciq-diff schema rejects malformed test changes" {
  let diff = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-diff/v1",
      #|  "basePurl": "pkg:golang/example/demo@0.1.0",
      #|  "targetPurl": "pkg:golang/example/demo@0.2.0",
      #|  "summary": {"added":0,"removed":0,"changed":0,"deprecated":0},
      #|  "changes": [],
      #|  "includeTestChanges": true,
      #|  "testSummary": {"added": 1, "modified": 0, "removed": 0},
      #|  "testChanges": [
      #|    {
      #|      "kind": "changed",
      #|      "language": "go",
      #|      "id": "test:go-module:demo::math_test.go::TestAdd",
      #|      "path": "go-module:demo::math_test.go::TestAdd",
      #|      "signature": "func TestAdd(t *testing.T)",
      #|      "location": {"uri":"math_test.go","startLine":12,"endLine":12}
      #|    }
      #|  ]
      #|}
    ),
  )
  let out = validate_ciq_diff_v1(diff)
  guard out is Err(_) else {
    fail("ciq-diff should reject invalid test change kind")
  }
}

///|
test "ciq-result schema accepts richer declaration matches" {
  let result = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-result/v1",
      #|  "purl": "pkg:golang/example/demo@0.1.0",
      #|  "matches": [
      #|    {
      #|      "id": "decl:go-module:go-module::main.go::Greet",
      #|      "kind": "method",
      #|      "path": "main.go",
      #|      "name": "Greet",
      #|      "canonical_name": "go-module::main.go::Greet",
      #|      "language": "go",
      #|      "baselineRole": "baseline",
      #|      "source_refs": [
      #|        {"uri": "main.go", "startLine": 58, "endLine": 58}
      #|      ],
      #|      "relations": [
      #|        {"kind": "declared_in", "target": "file:main.go"}
      #|      ],
      #|      "visibility": "public",
      #|      "docs": "",
      #|      "signature": "func (g *Greeter) Greet(name string) Message {",
      #|      "shape": {
      #|        "kind": "method",
      #|        "subkind": "method",
      #|        "form": "callable",
      #|        "signature": "func (g *Greeter) Greet(name string) Message {",
      #|        "owner": "Greeter",
      #|        "parameters": ["string"],
      #|        "returns": ["Message"]
      #|      },
      #|      "language_specific": {
      #|        "profile": "go-module",
      #|        "server": "gopls",
      #|        "go": {
      #|          "receiver": "Greeter",
      #|          "pointerReceiver": true
      #|        }
      #|      },
      #|      "location": {"uri": "main.go", "startLine": 58, "endLine": 58}
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_result_v1(result) is Ok(_) else {
    fail("ciq-result should allow richer shape and language_specific payloads")
  }
}

///|
test "ciq-diff schema accepts richer before and after record payloads" {
  let diff = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-diff/v1",
      #|  "basePurl": "pkg:openapi/acme/payment-api@2026.03.01",
      #|  "targetPurl": "pkg:openapi/acme/payment-api@2026.04.01",
      #|  "summary": {"added":0,"removed":0,"changed":1,"deprecated":1},
      #|  "changes": [
      #|    {
      #|      "kind": "changed",
      #|      "id": "decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment",
      #|      "path": "openapi/payment.yaml",
      #|      "level": "warning",
      #|      "before": "operation createPayment",
      #|      "after": "operation createPayment",
      #|      "beforeRecord": {
      #|        "id": "decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment",
      #|        "kind": "operation",
      #|        "path": "openapi/payment.yaml",
      #|        "signature": "operation createPayment",
      #|        "location": {"uri": "openapi/payment.yaml", "startLine": 26, "endLine": 26}
      #|      },
      #|      "afterRecord": {
      #|        "id": "decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment",
      #|        "kind": "operation",
      #|        "path": "openapi/payment.yaml",
      #|        "signature": "operation createPayment",
      #|        "language_specific": {
      #|          "profile": "openapi-spec",
      #|          "server": "none",
      #|          "openapi": {"statusCodes": ["201"]}
      #|        },
      #|        "location": {"uri": "openapi/payment.yaml", "startLine": 26, "endLine": 26}
      #|      }
      #|    },
      #|    {
      #|      "kind": "deprecated",
      #|      "id": "decl:go-module:go-module::main.go::OldGreet",
      #|      "path": "main.go",
      #|      "level": "warning",
      #|      "afterRecord": {
      #|        "id": "decl:go-module:go-module::main.go::OldGreet",
      #|        "kind": "method",
      #|        "path": "main.go",
      #|        "signature": "func (g *Greeter) OldGreet(name string) Message {",
      #|        "location": {"uri": "main.go", "startLine": 58, "endLine": 58}
      #|      }
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_diff_v1(diff) is Ok(_) else {
    fail("ciq-diff should allow additive beforeRecord and afterRecord payloads")
  }
}

///|
test "ciq-diff schema accepts semanticCategory on change entries" {
  let diff = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-diff/v1",
      #|  "basePurl": "pkg:cargo/example/demo@0.1.0",
      #|  "targetPurl": "pkg:cargo/example/demo@0.2.0",
      #|  "summary": {"added":0,"removed":1,"changed":1,"deprecated":0},
      #|  "changes": [
      #|    {
      #|      "kind": "changed",
      #|      "id": "decl:rust-crate:rust-crate::lib.rs::dangerous",
      #|      "path": "lib.rs",
      #|      "level": "breaking",
      #|      "semanticCategory": "rust-became-unsafe",
      #|      "before": "pub fn dangerous() -> i32",
      #|      "after": "pub unsafe fn dangerous() -> i32",
      #|      "beforeRecord": {"id": "decl:rust-crate:rust-crate::lib.rs::dangerous"},
      #|      "afterRecord": {"id": "decl:rust-crate:rust-crate::lib.rs::dangerous"}
      #|    },
      #|    {
      #|      "kind": "removed",
      #|      "id": "decl:rust-crate:rust-crate::lib.rs::old_fn",
      #|      "path": "lib.rs",
      #|      "level": "breaking",
      #|      "semanticCategory": "removed-declaration",
      #|      "beforeRecord": {"id": "decl:rust-crate:rust-crate::lib.rs::old_fn"}
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_diff_v1(diff) is Ok(_) else {
    fail("ciq-diff should accept semanticCategory on change entries")
  }
}

///|
test "ciq-diff schema accepts componentDiff on change entries" {
  let diff = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-diff/v1",
      #|  "basePurl": "pkg:npm/example/demo@0.1.0",
      #|  "targetPurl": "pkg:npm/example/demo@0.2.0",
      #|  "summary": {"added":0,"removed":0,"changed":1,"deprecated":0},
      #|  "changes": [
      #|    {
      #|      "kind": "changed",
      #|      "id": "pkg:npm/react@19.0.0",
      #|      "path": "package.json",
      #|      "level": "warning",
      #|      "semanticCategory": "component-version-upgrade",
      #|      "componentDiff": {
      #|        "changedFields": ["version", "purl"],
      #|        "upgradeKind": "version-upgrade",
      #|        "beforeVersion": "18.2.0",
      #|        "afterVersion": "19.0.0",
      #|        "beforePurl": "pkg:npm/react@18.2.0",
      #|        "afterPurl": "pkg:npm/react@19.0.0"
      #|      },
      #|      "beforeRecord": {"id": "pkg:npm/react@18.2.0"},
      #|      "afterRecord": {"id": "pkg:npm/react@19.0.0"}
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_diff_v1(diff) is Ok(_) else {
    fail("ciq-diff should accept componentDiff on change entries")
  }
}


///|
test "sarif minimal schema validates skeleton output" {
  let sarif = must_parse_json_contract(
    (
      #|{
      #|  "version": "2.1.0",
      #|  "runs": [
      #|    {
      #|      "tool": {
      #|        "driver": {
      #|          "name": "codeiq-check",
      #|          "rules": [
      #|            {"id":"compat.changed","shortDescription":{"text":"x"}}
      #|          ]
      #|        }
      #|      },
      #|      "results": [
      #|        {
      #|          "ruleId": "compat.changed",
      #|          "level": "warning",
      #|          "message": {"text":"Detected changed"}
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_sarif_v2_1_0_min(sarif) is Ok(_) else {
    fail("sarif skeleton should satisfy minimal sarif schema")
  }
}

///|
test "ciq-opa-bundle schema validates policy bundle" {
  let bundle = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-opa-bundle/v1",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "profile": "policy-bundle",
      #|  "source": {
      #|    "repo": "https://github.com/acme/compat-policy",
      #|    "ref": "main",
      #|    "commit": "1234567890abcdef1234567890abcdef12345678"
      #|  },
      #|  "opa": {
      #|    "entrypoint": "codeiq/compat/deny",
      #|    "format": "opa-bundle.tar.gz"
      #|  },
      #|  "provenance": {
      #|    "checksums": "checksums.txt",
      #|    "signature": {
      #|      "status": "unsigned",
      #|      "algorithm": "sha256"
      #|    }
      #|  },
      #|  "artifacts": [
      #|    {"path":"declarations.ndjson","sha256":"abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd","compression":"none"},
      #|    {"path":"symbols.ndjson","sha256":"bcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcde","compression":"none"},
      #|    {"path":"opa-bundle.tar.gz","sha256":"cdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef","compression":"gzip"},
      #|    {"path":"policy.rules.json","sha256":"defabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefa","compression":"none"}
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_opa_bundle_v1(bundle) is Ok(_) else {
    fail("policy bundle should satisfy ciq-opa-bundle/v1 schema")
  }
}

///|
test "ciq-opa-bundle schema accepts untrusted signature status" {
  let bundle = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-opa-bundle/v1",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "profile": "policy-bundle",
      #|  "source": {
      #|    "repo": "https://github.com/acme/compat-policy",
      #|    "ref": "main",
      #|    "commit": "1234567890abcdef1234567890abcdef12345678"
      #|  },
      #|  "opa": {
      #|    "entrypoint": "codeiq/compat/deny",
      #|    "format": "opa-bundle.tar.gz"
      #|  },
      #|  "provenance": {
      #|    "checksums": "checksums.txt",
      #|    "signature": {
      #|      "status": "untrusted",
      #|      "algorithm": "sha256"
      #|    }
      #|  },
      #|  "artifacts": [
      #|    {
      #|      "path": "declarations.ndjson",
      #|      "sha256": "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      #|      "compression": "none"
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_opa_bundle_v1(bundle) is Ok(_) else {
    fail("policy bundle should allow untrusted signature status")
  }
}

///|
test "ciq-opa-bundle schema accepts signature keyId" {
  let bundle = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-opa-bundle/v1",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "profile": "policy-bundle",
      #|  "source": {
      #|    "repo": "https://github.com/acme/compat-policy",
      #|    "ref": "main",
      #|    "commit": "1234567890abcdef1234567890abcdef12345678"
      #|  },
      #|  "opa": {
      #|    "entrypoint": "codeiq/compat/deny",
      #|    "format": "opa-bundle.tar.gz"
      #|  },
      #|  "provenance": {
      #|    "checksums": "checksums.txt",
      #|    "signature": {
      #|      "status": "verified",
      #|      "algorithm": "sha256",
      #|      "keyId": "acme-main"
      #|    }
      #|  },
      #|  "artifacts": [
      #|    {
      #|      "path": "declarations.ndjson",
      #|      "sha256": "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      #|      "compression": "none"
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_opa_bundle_v1(bundle) is Ok(_) else {
    fail("policy bundle should allow signature keyId")
  }
}

///|
test "ciq-opa-bundle schema accepts signature value" {
  let bundle = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "ciq-opa-bundle/v1",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "profile": "policy-bundle",
      #|  "source": {
      #|    "repo": "https://github.com/acme/compat-policy",
      #|    "ref": "main",
      #|    "commit": "1234567890abcdef1234567890abcdef12345678"
      #|  },
      #|  "opa": {
      #|    "entrypoint": "codeiq/compat/deny",
      #|    "format": "opa-bundle.tar.gz"
      #|  },
      #|  "provenance": {
      #|    "checksums": "checksums.txt",
      #|    "signature": {
      #|      "status": "verified",
      #|      "algorithm": "sha256",
      #|      "keyId": "acme-main",
      #|      "value": "ZmFrZS1zaWduYXR1cmU="
      #|    }
      #|  },
      #|  "artifacts": [
      #|    {
      #|      "path": "declarations.ndjson",
      #|      "sha256": "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      #|      "compression": "none"
      #|    }
      #|  ]
      #|}
    ),
  )
  guard validate_ciq_opa_bundle_v1(bundle) is Ok(_) else {
    fail("policy bundle should allow signature value")
  }
}

///|
test "registry-upload schema validates minimal request" {
  let upload = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-upload/v1",
      #|  "endpoint": "POST /api/v1/bundles",
      #|  "bundleFile": "dist/bundle.ciq.tgz",
      #|  "bundleType": "ciq-opa-bundle",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "size": 12345
      #|}
    ),
  )
  guard validate_codeiq_registry_upload_v1(upload) is Ok(_) else {
    fail("upload request should satisfy codeiq-registry-upload/v1 schema")
  }
}

///|
test "publish-receipt schema validates success receipt" {
  let receipt = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_01JY4EXAMPLE",
      #|  "bundleId": "bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "bundleType": "ciq-opa-bundle",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "local-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\""
      #|  }
      #|}
    ),
  )
  guard validate_codeiq_publish_receipt_v1(receipt) is Ok(_) else {
    fail("publish receipt should satisfy codeiq-publish-receipt/v1 schema")
  }
}

///|
test "publish-receipt schema validates signature status" {
  let receipt = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_01JY4EXAMPLE",
      #|  "bundleId": "bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "bundleType": "ciq-opa-bundle",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "local-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"",
      #|    "signature": {
      #|      "status": "verified",
      #|      "algorithm": "sha256",
      #|      "keyId": "acme-main"
      #|    }
      #|  }
      #|}
    ),
  )
  guard validate_codeiq_publish_receipt_v1(receipt) is Ok(_) else {
    fail("publish receipt should allow signature metadata")
  }
}

///|
test "publish-receipt schema validates signature value" {
  let receipt = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-publish-receipt/v1",
      #|  "publishId": "pub_01JY4EXAMPLE",
      #|  "bundleId": "bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "bundleType": "ciq-opa-bundle",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "local-registry",
      #|    "digestVerified": true,
      #|    "etag": "\"bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"",
      #|    "signature": {
      #|      "status": "verified",
      #|      "algorithm": "sha256",
      #|      "keyId": "acme-main",
      #|      "value": "ZmFrZS1zaWduYXR1cmU="
      #|    }
      #|  }
      #|}
    ),
  )
  guard validate_codeiq_publish_receipt_v1(receipt) is Ok(_) else {
    fail("publish receipt should allow signature value")
  }
}

///|
test "registry-download schema validates 304 response" {
  let download = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 304,
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "bundleId": "bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "etag": "\"bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
      #|  "notModified": true
      #|}
    ),
  )
  guard validate_codeiq_registry_download_v1(download) is Ok(_) else {
    fail(
      "registry download response should satisfy codeiq-registry-download/v1 schema",
    )
  }
}

///|
test "registry-download schema validates signature metadata" {
  let download = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 200,
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "bundleId": "bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "etag": "\"bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
      #|  "notModified": false,
      #|  "signature": {
      #|    "status": "untrusted",
      #|    "algorithm": "sha256",
      #|    "keyId": "unknown-key"
      #|  }
      #|}
    ),
  )
  guard validate_codeiq_registry_download_v1(download) is Ok(_) else {
    fail("registry download should allow signature metadata")
  }
}

///|
test "registry-download schema validates signature value" {
  let download = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 200,
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "bundleId": "bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "etag": "\"bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
      #|  "notModified": false,
      #|  "signature": {
      #|    "status": "verified",
      #|    "algorithm": "sha256",
      #|    "keyId": "acme-main",
      #|    "value": "ZmFrZS1zaWduYXR1cmU="
      #|  }
      #|}
    ),
  )
  guard validate_codeiq_registry_download_v1(download) is Ok(_) else {
    fail("registry download should allow signature value")
  }
}

///|
test "registry-upload schema validates signature metadata" {
  let upload = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-upload/v1",
      #|  "endpoint": "POST /api/v1/bundles",
      #|  "bundleFile": "dist/bundle.ciq.tgz",
      #|  "bundleType": "ciq-opa-bundle",
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "size": 12345,
      #|  "signature": {
      #|    "status": "verified",
      #|    "algorithm": "sha256",
      #|    "keyId": "acme-main",
      #|    "value": "ZmFrZS1zaWduYXR1cmU="
      #|  }
      #|}
    ),
  )
  guard validate_codeiq_registry_upload_v1(upload) is Ok(_) else {
    fail("upload request should allow signature metadata")
  }
}

///|
test "registry-download schema rejects missing digest" {
  let download = must_parse_json_contract(
    (
      #|{
      #|  "schemaVersion": "codeiq-registry-download/v1",
      #|  "status": 200,
      #|  "purl": "pkg:generic/acme/compat-policy@2026.03.01",
      #|  "bundleId": "bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "etag": "\"bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"",
      #|  "downloadUrl": "local://.codeiq/cache/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
      #|  "notModified": false,
      #|  "contentLength": 1234
      #|}
    ),
  )
  let out = validate_codeiq_registry_download_v1(download)
  guard out is Err(_) else {
    fail("registry download without digest should fail schema validation")
  }
}
