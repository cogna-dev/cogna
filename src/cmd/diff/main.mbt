///|
pub(all) struct DiffParams {
  repo : String
  since : String?
  include_test_changes : Bool
} derive(Eq)

///|
pub impl Show for DiffParams with output(self, logger) {
  logger.write_string("{repo: ")
  logger.write_object(self.repo)
  logger.write_string(", since: ")
  logger.write_object(self.since)
  logger.write_string(", include_test_changes: ")
  logger.write_object(self.include_test_changes)
  logger.write_char('}')
}

///|
pub(all) struct DiffResult {
  repo : String
  summary : String
} derive(Eq)

///|
pub impl Show for DiffResult with output(self, logger) {
  logger.write_string("{repo: ")
  logger.write_object(self.repo)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for DiffResult with display(self : DiffResult) -> String {
  self.summary
}

///|
fn diff_error(message : String) -> @cli.CliError {
  @cli.command_error("diff failed: \{message}")
}

///|
fn write_diff(path : String, diff : Json) -> Result[Unit, @cli.CliError] {
  let serialized = diff.stringify(indent=2)
  @fs.write_string_to_file(path, serialized) catch {
    err =>
      return Err(
        diff_error("cannot write diff file \{path}: \{@debug.to_repr(err)}"),
      )
  }
  Ok(())
}

///|
pub fn run(params : DiffParams) -> @cli.CliResult[DiffResult, @cli.CliError] {
  let (repo, resolved_since, resolved_include_test_changes) = if params.repo == "" {
    let resolved_out = @config.resolve(".")
    guard resolved_out is Ok(resolved) else {
      return Err(@cli.config_error(resolved_out.unwrap_err().to_string()))
    }
    (
      resolved.root_dir,
      match params.since {
        Some(value) => Some(value)
        None => resolved.config.diff.since
      },
      resolved.config.diff.include_test_changes,
    )
  } else {
    (params.repo, params.since, params.include_test_changes)
  }

  let diff_out = compute_diff_json(
    repo,
    resolved_since,
    resolved_include_test_changes,
  )
  guard diff_out is Ok(diff) else {
    return Err(diff_error(diff_out.unwrap_err()))
  }

  let output_path = "\{repo}/dist/diff.json"
  let write_out = write_diff(output_path, diff)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({ repo, summary: "Generated CIQ declaration diff at \{output_path}" })
}
