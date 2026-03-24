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
      #|    "format": "ndjson.zst",
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
      #|    {"path":"declarations.ndjson.zst","sha256":"abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd","compression":"zstd"}
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
      #|    {"path":"declarations.ndjson.zst","sha256":"abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd","compression":"zstd"},
      #|    {"path":"symbols.ndjson.zst","sha256":"bcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcde","compression":"zstd"},
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
      #|      "path": "declarations.ndjson.zst",
      #|      "sha256": "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      #|      "compression": "zstd"
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
      #|      "path": "declarations.ndjson.zst",
      #|      "sha256": "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      #|      "compression": "zstd"
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
      #|      "path": "declarations.ndjson.zst",
      #|      "sha256": "abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
      #|      "compression": "zstd"
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
      #|  "downloadUrl": "https://registry.acme.dev/api/v1/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
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
      #|  "downloadUrl": "https://registry.acme.dev/api/v1/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
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
      #|  "downloadUrl": "https://registry.acme.dev/api/v1/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      #|  "status": "published",
      #|  "provenance": {
      #|    "source": "remote-registry",
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
      #|  "downloadUrl": "local://.codeiq/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
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
      #|  "downloadUrl": "local://.codeiq/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
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
      #|  "downloadUrl": "local://.codeiq/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
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
      #|  "downloadUrl": "local://.codeiq/registry/bundles/bundle_sha256_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.ciq.tgz",
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
