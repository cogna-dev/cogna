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
pub fn validate(config : Config, path : String) -> Result[Config, ConfigError] {
  if config.schema_version != "ciq-config/v1" {
    Err(
      ConfigError::ValidationError(
        path~,
        "schema_version must be ciq-config/v1",
      ),
    )
  } else if config.profile != "go-module" &&
    config.profile != "rust-crate" &&
    config.profile != "terraform-module" &&
    config.profile != "openapi-spec" {
    Err(
      ConfigError::ValidationError(
        path~,
        "profile must be one of go-module, rust-crate, terraform-module, openapi-spec",
      ),
    )
  } else if !config.purl.has_prefix("pkg:") {
    Err(ConfigError::ValidationError(path~, "purl must start with pkg:"))
  } else if config.source.repo == "" {
    Err(ConfigError::ValidationError(path~, "source.repo must not be empty"))
  } else if config.source.source_ref == "" {
    Err(ConfigError::ValidationError(path~, "source.ref must not be empty"))
  } else if config.inputs.include_paths.length() == 0 {
    Err(
      ConfigError::ValidationError(
        path~,
        "inputs.include must have at least one path",
      ),
    )
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
  } else {
    Ok(config)
  }
}
