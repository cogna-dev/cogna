///|
pub fn default_config_yaml_for_profile(profile : String) -> String {
  let (purl, include_glob) = match profile {
    "go-module" => (
      "pkg:golang/acme/example@0.1.0",
      "**/*.go",
    )
    "rust-crate" => (
      "pkg:cargo/acme/example@0.1.0",
      "**/*.rs",
    )
    "terraform-module" => (
      "pkg:terraform/acme/example@0.1.0",
      "**/*.tf",
    )
    _ => (
      "pkg:openapi/acme/payment-api@2026.03.01",
      "openapi/**/*.yaml",
    )
  }

  let template = (
    #|schemaVersion: ciq-config/v2
    #|profile: __PROFILE__
    #|validation: none
    #|purl: __PURL__
    #|source:
    #|  repo: https://github.com/acme/example
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - __INCLUDE__
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
  )
  template
  .replace_all(old="__PROFILE__", new=profile)
  .replace_all(old="__PURL__", new=purl)
  .replace_all(old="__INCLUDE__", new=include_glob)
}

///|
pub fn default_config_yaml() -> String {
  default_config_yaml_for_profile("openapi-spec")
}
