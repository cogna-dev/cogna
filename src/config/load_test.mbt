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
  let path = "src/config/tmp_load_valid.yaml"
  cleanup_tmp_config(path)
  let wrote = write_tmp_config(path, valid_config_yaml())
  guard wrote is Ok(_) else { fail("failed to write valid tmp config") }

  let loaded = load_from_path(path)
  guard loaded is Ok(config) else {
    cleanup_tmp_config(path)
    fail("expected config to load")
  }

  guard config.schema_version == "ciq-config/v1" else {
    cleanup_tmp_config(path)
    fail("unexpected schema_version")
  }
  guard config.profile == "openapi-spec" else {
    cleanup_tmp_config(path)
    fail("unexpected profile")
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
  guard config.checks.policy == "default-compat" else {
    cleanup_tmp_config(path)
    fail("unexpected checks.policy")
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
      #|schemaVersion: ciq-config/v1
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
      #|  policy: default-compat
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
  guard text.contains(
    "profile must be one of go-module, rust-crate, terraform-module, openapi-spec",
  ) else {
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
      #|schemaVersion: ciq-config/v1
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
      #|  policy: default-compat
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
