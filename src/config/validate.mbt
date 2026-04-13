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
fn schema_error_message(error : @json_schema.SchemaError) -> String {
  match error {
    @json_schema.SchemaParseError(message) => "schema parse error: \{message}"
    @json_schema.InvalidSchema(message) => "invalid schema: \{message}"
    @json_schema.ValidationFailed(issues) =>
      if issues.length() == 0 {
        "validation failed"
      } else {
        let first = issues[0]
        "\{first.path}: \{first.message}"
      }
  }
}

///|
pub fn validate(config : Config, path : String) -> Result[Config, ConfigError] {
  let instance = config_to_json(config)
  let schema = match config.schema_version {
    "ciq-config/v1" => ciq_config_v1_schema()
    "ciq-config/v2" => ciq_config_v2_schema()
    _ =>
      return Err(
        ConfigError::ValidationError(
          path~,
          "schemaVersion must be ciq-config/v1 or ciq-config/v2",
        ),
      )
  }
  let schema_out = @json_schema.validate_json(schema, instance)
  if schema_out is Err(error) {
    Err(ConfigError::ValidationError(path~, schema_error_message(error)))
  } else if !config.purl.has_prefix("pkg:") {
    Err(ConfigError::ValidationError(path~, "purl must start with pkg:"))
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
  } else if config.schema_version == "ciq-config/v2" &&
    config.sbom.format != "spdx" {
    Err(ConfigError::ValidationError(path~, "sbom.format must be spdx"))
  } else if config.schema_version == "ciq-config/v2" &&
    (config.registry.port <= 0 || config.registry.port > 65535) {
    Err(
      ConfigError::ValidationError(
        path~,
        "registry.port must be in range 1..65535",
      ),
    )
  } else if config.schema_version == "ciq-config/v2" &&
    (config.mcp.port <= 0 || config.mcp.port > 65535) {
    Err(
      ConfigError::ValidationError(path~, "mcp.port must be in range 1..65535"),
    )
  } else if config.schema_version == "ciq-config/v2" &&
    config.registry.store_dir == "" {
    Err(
      ConfigError::ValidationError(path~, "registry.storeDir must not be empty"),
    )
  } else {
    Ok(config)
  }
}
