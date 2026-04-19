///|
test "e2e extractors manifest loads" {
  let cases_out = load_cases()
  guard cases_out is Ok(cases) else {
    fail(cases_out.unwrap_err())
  }
  assert_true(cases.length() > 0)
}

///|
fn find_case(case_id : String) -> Result[E2eCase, String] {
  let cases_out = load_cases()
  guard cases_out is Ok(cases) else {
    return Err(cases_out.unwrap_err())
  }
  for i in 0..<cases.length() {
    if cases[i].id == case_id {
      return Ok(cases[i])
    }
  }
  Err("missing e2e case: \{case_id}")
}

///|
fn assert_case_passes(case_id : String) -> Result[Unit, String] {
  let case_out = find_case(case_id)
  guard case_out is Ok(case_) else { return Err(case_out.unwrap_err()) }
  let result = run_case(case_)
  if result.status != "passed" {
    let reason = result.reason.unwrap_or("")
    return Err(
      "case \{case_id} expected passed, got \{result.status}: \{reason}",
    )
  }
  guard result.snapshot_dir is Some(snapshot_dir) else {
    return Err("case \{case_id} missing snapshot dir")
  }
  let assert_out = assert_snapshot_artifacts(snapshot_dir)
  guard assert_out is Ok(_) else {
    return Err(
      "case \{case_id} invalid snapshot artifacts: \{assert_out.unwrap_err()}",
    )
  }
  Ok(())
}

///|
fn assert_case_skipped(case_id : String, reason_part : String) -> Result[Unit, String] {
  let case_out = find_case(case_id)
  guard case_out is Ok(case_) else { return Err(case_out.unwrap_err()) }
  let result = run_case(case_)
  if result.status != "skipped" {
    return Err("case \{case_id} expected skipped, got \{result.status}")
  }
  guard result.reason is Some(reason) else {
    return Err("case \{case_id} expected skip reason")
  }
  if !reason.contains(reason_part) {
    return Err(
      "case \{case_id} skip reason mismatch, got: \{reason}, expected to contain: \{reason_part}",
    )
  }
  Ok(())
}

///|
test "e2e extractors rust local case passes" {
  let out = assert_case_passes("rust-local-example")
  guard out is Ok(_) else { fail(out.unwrap_err()) }
}

///|
test "e2e extractors go local case passes" {
  let out = assert_case_passes("go-local-example")
  guard out is Ok(_) else { fail(out.unwrap_err()) }
}

///|
test "e2e extractors openapi local case passes" {
  let out = assert_case_passes("openapi-local-example")
  guard out is Ok(_) else { fail(out.unwrap_err()) }
}

///|
test "e2e extractors terraform local case passes" {
  let out = assert_case_passes("terraform-local-example")
  guard out is Ok(_) else { fail(out.unwrap_err()) }
}

///|
test "e2e extractors rust remote package cases skip by default" {
  let first_out = assert_case_skipped(
    "rust-aws-sdk-dynamodb-1.110.0",
    "COGNA_ENABLE_REMOTE_E2E=true",
  )
  guard first_out is Ok(_) else { fail(first_out.unwrap_err()) }

  let second_out = assert_case_skipped(
    "rust-aws-config-1.8.15",
    "COGNA_ENABLE_REMOTE_E2E=true",
  )
  guard second_out is Ok(_) else { fail(second_out.unwrap_err()) }
}

///|
test "e2e extractors git remote case skips by default" {
  let out = assert_case_skipped(
    "rust-https-github.com-awslabs-aws-sdk-rust-main",
    "COGNA_ENABLE_GIT_REMOTE_E2E=true",
  )
  guard out is Ok(_) else { fail(out.unwrap_err()) }
}
