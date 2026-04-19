///|
pub(all) struct CacheListParams {
  prefix : String
} derive(Eq)

///|
pub impl Show for CacheListParams with output(self, logger) {
  logger.write_string("{prefix: ")
  logger.write_object(self.prefix)
  logger.write_char('}')
}

///|
pub(all) struct CacheAddParams {
  key : String
  file_path : String
} derive(Eq)

///|
pub impl Show for CacheAddParams with output(self, logger) {
  logger.write_string("{key: ")
  logger.write_object(self.key)
  logger.write_string(", file_path: ")
  logger.write_object(self.file_path)
  logger.write_char('}')
}

///|
pub(all) struct CacheRemoveParams {
  key : String
} derive(Eq)

///|
pub impl Show for CacheRemoveParams with output(self, logger) {
  logger.write_string("{key: ")
  logger.write_object(self.key)
  logger.write_char('}')
}

///|
pub(all) struct CacheCommandResult {
  summary : String
} derive(Eq)

///|
pub impl Show for CacheCommandResult with output(self, logger) {
  logger.write_string("{summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for CacheCommandResult with display(self : CacheCommandResult) -> String {
  self.summary
}

///|
fn cache_error(message : String) -> @cli.CliError {
  @cli.command_error("cache failed: \{message}")
}

///|
fn cache_root() -> Result[String, @cli.CliError] {
  let resolved_out = @config.resolve(".")
  guard resolved_out is Ok(resolved) else {
    return Err(@cli.config_error(resolved_out.unwrap_err().to_string()))
  }
  Ok(
    @config.resolve_project_path(
      resolved.root_dir,
      resolved.config.cache.local_store.store_dir,
    ),
  )
}

///|
pub fn run_list(
  params : CacheListParams,
) -> @cli.CliResult[CacheCommandResult, @cli.CliError] {
  let root_out = cache_root()
  guard root_out is Ok(root) else { return Err(root_out.unwrap_err()) }
  let list_out = @local_cache.list(root, prefix=params.prefix)
  guard list_out is Ok(entries) else { return Err(cache_error(list_out.unwrap_err())) }
  let lines : Array[String] = []
  for i in 0..<entries.length() {
    let entry = entries[i]
    lines.push("\{entry.key} (\{entry.size} bytes)")
  }
  let summary = if lines.is_empty() {
    "No cache entries found in \{root}"
  } else {
    lines.join("\n")
  }
  Ok({ summary, })
}

///|
pub fn run_add(
  params : CacheAddParams,
) -> @cli.CliResult[CacheCommandResult, @cli.CliError] {
  let root_out = cache_root()
  guard root_out is Ok(root) else { return Err(root_out.unwrap_err()) }
  let body = @fs.read_file_to_bytes(params.file_path) catch {
    err => return Err(cache_error("cannot read \{params.file_path}: \{@debug.to_repr(err)}"))
  }
  let put_out = @local_cache.put(root, params.key, body)
  guard put_out is Ok(entry) else { return Err(cache_error(put_out.unwrap_err())) }
  Ok({ summary: "Added cache entry \{entry.key} (\{entry.size} bytes)" })
}

///|
pub fn run_remove(
  params : CacheRemoveParams,
) -> @cli.CliResult[CacheCommandResult, @cli.CliError] {
  let root_out = cache_root()
  guard root_out is Ok(root) else { return Err(root_out.unwrap_err()) }
  let remove_out = @local_cache.remove(root, params.key)
  guard remove_out is Ok(existed) else {
    return Err(cache_error(remove_out.unwrap_err()))
  }
  let summary = if existed {
    "Removed cache entry \{params.key}"
  } else {
    "Cache entry not found: \{params.key}"
  }
  Ok({ summary, })
}
