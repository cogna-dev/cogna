///|
fn detached_shell_command(command : String) -> String {
  "exec </dev/null >/dev/null 2>&1; ".add(command)
}

///|
pub fn run_command_capture(command : String) -> (Int, String, String) {
  let result : Ref[(Int, String, String)?] = Ref::new(None)
  @mbasync.run_async_main(() => {
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

///|
pub fn spawn_detached(command : String) -> Result[Int, String] {
  let result : Ref[Result[Int, String]?] = Ref::new(None)
  @mbasync.run_async_main(() => {
    let value = Ok(
      @aprocess.spawn_orphan("sh", ["-c", detached_shell_command(command)]),
    ) catch {
      err => Err(err.to_string())
    }
    result.val = Some(value)
  })
  match result.val {
    Some(value) => value
    None => Err("detached spawn did not produce result")
  }
}

///|
pub fn is_alive(pid : Int) -> Bool {
  if pid <= 0 {
    return false
  }
  let command = "kill -0 \{pid} >/dev/null 2>&1 && ps -o stat= -p \{pid} 2>/dev/null | grep -qv '^Z'"
  let (exit_code, _, _) = run_command_capture(command)
  exit_code == 0
}

///|
pub fn terminate(pid : Int) -> Bool {
  if pid <= 0 {
    return false
  }
  let (exit_code, _, _) = run_command_capture(
    "kill -TERM \{pid} >/dev/null 2>&1",
  )
  exit_code == 0
}

///|
pub fn force_kill(pid : Int) -> Bool {
  if pid <= 0 {
    return false
  }
  let (exit_code, _, _) = run_command_capture(
    "kill -KILL \{pid} >/dev/null 2>&1",
  )
  exit_code == 0
}

///|
pub fn sleep_ms(ms : Int) -> Unit {
  if ms <= 0 {
    return
  }
  @mbasync.run_async_main(() => @mbasync.sleep(ms))
}
