// SDK fixture tests validate API DTO parsing and runtime behavior.

///|
fn write_test_file(path : String, content : String) -> Unit {
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to write test file")
  }
}

///|
fn ensure_test_dir(path : String) -> Unit {
  if @fs.path_exists(path) {
    return
  }
  @fs.create_dir(path) catch {
    _ => abort("failed to create test directory")
  }
}

///|
fn setup_sdk_runtime_context() -> Unit {
  let config_text =
    #|schemaVersion: ciq-config/v1
    #|profile: go-module
    #|purl: pkg:golang/example/sdkacceptance@0.1.0
    #|source:
    #|  repo: https://github.com/example/cogna-sdkacceptance
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - "**/*.go"
    #|checks:
    #|  format: sarif
    #|  policy: ./.cogna/policies
    #|
  write_test_file("./cogna.yaml", config_text)
  ensure_test_dir("./dist")
  ensure_test_dir("./.cogna")
  ensure_test_dir("./.cogna/cache")

  let declarations : Array[Json] = [
    {
      "id": "decl:go:example/sdkacceptance.Greeter",
      "kind": "type",
      "name": "Greeter",
      "canonical_name": "Greeter",
      "path": "main.go",
      "signature": "type Greeter struct { Prefix string `json:\"prefix\"` }",
      "visibility": "public",
      "docs": "Greeter holds a prefix string used when greeting",
      "language": "go",
      "location": { "uri": "main.go", "startLine": 12, "endLine": 14 },
    },
    {
      "id": "decl:go:example/sdkacceptance.Greeter.Greet",
      "kind": "method",
      "name": "Greet",
      "canonical_name": "Greeter.Greet",
      "path": "main.go",
      "signature": "func (g Greeter) Greet(name string) string",
      "visibility": "public",
      "docs": "Greet returns a formatted greeting string for the given name",
      "language": "go",
      "location": { "uri": "main.go", "startLine": 27, "endLine": 35 },
    },
    {
      "id": "decl:go:example/sdkacceptance.NewRequestID",
      "kind": "function",
      "name": "NewRequestID",
      "canonical_name": "NewRequestID",
      "path": "main.go",
      "signature": "func NewRequestID(prefix string) string",
      "visibility": "public",
      "docs": "NewRequestID generates a new UUID-based request ID with the given prefix",
      "language": "go",
      "location": { "uri": "main.go", "startLine": 16, "endLine": 18 },
    },
    {
      "id": "decl:go:example/sdkacceptance.BuildLabels",
      "kind": "function",
      "name": "BuildLabels",
      "canonical_name": "BuildLabels",
      "path": "main.go",
      "signature": "func BuildLabels(items []string) []string",
      "visibility": "public",
      "docs": "BuildLabels filters empty items and formats each as name:index",
      "language": "go",
      "location": { "uri": "main.go", "startLine": 20, "endLine": 25 },
    },
  ]
  let declaration_lines : Array[String] = []
  for i in 0..<declarations.length() {
    declaration_lines.push(declarations[i].stringify())
  }
  write_test_file("./dist/declarations.ndjson", declaration_lines.join("\n") + "\n")

  let spdx_doc : Json = {
    "spdxVersion": "SPDX-2.3",
    "SPDXID": "SPDXRef-DOCUMENT",
    "name": "sdkacceptance",
    "packages": [
      {
        "SPDXID": "SPDXRef-Root",
        "name": "sdkacceptance",
        "versionInfo": "0.1.0",
      },
      {
        "SPDXID": "SPDXRef-Package-UUID",
        "name": "github.com/google/uuid",
        "versionInfo": "1.6.0",
        "externalRefs": [
          {
            "referenceCategory": "PACKAGE-MANAGER",
            "referenceType": "purl",
            "referenceLocator": "pkg:golang/github.com/google/uuid@1.6.0",
          },
        ],
      },
      {
        "SPDXID": "SPDXRef-Package-LO",
        "name": "github.com/samber/lo",
        "versionInfo": "1.49.1",
        "externalRefs": [
          {
            "referenceCategory": "PACKAGE-MANAGER",
            "referenceType": "purl",
            "referenceLocator": "pkg:golang/github.com/samber/lo@1.49.1",
          },
        ],
      },
    ],
    "relationships": [
      {
        "spdxElementId": "SPDXRef-Root",
        "relationshipType": "DEPENDS_ON",
        "relatedSpdxElement": "SPDXRef-Package-UUID",
      },
      {
        "spdxElementId": "SPDXRef-Root",
        "relationshipType": "DEPENDS_ON",
        "relatedSpdxElement": "SPDXRef-Package-LO",
      },
    ],
  }
  write_test_file("./.cogna/sbom.spdx.json", spdx_doc.stringify(indent=2))

  let manifest_records : Array[String] = [
    ({ "purl": "pkg:golang/example/sdkacceptance@0.1.0" } : Json).stringify(),
  ]
  write_test_file("./dist/manifest.ndjson", manifest_records.join("\n") + "\n")
}

///|
/// --- FetchPackages ---
test "fetch_packages: fixture input parses into FetchPackagesRequest" {
  let input : Json = {}
  let req = @generated.FetchPackagesRequest::from_json(input)
  assert_true(req is Some(_))
}

///|
test "fetch_packages: fixture output parses into FetchPackagesResponse" {
  let output : Json = {
    "root": {
      "name": "example/sdkacceptance",
      "version": "0.1.0",
      "ecosystem": "go",
      "relation": "root",
      "children": [
        {
          "name": "github.com/google/uuid",
          "version": "1.6.0",
          "ecosystem": "go",
          "relation": "direct",
          "children": [],
        },
        {
          "name": "github.com/samber/lo",
          "version": "1.49.1",
          "ecosystem": "go",
          "relation": "direct",
          "children": [
            {
              "name": "golang.org/x/text",
              "version": "0.21.0",
              "ecosystem": "go",
              "relation": "transitive",
              "children": [],
            },
          ],
        },
      ],
    },
  }
  let resp = @generated.FetchPackagesResponse::from_json(output)
  guard resp is Some(r) else { fail("FetchPackagesResponse should parse") }
  guard r.root is Some(root) else { fail("root should be present") }
  inspect(root.name, content="example/sdkacceptance")
  inspect(root.relation, content="root")
  inspect(root.children.length(), content="2")
  inspect(root.children[0].name, content="github.com/google/uuid")
  inspect(root.children[1].children.length(), content="1")
  inspect(root.children[1].children[0].name, content="golang.org/x/text")
}

///|
test "fetch_packages: api returns structurally valid FetchPackagesResponse" {
  setup_sdk_runtime_context()
  let req = @generated.FetchPackagesRequest::{  }
  let resp = fetch_packages(req)
  guard resp is Some(r) else { fail("fetch_packages should return Some") }
  guard r.root is Some(root) else {
    fail("root should be present")
  }
  inspect(root.name, content="sdkacceptance")
  inspect(root.relation, content="root")
  inspect(root.children.length(), content="2")
}

///|
/// --- QueryOutlines ---
test "query_outlines: fixture input parses into QueryOutlinesRequest" {
  let input : Json = { "package": "example/sdkacceptance" }
  let req = @generated.QueryOutlinesRequest::from_json(input)
  guard req is Some(r) else { fail("QueryOutlinesRequest should parse") }
  inspect(r.package, content="example/sdkacceptance")
}

///|
test "query_outlines: fixture output parses into QueryOutlinesResponse" {
  let output : Json = {
    "package": "example/sdkacceptance",
    "outlines": [
      {
        "id": "decl:go:example/sdkacceptance.Greeter",
        "symbol": "Greeter",
        "kind": "type",
        "summary": "Greeter holds a prefix string used when greeting",
        "deprecated": false,
        "location": { "uri": "main.go", "start_line": 12, "end_line": 14 },
      },
      {
        "id": "decl:go:example/sdkacceptance.Greeter.Greet",
        "symbol": "Greeter.Greet",
        "kind": "method",
        "summary": "Greet returns a formatted greeting string for the given name",
        "deprecated": false,
        "location": { "uri": "main.go", "start_line": 27, "end_line": 35 },
      },
      {
        "id": "decl:go:example/sdkacceptance.NewRequestID",
        "symbol": "NewRequestID",
        "kind": "function",
        "summary": "NewRequestID generates a new UUID-based request ID with the given prefix",
        "deprecated": false,
        "location": { "uri": "main.go", "start_line": 16, "end_line": 18 },
      },
      {
        "id": "decl:go:example/sdkacceptance.BuildLabels",
        "symbol": "BuildLabels",
        "kind": "function",
        "summary": "BuildLabels filters empty items and formats each as name:index",
        "deprecated": false,
        "location": { "uri": "main.go", "start_line": 20, "end_line": 25 },
      },
    ],
  }
  let resp = @generated.QueryOutlinesResponse::from_json(output)
  guard resp is Some(r) else { fail("QueryOutlinesResponse should parse") }
  inspect(r.package, content="example/sdkacceptance")
  inspect(r.outlines.length(), content="4")
  inspect(r.outlines[0].symbol, content="Greeter")
  inspect(r.outlines[0].kind, content="type")
  guard r.outlines[0].location is Some(loc) else {
    fail("location should parse")
  }
  inspect(loc.uri, content="main.go")
  inspect(loc.start_line, content="12")
}

///|
test "query_outlines: api returns real outlines from ndjson" {
  setup_sdk_runtime_context()
  let req : @generated.QueryOutlinesRequest = { package: "example/sdkacceptance" }
  let resp = query_outlines(req)
  guard resp is Some(r) else { fail("query_outlines should return Some") }
  inspect(r.package, content="example/sdkacceptance")
  inspect(r.outlines.length(), content="4")
  inspect(r.outlines[0].id, content="decl:go:example/sdkacceptance.Greeter")
  inspect(r.outlines[0].symbol, content="Greeter")
  inspect(r.outlines[0].kind, content="type")
  guard r.outlines[0].location is Some(loc) else {
    fail("location should be present")
  }
  inspect(loc.uri, content="main.go")
  inspect(loc.start_line, content="12")
  inspect(loc.end_line, content="14")
}

///|
/// --- Query: exact-id ---
test "query exact-id: fixture input parses into QueryRequest" {
  let input : Json = {
    "package": "example/sdkacceptance",
    "exact_id": "decl:go:example/sdkacceptance.Greeter",
  }
  let req = @generated.QueryRequest::from_json(input)
  guard req is Some(r) else { fail("QueryRequest should parse") }
  inspect(r.package, content="example/sdkacceptance")
  inspect(r.exact_id, content="Some(\"decl:go:example/sdkacceptance.Greeter\")")
  assert_true(r.exact_symbol is None)
  assert_true(r.text is None)
}

///|
test "query exact-id: fixture output parses into QueryResponse" {
  let output : Json = {
    "package": "example/sdkacceptance",
    "mode": "exact-id",
    "matches": [
      {
        "id": "decl:go:example/sdkacceptance.Greeter",
        "symbol": "Greeter",
        "kind": "type",
        "signature": "type Greeter struct { Prefix string `json:\"prefix\"` }",
        "summary": "Greeter holds a prefix string used when greeting",
        "docs": null,
        "score": null,
        "location": { "uri": "main.go", "start_line": 12, "end_line": 14 },
      },
    ],
    "cursor": null,
  }
  let resp = @generated.QueryResponse::from_json(output)
  guard resp is Some(r) else { fail("QueryResponse should parse") }
  inspect(r.package, content="example/sdkacceptance")
  inspect(r.mode, content="exact-id")
  inspect(r.matches.length(), content="1")
  inspect(r.matches[0].symbol, content="Greeter")
  inspect(r.matches[0].kind, content="type")
}

///|
test "query exact-id: api routes to exact-id mode and returns Greeter match" {
  setup_sdk_runtime_context()
  let req : @generated.QueryRequest = {
    package: "example/sdkacceptance",
    exact_id: Some("decl:go:example/sdkacceptance.Greeter"),
    exact_symbol: None,
    text: None,
    limit: None,
    cursor: None,
  }
  let resp = query(req)
  guard resp is Some(r) else { fail("query should return Some") }
  inspect(r.package, content="example/sdkacceptance")
  inspect(r.mode, content="exact-id")
  assert_true(r.matches.length() >= 1)
  // First match must be Greeter (listed first in ndjson, matched at rank 2 by id substring)
  inspect(r.matches[0].symbol, content="Greeter")
  inspect(r.matches[0].kind, content="type")
}

///|
/// --- Query: exact-symbol ---
test "query exact-symbol: fixture input parses into QueryRequest" {
  let input : Json = {
    "package": "example/sdkacceptance",
    "exact_symbol": "Greeter.Greet",
  }
  let req = @generated.QueryRequest::from_json(input)
  guard req is Some(r) else { fail("QueryRequest should parse") }
  inspect(r.package, content="example/sdkacceptance")
  assert_true(r.exact_id is None)
  inspect(r.exact_symbol, content="Some(\"Greeter.Greet\")")
}

///|
test "query exact-symbol: fixture output parses into QueryResponse" {
  let output : Json = {
    "package": "example/sdkacceptance",
    "mode": "exact-symbol",
    "matches": [
      {
        "id": "decl:go:example/sdkacceptance.Greeter.Greet",
        "symbol": "Greeter.Greet",
        "kind": "method",
        "signature": "func (g Greeter) Greet(name string) string",
        "summary": "Greet returns a formatted greeting string for the given name",
        "docs": null,
        "score": null,
        "location": { "uri": "main.go", "start_line": 27, "end_line": 35 },
      },
    ],
    "cursor": null,
  }
  let resp = @generated.QueryResponse::from_json(output)
  guard resp is Some(r) else { fail("QueryResponse should parse") }
  inspect(r.mode, content="exact-symbol")
  inspect(r.matches[0].kind, content="method")
}

///|
test "query exact-symbol: api routes to exact-symbol mode and returns Greeter.Greet" {
  setup_sdk_runtime_context()
  let req : @generated.QueryRequest = {
    package: "example/sdkacceptance",
    exact_id: None,
    exact_symbol: Some("Greeter.Greet"),
    text: None,
    limit: None,
    cursor: None,
  }
  let resp = query(req)
  guard resp is Some(r) else { fail("query should return Some") }
  inspect(r.mode, content="exact-symbol")
  assert_true(r.matches.length() >= 1)
  inspect(r.matches[0].symbol, content="Greeter.Greet")
  inspect(r.matches[0].kind, content="method")
}

///|
/// --- Query: fuzzy-text ---
test "query fuzzy-text: fixture input parses into QueryRequest" {
  let input : Json = {
    "package": "example/sdkacceptance",
    "text": "label",
    "limit": 5,
  }
  let req = @generated.QueryRequest::from_json(input)
  guard req is Some(r) else { fail("QueryRequest should parse") }
  inspect(r.package, content="example/sdkacceptance")
  inspect(r.text, content="Some(\"label\")")
  inspect(r.limit, content="Some(5)")
  assert_true(r.exact_id is None)
  assert_true(r.exact_symbol is None)
}

///|
test "query fuzzy-text: fixture output parses into QueryResponse" {
  let output : Json = {
    "package": "example/sdkacceptance",
    "mode": "fuzzy-text",
    "matches": [
      {
        "id": "decl:go:example/sdkacceptance.BuildLabels",
        "symbol": "BuildLabels",
        "kind": "function",
        "signature": "func BuildLabels(items []string) []string",
        "summary": "BuildLabels filters empty items and formats each as name:index",
        "docs": null,
        "score": 0.94,
        "location": { "uri": "main.go", "start_line": 20, "end_line": 25 },
      },
      {
        "id": "decl:go:example/sdkacceptance.Greeter.Greet",
        "symbol": "Greeter.Greet",
        "kind": "method",
        "signature": "func (g Greeter) Greet(name string) string",
        "summary": "Greet returns a formatted greeting string for the given name",
        "docs": null,
        "score": 0.41,
        "location": { "uri": "main.go", "start_line": 27, "end_line": 35 },
      },
    ],
    "cursor": null,
  }
  let resp = @generated.QueryResponse::from_json(output)
  guard resp is Some(r) else { fail("QueryResponse should parse") }
  inspect(r.mode, content="fuzzy-text")
  inspect(r.matches.length(), content="2")
  guard r.matches[0].score is Some(s) else { fail("score should be present") }
  assert_true(s > 0.9)
}

///|
test "query fuzzy-text: api routes to fuzzy-text mode and matches BuildLabels" {
  setup_sdk_runtime_context()
  let req : @generated.QueryRequest = {
    package: "example/sdkacceptance",
    exact_id: None,
    exact_symbol: None,
    // "BuildLabel" appears in the signature of BuildLabels (substring match at rank 3)
    text: Some("BuildLabel"),
    limit: Some(5),
    cursor: None,
  }
  let resp = query(req)
  guard resp is Some(r) else { fail("query should return Some") }
  inspect(r.mode, content="fuzzy-text")
  assert_true(r.matches.length() >= 1)
  inspect(r.matches[0].symbol, content="BuildLabels")
  inspect(r.matches[0].kind, content="function")
}
