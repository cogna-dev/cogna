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
  inspect(block.signature, content="resource \"aws_vpc\" \"main\" {")
  inspect(block.line_no, content="1")
  inspect(block.attrs.length(), content="1")
  inspect(block.attrs[0].name, content="cidr_block")
  inspect(block.attrs[0].value, content="\"10.0.0.0/16\"")
  inspect(block.attrs[0].line_no, content="2")
}

///|
test "hcl preserves child before parent and ignores unknown blocks" {
  let parsed = parse_hcl_file([
    "resource \"aws_security_group\" \"web\" {",
    "  lifecycle {",
    "    ignore_changes = all",
    "  }",
    "  dynamic \"ingress\" {",
    "    for_each = []",
    "  }",
    "  name = \"web\"",
    "}",
  ])
  inspect(parsed.blocks.length(), content="2")
  inspect(parsed.blocks[0].kind, content="dynamic")
  inspect(parsed.blocks[0].name, content="ingress")
  inspect(parsed.blocks[0].attrs.length(), content="1")
  inspect(parsed.blocks[0].attrs[0].name, content="for_each")
  inspect(parsed.blocks[1].kind, content="resource")
  inspect(parsed.blocks[1].name, content="aws_security_group.web")
  inspect(parsed.blocks[1].attrs.length(), content="1")
  inspect(parsed.blocks[1].attrs[0].name, content="name")
  inspect(parsed.blocks[1].attrs[0].value, content="\"web\"")
}

///|
test "hcl parses one-line and zero-label blocks" {
  let parsed = parse_hcl_file([
    "locals {",
    "  region = \"us-east-1\"",
    "}",
    "terraform {}",
    "data \"aws_ami\" \"ubuntu\" {}",
  ])
  inspect(parsed.blocks.length(), content="3")
  inspect(parsed.blocks[0].kind, content="locals")
  inspect(parsed.blocks[0].name, content="locals")
  inspect(parsed.blocks[0].attrs.length(), content="1")
  inspect(parsed.blocks[1].kind, content="terraform")
  inspect(parsed.blocks[1].name, content="terraform")
  inspect(parsed.blocks[1].attrs.length(), content="0")
  inspect(parsed.blocks[2].kind, content="data")
  inspect(parsed.blocks[2].name, content="aws_ami.ubuntu")
}

///|
test "hcl ignores top-level attrs and unmatched close braces" {
  let parsed = parse_hcl_file([
    "name = \"top-level\"",
    "}",
    "module \"network\" {",
    "  source = \"./network\"",
    "}",
    "}",
  ])
  inspect(parsed.blocks.length(), content="1")
  inspect(parsed.blocks[0].kind, content="module")
  inspect(parsed.blocks[0].name, content="network")
  inspect(parsed.blocks[0].attrs.length(), content="1")
  inspect(parsed.blocks[0].attrs[0].name, content="source")
}
