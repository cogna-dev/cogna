///|
pub fn write_config(path : String) -> Unit raise @fs.IOError {
  @fs.write_string_to_file(path, default_config_yaml())
}
