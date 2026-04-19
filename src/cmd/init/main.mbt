///|
pub(all) struct InitParams {
  output_path : String
} derive(Eq)

///|
pub impl Show for InitParams with output(self, logger) {
  logger.write_string("{output_path: ")
  logger.write_object(self.output_path)
  logger.write_char('}')
}

///|
pub(all) struct InitResult {
  output_path : String
  policy_dir : String
  summary : String
} derive(Eq)

///|
pub impl Show for InitResult with output(self, logger) {
  logger.write_string("{output_path: ")
  logger.write_object(self.output_path)
  logger.write_string(", policy_dir: ")
  logger.write_object(self.policy_dir)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for InitResult with display(self : InitResult) -> String {
  self.summary
}

///|
pub fn run(params : InitParams) -> @cli.CliResult[InitResult, @cli.CliError] {
  let write_result = try? write_config(params.output_path)
  if write_result is Ok(policy_dir) {
    Ok({
      output_path: params.output_path,
      policy_dir,
      summary: "Generated CIQ config at \{params.output_path} and materialized built-in policies at \{policy_dir}",
    })
  } else {
    Err(
      @cli.command_error(
        "Failed to generate CIQ config at \{params.output_path}",
      ),
    )
  }
}
