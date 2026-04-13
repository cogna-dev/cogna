///|
pub(all) struct Logger {
  color : Bool
} derive(Eq)

///|
pub impl Show for Logger with output(self, logger) {
  logger.write_string("{color: ")
  logger.write_object(self.color)
  logger.write_char('}')
}

///|
const ANSI_RESET : String = "\u001b[0m"

///|
const ANSI_RED : String = "\u001b[31m"

///|
const ANSI_YELLOW : String = "\u001b[33m"

///|
const ANSI_BLUE : String = "\u001b[34m"

///|
const ANSI_GREEN : String = "\u001b[32m"

///|
pub fn new_logger(no_color? : Bool = false) -> Logger {
  { color: !no_color }
}

///|
fn wrap(color : Bool, code : String, text : String) -> String {
  if color {
    "\{code}\{text}\{ANSI_RESET}"
  } else {
    text
  }
}

///|
pub fn Logger::info(self : Logger, text : String) -> Unit {
  ignore(self)
  println(wrap(self.color, ANSI_BLUE, "info: \{text}"))
}

///|
pub fn Logger::success(self : Logger, text : String) -> Unit {
  ignore(self)
  println(wrap(self.color, ANSI_GREEN, "success: \{text}"))
}

///|
pub fn Logger::warn(self : Logger, text : String) -> Unit {
  ignore(self)
  println(wrap(self.color, ANSI_YELLOW, "warning: \{text}"))
}

///|
pub fn Logger::error(self : Logger, text : String) -> Unit {
  ignore(self)
  println(wrap(self.color, ANSI_RED, "error: \{text}"))
}
