///|
pub(all) struct QueryParams {
  query_file : String
} derive(Eq)

///|
pub impl Show for QueryParams with output(self, logger) {
  logger.write_string("{query_file: ")
  logger.write_object(self.query_file)
  logger.write_char('}')
}

///|
pub(all) struct QueryResult {
  query_file : String
  summary : String
} derive(Eq)

///|
pub impl Show for QueryResult with output(self, logger) {
  logger.write_string("{query_file: ")
  logger.write_object(self.query_file)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for QueryResult with display(self : QueryResult) -> String {
  self.summary
}

///|
fn read_json(path : String, kind : String) -> Result[Json, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(
        @cli.command_error(
          "query failed: cannot read \{kind} \{path}: \{err.to_string()}",
        ),
      )
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(@cli.command_error("query failed: invalid json in \{kind} \{path}"))
  }
  Ok(value)
}

///|
fn result_path(query_file : String) -> String {
  if query_file.has_suffix(".json") {
    let trimmed = query_file.strip_suffix(".json")
    match trimmed {
      Some(prefix) => "\{prefix}.result.json"
      None => "./query.result.json"
    }
  } else {
    "\{query_file}.result.json"
  }
}

///|
fn write_result(
  path : String,
  result_json : Json,
) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, result_json.stringify(indent=2)) catch {
    err =>
      return Err(
        @cli.command_error(
          "query failed: cannot write result file \{path}: \{err.to_string()}",
        ),
      )
  }
  Ok(())
}

///|
pub fn run(params : QueryParams) -> @cli.CliResult[QueryResult, @cli.CliError] {
  let query_out = read_json(params.query_file, "query")
  guard query_out is Ok(query) else { return Err(query_out.unwrap_err()) }

  let shape_out = @sdk_query.validate_query_shape(query, params.query_file)
  guard shape_out is Ok(_) else {
    return Err(@cli.command_error("query failed: \{shape_out.unwrap_err()}"))
  }

  let output_path = result_path(params.query_file)
  let result_json = @sdk_query.build_ciq_result(query, params.query_file)

  let result_shape_out = @sdk_query.validate_result_shape(result_json)
  guard result_shape_out is Ok(_) else {
    return Err(@cli.command_error("query failed: \{result_shape_out.unwrap_err()}"))
  }

  let write_out = write_result(output_path, result_json)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    query_file: params.query_file,
    summary: "Generated CIQ result at \{output_path}",
  })
}
