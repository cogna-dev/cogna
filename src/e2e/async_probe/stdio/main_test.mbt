///|
test "async probe stdio read_until is callable" {
  let outcome : Ref[Result[String?, String]?] = Ref::new(None)
  @async.run_async_main(() => {
    outcome.val = Some(try {
      let line = @async.with_timeout(10, () => {
        @astdio.stdin.read_until("\n")
      })
      Ok(line)
    } catch {
      err => Err(err.to_string())
    })
  })
  guard outcome.val is Some(result) else {
    fail("stdio probe did not capture any result")
  }
  match result {
    Ok(_) => ()
    Err(error_text) => assert_true(error_text.contains("Timeout"))
  }
}
