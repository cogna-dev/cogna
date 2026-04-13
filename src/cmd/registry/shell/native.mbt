///|
pub fn sleep_ms(ms : Int) -> Unit {
  if ms <= 0 {
    return
  }
  @async.run_async_main(() => @async.sleep(ms))
}
