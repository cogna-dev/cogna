///|
pub fn validate(config : Config, path : String) -> Result[Config, ConfigError] {
  if config.schema_version != "ciq-config/v1" {
    Err(
      ConfigError::ValidationError(
        path~,
        "schema_version must be ciq-config/v1",
      ),
    )
  } else if config.project.name == "" {
    Err(ConfigError::ValidationError(path~, "project.name must not be empty"))
  } else if config.project.version == "" {
    Err(
      ConfigError::ValidationError(path~, "project.version must not be empty"),
    )
  } else if !config.project.purl.has_prefix("pkg:") {
    Err(
      ConfigError::ValidationError(path~, "project.purl must start with pkg:"),
    )
  } else if config.build.profile == "" {
    Err(ConfigError::ValidationError(path~, "build.profile must not be empty"))
  } else if config.build.output_dir == "" {
    Err(
      ConfigError::ValidationError(path~, "build.output_dir must not be empty"),
    )
  } else if config.diff.since == "" {
    Err(ConfigError::ValidationError(path~, "diff.since must not be empty"))
  } else {
    Ok(config)
  }
}
