///|
test "async probe combo process and stdio symbols in one package" {
  let process_result : Ref[Result[(Int, String), String]] = Ref::new(Err("unset"))
  let stdio_result : Ref[Result[String?, String]?] = Ref::new(None)

  @async.run_async_main(() => {
    process_result.val = try {
      let (code, stdout, _) = @aprocess.collect_output(
        "sh",
        ["-c", "printf probe_combo_ok"],
      )
      Ok((code, @utf8.decode_lossy(stdout.binary())))
    } catch {
      err => Err(err.to_string())
    }

    stdio_result.val = Some(try {
      let line = @async.with_timeout(10, () => {
        @astdio.stdin.read_until("\n")
      })
      Ok(line)
    } catch {
      err => Err(err.to_string())
    })
  })

  guard process_result.val is Ok((code, stdout)) else {
    fail("combo process probe failed: \{process_result.val.unwrap_err()}")
  }
  inspect(code, content="0")
  inspect(stdout, content="probe_combo_ok")

  guard stdio_result.val is Some(stdio_out) else {
    fail("combo stdio probe did not capture any result")
  }
  match stdio_out {
    Ok(_) => ()
    Err(error_text) => assert_true(error_text.contains("Timeout"))
  }
}
