///|
pub(all) struct ProjectMeta {
  name : String
  version : String
  purl : String
} derive(Show, Eq)

///|
pub(all) struct BuildOptions {
  profile : String
  output_dir : String
} derive(Show, Eq)

///|
pub(all) struct DiffOptions {
  since : String
  include_test_changes : Bool
} derive(Show, Eq)

///|
pub(all) struct Config {
  schema_version : String
  project : ProjectMeta
  build : BuildOptions
  diff : DiffOptions
} derive(Show, Eq)

///|
pub(all) suberror ConfigError {
  FileReadError(path~ : String, String)
  ParseError(path~ : String, String)
  ValidationError(path~ : String, String)
} derive(Show, Eq)
