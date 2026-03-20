///|
pub fn ciq_bundle_v1_schema() -> JsonSchema {
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
          "format": { "type": "string", "const": "ndjson.zst" },
          "model": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
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
pub fn ciq_diff_v1_schema() -> JsonSchema {
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
          },
          "additionalProperties": true,
        },
      },
    },
    "additionalProperties": true,
  }
}

///|
pub fn ciq_query_v1_schema() -> JsonSchema {
  {
    "type": "object",
    "required": ["schemaVersion", "purl", "selector"],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-query/v1" },
      "purl": { "type": "string", "minLength": 1 },
      "selector": {
        "type": "object",
        "required": ["path", "kind"],
        "properties": {
          "path": { "type": "string", "minLength": 1 },
          "kind": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": true,
      },
      "intent": { "type": "string" },
    },
    "additionalProperties": false,
  }
}

///|
pub fn ciq_result_v1_schema() -> JsonSchema {
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
          },
          "additionalProperties": false,
        },
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn sarif_v2_1_0_min_schema() -> JsonSchema {
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
pub fn validate_ciq_bundle_v1(instance : Json) -> Result[Unit, SchemaError] {
  validate_json(ciq_bundle_v1_schema(), instance)
}

///|
pub fn validate_ciq_diff_v1(instance : Json) -> Result[Unit, SchemaError] {
  validate_json(ciq_diff_v1_schema(), instance)
}

///|
pub fn validate_ciq_query_v1(instance : Json) -> Result[Unit, SchemaError] {
  validate_json(ciq_query_v1_schema(), instance)
}

///|
pub fn validate_ciq_result_v1(instance : Json) -> Result[Unit, SchemaError] {
  validate_json(ciq_result_v1_schema(), instance)
}

///|
pub fn validate_sarif_v2_1_0_min(instance : Json) -> Result[Unit, SchemaError] {
  validate_json(sarif_v2_1_0_min_schema(), instance)
}
