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
      #|    "commit": "unknown"
      #|  },
      #|  "artifacts": [
      #|    {"path":"declarations.ndjson.zst","sha256":"x","compression":"zstd"}
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
