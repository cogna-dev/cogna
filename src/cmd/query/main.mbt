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
fn query_error(message : String) -> @cli.CliError {
  @cli.command_error("query failed: \{message}")
}

///|
fn read_json(path : String, kind : String) -> Result[Json, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(query_error("cannot read \{kind} \{path}: \{err.to_string()}"))
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(query_error("invalid json in \{kind} \{path}"))
  }
  Ok(value)
}

///|
fn ensure_query_shape(
  query : Json,
  query_file : String,
) -> Result[Unit, @cli.CliError] {
  let out = @schema.validate_ciq_query_v1(query)
  guard out is Ok(_) else {
    return Err(
      query_error(
        "query file \{query_file} does not satisfy ciq-query/v1 schema: \{out.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(())
}

///|
fn query_value(query : Json, field : String, fallback : String) -> String {
  guard query is Object(query_object) else { return fallback }
  match query_object.get(field) {
    Some(String(value)) => value
    _ => fallback
  }
}

///|
fn selector_value(query : Json, field : String, fallback : String) -> String {
  guard query is Object(query_object) else { return fallback }
  guard query_object.get("selector") is Some(Object(selector_object)) else {
    return fallback
  }
  match selector_object.get(field) {
    Some(String(value)) => value
    _ => fallback
  }
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
fn ciq_result(query : Json) -> Json {
  let path = selector_value(query, "path", "unknown")
  let kind = selector_value(query, "kind", "symbol")
  {
    "schemaVersion": "ciq-result/v1",
    "purl": query_value(query, "purl", "unknown"),
    "matches": [
      {
        "id": "decl:skeleton:\{path}",
        "kind": kind,
        "signature": "placeholder signature",
        "location": {
          "uri": "dist/symbols.ndjson.zst",
          "startLine": 1,
          "endLine": 1,
        },
      },
    ],
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
        query_error("cannot write result file \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
pub fn run(params : QueryParams) -> @cli.CliResult[QueryResult, @cli.CliError] {
  let query_out = read_json(params.query_file, "query")
  guard query_out is Ok(query) else { return Err(query_out.unwrap_err()) }

  let shape_out = ensure_query_shape(query, params.query_file)
  guard shape_out is Ok(_) else { return Err(shape_out.unwrap_err()) }

  let output_path = result_path(params.query_file)
  let result_json = ciq_result(query)
  let result_shape_out = @schema.validate_ciq_result_v1(result_json)
  guard result_shape_out is Ok(_) else {
    return Err(
      query_error(
        "generated result does not satisfy ciq-result/v1 schema: \{result_shape_out.unwrap_err().to_string()}",
      ),
    )
  }

  let write_out = write_result(output_path, result_json)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    query_file: params.query_file,
    summary: "Generated CIQ result at \{output_path}",
  })
}
