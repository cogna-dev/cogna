///|
pub fn load_from_path(path : String) -> Result[Config, ConfigError] {
  let _file_content = @fs.read_file_to_string(path) catch {
    err => return Err(ConfigError::FileReadError(path~, err.to_string()))
  }
  validate(default_config(), path)
}
