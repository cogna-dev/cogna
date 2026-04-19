///|
pub(all) struct CaseRunResult {
  case_id : String
  status : String
  reason : String?
  snapshot_dir : String?
} derive(Eq)

///|
fn ensure_dir(path : String) -> Result[Unit, String] {
  if @fs.path_exists(path) {
    return Ok(())
  }
  @fs.create_dir(path) catch {
    err => return Err("cannot create directory \{path}: \{err.to_string()}")
  }
  Ok(())
}

///|
fn ensure_parent_dirs(path : String) -> Result[Unit, String] {
  let parts = path.split("/").to_array()
  if parts.length() <= 1 {
    return Ok(())
  }
  let mut current = parts[0].to_string()
  if current == "" {
    current = "/"
  }
  for i in 1..<(parts.length() - 1) {
    if current == "/" {
      current = "/\{parts[i]}"
    } else {
      current = "\{current}/\{parts[i]}"
    }
    let out = ensure_dir(current)
    guard out is Ok(_) else { return Err(out.unwrap_err()) }
  }
  Ok(())
}

///|
fn remove_tree(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  let is_dir = try? @fs.is_dir(path)
  if is_dir is Ok(true) {
    let entries = @fs.read_dir(path) catch { _ => [] }
    for i in 0..<entries.length() {
      remove_tree("\{path}/\{entries[i]}")
    }
    @fs.remove_dir(path) catch { _ => () }
  } else {
    @fs.remove_file(path) catch { _ => () }
  }
}

///|
fn read_source_view(case_ : E2eCase) -> Result[@vp.ReadonlyPackageView, String] {
  let workspace_root = match case_.source {
    LocalWorkspace(_) => "."
    _ =>
      match @sys.get_env_var("COGNA_REMOTE_WORKSPACE_ROOT") {
        Some(value) => {
          let path = value.trim().to_string()
          if path == "" {
            "."
          } else {
            path
          }
        }
        None => "."
      }
  }
  let spec = match case_.source {
    LocalWorkspace(path) => @vp.SourceSpec::LocalWorkspace({ root_dir: path })
    CargoPackage(name, version) =>
      @vp.SourceSpec::CargoPackage({
        name,
        version,
        registry: None,
      })
    GoModule(module_path, version) =>
      @vp.SourceSpec::GoModule({
        module_path,
        version,
        proxy: None,
      })
    TerraformPackage(kind, source, version) =>
      @vp.SourceSpec::TerraformPackage({
        kind,
        source,
        version,
      })
    GitRepo(url, ref_) => @vp.SourceSpec::GitRepo({ url, ref_ })
  }
  let package_out = @source.resolve_source_in_workspace(workspace_root, spec)
  guard package_out is Ok(package_) else {
    return Err(package_out.unwrap_err())
  }
  Ok(@vp.view_of(package_))
}

///|
fn include_path_for(extractor : String, path : String) -> Bool {
  match extractor {
    "rust" => path.has_suffix(".rs")
    "go" => path.has_suffix(".go")
    "terraform" => path.has_suffix(".tf")
    "openapi" => path.has_suffix(".yaml") || path.has_suffix(".yml")
    _ => false
  }
}

///|
fn profile_for_extractor(extractor : String) -> String {
  match extractor {
    "rust" => "rust-crate"
    "go" => "go-module"
    "terraform" => "terraform-module"
    "openapi" => "openapi-spec"
    _ => "openapi-spec"
  }
}

///|
fn purl_for_case(case_ : E2eCase) -> String {
  match profile_for_extractor(case_.extractor) {
    "rust-crate" => "pkg:cargo/e2e/\{case_.id}@0.0.0"
    "go-module" => "pkg:golang/e2e/\{case_.id}@0.0.0"
    "terraform-module" => "pkg:terraform/e2e/\{case_.id}@0.0.0"
    _ => "pkg:openapi/e2e/\{case_.id}@0.0.0"
  }
}

///|
fn remote_e2e_enabled() -> Bool {
  match @sys.get_env_var("COGNA_ENABLE_REMOTE_E2E") {
    Some("true") => true
    _ => false
  }
}

///|
fn git_remote_e2e_enabled() -> Bool {
  match @sys.get_env_var("COGNA_ENABLE_GIT_REMOTE_E2E") {
    Some("true") => true
    _ =>
      match @sys.get_env_var("COGNA_ENABLE_GIT_E2E") {
        Some("true") => true
        _ => false
      }
  }
}

///|
pub fn rust_package_remote_e2e_enabled() -> Bool {
  match @sys.get_env_var("COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E") {
    Some("true") => true
    _ => false
  }
}

///|
fn extract_rust_case(
  case_ : E2eCase,
  package_view : @vp.ReadonlyPackageView,
) -> Result[Array[Json], String] {
  let declarations : Array[Json] = []
  let symbols : Array[Json] = []
  let paths = package_view.list_paths()
  for i in 0..<paths.length() {
    let relative_path = paths[i]
    if !include_path_for("rust", relative_path) {
      continue
    }
    let text_out = package_view.read_text(relative_path)
    guard text_out is Ok(content) else {
      return Err("cannot read source file \{relative_path}: \{text_out.unwrap_err()}")
    }
    let lines = content.split("\n").to_array().map(line => line.to_string())
    @extract_rust.extract_file(
      declarations,
      symbols,
      "rust-crate",
      "canonical",
      relative_path,
      lines,
    )
  }
  @extract_rust.postprocess_declarations(declarations, "rust-crate")
  let final_declarations = @extract.sort_and_dedup(declarations, "id")
  if final_declarations.is_empty() {
    return Err("extractor produced no declarations for case \{case_.id}")
  }
  Ok(final_declarations)
}

///|
fn extract_go_case(
  case_ : E2eCase,
  package_view : @vp.ReadonlyPackageView,
) -> Result[Array[Json], String] {
  let declarations : Array[Json] = []
  let symbols : Array[Json] = []
  let paths = package_view.list_paths()
  for i in 0..<paths.length() {
    let relative_path = paths[i]
    if !include_path_for("go", relative_path) {
      continue
    }
    let text_out = package_view.read_text(relative_path)
    guard text_out is Ok(content) else {
      return Err("cannot read source file \{relative_path}: \{text_out.unwrap_err()}")
    }
    let lines = content.split("\n").to_array().map(line => line.to_string())
    @extract_go.extract_file(
      declarations,
      symbols,
      "go-module",
      "canonical",
      relative_path,
      lines,
    )
  }
  @extract_go.postprocess_declarations(declarations, "go-module")
  let final_declarations = @extract.sort_and_dedup(declarations, "id")
  if final_declarations.is_empty() {
    return Err("extractor produced no declarations for case \{case_.id}")
  }
  Ok(final_declarations)
}

///|
fn extract_terraform_case(
  case_ : E2eCase,
  package_view : @vp.ReadonlyPackageView,
) -> Result[Array[Json], String] {
  let declarations : Array[Json] = []
  let symbols : Array[Json] = []
  let paths = package_view.list_paths()
  for i in 0..<paths.length() {
    let relative_path = paths[i]
    if !include_path_for("terraform", relative_path) {
      continue
    }
    let text_out = package_view.read_text(relative_path)
    guard text_out is Ok(content) else {
      return Err("cannot read source file \{relative_path}: \{text_out.unwrap_err()}")
    }
    let lines = content.split("\n").to_array().map(line => line.to_string())
    @extract_terraform.extract_file(
      declarations,
      symbols,
      "terraform-module",
      "canonical",
      relative_path,
      lines,
    )
  }
  let final_declarations = @extract.sort_and_dedup(declarations, "id")
  if final_declarations.is_empty() {
    return Err("extractor produced no declarations for case \{case_.id}")
  }
  Ok(final_declarations)
}

///|
fn extract_openapi_case(
  case_ : E2eCase,
  package_view : @vp.ReadonlyPackageView,
) -> Result[Array[Json], String] {
  let declarations : Array[Json] = []
  let symbols : Array[Json] = []
  let paths = package_view.list_paths()
  for i in 0..<paths.length() {
    let relative_path = paths[i]
    if !include_path_for("openapi", relative_path) {
      continue
    }
    let text_out = package_view.read_text(relative_path)
    guard text_out is Ok(content) else {
      return Err("cannot read source file \{relative_path}: \{text_out.unwrap_err()}")
    }
    let lines = content.split("\n").to_array().map(line => line.to_string())
    @extract_openapi.extract_file(
      declarations,
      symbols,
      "openapi-spec",
      "canonical",
      relative_path,
      lines,
    )
  }
  let final_declarations = @extract.sort_and_dedup(declarations, "id")
  if final_declarations.is_empty() {
    return Err("extractor produced no declarations for case \{case_.id}")
  }
  Ok(final_declarations)
}

///|
fn manifest_json(case_ : E2eCase) -> Json {
  {
    "schemaVersion": "ciq-bundle/v1",
    "purl": purl_for_case(case_),
    "profile": profile_for_extractor(case_.extractor),
    "source": {
      "repo": ".",
      "ref": "main",
      "commit": "unknown",
    },
    "artifacts": [
      {
        "path": "declarations.ndjson",
        "sha256": "<computed>",
        "compression": "none",
      },
    ],
  }
}

///|
fn metadata_json(case_ : E2eCase, declarations : Array[Json]) -> Json {
  {
    "schemaVersion": "ciq-metadata/v1",
    "profile": profile_for_extractor(case_.extractor),
    "extractor": {
      "role": "canonical",
      "backend": "canonical",
      "mode": "parser-first",
      "server": "canonical",
      "version": "canonical-v1",
      "fallback": false,
      "stats": {
        "declarations": declarations.length(),
        "diagnosticFiles": 0,
      },
    },
    "case": {
      "id": case_.id,
      "extractor": case_.extractor,
    },
  }
}

///|
fn checksums_text(
  declarations_sha : String,
  manifest_sha : String,
  metadata_sha : String,
) -> String {
  "declarations.ndjson  \{declarations_sha}\n" +
  "manifest.json  \{manifest_sha}\n" +
  "metadata.json  \{metadata_sha}\n"
}

///|
fn write_text(path : String, text : String) -> Result[Unit, String] {
  let parent_out = ensure_parent_dirs(path)
  guard parent_out is Ok(_) else { return Err(parent_out.unwrap_err()) }
  @fs.write_string_to_file(path, text) catch {
    err => return Err("cannot write file \{path}: \{err.to_string()}")
  }
  Ok(())
}

///|
fn snapshot_root(case_ : E2eCase) -> String {
  "./e2e/extractors/\{case_.extractor}/\{case_.id}/snapshots/cogna"
}

///|
fn write_case_outputs(
  case_ : E2eCase,
  declarations : Array[Json],
) -> Result[String, String] {
  let root = snapshot_root(case_)
  remove_tree(root)
  let parent_out = ensure_parent_dirs("\{root}/declarations.ndjson")
  guard parent_out is Ok(_) else { return Err(parent_out.unwrap_err()) }
  let root_out = ensure_dir(root)
  guard root_out is Ok(_) else { return Err(root_out.unwrap_err()) }

  let declarations_text = @extract.to_ndjson(declarations)
  let declarations_sha = @sha256.sha256_hexdigest(@utf8.encode(declarations_text))

  let manifest_obj = manifest_json(case_)
  guard manifest_obj is Object(manifest_map) else {
    return Err("manifest must be object")
  }
  guard manifest_map.get("artifacts") is Some(Array(artifacts)) else {
    return Err("manifest artifacts missing")
  }
  if artifacts.length() > 0 {
    guard artifacts[0] is Object(artifact) else {
      return Err("manifest artifact must be object")
    }
    artifact["sha256"] = Json::string(declarations_sha)
  }
  let manifest_text = manifest_obj.stringify(indent=2)
  let manifest_sha = @sha256.sha256_hexdigest(@utf8.encode(manifest_text))

  let metadata_text = metadata_json(case_, declarations).stringify(indent=2)
  let metadata_sha = @sha256.sha256_hexdigest(@utf8.encode(metadata_text))
  let checksums = checksums_text(declarations_sha, manifest_sha, metadata_sha)

  let decl_out = write_text("\{root}/declarations.ndjson", declarations_text)
  guard decl_out is Ok(_) else { return Err(decl_out.unwrap_err()) }
  let manifest_out = write_text("\{root}/manifest.json", manifest_text)
  guard manifest_out is Ok(_) else { return Err(manifest_out.unwrap_err()) }
  let metadata_out = write_text("\{root}/metadata.json", metadata_text)
  guard metadata_out is Ok(_) else { return Err(metadata_out.unwrap_err()) }
  let checksums_out = write_text("\{root}/checksums.txt", checksums)
  guard checksums_out is Ok(_) else { return Err(checksums_out.unwrap_err()) }

  Ok(root)
}

///|
pub fn run_case(case_ : E2eCase) -> CaseRunResult {
  if case_.extractor != "rust" &&
    case_.extractor != "go" &&
    case_.extractor != "terraform" &&
    case_.extractor != "openapi" {
    return {
      case_id: case_.id,
      status: "skipped",
      reason: Some("unsupported extractor in phase-1 harness: \{case_.extractor}"),
      snapshot_dir: None,
    }
  }
  match case_.source {
    CargoPackage(_, _) => {
      if !remote_e2e_enabled() {
        return {
          case_id: case_.id,
          status: "skipped",
          reason: Some(
            "remote e2e cases are disabled by default (set COGNA_ENABLE_REMOTE_E2E=true)",
          ),
          snapshot_dir: None,
        }
      }
      if case_.extractor == "rust" && !rust_package_remote_e2e_enabled() {
        return {
          case_id: case_.id,
          status: "skipped",
          reason: Some(
            "rust remote package cases are disabled by default (set COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E=true)",
          ),
          snapshot_dir: None,
        }
      }
    }
    GitRepo(_, _) => {
      if !git_remote_e2e_enabled() {
        return {
          case_id: case_.id,
          status: "skipped",
          reason: Some(
            "git remote e2e cases are disabled by default (set COGNA_ENABLE_GIT_REMOTE_E2E=true)",
          ),
          snapshot_dir: None,
        }
      }
    }
    GoModule(_, _) => {
      if !remote_e2e_enabled() {
        return {
          case_id: case_.id,
          status: "skipped",
          reason: Some(
            "remote e2e cases are disabled by default (set COGNA_ENABLE_REMOTE_E2E=true)",
          ),
          snapshot_dir: None,
        }
      }
    }
    TerraformPackage(_, source, _) => {
      if !source.has_prefix("./") && !source.has_prefix("../") && !remote_e2e_enabled() {
        return {
          case_id: case_.id,
          status: "skipped",
          reason: Some(
            "remote e2e cases are disabled by default (set COGNA_ENABLE_REMOTE_E2E=true)",
          ),
          snapshot_dir: None,
        }
      }
    }
    _ => ()
  }
  let view_out = read_source_view(case_)
  guard view_out is Ok(package_view) else {
    return {
      case_id: case_.id,
      status: "failed",
      reason: Some(view_out.unwrap_err()),
      snapshot_dir: None,
    }
  }
  let declarations_out = match case_.extractor {
    "rust" => extract_rust_case(case_, package_view)
    "go" => extract_go_case(case_, package_view)
    "terraform" => extract_terraform_case(case_, package_view)
    "openapi" => extract_openapi_case(case_, package_view)
    _ => Err("unsupported extractor in phase-1 harness: \{case_.extractor}")
  }
  guard declarations_out is Ok(declarations) else {
    return {
      case_id: case_.id,
      status: "failed",
      reason: Some(declarations_out.unwrap_err()),
      snapshot_dir: None,
    }
  }
  let write_out = write_case_outputs(case_, declarations)
  guard write_out is Ok(path) else {
    return {
      case_id: case_.id,
      status: "failed",
      reason: Some(write_out.unwrap_err()),
      snapshot_dir: None,
    }
  }
  {
    case_id: case_.id,
    status: "passed",
    reason: None,
    snapshot_dir: Some(path),
  }
}
