///|
pub(all) struct QueryParams {
  query_file : String
} derive(Show, Eq)

///|
pub(all) struct QueryResult {
  query_file : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for QueryResult with display(self : QueryResult) -> String {
  self.summary
}

///|
pub fn run(params : QueryParams) -> @cli.CliResult[QueryResult, @cli.CliError] {
  Ok({
    query_file: params.query_file,
    summary: "TODO: implement query command for \{params.query_file}",
  })
}
