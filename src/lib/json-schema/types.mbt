///|
pub(all) struct ValidationIssue {
  path : String
  message : String
} derive(Show, Eq)

///|
pub(all) suberror SchemaError {
  SchemaParseError(String)
  InvalidSchema(String)
  ValidationFailed(Array[ValidationIssue])
} derive(Show, Eq)

///|
pub type JsonSchema = Json
