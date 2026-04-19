///|
fn remote_e2e_gates_enabled() -> Bool {
  let remote = match @sys.get_env_var("COGNA_ENABLE_REMOTE_E2E") {
    Some("true") => true
    _ => false
  }
  let git_remote = match @sys.get_env_var("COGNA_ENABLE_GIT_REMOTE_E2E") {
    Some("true") => true
    _ => false
  }
  let rust_pkg_remote = match @sys.get_env_var("COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E") {
    Some("true") => true
    _ => false
  }
  remote && git_remote && rust_pkg_remote
}

///|
fn case_should_run(case_ : E2eCase) -> Bool {
  match case_.source {
    LocalWorkspace(_) => false
    CargoPackage(_, _) => case_.extractor == "rust"
    GoModule(_, _) => true
    TerraformPackage(_, source, _) => !source.has_prefix("./") && !source.has_prefix("../")
    GitRepo(_, _) => true
  }
}

///|
fn find_result(results : Array[CaseRunResult], case_id : String) -> CaseRunResult? {
  for i in 0..<results.length() {
    if results[i].case_id == case_id {
      return Some(results[i])
    }
  }
  None
}

///|
test "remote extractor e2e acceptance passes when gates enabled" {
  if !remote_e2e_gates_enabled() {
    return
  }

  let run_out = run_acceptance()
  guard run_out is Ok(results) else {
    fail(run_out.unwrap_err())
  }

  let cases_out = load_cases()
  guard cases_out is Ok(cases) else {
    fail(cases_out.unwrap_err())
  }

  for i in 0..<cases.length() {
    let case_ = cases[i]
    if !case_should_run(case_) {
      continue
    }
    guard find_result(results, case_.id) is Some(result) else {
      fail("remote case missing in acceptance results: \{case_.id}")
    }
    if result.status != "passed" {
      let reason = result.reason.unwrap_or("<none>")
      fail(
        "remote case expected passed, got \{result.status}: \{case_.id}: \{reason}",
      )
    }
    guard result.snapshot_dir is Some(snapshot_dir) else {
      fail("remote case missing snapshot dir: \{case_.id}")
    }
    let assert_out = assert_snapshot_artifacts(snapshot_dir)
    guard assert_out is Ok(_) else {
      fail(
        "remote case snapshot artifacts invalid: \{case_.id}: \{assert_out.unwrap_err()}",
      )
    }
  }
}
