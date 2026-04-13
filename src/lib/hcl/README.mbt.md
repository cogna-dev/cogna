# hcl library

Reusable HCL/Terraform source parsing helpers for MoonBit packages.

This package intentionally contains **generic** capabilities only:

- Parse source lines into an `HclFile` (`parse_hcl_file`)
- Capture block metadata (`HclBlock`)
- Capture immediate attribute assignments (`HclAttr`)

Terraform-specific extraction policy should stay in the owning package.

## Example

```mbt check
///|
test "hcl parses a simple resource block" {
  let parsed = parse_hcl_file([
    "resource \"aws_vpc\" \"main\" {",
    "  cidr_block = \"10.0.0.0/16\"",
    "}",
  ])
  inspect(parsed.blocks.length(), content="1")
  let block = parsed.blocks[0]
  inspect(block.kind, content="resource")
  inspect(block.name, content="aws_vpc.main")
  inspect(block.attrs.length(), content="1")
}
```
