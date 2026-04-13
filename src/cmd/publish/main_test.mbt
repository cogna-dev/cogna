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
  remove_file_if_exists("\{repo}/dist/bundle.ciq.tgz")
  remove_file_if_exists("\{repo}/dist/manifest.json")
  remove_file_if_exists("\{repo}/dist/publish.json")
  remove_file_if_exists(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/manifest.json",
  )
  remove_file_if_exists(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/package.files.json",
  )
  remove_file_if_exists(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/metadata.json",
  )
  remove_file_if_exists(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/checksums.txt",
  )
  remove_file_if_exists(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/bundle.ciq.tgz",
  )
  remove_dir_if_exists("\{repo}/dist/dependencies/pkg_npm_react_18.2.0")
  remove_dir_if_exists("\{repo}/dist/dependencies")
  remove_dir_if_exists(".codeiq/registry/http")
  remove_dir_if_exists(".codeiq/registry/index")
  remove_dir_if_exists(".codeiq/registry/bundles")
  remove_dir_if_exists(".codeiq/registry")
  remove_dir_if_exists(".codeiq/cache/registry/index")
  remove_dir_if_exists(".codeiq/cache/registry/bundles")
  remove_dir_if_exists(".codeiq/cache/registry")
  remove_dir_if_exists(".codeiq/cache")
  remove_dir_if_exists(".codeiq")
  remove_dir_if_exists("\{repo}/dist")
  remove_dir_if_exists(repo)
  @sys.unset_env_var("CODEIQ_REGISTRY_STORE_DIR")
  @sys.unset_env_var("CODEIQ_REGISTRY_BASE_URL")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
  @sys.unset_env_var("CODEIQ_SIGNATURE_STATUS")
  @sys.unset_env_var("CODEIQ_SIGNATURE_KEY_ID")
  @sys.unset_env_var("CODEIQ_SIGNATURE_VALUE")
  @sys.unset_env_var("CODEIQ_SIGNATURE_PUBLIC_KEY_FILE")
  @sys.unset_env_var("CODEIQ_REGISTRY_ALLOW_INSECURE_HTTP")
}

///|
fn tmp_publish_repo(name : String) -> String {
  "/tmp/codeiq-publish-\{name}"
}

///|
test "publish generates local publish receipt" {
  let repo = tmp_publish_repo("repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("publish should succeed")
  }

  inspect(
    result.display(),
    content="Generated publish receipt at /tmp/codeiq-publish-repo/dist/publish.json",
  )

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(
    receipt.contains("\"schemaVersion\": \"codeiq-publish-receipt/v1\""),
  )
  assert_true(receipt.contains("\"publishId\":"))
  assert_true(receipt.contains("\"bundleType\": \"ciq-bundle\""))
  assert_true(
    receipt.contains("\"status\": \"published\"") ||
    receipt.contains("\"status\": \"already-exists\""),
  )
  assert_true(receipt.contains("\"provenance\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish aggregates dependency bundle receipts when config enables dependencies" {
  let repo = tmp_publish_repo("with-dependencies")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")
  let dependencies_dir_out = try? @fs.create_dir("\{repo}/dist/dependencies")
  guard dependencies_dir_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to create dependency dir")
  }
  let dependency_bundle_dir_out = try? @fs.create_dir(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0",
  )
  guard dependency_bundle_dir_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to create dependency bundle dir")
  }

  let config =
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
  let config_out = try? @fs.write_string_to_file("\{repo}/codeiq.yml", config)
  guard config_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to write config")
  }

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  let bundle_out = try? @fs.write_string_to_file(
    bundle_path, "bundle placeholder",
  )
  guard bundle_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to write bundle fixture")
  }
  let main_manifest_out = try? @fs.write_string_to_file(
    "\{repo}/dist/manifest.json",
    (
      {
        "schemaVersion": "ciq-bundle/v1",
        "purl": "pkg:openapi/acme/payment-api@2026.03.01",
        "profile": "openapi-spec",
        "declarationSchema": {
          "version": "ciq-declarations/v1",
          "format": "ndjson",
          "model": "signature + shape + language_specific tagged union",
        },
        "source": {
          "repo": "https://github.com/acme/payment-api",
          "ref": "main",
          "commit": "abcdef",
        },
        "artifacts": [],
      } : Json).stringify(indent=2),
  )
  guard main_manifest_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to write main manifest")
  }
  let dependency_bundle_out = try? @fs.write_string_to_file(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/bundle.ciq.tgz",
    "dependency bundle placeholder",
  )
  guard dependency_bundle_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to write dependency bundle")
  }
  let dependency_manifest_out = try? @fs.write_string_to_file(
    "\{repo}/dist/dependencies/pkg_npm_react_18.2.0/manifest.json",
    (
      {
        "schemaVersion": "ciq-bundle/v1",
        "purl": "pkg:npm/react@18.2.0",
        "profile": "openapi-spec",
        "declarationSchema": {
          "version": "ciq-declarations/v1",
          "format": "ndjson",
          "model": "dependency-files-only",
        },
        "source": {
          "repo": "local-package-cache",
          "ref": "installed",
          "commit": "sha256:abcd",
        },
        "artifacts": [],
      } : Json).stringify(indent=2),
  )
  guard dependency_manifest_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("failed to write dependency manifest")
  }

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish should aggregate dependency receipts")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("aggregated publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"dependencyCount\": 1"))
  assert_true(receipt.contains("\"dependencyReceipts\""))
  assert_true(receipt.contains("pkg:npm/react@18.2.0"))

  cleanup_tmp_repo(repo)
}

///|
test "publish fails when bundle file is missing" {
  let repo = tmp_publish_repo("missing-bundle")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let out = run({ bundle_file: "\{repo}/dist/bundle.ciq.tgz" })
  guard out is Err(error) else {
    cleanup_tmp_repo(repo)
    fail("publish should fail when bundle file missing")
  }

  let text = error.to_string()
  assert_true(text.contains("publish failed:"))
  assert_true(text.contains("bundle file does not exist"))

  cleanup_tmp_repo(repo)
}

///|
test "publish returns already-exists receipt when etag matches" {
  let repo = tmp_publish_repo("etag-match")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  let first_out = run({ bundle_file: bundle_path })
  guard first_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("first publish should succeed")
  }

  let first_receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("first publish receipt should exist")
      ""
    }
  }
  let parsed = try? @json.parse(first_receipt)
  guard parsed is Ok(Object(receipt_object)) else {
    cleanup_tmp_repo(repo)
    fail("first receipt should be valid json")
  }
  guard receipt_object.get("bundleId") is Some(String(bundle_id)) else {
    cleanup_tmp_repo(repo)
    fail("first receipt should contain bundleId")
  }

  @sys.set_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH", "\"\{bundle_id}\"")
  let second_out = run({ bundle_file: bundle_path })
  @sys.unset_env_var("CODEIQ_REGISTRY_IF_NONE_MATCH")
  guard second_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("second publish should succeed with etag")
  }

  let second_receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("second publish receipt should exist")
      ""
    }
  }
  assert_true(second_receipt.contains("\"status\": \"already-exists\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish receipt uses shared local registry cache path" {
  let repo = tmp_publish_repo("shared-cache")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish should succeed")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"source\": \"local-registry\""))
  assert_true(receipt.contains("local://.codeiq/cache/registry/bundles/"))

  cleanup_tmp_repo(repo)
}

///|
test "publish receipt includes signature metadata from local registry response" {
  let repo = tmp_publish_repo("signature-metadata")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_SIGNATURE_STATUS", "verified")
  @sys.set_env_var("CODEIQ_SIGNATURE_KEY_ID", "acme-main")
  @sys.set_env_var("CODEIQ_SIGNATURE_VALUE", "ZmFrZS1zaWduYXR1cmU=")
  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish should succeed with signature metadata")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"signature\""))
  assert_true(receipt.contains("\"status\": \"verified\""))
  assert_true(receipt.contains("\"keyId\": \"acme-main\""))
  assert_true(receipt.contains("\"value\": \"ZmFrZS1zaWduYXR1cmU=\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish preserves verified signature without trust downgrade" {
  let repo = tmp_publish_repo("signature-preserved")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_SIGNATURE_STATUS", "verified")
  @sys.set_env_var("CODEIQ_SIGNATURE_KEY_ID", "acme-main")
  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish should succeed in local-only mode")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"signature\""))
  assert_true(receipt.contains("\"status\": \"verified\""))
  assert_true(receipt.contains("\"keyId\": \"acme-main\""))

  cleanup_tmp_repo(repo)
}

///|
test "publish allows untrusted signature metadata in local-only mode" {
  let repo = tmp_publish_repo("untrusted-signature")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_string_to_file(bundle_path, "bundle placeholder") catch {
    _ => abort("failed to write bundle fixture")
  }

  @sys.set_env_var("CODEIQ_SIGNATURE_STATUS", "untrusted")
  @sys.set_env_var("CODEIQ_SIGNATURE_KEY_ID", "unknown-key")
  let out = run({ bundle_file: bundle_path })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("publish should allow untrusted signature metadata locally")
  }

  let receipt = @fs.read_file_to_string("\{repo}/dist/publish.json") catch {
    _ => {
      cleanup_tmp_repo(repo)
      fail("publish receipt should exist")
      ""
    }
  }
  assert_true(receipt.contains("\"signature\""))
  assert_true(receipt.contains("\"status\": \"untrusted\""))
  assert_true(receipt.contains("\"keyId\": \"unknown-key\""))

  cleanup_tmp_repo(repo)
}
