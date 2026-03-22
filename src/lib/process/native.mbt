///|
#borrow(command)
extern "C" fn run_command_capture_ffi(command : Bytes) -> FixedArray[Bytes] = "codeiq_process_run_command_capture"

///|
fn bytes_to_string(bytes : Bytes) -> String {
  @utf8.decode(bytes) catch {
    _ => ""
  }
}

///|
fn string_to_bytes(text : String) -> Bytes {
  @utf8.encode("\{text}\u0000")
}

///|
pub fn run_command_capture(command : String) -> (Int, String, String) {
  let fields = run_command_capture_ffi(string_to_bytes(command))
  if fields.length() < 3 {
    return (127, "", "process ffi returned invalid response")
  }
  let exit_code_text = bytes_to_string(fields[0])
  let parsed = try? @strconv.parse_int(exit_code_text)
  let exit_code = match parsed {
    Ok(value) => value
    Err(_) => 127
  }
  (exit_code, bytes_to_string(fields[1]), bytes_to_string(fields[2]))
}
