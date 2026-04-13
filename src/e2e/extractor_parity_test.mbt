///|
fn remove_parity_file(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn remove_parity_dir(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn cleanup_parity_repo(path : String) -> Unit {
  remove_parity_file("\{path}/codeiq.yml")
  remove_parity_file("\{path}/codeiq.yaml")
  remove_parity_file("\{path}/main.go")
  remove_parity_file("\{path}/lib.rs")
  remove_parity_file("\{path}/dist/manifest.json")
  remove_parity_file("\{path}/dist/declarations.ndjson")
  remove_parity_file("\{path}/dist/symbols.ndjson")
  remove_parity_file("\{path}/dist/software-components.ndjson")
  remove_parity_file("\{path}/dist/sbom.spdx.json")
  remove_parity_file("\{path}/dist/metadata.json")
  remove_parity_file("\{path}/dist/checksums.txt")
  remove_parity_file("\{path}/dist/bundle.ciq.tgz")
  remove_parity_dir("\{path}/dist")
  remove_parity_dir(path)
}

///|
fn write_parity_fixture_repo(path : String, fixture_root : String) -> Unit {
  @fs.create_dir(path) catch {
    _ => abort("failed to create parity fixture repo")
  }
  let source = @fs.read_file_to_string(fixture_root) catch {
    _ => abort("failed to read parity fixture source")
  }
  let target = match fixture_root {
    "examples/go-module/full/repo/main.go" => "main.go"
    "examples/rust-crate/full/repo/lib.rs" => "lib.rs"
    _ => abort("unexpected parity fixture root")
  }
  @fs.write_string_to_file("\{path}/\{target}", source) catch {
    _ => abort("failed to write parity fixture source")
  }
}

///|
fn write_parity_config(
  path : String,
  profile : String,
  include_glob : String,
  purl : String,
  validation : String,
) -> Unit {
  let content =
    #|schemaVersion: ciq-config/v1
    #|profile: 
    #|validation: 
    #|purl: 
    #|source:
    #|  repo: https://github.com/example/demo
    #|  ref: main
    #|inputs:
    #|  include:
    #|    - 
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  let normalized = content
    .replace(old="profile: ", new="profile: \{profile}")
    .replace(old="validation: ", new="validation: \{validation}")
    .replace(old="purl: ", new="purl: \{purl}")
    .replace(old="    - ", new="    - \{include_glob}")
  @fs.write_string_to_file("\{path}/codeiq.yaml", normalized) catch {
    _ => abort("failed to write parity config")
  }
}

///|
fn read_parity_text(path : String) -> String {
  @fs.read_file_to_string(path) catch {
    _ => abort("cannot read parity file: \{path}")
  }
}

///|
fn normalize_parity_snapshot_text(content : String) -> String {
  let parsed = try? @json.parse(content)
  guard parsed is Ok(Object(root)) else { return content }

  if root.get("schemaVersion") is Some(String("ciq-metadata/v1")) {
    let extractor_obj : Map[String, Json] = match root.get("extractor") {
      Some(Object(e)) => e
      _ => {}
    }
    return ({
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
    } : Json).stringify(indent=2)
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
    return ({
      "schemaVersion": root.get("schemaVersion").unwrap_or("ciq-bundle/v1"),
      "purl": root.get("purl").unwrap_or(""),
      "profile": root.get("profile").unwrap_or(""),
      "declarationSchema": root.get("declarationSchema").unwrap_or({}),
      "source": normalized_source,
      "artifacts": root.get("artifacts").unwrap_or([]),
    } : Json).stringify(indent=2)
  }

  content
}

///|
fn normalize_parity_checksums_text(content : String) -> String {
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
fn compare_parity_artifacts(
  fixture_name : String,
  none_root : String,
  lsp_root : String,
) -> Unit raise {
  let none_manifest = normalize_parity_snapshot_text(
    read_parity_text("\{none_root}/manifest.json"),
  )
  let lsp_manifest = normalize_parity_snapshot_text(
    read_parity_text("\{lsp_root}/manifest.json"),
  )
  assert_eq(none_manifest, lsp_manifest)

  let none_metadata = normalize_parity_snapshot_text(
    read_parity_text("\{none_root}/metadata.json"),
  )
  let lsp_metadata = normalize_parity_snapshot_text(
    read_parity_text("\{lsp_root}/metadata.json"),
  )
  assert_eq(none_metadata, lsp_metadata)

  let none_checksums = normalize_parity_checksums_text(
    read_parity_text("\{none_root}/checksums.txt"),
  )
  let lsp_checksums = normalize_parity_checksums_text(
    read_parity_text("\{lsp_root}/checksums.txt"),
  )
  assert_eq(none_checksums, lsp_checksums)

  let none_declarations = read_parity_text("\{none_root}/declarations.ndjson")
  let lsp_declarations = read_parity_text("\{lsp_root}/declarations.ndjson")
  assert_eq(@build_cmd.compare_ndjson_lines(none_declarations, lsp_declarations), 0)

  let none_symbols = read_parity_text("\{none_root}/symbols.ndjson")
  let lsp_symbols = read_parity_text("\{lsp_root}/symbols.ndjson")
  assert_eq(@build_cmd.compare_ndjson_lines(none_symbols, lsp_symbols), 0)

  let none_components = read_parity_text("\{none_root}/software-components.ndjson")
  let lsp_components = read_parity_text("\{lsp_root}/software-components.ndjson")
  assert_eq(none_components, lsp_components)

  let none_spdx = read_parity_text("\{none_root}/sbom.spdx.json")
  let lsp_spdx = read_parity_text("\{lsp_root}/sbom.spdx.json")
  assert_eq(none_spdx, lsp_spdx)

  let none_bundle = @fs.read_file_to_bytes("\{none_root}/bundle.ciq.tgz") catch {
    _ => abort("missing none bundle for parity fixture \{fixture_name}")
  }
  let lsp_bundle = @fs.read_file_to_bytes("\{lsp_root}/bundle.ciq.tgz") catch {
    _ => abort("missing lsp bundle for parity fixture \{fixture_name}")
  }
  assert_eq(@sha256.sha256_hexdigest(none_bundle), @sha256.sha256_hexdigest(lsp_bundle))
}

///|
fn run_parity_case(
  title : String,
  fixture_root : String,
  profile : String,
  include_glob : String,
  purl : String,
) -> Unit raise {
  let none_repo = "src/e2e/tmp_parity_\{title}_none"
  let lsp_repo = "src/e2e/tmp_parity_\{title}_lsp"
  cleanup_parity_repo(none_repo)
  cleanup_parity_repo(lsp_repo)

  write_parity_fixture_repo(none_repo, fixture_root)
  write_parity_fixture_repo(lsp_repo, fixture_root)
  write_parity_config(none_repo, profile, include_glob, purl, "none")
  write_parity_config(lsp_repo, profile, include_glob, purl, "lsp")

  let none_out = @build_cmd.run({ repo: none_repo })
  guard none_out is Ok(_) else {
    cleanup_parity_repo(none_repo)
    cleanup_parity_repo(lsp_repo)
    fail("parity baseline build should succeed")
  }

  let lsp_out = @build_cmd.run({ repo: lsp_repo })
  guard lsp_out is Ok(_) else {
    cleanup_parity_repo(none_repo)
    cleanup_parity_repo(lsp_repo)
    fail("parity lsp build should succeed")
  }

  compare_parity_artifacts(title, "\{none_repo}/dist", "\{lsp_repo}/dist")

  cleanup_parity_repo(none_repo)
  cleanup_parity_repo(lsp_repo)
}

///|
test "e2e go extractor parity matches between validation none and lsp" {
  run_parity_case(
    "go",
    "examples/go-module/full/repo/main.go",
    "go-module",
    "**/*.go",
    "pkg:golang/example/demo@0.1.0",
  )
}

///|
test "e2e rust extractor parity matches between validation none and lsp" {
  run_parity_case(
    "rust",
    "examples/rust-crate/full/repo/lib.rs",
    "rust-crate",
    "**/*.rs",
    "pkg:cargo/example/demo@0.1.0",
  )
}
