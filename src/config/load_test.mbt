///|
fn write_tmp_config(path : String, content : String) -> Result[Unit, String] {
  @fs.write_string_to_file(path, content) catch {
    _ => return Err("failed to write tmp config")
  }
  Ok(())
}

///|
fn valid_config_yaml() -> String {
  (
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
    #|  storeDir: .cogna/cache/registry
    #|mcp:
    #|  port: 3000
    #|
  )
}

///|
fn cleanup_tmp_config(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
test "load config parses init template correctly" {
  let path = "src/config/tmp_load_valid.yml"
  cleanup_tmp_config(path)
  let wrote = write_tmp_config(path, valid_config_yaml())
  guard wrote is Ok(_) else { fail("failed to write valid tmp config") }

  let loaded = load_from_path(path)
  guard loaded is Ok(config) else {
    cleanup_tmp_config(path)
    fail("expected config to load")
  }

  guard config.schema_version == "ciq-config/v2" else {
    cleanup_tmp_config(path)
    fail("unexpected schema_version")
  }
  guard config.profile == "openapi-spec" else {
    cleanup_tmp_config(path)
    fail("unexpected profile")
  }
  guard config.validation == "none" else {
    cleanup_tmp_config(path)
    fail("unexpected validation")
  }
  guard config.purl == "pkg:openapi/acme/payment-api@2026.03.01" else {
    cleanup_tmp_config(path)
    fail("unexpected purl")
  }
  guard config.source.repo == "https://github.com/acme/payment-api" else {
    cleanup_tmp_config(path)
    fail("unexpected source.repo")
  }
  guard config.source.source_ref == "main" else {
    cleanup_tmp_config(path)
    fail("unexpected source.ref")
  }
  guard config.inputs.include_paths == ["openapi/**/*.yaml"] else {
    cleanup_tmp_config(path)
    fail("unexpected inputs.include")
  }
  guard config.checks.format == "sarif" else {
    cleanup_tmp_config(path)
    fail("unexpected checks.format")
  }
  guard config.checks.policy == "./dist/policy.ciq.tgz" else {
    cleanup_tmp_config(path)
    fail("unexpected checks.policy")
  }
  guard config.sbom.format == "spdx" else {
    cleanup_tmp_config(path)
    fail("unexpected sbom.format")
  }
  guard config.publish.include_dependencies else {
    cleanup_tmp_config(path)
    fail("unexpected publish.includeDependencies")
  }

  cleanup_tmp_config(path)
}

///|
test "load config rejects unsupported profile" {
  let path = "src/config/tmp_load_bad_profile.yaml"
  cleanup_tmp_config(path)
  let wrote = write_tmp_config(
    path,
    (
      #|schemaVersion: ciq-config/v2
      #|profile: unknown-profile
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
      #|  storeDir: .cogna/cache/registry
      #|mcp:
      #|  port: 3000
      #|
    ),
  )
  guard wrote is Ok(_) else { fail("failed to write bad-profile tmp config") }

  let loaded = load_from_path(path)
  guard loaded is Err(error) else {
    cleanup_tmp_config(path)
    fail("expected invalid profile to fail")
  }

  let text = error.to_string()
  guard text.contains("$.profile: value is not in enum") else {
    cleanup_tmp_config(path)
    fail("unexpected validation message for profile")
  }

  cleanup_tmp_config(path)
}

///|
test "load config rejects README/example inputs" {
  let path = "src/config/tmp_load_bad_inputs.yaml"
  cleanup_tmp_config(path)
  let wrote = write_tmp_config(
    path,
    (
      #|schemaVersion: ciq-config/v2
      #|profile: openapi-spec
      #|purl: pkg:openapi/acme/payment-api@2026.03.01
      #|source:
      #|  repo: https://github.com/acme/payment-api
      #|  ref: main
      #|inputs:
      #|  include:
      #|    - README.md
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
      #|  storeDir: .cogna/cache/registry
      #|mcp:
      #|  port: 3000
      #|
    ),
  )
  guard wrote is Ok(_) else { fail("failed to write bad-inputs tmp config") }

  let loaded = load_from_path(path)
  guard loaded is Err(error) else {
    cleanup_tmp_config(path)
    fail("expected disallowed inputs.include path to fail")
  }

  let text = error.to_string()
  guard text.contains(
    "inputs.include must reference code/spec files only (no README/example paths)",
  ) else {
    cleanup_tmp_config(path)
    fail("unexpected validation message for include path")
  }

  cleanup_tmp_config(path)
}

///|
test "load config parses explicit validation mode" {
  let path = "src/config/tmp_load_validation.yaml"
  cleanup_tmp_config(path)
  let wrote = write_tmp_config(
    path,
    valid_config_yaml()
    .replace(old="profile: openapi-spec", new="profile: go-module")
    .replace(
      old="purl: pkg:openapi/acme/payment-api@2026.03.01",
      new="validation: lsp\npurl: pkg:golang/acme/payment-api@2026.03.01",
    )
    .replace(old="openapi/**/*.yaml", new="**/*.go"),
  )
  guard wrote is Ok(_) else { fail("failed to write validation tmp config") }

  let loaded = load_from_path(path)
  guard loaded is Ok(config) else {
    cleanup_tmp_config(path)
    fail("expected validation config to load")
  }

  guard config.validation == "lsp" else {
    cleanup_tmp_config(path)
    fail("unexpected validation mode")
  }

  cleanup_tmp_config(path)
}

///|
test "resolve prefers cogna.yml and falls back to cogna.yaml" {
  let dir = "src/config/tmp_resolve_config"
  cleanup_tmp_config("\{dir}/cogna.yml")
  cleanup_tmp_config("\{dir}/cogna.yaml")
  @fs.remove_dir(dir) catch {
    _ => ()
  }
  @fs.create_dir(dir)

  let legacy = write_tmp_config(
    "\{dir}/cogna.yaml",
    valid_config_yaml().replace(old="ciq-config/v2", new="ciq-config/v1"),
  )
  guard legacy is Ok(_) else { fail("failed to write fallback config") }
  let fallback = resolve(dir)
  guard fallback is Ok(legacy_resolved) else {
    cleanup_tmp_config("\{dir}/cogna.yaml")
    @fs.remove_dir(dir) catch {
      _ => ()
    }
    fail("expected fallback config to resolve")
  }
  inspect(
    legacy_resolved.path,
    content="src/config/tmp_resolve_config/cogna.yaml",
  )

  let preferred = write_tmp_config("\{dir}/cogna.yml", valid_config_yaml())
  guard preferred is Ok(_) else { fail("failed to write preferred config") }
  let resolved = resolve(dir)
  guard resolved is Ok(preferred_resolved) else {
    cleanup_tmp_config("\{dir}/cogna.yml")
    cleanup_tmp_config("\{dir}/cogna.yaml")
    @fs.remove_dir(dir) catch {
      _ => ()
    }
    fail("expected preferred config to resolve")
  }
  inspect(
    preferred_resolved.path,
    content="src/config/tmp_resolve_config/cogna.yml",
  )

  cleanup_tmp_config("\{dir}/cogna.yml")
  cleanup_tmp_config("\{dir}/cogna.yaml")
  @fs.remove_dir(dir) catch {
    _ => ()
  }
}
