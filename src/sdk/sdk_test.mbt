// SDK fixture tests: validate all 5 user-facing APIs against e2e/sdk-fixtures/*.json.
// Fixtures contain the canonical input/output shapes defined in spec/api.md.
// These tests verify:
//   (a) fixture input JSON parses into the correct request struct
//   (b) fixture output JSON round-trips through the response struct
//   (c) SDK api.mbt dispatches correctly and returns structurally valid responses
// NOTE: @core.* functions are currently TODO stubs, so response *values* are not
//       yet verified against fixture outputs — only structure and mode routing.

///|
/// --- Build ---
test "build: fixture input parses into BuildRequest" {
  let input : Json = {}
  let req = BuildRequest::from_json(input)
  assert_true(req is Some(_))
}

///|
test "build: fixture output parses into BuildResponse" {
  let output : Json = { "success": true }
  let resp = BuildResponse::from_json(output)
  guard resp is Some(r) else { fail("BuildResponse should parse") }
  assert_true(r.success)
}

///|
test "build: api returns success response" {
  let req = BuildRequest::{  }
  let resp = build(req)
  assert_true(resp.success)
}

///|
/// --- Diff ---
test "diff: fixture input parses into DiffRequest" {
  let input : Json = {
    "base": "v0.0.1",
    "target": "working-tree",
    "include_test_changes": false,
  }
  let req = DiffRequest::from_json(input)
  guard req is Some(r) else { fail("DiffRequest should parse") }
  inspect(r.base, content="Some(\"v0.0.1\")")
  inspect(r.target, content="Some(\"working-tree\")")
  inspect(r.include_test_changes, content="Some(false)")
}

///|
test "diff: fixture output parses into DiffResponse" {
  let output : Json = {
    "summary": { "added": 4, "removed": 0, "changed": 0, "deprecated": 0 },
    "changes": [
      {
        "kind": "added",
        "id": "decl:go:example/sdkacceptance.Greeter",
        "symbol": "Greeter",
        "level": "non-breaking",
        "message": "new exported type added",
      },
    ],
    "test_changes": [],
  }
  let resp = DiffResponse::from_json(output)
  guard resp is Some(r) else { fail("DiffResponse should parse") }
  guard r.summary is Some(s) else { fail("summary should be present") }
  inspect(s.added, content="4")
  inspect(r.changes.length(), content="1")
  inspect(r.changes[0].kind, content="added")
}

///|
test "diff: api returns structurally valid DiffResponse" {
  let req : DiffRequest = {
    base: Some("v0.0.1"),
    target: Some("working-tree"),
    include_test_changes: Some(false),
  }
  let resp = diff(req)
  guard resp is Some(r) else { fail("diff should return Some") }
  // @core.diff is a TODO stub; verify structure only
  guard r.summary is Some(s) else {
    fail("summary should be present in stub response")
  }
  assert_true(s.added >= 0)
  assert_true(s.removed >= 0)
  assert_true(s.changed >= 0)
  assert_true(s.deprecated >= 0)
}

///|
/// --- FetchPackages ---
test "fetch_packages: fixture input parses into FetchPackagesRequest" {
  let input : Json = {}
  let req = FetchPackagesRequest::from_json(input)
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
  let resp = FetchPackagesResponse::from_json(output)
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
  let req = FetchPackagesRequest::{  }
  let resp = fetch_packages(req)
  // @core.fetch_packages is a TODO stub; verify structure only
  guard resp is Some(r) else { fail("fetch_packages should return Some") }
  guard r.root is Some(root) else {
    fail("root should be present in stub response")
  }
  assert_true(root.name != "")
  assert_true(root.relation != "")
}

///|
/// --- QueryOutlines ---
test "query_outlines: fixture input parses into QueryOutlinesRequest" {
  let input : Json = { "package": "example/sdkacceptance" }
  let req = QueryOutlinesRequest::from_json(input)
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
  let resp = QueryOutlinesResponse::from_json(output)
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
  let req : QueryOutlinesRequest = { package: "example/sdkacceptance" }
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
  let req = QueryRequest::from_json(input)
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
  let resp = QueryResponse::from_json(output)
  guard resp is Some(r) else { fail("QueryResponse should parse") }
  inspect(r.package, content="example/sdkacceptance")
  inspect(r.mode, content="exact-id")
  inspect(r.matches.length(), content="1")
  inspect(r.matches[0].symbol, content="Greeter")
  inspect(r.matches[0].kind, content="type")
}

///|
test "query exact-id: api routes to exact-id mode and returns Greeter match" {
  let req : QueryRequest = {
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
  let req = QueryRequest::from_json(input)
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
  let resp = QueryResponse::from_json(output)
  guard resp is Some(r) else { fail("QueryResponse should parse") }
  inspect(r.mode, content="exact-symbol")
  inspect(r.matches[0].kind, content="method")
}

///|
test "query exact-symbol: api routes to exact-symbol mode and returns Greeter.Greet" {
  let req : QueryRequest = {
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
  let req = QueryRequest::from_json(input)
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
  let resp = QueryResponse::from_json(output)
  guard resp is Some(r) else { fail("QueryResponse should parse") }
  inspect(r.mode, content="fuzzy-text")
  inspect(r.matches.length(), content="2")
  guard r.matches[0].score is Some(s) else { fail("score should be present") }
  assert_true(s > 0.9)
}

///|
test "query fuzzy-text: api routes to fuzzy-text mode and matches BuildLabels" {
  let req : QueryRequest = {
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
