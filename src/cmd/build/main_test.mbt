///|
fn ensure_file_removed(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn ensure_dir_removed(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn cleanup_tmp_repo(repo : String) -> Unit {
  ensure_file_removed("\{repo}/codeiq.yaml")
  ensure_file_removed("\{repo}/dist/manifest.json")
  ensure_file_removed("\{repo}/dist/declarations.ndjson.zst")
  ensure_file_removed("\{repo}/dist/symbols.ndjson.zst")
  ensure_file_removed("\{repo}/dist/metadata.json")
  ensure_file_removed("\{repo}/dist/checksums.txt")
  ensure_dir_removed("\{repo}/dist")
  ensure_dir_removed(repo)
}

///|
fn write_valid_config(path : String) -> Unit {
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
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to write test config")
  }
}

///|
test "build creates bundle skeleton files" {
  let repo = "src/cmd/build/tmp_build_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_valid_config("\{repo}/codeiq.yaml")
  let out = run({ repo, })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("build should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ bundle skeleton at src/cmd/build/tmp_build_repo/dist",
  )

  let manifest = @fs.read_file_to_string("\{repo}/dist/manifest.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("manifest should exist")
      ""
    }
  }
  assert_true(manifest.contains("\"schemaVersion\": \"ciq-bundle/v1\""))
  assert_true(
    manifest.contains("\"purl\": \"pkg:openapi/acme/payment-api@2026.03.01\""),
  )

  let metadata = @fs.read_file_to_string("\{repo}/dist/metadata.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("metadata should exist")
      ""
    }
  }
  assert_true(metadata.contains("\"schemaVersion\": \"ciq-metadata/v1\""))
  assert_true(metadata.contains("\"status\": \"completed\""))
  assert_true(metadata.contains("\"role\": \"baseline\""))
  assert_true(metadata.contains("\"mode\": \"parser-only\""))

  let checksums = @fs.read_file_to_string("\{repo}/dist/checksums.txt") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("checksums should exist")
      ""
    }
  }
  assert_true(checksums.contains("manifest.json  pending"))
  assert_true(checksums.contains("symbols.ndjson.zst  stable-"))

  let declarations = @fs.read_file_to_string(
    "\{repo}/dist/declarations.ndjson.zst",
  ) catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("declarations should exist")
      ""
    }
  }
  assert_true(declarations.contains("\"baselineRole\":\"baseline\""))

  let symbols = @fs.read_file_to_string("\{repo}/dist/symbols.ndjson.zst") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("symbols should exist")
      ""
    }
  }
  assert_true(symbols.contains("\"id\":\"sym:openapi-spec:"))

  cleanup_tmp_repo(repo)
}

///|
test "build returns config error when config file is missing" {
  let repo = "src/cmd/build/tmp_build_missing_config"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let out = run({ repo, })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("build should fail when config is missing")
  }

  let text = error.to_string()
  assert_true(text.contains("config error:"))
  assert_true(text.contains("codeiq.yaml"))

  cleanup_tmp_repo(repo)
}
