///|
pub(all) struct BuildParams {
  repo : String
} derive(Show, Eq)

///|
pub(all) struct BuildResult {
  repo : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for BuildResult with display(self : BuildResult) -> String {
  self.summary
}

///|
pub fn run(params : BuildParams) -> @cli.CliResult[BuildResult, @cli.CliError] {
  Ok({
    repo: params.repo,
    summary: "TODO: implement build command for \{params.repo}",
  })
}
