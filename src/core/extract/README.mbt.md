# extractors package

Cogna declaration extraction primitives and profile-specific post-processing.

This package intentionally contains product-bound extraction logic:

- declaration and symbol record construction
- shared shape/relation enrichment
- Go and Rust extractor post-processing
- NDJSON emission helpers for bundle artifacts

Command-layer orchestration stays in `src/cmd/build`.

## Example

```mbt check
///|
test "extractors build canonical declaration ids" {
  inspect(
    declaration_id("go-module", "main.go", "Hello"),
    content="decl:go-module:go-module::main.go::Hello",
  )
}
```
