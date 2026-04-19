///|
fn remove_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn reset_repo(path : String) -> Unit {
  remove_if_exists("\{path}/cogna.yaml")
  remove_if_exists("\{path}/dist/manifest.json")
  remove_if_exists("\{path}/dist/declarations.ndjson")
  remove_if_exists("\{path}/dist/metadata.json")
  remove_if_exists("\{path}/dist/checksums.txt")
  remove_if_exists("\{path}/dist/bundle.ciq.tgz")
  remove_dir_if_exists("\{path}/dist")
  remove_dir_if_exists("\{path}/.cogna")
}

///|
fn read_text_snapshot(path : String, fail_message : String) -> String {
  @fs.read_file_to_string(path) catch {
    _ => abort(fail_message)
  }
}

///|
fn cleanup_source_tree(path : String, source_file : String) -> Unit {
  remove_if_exists("\{path}/\{source_file}")
  let segments = source_file.split("/").to_array()
  if segments.length() <= 1 {
    return
  }
  let dir_segments = segments.view(end=segments.length() - 1).to_array()
  for i in 0..<dir_segments.length() {
    let mut nested = path
    for j in 0..<(dir_segments.length() - i) {
      nested = "\{nested}/\{dir_segments[j]}"
    }
    remove_dir_if_exists(nested)
  }
}

///|
fn cleanup_case(path : String, source_file : String) -> Unit {
  reset_repo(path)
  cleanup_source_tree(path, source_file)
  remove_dir_if_exists(path)
}

///|
fn tmp_snapshot_repo(title : String) -> String {
  "/tmp/cogna-build-snapshot-\{title}"
}

///|
fn ensure_repo_with_file(
  path : String,
  file_path : String,
  content : String,
) -> Unit {
  if !@fs.path_exists(path) {
    @fs.create_dir(path) catch {
      _ => abort("failed to create fixture repo")
    }
  }
  let full = "\{path}/\{file_path}"
  let segments = file_path.split("/").to_array()
  let mut prefix = path
  for i in 0..<(segments.length() - 1) {
    prefix = "\{prefix}/\{segments[i]}"
    if !@fs.path_exists(prefix) {
      @fs.create_dir(prefix) catch {
        _ => abort("failed to create fixture dir")
      }
    }
  }
  @fs.write_string_to_file(full, content) catch {
    _ => abort("failed to write source fixture")
  }
}

///|
fn write_config_for(
  path : String,
  profile : String,
  include_glob : String,
) -> Unit {
  let purl = match profile {
    "go-module" => "pkg:golang/example/demo@0.1.0"
    "rust-crate" => "pkg:cargo/example-demo@0.1.0"
    "terraform-module" => "pkg:terraform/example/demo@0.1.0"
    "openapi-spec" => "pkg:openapi/example/demo@0.1.0"
    _ => "pkg:openapi/example/demo@0.1.0"
  }
  let content = (
      #|schemaVersion: ciq-config/v2
      #|profile: 
      #|purl: 
      #|source:
      #|  repo: https://github.com/example/demo
      #|  ref: main
      #|inputs:
      #|  include:
      #|    - 
      #|checks:
      #|  format: sarif
      #|  policy: ./.cogna/policies
      #|
    )
    .replace(old="profile: ", new="profile: \{profile}")
    .replace(old="purl: ", new="purl: \{purl}")
    .replace(old="    - ", new="    - \{include_glob}")
  @fs.write_string_to_file("\{path}/cogna.yaml", content) catch {
    _ => abort("failed to write config")
  }
}

///|
fn read_snapshot(path : String, fallback : String) -> String {
  @fs.read_file_to_string(path) catch {
    _ => fallback
  }
}

///|
fn persist_snapshot(path : String, content : String) -> Unit {
  let parts = path.split("/").to_array()
  if parts.length() > 1 {
    let mut dir = ""
    for i in 0..<(parts.length() - 1) {
      if i > 0 {
        dir = "\{dir}/"
      }
      dir = "\{dir}\{parts[i]}"
    }
    if dir != "" && !@fs.path_exists(dir) {
      @fs.create_dir(dir) catch {
        _ => abort("failed to create snapshot directory \{dir}")
      }
    }
  }
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to persist snapshot")
  }
}

///|
fn normalize_snapshot_text(content : String) -> String {
  let parsed = try? @json.parse(content)
  guard parsed is Ok(Object(root)) else { return content }

  if root.get("schemaVersion") is Some(String("ciq-metadata/v1")) {
    let extractor_obj : Map[String, Json] = match root.get("extractor") {
      Some(Object(e)) => e
      _ => {}
    }
    let normalized : Json = {
      "schemaVersion": root.get("schemaVersion").unwrap_or("ciq-metadata/v1"),
      "profile": root.get("profile").unwrap_or("unknown"),
      "inputPatterns": root.get("inputPatterns").unwrap_or([]),
      "build": root.get("build").unwrap_or({}),
      "extractor": {
        "role": extractor_obj.get("role").unwrap_or("canonical"),
        "mode": extractor_obj.get("mode").unwrap_or("unknown"),
        "backend": extractor_obj.get("backend").unwrap_or("canonical"),
        "server": extractor_obj.get("server").unwrap_or("canonical"),
        "version": extractor_obj.get("version").unwrap_or("canonical-v1"),
        "fallback": extractor_obj.get("fallback").unwrap_or(false),
        "timingMs": extractor_obj.get("timingMs").unwrap_or({}),
        "stats": extractor_obj.get("stats").unwrap_or({}),
      },
    }
    return normalized.stringify(indent=2)
  }

  if root.get("schemaVersion") is Some(String("ciq-bundle/v1")) {
    let normalized_source = match root.get("source") {
      Some(Object(source)) => {
        let object : Map[String, Json] = {
          "repo": source.get("repo").unwrap_or(""),
          "ref": source.get("ref").unwrap_or(""),
          "commit": "<normalized>",
        }
        Json::object(object)
      }
      _ => Json::object({})
    }
    let normalized : Json = {
      "schemaVersion": root.get("schemaVersion").unwrap_or("ciq-bundle/v1"),
      "purl": root.get("purl").unwrap_or(""),
      "profile": root.get("profile").unwrap_or(""),
      "source": normalized_source,
      "artifacts": root.get("artifacts").unwrap_or([]),
    }
    return normalized.stringify(indent=2)
  }

  content
}

///|
fn normalize_checksums_text(content : String) -> String {
  let lines = content.split("\n").to_array()
  let normalized : Array[String] = []
  for i in 0..<lines.length() {
    let line = lines[i]
    if line.has_prefix("metadata.json  ") {
      normalized.push("metadata.json  <normalized>")
    } else {
      normalized.push(line.to_string())
    }
  }
  normalized.join("\n")
}

///|
fn read_fixture(path : String) -> String {
  @fs.read_file_to_string(path) catch {
    _ => abort("failed to read fixture file")
  }
}

///|
fn run_snapshot_case(
  title : String,
  profile : String,
  source_file : String,
  source_fixture : String,
  include_glob : String,
  snapshot_root : String,
) -> Unit raise {
  let repo = tmp_snapshot_repo(title)
  cleanup_case(repo, source_file)
  ensure_repo_with_file(repo, source_file, read_fixture(source_fixture))
  write_config_for(repo, profile, include_glob)
  reset_repo(repo)
  write_config_for(repo, profile, include_glob)

  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_case(repo, source_file)
    fail("build should succeed for snapshot case \{title}")
  }

  let declarations = read_text_snapshot(
    "\{repo}/dist/declarations.ndjson",
    "declarations output should exist",
  )

  let dec_snapshot_path = "\{snapshot_root}/declarations.ndjson"
  let manifest_snapshot_path = "\{snapshot_root}/manifest.json"
  let metadata_snapshot_path = "\{snapshot_root}/metadata.json"
  let checksums_snapshot_path = "\{snapshot_root}/checksums.txt"
  let expected_dec = read_snapshot(dec_snapshot_path, declarations)
  let manifest = @fs.read_file_to_string("\{repo}/dist/manifest.json") catch {
    _ => abort("manifest output should exist")
  }
  let metadata = @fs.read_file_to_string("\{repo}/dist/metadata.json") catch {
    _ => abort("metadata output should exist")
  }
  let checksums = @fs.read_file_to_string("\{repo}/dist/checksums.txt") catch {
    _ => abort("checksums output should exist")
  }
  let normalized_manifest = normalize_snapshot_text(manifest)
  let normalized_metadata = normalize_snapshot_text(metadata)
  let normalized_checksums = normalize_checksums_text(checksums)
  let expected_manifest = read_snapshot(
    manifest_snapshot_path, normalized_manifest,
  )
  let expected_metadata = read_snapshot(
    metadata_snapshot_path, normalized_metadata,
  )
  let expected_checksums = normalize_checksums_text(
    read_snapshot(checksums_snapshot_path, normalized_checksums),
  )
  let missing_snapshots = !@fs.path_exists(dec_snapshot_path) ||
    !@fs.path_exists(manifest_snapshot_path) ||
    !@fs.path_exists(metadata_snapshot_path) ||
    !@fs.path_exists(checksums_snapshot_path)
  let update = match @sys.get_env_var("COGNA_UPDATE_SNAPSHOTS") {
    Some("true") => true
    _ =>
      match @env.args().search("--update-snapshots") {
        Some(_) => true
        None =>
          match @env.args().search("--update") {
            Some(_) => true
            None => false
          }
      }
  }
  if missing_snapshots {
    if update {
      persist_snapshot(dec_snapshot_path, declarations)
      persist_snapshot(manifest_snapshot_path, normalized_manifest)
      persist_snapshot(metadata_snapshot_path, normalized_metadata)
      persist_snapshot(checksums_snapshot_path, normalized_checksums)
    } else {
      cleanup_case(repo, source_file)
      fail(
        "snapshot baseline missing for \{title}; rerun with `moon test --update src/cmd/build/snapshot_test.mbt` to create it",
      )
    }
  } else if expected_dec == declarations &&
    expected_manifest == normalized_manifest &&
    expected_metadata == normalized_metadata &&
    expected_checksums == normalized_checksums {
    ()
  } else if update {
    persist_snapshot(dec_snapshot_path, declarations)
    persist_snapshot(manifest_snapshot_path, normalized_manifest)
    persist_snapshot(metadata_snapshot_path, normalized_metadata)
    persist_snapshot(checksums_snapshot_path, normalized_checksums)
  } else {
    cleanup_case(repo, source_file)
    fail(
      "snapshot mismatch for \{title}; rerun with `moon test --update src/cmd/build/snapshot_test.mbt` to refresh examples",
    )
  }
  assert_true(metadata.contains("\"role\": \"canonical\""))
  assert_true(metadata.contains("\"backend\": \"canonical\""))

  cleanup_case(repo, source_file)
}

///|
test "snapshot terraform baseline extractor output" {
  run_snapshot_case(
    "terraform", "terraform-module", "main.tf", "examples/terraform-module/full/repo/main.tf",
    "**/*.tf", "examples/terraform-module/full/snapshots/cogna",
  )
}

///|
test "snapshot openapi baseline extractor output" {
  run_snapshot_case(
    "openapi", "openapi-spec", "openapi/payment.yaml", "examples/openapi-spec/full/repo/openapi/payment.yaml",
    "openapi/**/*.yaml", "examples/openapi-spec/full/snapshots/cogna",
  )
}

///|
test "snapshot go canonical extractor output" {
  run_snapshot_case(
    "go", "go-module", "main.go", "examples/go-module/full/repo/main.go", "**/*.go",
    "examples/go-module/full/snapshots/cogna",
  )
}

///|
test "snapshot rust canonical extractor output" {
  run_snapshot_case(
    "rust", "rust-crate", "lib.rs", "examples/rust-crate/full/repo/lib.rs", "**/*.rs",
    "examples/rust-crate/full/snapshots/cogna",
  )
}
