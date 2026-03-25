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
  ensure_file_removed("\{repo}/main.go")
  ensure_file_removed("\{repo}/lib.rs")
  ensure_file_removed("\{repo}/dist/manifest.json")
  ensure_file_removed("\{repo}/dist/declarations.ndjson")
  ensure_file_removed("\{repo}/dist/symbols.ndjson")
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
fn read_text_main(path : String, fail_message : String) -> String {
  @fs.read_file_to_string(path) catch {
    _ => abort(fail_message)
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
  assert_true(has_64_hex(checksum_for(checksums, "declarations.ndjson")))
  assert_true(has_64_hex(checksum_for(checksums, "symbols.ndjson")))
  assert_true(has_64_hex(checksum_for(checksums, "metadata.json")))

  let declarations = read_text_main(
    "\{repo}/dist/declarations.ndjson",
    "declarations should exist",
  )
  assert_true(declarations.contains("\"baselineRole\":\"baseline\""))

  let symbols = read_text_main(
    "\{repo}/dist/symbols.ndjson",
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
  assert_true(manifest.contains("\"provenance\""))
  assert_true(manifest.contains("\"checksums\": \"checksums.txt\""))
  assert_true(manifest.contains("\"status\": \"unsigned\""))
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
test "build policy-bundle supports signature status and key id env" {
  let repo = "src/cmd/build/tmp_build_policy_signature_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  @sys.set_env_var("CODEIQ_SIGNATURE_STATUS", "verified")
  @sys.set_env_var("CODEIQ_SIGNATURE_KEY_ID", "acme-main")
  let out = run({ repo, })
  @sys.unset_env_var("CODEIQ_SIGNATURE_STATUS")
  @sys.unset_env_var("CODEIQ_SIGNATURE_KEY_ID")
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
  assert_true(manifest.contains("\"status\": \"verified\""))
  assert_true(manifest.contains("\"keyId\": \"acme-main\""))

  cleanup_tmp_repo(repo)
}

///|
test "build policy-bundle includes signature value when provided" {
  let repo = "src/cmd/build/tmp_build_policy_signature_value_repo"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  @sys.set_env_var("CODEIQ_SIGNATURE_STATUS", "verified")
  @sys.set_env_var("CODEIQ_SIGNATURE_KEY_ID", "acme-main")
  @sys.set_env_var("CODEIQ_SIGNATURE_VALUE", "ZmFrZS1zaWduYXR1cmU=")
  let out = run({ repo, })
  @sys.unset_env_var("CODEIQ_SIGNATURE_STATUS")
  @sys.unset_env_var("CODEIQ_SIGNATURE_KEY_ID")
  @sys.unset_env_var("CODEIQ_SIGNATURE_VALUE")
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
  assert_true(manifest.contains("\"status\": \"verified\""))
  assert_true(manifest.contains("\"keyId\": \"acme-main\""))
  assert_true(manifest.contains("\"value\": \"ZmFrZS1zaWduYXR1cmU=\""))

  cleanup_tmp_repo(repo)
}

///|
test "build fails when lsp server is unavailable for go profile" {
  let repo = "src/cmd/build/tmp_build_go_lsp_hardfail"
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
    _ => abort("failed to write go hardfail config")
  }
  @fs.write_string_to_file(
    "\{repo}/main.go",
    "package main\n\nfunc Hello() string { return \"hi\" }\n",
  ) catch {
    _ => abort("failed to write go fixture")
  }

  @sys.set_env_var("CODEIQ_TEST_FORCE_LSP_FALLBACK", "true")
  let out = run({ repo, })
  @sys.unset_env_var("CODEIQ_TEST_FORCE_LSP_FALLBACK")
  guard out is Err(e) else {
    cleanup_tmp_repo(repo)
    fail("build should fail when lsp server is missing for go-module")
  }
  assert_true(e.message.contains("gopls"))
  assert_true(e.message.contains("missing:"))

  cleanup_tmp_repo(repo)
}

///|
test "build fails when lsp server is unavailable for rust profile" {
  let repo = "src/cmd/build/tmp_build_rust_lsp_hardfail"
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let config =
    #|schemaVersion: ciq-config/v1
    #|profile: rust-crate
    #|purl: pkg:cargo/acme-demo@0.1.0
    #|source:
    #|  repo: https://github.com/acme/demo
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - "**/*.rs"
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  @fs.write_string_to_file("\{repo}/codeiq.yaml", config) catch {
    _ => abort("failed to write rust hardfail config")
  }
  @fs.write_string_to_file(
    "\{repo}/lib.rs",
    "pub fn hello() -> &'static str { \"hi\" }\n",
  ) catch {
    _ => abort("failed to write rust fixture")
  }

  @sys.set_env_var("CODEIQ_TEST_FORCE_LSP_FALLBACK", "true")
  let out = run({ repo, })
  @sys.unset_env_var("CODEIQ_TEST_FORCE_LSP_FALLBACK")
  guard out is Err(e) else {
    cleanup_tmp_repo(repo)
    fail("build should fail when lsp server is missing for rust-crate")
  }
  assert_true(e.message.contains("rust-analyzer"))
  assert_true(e.message.contains("missing:"))

  cleanup_tmp_repo(repo)
}
