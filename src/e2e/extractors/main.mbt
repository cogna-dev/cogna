///|
pub fn run_acceptance() -> Result[Array[CaseRunResult], String] {
  let cases_out = load_cases()
  guard cases_out is Ok(cases) else { return Err(cases_out.unwrap_err()) }
  let results : Array[CaseRunResult] = []
  for i in 0..<cases.length() {
    let case_ = cases[i]
    let result = run_case(case_)
    match result.status {
      "passed" => {
        guard result.snapshot_dir is Some(snapshot_dir) else {
          return Err("missing snapshot_dir for passed case \{case_.id}")
        }
        let assert_out = assert_snapshot_artifacts(snapshot_dir)
        guard assert_out is Ok(_) else {
          return Err(
            "snapshot validation failed for \{case_.id}: \{assert_out.unwrap_err()}",
          )
        }
      }
      "failed" => {
        guard result.reason is Some(reason) else {
          return Err("missing failure reason for case \{case_.id}")
        }
        let local_requirement_failure =
          reason.contains("is not available locally") ||
          reason.contains("Run `cargo fetch`") ||
          reason.contains("Run `cargo vendor`") ||
          reason.contains("Run `go mod download`") ||
          reason.contains("Run `go mod vendor`") ||
          reason.contains("Run `terraform init`")
        if !local_requirement_failure {
          return Err("unexpected failure for case \{case_.id}: \{reason}")
        }
      }
      "skipped" => ()
      _ => return Err("unknown case status for \{case_.id}: \{result.status}")
    }
    results.push(result)
  }
  Ok(results)
}
