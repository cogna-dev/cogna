///|
fn cleanup_lsp_e2e(path : String) -> Unit {
  @fs.remove_file("\{path}/codeiq.yaml") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/main.go") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/lib.rs") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/main.tf") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_dir("\{path}/dist") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/openapi/payment.yaml") catch {
    _ => ()
  }
  @fs.remove_dir("\{path}/openapi") catch {
    _ => ()
  }
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn write_openapi_repo(path : String) -> Unit {
  @fs.create_dir(path) catch {
    _ => abort("failed to create lsp e2e repo")
  }
  @fs.create_dir("\{path}/openapi") catch {
    _ => abort("failed to create lsp e2e openapi dir")
  }
  let spec = @fs.read_file_to_string(
    "examples/openapi-spec/full/repo/openapi/payment.yaml",
  ) catch {
    _ => abort("failed to read openapi fixture")
  }
  @fs.write_string_to_file("\{path}/openapi/payment.yaml", spec) catch {
    _ => abort("failed to write openapi fixture")
  }
}

///|
fn write_openapi_config(path : String) -> Unit {
  let content =
    #|schemaVersion: ciq-config/v1
    #|profile: openapi-spec
    #|purl: pkg:openapi/acme/payment-api@2026.03.01
    #|source:
    #|  repo: https://github.com/acme/payment-api
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - openapi/**/*.yaml
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  @fs.write_string_to_file("\{path}/codeiq.yaml", content) catch {
    _ => abort("failed to write openapi config")
  }
}

///|
fn read_text(path : String) -> String {
  @fs.read_file_to_string(path) catch {
    _ => abort("cannot read file: \{path}")
  }
}

///|
test "e2e build lsp extractor writes baseline metadata and symbols" {
  let path = "src/e2e/tmp_lsp_extractor_e2e"
  cleanup_lsp_e2e(path)
  write_openapi_repo(path)
  write_openapi_config(path)

  let out = @build_cmd.run({ repo: path })
  guard out is Ok(result) else {
    cleanup_lsp_e2e(path)
    fail("build should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ bundle skeleton at src/e2e/tmp_lsp_extractor_e2e/dist",
  )

  let metadata = @fs.read_file_to_string("\{path}/dist/metadata.json")
  assert_true(metadata.contains("\"role\": \"baseline\""))
  assert_true(metadata.contains("\"mode\": \"parser-only\""))
  assert_true(metadata.contains("\"version\": \"none | baseline-v2\""))

  let manifest = @fs.read_file_to_string("\{path}/dist/manifest.json")
  assert_true(manifest.contains("\"schemaVersion\": \"ciq-bundle/v1\""))
  assert_true(manifest.contains("\"declarationSchema\""))

  let checksums = @fs.read_file_to_string("\{path}/dist/checksums.txt")
  assert_true(checksums.contains("manifest.json  "))
  assert_true(checksums.contains("metadata.json  "))

  let declarations = read_text("\{path}/dist/declarations.ndjson")
  assert_true(declarations.contains("\"kind\":\"operation\""))
  assert_true(declarations.contains("\"kind\":\"path\""))
  assert_true(declarations.contains("\"name\":\"Payment.discriminator\""))
  assert_true(declarations.contains("\"baselineRole\":\"baseline\""))
  assert_true(declarations.contains("\"shape\":{\"kind\":"))
  assert_true(declarations.contains("\"relations\":[{\"kind\":\"declared_in\""))

  let symbols = read_text("\{path}/dist/symbols.ndjson")
  assert_true(symbols.contains("\"id\":\"sym:openapi-spec:"))

  let bundle = @fs.read_file_to_bytes("\{path}/dist/bundle.ciq.tgz")
  assert_true(bundle.length() > 0)

  cleanup_lsp_e2e(path)
}

///|
fn write_go_repo(path : String) -> Unit {
  @fs.create_dir(path) catch {
    _ => abort("failed to create go e2e repo")
  }
  let source = @fs.read_file_to_string("examples/go-module/full/repo/main.go") catch {
    _ => abort("failed to read go fixture")
  }
  @fs.write_string_to_file("\{path}/main.go", source) catch {
    _ => abort("failed to write go fixture")
  }
}

///|
fn write_go_config(path : String) -> Unit {
  let content =
    #|schemaVersion: ciq-config/v1
    #|profile: go-module
    #|purl: pkg:golang/example/demo@0.1.0
    #|source:
    #|  repo: https://github.com/example/demo
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - **/*.go
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  @fs.write_string_to_file("\{path}/codeiq.yaml", content) catch {
    _ => abort("failed to write go config")
  }
}

///|
test "e2e go extractor includes richer relations" {
  let path = "src/e2e/tmp_lsp_extractor_go"
  cleanup_lsp_e2e(path)
  write_go_repo(path)
  write_go_config(path)

  let out = @build_cmd.run({ repo: path })
  guard out is Ok(_) else {
    cleanup_lsp_e2e(path)
    fail("go build should succeed")
  }

  let metadata = @fs.read_file_to_string("\{path}/dist/metadata.json")
  assert_true(metadata.contains("\"server\": \"gopls\""))

  let declarations = read_text("\{path}/dist/declarations.ndjson")
  assert_true(declarations.contains("\"kind\":\"function\""))
  assert_true(declarations.contains("Package sample exposes provider coverage fixtures."))
  assert_true(declarations.contains("\"name\":\"Box\""))
  assert_true(declarations.contains("\"kind\":\"embedded_field\""))
  assert_true(declarations.contains("\"name\":\"MapValue\""))
  assert_true(declarations.contains("Deprecated: use Hello instead."))
  assert_true(declarations.contains("\"relations\":[{"))
  assert_true(declarations.contains("\"kind\":\"declared_in\""))
  assert_true(
    declarations.contains("\"kind\":\"has_parameter\"") ||
    declarations.contains("\"kind\":\"returns\"") ||
    declarations.contains("\"kind\":\"references_type\""),
  )

  cleanup_lsp_e2e(path)
}

///|
fn write_fixture_repo(path : String, fixture_root : String) -> Unit {
  @fs.create_dir(path) catch {
    _ => abort("failed to create fixture repo")
  }
  let source = @fs.read_file_to_string(fixture_root) catch {
    _ => abort("failed to read fixture source")
  }
  let target = match fixture_root {
    "examples/rust-crate/full/repo/lib.rs" => "lib.rs"
    "examples/terraform-module/full/repo/main.tf" => "main.tf"
    _ => abort("unexpected fixture root")
  }
  @fs.write_string_to_file("\{path}/\{target}", source) catch {
    _ => abort("failed to write fixture source")
  }
}

///|
fn write_profile_config(path : String, profile : String, include_glob : String, purl : String) -> Unit {
  let content =
    #|schemaVersion: ciq-config/v1
    #|profile: 
    #|purl: 
    #|source:
    #|  repo: https://github.com/example/demo
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - 
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  let normalized = content
    .replace(old="profile: ", new="profile: \{profile}")
    .replace(old="purl: ", new="purl: \{purl}")
    .replace(old="    - ", new="    - \{include_glob}")
  @fs.write_string_to_file("\{path}/codeiq.yaml", normalized) catch {
    _ => abort("failed to write profile config")
  }
}

///|
test "e2e rust extractor carries doc comments" {
  let path = "src/e2e/tmp_lsp_extractor_rust"
  cleanup_lsp_e2e(path)
  write_fixture_repo(path, "examples/rust-crate/full/repo/lib.rs")
  write_profile_config(path, "rust-crate", "**/*.rs", "pkg:cargo/example/demo@0.1.0")

  let out = @build_cmd.run({ repo: path })
  guard out is Ok(_) else {
    cleanup_lsp_e2e(path)
    fail("rust build should succeed")
  }

  let declarations = read_text("\{path}/dist/declarations.ndjson")
  assert_true(declarations.contains("Public module doc sample."))
  assert_true(declarations.contains("ApiItem doc comment.\\nDeprecated"))
  assert_true(declarations.contains("Constructor doc comment."))

  cleanup_lsp_e2e(path)
}

///|
test "e2e terraform extractor covers data source and object type" {
  let path = "src/e2e/tmp_lsp_extractor_terraform"
  cleanup_lsp_e2e(path)
  write_fixture_repo(path, "examples/terraform-module/full/repo/main.tf")
  write_profile_config(path, "terraform-module", "**/*.tf", "pkg:terraform/example/demo@0.1.0")

  let out = @build_cmd.run({ repo: path })
  guard out is Ok(_) else {
    cleanup_lsp_e2e(path)
    fail("terraform build should succeed")
  }

  let declarations = read_text("\{path}/dist/declarations.ndjson")
  assert_true(declarations.contains("\"kind\":\"data\""))
  assert_true(declarations.contains("\"name\":\"aws_caller_identity.current\""))
  assert_true(declarations.contains("type = object({ env = string, retries = number })"))

  cleanup_lsp_e2e(path)
}
