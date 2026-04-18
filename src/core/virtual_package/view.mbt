///|
pub(all) struct ReadonlyPackageView {
  pkg : VirtualPackage
} derive(Eq)

///|
pub fn view_of(pkg : VirtualPackage) -> ReadonlyPackageView {
  { pkg, }
}

///|
fn find_file(
  package_view : ReadonlyPackageView,
  path : String,
) -> VirtualFile? {
  let path_out = normalize_path(path)
  guard path_out is Ok(normalized_path) else { return None }
  for i in 0..<package_view.pkg.files.length() {
    let file = package_view.pkg.files[i]
    if file.path == normalized_path {
      return Some(file)
    }
  }
  None
}

///|
pub fn ReadonlyPackageView::list_paths(self : ReadonlyPackageView) -> Array[String] {
  let paths : Array[String] = []
  for i in 0..<self.pkg.files.length() {
    paths.push(self.pkg.files[i].path)
  }
  paths
}

///|
pub fn ReadonlyPackageView::exists(self : ReadonlyPackageView, path : String) -> Bool {
  find_file(self, path) is Some(_)
}

///|
pub fn ReadonlyPackageView::read_bytes(
  self : ReadonlyPackageView,
  path : String,
) -> Result[Bytes, String] {
  match find_file(self, path) {
    Some(file) => Ok(file.bytes)
    None => Err("package file not found: \{path}")
  }
}

///|
pub fn ReadonlyPackageView::read_text(
  self : ReadonlyPackageView,
  path : String,
) -> Result[String, String] {
  let bytes_out = self.read_bytes(path)
  guard bytes_out is Ok(bytes) else { return Err(bytes_out.unwrap_err()) }
  let text = @utf8.decode(bytes) catch {
    _ => return Err("invalid utf-8 bytes in \{path}")
  }
  Ok(text)
}
