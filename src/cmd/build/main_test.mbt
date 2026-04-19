///|
fn ensure_tree_removed(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  let is_dir = try? @fs.is_dir(path)
  if is_dir is Ok(true) {
    let entries = @fs.read_dir(path) catch { _ => [] }
    for i in 0..<entries.length() {
      ensure_tree_removed("\{path}/\{entries[i]}")
    }
    @fs.remove_dir(path) catch {
      _ => ()
    }
  } else {
    @fs.remove_file(path) catch {
      _ => ()
    }
  }
}

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
  ensure_tree_removed(repo)
  ensure_file_removed("\{repo}/cogna.yml")
  ensure_file_removed("\{repo}/cogna.yaml")
  ensure_file_removed("\{repo}/policy.rego")
  ensure_file_removed("\{repo}/a.rego")
  ensure_file_removed("\{repo}/z.rego")
  ensure_file_removed("\{repo}/main.go")
  ensure_file_removed("\{repo}/lib.rs")
  ensure_file_removed("\{repo}/dist/manifest.json")
  ensure_file_removed("\{repo}/dist/declarations.ndjson")
  ensure_file_removed("\{repo}/dist/metadata.json")
  ensure_file_removed("\{repo}/dist/checksums.txt")
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
  ensure_file_removed("\{repo}/.cogna/cache/index/keys.jsonl")
  ensure_dir_removed("\{repo}/.cogna/cache/index")
  ensure_dir_removed("\{repo}/.cogna/cache/meta")
  ensure_dir_removed("\{repo}/.cogna/cache/objects")
  ensure_dir_removed("\{repo}/.cogna/cache")
  ensure_dir_removed("\{repo}/.cogna")
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
    #|  policy: ./.cogna/policies
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
    #|  policy: ./.cogna/policies
    #|diff:
    #|  includeTestChanges: false
    #|sbom:
    #|  format: spdx
    #|  dependencyBundles: true
    #|  requireLocalPackages: true
    #|cache:
    #|  type: local
    #|  local:
    #|    storeDir: .cogna/cache
    #|  http:
    #|    baseUrl:
    #|    timeoutMs: 10000
    #|mcp:
    #|  port: 3000
    #|
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to write test v2 config")
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
  "/tmp/cogna-build-\{name}"
}

///|
test "build creates bundle skeleton files" {
  let repo = tmp_build_repo("repo")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_valid_config("\{repo}/cogna.yaml")
  let out = run({ repo, })
  guard out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("build should succeed")
  }

  inspect(
    result.display(),
    content="Generated CIQ bundle skeleton at /tmp/cogna-build-repo/dist",
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
  assert_true(has_64_hex(checksum_for(checksums, "metadata.json")))

  let declarations = read_text_main(
    "\{repo}/dist/declarations.ndjson",
    "declarations should exist",
  )
  assert_true(declarations.contains("\"kind\":\"bundle\""))
  assert_true(declarations.contains("\"signature\":\"bundle_root\""))

  let spdx = read_text_main(
    "\{repo}/.cogna/sbom.spdx.json",
    "spdx sbom should exist",
  )
  assert_true(spdx.contains("\"spdxVersion\": \"SPDX-2.3\""))
  assert_true(spdx.contains("\"packages\""))

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

  write_valid_v2_config("\{repo}/cogna.yml")
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
    dependency_manifest.contains("\"schemaVersion\": \"ciq-bundle/v1\""),
  )
  assert_true(
    dependency_manifest.contains("\"purl\": \"pkg:npm/react@18.2.0\""),
  )
  assert_true(!dependency_manifest.contains("\"declarationSchema\""))
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
test "build restores bundle skeleton from local cache on second run" {
  let repo = tmp_build_repo("local-cache-hit")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_valid_v2_config("\{repo}/cogna.yml")
  let first_out = run({ repo, })
  guard first_out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("first build should succeed")
  }
  ensure_file_removed("\{repo}/dist/manifest.json")
  ensure_file_removed("\{repo}/dist/declarations.ndjson")
  ensure_file_removed("\{repo}/dist/metadata.json")
  ensure_file_removed("\{repo}/dist/checksums.txt")
  ensure_file_removed("\{repo}/dist/bundle.ciq.tgz")

  let second_out = run({ repo, })
  guard second_out is Ok(result) else {
    cleanup_tmp_repo(repo)
    fail("second build should restore from cache")
  }

  inspect(
    result.display(),
    content="Restored CIQ bundle skeleton from local cache at /tmp/cogna-build-local-cache-hit/dist",
  )
  let manifest = read_text_main(
    "\{repo}/dist/manifest.json",
    "manifest should be restored from local cache",
  )
  assert_true(manifest.contains("\"schemaVersion\": \"ciq-bundle/v1\""))

  cleanup_tmp_repo(repo)
}

///|
test "build stores bundle in local cache after generation" {
  let repo = tmp_build_repo("local-cache-store")
  cleanup_tmp_repo(repo)
  @fs.create_dir(repo)

  write_valid_v2_config("\{repo}/cogna.yml")
  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_tmp_repo(repo)
    fail("build should succeed")
  }

  let cache_entries_out = @local_cache.list("\{repo}/.cogna/cache", prefix="build/")
  guard cache_entries_out is Ok(entries) else {
    cleanup_tmp_repo(repo)
    fail("local cache entries should be readable")
  }
  assert_true(entries.length() > 0)

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
  assert_true(text.contains("cogna.yml"))

  cleanup_tmp_repo(repo)
}
