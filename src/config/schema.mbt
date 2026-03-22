///|
pub fn ciq_config_v1_schema() -> @json_schema.JsonSchema {
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "ciq-config/v1",
    "type": "object",
    "required": [
      "schemaVersion", "profile", "purl", "source", "inputs", "checks",
    ],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-config/v1" },
      "profile": {
        "type": "string",
        "enum": [
          "go-module", "rust-crate", "terraform-module", "openapi-spec", "policy-bundle",
        ],
      },
      "purl": { "type": "string", "minLength": 1 },
      "source": {
        "type": "object",
        "required": ["repo", "ref"],
        "properties": {
          "repo": { "type": "string", "minLength": 1 },
          "ref": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "inputs": {
        "type": "object",
        "required": ["include"],
        "properties": {
          "include": {
            "type": "array",
            "minItems": 1,
            "items": { "type": "string", "minLength": 1 },
          },
        },
        "additionalProperties": false,
      },
      "checks": {
        "type": "object",
        "required": ["format", "policy"],
        "properties": {
          "format": { "type": "string", "const": "sarif" },
          "policy": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn config_to_json(config : Config) -> Json {
  {
    "schemaVersion": config.schema_version,
    "profile": config.profile,
    "purl": config.purl,
    "source": { "repo": config.source.repo, "ref": config.source.source_ref },
    "inputs": { "include": config.inputs.include_paths },
    "checks": { "format": config.checks.format, "policy": config.checks.policy },
  }
}
