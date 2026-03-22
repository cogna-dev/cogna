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
  ensure_file_removed("\{repo}/policy.rego")
  ensure_file_removed("\{repo}/dist/manifest.json")
  ensure_file_removed("\{repo}/dist/declarations.ndjson.zst")
  ensure_file_removed("\{repo}/dist/symbols.ndjson.zst")
  ensure_file_removed("\{repo}/dist/metadata.json")
  ensure_file_removed("\{repo}/dist/checksums.txt")
  ensure_file_removed("\{repo}/dist/opa-bundle.tar.gz")
  ensure_file_removed("\{repo}/dist/policy.rules.json")
  ensure_file_removed("\{repo}/dist/bundle.ciq.tgz")
  ensure_dir_removed("\{repo}/dist")
  ensure_dir_removed(repo)
}

///|
fn has_64_hex(value : String) -> Bool {
  if value.length() != 64 {
    return false
  }
  for c in value {
    if (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') {
      continue
    }
    return false
  }
  true
}

///|
fn checksum_for(checksums : String, file_name : String) -> String {
  let lines = checksums.split("\n").to_array()
  for i in 0..<lines.length() {
    let line = lines[i]
    if line.has_prefix(file_name + "  ") {
      let sha = line[file_name.length() + 2:].to_string().trim().to_string()
      return sha
    }
  }
  ""
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
fn write_policy_config(path : String) -> Unit {
  let content =
    #|schemaVersion: ciq-config/v1
    #|profile: policy-bundle
    #|purl: pkg:generic/acme/compat-policy@2026.03.01
    #|source:
    #|  repo: https://github.com/acme/compat-policy
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - "**/*.rego"
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to write test policy config")
  }
}

///|
fn decode_zstd_text_main(path : String, fail_message : String) -> String {
  let compressed = @fs.read_file_to_bytes(path) catch {
    _ => abort(fail_message)
  }
  let decompressed = @zstd.decompress(compressed) catch {
    _ => abort("zstd decompression failed: \{path}")
  }
  @utf8.decode(decompressed) catch {
    _ => abort("utf8 decode failed: \{path}")
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
  assert_true(metadata.contains("\"version\": \"none | baseline-v2\""))
  assert_true(metadata.contains("\"fallback\": false"))

  let checksums = @fs.read_file_to_string("\{repo}/dist/checksums.txt") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("checksums should exist")
      ""
    }
  }
  assert_true(has_64_hex(checksum_for(checksums, "manifest.json")))
  assert_true(has_64_hex(checksum_for(checksums, "declarations.ndjson.zst")))
  assert_true(has_64_hex(checksum_for(checksums, "symbols.ndjson.zst")))
  assert_true(has_64_hex(checksum_for(checksums, "metadata.json")))

  let declarations = decode_zstd_text_main(
    "\{repo}/dist/declarations.ndjson.zst",
    "declarations should exist",
  )
  assert_true(declarations.contains("\"baselineRole\":\"baseline\""))

  let symbols = decode_zstd_text_main(
    "\{repo}/dist/symbols.ndjson.zst",
    "symbols should exist",
  )
  assert_true(symbols.contains("\"id\":\"sym:openapi-spec:"))

  let bundle = @fs.read_file_to_bytes("\{repo}/dist/bundle.ciq.tgz") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("bundle.ciq.tgz should exist")
      b""
    }
  }
  assert_true(bundle.length() > 0)

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

///|
test "build creates policy-bundle artifacts and opa manifest" {
  let repo = "src/cmd/build/tmp_build_policy_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  let policy =
    #|package codeiq.compat
    #|
    #|deny contains out if {
    #|  out := {
    #|    "rule_id": "compat.removed-public-api",
    #|    "level": "error",
    #|    "message": "Removed public API requires compatibility review",
    #|  }
    #|}
    #|
  @fs.write_string_to_file("\{repo}/policy.rego", policy) catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("failed to write policy file")
    }
  }

  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("policy bundle build should succeed")
  }

  let manifest = @fs.read_file_to_string("\{repo}/dist/manifest.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("manifest should exist")
      ""
    }
  }
  assert_true(manifest.contains("\"schemaVersion\": \"ciq-opa-bundle/v1\""))
  assert_true(manifest.contains("\"profile\": \"policy-bundle\""))
  assert_true(manifest.contains("\"entrypoint\": \"codeiq/compat/deny\""))
  assert_true(manifest.contains("\"path\": \"opa-bundle.tar.gz\""))
  assert_true(manifest.contains("\"path\": \"policy.rules.json\""))
  assert_true(!manifest.contains("\"declarationSchema\""))

  let opa_bundle = @fs.read_file_to_bytes("\{repo}/dist/opa-bundle.tar.gz") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("opa bundle should exist")
      b""
    }
  }
  assert_true(opa_bundle.length() > 0)

  let policy_rules = @fs.read_file_to_string("\{repo}/dist/policy.rules.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("policy rules should exist")
      ""
    }
  }
  assert_true(
    policy_rules.contains("\"schemaVersion\": \"codeiq-policy-rules/v1\""),
  )
  assert_true(policy_rules.contains("compat.removed-public-api"))

  let checksums = @fs.read_file_to_string("\{repo}/dist/checksums.txt") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("checksums should exist")
      ""
    }
  }
  assert_true(has_64_hex(checksum_for(checksums, "opa-bundle.tar.gz")))
  assert_true(has_64_hex(checksum_for(checksums, "policy.rules.json")))

  cleanup_tmp_repo(repo)
}

///|
test "build marks fallback when lsp server is unavailable" {
  let repo = "src/cmd/build/tmp_build_go_lsp_fallback"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let config =
    #|schemaVersion: ciq-config/v1
    #|profile: go-module
    #|purl: pkg:golang/github.com/acme/demo@0.1.0
    #|source:
    #|  repo: https://github.com/acme/demo
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - "**/*.go"
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  @fs.write_string_to_file("\{repo}/codeiq.yaml", config) catch {
    _ => abort("failed to write go fallback config")
  }
  @fs.write_string_to_file(
    "\{repo}/main.go",
    "package main\n\nfunc Hello() string { return \"hi\" }\n",
  ) catch {
    _ => abort("failed to write go fixture")
  }

  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("build should succeed when lsp server is missing")
  }

  let metadata = @fs.read_file_to_string("\{repo}/dist/metadata.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("metadata should exist for fallback case")
      ""
    }
  }
  assert_true(metadata.contains("\"mode\": \"lsp-assisted\""))
  assert_true(metadata.contains("\"server\": \"gopls\""))
  assert_true(metadata.contains("\"fallback\": true"))
  assert_true(metadata.contains("missing:"))

  cleanup_tmp_repo(repo)
}
