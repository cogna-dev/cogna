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
  @build_shell.run_command_capture("rm -rf '\{repo}'") |> ignore
  ensure_file_removed("\{repo}/codeiq.yml")
  ensure_file_removed("\{repo}/codeiq.yaml")
  ensure_file_removed("\{repo}/policy.rego")
  ensure_file_removed("\{repo}/a.rego")
  ensure_file_removed("\{repo}/z.rego")
  ensure_file_removed("\{repo}/main.go")
  ensure_file_removed("\{repo}/lib.rs")
  ensure_file_removed("\{repo}/dist/manifest.json")
  ensure_file_removed("\{repo}/dist/declarations.ndjson")
  ensure_file_removed("\{repo}/dist/symbols.ndjson")
  ensure_file_removed("\{repo}/dist/software-components.ndjson")
  ensure_file_removed("\{repo}/dist/sbom.spdx.json")
  ensure_file_removed("\{repo}/dist/metadata.json")
  ensure_file_removed("\{repo}/dist/checksums.txt")
  ensure_file_removed("\{repo}/dist/opa-bundle.tar.gz")
  ensure_file_removed("\{repo}/dist/policy.rules.json")
  ensure_file_removed("\{repo}/dist/bundle.ciq.tgz")
  ensure_file_removed(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/manifest.json",
  )
  ensure_file_removed(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/package.files.json",
  )
  ensure_file_removed(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/metadata.json",
  )
  ensure_file_removed(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/checksums.txt",
  )
  ensure_file_removed(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/bundle.ciq.tgz",
  )
  ensure_dir_removed("\{repo}/dist/dependencies/pkg_npm_react_18.2.0")
  ensure_dir_removed("\{repo}/dist/dependencies")
  ensure_file_removed("\{repo}/node_modules/react/package.json")
  ensure_dir_removed("\{repo}/node_modules/react")
  ensure_dir_removed("\{repo}/node_modules")
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
fn write_valid_v2_config(path : String) -> Unit {
  let content =
    #|schemaVersion: ciq-config/v2
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
    #|  policy: ./dist/policy.ciq.tgz
    #|diff:
    #|  includeTestChanges: false
    #|sbom:
    #|  format: spdx
    #|  dependencyBundles: true
    #|  requireLocalPackages: true
    #|publish:
    #|  includeDependencies: true
    #|registry:
    #|  port: 8787
    #|  storeDir: .codeiq/cache/registry
    #|mcp:
    #|  port: 3000
    #|
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to write test v2 config")
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
fn tmp_build_repo(name : String) -> String {
  "/tmp/codeiq-build-\{name}"
}

///|
fn write_policy_rego(repo : String, content : String) -> Unit {
  @fs.write_string_to_file("\{repo}/policy.rego", content) catch {
    _ => abort("failed to write policy file")
  }
}

///|
test "build creates bundle skeleton files" {
  let repo = tmp_build_repo("repo")
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
    content="Generated CIQ bundle skeleton at /tmp/codeiq-build-repo/dist",
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
  assert_true(metadata.contains("\"role\": \"canonical\""))
  assert_true(metadata.contains("\"backend\": \"canonical\""))
  assert_true(metadata.contains("\"mode\": \"parser-only\""))
  assert_true(metadata.contains("\"server\": \"canonical\""))
  assert_true(metadata.contains("\"version\": \"canonical-v1\""))
  assert_true(metadata.contains("\"fallback\": false"))
  assert_false(metadata.contains("\"requestedBackend\""))
  assert_false(metadata.contains("\"effectiveBackend\""))

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
  assert_true(has_64_hex(checksum_for(checksums, "software-components.ndjson")))
  assert_true(has_64_hex(checksum_for(checksums, "sbom.spdx.json")))
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
  let components = read_text_main(
    "\{repo}/dist/software-components.ndjson",
    "software components should exist",
  )
  assert_true(components.contains("\"kind\":\"component\""))
  let spdx = read_text_main(
    "\{repo}/dist/sbom.spdx.json",
    "spdx sbom should exist",
  )
  assert_true(
    spdx.contains(
      "\"@context\": \"https://spdx.org/rdf/3.0.1/spdx-context.jsonld\"",
    ),
  )

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
test "build writes dependency bundles for resolved local packages" {
  let repo = tmp_build_repo("dependencies-repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  let node_modules_out = try? @fs.create_dir("\{repo}/node_modules")
  guard node_modules_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to create node_modules")
  }
  let react_dir_out = try? @fs.create_dir("\{repo}/node_modules/react")
  guard react_dir_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to create react package")
  }

  write_valid_v2_config("\{repo}/codeiq.yml")
  let package_out = try? @fs.write_string_to_file(
    "\{repo}/package.json",
    Json::object({
      "name": Json::string("payment-api"),
      "version": Json::string("1.0.0"),
      "dependencies": Json::object({ "react": Json::string("18.2.0") }),
    }).stringify(indent=2),
  )
  guard package_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to write package.json")
  }
  let dependency_package_out = try? @fs.write_string_to_file(
    "\{repo}/node_modules/react/package.json",
    Json::object({
      "name": Json::string("react"),
      "version": Json::string("18.2.0"),
    }).stringify(indent=2),
  )
  guard dependency_package_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to write dependency package")
  }

  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("build with dependencies should succeed")
  }

  let dependency_manifest = read_text_main(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/manifest.json",
    "dependency manifest should exist",
  )
  assert_true(
    dependency_manifest.contains("\"model\": \"dependency-files-only\""),
  )
  let dependency_files = read_text_main(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/package.files.json",
    "dependency files should exist",
  )
  assert_true(
    dependency_files.contains("react/package.json") ||
    dependency_files.contains("package.json"),
  )
  let dependency_bundle = @fs.read_file_to_bytes(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/bundle.ciq.tgz",
  ) catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("dependency bundle should exist")
      b""
    }
  }
  assert_true(dependency_bundle.length() > 0)

  cleanup_tmp_repo(repo)
}

///|
test "build returns config error when config file is missing" {
  let repo = tmp_build_repo("missing-config")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let out = run({ repo, })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("build should fail when config is missing")
  }

  let text = error.to_string()
  assert_true(text.contains("config error:"))
  assert_true(text.contains("codeiq.yml"))

  cleanup_tmp_repo(repo)
}

///|
test "build creates policy-bundle artifacts and opa manifest" {
  let repo = tmp_build_repo("policy-repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  let policy =
    #|package codeiq.compat
    #|
    #|deny contains out if {
    #|  out := {
    #|    "rule_id": "compat.core.removed-declaration",
    #|    "level": "error",
    #|    "message": "Removed public API requires compatibility review",
    #|    "docs": "https://example.dev/policy/compat.core.removed-declaration"
    #|  }
    #|}
    #|
  write_policy_rego(repo, policy)

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
  assert_true(manifest.contains("\"path\": \"software-components.ndjson\""))
  assert_true(manifest.contains("\"path\": \"sbom.spdx.json\""))
  assert_true(!manifest.contains("\"path\": \"sbom.cdx.json\""))
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
  assert_true(policy_rules.contains("compat.core.removed-declaration"))
  assert_true(policy_rules.contains("\"family\": \"core\""))
  assert_true(policy_rules.contains("\"defaultLevel\": \"error\""))
  assert_true(
    policy_rules.contains("\"entrypoint\": \"data.codeiq.compat.deny\""),
  )

  let checksums = @fs.read_file_to_string("\{repo}/dist/checksums.txt") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("checksums should exist")
      ""
    }
  }
  assert_true(has_64_hex(checksum_for(checksums, "opa-bundle.tar.gz")))
  assert_true(has_64_hex(checksum_for(checksums, "policy.rules.json")))
  assert_true(has_64_hex(checksum_for(checksums, "software-components.ndjson")))
  assert_true(has_64_hex(checksum_for(checksums, "sbom.spdx.json")))

  cleanup_tmp_repo(repo)
}

///|
test "build policy-bundle uses builtin rego and generated catalog when repo has no rego files" {
  let repo = tmp_build_repo("builtin-policy-repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("builtin policy bundle build should succeed")
  }

  let policy_rules = @fs.read_file_to_string("\{repo}/dist/policy.rules.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("policy rules should exist")
      ""
    }
  }
  assert_true(
    policy_rules.contains("\"schemaVersion\": \"codeiq-policy-rules/v1\"") ||
    policy_rules.contains("\"schemaVersion\":\"codeiq-policy-rules/v1\""),
  )
  assert_true(policy_rules.contains("compat.core.removed-declaration"))
  assert_true(policy_rules.contains("compat.go.signature-changed"))
  assert_true(policy_rules.contains("compat.rust.became-unsafe"))
  assert_true(policy_rules.contains("compat.terraform.input-became-required"))
  assert_true(policy_rules.contains("compat.terraform.output-removed"))
  assert_true(policy_rules.contains("compat.openapi.response-status-removed"))
  assert_true(policy_rules.contains("compat.openapi.response-schema-narrowed"))
  assert_true(policy_rules.contains("compat.component.version-upgrade"))
  assert_true(
    policy_rules.contains("\"entrypoint\": \"data.codeiq.compat.deny\""),
  )

  let opa_bundle = @fs.read_file_to_bytes("\{repo}/dist/opa-bundle.tar.gz") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("opa bundle should exist")
      b""
    }
  }
  assert_true(opa_bundle.length() > 0)

  cleanup_tmp_repo(repo)
}

///|
test "build rejects duplicate custom policy rule ids" {
  let repo = tmp_build_repo("duplicate-policy-repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  let policy =
    #|package codeiq.compat
    #|
    #|deny contains out if {
    #|  out := {
    #|    "rule_id": "compat.core.removed-declaration",
    #|    "level": "error",
    #|    "message": "first",
    #|    "docs": "https://example.dev/policy/first"
    #|  }
    #|}
    #|
    #|deny contains out if {
    #|  out := {
    #|    "rule_id": "compat.core.removed-declaration",
    #|    "level": "error",
    #|    "message": "second",
    #|    "docs": "https://example.dev/policy/second"
    #|  }
    #|}
    #|
  write_policy_rego(repo, policy)

  let out = run({ repo, })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("duplicate custom rule ids should fail build")
  }
  assert_true(error.message.contains("duplicate rule_id"))

  cleanup_tmp_repo(repo)
}

///|
test "build reads custom rego files in deterministic lexicographic order" {
  let repo = tmp_build_repo("sorted-policy-repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  let z_policy =
    #|package codeiq.compat
    #|
    #|deny contains out if {
    #|  out := {
    #|    "rule_id": "compat.custom.zeta-rule",
    #|    "level": "warning",
    #|    "message": "zeta",
    #|    "docs": "https://example.dev/policy/zeta"
    #|  }
    #|}
    #|
  let a_policy =
    #|package codeiq.compat
    #|
    #|deny contains out if {
    #|  out := {
    #|    "rule_id": "compat.custom.alpha-rule",
    #|    "level": "error",
    #|    "message": "alpha",
    #|    "docs": "https://example.dev/policy/alpha"
    #|  }
    #|}
    #|
  @fs.write_string_to_file("\{repo}/z.rego", z_policy) catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("failed to write z.rego")
    }
  }
  @fs.write_string_to_file("\{repo}/a.rego", a_policy) catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("failed to write a.rego")
    }
  }

  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("sorted custom policy bundle build should succeed")
  }

  let policy_rules = @fs.read_file_to_string("\{repo}/dist/policy.rules.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("policy rules should exist")
      ""
    }
  }
  let alpha_index = policy_rules.find("compat.custom.alpha-rule")
  let zeta_index = policy_rules.find("compat.custom.zeta-rule")
  guard alpha_index is Some(alpha_pos) else {
    cleanup_tmp_repo(repo)
    fail("alpha rule should exist in policy rules catalog")
  }
  guard zeta_index is Some(zeta_pos) else {
    cleanup_tmp_repo(repo)
    fail("zeta rule should exist in policy rules catalog")
  }
  assert_true(alpha_pos < zeta_pos)

  cleanup_tmp_repo(repo)
}

///|
test "build rejects custom policy rules missing literal metadata" {
  let repo = tmp_build_repo("missing-metadata-policy-repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  let policy =
    #|package codeiq.compat
    #|
    #|deny contains out if {
    #|  out := {
    #|    "rule_id": "compat.core.removed-declaration",
    #|    "level": "error",
    #|    "message": "Removed public API requires compatibility review"
    #|  }
    #|}
    #|
  write_policy_rego(repo, policy)

  let out = run({ repo, })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("missing docs metadata should fail build")
  }
  assert_true(error.message.contains("missing literal docs metadata"))

  cleanup_tmp_repo(repo)
}

///|
test "build rejects custom policy bundles with no extracted rules" {
  let repo = tmp_build_repo("empty-catalog-policy-repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_policy_config("\{repo}/codeiq.yaml")
  let policy =
    #|package codeiq.compat
    #|
    #|default deny = []
    #|
  write_policy_rego(repo, policy)

  let out = run({ repo, })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("empty extracted policy catalog should fail build")
  }
  assert_true(error.message.contains("no rules extracted"))

  cleanup_tmp_repo(repo)
}

///|
test "build policy-bundle supports signature status and key id env" {
  let repo = tmp_build_repo("policy-signature-repo")
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
  let repo = tmp_build_repo("policy-signature-value-repo")
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
  let repo = tmp_build_repo("go-lsp-hardfail")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let config =
    #|schemaVersion: ciq-config/v1
    #|profile: go-module
    #|validation: lsp
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
  let repo = tmp_build_repo("rust-lsp-hardfail")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let config =
    #|schemaVersion: ciq-config/v1
    #|profile: rust-crate
    #|validation: lsp
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

///|
test "build keeps canonical metadata under lsp validation" {
  let repo = tmp_build_repo("go-validation-metadata")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  let config =
    #|schemaVersion: ciq-config/v1
    #|profile: go-module
    #|validation: lsp
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
    _ => abort("failed to write go validation config")
  }
  @fs.write_string_to_file(
    "\{repo}/main.go",
    "package main\n\nfunc Hello() string { return \"hi\" }\n",
  ) catch {
    _ => abort("failed to write go validation fixture")
  }

  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("build should succeed with lsp validation")
  }

  let metadata = read_text_main(
    "\{repo}/dist/metadata.json",
    "metadata should exist under validation",
  )
  assert_true(metadata.contains("\"mode\": \"parser-first\""))
  assert_true(metadata.contains("\"fallback\": false"))
  assert_true(metadata.contains("\"backend\": \"canonical\""))
  assert_true(metadata.contains("\"server\": \"canonical\""))

  let declarations = read_text_main(
    "\{repo}/dist/declarations.ndjson",
    "declarations should exist under validation",
  )
  assert_true(declarations.contains("\"baselineRole\":\"baseline\""))
  assert_true(declarations.contains("\"server\":\"gopls\""))

  cleanup_tmp_repo(repo)
}
