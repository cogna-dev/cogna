# json-schema library

Reusable JSON Schema parsing and validation utilities for MoonBit packages.

This package intentionally contains **generic** capabilities only:

- Schema parsing (`parse_schema_text`)
- Schema meta validation (`validate_schema_json`)
- JSON instance validation (`validate_json`)
- Shared error model (`SchemaError`, `ValidationIssue`)

Business-specific schemas (for CodeIQ contracts like `ciq-bundle/v1`) should stay in
the `src/schema` package.

## Example

```mbt check
///|
test "json-schema basic validation" {
  let schema_text =
    #|{
    #|  "type": "object",
    #|  "required": ["name"],
    #|  "properties": {
    #|    "name": { "type": "string", "minLength": 1 }
    #|  },
    #|  "additionalProperties": false
    #|}

  let parsed = parse_schema_text(schema_text)
  guard parsed is Ok(schema) else { fail("schema should parse") }

  let instance : Json = { "name": "CodeIQ" }
  guard validate_json(schema, instance) is Ok(_) else {
    fail("instance should pass")
  }
}
```
