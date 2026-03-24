///|
pub fn run_command_capture(command : String) -> (Int, String, String) {
  ignore(@utf8.encode(command))
  (127, "", "shell command execution is unsupported on wasm target")
}

///|
pub fn spawn_detached(command : String) -> Result[Int, String] {
  ignore(@utf8.encode(command))
  Err("detached shell execution is unsupported on wasm target")
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
