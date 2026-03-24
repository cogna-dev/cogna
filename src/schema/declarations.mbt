///|
pub fn ciq_declaration_v1_schema() -> @json_schema.JsonSchema {
  {
    "type": "object",
    "required": [
      "id", "kind", "name", "canonical_name", "path", "signature", "shape", "visibility",
      "docs", "baselineRole", "language", "source_refs", "relations", "location",
      "language_specific",
    ],
    "properties": {
      "id": { "type": "string", "minLength": 1 },
      "kind": { "type": "string", "minLength": 1 },
      "name": { "type": "string", "minLength": 1 },
      "canonical_name": { "type": "string", "minLength": 1 },
      "path": { "type": "string", "minLength": 1 },
      "signature": { "type": "string", "minLength": 1 },
      "shape": {
        "type": "object",
        "required": ["kind", "subkind", "form", "signature"],
        "properties": {
          "kind": { "type": "string", "minLength": 1 },
          "subkind": { "type": "string", "minLength": 1 },
          "form": { "type": "string", "enum": ["symbol", "callable"] },
          "signature": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "visibility": { "type": "string", "minLength": 1 },
      "docs": { "type": "string" },
      "baselineRole": { "type": "string", "const": "baseline" },
      "language": { "type": "string", "minLength": 1 },
      "source_refs": {
        "type": "array",
        "minItems": 1,
        "items": {
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
      "relations": {
        "type": "array",
        "minItems": 1,
        "items": {
          "type": "object",
          "required": ["kind", "target"],
          "properties": {
            "kind": {
              "type": "string",
              "enum": [
                "declared_in", "contains", "has_member", "has_parameter", "returns",
                "references_type", "implements",
              ],
            },
            "target": { "type": "string", "minLength": 1 },
          },
          "additionalProperties": false,
        },
      },
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
      "language_specific": {
        "type": "object",
        "required": ["profile", "server"],
        "properties": {
          "profile": { "type": "string", "minLength": 1 },
          "server": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": true,
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn validate_ciq_declaration_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @json_schema.validate_json(ciq_declaration_v1_schema(), instance)
}
