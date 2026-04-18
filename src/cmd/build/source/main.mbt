///|
pub fn resolve_source_in_workspace(
  workspace_root : String,
  spec : @vp.SourceSpec,
) -> Result[@vp.VirtualPackage, String] {
  match spec {
    LocalWorkspace(source) => resolve_local_workspace(source.root_dir)
    CargoPackage(source) => resolve_cargo_package(workspace_root, source)
    GoModule(source) => resolve_go_module(workspace_root, source)
    TerraformPackage(source) =>
      resolve_terraform_package(workspace_root, source)
    GitRepo(source) => resolve_git_repo(source)
  }
}

///|
pub fn resolve_source(spec : @vp.SourceSpec) -> Result[@vp.VirtualPackage, String] {
  let workspace_root = match spec {
    LocalWorkspace(source) => source.root_dir
    _ => "."
  }
  resolve_source_in_workspace(workspace_root, spec)
}
