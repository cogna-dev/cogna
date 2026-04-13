# schema package

JSON-schema contracts and validators for CodeIQ bundle, diff, query, registry, and SARIF artifacts.

This package intentionally contains:

- schema constructors for CodeIQ JSON contracts
- validation helpers for generated bundle and diff outputs
- declaration schema validation
- minimal SARIF shape validation used by command flows

It centralizes artifact contracts so commands and tests can share one source of truth.

## Example

```mbt check
///|
test "schema validates minimal bundle shape" {
  let bundle : Json = {
    "schemaVersion": "ciq-bundle/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.03.01",
    "profile": "openapi-spec",
    "declarationSchema": {
      "version": "ciq-declarations/v1",
      "format": "ndjson",
      "model": "signature + shape + language_specific tagged union",
    },
    "source": {
      "repo": "https://github.com/acme/payment-api",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      { "path": "declarations.ndjson", "sha256": "x", "compression": "none" },
    ],
  }
  inspect(validate_ciq_bundle_v1(bundle), content="Ok(())")
}
```
