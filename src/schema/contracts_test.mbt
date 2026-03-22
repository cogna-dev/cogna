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
      #|    "model": "signature + shape + language_specific tagged union"
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
      #|  "status": "published"
      #|}
    ),
  )
  guard validate_codeiq_publish_receipt_v1(receipt) is Ok(_) else {
    fail("publish receipt should satisfy codeiq-publish-receipt/v1 schema")
  }
}
