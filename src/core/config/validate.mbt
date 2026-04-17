///|
fn has_disallowed_input_path(paths : Array[String]) -> Bool {
  for i = 0; i < paths.length(); i = i + 1 {
    let input_path = paths[i]
    if input_path.contains("README") ||
      input_path.contains("readme") ||
      input_path.contains("example") ||
      input_path.contains("examples") {
      return true
    }
  }
  false
}

///|
fn is_supported_profile(profile : String) -> Bool {
  match profile {
    "openapi-spec" | "go-module" | "rust-crate" | "terraform-module" |
    "policy-bundle" => true
    _ => false
  }
}

///|
pub fn validate(config : Config, path : String) -> Result[Config, ConfigError] {
  if config.schema_version != "ciq-config/v1" &&
    config.schema_version != "ciq-config/v2" {
    Err(
      ConfigError::ValidationError(
        path~,
        "schemaVersion must be ciq-config/v1 or ciq-config/v2",
      ),
    )
  } else if !is_supported_profile(config.profile) {
    Err(ConfigError::ValidationError(path~, "$.profile: value is not in enum"))
  } else if config.purl == "" {
    Err(ConfigError::ValidationError(path~, "purl must not be empty"))
  } else if !config.purl.has_prefix("pkg:") {
    Err(ConfigError::ValidationError(path~, "purl must start with pkg:"))
  } else if config.source.repo == "" {
    Err(ConfigError::ValidationError(path~, "source.repo must not be empty"))
  } else if config.source.source_ref == "" {
    Err(ConfigError::ValidationError(path~, "source.ref must not be empty"))
  } else if config.inputs.include_paths.is_empty() {
    Err(ConfigError::ValidationError(path~, "inputs.include must not be empty"))
  } else if has_disallowed_input_path(config.inputs.include_paths) {
    Err(
      ConfigError::ValidationError(
        path~,
        "inputs.include must reference code/spec files only (no README/example paths)",
      ),
    )
  } else if config.checks.format != "sarif" {
    Err(ConfigError::ValidationError(path~, "checks.format must be sarif"))
  } else if config.checks.policy == "" {
    Err(ConfigError::ValidationError(path~, "checks.policy must not be empty"))
  } else if config.validation != "none" && config.validation != "lsp" {
    Err(ConfigError::ValidationError(path~, "validation must be none or lsp"))
  } else if config.schema_version == "ciq-config/v2" &&
    config.sbom.format != "spdx" {
    Err(ConfigError::ValidationError(path~, "sbom.format must be spdx"))
  } else if config.schema_version == "ciq-config/v2" &&
    config.cache.type_ != "local" && config.cache.type_ != "http" {
    Err(ConfigError::ValidationError(path~, "cache.type must be local or http"))
  } else if config.schema_version == "ciq-config/v2" &&
    config.cache.local_store.store_dir == "" {
    Err(
      ConfigError::ValidationError(path~, "cache.local.storeDir must not be empty"),
    )
  } else if config.schema_version == "ciq-config/v2" &&
    config.cache.type_ == "http" && config.cache.http.base_url == "" {
    Err(
      ConfigError::ValidationError(path~, "cache.http.baseUrl must not be empty"),
    )
  } else if config.schema_version == "ciq-config/v2" &&
    config.cache.http.timeout_ms <= 0 {
    Err(
      ConfigError::ValidationError(path~, "cache.http.timeoutMs must be positive"),
    )
  } else if config.schema_version == "ciq-config/v2" &&
    (config.mcp.port <= 0 || config.mcp.port > 65535) {
    Err(
      ConfigError::ValidationError(path~, "mcp.port must be in range 1..65535"),
    )
  } else {
    Ok(config)
  }
}
