///|
pub(all) struct ValidationIssue {
  path : String
  message : String
} derive(Eq)

///|
pub impl Show for ValidationIssue with output(self, logger) {
  logger.write_string("{path: ")
  logger.write_object(self.path)
  logger.write_string(", message: ")
  logger.write_object(self.message)
  logger.write_char('}')
}

///|
pub(all) suberror SchemaError {
  SchemaParseError(String)
  InvalidSchema(String)
  ValidationFailed(Array[ValidationIssue])
} derive(Eq)

///|
pub impl Show for SchemaError with output(self, logger) {
  match self {
    SchemaParseError(message) => {
      logger.write_string("SchemaParseError(")
      logger.write_object(message)
      logger.write_char(')')
    }
    InvalidSchema(message) => {
      logger.write_string("InvalidSchema(")
      logger.write_object(message)
      logger.write_char(')')
    }
    ValidationFailed(issues) => {
      logger.write_string("ValidationFailed(")
      logger.write_object(issues)
      logger.write_char(')')
    }
  }
}

///|
pub type JsonSchema = Json
