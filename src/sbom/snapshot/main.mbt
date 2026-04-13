///|
pub(all) struct PackageFile {
  path : String
  sha256 : String
  size : Int
} derive(Eq)

///|
pub impl Show for PackageFile with output(self, logger) {
  logger.write_string("{path: ")
  logger.write_object(self.path)
  logger.write_string(", sha256: ")
  logger.write_object(self.sha256)
  logger.write_string(", size: ")
  logger.write_object(self.size)
  logger.write_char('}')
}

///|
pub(all) struct ResolvedDependency {
  name : String
  version : String
  manager : String
  evidence_path : String
  content_digest : String
} derive(Eq)

///|
pub impl Show for ResolvedDependency with output(self, logger) {
  logger.write_string("{name: ")
  logger.write_object(self.name)
  logger.write_string(", version: ")
  logger.write_object(self.version)
  logger.write_string(", manager: ")
  logger.write_object(self.manager)
  logger.write_string(", evidence_path: ")
  logger.write_object(self.evidence_path)
  logger.write_string(", content_digest: ")
  logger.write_object(self.content_digest)
  logger.write_char('}')
}

///|
pub fn trim_spaces(value : String) -> String {
  let mut start = 0
  let mut end = value.length()
  while start < end {
    let c = value.code_unit_at(start)
    if c == ' ' || c == '\t' || c == '\r' {
      start += 1
    } else {
      break
    }
  }
  while end > start {
    let c = value.code_unit_at(end - 1)
    if c == ' ' || c == '\t' || c == '\r' {
      end -= 1
    } else {
      break
    }
  }
  value[start:end].to_string()
}

///|
pub fn join_path(base : String, child : String) -> String {
  if base == "" || base == "." {
    "./\{child}"
  } else if base.has_suffix("/") {
    "\{base}\{child}"
  } else {
    "\{base}/\{child}"
  }
}

///|
pub fn strip_relative_prefix(path : String) -> String {
  if path.has_prefix("./") {
    path[2:].to_string()
  } else {
    path
  }
}

///|
pub fn resolve_path(base : String, child : String) -> String {
  if child == "" {
    base
  } else if child.has_prefix("/") {
    child
  } else if child.has_prefix("./") {
    join_path(base, child[2:].to_string())
  } else {
    join_path(base, child)
  }
}

///|
pub fn resolve_root_path(repo : String, evidence_path : String) -> String {
  if evidence_path.has_prefix("/") {
    evidence_path
  } else {
    resolve_path(repo, evidence_path)
  }
}

///|
pub fn display_path(repo : String, path : String) -> String {
  let normalized_repo = if repo.has_suffix("/") {
    repo[:repo.length() - 1].to_string()
  } else {
    repo
  }
  let repo_prefix = "\{normalized_repo}/"
  if path == normalized_repo {
    "."
  } else if path.has_prefix(repo_prefix) {
    path[repo_prefix.length():].to_string()
  } else {
    path
  }
}

///|
pub fn directory_exists(path : String) -> Bool {
  let out = try? @fs.is_dir(path)
  out is Ok(true)
}

///|
fn collect_snapshot_paths(
  root_path : String,
  relative_dir : String,
  out : Array[String],
) -> Result[Unit, String] {
  let current_dir = if relative_dir == "" {
    root_path
  } else {
    join_path(root_path, relative_dir)
  }
  let entries = @fs.read_dir(current_dir) catch {
    err =>
      return Err(
        "cannot read package directory \{current_dir}: \{err.to_string()}",
      )
  }
  entries.sort()
  for i in 0..<entries.length() {
    let entry = entries[i]
    let relative_path = if relative_dir == "" {
      entry
    } else {
      "\{relative_dir}/\{entry}"
    }
    let absolute_path = join_path(root_path, relative_path)
    let is_dir = try? @fs.is_dir(absolute_path)
    if is_dir is Ok(true) {
      let nested = collect_snapshot_paths(root_path, relative_path, out)
      guard nested is Ok(_) else { return Err(nested.unwrap_err()) }
      continue
    }
    let is_file = try? @fs.is_file(absolute_path)
    if is_file is Ok(true) {
      out.push(relative_path)
    }
  }
  Ok(())
}

///|
pub fn snapshot_files(root_path : String) -> Result[Array[PackageFile], String] {
  if !@fs.path_exists(root_path) {
    return Err("package root does not exist: \{root_path}")
  }
  let relative_paths : Array[String] = []
  let collect_out = collect_snapshot_paths(root_path, "", relative_paths)
  guard collect_out is Ok(_) else { return Err(collect_out.unwrap_err()) }
  if relative_paths.is_empty() {
    return Err("package root has no files: \{root_path}")
  }
  let files : Array[PackageFile] = []
  for i in 0..<relative_paths.length() {
    let relative_path = relative_paths[i]
    let absolute_path = join_path(root_path, relative_path)
    let bytes = @fs.read_file_to_bytes(absolute_path) catch {
      err =>
        return Err(
          "cannot read package file \{absolute_path}: \{err.to_string()}"
        )
    }
    files.push({
      path: relative_path,
      sha256: @sha256.sha256_hexdigest(bytes),
      size: bytes.length(),
    })
  }
  Ok(files)
}

///|
pub fn snapshot_digest(files : Array[PackageFile]) -> String {
  let lines : Array[String] = []
  for i in 0..<files.length() {
    let file = files[i]
    lines.push("\{file.path} \{file.sha256} \{file.size}")
  }
  @sha256.sha256_hexdigest(@utf8.encode(lines.join("\n")))
}

///|
pub fn read_json_object(
  path : String,
  label : String,
) -> Result[Map[String, Json], String] {
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read \{label}: \{err.to_string()}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(object)) else {
    return Err("invalid json in \{label}")
  }
  Ok(object)
}

///|
pub fn json_string_field(object : Map[String, Json], field : String) -> String? {
  match object.get(field) {
    Some(String(value)) if trim_spaces(value) != "" => Some(trim_spaces(value))
    _ => None
  }
}

///|
pub fn dependency_resolution(
  repo : String,
  manager : String,
  name : String,
  version : String,
  root_path : String,
) -> Result[ResolvedDependency, String] {
  let snapshot_out = snapshot_files(root_path)
  guard snapshot_out is Ok(files) else { return Err(snapshot_out.unwrap_err()) }
  Ok({
    name,
    version,
    manager,
    evidence_path: display_path(repo, root_path),
    content_digest: snapshot_digest(files),
  })
}

///|
pub fn home_dir() -> String? {
  match @sys.get_env_var("HOME") {
    Some(value) => {
      let trimmed = trim_spaces(value)
      if trimmed == "" {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
pub fn env_path(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) => {
      let trimmed = trim_spaces(value)
      if trimmed == "" {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
pub fn strip_wrapping_quotes(value : String) -> String {
  let trimmed = trim_spaces(value)
  if trimmed.length() >= 2 &&
    (
      (
        trimmed.code_unit_at(0) == '"' &&
        trimmed.code_unit_at(trimmed.length() - 1) == '"'
      ) ||
      (
        trimmed.code_unit_at(0) == '\'' &&
        trimmed.code_unit_at(trimmed.length() - 1) == '\''
      )
    ) {
    trimmed[1:trimmed.length() - 1].to_string()
  } else {
    trimmed
  }
}
