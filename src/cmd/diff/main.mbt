///|
pub(all) struct DiffParams {
  repo : String
} derive(Show, Eq)

///|
pub(all) struct DiffResult {
  repo : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for DiffResult with display(self : DiffResult) -> String {
  self.summary
}

///|
pub fn run(params : DiffParams) -> @cli.CliResult[DiffResult, @cli.CliError] {
  Ok({
    repo: params.repo,
    summary: "TODO: implement diff command for \{params.repo}",
  })
}
