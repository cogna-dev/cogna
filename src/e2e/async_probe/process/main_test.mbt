///|
test "async probe process collects stdout" {
  let result : Ref[Result[(Int, String), String]] = Ref::new(Err("unset"))
  @async.run_async_main(() => {
    result.val = try {
      let (code, stdout, _) = @aprocess.collect_output("sh", [
        "-c", "printf probe_process_ok",
      ])
      Ok((code, @utf8.decode_lossy(stdout.binary())))
    } catch {
      err => Err(err.to_string())
    }
  })
  guard result.val is Ok((code, stdout)) else {
    fail("process probe failed: \{result.val.unwrap_err()}")
  }
  inspect(code, content="0")
  inspect(stdout, content="probe_process_ok")
}
