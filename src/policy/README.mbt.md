# policy package

Built-in compatibility policy catalog and policy-document metadata for CodeIQ.

This package intentionally contains the CodeIQ policy domain:

- built-in rule catalog and docs URLs
- generated catalog JSON
- built-in Rego source
- rule parsing from policy text for downstream tools

It is product-specific policy logic, not a generic external catalog library.

## Example

```mbt check
///|
test "policy publishes docs index uri" {
  inspect(index_uri(), content="https://codeiq.xaclabs.dev/docs/policies")
}
```
