///|
fn terraform_modules_manifest_path(workspace_root : String) -> String {
  "\{workspace_root}/.terraform/modules/modules.json"
}

///|
fn parse_json_string(object : Map[String, Json], key : String) -> String? {
  match object.get(key) {
    Some(String(value)) if value.trim().to_string() != "" => Some(value.trim().to_string())
    _ => None
  }
}

///|
fn terraform_module_dir_from_manifest(
  workspace_root : String,
  source : @vp.TerraformPackageSource,
) -> String? {
  let manifest_path = terraform_modules_manifest_path(workspace_root)
  if !@fs.path_exists(manifest_path) {
    return None
  }
  let text = @fs.read_file_to_string(manifest_path) catch { _ => return None }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(root)) else { return None }
  guard root.get("Modules") is Some(Array(modules)) else { return None }
  for i in 0..<modules.length() {
    match modules[i] {
      Object(module_obj) => {
        let module_source = parse_json_string(module_obj, "Source")
        let module_key = parse_json_string(module_obj, "Key")
        let module_dir = parse_json_string(module_obj, "Dir")
        let matches_source =
          module_source == Some(source.source) || module_key == Some(source.source)
        if !matches_source {
          continue
        }
        let matches_version = match source.version {
          Some(version) => parse_json_string(module_obj, "Version") == Some(version)
          None => true
        }
        if !matches_version {
          continue
        }
        guard module_dir is Some(dir) else { continue }
        let abs_dir = resolve_path(workspace_root, dir)
        let dir_out = try? @fs.is_dir(abs_dir)
        if dir_out is Ok(true) {
          return Some(abs_dir)
        }
      }
      _ => ()
    }
  }
  None
}

///|
fn terraform_provider_lock_exists(workspace_root : String) -> Bool {
  @fs.path_exists("\{workspace_root}/.terraform.lock.hcl")
}

///|
fn ignored_terraform_cache_path(relative_path : String) -> Bool {
  ignored_local_path(relative_path) ||
  relative_path == ".terraform" ||
  relative_path.has_prefix(".terraform/")
}

///|
pub fn resolve_terraform_package(
  workspace_root : String,
  source : @vp.TerraformPackageSource,
) -> Result[@vp.VirtualPackage, String] {
  if source.kind == "module" {
    if source.source.has_prefix("./") || source.source.has_prefix("../") {
      let module_root = resolve_path(workspace_root, source.source)
      return resolve_directory_package(
        module_root,
        "terraform",
        "module:\{source.source}",
        source.source,
        ignored_terraform_cache_path,
      )
    }
    let module_dir = terraform_module_dir_from_manifest(workspace_root, source)
    guard module_dir is Some(root_dir) else {
      return Err("Terraform modules are not initialized. Run `terraform init`.")
    }
    return resolve_directory_package(
      root_dir,
      "terraform",
      match source.version {
        Some(version) => "module:\{source.source}@\{version}"
        None => "module:\{source.source}"
      },
      source.source,
      ignored_terraform_cache_path,
    )
  }
  if source.kind == "provider" {
    if !terraform_provider_lock_exists(workspace_root) {
      return Err("Terraform providers are not initialized. Run `terraform init`.")
    }
    let lock_file = "\{workspace_root}/.terraform.lock.hcl"
    let bytes = @fs.read_file_to_bytes(lock_file) catch {
      err => return Err("cannot read file \{lock_file}: \{@debug.to_repr(err)}")
    }
    let virtual_file_out = @vp.virtual_file(".terraform.lock.hcl", bytes)
    guard virtual_file_out is Ok(file) else {
      return Err(virtual_file_out.unwrap_err())
    }
    return Ok({
      source_kind: "terraform",
      source_id: match source.version {
        Some(version) => "provider:\{source.source}@\{version}"
        None => "provider:\{source.source}"
      },
      display_name: source.source,
      root_hint: workspace_root,
      files: [file],
    })
  }
  Err("unsupported Terraform package kind: \{source.kind}")
}
