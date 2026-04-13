///|
pub(all) struct CliError {
  code : Int
  message : String
} derive(Eq)

///|
pub impl Show for CliError with output(self, logger) {
  logger.write_string("{code: ")
  logger.write_object(self.code)
  logger.write_string(", message: ")
  logger.write_object(self.message)
  logger.write_char('}')
}

///|
pub fn usage_error(message : String) -> CliError {
  { code: 64, message: "usage error: \{message}" }
}

///|
pub fn config_error(message : String) -> CliError {
  { code: 78, message: "config error: \{message}" }
}

///|
pub fn command_error(message : String) -> CliError {
  { code: 1, message: "command error: \{message}" }
}

///|
pub fn internal_error(message : String) -> CliError {
  { code: 1, message: "internal error: \{message}" }
}

///|
pub fn exit_code(error : CliError) -> Int {
  error.code
}

///|
pub fn to_text(error : CliError) -> String {
  error.message
}
