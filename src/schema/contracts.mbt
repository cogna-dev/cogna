///|
fn semantic_finding_schema() -> Json {
  {
    "type": "object",
    "required": ["code"],
    "properties": { "code": { "type": "string", "minLength": 1 } },
    "additionalProperties": true,
  }
}

///|
fn semantic_diff_schema() -> Json {
  {
    "type": "object",
    "properties": {
      "findings": { "type": "array", "items": semantic_finding_schema() },
      "changedFields": { "type": "array" },
      "shapeDiff": { "type": "object" },
      "languageSpecificDiff": { "type": "object" },
    },
    "additionalProperties": true,
  }
}

///|
pub fn codeiq_policy_rules_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": ["schemaVersion", "rules"],
    "properties": {
      "schemaVersion": { "type": "string", "const": "codeiq-policy-rules/v1" },
      "rules": {
        "type": "array",
        "items": {
          "type": "object",
          "required": [
            "id", "family", "defaultLevel", "summary", "docs", "entrypoint",
          ],
          "properties": {
            "id": { "type": "string", "minLength": 1 },
            "family": { "type": "string", "minLength": 1 },
            "defaultLevel": {
              "type": "string",
              "enum": ["error", "warning", "note"],
            },
            "summary": { "type": "string", "minLength": 1 },
            "docs": { "type": "string", "minLength": 1 },
            "entrypoint": { "type": "string", "minLength": 1 },
          },
          "additionalProperties": false,
        },
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn ciq_bundle_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": [
      "schemaVersion", "purl", "profile", "declarationSchema", "source", "artifacts",
    ],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-bundle/v1" },
      "purl": { "type": "string", "minLength": 1 },
      "profile": {
        "type": "string",
        "enum": ["go-module", "rust-crate", "terraform-module", "openapi-spec"],
      },
      "declarationSchema": {
        "type": "object",
        "required": ["version", "format", "model"],
        "properties": {
          "version": { "type": "string", "const": "ciq-declarations/v1" },
          "format": { "type": "string", "enum": ["ndjson"] },
          "model": { "type": "string", "minLength": 1 },
          "schema": { "type": "object" },
        },
        "additionalProperties": true,
      },
      "source": {
        "type": "object",
        "required": ["repo", "ref", "commit"],
        "properties": {
          "repo": { "type": "string", "minLength": 1 },
          "ref": { "type": "string", "minLength": 1 },
          "commit": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "artifacts": {
        "type": "array",
        "minItems": 1,
        "items": {
          "type": "object",
          "required": ["path", "sha256", "compression"],
          "properties": {
            "path": { "type": "string", "minLength": 1 },
            "sha256": { "type": "string", "minLength": 1 },
            "compression": { "type": "string", "minLength": 1 },
          },
          "additionalProperties": false,
        },
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn ciq_diff_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": [
      "schemaVersion", "basePurl", "targetPurl", "summary", "changes",
    ],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-diff/v1" },
      "basePurl": { "type": "string", "minLength": 1 },
      "targetPurl": { "type": "string", "minLength": 1 },
      "summary": {
        "type": "object",
        "required": ["added", "removed", "changed", "deprecated"],
        "properties": {
          "added": { "type": "integer" },
          "removed": { "type": "integer" },
          "changed": { "type": "integer" },
          "deprecated": { "type": "integer" },
        },
        "additionalProperties": false,
      },
      "changes": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["kind", "id", "path", "level"],
          "properties": {
            "kind": {
              "type": "string",
              "enum": ["added", "removed", "changed", "deprecated"],
            },
            "id": { "type": "string", "minLength": 1 },
            "path": { "type": "string", "minLength": 1 },
            "level": {
              "type": "string",
              "enum": ["breaking", "warning", "note", "error"],
            },
            "before": { "type": "string", "minLength": 1 },
            "after": { "type": "string", "minLength": 1 },
            "beforeRecord": { "type": "object" },
            "afterRecord": { "type": "object" },
            "semanticDiff": semantic_diff_schema(),
            "componentDiff": { "type": "object" },
          },
          "additionalProperties": false,
        },
      },
      "includeTestChanges": { "type": "boolean" },
      "testSummary": {
        "type": "object",
        "required": ["added", "modified", "removed"],
        "properties": {
          "added": { "type": "integer" },
          "modified": { "type": "integer" },
          "removed": { "type": "integer" },
        },
        "additionalProperties": false,
      },
      "testChanges": {
        "type": "array",
        "items": {
          "type": "object",
          "required": [
            "kind", "language", "id", "path", "signature", "location",
          ],
          "properties": {
            "kind": {
              "type": "string",
              "enum": ["added", "modified", "removed"],
            },
            "language": { "type": "string", "enum": ["go", "rust", "unknown"] },
            "id": { "type": "string", "minLength": 1 },
            "path": { "type": "string", "minLength": 1 },
            "signature": { "type": "string", "minLength": 1 },
            "location": {
              "type": "object",
              "required": ["uri", "startLine", "endLine"],
              "properties": {
                "uri": { "type": "string", "minLength": 1 },
                "startLine": { "type": "integer" },
                "endLine": { "type": "integer" },
              },
              "additionalProperties": false,
            },
            "tracking": {
              "type": "object",
              "properties": {
                "traceabilityKey": { "type": "string", "minLength": 1 },
                "externalIds": {
                  "type": "array",
                  "items": { "type": "string", "minLength": 1 },
                },
              },
              "additionalProperties": true,
            },
          },
          "additionalProperties": false,
        },
      },
    },
    "additionalProperties": true,
  }
}

///|
pub fn ciq_query_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": ["schemaVersion", "purl", "selector"],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-query/v1" },
      "purl": { "type": "string", "minLength": 1 },
      "selector": {
        "type": "object",
        "required": ["path"],
        "properties": {
          "path": { "type": "string", "minLength": 1 },
          "kind": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": true,
      },
      "repo": { "type": "string", "minLength": 1 },
      "intent": { "type": "string" },
    },
    "additionalProperties": false,
  }
}

///|
pub fn ciq_result_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": ["schemaVersion", "purl", "matches"],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-result/v1" },
      "purl": { "type": "string", "minLength": 1 },
      "matches": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["id", "kind", "signature", "location"],
          "properties": {
            "id": { "type": "string", "minLength": 1 },
            "kind": { "type": "string", "minLength": 1 },
            "path": { "type": "string", "minLength": 1 },
            "name": { "type": "string", "minLength": 1 },
            "canonical_name": { "type": "string", "minLength": 1 },
            "language": { "type": "string", "minLength": 1 },
            "baselineRole": { "type": "string", "minLength": 1 },
            "source_refs": { "type": "array" },
            "relations": { "type": "array" },
            "visibility": { "type": "string", "minLength": 1 },
            "docs": { "type": "string" },
            "signature": { "type": "string", "minLength": 1 },
            "shape": { "type": "object" },
            "language_specific": { "type": "object" },
            "location": {
              "type": "object",
              "required": ["uri", "startLine", "endLine"],
              "properties": {
                "uri": { "type": "string", "minLength": 1 },
                "startLine": { "type": "integer" },
                "endLine": { "type": "integer" },
              },
              "additionalProperties": false,
            },
          },
          "additionalProperties": false,
        },
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn ciq_opa_bundle_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": [
      "schemaVersion", "purl", "profile", "source", "artifacts", "provenance",
    ],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-opa-bundle/v1" },
      "purl": { "type": "string", "minLength": 1 },
      "profile": { "type": "string", "const": "policy-bundle" },
      "source": {
        "type": "object",
        "required": ["repo", "ref", "commit"],
        "properties": {
          "repo": { "type": "string", "minLength": 1 },
          "ref": { "type": "string", "minLength": 1 },
          "commit": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "opa": {
        "type": "object",
        "required": ["entrypoint", "format"],
        "properties": {
          "entrypoint": { "type": "string", "minLength": 1 },
          "format": { "type": "string", "const": "opa-bundle.tar.gz" },
        },
        "additionalProperties": false,
      },
      "provenance": {
        "type": "object",
        "required": ["checksums", "signature"],
        "properties": {
          "checksums": { "type": "string", "const": "checksums.txt" },
          "signature": {
            "type": "object",
            "required": ["status", "algorithm"],
            "properties": {
              "status": {
                "type": "string",
                "enum": ["unsigned", "verified", "untrusted"],
              },
              "algorithm": { "type": "string", "const": "sha256" },
              "keyId": { "type": "string", "minLength": 1 },
              "value": { "type": "string", "minLength": 1 },
            },
            "additionalProperties": false,
          },
        },
        "additionalProperties": false,
      },
      "artifacts": {
        "type": "array",
        "minItems": 1,
        "items": {
          "type": "object",
          "required": ["path", "sha256", "compression"],
          "properties": {
            "path": { "type": "string", "minLength": 1 },
            "sha256": { "type": "string", "minLength": 1 },
            "compression": { "type": "string", "minLength": 1 },
          },
          "additionalProperties": false,
        },
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn codeiq_registry_upload_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": [
      "schemaVersion", "endpoint", "bundleFile", "bundleType", "purl", "digest",
      "size",
    ],
    "properties": {
      "schemaVersion": {
        "type": "string",
        "const": "codeiq-registry-upload/v1",
      },
      "endpoint": { "type": "string", "const": "POST /api/v1/bundles" },
      "bundleFile": { "type": "string", "minLength": 1 },
      "bundleType": {
        "type": "string",
        "enum": ["ciq-bundle", "ciq-opa-bundle"],
      },
      "purl": { "type": "string", "minLength": 1 },
      "digest": { "type": "string", "minLength": 1 },
      "size": { "type": "integer" },
      "signature": {
        "type": "object",
        "required": ["status", "algorithm"],
        "properties": {
          "status": {
            "type": "string",
            "enum": ["unsigned", "verified", "untrusted"],
          },
          "algorithm": { "type": "string", "const": "sha256" },
          "keyId": { "type": "string", "minLength": 1 },
          "value": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn codeiq_publish_receipt_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": [
      "schemaVersion", "publishId", "bundleId", "purl", "digest", "bundleType", "downloadUrl",
      "status", "provenance",
    ],
    "properties": {
      "schemaVersion": {
        "type": "string",
        "const": "codeiq-publish-receipt/v1",
      },
      "publishId": { "type": "string", "minLength": 1 },
      "bundleId": { "type": "string", "minLength": 1 },
      "purl": { "type": "string", "minLength": 1 },
      "digest": { "type": "string", "minLength": 1 },
      "bundleType": {
        "type": "string",
        "enum": ["ciq-bundle", "ciq-opa-bundle"],
      },
      "downloadUrl": { "type": "string", "minLength": 1 },
      "status": { "type": "string", "enum": ["published", "already-exists"] },
      "dependencyCount": { "type": "integer" },
      "dependencyReceipts": {
        "type": "array",
        "items": {
          "type": "object",
          "required": [
            "schemaVersion", "publishId", "bundleId", "purl", "digest", "bundleType",
            "downloadUrl", "status", "provenance",
          ],
          "properties": {
            "schemaVersion": {
              "type": "string",
              "const": "codeiq-publish-receipt/v1",
            },
            "publishId": { "type": "string", "minLength": 1 },
            "bundleId": { "type": "string", "minLength": 1 },
            "purl": { "type": "string", "minLength": 1 },
            "digest": { "type": "string", "minLength": 1 },
            "bundleType": {
              "type": "string",
              "enum": ["ciq-bundle", "ciq-opa-bundle"],
            },
            "downloadUrl": { "type": "string", "minLength": 1 },
            "status": {
              "type": "string",
              "enum": ["published", "already-exists"],
            },
            "provenance": { "type": "object" },
          },
          "additionalProperties": true,
        },
      },
      "provenance": {
        "type": "object",
        "required": ["source", "digestVerified"],
        "properties": {
          "source": {
            "type": "string",
            "enum": ["local-registry", "remote-registry"],
          },
          "digestVerified": { "type": "boolean" },
          "etag": { "type": "string", "minLength": 1 },
          "signature": {
            "type": "object",
            "required": ["status", "algorithm"],
            "properties": {
              "status": {
                "type": "string",
                "enum": ["unsigned", "verified", "untrusted"],
              },
              "algorithm": { "type": "string", "const": "sha256" },
              "keyId": { "type": "string", "minLength": 1 },
              "value": { "type": "string", "minLength": 1 },
            },
            "additionalProperties": false,
          },
        },
        "additionalProperties": false,
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn codeiq_registry_download_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": [
      "schemaVersion", "status", "purl", "bundleId", "digest", "etag", "downloadUrl",
      "notModified",
    ],
    "properties": {
      "schemaVersion": {
        "type": "string",
        "const": "codeiq-registry-download/v1",
      },
      "status": { "type": "integer", "enum": [200, 304] },
      "purl": { "type": "string", "minLength": 1 },
      "bundleId": { "type": "string", "minLength": 1 },
      "digest": { "type": "string", "minLength": 1 },
      "etag": { "type": "string", "minLength": 1 },
      "downloadUrl": { "type": "string", "minLength": 1 },
      "notModified": { "type": "boolean" },
      "contentLength": { "type": "integer" },
      "signature": {
        "type": "object",
        "required": ["status", "algorithm"],
        "properties": {
          "status": {
            "type": "string",
            "enum": ["unsigned", "verified", "untrusted"],
          },
          "algorithm": { "type": "string", "const": "sha256" },
          "keyId": { "type": "string", "minLength": 1 },
          "value": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn sarif_v2_1_0_min_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": ["version", "runs"],
    "properties": {
      "version": { "type": "string", "const": "2.1.0" },
      "runs": {
        "type": "array",
        "minItems": 1,
        "items": {
          "type": "object",
          "required": ["tool", "results"],
          "properties": {
            "tool": {
              "type": "object",
              "required": ["driver"],
              "properties": {
                "driver": {
                  "type": "object",
                  "required": ["name", "rules"],
                  "properties": {
                    "name": { "type": "string", "minLength": 1 },
                    "rules": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "required": ["id", "shortDescription"],
                        "properties": {
                          "id": { "type": "string", "minLength": 1 },
                          "shortDescription": {
                            "type": "object",
                            "required": ["text"],
                            "properties": {
                              "text": { "type": "string", "minLength": 1 },
                            },
                            "additionalProperties": true,
                          },
                        },
                        "additionalProperties": true,
                      },
                    },
                  },
                  "additionalProperties": true,
                },
              },
              "additionalProperties": true,
            },
            "results": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["ruleId", "level", "message"],
                "properties": {
                  "ruleId": { "type": "string", "minLength": 1 },
                  "level": {
                    "type": "string",
                    "enum": ["note", "warning", "error"],
                  },
                  "message": {
                    "type": "object",
                    "required": ["text"],
                    "properties": {
                      "text": { "type": "string", "minLength": 1 },
                    },
                    "additionalProperties": true,
                  },
                },
                "additionalProperties": true,
              },
            },
          },
          "additionalProperties": true,
        },
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn validate_ciq_bundle_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(ciq_bundle_v1_schema(), instance)
}

///|
pub fn validate_ciq_diff_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(ciq_diff_v1_schema(), instance)
}

///|
pub fn validate_ciq_query_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(ciq_query_v1_schema(), instance)
}

///|
pub fn validate_ciq_result_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(ciq_result_v1_schema(), instance)
}

///|
pub fn validate_ciq_opa_bundle_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(ciq_opa_bundle_v1_schema(), instance)
}

///|
pub fn validate_codeiq_policy_rules_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(codeiq_policy_rules_v1_schema(), instance)
}

///|
pub fn validate_codeiq_registry_upload_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(codeiq_registry_upload_v1_schema(), instance)
}

///|
pub fn validate_codeiq_publish_receipt_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(codeiq_publish_receipt_v1_schema(), instance)
}

///|
pub fn validate_codeiq_registry_download_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(codeiq_registry_download_v1_schema(), instance)
}

///|
pub fn validate_sarif_v2_1_0_min(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(sarif_v2_1_0_min_schema(), instance)
}
