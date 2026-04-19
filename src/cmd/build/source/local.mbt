///|
pub fn ignored_local_path(relative_path : String) -> Bool {
  relative_path == "dist" ||
  relative_path.has_prefix("dist/") ||
  relative_path == ".git" ||
  relative_path.has_prefix(".git/")
}

///|
fn collect_directory_files(
  root_dir : String,
  relative_dir : String,
  out : Array[@vp.VirtualFile],
  ignored : (String) -> Bool,
) -> Result[Unit, String] {
  let dir_path = if relative_dir == "" {
    root_dir
  } else {
    "\{root_dir}/\{relative_dir}"
  }
  let entries = @fs.read_dir(dir_path) catch {
    err => return Err("cannot read directory \{dir_path}: \{@debug.to_repr(err)}")
  }
  entries.sort()
  for i in 0..<entries.length() {
    let entry = entries[i]
    let relative_path = if relative_dir == "" {
      entry
    } else {
      "\{relative_dir}/\{entry}"
    }
    if ignored(relative_path) {
      continue
    }
    let absolute_path = "\{root_dir}/\{relative_path}"
    let dir_out = try? @fs.is_dir(absolute_path)
    if dir_out is Ok(true) {
      let nested_out = collect_directory_files(root_dir, relative_path, out, ignored)
      guard nested_out is Ok(_) else { return Err(nested_out.unwrap_err()) }
      continue
    }
    let file_out = try? @fs.is_file(absolute_path)
    if file_out is Ok(true) {
      let bytes = @fs.read_file_to_bytes(absolute_path) catch {
        err => return Err("cannot read file \{absolute_path}: \{@debug.to_repr(err)}")
      }
      let virtual_file_out = @vp.virtual_file(relative_path, bytes)
      guard virtual_file_out is Ok(file) else {
        return Err(virtual_file_out.unwrap_err())
      }
      out.push(file)
    }
  }
  Ok(())
}

///|
pub fn resolve_directory_package(
  root_dir : String,
  source_kind : String,
  source_id : String,
  display_name : String,
  ignored : (String) -> Bool,
) -> Result[@vp.VirtualPackage, String] {
  if !@fs.path_exists(root_dir) {
    return Err("package root does not exist: \{root_dir}")
  }
  let dir_out = try? @fs.is_dir(root_dir)
  guard dir_out is Ok(true) else {
    return Err("package root is not a directory: \{root_dir}")
  }
  let files : Array[@vp.VirtualFile] = []
  let collect_out = collect_directory_files(root_dir, "", files, ignored)
  guard collect_out is Ok(_) else { return Err(collect_out.unwrap_err()) }
  Ok({
    source_kind,
    source_id,
    display_name,
    root_hint: root_dir,
    files,
  })
}

///|
pub fn resolve_local_workspace(root_dir : String) -> Result[@vp.VirtualPackage, String] {
  resolve_directory_package(
    root_dir,
    "local",
    root_dir,
    root_dir,
    ignored_local_path,
  )
}
