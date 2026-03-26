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
  remove_file_if_exists("\{repo}/dist/base/manifest.json")
  remove_file_if_exists("\{repo}/dist/base/declarations.ndjson")
  remove_file_if_exists("\{repo}/dist/base/symbols.ndjson")
  remove_file_if_exists("\{repo}/dist/base/software-components.ndjson")
  remove_file_if_exists("\{repo}/dist/target/manifest.json")
  remove_file_if_exists("\{repo}/dist/target/declarations.ndjson")
  remove_file_if_exists("\{repo}/dist/target/symbols.ndjson")
  remove_file_if_exists("\{repo}/dist/target/software-components.ndjson")
  remove_file_if_exists("\{repo}/dist/diff.json")
  remove_dir_if_exists("\{repo}/dist/base")
  remove_dir_if_exists("\{repo}/dist/target")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
}

///|
fn write_manifest(path : String, purl : String, profile : String) -> Unit {
  let sha = @sha256.sha256_hexdigest(@utf8.encode("fixture"))
  let content : Json = {
    "schemaVersion": "ciq-bundle/v1",
    "purl": purl,
    "profile": profile,
    "declarationSchema": {
      "version": "ciq-declarations/v1",
      "format": "ndjson",
      "model": "signature + shape + language_specific tagged union",
    },
    "source": {
      "repo": "https://github.com/acme/payment-api",
      "ref": "main",
      "commit": "1234567890abcdef1234567890abcdef12345678",
    },
    "artifacts": [
      { "path": "declarations.ndjson", "sha256": sha, "compression": "none" },
    ],
  }
  @fs.write_string_to_file(path, content.stringify(indent=2)) catch {
    _ => abort("failed to write manifest fixture")
  }
}

///|
fn write_records(path : String, lines : String) -> Unit {
  @fs.write_string_to_file(path, lines) catch {
    _ => abort("failed to write records fixture")
  }
}

///|
test "diff generates skeleton diff output" {
  let repo = "src/cmd/diff/tmp_diff_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:openapi/acme/payment-api@2026.03.01",
    "openapi-spec",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )

  let base_declarations =
    #|{"id":"decl:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|{"id":"decl:payment:remove","kind":"operation","path":"openapi/payment.yaml","signature":"operation removePayment","location":{"uri":"openapi/payment.yaml","startLine":30,"endLine":40}}
    #|
  let base_symbols =
    #|{"id":"sym:payment:create","kind":"symbol","path":"openapi/payment.yaml","signature":"symbol createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":10}}
    #|
  let target_declarations =
    #|{"id":"decl:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPaymentV2","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|{"id":"decl:payment:add","kind":"operation","path":"openapi/payment.yaml","signature":"operation addPayment","location":{"uri":"openapi/payment.yaml","startLine":50,"endLine":60}}
    #|
  let target_symbols =
    #|{"id":"sym:payment:create","kind":"symbol","path":"openapi/payment.yaml","signature":"symbol createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":10}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", base_symbols)
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", target_symbols)

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ declaration diff at src/cmd/diff/tmp_diff_repo/dist/diff.json",
  )

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"schemaVersion\": \"ciq-diff/v1\""))
  assert_true(
    diff_text.contains(
      "\"basePurl\": \"pkg:openapi/acme/payment-api@2026.03.01\"",
    ),
  )
  assert_true(
    diff_text.contains(
      "\"targetPurl\": \"pkg:openapi/acme/payment-api@2026.04.01\"",
    ),
  )
  assert_true(diff_text.contains("\"kind\": \"added\""))
  assert_true(diff_text.contains("\"kind\": \"removed\""))
  assert_true(diff_text.contains("\"kind\": \"changed\""))
  assert_true(diff_text.contains("\"decl:payment:add\""))
  assert_true(diff_text.contains("\"decl:payment:remove\""))
  assert_true(diff_text.contains("\"decl:payment:create\""))
  assert_true(diff_text.contains("\"afterRecord\""))
  assert_true(diff_text.contains("\"beforeRecord\""))
  // R13-1: semantic fields present on all change kinds
  assert_true(diff_text.contains("\"semanticCategory\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff fails when base manifest is missing" {
  let repo = "src/cmd/diff/tmp_diff_missing_base"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/target")
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("diff should fail when base manifest is missing")
  }

  let text = error.to_string()
  assert_true(text.contains("diff failed:"))
  assert_true(text.contains("base/manifest.json"))

  cleanup_tmp_repo(repo)
}

///|
test "diff includes since and test changes fields when requested" {
  let repo = "src/cmd/diff/tmp_diff_since_test_changes"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:openapi/acme/payment-api@2026.03.01",
    "openapi-spec",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )

  let records =
    #|{"id":"decl:payment:create","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","location":{"uri":"openapi/payment.yaml","startLine":10,"endLine":20}}
    #|
  write_records("\{repo}/dist/base/declarations.ndjson", records)
  write_records("\{repo}/dist/base/symbols.ndjson", records)
  write_records("\{repo}/dist/target/declarations.ndjson", records)
  write_records("\{repo}/dist/target/symbols.ndjson", records)

  let out = run({
    repo,
    since: Some("2026-03-01T00:00:00Z"),
    include_test_changes: true,
  })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed with since and test-changes")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"since\": \"2026-03-01T00:00:00Z\""))
  assert_true(diff_text.contains("\"includeTestChanges\": true"))
  assert_true(diff_text.contains("\"testSummary\""))
  assert_true(diff_text.contains("\"testChanges\": []"))

  cleanup_tmp_repo(repo)
}

///|
test "diff computes go test changes when requested" {
  let repo = "src/cmd/diff/tmp_diff_go_test_changes"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:golang/example/demo@0.1.0",
    "go-module",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:golang/example/demo@0.2.0",
    "go-module",
  )

  let base_declarations =
    #|{"id":"decl:go-module:demo::math_test.go::TestAdd","kind":"function","name":"TestAdd","path":"math_test.go","signature":"func TestAdd(t *testing.T)","language":"go","location":{"uri":"math_test.go","startLine":12,"endLine":12}}
    #|{"id":"decl:go-module:demo::math_test.go::TestRemoved","kind":"function","name":"TestRemoved","path":"math_test.go","signature":"func TestRemoved(t *testing.T)","language":"go","location":{"uri":"math_test.go","startLine":28,"endLine":28}}
    #|
  let target_declarations =
    #|{"id":"decl:go-module:demo::math_test.go::TestAdd","kind":"function","name":"TestAdd","path":"math_test.go","signature":"func TestAdd(t *testing.T) // v2","language":"go","location":{"uri":"math_test.go","startLine":14,"endLine":14}}
    #|{"id":"decl:go-module:demo::math_test.go::TestAdded","kind":"function","name":"TestAdded","path":"math_test.go","signature":"func TestAdded(t *testing.T)","language":"go","location":{"uri":"math_test.go","startLine":40,"endLine":40}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  let out = run({
    repo,
    since: Some("2026-03-01T00:00:00Z"),
    include_test_changes: true,
  })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should compute go test changes")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"includeTestChanges\": true"))
  assert_true(diff_text.contains("\"testSummary\": {"))
  assert_true(diff_text.contains("\"added\": 1"))
  assert_true(diff_text.contains("\"modified\": 1"))
  assert_true(diff_text.contains("\"removed\": 1"))
  assert_true(
    diff_text.contains(
      "\"id\": \"test:go-module:demo::math_test.go::TestAdded\"",
    ),
  )
  assert_true(
    diff_text.contains(
      "\"id\": \"test:go-module:demo::math_test.go::TestRemoved\"",
    ),
  )
  assert_true(diff_text.contains("\"kind\": \"modified\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff includes software component changes" {
  let repo = "src/cmd/diff/tmp_diff_components"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:openapi/acme/payment-api@2026.03.01",
    "openapi-spec",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )
  write_records("\{repo}/dist/base/declarations.ndjson", "")
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", "")
  write_records("\{repo}/dist/target/symbols.ndjson", "")
  let base_component =
    #|{"id":"pkg:npm/react@18.2.0","kind":"component","path":"package.json","signature":"library react@18.2.0","name":"react","componentType":"library","scope":"dependency","version":"18.2.0","purl":"pkg:npm/react@18.2.0","location":{"uri":"package.json","startLine":1,"endLine":1}}
    #|
  let target_component =
    #|{"id":"pkg:npm/react@19.0.0","kind":"component","path":"package.json","signature":"library react@19.0.0","name":"react","componentType":"library","scope":"dependency","version":"19.0.0","purl":"pkg:npm/react@19.0.0","location":{"uri":"package.json","startLine":1,"endLine":1}}
    #|
  write_records(
    "\{repo}/dist/base/software-components.ndjson",
    base_component,
  )
  write_records(
    "\{repo}/dist/target/software-components.ndjson",
    target_component,
  )

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }
  assert_true(diff_text.contains("pkg:npm/react@18.2.0"))
  assert_true(diff_text.contains("pkg:npm/react@19.0.0"))
  assert_true(diff_text.contains("\"kind\": \"changed\"") || diff_text.contains("\"kind\":\"changed\""))
  assert_true(diff_text.contains("\"componentDiff\""))
  assert_true(diff_text.contains("\"upgradeKind\": \"version-upgrade\"") || diff_text.contains("\"upgradeKind\":\"version-upgrade\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff marks declarations changed when richer shape metadata changes" {
  let repo = "src/cmd/diff/tmp_diff_shape_change"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:golang/example/demo@0.1.0",
    "go-module",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:golang/example/demo@0.2.0",
    "go-module",
  )

  let base_declarations =
    #|{"id":"decl:go-module:go-module::main.go::Greet","kind":"method","path":"main.go","signature":"func (g *Greeter) Greet(name string) Message {","shape":{"kind":"method","subkind":"method","form":"callable","signature":"func (g *Greeter) Greet(name string) Message {","owner":"Greeter","parameters":["string"]},"language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter","pointerReceiver":true,"methodSetTypes":["*Greeter","*Box"]}},"location":{"uri":"main.go","startLine":58,"endLine":58}}
    #|
  let target_declarations =
    #|{"id":"decl:go-module:go-module::main.go::Greet","kind":"method","path":"main.go","signature":"func (g *Greeter) Greet(name string) Message {","shape":{"kind":"method","subkind":"method","form":"callable","signature":"func (g *Greeter) Greet(name string) Message {","owner":"Greeter","parameters":["string"],"returns":["Message"]},"language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter","pointerReceiver":true,"methodSetTypes":["*Greeter","*Box"]}},"location":{"uri":"main.go","startLine":58,"endLine":58}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }
  assert_true(diff_text.contains("\"kind\": \"changed\""))
  assert_true(diff_text.contains("\"decl:go-module:go-module::main.go::Greet\""))
  assert_true(diff_text.contains("\"beforeRecord\""))
  assert_true(diff_text.contains("\"afterRecord\""))
  assert_true(diff_text.contains("\"owner\": \"Greeter\"") || diff_text.contains("\"owner\":\"Greeter\""))
  assert_true(diff_text.contains("\"returns\""))
  assert_true(diff_text.contains("\"Message\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff marks rust declarations changed when richer language metadata changes" {
  let repo = "src/cmd/diff/tmp_diff_rust_shape_change"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:cargo/example/demo@0.1.0",
    "rust-crate",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:cargo/example/demo@0.2.0",
    "rust-crate",
  )

  let base_declarations =
    #|{"id":"decl:rust-crate:rust-crate::lib.rs::dangerous","kind":"function","path":"lib.rs","signature":"pub unsafe fn dangerous() -> i32 {","shape":{"kind":"function","subkind":"function","form":"callable","signature":"pub unsafe fn dangerous() -> i32 {","returns":["i32"]},"language_specific":{"profile":"rust-crate","server":"rust-analyzer","rust":{}},"location":{"uri":"lib.rs","startLine":70,"endLine":70}}
    #|
  let target_declarations =
    #|{"id":"decl:rust-crate:rust-crate::lib.rs::dangerous","kind":"function","path":"lib.rs","signature":"pub unsafe fn dangerous() -> i32 {","shape":{"kind":"function","subkind":"function","form":"callable","signature":"pub unsafe fn dangerous() -> i32 {","returns":["i32"]},"language_specific":{"profile":"rust-crate","server":"rust-analyzer","rust":{"unsafe":true}},"location":{"uri":"lib.rs","startLine":70,"endLine":70}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("rust diff should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("rust diff output should exist")
      ""
    }
  }
  assert_true(diff_text.contains("\"kind\": \"changed\"") || diff_text.contains("\"kind\":\"changed\""))
  assert_true(diff_text.contains("\"decl:rust-crate:rust-crate::lib.rs::dangerous\""))
  assert_true(diff_text.contains("\"beforeRecord\""))
  assert_true(diff_text.contains("\"afterRecord\""))
  assert_true(diff_text.contains("\"unsafe\":true") || diff_text.contains("\"unsafe\": true"))
  // R13-1: semantic level should be "breaking" for rust-became-unsafe
  assert_true(diff_text.contains("\"level\": \"breaking\"") || diff_text.contains("\"level\":\"breaking\""))
  assert_true(diff_text.contains("\"semanticCategory\": \"rust-became-unsafe\"") || diff_text.contains("\"semanticCategory\":\"rust-became-unsafe\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff marks terraform declarations changed when richer language metadata changes" {
  let repo = "src/cmd/diff/tmp_diff_terraform_shape_change"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:terraform/example/demo@0.1.0",
    "terraform-module",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:terraform/example/demo@0.2.0",
    "terraform-module",
  )

  let base_declarations =
    #|{"id":"decl:terraform-module:terraform-module::main.tf::aws_vpc.main","kind":"resource","path":"main.tf","signature":"resource \"aws_vpc\" \"main\" {","shape":{"kind":"resource","subkind":"resource","form":"symbol","signature":"resource \"aws_vpc\" \"main\" {"},"language_specific":{"profile":"terraform-module","server":"hcl-parser","terraform":{"providerRef":"aws.east","dependsOn":["module.network_labels"]}},"location":{"uri":"main.tf","startLine":56,"endLine":56}}
    #|
  let target_declarations =
    #|{"id":"decl:terraform-module:terraform-module::main.tf::aws_vpc.main","kind":"resource","path":"main.tf","signature":"resource \"aws_vpc\" \"main\" {","shape":{"kind":"resource","subkind":"resource","form":"symbol","signature":"resource \"aws_vpc\" \"main\" {"},"language_specific":{"profile":"terraform-module","server":"hcl-parser","terraform":{"providerRef":"aws.east","dependsOn":["module.network_labels"],"preventDestroy":true,"createBeforeDestroy":true,"ignoreChanges":["tags"]}},"location":{"uri":"main.tf","startLine":56,"endLine":56}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("terraform diff should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("terraform diff output should exist")
      ""
    }
  }
  assert_true(diff_text.contains("\"kind\": \"changed\"") || diff_text.contains("\"kind\":\"changed\""))
  assert_true(diff_text.contains("\"decl:terraform-module:terraform-module::main.tf::aws_vpc.main\""))
  assert_true(diff_text.contains("\"beforeRecord\""))
  assert_true(diff_text.contains("\"afterRecord\""))
  assert_true(diff_text.contains("\"preventDestroy\":true") || diff_text.contains("\"preventDestroy\": true"))
  // R13-1: semantic level should be "warning" for terraform-prevent-destroy-added
  assert_true(diff_text.contains("\"semanticCategory\": \"terraform-prevent-destroy-added\"") || diff_text.contains("\"semanticCategory\":\"terraform-prevent-destroy-added\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff marks openapi declarations changed when richer language metadata changes" {
  let repo = "src/cmd/diff/tmp_diff_openapi_shape_change"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:openapi/acme/payment-api@2026.03.01",
    "openapi-spec",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )

  let base_declarations =
    #|{"id":"decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","shape":{"kind":"operation","subkind":"operation","form":"symbol","signature":"operation createPayment"},"language_specific":{"profile":"openapi-spec","server":"none","openapi":{"httpMethod":"POST","operationId":"createPayment"}},"location":{"uri":"openapi/payment.yaml","startLine":26,"endLine":26}}
    #|
  let target_declarations =
    #|{"id":"decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment","kind":"operation","path":"openapi/payment.yaml","signature":"operation createPayment","shape":{"kind":"operation","subkind":"operation","form":"symbol","signature":"operation createPayment"},"language_specific":{"profile":"openapi-spec","server":"none","openapi":{"httpMethod":"POST","operationId":"createPayment","required":true,"mediaTypes":["application/json"],"statusCodes":["201"],"callbackExpression":"{$request.body#/callbackUrl}"}},"location":{"uri":"openapi/payment.yaml","startLine":26,"endLine":26}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("openapi diff should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("openapi diff output should exist")
      ""
    }
  }
  assert_true(diff_text.contains("\"kind\": \"changed\"") || diff_text.contains("\"kind\":\"changed\""))
  assert_true(diff_text.contains("\"decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment\""))
  assert_true(diff_text.contains("\"beforeRecord\""))
  assert_true(diff_text.contains("\"afterRecord\""))
  assert_true(diff_text.contains("\"statusCodes\""))
  assert_true(diff_text.contains("\"201\""))
  // R13-1: OpenAPI became-required fires first (required added); statusCodes is in the after record but doesn't determine level
  // The openapi diff has both "required":true added (breaking) and "statusCodes" added (warning)
  // required takes priority → breaking + openapi-became-required
  assert_true(diff_text.contains("\"semanticCategory\": \"openapi-became-required\"") || diff_text.contains("\"semanticCategory\":\"openapi-became-required\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff includes semanticDiff in changed entries" {
  let repo = "src/cmd/diff/tmp_diff_semantic_diff"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:golang/example/demo@0.1.0",
    "go-module",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:golang/example/demo@0.2.0",
    "go-module",
  )

  // shape.returns changed: base has no returns, target adds ["Message"]
  let base_declarations =
    #|{"id":"decl:go-module:go-module::main.go::Greet","kind":"method","path":"main.go","signature":"func (g *Greeter) Greet(name string) Message {","shape":{"kind":"method","subkind":"method","form":"callable","signature":"func (g *Greeter) Greet(name string) Message {","owner":"Greeter","parameters":["string"]},"language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter"}},"location":{"uri":"main.go","startLine":58,"endLine":58}}
    #|
  let target_declarations =
    #|{"id":"decl:go-module:go-module::main.go::Greet","kind":"method","path":"main.go","signature":"func (g *Greeter) Greet(name string) Message {","shape":{"kind":"method","subkind":"method","form":"callable","signature":"func (g *Greeter) Greet(name string) Message {","owner":"Greeter","parameters":["string"],"returns":["Message"]},"language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter","pointerReceiver":true}},"location":{"uri":"main.go","startLine":58,"endLine":58}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"kind\": \"changed\""))
  assert_true(diff_text.contains("\"semanticDiff\""))
  assert_true(diff_text.contains("\"changedFields\""))
  // both shape and language_specific changed
  assert_true(diff_text.contains("\"shape\""))
  assert_true(diff_text.contains("\"language_specific\""))
  assert_true(diff_text.contains("\"shapeDiff\""))
  assert_true(diff_text.contains("\"languageSpecificDiff\""))

  cleanup_tmp_repo(repo)
}

///|
test "diff includes componentDiff in changed component entries" {
  let repo = "src/cmd/diff/tmp_diff_component_diff"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:openapi/acme/payment-api@2026.03.01",
    "openapi-spec",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:openapi/acme/payment-api@2026.04.01",
    "openapi-spec",
  )
  write_records("\{repo}/dist/base/declarations.ndjson", "")
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", "")
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  // Same purl id (purl-keyed), but version field and signature differ
  let base_component =
    #|{"id":"pkg:npm/react","kind":"component","path":"package.json","signature":"library react@18.2.0","version":"18.2.0","purl":"pkg:npm/react@18.2.0","componentType":"library","scope":"required","location":{"uri":"package.json","startLine":1,"endLine":1}}
    #|
  let target_component =
    #|{"id":"pkg:npm/react","kind":"component","path":"package.json","signature":"library react@19.0.0","version":"19.0.0","purl":"pkg:npm/react@19.0.0","componentType":"library","scope":"required","location":{"uri":"package.json","startLine":1,"endLine":1}}
    #|
  write_records(
    "\{repo}/dist/base/software-components.ndjson",
    base_component,
  )
  write_records(
    "\{repo}/dist/target/software-components.ndjson",
    target_component,
  )

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"kind\": \"changed\""))
  assert_true(diff_text.contains("pkg:npm/react"))
  assert_true(diff_text.contains("\"semanticDiff\""))
  assert_true(diff_text.contains("\"componentDiff\""))
  assert_true(diff_text.contains("\"upgradeKind\""))
  assert_true(
    diff_text.contains("\"beforeVersion\": \"18.2.0\"") ||
    diff_text.contains("\"beforeVersion\":\"18.2.0\""),
  )
  assert_true(
    diff_text.contains("\"afterVersion\": \"19.0.0\"") ||
    diff_text.contains("\"afterVersion\":\"19.0.0\""),
  )

  cleanup_tmp_repo(repo)
}

///|
test "diff includes richer records for added removed and deprecated declarations" {
  let repo = "src/cmd/diff/tmp_diff_handoff_records"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  @fs.create_dir("\{repo}/dist/base")
  @fs.create_dir("\{repo}/dist/target")

  write_manifest(
    "\{repo}/dist/base/manifest.json",
    "pkg:golang/example/demo@0.1.0",
    "go-module",
  )
  write_manifest(
    "\{repo}/dist/target/manifest.json",
    "pkg:golang/example/demo@0.2.0",
    "go-module",
  )

  let base_declarations =
    #|{"id":"decl:go-module:go-module::main.go::OldGreet","kind":"method","name":"OldGreet","path":"main.go","signature":"func (g *Greeter) OldGreet(name string) Message {","location":{"uri":"main.go","startLine":10,"endLine":10}}
    #|{"id":"decl:go-module:go-module::main.go::RemovedGreet","kind":"method","name":"RemovedGreet","path":"main.go","signature":"func (g *Greeter) RemovedGreet(name string) Message {","location":{"uri":"main.go","startLine":20,"endLine":20}}
    #|
  let target_declarations =
    #|{"id":"decl:go-module:go-module::main.go::OldGreet","kind":"method","name":"OldGreet","path":"main.go","signature":"func (g *Greeter) OldGreet(name string) Message {","deprecated":true,"language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter"}},"location":{"uri":"main.go","startLine":10,"endLine":10}}
    #|{"id":"decl:go-module:go-module::main.go::AddedGreet","kind":"method","name":"AddedGreet","path":"main.go","signature":"func (g *Greeter) AddedGreet(name string) Message {","language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter"}},"location":{"uri":"main.go","startLine":30,"endLine":30}}
    #|

  write_records("\{repo}/dist/base/declarations.ndjson", base_declarations)
  write_records("\{repo}/dist/base/symbols.ndjson", "")
  write_records("\{repo}/dist/target/declarations.ndjson", target_declarations)
  write_records("\{repo}/dist/target/symbols.ndjson", "")

  let out = run({ repo, since: None, include_test_changes: false })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("diff handoff records should succeed")
  }

  let diff_text = @fs.read_file_to_string("\{repo}/dist/diff.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("diff output should exist")
      ""
    }
  }

  assert_true(diff_text.contains("\"kind\": \"added\""))
  assert_true(diff_text.contains("\"kind\": \"removed\""))
  assert_true(diff_text.contains("\"kind\": \"deprecated\""))
  assert_true(diff_text.contains("decl:go-module:go-module::main.go::AddedGreet"))
  assert_true(diff_text.contains("decl:go-module:go-module::main.go::RemovedGreet"))
  assert_true(diff_text.contains("decl:go-module:go-module::main.go::OldGreet"))
  assert_true(diff_text.contains("\"afterRecord\""))
  assert_true(diff_text.contains("\"beforeRecord\""))

  cleanup_tmp_repo(repo)
}
