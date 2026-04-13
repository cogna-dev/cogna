///|
extern "c" fn read_stdin_line_bytes() -> Bytes = "codeiq_read_stdin_line_ffi"

///|
pub fn read_stdin_line() -> String? {
  decode_stdin_line(read_stdin_line_bytes())
}
