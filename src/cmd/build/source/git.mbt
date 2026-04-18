///|
fn shell_quote(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn ensure_tree_removed(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  let is_dir = try? @fs.is_dir(path)
  if is_dir is Ok(true) {
    let entries = @fs.read_dir(path) catch { _ => [] }
    for i in 0..<entries.length() {
      ensure_tree_removed("\{path}/\{entries[i]}")
    }
    @fs.remove_dir(path) catch { _ => () }
  } else {
    @fs.remove_file(path) catch { _ => () }
  }
}

///|
fn allocate_git_checkout_dir() -> Result[String, String] {
  let (exit_code, stdout, stderr) = @process.run_command_capture(
    "mktemp -d /tmp/cogna-source-git-XXXXXX",
  )
  if exit_code != 0 {
    return Err(
      "failed to create temporary git checkout directory: \{stderr.trim().to_string()}",
    )
  }
  let path = stdout.trim().to_string()
  if path == "" {
    Err("failed to create temporary git checkout directory: empty path")
  } else {
    Ok(path)
  }
}

///|
fn run_git_command(command : String) -> Result[Unit, String] {
  let (exit_code, _, stderr) = @process.run_command_capture(command)
  if exit_code == 0 {
    Ok(())
  } else {
    Err(stderr.trim().to_string())
  }
}

///|
pub fn resolve_git_repo(source : @vp.GitRepoSource) -> Result[@vp.VirtualPackage, String] {
  let checkout_dir_out = allocate_git_checkout_dir()
  guard checkout_dir_out is Ok(checkout_dir) else {
    return Err(checkout_dir_out.unwrap_err())
  }
  let clone_command =
    "git clone --quiet \{shell_quote(source.url)} \{shell_quote(checkout_dir)}"
  let clone_out = run_git_command(clone_command)
  guard clone_out is Ok(_) else {
    ensure_tree_removed(checkout_dir)
    return Err("git clone failed: \{clone_out.unwrap_err()}")
  }
  match source.ref_ {
    Some(ref_) => {
      let checkout_command =
        "git -C \{shell_quote(checkout_dir)} checkout --quiet \{shell_quote(ref_)}"
      let checkout_out = run_git_command(checkout_command)
      guard checkout_out is Ok(_) else {
        ensure_tree_removed(checkout_dir)
        return Err("git checkout failed: \{checkout_out.unwrap_err()}")
      }
    }
    None => ()
  }
  let package_out = resolve_directory_package(
    checkout_dir,
    "git",
    match source.ref_ {
      Some(ref_) => "\{source.url}@\{ref_}"
      None => source.url
    },
    source.url,
    ignored_local_path,
  )
  ensure_tree_removed(checkout_dir)
  package_out
}
