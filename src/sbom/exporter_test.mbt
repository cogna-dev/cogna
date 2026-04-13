///|
fn write_file(path : String, content : String) -> Unit {
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to write fixture")
  }
}

///|
fn cleanup_repo(repo : String) -> Unit {
  @fs.remove_file("\{repo}/codeiq.yml") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/codeiq.yaml") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/package.json") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/go.mod") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/openapi.yaml") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/localpkg/package.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/localpkg") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/node_modules/react/package.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/node_modules/react") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/node_modules") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "sbom collects root dependency and source file components" {
  let repo = "src/lib/sbom/tmp_sbom_repo"
  cleanup_repo(repo)
  @fs.create_dir(repo)
  let config : @config.Config = {
    schema_version: "ciq-config/v2",
    profile: "openapi-spec",
    validation: "none",
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
    source: { repo: "https://github.com/acme/payment-api", source_ref: "main" },
    inputs: { include_paths: ["openapi.yaml"] },
    checks: { format: "sarif", policy: "./dist/policy.ciq.tgz" },
    diff: { since: None, include_test_changes: false },
    sbom: {
      format: "spdx",
      dependency_bundles: true,
      require_local_packages: true,
    },
    publish: { include_dependencies: true },
    registry: { port: 8787, store_dir: ".codeiq/cache/registry" },
    mcp: { port: 3000 },
  }
  write_file(
    "\{repo}/package.json",
    Json::object({
      "name": Json::string("payment-api"),
      "version": Json::string("1.0.0"),
      "dependencies": Json::object({ "react": Json::string("18.2.0") }),
    }).stringify(indent=2),
  )
  let node_modules_out = try? @fs.create_dir("\{repo}/node_modules")
  guard node_modules_out is Ok(_) else {
    cleanup_repo(repo)
    fail("failed to create node_modules")
  }
  let react_dir_out = try? @fs.create_dir("\{repo}/node_modules/react")
  guard react_dir_out is Ok(_) else {
    cleanup_repo(repo)
    fail("failed to create react package")
  }
  write_file(
    "\{repo}/node_modules/react/package.json",
    Json::object({
      "name": Json::string("react"),
      "version": Json::string("18.2.0"),
    }).stringify(indent=2),
  )
  write_file(
    "\{repo}/openapi.yaml",
    "openapi: 3.1.0\ninfo:\n  title: Payment API\n",
  )

  let components_out = collect_components(config, repo)
  guard components_out is Ok(components) else {
    cleanup_repo(repo)
    fail("collect_components should succeed")
  }
  inspect(components.length(), content="3")
  let artifacts = build_sbom_artifacts(components)
  assert_true(artifacts.components_ndjson.contains("pkg:npm/react@18.2.0"))
  assert_true(
    artifacts.components_ndjson.contains("component:file:openapi.yaml"),
  )
  assert_true(
    artifacts.spdx_json.contains(
      "\"@context\": \"https://spdx.org/rdf/3.0.1/spdx-context.jsonld\"",
    ),
  )

  cleanup_repo(repo)
}

///|
test "sbom resolves local npm dependency evidence and hashes" {
  let repo = "src/lib/sbom/tmp_sbom_local_repo"
  cleanup_repo(repo)
  @fs.create_dir(repo)
  let local_pkg_out = try? @fs.create_dir("\{repo}/localpkg")
  guard local_pkg_out is Ok(_) else {
    cleanup_repo(repo)
    fail("failed to create local package dir")
  }
  let config : @config.Config = {
    schema_version: "ciq-config/v2",
    profile: "openapi-spec",
    validation: "none",
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
    source: { repo: "https://github.com/acme/payment-api", source_ref: "main" },
    inputs: { include_paths: ["openapi.yaml"] },
    checks: { format: "sarif", policy: "./dist/policy.ciq.tgz" },
    diff: { since: None, include_test_changes: false },
    sbom: {
      format: "spdx",
      dependency_bundles: true,
      require_local_packages: true,
    },
    publish: { include_dependencies: true },
    registry: { port: 8787, store_dir: ".codeiq/cache/registry" },
    mcp: { port: 3000 },
  }
  write_file(
    "\{repo}/package.json",
    Json::object({
      "name": Json::string("payment-api"),
      "version": Json::string("1.0.0"),
      "dependencies": Json::object({
        "localpkg": Json::string("file:./localpkg"),
      }),
    }).stringify(indent=2),
  )
  write_file(
    "\{repo}/localpkg/package.json",
    Json::object({
      "name": Json::string("localpkg"),
      "version": Json::string("0.4.0"),
    }).stringify(indent=2),
  )
  write_file(
    "\{repo}/openapi.yaml",
    "openapi: 3.1.0\ninfo:\n  title: Payment API\n",
  )

  let components_out = collect_components(config, repo)
  guard components_out is Ok(components) else {
    cleanup_repo(repo)
    fail("collect_components should resolve local package")
  }
  let artifacts = build_sbom_artifacts(components)
  assert_true(artifacts.components_ndjson.contains("pkg:npm/localpkg@0.4.0"))
  assert_true(artifacts.components_ndjson.contains("\"path\":\"localpkg\""))
  assert_true(artifacts.components_ndjson.contains("\"hashes\":[{"))
  assert_true(
    artifacts.spdx_json.contains("\"software_downloadLocation\": \"localpkg\""),
  )
  assert_true(artifacts.spdx_json.contains("\"verifiedUsing\""))

  cleanup_repo(repo)
}

///|
test "sbom fails when local npm dependency content is missing" {
  let repo = "src/lib/sbom/tmp_sbom_missing_local_repo"
  cleanup_repo(repo)
  @fs.create_dir(repo)
  let config : @config.Config = {
    schema_version: "ciq-config/v2",
    profile: "openapi-spec",
    validation: "none",
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
    source: { repo: "https://github.com/acme/payment-api", source_ref: "main" },
    inputs: { include_paths: ["openapi.yaml"] },
    checks: { format: "sarif", policy: "./dist/policy.ciq.tgz" },
    diff: { since: None, include_test_changes: false },
    sbom: {
      format: "spdx",
      dependency_bundles: true,
      require_local_packages: true,
    },
    publish: { include_dependencies: true },
    registry: { port: 8787, store_dir: ".codeiq/cache/registry" },
    mcp: { port: 3000 },
  }
  write_file(
    "\{repo}/package.json",
    Json::object({
      "name": Json::string("payment-api"),
      "version": Json::string("1.0.0"),
      "dependencies": Json::object({
        "localpkg": Json::string("file:./localpkg"),
      }),
    }).stringify(indent=2),
  )
  write_file(
    "\{repo}/openapi.yaml",
    "openapi: 3.1.0\ninfo:\n  title: Payment API\n",
  )

  let components_out = collect_components(config, repo)
  guard components_out is Err(message) else {
    cleanup_repo(repo)
    fail("collect_components should fail when local package missing")
  }
  assert_true(message.contains("local npm package localpkg not found"))

  cleanup_repo(repo)
}
