///|
pub fn ciq_config_v1_schema() -> @json_schema.JsonSchema {
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "ciq-config/v1",
    "type": "object",
    "required": [
      "schemaVersion", "profile", "purl", "source", "inputs", "checks",
    ],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-config/v1" },
      "profile": {
        "type": "string",
        "enum": [
          "go-module", "rust-crate", "terraform-module", "openapi-spec", "policy-bundle",
        ],
      },
      "validation": {
        "type": "string",
        "enum": ["none", "lsp"],
      },
      "purl": { "type": "string", "minLength": 1 },
      "source": {
        "type": "object",
        "required": ["repo", "ref"],
        "properties": {
          "repo": { "type": "string", "minLength": 1 },
          "ref": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "inputs": {
        "type": "object",
        "required": ["include"],
        "properties": {
          "include": {
            "type": "array",
            "minItems": 1,
            "items": { "type": "string", "minLength": 1 },
          },
        },
        "additionalProperties": false,
      },
      "checks": {
        "type": "object",
        "required": ["format", "policy"],
        "properties": {
          "format": { "type": "string", "const": "sarif" },
          "policy": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn ciq_config_v2_schema() -> @json_schema.JsonSchema {
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "ciq-config/v2",
    "type": "object",
    "required": [
      "schemaVersion", "profile", "purl", "source", "inputs", "checks", "diff", "sbom",
      "publish", "registry", "mcp",
    ],
    "properties": {
      "schemaVersion": { "type": "string", "const": "ciq-config/v2" },
      "profile": {
        "type": "string",
        "enum": [
          "go-module", "rust-crate", "terraform-module", "openapi-spec", "policy-bundle",
        ],
      },
      "validation": {
        "type": "string",
        "enum": ["none", "lsp"],
      },
      "purl": { "type": "string", "minLength": 1 },
      "source": {
        "type": "object",
        "required": ["repo", "ref"],
        "properties": {
          "repo": { "type": "string", "minLength": 1 },
          "ref": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "inputs": {
        "type": "object",
        "required": ["include"],
        "properties": {
          "include": {
            "type": "array",
            "minItems": 1,
            "items": { "type": "string", "minLength": 1 },
          },
        },
        "additionalProperties": false,
      },
      "checks": {
        "type": "object",
        "required": ["format", "policy"],
        "properties": {
          "format": { "type": "string", "const": "sarif" },
          "policy": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "diff": {
        "type": "object",
        "required": ["includeTestChanges"],
        "properties": {
          "since": { "type": "string", "minLength": 1 },
          "includeTestChanges": { "type": "boolean" },
        },
        "additionalProperties": false,
      },
      "sbom": {
        "type": "object",
        "required": ["format", "dependencyBundles", "requireLocalPackages"],
        "properties": {
          "format": { "type": "string", "const": "spdx" },
          "dependencyBundles": { "type": "boolean" },
          "requireLocalPackages": { "type": "boolean" },
        },
        "additionalProperties": false,
      },
      "publish": {
        "type": "object",
        "required": ["includeDependencies"],
        "properties": { "includeDependencies": { "type": "boolean" } },
        "additionalProperties": false,
      },
      "registry": {
        "type": "object",
        "required": ["port", "storeDir"],
        "properties": {
          "port": { "type": "number" },
          "storeDir": { "type": "string", "minLength": 1 },
        },
        "additionalProperties": false,
      },
      "mcp": {
        "type": "object",
        "required": ["port"],
        "properties": { "port": { "type": "number" } },
        "additionalProperties": false,
      },
    },
    "additionalProperties": false,
  }
}

///|
pub fn config_to_json(config : Config) -> Json {
  if config.schema_version == "ciq-config/v1" {
    {
      "schemaVersion": config.schema_version,
      "profile": config.profile,
      "validation": config.validation,
      "purl": config.purl,
      "source": { "repo": config.source.repo, "ref": config.source.source_ref },
      "inputs": { "include": config.inputs.include_paths },
      "checks": {
        "format": config.checks.format,
        "policy": config.checks.policy,
      },
    }
  } else {
    let diff : Map[String, Json] = {
      "includeTestChanges": Json::boolean(config.diff.include_test_changes),
    }
    if config.diff.since is Some(since) {
      diff["since"] = Json::string(since)
    }
    {
      "schemaVersion": config.schema_version,
      "profile": config.profile,
      "validation": config.validation,
      "purl": config.purl,
      "source": { "repo": config.source.repo, "ref": config.source.source_ref },
      "inputs": { "include": config.inputs.include_paths },
      "checks": {
        "format": config.checks.format,
        "policy": config.checks.policy,
      },
      "diff": Json::object(diff),
      "sbom": {
        "format": config.sbom.format,
        "dependencyBundles": config.sbom.dependency_bundles,
        "requireLocalPackages": config.sbom.require_local_packages,
      },
      "publish": { "includeDependencies": config.publish.include_dependencies },
      "registry": {
        "port": config.registry.port,
        "storeDir": config.registry.store_dir,
      },
      "mcp": { "port": config.mcp.port },
    }
  }
}
