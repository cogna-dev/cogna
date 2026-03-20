///|
pub fn default_config() -> Config {
  {
    schema_version: "ciq-config/v1",
    profile: "openapi-spec",
    purl: "pkg:openapi/acme/payment-api@2026.03.01",
    source: { repo: "https://github.com/acme/payment-api", source_ref: "main" },
    inputs: { include_paths: ["openapi/**/*.yaml"] },
    checks: { format: "sarif", policy: "default-compat" },
  }
}
