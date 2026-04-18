///|
test "e2e extractors manifest loads" {
  let cases_out = load_cases()
  guard cases_out is Ok(cases) else {
    fail(cases_out.unwrap_err())
  }
  assert_true(cases.length() > 0)
}

///|
test "e2e rust acceptance harness runs cases" {
  let run_out = run_acceptance()
  guard run_out is Ok(results) else {
    fail(run_out.unwrap_err())
  }
  assert_true(results.length() > 0)
}
