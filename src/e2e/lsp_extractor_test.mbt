///|
fn cleanup_lsp_e2e(path : String) -> Unit {
  @fs.remove_file("\{path}/codeiq.yaml") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/declarations.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/symbols.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/checksums.txt") catch {
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
  let spec =
    #|openapi: 3.1.0
    #|info:
    #|  title: Payment API
    #|  version: 1.0.0
    #|paths:
    #|  /payments:
    #|    get:
    #|      operationId: listPayments
    #|      responses:
    #|        "200":
    #|          description: ok
    #|components:
    #|  schemas:
    #|    Payment:
    #|      type: object
    #|
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

  let declarations = @fs.read_file_to_string(
    "\{path}/dist/declarations.ndjson.zst",
  )
  assert_true(declarations.contains("\"kind\":\"operation\""))
  assert_true(declarations.contains("\"baselineRole\":\"baseline\""))

  let symbols = @fs.read_file_to_string("\{path}/dist/symbols.ndjson.zst")
  assert_true(symbols.contains("\"id\":\"sym:openapi-spec:"))

  cleanup_lsp_e2e(path)
}
