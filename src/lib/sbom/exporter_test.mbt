///|
fn write_file(path : String, content : String) -> Unit {
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to write fixture")
  }
}

///|
fn cleanup_repo(repo : String) -> Unit {
  @fs.remove_file("\{repo}/codeiq.yaml") catch { _ => () }
  @fs.remove_file("\{repo}/package.json") catch { _ => () }
  @fs.remove_file("\{repo}/go.mod") catch { _ => () }
  @fs.remove_file("\{repo}/openapi.yaml") catch { _ => () }
  @fs.remove_dir(repo) catch { _ => () }
}

///|
test "sbom collects root dependency and source file components" {
  let repo = "src/lib/sbom/tmp_sbom_repo"
  cleanup_repo(repo)
  @fs.create_dir(repo)
  let config : @config.Config = {
    schema_version: "ciq-config/v1",
    profile: "openapi-spec",
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
    source: { repo: "https://github.com/acme/payment-api", source_ref: "main" },
    inputs: { include_paths: ["openapi.yaml"] },
    checks: { format: "sarif", policy: "default-compat" },
  }
  write_file(
    "\{repo}/package.json",
    Json::object({
      "name": Json::string("payment-api"),
      "version": Json::string("1.0.0"),
      "dependencies": Json::object({ "react": Json::string("18.2.0") }),
    }).stringify(indent=2),
  )
  write_file("\{repo}/openapi.yaml", "openapi: 3.1.0\ninfo:\n  title: Payment API\n")

  let components_out = collect_components(config, repo)
  guard components_out is Ok(components) else {
    cleanup_repo(repo)
    fail("collect_components should succeed")
  }
  inspect(components.length(), content="3")
  let artifacts = build_sbom_artifacts(components)
  assert_true(artifacts.components_ndjson.contains("pkg:npm/react@18.2.0"))
  assert_true(artifacts.components_ndjson.contains("component:file:openapi.yaml"))
  assert_true(artifacts.cyclonedx_json.contains("\"bomFormat\": \"CycloneDX\""))
  assert_true(artifacts.spdx_json.contains("\"@context\": \"https://spdx.org/rdf/3.0.1/spdx-context.jsonld\""))

  cleanup_repo(repo)
}
