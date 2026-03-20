///|
pub(all) struct InitParams {
  output_path : String
} derive(Show, Eq)

///|
pub(all) struct InitResult {
  output_path : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for InitResult with display(self : InitResult) -> String {
  self.summary
}

///|
pub fn run(params : InitParams) -> @cli.CliResult[InitResult, @cli.CliError] {
  let write_result = try? write_config(params.output_path)
  if write_result is Ok(_) {
    Ok({
      output_path: params.output_path,
      summary: "Generated CIQ config at \{params.output_path}",
    })
  } else {
    Err(
      @cli.command_error(
        "Failed to generate CIQ config at \{params.output_path}",
      ),
    )
  }
}
