///|
fn trim_spaces(value : String) -> String {
  let mut start = 0
  let mut end = value.length()
  while start < end {
    let c = value.code_unit_at(start)
    if c == ' ' || c == '\t' || c == '\r' {
      start = start + 1
    } else {
      break
    }
  }
  while end > start {
    let c = value.code_unit_at(end - 1)
    if c == ' ' || c == '\t' || c == '\r' {
      end = end - 1
    } else {
      break
    }
  }
  value[start:end].to_string()
}

///|
fn parse_key_value(
  line : String,
  path : String,
  line_no : Int,
) -> Result[(String, String), ConfigError] {
  let mut split_idx = -1
  for i in 0..<line.length() {
    if line.code_unit_at(i) == ':' {
      split_idx = i
      break
    }
  }

  if split_idx < 0 {
    return Err(
      ConfigError::ParseError(path~, "line \{line_no}: expected key:value pair"),
    )
  }

  let key = line[0:split_idx].to_string() |> trim_spaces
  let value = line[split_idx + 1:].to_string() |> trim_spaces
  Ok((key, value))
}

///|
fn parse_bool(
  value : String,
  path : String,
  line_no : Int,
  field : String,
) -> Result[Bool, ConfigError] {
  match value {
    "true" => Ok(true)
    "false" => Ok(false)
    _ =>
      Err(
        ConfigError::ParseError(
          path~,
          "line \{line_no}: \{field} must be true or false",
        ),
      )
  }
}

///|
fn parse_int(
  value : String,
  path : String,
  line_no : Int,
  field : String,
) -> Result[Int, ConfigError] {
  let parsed = try? @string.parse_int(value)
  guard parsed is Ok(number) else {
    return Err(
      ConfigError::ParseError(
        path~,
        "line \{line_no}: \{field} must be an integer",
      ),
    )
  }
  Ok(number)
}

///|
fn join_path(base : String, child : String) -> String {
  if base == "" || base == "." {
    "./\{child}"
  } else if base.has_suffix("/") {
    "\{base}\{child}"
  } else {
    "\{base}/\{child}"
  }
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
    if out == "" {
      "."
    } else {
      out
    }
  }
}

///|
fn has_path_prefix(value : String, prefix : String) -> Bool {
  value.has_prefix(prefix)
}

///|
pub fn resolve_project_path(root_dir : String, path : String) -> String {
  if path == "" {
    root_dir
  } else if has_path_prefix(path, "/") ||
    has_path_prefix(path, "./") ||
    has_path_prefix(path, "../") {
    if path.has_prefix("/") {
      path
    } else {
      join_path(root_dir, path)
    }
  } else {
    join_path(root_dir, path)
  }
}

///|
pub fn find_config_path(root_dir : String) -> String? {
  let base = if root_dir == "" { "." } else { root_dir }
  let preferred = join_path(base, "cogna.yml")
  if @fs.path_exists(preferred) {
    return Some(preferred)
  }
  let fallback = join_path(base, "cogna.yaml")
  if @fs.path_exists(fallback) {
    Some(fallback)
  } else {
    None
  }
}

///|
pub fn resolve(root_dir : String) -> Result[ResolvedConfig, ConfigError] {
  let base = if root_dir == "" { "." } else { root_dir }
  match find_config_path(base) {
    Some(path) => {
      let loaded = load_from_path(path)
      guard loaded is Ok(config) else { return Err(loaded.unwrap_err()) }
      Ok({ path, root_dir: parent_dir(path), config })
    }
    None =>
      Err(
        ConfigError::FileReadError(
          path=base,
          "config file not found (tried cogna.yml, cogna.yaml)",
        ),
      )
  }
}

///|
fn parse_config(content : String, path : String) -> Result[Config, ConfigError] {
  let defaults = default_config()
  let mut schema_version = defaults.schema_version
  let mut profile = defaults.profile
  let mut validation = defaults.validation
  let mut purl = defaults.purl
  let mut source_repo = defaults.source.repo
  let mut source_ref = defaults.source.source_ref
  let includes : Array[String] = []
  let mut checks_format = defaults.checks.format
  let mut checks_policy = defaults.checks.policy
  let mut diff_since = defaults.diff.since
  let mut diff_include_test_changes = defaults.diff.include_test_changes
  let mut sbom_format = defaults.sbom.format
  let mut sbom_dependency_bundles = defaults.sbom.dependency_bundles
  let mut sbom_require_local_packages = defaults.sbom.require_local_packages
  let mut cache_type = defaults.cache.type_
  let mut cache_local_store_dir = defaults.cache.local_store.store_dir
  let mut cache_http_base_url = defaults.cache.http.base_url
  let mut cache_http_timeout_ms = defaults.cache.http.timeout_ms
  let mut mcp_port = defaults.mcp.port

  let lines = content.split("\n").to_array()
  let mut section = "root"

  for i in 0..<lines.length() {
    let line_no = i + 1
    let raw_line = lines[i].to_string()
    let line = trim_spaces(raw_line)

    if line == "" || line.has_prefix("#") {
      continue
    }

    if line == "source:" {
      section = "source"
      continue
    }
    if line == "inputs:" {
      section = "inputs"
      continue
    }
    if line == "include:" {
      section = "inputs_include"
      continue
    }
    if line == "checks:" {
      section = "checks"
      continue
    }
    if line == "diff:" {
      section = "diff"
      continue
    }
    if line == "sbom:" {
      section = "sbom"
      continue
    }
    if line == "cache:" {
      section = "cache"
      continue
    }
    if line == "local:" &&
      (section == "cache" || section == "cache_local" || section == "cache_http") {
      section = "cache_local"
      continue
    }
    if line == "http:" &&
      (section == "cache" || section == "cache_local" || section == "cache_http") {
      section = "cache_http"
      continue
    }
    if line == "mcp:" {
      section = "mcp"
      continue
    }

    if line.has_prefix("- ") {
      if section != "inputs_include" {
        return Err(
          ConfigError::ParseError(
            path~,
            "line \{line_no}: list item outside inputs.include",
          ),
        )
      }
      let include_path = line[2:].to_string() |> trim_spaces
      if include_path == "" {
        return Err(
          ConfigError::ParseError(
            path~,
            "line \{line_no}: include path is empty",
          ),
        )
      }
      includes.push(include_path)
      continue
    }

    let parsed = parse_key_value(line, path, line_no)
    guard parsed is Ok((key, value)) else { return Err(parsed.unwrap_err()) }

    match (section, key) {
      ("root", "schemaVersion") => schema_version = value
      ("root", "profile") => profile = value
      ("root", "validation") => validation = value
      ("root", "purl") => purl = value
      ("source", "repo") => source_repo = value
      ("source", "ref") => source_ref = value
      ("checks", "format") => checks_format = value
      ("checks", "policy") => checks_policy = value
      ("diff", "since") =>
        diff_since = if value == "" { None } else { Some(value) }
      ("diff", "includeTestChanges") => {
        let parsed = parse_bool(value, path, line_no, "diff.includeTestChanges")
        guard parsed is Ok(flag) else { return Err(parsed.unwrap_err()) }
        diff_include_test_changes = flag
      }
      ("sbom", "format") => sbom_format = value
      ("sbom", "dependencyBundles") => {
        let parsed = parse_bool(value, path, line_no, "sbom.dependencyBundles")
        guard parsed is Ok(flag) else { return Err(parsed.unwrap_err()) }
        sbom_dependency_bundles = flag
      }
      ("sbom", "requireLocalPackages") => {
        let parsed = parse_bool(
          value, path, line_no, "sbom.requireLocalPackages",
        )
        guard parsed is Ok(flag) else { return Err(parsed.unwrap_err()) }
        sbom_require_local_packages = flag
      }
      ("cache", "type") => cache_type = value
      ("cache_local", "storeDir") => cache_local_store_dir = value
      ("cache_http", "baseUrl") => cache_http_base_url = value
      ("cache_http", "timeoutMs") => {
        let parsed = parse_int(value, path, line_no, "cache.http.timeoutMs")
        guard parsed is Ok(number) else { return Err(parsed.unwrap_err()) }
        cache_http_timeout_ms = number
      }
      ("mcp", "port") => {
        let parsed = parse_int(value, path, line_no, "mcp.port")
        guard parsed is Ok(number) else { return Err(parsed.unwrap_err()) }
        mcp_port = number
      }
      (_, _) =>
        return Err(
          ConfigError::ParseError(
            path~,
            "line \{line_no}: unsupported key \{key} in section \{section}",
          ),
        )
    }
  }

  Ok({
    schema_version,
    profile,
    validation,
    purl,
    source: { repo: source_repo, source_ref },
    inputs: { include_paths: includes },
    checks: { format: checks_format, policy: checks_policy },
    diff: { since: diff_since, include_test_changes: diff_include_test_changes },
    sbom: {
      format: sbom_format,
      dependency_bundles: sbom_dependency_bundles,
      require_local_packages: sbom_require_local_packages,
    },
    cache: {
      type_: cache_type,
      local_store: { store_dir: cache_local_store_dir },
      http: {
        base_url: cache_http_base_url,
        timeout_ms: cache_http_timeout_ms,
      },
    },
    mcp: { port: mcp_port },
  })
}

///|
pub fn load_from_path(path : String) -> Result[Config, ConfigError] {
  let file_content = @fs.read_file_to_string(path) catch {
    err => return Err(ConfigError::FileReadError(path~, err.to_string()))
  }
  let parsed = parse_config(file_content, path)
  guard parsed is Ok(config) else { return Err(parsed.unwrap_err()) }
  validate(config, path)
}
