///| Re-export schema functions for SDK consumers.

///|
pub fn ciq_bundle_v1_schema() -> @json_schema.JsonSchema {
  @schema.ciq_bundle_v1_schema()
}

///|
pub fn ciq_query_v1_schema() -> @json_schema.JsonSchema {
  @schema.ciq_query_v1_schema()
}

///|
pub fn ciq_result_v1_schema() -> @json_schema.JsonSchema {
  @schema.ciq_result_v1_schema()
}

///|
pub fn validate_ciq_bundle_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @schema.validate_ciq_bundle_v1(instance)
}

///|
pub fn validate_ciq_query_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @schema.validate_ciq_query_v1(instance)
}

///|
pub fn validate_ciq_result_v1(
  instance : Json,
) -> Result[Unit, @json_schema.SchemaError] {
  @schema.validate_ciq_result_v1(instance)
}

///|
fn parse_json_text(text : String, label : String) -> Result[Json, String] {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { return Err("invalid json in \{label}") }
  Ok(value)
}

///|
fn validation_issue_json(issue : @json_schema.ValidationIssue) -> Json {
  { "path": issue.path, "message": issue.message }
}

///|
fn schema_error_message(error : @json_schema.SchemaError) -> String {
  match error {
    @json_schema.SchemaParseError(message) => "schema parse error: \{message}"
    @json_schema.InvalidSchema(message) => "invalid schema: \{message}"
    @json_schema.ValidationFailed(issues) => {
      if issues.is_empty() {
        "validation failed"
      } else {
        let first = issues[0]
        "\{first.path}: \{first.message}"
      }
    }
  }
}

///|
fn schema_error_issues(error : @json_schema.SchemaError) -> Array[Json] {
  match error {
    @json_schema.ValidationFailed(issues) => issues.map(issue => validation_issue_json(issue))
    _ => []
  }
}

///|
fn validation_report_json(
  instance_out : Result[Json, String],
  validate : (Json) -> Result[Unit, @json_schema.SchemaError],
) -> Json {
  guard instance_out is Ok(instance) else {
    return { "ok": false, "message": instance_out.unwrap_err(), "issues": [] }
  }
  match validate(instance) {
    Ok(_) => { "ok": true }
    Err(error) => {
      {
        "ok": false,
        "message": schema_error_message(error),
        "issues": schema_error_issues(error),
      }
    }
  }
}

///|
pub fn ciq_bundle_v1_schema_json() -> String {
  ciq_bundle_v1_schema().stringify()
}

///|
pub fn ciq_query_v1_schema_json() -> String {
  ciq_query_v1_schema().stringify()
}

///|
pub fn ciq_result_v1_schema_json() -> String {
  ciq_result_v1_schema().stringify()
}

///|
pub fn validate_ciq_bundle_v1_json(instance_text : String) -> String {
  validation_report_json(
    parse_json_text(instance_text, "ciq-bundle/v1 instance"),
    validate_ciq_bundle_v1,
  ).stringify()
}

///|
pub fn validate_ciq_query_v1_json(instance_text : String) -> String {
  validation_report_json(
    parse_json_text(instance_text, "ciq-query/v1 instance"),
    validate_ciq_query_v1,
  ).stringify()
}

///|
pub fn validate_ciq_result_v1_json(instance_text : String) -> String {
  validation_report_json(
    parse_json_text(instance_text, "ciq-result/v1 instance"),
    validate_ciq_result_v1,
  ).stringify()
}
