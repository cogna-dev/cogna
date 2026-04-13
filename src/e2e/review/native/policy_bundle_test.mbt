///|
fn policy_bundle_cleanup(path : String) -> Unit {
  @fs.remove_file("\{path}/codeiq.yaml") catch {
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
  @fs.remove_file("\{path}/dist/software-components.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/sbom.spdx.json") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/opa-bundle.tar.gz") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/policy.rules.json") catch {
    _ => ()
  }
  @fs.remove_file("\{path}/dist/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_dir("\{path}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn cleanup_policy_bundle_runtime_state() -> Unit {
  @fs.remove_file("./dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("./dist/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("./dist/query.result.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/check.sarif.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/mcp-server.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/mcp-tools-state.json") catch {
    _ => ()
  }
  @fs.remove_file("./dist/opa-bundle.tar.gz") catch {
    _ => ()
  }
  @fs.remove_file("./dist/policy.rules.json") catch {
    _ => ()
  }
}

///|
fn write_policy_bundle_config_native(path : String) -> Unit {
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
    _ => abort("failed to write native policy bundle config")
  }
}

///|
test "e2e review materializes built policy bundle artifacts" {
  let path = "src/e2e/tmp_codeiq_e2e_policy_bundle"
  policy_bundle_cleanup(path)
  cleanup_policy_bundle_runtime_state()
  @fs.create_dir(path) catch {
    _ => abort("failed to create policy bundle repo")
  }
  write_policy_bundle_config_native("\{path}/codeiq.yaml")

  let build_out = @build_cmd.run(@build_cmd.BuildParams::{ repo: path })
  guard build_out is Ok(_) else {
    policy_bundle_cleanup(path)
    cleanup_policy_bundle_runtime_state()
    fail("policy bundle build should succeed")
  }

  let materialize_out = @bundle.materialize_bundle_tar_gz(
    "\{path}/dist/bundle.ciq.tgz",
    "./dist",
  )
  guard materialize_out is Ok(_) else {
    policy_bundle_cleanup(path)
    cleanup_policy_bundle_runtime_state()
    fail("materialize should succeed for built policy bundle")
  }

  let manifest = @fs.read_file_to_string("./dist/manifest.json") catch {
    _ => {
      policy_bundle_cleanup(path)
      cleanup_policy_bundle_runtime_state()
      fail("materialized manifest should exist")
      ""
    }
  }
  assert_true(manifest.contains("\"schemaVersion\": \"ciq-opa-bundle/v1\""))
  assert_true(manifest.contains("\"entrypoint\": \"codeiq/compat/deny\""))

  let policy_rules = @fs.read_file_to_string("./dist/policy.rules.json") catch {
    _ => {
      policy_bundle_cleanup(path)
      cleanup_policy_bundle_runtime_state()
      fail("materialized policy rules should exist")
      ""
    }
  }
  assert_true(policy_rules.contains("compat.core.removed-declaration"))
  assert_true(policy_rules.contains("compat.go.signature-changed"))
  assert_true(policy_rules.contains("compat.rust.became-unsafe"))
  assert_true(policy_rules.contains("compat.component.version-upgrade"))
  assert_true(
    policy_rules.contains("\"entrypoint\": \"data.codeiq.compat.deny\""),
  )

  let opa_bundle = @fs.read_file_to_bytes("./dist/opa-bundle.tar.gz") catch {
    _ => {
      policy_bundle_cleanup(path)
      cleanup_policy_bundle_runtime_state()
      fail("materialized opa bundle should exist")
      b""
    }
  }
  assert_true(opa_bundle.length() > 0)

  policy_bundle_cleanup(path)
  cleanup_policy_bundle_runtime_state()
}
