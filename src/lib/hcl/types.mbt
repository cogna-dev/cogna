///|
/// A single HCL attribute assignment (e.g. `type = "string"`, `count = 1`).
pub(all) struct HclAttr {
  /// The attribute name (left-hand side).
  name : String
  /// The raw value text (right-hand side, un-evaluated).
  value : String
  /// 1-based line number of the attribute in the source file.
  line_no : Int
} derive(Show, Eq)

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
} derive(Show, Eq)

///|
/// Parsed result for a single `.tf` file.
pub(all) struct HclFile {
  /// All top-level and nested blocks extracted from the file.
  blocks : Array[HclBlock]
} derive(Show, Eq)
