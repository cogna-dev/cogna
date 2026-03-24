///|
extern "c" fn read_stdin_line_bytes() -> Bytes = "codeiq_read_stdin_line_ffi"

///|
pub fn read_stdin_line() -> String? {
  let bytes = read_stdin_line_bytes()
  if bytes.length() == 0 {
    None
  } else {
    Some(@utf8.decode_lossy(bytes))
  }
}
