///|
pub(all) struct CliError {
  code : Int
  message : String
} derive(Show, Eq)

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
