///|
fn unsupported_shell_message() -> String {
  let timer : @async.Timer? = None
  ignore(timer)
  ignore(@aprocess.unimplemented)
  @utf8.decode_lossy(b"shell command execution is unsupported on this target")
}

///|
pub fn run_command_capture(command : String) -> (Int, String, String) {
  ignore(command)
  (127, "", unsupported_shell_message())
}
