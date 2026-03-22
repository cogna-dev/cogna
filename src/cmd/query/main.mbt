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
fn query_repo(query : Json) -> String {
  query_value(query, "repo", ".")
}

///|
fn parent_dir(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() <= 1 {
    "."
  } else {
    let mut out = ""
    for i in 0..<(parts.length() - 1) {
      if i > 0 {
        out = "\{out}/"
      }
      out = "\{out}\{parts[i]}"
    }
    out
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
fn record_string(record : Json, field : String) -> String? {
  guard record is Object(object) else { return None }
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
}

///|
fn record_location(record : Json, path_fallback : String) -> Json {
  guard record is Object(object) else {
    return { "uri": path_fallback, "startLine": 1, "endLine": 1 }
  }
  match object.get("location") {
    Some(Object(location_object)) => {
      let uri = match location_object.get("uri") {
        Some(String(value)) if value != "" => value
        _ => path_fallback
      }
      let start_line = match location_object.get("startLine") {
        Some(Number(value, ..)) => value.to_int()
        _ => 1
      }
      let end_line = match location_object.get("endLine") {
        Some(Number(value, ..)) => value.to_int()
        _ => start_line
      }
      { "uri": uri, "startLine": start_line, "endLine": end_line }
    }
    _ => { "uri": path_fallback, "startLine": 1, "endLine": 1 }
  }
}

///|
fn append_records(
  records : Array[Json],
  source : Result[Array[Json], String],
) -> Unit {
  guard source is Ok(values) else { return }
  for i in 0..<values.length() {
    records.push(values[i])
  }
}

///|
fn all_bundle_records(repo : String) -> Array[Json] {
  let records : Array[Json] = []
  append_records(records, @bundle.read_bundle_declarations(repo))
  append_records(records, @bundle.read_bundle_symbols(repo))
  records
}

///|
fn record_matches_selector(
  record : Json,
  selector_path : String,
  selector_kind : String,
) -> Json? {
  let path = match record_string(record, "path") {
    Some(value) => value
    None => ""
  }
  let kind = match record_string(record, "kind") {
    Some(value) => value
    None => ""
  }
  let id = match record_string(record, "id") {
    Some(value) => value
    None => ""
  }
  let signature = match record_string(record, "signature") {
    Some(value) => value
    None => ""
  }

  if id == "" || kind == "" || signature == "" {
    return None
  }
  if kind != selector_kind {
    return None
  }
  if path != selector_path && !id.contains(selector_path) {
    return None
  }

  Some({
    "id": id,
    "kind": kind,
    "signature": signature,
    "location": record_location(record, path),
  })
}

///|
pub fn query_matches(
  repo : String,
  selector_path : String,
  selector_kind : String,
) -> Array[Json] {
  let selected : Array[Json] = []
  let seen : Map[String, Bool] = {}
  let records = all_bundle_records(repo)
  for i in 0..<records.length() {
    let match_out = record_matches_selector(
      records[i],
      selector_path,
      selector_kind,
    )
    guard match_out is Some(found) else { continue }
    guard found is Object(found_object) else { continue }
    guard found_object.get("id") is Some(String(id)) else { continue }
    if !seen.contains(id) {
      seen[id] = true
      selected.push(found)
    }
  }
  selected
}

///|
fn parse_cursor(cursor : String?) -> Int {
  match cursor {
    Some(value) if value.has_prefix("cursor:") => {
      let suffix = value.split(":").to_array()
      if suffix.length() == 2 {
        let parsed = try? @strconv.parse_int(suffix[1])
        match parsed {
          Ok(number) if number >= 0 => number
          _ => 0
        }
      } else {
        0
      }
    }
    _ => 0
  }
}

///|
pub fn query_outlines(
  repo : String,
  purl : String,
  limit : Int,
  cursor : String?,
) -> (Array[Json], String?) {
  let records = all_bundle_records(repo)
  let outlines : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<records.length() {
    let path = match record_string(records[i], "path") {
      Some(value) => value
      None => continue
    }
    let kind = match record_string(records[i], "kind") {
      Some(value) => value
      None => continue
    }
    let signature = match record_string(records[i], "signature") {
      Some(value) => value
      None => continue
    }
    let key = "\{path}::\{kind}::\{signature}"
    if seen.contains(key) {
      continue
    }
    seen[key] = true
    outlines.push({
      "purl": purl,
      "path": path,
      "kind": kind,
      "summary": signature,
    })
  }

  let start = parse_cursor(cursor)
  let max_limit = if limit <= 0 { 20 } else { limit }
  let end = if start + max_limit > outlines.length() {
    outlines.length()
  } else {
    start + max_limit
  }

  let page : Array[Json] = []
  for i in start..<end {
    page.push(outlines[i])
  }
  if end < outlines.length() {
    (page, Some("cursor:\{end}"))
  } else {
    (page, None)
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
fn ciq_result(query : Json, query_file : String) -> Json {
  let path = selector_value(query, "path", "unknown")
  let kind = selector_value(query, "kind", "symbol")
  let query_repo_value = query_repo(query)
  let repo = if query_repo_value == "." {
    parent_dir(query_file)
  } else {
    query_repo_value
  }
  let final_matches = query_matches(repo, path, kind)

  {
    "schemaVersion": "ciq-result/v1",
    "purl": query_value(query, "purl", "unknown"),
    "matches": final_matches,
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
  let result_json = ciq_result(query, params.query_file)
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
