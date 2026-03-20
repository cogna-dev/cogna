///|
pub fn default_config() -> Config {
  {
    schema_version: "ciq-config/v1",
    project: {
      name: "codeiq-project",
      version: "0.1.0",
      purl: "pkg:openapi/acme/payment-api@2026.03.01",
    },
    build: { profile: "openapi-spec", output_dir: "./dist" },
    diff: { since: "HEAD~1", include_test_changes: true },
  }
}
