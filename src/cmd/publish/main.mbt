///|
pub(all) struct PublishParams {
  bundle_file : String
} derive(Show, Eq)

///|
pub(all) struct PublishResult {
  bundle_file : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for PublishResult with display(self : PublishResult) -> String {
  self.summary
}

///|
pub fn run(
  params : PublishParams,
) -> @cli.CliResult[PublishResult, @cli.CliError] {
  Ok({
    bundle_file: params.bundle_file,
    summary: "TODO: implement publish command for \{params.bundle_file}",
  })
}
