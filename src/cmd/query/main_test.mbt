///|
fn remove_file_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn cleanup_tmp_repo(repo : String) -> Unit {
  remove_file_if_exists("\{repo}/query.json")
  remove_file_if_exists("\{repo}/query.result.json")
  remove_file_if_exists("\{repo}/dist/declarations.ndjson")
  remove_file_if_exists("\{repo}/dist/symbols.ndjson")
  remove_file_if_exists("\{repo}/dist/software-components.ndjson")
  remove_file_if_exists("\{repo}/dist/manifest.json")
  remove_file_if_exists("\{repo}/dist/metadata.json")
  remove_file_if_exists("\{repo}/dist/checksums.txt")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
}

///|
fn tmp_query_repo(name : String) -> String {
  "/tmp/codeiq-query-\{name}"
}

///|
fn write_query(path : String) -> Unit {
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "payment::create", "kind": "operation" },
    "intent": "upgrade",
  }
  @fs.write_string_to_file(path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }
}

///|
test "query generates ciq result from query file" {
  let repo = tmp_query_repo("repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let query_path = "\{repo}/query.json"
  write_query(query_path)

  let out = run({ query_file: query_path })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ result at /tmp/codeiq-query-repo/query.result.json",
  )

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("\"schemaVersion\": \"ciq-result/v1\""))
  assert_true(
    result_json.contains(
      "\"purl\": \"pkg:openapi/acme/payment-api@2026.04.01\"",
    ),
  )
  assert_true(result_json.contains("\"matches\": []"))

  cleanup_tmp_repo(repo)
}

///|
test "query uses local declarations when repo is provided" {
  let repo = tmp_query_repo("repo-with-bundle")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "openapi/payment.yaml", "kind": "operation" },
    "intent": "upgrade",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }

  let declarations =
    #|{"id":"decl:openapi:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write declarations fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("operation createPayment"))
  assert_true(result_json.contains("decl:openapi:payment:create"))

  cleanup_tmp_repo(repo)
}

///|
test "query preserves shape and language_specific fields in matches" {
  let repo = tmp_query_repo("repo-rich-matches")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:golang/example/demo@0.1.0",
    "selector": { "path": "main.go", "kind": "method" },
    "intent": "lookup",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }

  let declarations =
    #|{"id":"decl:go-module:go-module::main.go::Greet","kind":"method","name":"Greet","canonical_name":"go-module::main.go::Greet","path":"main.go","signature":"func (g *Greeter) Greet(name string) Message {","shape":{"kind":"method","subkind":"method","form":"callable","signature":"func (g *Greeter) Greet(name string) Message {","owner":"Greeter","parameters":["string"],"returns":["Message"]},"visibility":"public","docs":"Greets a user.","baselineRole":"baseline","language":"go","source_refs":[{"uri":"main.go","startLine":58,"endLine":58}],"relations":[{"kind":"declared_in","target":"file:main.go"}],"language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter","pointerReceiver":true,"methodSetTypes":["*Greeter","*Box"]}},"location":{"uri":"main.go","startLine":58,"endLine":58}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write declarations fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("\"shape\""))
  assert_true(result_json.contains("\"owner\": \"Greeter\""))
  assert_true(result_json.contains("\"language_specific\""))
  assert_true(result_json.contains("\"receiver\": \"Greeter\""))
  assert_true(result_json.contains("\"methodSetTypes\""))
  assert_true(result_json.contains("\"*Greeter\""))
  assert_true(result_json.contains("\"path\": \"main.go\""))
  assert_true(result_json.contains("\"name\": \"Greet\""))
  assert_true(
    result_json.contains("\"canonical_name\": \"go-module::main.go::Greet\""),
  )
  assert_true(result_json.contains("\"language\": \"go\""))
  assert_true(result_json.contains("\"baselineRole\": \"baseline\""))
  assert_true(result_json.contains("\"visibility\": \"public\""))
  assert_true(result_json.contains("Greets a user."))
  assert_true(result_json.contains("\"source_refs\""))
  assert_true(result_json.contains("\"relations\""))
  assert_true(result_json.contains("\"declared_in\""))

  cleanup_tmp_repo(repo)
}

///|
test "query uses symbols when declaration kind does not match" {
  let repo = tmp_query_repo("repo-symbols")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "openapi/payment.yaml", "kind": "symbol" },
    "intent": "lookup",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }

  let declarations =
    #|{"id":"decl:openapi:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  let symbols =
    #|{"id":"sym:openapi:payment:create","kind":"symbol","path":"openapi/payment.yaml","signature":"symbol createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":10}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write declarations fixture")
  }
  @fs.write_string_to_file("\{repo}/dist/symbols.ndjson", symbols) catch {
    _ => abort("failed to write symbols fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("symbol createPayment"))
  assert_true(result_json.contains("sym:openapi:payment:create"))

  cleanup_tmp_repo(repo)
}

///|
test "query infers candidates across kinds when selector kind is omitted" {
  let repo = tmp_query_repo("repo-inferred-kind")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "openapi/payment.yaml" },
    "intent": "lookup",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }

  let declarations =
    #|{"id":"decl:openapi:payment:create","kind":"operation","path":"openapi/payment.yaml","canonical_name":"payment.api.create","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  let symbols =
    #|{"id":"sym:openapi:payment:create","kind":"symbol","path":"openapi/payment.yaml","signature":"symbol createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":10}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write declarations fixture")
  }
  @fs.write_string_to_file("\{repo}/dist/symbols.ndjson", symbols) catch {
    _ => abort("failed to write symbols fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("operation createPayment"))
  assert_true(result_json.contains("symbol createPayment"))
  assert_true(result_json.contains("decl:openapi:payment:create"))
  assert_true(result_json.contains("sym:openapi:payment:create"))

  cleanup_tmp_repo(repo)
}

///|
test "query uses software components when component kind is requested" {
  let repo = tmp_query_repo("repo-components")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "package.json", "kind": "component" },
    "intent": "dependency-audit",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write query fixture")
  }

  let components =
    #|{"id":"pkg:npm/react@18.2.0","kind":"component","path":"package.json","signature":"library react@18.2.0","location":{"uri":"package.json","startLine":1,"endLine":1}}
    #|
  @fs.write_string_to_file(
    "\{repo}/dist/software-components.ndjson",
    components,
  ) catch {
    _ => abort("failed to write components fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("library react@18.2.0"))
  assert_true(result_json.contains("pkg:npm/react@18.2.0"))

  cleanup_tmp_repo(repo)
}

///|
test "query fails when schemaVersion is invalid" {
  let repo = tmp_query_repo("bad-schema")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let query_path = "\{repo}/query.json"
  let bad_query : Json = {
    "schemaVersion": "ciq-query/v0",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "payment::create", "kind": "operation" },
  }
  @fs.write_string_to_file(query_path, bad_query.stringify(indent=2)) catch {
    _ => abort("failed to write bad query fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("query should fail for invalid schemaVersion")
  }

  let text = error.to_string()
  assert_true(text.contains("query failed:"))
  assert_true(text.contains("ciq-query/v1 schema"))

  cleanup_tmp_repo(repo)
}

///|
test "query preserves richer rust language_specific facts in matches" {
  let repo = tmp_query_repo("repo-rust-rich-matches")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:cargo/example/demo@0.1.0",
    "selector": { "path": "lib.rs", "kind": "function" },
    "intent": "lookup",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write rust query fixture")
  }

  let declarations =
    #|{"id":"decl:rust-crate:rust-crate::lib.rs::c_add","kind":"function","name":"c_add","canonical_name":"rust-crate::lib.rs::c_add","path":"lib.rs","signature":"pub extern \"C\" fn c_add(a: i32, b: i32) -> i32 {","shape":{"kind":"function","subkind":"function","form":"callable","signature":"pub extern \"C\" fn c_add(a: i32, b: i32) -> i32 {","parameters":["i32","i32"],"returns":["i32"],"type_params":[]},"visibility":"public","docs":"","baselineRole":"baseline","language":"rust","source_refs":[{"uri":"lib.rs","startLine":74,"endLine":74}],"relations":[{"kind":"declared_in","target":"file:lib.rs"},{"kind":"has_parameter","target":"type:rust-crate::i32"},{"kind":"returns","target":"type:rust-crate::i32"}],"location":{"uri":"lib.rs","startLine":74,"endLine":74},"language_specific":{"profile":"rust-crate","server":"rust-analyzer","rust":{"typeParams":[],"externAbi":"C"}}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write rust declarations fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("rust query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("rust query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("\"language_specific\""))
  assert_true(result_json.contains("\"rust\""))
  assert_true(
    result_json.contains("\"externAbi\": \"C\"") ||
    result_json.contains("\"externAbi\":\"C\""),
  )
  assert_true(
    result_json.contains("\"canonical_name\": \"rust-crate::lib.rs::c_add\""),
  )
  assert_true(result_json.contains("\"source_refs\""))
  assert_true(result_json.contains("\"relations\""))

  cleanup_tmp_repo(repo)
}

///|
test "query preserves terraform language_specific facts in matches" {
  let repo = tmp_query_repo("repo-terraform-rich-matches")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:terraform/example/demo@0.1.0",
    "selector": { "path": "main.tf", "kind": "resource" },
    "intent": "lookup",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write terraform query fixture")
  }

  let declarations =
    #|{"id":"decl:terraform-module:terraform-module::main.tf::aws_vpc.main","kind":"resource","name":"aws_vpc.main","canonical_name":"terraform-module::main.tf::aws_vpc.main","path":"main.tf","signature":"resource \"aws_vpc\" \"main\" {","shape":{"kind":"resource","subkind":"resource","form":"symbol","signature":"resource \"aws_vpc\" \"main\" {"},"visibility":"public","docs":"","baselineRole":"baseline","language":"terraform","source_refs":[{"uri":"main.tf","startLine":56,"endLine":56}],"relations":[{"kind":"declared_in","target":"file:main.tf"},{"kind":"uses_provider","target":"decl:terraform-module:terraform-module::main.tf::aws"}],"location":{"uri":"main.tf","startLine":56,"endLine":56},"language_specific":{"profile":"terraform-module","server":"hcl-parser","terraform":{"providerRef":"aws.east","dependsOn":["module.network_labels"],"preventDestroy":true,"createBeforeDestroy":true,"ignoreChanges":["tags"]},"providers":{"terraform":[{"name":"aws","source":"hashicorp/aws","version":">= 5.0.0","alias":"east"}]}}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write terraform declarations fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("terraform query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("terraform query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("\"language_specific\""))
  assert_true(result_json.contains("\"terraform\""))
  assert_true(
    result_json.contains("\"preventDestroy\": true") ||
    result_json.contains("\"preventDestroy\":true"),
  )
  assert_true(result_json.contains("\"ignoreChanges\""))
  assert_true(result_json.contains("aws.east"))
  assert_true(
    result_json.contains(
      "\"canonical_name\": \"terraform-module::main.tf::aws_vpc.main\"",
    ),
  )
  assert_true(result_json.contains("\"relations\""))
  assert_true(result_json.contains("\"uses_provider\""))

  cleanup_tmp_repo(repo)
}

///|
test "query preserves openapi language_specific facts in matches" {
  let repo = tmp_query_repo("repo-openapi-rich-matches")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let query_path = "\{repo}/query.json"
  let query : Json = {
    "schemaVersion": "ciq-query/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.04.01",
    "selector": { "path": "openapi/payment.yaml", "kind": "operation" },
    "intent": "lookup",
    "repo": repo,
  }
  @fs.write_string_to_file(query_path, query.stringify(indent=2)) catch {
    _ => abort("failed to write openapi query fixture")
  }

  let declarations =
    #|{"id":"decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment","kind":"operation","name":"createPayment","canonical_name":"openapi-spec::openapi::payment.yaml::createPayment","path":"openapi/payment.yaml","signature":"operation createPayment","shape":{"kind":"operation","subkind":"operation","form":"symbol","signature":"operation createPayment"},"visibility":"public","docs":"","baselineRole":"baseline","language":"openapi","source_refs":[{"uri":"openapi/payment.yaml","startLine":26,"endLine":26}],"relations":[{"kind":"declared_in","target":"file:openapi/payment.yaml"}],"location":{"uri":"openapi/payment.yaml","startLine":26,"endLine":26},"language_specific":{"profile":"openapi-spec","server":"none","openapi":{"httpMethod":"POST","operationId":"createPayment","required":true,"mediaTypes":["application/json"],"statusCodes":["201"],"callbackExpression":"{$request.body#/callbackUrl}"}}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => abort("failed to write openapi declarations fixture")
  }

  let out = run({ query_file: query_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("openapi query should succeed")
  }

  let result_json = @fs.read_file_to_string("\{repo}/query.result.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("openapi query result should exist")
      ""
    }
  }
  assert_true(result_json.contains("\"language_specific\""))
  assert_true(result_json.contains("\"openapi\""))
  assert_true(result_json.contains("\"201\""))
  assert_true(result_json.contains("application/json"))
  assert_true(result_json.contains("callbackUrl"))
  assert_true(
    result_json.contains(
      "\"canonical_name\": \"openapi-spec::openapi::payment.yaml::createPayment\"",
    ),
  )
  assert_true(result_json.contains("\"baselineRole\": \"baseline\""))
  assert_true(result_json.contains("\"source_refs\""))

  cleanup_tmp_repo(repo)
}
