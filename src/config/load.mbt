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
fn parse_config(content : String, path : String) -> Result[Config, ConfigError] {
  let mut schema_version = ""
  let mut profile = ""
  let mut purl = ""
  let mut source_repo = ""
  let mut source_ref = ""
  let includes : Array[String] = []
  let mut checks_format = ""
  let mut checks_policy = ""

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
      ("root", "purl") => purl = value
      ("source", "repo") => source_repo = value
      ("source", "ref") => source_ref = value
      ("checks", "format") => checks_format = value
      ("checks", "policy") => checks_policy = value
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
    purl,
    source: { repo: source_repo, source_ref },
    inputs: { include_paths: includes },
    checks: { format: checks_format, policy: checks_policy },
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
