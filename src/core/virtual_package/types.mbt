///|
pub(all) struct LocalWorkspaceSource {
  root_dir : String
} derive(Eq)

///|
pub(all) struct CargoPackageSource {
  name : String
  version : String
  registry : String?
} derive(Eq)

///|
pub(all) struct GoModuleSource {
  module_path : String
  version : String
  proxy : String?
} derive(Eq)

///|
pub(all) struct TerraformPackageSource {
  kind : String
  source : String
  version : String?
} derive(Eq)

///|
pub(all) struct GitRepoSource {
  url : String
  ref_ : String?
} derive(Eq)

///|
pub(all) enum SourceSpec {
  LocalWorkspace(LocalWorkspaceSource)
  CargoPackage(CargoPackageSource)
  GoModule(GoModuleSource)
  TerraformPackage(TerraformPackageSource)
  GitRepo(GitRepoSource)
} derive(Eq)

///|
pub(all) struct VirtualFile {
  path : String
  bytes : Bytes
  sha256 : String
  size : Int
} derive(Eq)

///|
pub(all) struct VirtualPackage {
  source_kind : String
  source_id : String
  display_name : String
  root_hint : String
  files : Array[VirtualFile]
} derive(Eq)

///|
pub fn source_spec_kind(spec : SourceSpec) -> String {
  match spec {
    LocalWorkspace(_) => "local"
    CargoPackage(_) => "cargo"
    GoModule(_) => "gomod"
    TerraformPackage(_) => "terraform"
    GitRepo(_) => "git"
  }
}

///|
pub fn virtual_file(path : String, bytes : Bytes) -> Result[VirtualFile, String] {
  let path_out = normalize_path(path)
  guard path_out is Ok(normalized_path) else { return Err(path_out.unwrap_err()) }
  Ok({
    path: normalized_path,
    bytes,
    sha256: @sha256.sha256_hexdigest(bytes),
    size: bytes.length(),
  })
}
