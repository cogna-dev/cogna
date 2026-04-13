///|
/// A single HCL attribute assignment (e.g. `type = "string"`, `count = 1`).
pub(all) struct HclAttr {
  /// The attribute name (left-hand side).
  name : String
  /// The raw value text (right-hand side, un-evaluated).
  value : String
  /// 1-based line number of the attribute in the source file.
  line_no : Int
} derive(Eq)

///|
pub impl Show for HclAttr with output(self, logger) {
  logger.write_string("{name: ")
  logger.write_object(self.name)
  logger.write_string(", value: ")
  logger.write_object(self.value)
  logger.write_string(", line_no: ")
  logger.write_object(self.line_no)
  logger.write_char('}')
}

///|
/// A top-level or nested HCL block (e.g. `resource "aws_vpc" "main" { ... }`).
pub(all) struct HclBlock {
  /// Block type keyword (e.g. `resource`, `variable`, `provider`).
  kind : String
  /// Primary label(s) joined by `.` when multiple exist (e.g. `aws_vpc.main`).
  name : String
  /// The signature line as it appears in source (for display / snapshot).
  signature : String
  /// 1-based line number of the opening `{` line.
  line_no : Int
  /// Nested attributes recognised inside this block.
  attrs : Array[HclAttr]
} derive(Eq)

///|
pub impl Show for HclBlock with output(self, logger) {
  logger.write_string("{kind: ")
  logger.write_object(self.kind)
  logger.write_string(", name: ")
  logger.write_object(self.name)
  logger.write_string(", signature: ")
  logger.write_object(self.signature)
  logger.write_string(", line_no: ")
  logger.write_object(self.line_no)
  logger.write_string(", attrs: ")
  logger.write_object(self.attrs)
  logger.write_char('}')
}

///|
/// Parsed result for a single `.tf` file.
pub(all) struct HclFile {
  /// All top-level and nested blocks extracted from the file.
  blocks : Array[HclBlock]
} derive(Eq)

///|
pub impl Show for HclFile with output(self, logger) {
  logger.write_string("{blocks: ")
  logger.write_object(self.blocks)
  logger.write_char('}')
}
