///|
pub fn default_config_yaml() -> String {
  (
    #|schemaVersion: ciq-config/v2
    #|profile: openapi-spec
    #|validation: none
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
    #|  storeDir: .cogna/cache/registry
    #|mcp:
    #|  port: 3000
    #|
  )
}
