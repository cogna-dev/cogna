///|
test "shell spawn_detached starts and terminates a child" {
  let pid_out = spawn_detached("python3 -c \"import time; time.sleep(30)\"")
  guard pid_out is Ok(pid) else {
    fail("spawn_detached should succeed")
  }
  assert_true(pid > 0)
  assert_true(is_alive(pid))

  let terminated = terminate(pid)
  assert_true(terminated)
  sleep_ms(200)
  if is_alive(pid) {
    assert_true(force_kill(pid))
    sleep_ms(200)
  }
  assert_true(!is_alive(pid))
}
