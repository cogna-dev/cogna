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
fn decode_utf8(bytes : Bytes, path : String) -> Result[String, String] {
  let text = @utf8.decode(bytes) catch {
    _ => return Err("invalid utf-8 bytes in \{path}")
  }
  Ok(text)
}

///|
fn read_ndjson(path : String) -> Result[Array[Json], String] {
  let file_bytes = @fs.read_file_to_bytes(path) catch {
    _ => return Err("cannot read ndjson \{path}")
  }
  let text_out = decode_utf8(file_bytes, path)
  guard text_out is Ok(text) else { return Err(text_out.unwrap_err()) }
  if text == "" {
    return Ok([])
  }

  let lines = text.split("\n").to_array()
  let records : Array[Json] = []
  for i in 0..<lines.length() {
    let line = lines[i].to_string().trim().to_string()
    if line == "" {
      continue
    }
    let parsed = try? @json.parse(line)
    guard parsed is Ok(value) else {
      return Err("invalid ndjson line in \{path} at \{i + 1}")
    }
    records.push(value)
  }
  Ok(records)
}

///|
fn query_deadline_exceeded(cancelled : () -> Bool) -> Bool {
  cancelled()
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
fn selector_kind_hint(query : Json) -> String? {
  guard query is Object(query_object) else { return None }
  guard query_object.get("selector") is Some(Object(selector_object)) else {
    return None
  }
  match selector_object.get("kind") {
    Some(String(value)) if value != "" => Some(value)
    _ => None
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
fn selector_match_rank(record : Json, selector_path : String) -> Int? {
  let path = record_string(record, "path").unwrap_or("")
  let canonical_name = record_string(record, "canonical_name").unwrap_or("")
  let id = record_string(record, "id").unwrap_or("")
  let signature = record_string(record, "signature").unwrap_or("")
  if path == selector_path {
    Some(0)
  } else if canonical_name == selector_path {
    Some(1)
  } else if id.contains(selector_path) {
    Some(2)
  } else if signature.contains(selector_path) {
    Some(3)
  } else {
    None
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
fn append_record_field(
  target : Map[String, Json],
  record_object : Map[String, Json],
  field : String,
) -> Unit {
  match record_object.get(field) {
    Some(value) => target[field] = value
    None => ()
  }
}

///|
fn append_result_passthrough_fields(
  target : Map[String, Json],
  record_object : Map[String, Json],
) -> Unit {
  let fields = [
    "path", "name", "canonical_name", "language", "baselineRole", "source_refs",
    "relations", "visibility", "docs", "shape", "language_specific",
  ]
  for i in 0..<fields.length() {
    append_record_field(target, record_object, fields[i])
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
fn read_repo_records(
  repo : String,
  name : String,
) -> Result[Array[Json], String] {
  let plain_path = "\{repo}/dist/\{name}.ndjson"
  if @fs.path_exists(plain_path) {
    read_ndjson(plain_path)
  } else {
    Err("cannot read ndjson \{plain_path}")
  }
}

///|
fn all_bundle_records(repo : String) -> Array[Json] {
  let records : Array[Json] = []
  append_records(records, read_repo_records(repo, "declarations"))
  append_records(records, read_repo_records(repo, "symbols"))
  append_records(records, read_repo_records(repo, "software-components"))
  records
}

///|
fn all_bundle_records_with_cancel(
  repo : String,
  cancelled : () -> Bool,
) -> Result[Array[Json], String] {
  if query_deadline_exceeded(cancelled) {
    return Err("request cancelled")
  }
  let declarations = match read_repo_records(repo, "declarations") {
    Ok(values) => values
    Err(_) => []
  }
  if query_deadline_exceeded(cancelled) {
    return Err("request cancelled")
  }
  let symbols = match read_repo_records(repo, "symbols") {
    Ok(values) => values
    Err(_) => []
  }
  if query_deadline_exceeded(cancelled) {
    return Err("request cancelled")
  }
  let components = match read_repo_records(repo, "software-components") {
    Ok(values) => values
    Err(_) => []
  }
  if query_deadline_exceeded(cancelled) {
    return Err("request cancelled")
  }
  let records : Array[Json] = []
  for i in 0..<declarations.length() {
    records.push(declarations[i])
  }
  for i in 0..<symbols.length() {
    records.push(symbols[i])
  }
  for i in 0..<components.length() {
    records.push(components[i])
  }
  Ok(records)
}

///|
fn record_matches_selector(
  record : Json,
  selector_path : String,
  selector_kind : String?,
  expected_rank : Int,
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
  match selector_kind {
    Some(kind_hint) if kind != kind_hint => return None
    _ => ()
  }
  guard selector_match_rank(record, selector_path) is Some(rank) else {
    return None
  }
  if rank != expected_rank {
    return None
  }

  let location_path = if path == "" { selector_path } else { path }

  let match_record : Map[String, Json] = {
    "id": id,
    "kind": kind,
    "signature": signature,
    "location": record_location(record, location_path),
  }
  guard record is Object(record_object) else {
    return Some(Json::object(match_record))
  }
  append_result_passthrough_fields(match_record, record_object)
  Some(Json::object(match_record))
}

///|
pub fn query_matches(
  repo : String,
  selector_path : String,
  selector_kind : String?,
) -> Array[Json] {
  let selected : Array[Json] = []
  let seen : Map[String, Bool] = {}
  let records = all_bundle_records(repo)
  for rank in 0..<4 {
    for i in 0..<records.length() {
      let match_out = record_matches_selector(
        records[i],
        selector_path,
        selector_kind,
        rank,
      )
      guard match_out is Some(found) else { continue }
      guard found is Object(found_object) else { continue }
      guard found_object.get("id") is Some(String(id)) else { continue }
      if !seen.contains(id) {
        seen[id] = true
        selected.push(found)
      }
    }
  }
  selected
}

///|
pub fn query_matches_with_cancel(
  repo : String,
  selector_path : String,
  selector_kind : String?,
  cancelled : () -> Bool,
) -> Result[Array[Json], String] {
  let records_out = all_bundle_records_with_cancel(repo, cancelled)
  guard records_out is Ok(records) else { return Err(records_out.unwrap_err()) }
  let selected : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for rank in 0..<4 {
    for i in 0..<records.length() {
      if query_deadline_exceeded(cancelled) {
        return Err("request cancelled")
      }
      let match_out = record_matches_selector(
        records[i],
        selector_path,
        selector_kind,
        rank,
      )
      guard match_out is Some(found) else { continue }
      guard found is Object(found_object) else { continue }
      guard found_object.get("id") is Some(String(id)) else { continue }
      if !seen.contains(id) {
        seen[id] = true
        selected.push(found)
      }
    }
  }
  Ok(selected)
}

///|
fn parse_cursor(cursor : String?) -> Int {
  match cursor {
    Some(value) if value.has_prefix("cursor:") => {
      let suffix = value.split(":").to_array()
      if suffix.length() == 2 {
        let parsed = try? @string.parse_int(suffix[1])
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
pub fn query_outlines_with_cancel(
  repo : String,
  purl : String,
  limit : Int,
  cursor : String?,
  cancelled : () -> Bool,
) -> Result[(Array[Json], String?), String] {
  let records_out = all_bundle_records_with_cancel(repo, cancelled)
  guard records_out is Ok(records) else { return Err(records_out.unwrap_err()) }
  let outlines : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<records.length() {
    if query_deadline_exceeded(cancelled) {
      return Err("request cancelled")
    }
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
    if query_deadline_exceeded(cancelled) {
      return Err("request cancelled")
    }
    page.push(outlines[i])
  }
  if end < outlines.length() {
    Ok((page, Some("cursor:\{end}")))
  } else {
    Ok((page, None))
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
  let kind = selector_kind_hint(query)
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
