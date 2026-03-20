///|
pub(all) struct Source {
  repo : String
  source_ref : String
} derive(Show, Eq)

///|
pub(all) struct Inputs {
  include_paths : Array[String]
} derive(Show, Eq)

///|
pub(all) struct Checks {
  format : String
  policy : String
} derive(Show, Eq)

///|
pub(all) struct Config {
  schema_version : String
  profile : String
  purl : String
  source : Source
  inputs : Inputs
  checks : Checks
} derive(Show, Eq)

///|
pub(all) suberror ConfigError {
  FileReadError(path~ : String, String)
  ParseError(path~ : String, String)
  ValidationError(path~ : String, String)
} derive(Show, Eq)
