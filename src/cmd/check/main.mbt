///|
pub(all) struct CheckParams {
  diff_file : String
  policy_bundle : String
} derive(Show, Eq)

///|
pub(all) struct CheckResult {
  diff_file : String
  policy_bundle : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for CheckResult with display(self : CheckResult) -> String {
  self.summary
}

///|
pub fn run(params : CheckParams) -> @cli.CliResult[CheckResult, @cli.CliError] {
  Ok({
    diff_file: params.diff_file,
    policy_bundle: params.policy_bundle,
    summary: "TODO: implement check command for \{params.diff_file} with \{params.policy_bundle}",
  })
}
