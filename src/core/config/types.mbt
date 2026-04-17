///|
pub(all) struct Source {
  repo : String
  source_ref : String
} derive(Eq)

///|
pub impl Show for Source with output(self, logger) {
  logger.write_string("{repo: ")
  logger.write_object(self.repo)
  logger.write_string(", source_ref: ")
  logger.write_object(self.source_ref)
  logger.write_char('}')
}

///|
pub(all) struct Inputs {
  include_paths : Array[String]
} derive(Eq)

///|
pub impl Show for Inputs with output(self, logger) {
  logger.write_string("{include_paths: ")
  logger.write_object(self.include_paths)
  logger.write_char('}')
}

///|
pub(all) struct Checks {
  format : String
  policy : String
} derive(Eq)

///|
pub impl Show for Checks with output(self, logger) {
  logger.write_string("{format: ")
  logger.write_object(self.format)
  logger.write_string(", policy: ")
  logger.write_object(self.policy)
  logger.write_char('}')
}

///|
pub(all) struct DiffSettings {
  since : String?
  include_test_changes : Bool
} derive(Eq)

///|
pub impl Show for DiffSettings with output(self, logger) {
  logger.write_string("{since: ")
  logger.write_object(self.since)
  logger.write_string(", include_test_changes: ")
  logger.write_object(self.include_test_changes)
  logger.write_char('}')
}

///|
pub(all) struct SbomSettings {
  format : String
  dependency_bundles : Bool
  require_local_packages : Bool
} derive(Eq)

///|
pub impl Show for SbomSettings with output(self, logger) {
  logger.write_string("{format: ")
  logger.write_object(self.format)
  logger.write_string(", dependency_bundles: ")
  logger.write_object(self.dependency_bundles)
  logger.write_string(", require_local_packages: ")
  logger.write_object(self.require_local_packages)
  logger.write_char('}')
}

///|
pub(all) struct LocalCacheSettings {
  store_dir : String
} derive(Eq)

///|
pub impl Show for LocalCacheSettings with output(self, logger) {
  logger.write_string("{store_dir: ")
  logger.write_object(self.store_dir)
  logger.write_char('}')
}

///|
pub(all) struct HttpCacheSettings {
  base_url : String
  timeout_ms : Int
} derive(Eq)

///|
pub impl Show for HttpCacheSettings with output(self, logger) {
  logger.write_string("{base_url: ")
  logger.write_object(self.base_url)
  logger.write_string(", timeout_ms: ")
  logger.write_object(self.timeout_ms)
  logger.write_char('}')
}

///|
pub(all) struct CacheSettings {
  type_ : String
  local_store : LocalCacheSettings
  http : HttpCacheSettings
} derive(Eq)

///|
pub impl Show for CacheSettings with output(self, logger) {
  logger.write_string("{type_: ")
  logger.write_object(self.type_)
  logger.write_string(", local_store: ")
  logger.write_object(self.local_store)
  logger.write_string(", http: ")
  logger.write_object(self.http)
  logger.write_char('}')
}

///|
pub(all) struct McpSettings {
  port : Int
} derive(Eq)

///|
pub impl Show for McpSettings with output(self, logger) {
  logger.write_string("{port: ")
  logger.write_object(self.port)
  logger.write_char('}')
}

///|
pub(all) struct ResolvedConfig {
  path : String
  root_dir : String
  config : Config
} derive(Eq)

///|
pub impl Show for ResolvedConfig with output(self, logger) {
  logger.write_string("{path: ")
  logger.write_object(self.path)
  logger.write_string(", root_dir: ")
  logger.write_object(self.root_dir)
  logger.write_string(", config: ")
  logger.write_object(self.config)
  logger.write_char('}')
}

///|
pub(all) struct Config {
  schema_version : String
  profile : String
  validation : String
  purl : String
  source : Source
  inputs : Inputs
  checks : Checks
  diff : DiffSettings
  sbom : SbomSettings
  cache : CacheSettings
  mcp : McpSettings
} derive(Eq)

///|
pub impl Show for Config with output(self, logger) {
  logger.write_string("{schema_version: ")
  logger.write_object(self.schema_version)
  logger.write_string(", profile: ")
  logger.write_object(self.profile)
  logger.write_string(", validation: ")
  logger.write_object(self.validation)
  logger.write_string(", purl: ")
  logger.write_object(self.purl)
  logger.write_string(", source: ")
  logger.write_object(self.source)
  logger.write_string(", inputs: ")
  logger.write_object(self.inputs)
  logger.write_string(", checks: ")
  logger.write_object(self.checks)
  logger.write_string(", diff: ")
  logger.write_object(self.diff)
  logger.write_string(", sbom: ")
  logger.write_object(self.sbom)
  logger.write_string(", cache: ")
  logger.write_object(self.cache)
  logger.write_string(", mcp: ")
  logger.write_object(self.mcp)
  logger.write_char('}')
}

///|
pub(all) suberror ConfigError {
  FileReadError(path~ : String, String)
  ParseError(path~ : String, String)
  ValidationError(path~ : String, String)
} derive(Eq)

///|
pub impl Show for ConfigError with output(self, logger) {
  match self {
    FileReadError(path~, message) => {
      logger.write_string("FileReadError(path=")
      logger.write_object(path)
      logger.write_string(", ")
      logger.write_object(message)
      logger.write_char(')')
    }
    ParseError(path~, message) => {
      logger.write_string("ParseError(path=")
      logger.write_object(path)
      logger.write_string(", ")
      logger.write_object(message)
      logger.write_char(')')
    }
    ValidationError(path~, message) => {
      logger.write_string("ValidationError(path=")
      logger.write_object(path)
      logger.write_string(", ")
      logger.write_object(message)
      logger.write_char(')')
    }
  }
}
