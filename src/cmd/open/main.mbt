///|
pub(all) struct OpenParams {
  folder : String
} derive(Eq)

///|
pub impl Show for OpenParams with output(self, logger) {
  logger.write_string("{folder: ")
  logger.write_object(self.folder)
  logger.write_char('}')
}

///|
pub(all) struct OpenResult {
  folder : String
  summary : String
} derive(Eq)

///|
pub impl Show for OpenResult with output(self, logger) {
  logger.write_string("{folder: ")
  logger.write_object(self.folder)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for OpenResult with display(self : OpenResult) -> String {
  self.summary
}

///|
fn open_error(message : String) -> @cli.CliError {
  @cli.command_error("open failed: \{message}")
}

///|
fn current_dir_path() -> String {
  @env.current_dir().unwrap_or(".")
}

///|
fn shell_quote(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn absolute_folder_path(folder : String) -> String {
  @config.resolve_project_path(current_dir_path(), folder)
}

///|
fn ensure_directory(path : String) -> Result[Unit, @cli.CliError] {
  if !@fs.path_exists(path) {
    return Err(open_error("folder does not exist: \{path}"))
  }
  let dir_out = try? @fs.is_dir(path)
  match dir_out {
    Ok(true) => Ok(())
    Ok(false) => Err(open_error("path is not a directory: \{path}"))
    Err(err) => Err(open_error("cannot inspect \{path}: \{err.to_string()}"))
  }
}

///|
fn hex_digit(value : Int) -> String {
  if value < 10 {
    "\{value}"
  } else {
    match value {
      10 => "A"
      11 => "B"
      12 => "C"
      13 => "D"
      14 => "E"
      _ => "F"
    }
  }
}

///|
fn percent_encode(value : String) -> String {
  let bytes = @utf8.encode(value)
  let encoded = StringBuilder::new()
  for i in 0..<bytes.length() {
    let byte = bytes[i].to_int()
    let keep = (byte >= 'a'.to_int() && byte <= 'z'.to_int()) ||
      (byte >= 'A'.to_int() && byte <= 'Z'.to_int()) ||
      (byte >= '0'.to_int() && byte <= '9'.to_int()) ||
      byte == '-'.to_int() ||
      byte == '_'.to_int() ||
      byte == '.'.to_int() ||
      byte == '~'.to_int()
    if keep {
      encoded.write_char(byte.unsafe_to_char())
    } else {
      encoded.write_char('%')
      encoded.write_string(hex_digit(byte / 16))
      encoded.write_string(hex_digit(byte % 16))
    }
  }
  encoded.to_string()
}

///|
fn deep_link_url(folder : String) -> String {
  "cogna://open?folder=\{percent_encode(folder)}"
}

///|
fn open_command(url : String) -> String {
  let quoted = shell_quote(url)
  let fallback = (
    #|
    #|else
    #|  exit 127
    #|fi
  )
  let script =
    (
    #|if command -v open >/dev/null 2>&1; then
    #|  open 
  ).add(quoted)
    .add(
      (
      #|
      #|elif command -v xdg-open >/dev/null 2>&1; then
      #|  xdg-open 
      ),
    )
    .add(quoted)
    .add(
      (
      #|
      #|elif command -v cmd.exe >/dev/null 2>&1; then
      #|  cmd.exe /c start "" 
      ),
    )
    .add(quoted)
    .add(fallback)
  script
}

///|
pub fn run(params : OpenParams) -> @cli.CliResult[OpenResult, @cli.CliError] {
  let folder = absolute_folder_path(params.folder)
  let validate_out = ensure_directory(folder)
  guard validate_out is Ok(_) else { return Err(validate_out.unwrap_err()) }

  let url = deep_link_url(folder)
  let (exit_code, _, stderr) = @process.run_command_capture(open_command(url))
  if exit_code != 0 {
    let detail = if stderr.trim().to_string() == "" {
      "desktop protocol handler is not available"
    } else {
      stderr.trim().to_string()
    }
    return Err(open_error(detail))
  }

  Ok({
    folder,
    summary: "Requested Cogna Desktop to open \{folder}",
  })
}
