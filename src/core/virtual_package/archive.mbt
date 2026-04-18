///|
fn common_archive_root(paths : Array[String]) -> String? {
  if paths.is_empty() {
    return None
  }
  let first = first_path_segment(paths[0])
  if first == "" {
    return None
  }
  for i in 0..<paths.length() {
    if first_path_segment(paths[i]) != first {
      return None
    }
  }
  Some(first)
}

///|
pub fn archive_files(entries : Array[(String, Bytes)]) -> Result[Array[VirtualFile], String] {
  let normalized_paths : Array[String] = []
  for i in 0..<entries.length() {
    let (path, _) = entries[i]
    let path_out = normalize_path(path)
    guard path_out is Ok(normalized_path) else { return Err(path_out.unwrap_err()) }
    normalized_paths.push(normalized_path)
  }
  let root_prefix = common_archive_root(normalized_paths)
  let files : Array[VirtualFile] = []
  for i in 0..<entries.length() {
    let (_, bytes) = entries[i]
    let normalized_path = normalized_paths[i]
    let final_path = match root_prefix {
      Some(prefix) => strip_root_prefix(normalized_path, prefix)
      None => Ok(normalized_path)
    }
    guard final_path is Ok(path) else { return Err(final_path.unwrap_err()) }
    let file_out = virtual_file(path, bytes)
    guard file_out is Ok(file) else { return Err(file_out.unwrap_err()) }
    files.push(file)
  }
  Ok(files)
}
