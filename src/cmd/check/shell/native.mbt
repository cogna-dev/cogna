///|
pub fn run_command_capture(command : String) -> (Int, String, String) {
  let result : Ref[(Int, String, String)?] = Ref::new(None)
  @async.run_async_main(() => {
    let value = try {
      let (exit_code, stdout_data, stderr_data) = @aprocess.collect_output(
        "sh",
        ["-c", command],
      )
      let stdout = @utf8.decode_lossy(stdout_data.binary())
      let stderr = @utf8.decode_lossy(stderr_data.binary())
      (exit_code, stdout, stderr)
    } catch {
      err => (127, "", err.to_string())
    }
    result.val = Some(value)
  })
  match result.val {
    Some(value) => value
    None => (127, "", "async shell execution did not produce result")
  }
}
