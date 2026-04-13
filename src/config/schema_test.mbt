///|
test "ciq-config/v2 schema validates default config JSON" {
  let schema = ciq_config_v2_schema()
  let instance = config_to_json(default_config())
  let out = @json_schema.validate_json(schema, instance)
  guard out is Ok(_) else { fail("default config should satisfy ciq schema") }
}

///|
test "ciq-config/v2 schema rejects missing required field" {
  let schema = ciq_config_v2_schema()
  let instance : Json = {
    "schemaVersion": "ciq-config/v2",
    "profile": "openapi-spec",
    "purl": "pkg:openapi/acme/payment-api@2026.03.01",
    "source": { "repo": "https://github.com/acme/payment-api", "ref": "main" },
    "checks": { "format": "sarif", "policy": "default-compat" },
  }
  let out = @json_schema.validate_json(schema, instance)
  guard out is Err(error) else { fail("missing inputs should fail") }
  guard error.to_string().contains("missing required property inputs") else {
    fail("expected missing required property error")
  }
}

///|
test "ciq-config/v1 schema rejects additional property" {
  let schema = ciq_config_v1_schema()
  let instance : Json = {
    "schemaVersion": "ciq-config/v1",
    "profile": "openapi-spec",
    "purl": "pkg:openapi/acme/payment-api@2026.03.01",
    "source": {
      "repo": "https://github.com/acme/payment-api",
      "ref": "main",
      "extra": true,
    },
    "inputs": { "include": ["openapi/**/*.yaml"] },
    "checks": { "format": "sarif", "policy": "default-compat" },
  }
  let out = @json_schema.validate_json(schema, instance)
  guard out is Err(error) else { fail("additional property should fail") }
  guard error.to_string().contains("additional property extra is not allowed") else {
    fail("expected additional property error")
  }
}

///|
test "ciq-config/v1 schema still validates legacy config shape" {
  let schema = ciq_config_v1_schema()
  let instance : Json = {
    "schemaVersion": "ciq-config/v1",
    "profile": "openapi-spec",
    "purl": "pkg:openapi/acme/payment-api@2026.03.01",
    "source": { "repo": "https://github.com/acme/payment-api", "ref": "main" },
    "inputs": { "include": ["openapi/**/*.yaml"] },
    "checks": { "format": "sarif", "policy": "default-compat" },
  }
  let out = @json_schema.validate_json(schema, instance)
  guard out is Ok(_) else { fail("legacy config should satisfy v1 schema") }
}

///|
test "ciq-config/v2 schema accepts validation mode" {
  let schema = ciq_config_v2_schema()
  let instance : Json = {
    "schemaVersion": "ciq-config/v2",
    "profile": "go-module",
    "validation": "lsp",
    "purl": "pkg:golang/acme/demo@0.1.0",
    "source": { "repo": "https://github.com/acme/demo", "ref": "main" },
    "inputs": { "include": ["**/*.go"] },
    "checks": { "format": "sarif", "policy": "default-compat" },
    "diff": { "includeTestChanges": false },
    "sbom": {
      "format": "spdx",
      "dependencyBundles": true,
      "requireLocalPackages": true,
    },
    "publish": { "includeDependencies": true },
    "registry": { "port": 8787, "storeDir": ".codeiq/cache/registry" },
    "mcp": { "port": 3000 },
  }
  let out = @json_schema.validate_json(schema, instance)
  guard out is Ok(_) else { fail("validation mode should satisfy v2 schema") }
}

///|
test "ciq-config/v2 schema rejects unsupported validation mode" {
  let schema = ciq_config_v2_schema()
  let instance : Json = {
    "schemaVersion": "ciq-config/v2",
    "profile": "go-module",
    "validation": "native",
    "purl": "pkg:golang/acme/demo@0.1.0",
    "source": { "repo": "https://github.com/acme/demo", "ref": "main" },
    "inputs": { "include": ["**/*.go"] },
    "checks": { "format": "sarif", "policy": "default-compat" },
    "diff": { "includeTestChanges": false },
    "sbom": {
      "format": "spdx",
      "dependencyBundles": true,
      "requireLocalPackages": true,
    },
    "publish": { "includeDependencies": true },
    "registry": { "port": 8787, "storeDir": ".codeiq/cache/registry" },
    "mcp": { "port": 3000 },
  }
  let out = @json_schema.validate_json(schema, instance)
  guard out is Err(error) else { fail("unsupported validation mode should fail") }
  guard error.to_string().contains("validation") &&
    error.to_string().contains("enum") else {
    fail("expected validation enum error")
  }
}
