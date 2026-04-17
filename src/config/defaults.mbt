///|
pub fn default_config() -> Config {
  {
    schema_version: "ciq-config/v2",
    profile: "openapi-spec",
    validation: "none",
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
    source: { repo: "https://github.com/acme/payment-api", source_ref: "main" },
    inputs: { include_paths: ["openapi/**/*.yaml"] },
    checks: { format: "sarif", policy: "./policies" },
    diff: { since: None, include_test_changes: false },
    sbom: {
      format: "spdx",
      dependency_bundles: true,
      require_local_packages: true,
    },
    publish: { include_dependencies: true },
    registry: { port: 8787, store_dir: ".cogna/cache/registry" },
    mcp: { port: 3000 },
  }
}
