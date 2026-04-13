///|
fn unsupported_shell_message() -> String {
  let timer : @async.Timer? = None
  ignore(timer)
  ignore(@aprocess.unimplemented)
  @utf8.decode_lossy(b"shell command execution is unsupported on this target")
}

///|
fn unsupported_detached_shell_message() -> String {
  let timer : @async.Timer? = None
  ignore(timer)
  ignore(@aprocess.unimplemented)
  @utf8.decode_lossy(b"detached shell execution is unsupported on this target")
}

///|
pub fn run_command_capture(command : String) -> (Int, String, String) {
  ignore(command)
  (127, "", unsupported_shell_message())
}

///|
pub fn spawn_detached(command : String) -> Result[Int, String] {
  ignore(command)
  Err(unsupported_detached_shell_message())
}

///|
pub fn is_alive(pid : Int) -> Bool {
  ignore(pid)
  false
}

///|
pub fn terminate(pid : Int) -> Bool {
  ignore(pid)
  false
}

///|
pub fn force_kill(pid : Int) -> Bool {
  ignore(pid)
  false
}

///|
pub fn sleep_ms(ms : Int) -> Unit {
  ignore(ms)
}
