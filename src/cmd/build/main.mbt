///|
pub(all) struct BuildParams {
  repo : String
} derive(Eq)

///|
pub impl Show for BuildParams with output(self, logger) {
  logger.write_string("{repo: ")
  logger.write_object(self.repo)
  logger.write_char('}')
}

///|
pub(all) struct BuildResult {
  repo : String
  summary : String
} derive(Eq)

///|
pub impl Show for BuildResult with output(self, logger) {
  logger.write_string("{repo: ")
  logger.write_object(self.repo)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for BuildResult with display(self : BuildResult) -> String {
  self.summary
}

///|
fn build_error(message : String) -> @cli.CliError {
  @cli.command_error("build failed: \{message}")
}

///|
pub fn run(params : BuildParams) -> @cli.CliResult[BuildResult, @cli.CliError] {
  let lookup_root = if params.repo == "" { "." } else { params.repo }
  let resolved_out = @config.resolve(lookup_root)
  guard resolved_out is Ok(_) else {
    return Err(@cli.config_error(resolved_out.unwrap_err().to_string()))
  }
  match run_build(params.repo) {
    Ok(execution) => {
      let summary = match execution.outcome {
        BuildOutcome::RestoredLocal =>
          "Restored CIQ bundle skeleton from local cache at \{execution.dist_dir}"
        BuildOutcome::RestoredHttp =>
          "Restored CIQ bundle skeleton from http cache at \{execution.dist_dir}"
        BuildOutcome::Generated =>
          "Generated CIQ bundle skeleton at \{execution.dist_dir}"
      }
      Ok({ repo: execution.root_dir, summary })
    }
    Err(msg) => Err(build_error(msg))
  }
}
