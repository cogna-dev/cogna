///|
fn parse_declaration_json(text : String) -> Json {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    abort("failed to parse declaration json fixture")
  }
  value
}

///|
test "declaration schema validates baseline declaration" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:go-module:go-module::main.go::Hello",
      #|  "kind": "function",
      #|  "name": "Hello",
      #|  "canonical_name": "go-module::main.go::Hello",
      #|  "path": "main.go",
      #|  "signature": "func Hello(name string) string",
      #|  "shape": {
      #|    "kind": "function",
      #|    "subkind": "function",
      #|    "form": "callable",
      #|    "signature": "func Hello(name string) string"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "go",
      #|  "source_refs": [
      #|    {"uri": "main.go", "startLine": 3, "endLine": 3}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:main.go"},
      #|    {"kind": "has_parameter", "target": "type:go-module::string"},
      #|    {"kind": "returns", "target": "type:go-module::string"}
      #|  ],
      #|  "location": {"uri": "main.go", "startLine": 3, "endLine": 3},
      #|  "language_specific": {"profile": "go-module", "server": "gopls"}
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail("baseline declaration should satisfy ciq-declaration/v1 schema")
  }
}

///|
test "declaration schema rejects unknown relation kind" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:go-module:go-module::main.go::Hello",
      #|  "kind": "function",
      #|  "name": "Hello",
      #|  "canonical_name": "go-module::main.go::Hello",
      #|  "path": "main.go",
      #|  "signature": "func Hello(name string) string",
      #|  "shape": {
      #|    "kind": "function",
      #|    "subkind": "function",
      #|    "form": "callable",
      #|    "signature": "func Hello(name string) string"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "go",
      #|  "source_refs": [
      #|    {"uri": "main.go", "startLine": 3, "endLine": 3}
      #|  ],
      #|  "relations": [
      #|    {"kind": "invalid_relation", "target": "file:main.go"}
      #|  ],
      #|  "location": {"uri": "main.go", "startLine": 3, "endLine": 3},
      #|  "language_specific": {"profile": "go-module", "server": "gopls"}
      #|}
    ),
  )

  let out = validate_ciq_declaration_v1(record)
  guard out is Err(_) else {
    fail("declaration with unknown relation kind should fail schema validation")
  }
}

///|
test "declaration schema rejects unknown top-level field" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:go-module:go-module::main.go::Hello",
      #|  "kind": "function",
      #|  "name": "Hello",
      #|  "canonical_name": "go-module::main.go::Hello",
      #|  "path": "main.go",
      #|  "signature": "func Hello(name string) string",
      #|  "shape": {
      #|    "kind": "function",
      #|    "subkind": "function",
      #|    "form": "callable",
      #|    "signature": "func Hello(name string) string"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "go",
      #|  "source_refs": [
      #|    {"uri": "main.go", "startLine": 3, "endLine": 3}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:main.go"}
      #|  ],
      #|  "location": {"uri": "main.go", "startLine": 3, "endLine": 3},
      #|  "language_specific": {"profile": "go-module", "server": "gopls"},
      #|  "unexpected": true
      #|}
    ),
  )

  let out = validate_ciq_declaration_v1(record)
  guard out is Err(_) else {
    fail("declaration with unknown top-level field should fail schema validation")
  }
}
