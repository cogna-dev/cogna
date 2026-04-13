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
    fail(
      "declaration with unknown top-level field should fail schema validation",
    )
  }
}

///|
test "declaration schema accepts terraform provider metadata and relations" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:terraform-module:terraform-module::main.tf::aws_vpc.main",
      #|  "kind": "resource",
      #|  "name": "aws_vpc.main",
      #|  "canonical_name": "terraform-module::main.tf::aws_vpc.main",
      #|  "path": "main.tf",
      #|  "signature": "resource \"aws_vpc\" \"main\" {",
      #|  "shape": {
      #|    "kind": "resource",
      #|    "subkind": "resource",
      #|    "form": "symbol",
      #|    "signature": "resource \"aws_vpc\" \"main\" {"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "terraform",
      #|  "source_refs": [
      #|    {"uri": "main.tf", "startLine": 44, "endLine": 44}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:main.tf"},
      #|    {"kind": "uses_provider", "target": "decl:terraform-module:terraform-module::main.tf::aws"}
      #|  ],
      #|  "location": {"uri": "main.tf", "startLine": 44, "endLine": 44},
      #|  "language_specific": {
      #|    "profile": "terraform-module",
      #|    "server": "hcl-parser",
      #|    "providers": {
      #|      "terraform": [
      #|        {
      #|          "name": "aws",
      #|          "source": "hashicorp/aws",
      #|          "version": ">= 5.0.0",
      #|          "alias": "east"
      #|        }
      #|      ]
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail(
      "terraform provider metadata and provider relations should satisfy ciq-declaration/v1 schema",
    )
  }
}

///|
test "declaration schema accepts richer terraform contract metadata" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:terraform-module:terraform-module::main.tf::network_labels",
      #|  "kind": "module",
      #|  "name": "network_labels",
      #|  "canonical_name": "terraform-module::main.tf::network_labels",
      #|  "path": "main.tf",
      #|  "signature": "module \"network_labels\" {",
      #|  "shape": {
      #|    "kind": "module",
      #|    "subkind": "module",
      #|    "form": "symbol",
      #|    "signature": "module \"network_labels\" {",
      #|    "owner": "network_labels"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "terraform",
      #|  "source_refs": [
      #|    {"uri": "main.tf", "startLine": 48, "endLine": 48}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:main.tf"},
      #|    {"kind": "uses_provider", "target": "decl:terraform-module:terraform-module::main.tf::aws"}
      #|  ],
      #|  "location": {"uri": "main.tf", "startLine": 48, "endLine": 48},
      #|  "language_specific": {
      #|    "profile": "terraform-module",
      #|    "server": "hcl-parser",
      #|    "providers": {
      #|      "terraform": [
      #|        {
      #|          "name": "aws",
      #|          "source": "hashicorp/aws",
      #|          "version": ">= 5.0.0",
      #|          "alias": "east"
      #|        }
      #|      ]
      #|    },
      #|    "terraform": {
      #|      "moduleSource": "./modules/labels",
      #|      "providerRef": "aws.east",
      #|      "dependsOn": ["data.aws_caller_identity.current"]
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail(
      "terraform richer contract metadata should satisfy ciq-declaration/v1 schema",
    )
  }
}

///|
test "declaration schema accepts terraform lifecycle metadata" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:terraform-module:terraform-module::main.tf::aws_vpc.main",
      #|  "kind": "resource",
      #|  "name": "aws_vpc.main",
      #|  "canonical_name": "terraform-module::main.tf::aws_vpc.main",
      #|  "path": "main.tf",
      #|  "signature": "resource \"aws_vpc\" \"main\" {",
      #|  "shape": {
      #|    "kind": "resource",
      #|    "subkind": "resource",
      #|    "form": "symbol",
      #|    "signature": "resource \"aws_vpc\" \"main\" {"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "terraform",
      #|  "source_refs": [
      #|    {"uri": "main.tf", "startLine": 56, "endLine": 56}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:main.tf"},
      #|    {"kind": "uses_provider", "target": "decl:terraform-module:terraform-module::main.tf::aws"}
      #|  ],
      #|  "location": {"uri": "main.tf", "startLine": 56, "endLine": 56},
      #|  "language_specific": {
      #|    "profile": "terraform-module",
      #|    "server": "hcl-parser",
      #|    "terraform": {
      #|      "providerRef": "aws.east",
      #|      "dependsOn": ["module.network_labels"],
      #|      "preventDestroy": true,
      #|      "createBeforeDestroy": true,
      #|      "ignoreChanges": ["tags"]
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail(
      "terraform lifecycle metadata should satisfy ciq-declaration/v1 schema",
    )
  }
}

///|
test "declaration schema accepts richer openapi contract metadata" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment",
      #|  "kind": "operation",
      #|  "name": "createPayment",
      #|  "canonical_name": "openapi-spec::openapi::payment.yaml::createPayment",
      #|  "path": "openapi/payment.yaml",
      #|  "signature": "operation createPayment",
      #|  "shape": {
      #|    "kind": "operation",
      #|    "subkind": "operation",
      #|    "form": "symbol",
      #|    "signature": "operation createPayment"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "openapi",
      #|  "source_refs": [
      #|    {"uri": "openapi/payment.yaml", "startLine": 26, "endLine": 26}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:openapi/payment.yaml"}
      #|  ],
      #|  "location": {"uri": "openapi/payment.yaml", "startLine": 26, "endLine": 26},
      #|  "language_specific": {
      #|    "profile": "openapi-spec",
      #|    "server": "none",
      #|    "openapi": {
      #|      "httpMethod": "POST",
      #|      "operationId": "createPayment",
      #|      "required": true,
      #|      "mediaTypes": ["application/json"],
      #|      "statusCodes": ["201"],
      #|      "callbackExpression": "{$request.body#/callbackUrl}"
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail(
      "openapi richer contract metadata should satisfy ciq-declaration/v1 schema",
    )
  }
}

///|
test "declaration schema accepts openapi discriminator and composition metadata" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:openapi-spec:openapi-spec::openapi::payment.yaml::Payment.discriminator",
      #|  "kind": "discriminator",
      #|  "name": "Payment.discriminator",
      #|  "canonical_name": "openapi-spec::openapi::payment.yaml::Payment.discriminator",
      #|  "path": "openapi/payment.yaml",
      #|  "signature": "discriminator:",
      #|  "shape": {
      #|    "kind": "discriminator",
      #|    "subkind": "discriminator",
      #|    "form": "symbol",
      #|    "signature": "discriminator:"
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "openapi",
      #|  "source_refs": [
      #|    {"uri": "openapi/payment.yaml", "startLine": 143, "endLine": 143}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:openapi/payment.yaml"}
      #|  ],
      #|  "location": {"uri": "openapi/payment.yaml", "startLine": 143, "endLine": 143},
      #|  "language_specific": {
      #|    "profile": "openapi-spec",
      #|    "server": "none",
      #|    "openapi": {
      #|      "discriminatorProperty": "type",
      #|      "discriminatorMapping": {
      #|        "card": "#/components/schemas/CardPayment",
      #|        "bank": "#/components/schemas/BankPayment"
      #|      },
      #|      "memberRefs": [
      #|        "#/components/schemas/CardPayment",
      #|        "#/components/schemas/BankPayment"
      #|      ]
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail(
      "openapi discriminator and composition metadata should satisfy ciq-declaration/v1 schema",
    )
  }
}

///|
test "declaration schema accepts richer language-specific semantics" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:go-module:go-module::main.go::Greet",
      #|  "kind": "method",
      #|  "name": "Greet",
      #|  "canonical_name": "go-module::main.go::Greet",
      #|  "path": "main.go",
      #|  "signature": "func (g *Greeter) Greet(name string) Message {",
      #|  "shape": {
      #|    "kind": "method",
      #|    "subkind": "method",
      #|    "form": "callable",
      #|    "signature": "func (g *Greeter) Greet(name string) Message {",
      #|    "owner": "Greeter",
      #|    "parameters": ["string"],
      #|    "returns": ["Message"]
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "go",
      #|  "source_refs": [
      #|    {"uri": "main.go", "startLine": 58, "endLine": 58}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:main.go"}
      #|  ],
      #|  "location": {"uri": "main.go", "startLine": 58, "endLine": 58},
      #|  "language_specific": {
      #|    "profile": "go-module",
      #|    "server": "gopls",
      #|    "go": {
      #|      "receiver": "Greeter",
      #|      "pointerReceiver": true,
      #|      "owner": "Greeter"
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail(
      "richer shape/language_specific payload should satisfy ciq-declaration/v1 schema",
    )
  }
}

///|
test "declaration schema accepts go method-set metadata and owner relations" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:go-module:go-module::main.go::Label",
      #|  "kind": "method",
      #|  "name": "Label",
      #|  "canonical_name": "go-module::main.go::Label",
      #|  "path": "main.go",
      #|  "signature": "func (g Greeter) Label() string {",
      #|  "shape": {
      #|    "kind": "method",
      #|    "subkind": "method",
      #|    "form": "callable",
      #|    "signature": "func (g Greeter) Label() string {",
      #|    "owner": "Greeter",
      #|    "returns": ["string"]
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "go",
      #|  "source_refs": [
      #|    {"uri": "main.go", "startLine": 66, "endLine": 66}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:main.go"},
      #|    {"kind": "returns", "target": "type:go-module::string"}
      #|  ],
      #|  "location": {"uri": "main.go", "startLine": 66, "endLine": 66},
      #|  "language_specific": {
      #|    "profile": "go-module",
      #|    "server": "gopls",
      #|    "go": {
      #|      "receiver": "Greeter",
      #|      "pointerReceiver": false,
      #|      "owner": "Greeter",
      #|      "methodSetTypes": ["Greeter", "*Greeter"]
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail("go method-set metadata should satisfy ciq-declaration/v1 schema")
  }
}

///|
test "declaration schema accepts richer rust semantic metadata" {
  let record = parse_declaration_json(
    (
      #|{
      #|  "id": "decl:rust-crate:rust-crate::lib.rs::Borrowed<'a, const N: usize>",
      #|  "kind": "struct",
      #|  "name": "Borrowed<'a, const N: usize>",
      #|  "canonical_name": "rust-crate::lib.rs::Borrowed<'a, const N: usize>",
      #|  "path": "lib.rs",
      #|  "signature": "pub struct Borrowed<'a, const N: usize> {",
      #|  "shape": {
      #|    "kind": "struct",
      #|    "subkind": "struct",
      #|    "form": "symbol",
      #|    "signature": "pub struct Borrowed<'a, const N: usize> {",
      #|    "owner": "Borrowed",
      #|    "type_params": ["'a", "const N: usize"]
      #|  },
      #|  "visibility": "public",
      #|  "docs": "",
      #|  "baselineRole": "baseline",
      #|  "language": "rust",
      #|  "source_refs": [
      #|    {"uri": "lib.rs", "startLine": 66, "endLine": 66}
      #|  ],
      #|  "relations": [
      #|    {"kind": "declared_in", "target": "file:lib.rs"}
      #|  ],
      #|  "location": {"uri": "lib.rs", "startLine": 66, "endLine": 66},
      #|  "language_specific": {
      #|    "profile": "rust-crate",
      #|    "server": "rust-analyzer",
      #|    "rust": {
      #|      "owner": "Borrowed",
      #|      "typeParams": ["'a", "const N: usize"],
      #|      "unsafe": false,
      #|      "externAbi": "C"
      #|    }
      #|  }
      #|}
    ),
  )

  guard validate_ciq_declaration_v1(record) is Ok(_) else {
    fail("richer rust metadata should satisfy ciq-declaration/v1 schema")
  }
}
