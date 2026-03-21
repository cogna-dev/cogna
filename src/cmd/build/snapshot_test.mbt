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
  remove_if_exists("\{path}/codeiq.yaml")
  remove_if_exists("\{path}/dist/manifest.json")
  remove_if_exists("\{path}/dist/declarations.ndjson.zst")
  remove_if_exists("\{path}/dist/symbols.ndjson.zst")
  remove_if_exists("\{path}/dist/metadata.json")
  remove_if_exists("\{path}/dist/checksums.txt")
  remove_dir_if_exists("\{path}/dist")
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
      #|schemaVersion: ciq-config/v1
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
      #|  policy: default-compat
      #|
    )
    .replace(old="profile: ", new="profile: \{profile}")
    .replace(old="purl: ", new="purl: \{purl}")
    .replace(old="    - ", new="    - \{include_glob}")
  @fs.write_string_to_file("\{path}/codeiq.yaml", content) catch {
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
  @fs.write_string_to_file(path, content) catch {
    _ => abort("failed to persist snapshot")
  }
}

///|
fn run_snapshot_case(
  title : String,
  profile : String,
  source_file : String,
  source_content : String,
  include_glob : String,
  snapshot_root : String,
) -> Unit raise {
  let repo = "src/cmd/build/tmp_snapshot_\{title}"
  cleanup_case(repo, source_file)
  ensure_repo_with_file(repo, source_file, source_content)
  write_config_for(repo, profile, include_glob)
  reset_repo(repo)
  write_config_for(repo, profile, include_glob)

  let out = run({ repo, })
  guard out is Ok(_) else {
    cleanup_case(repo, source_file)
    fail("build should succeed for snapshot case \{title}")
  }

  let declarations = @fs.read_file_to_string(
    "\{repo}/dist/declarations.ndjson.zst",
  ) catch {
    _ => {
      cleanup_case(repo, source_file)
      fail("declarations output should exist")
      ""
    }
  }
  let symbols = @fs.read_file_to_string("\{repo}/dist/symbols.ndjson.zst") catch {
    _ => {
      cleanup_case(repo, source_file)
      fail("symbols output should exist")
      ""
    }
  }

  let dec_snapshot_path = "\{snapshot_root}/declarations.ndjson"
  let sym_snapshot_path = "\{snapshot_root}/symbols.ndjson"
  let expected_dec = read_snapshot(dec_snapshot_path, declarations)
  let expected_sym = read_snapshot(sym_snapshot_path, symbols)
  let missing_snapshots = !@fs.path_exists(dec_snapshot_path) ||
    !@fs.path_exists(sym_snapshot_path)
  if missing_snapshots {
    persist_snapshot(dec_snapshot_path, declarations)
    persist_snapshot(sym_snapshot_path, symbols)
  } else if expected_dec == declarations && expected_sym == symbols {
    ()
  } else {
    let update = match @env.args().search("--update-snapshots") {
      Some(_) => true
      None => false
    }
    if update {
      persist_snapshot(dec_snapshot_path, declarations)
      persist_snapshot(sym_snapshot_path, symbols)
    } else {
      cleanup_case(repo, source_file)
      fail(
        "snapshot mismatch for \{title}; rerun with --update-snapshots to refresh examples",
      )
    }
  }

  let metadata = @fs.read_file_to_string("\{repo}/dist/metadata.json") catch {
    _ => {
      cleanup_case(repo, source_file)
      fail("metadata should exist")
      ""
    }
  }
  assert_true(metadata.contains("\"role\": \"baseline\""))

  cleanup_case(repo, source_file)
}

///|
test "snapshot go baseline extractor output" {
  run_snapshot_case(
    "go",
    "go-module",
    "main.go",
    (
      #|package sample
      #|
      #|type Greeter struct {}
      #|
      #|func Hello(name string) string {
      #|  return "hello"
      #|}
      #|
    ),
    "**/*.go",
    "examples/go-module/full/snapshots/lsp",
  )
}

///|
test "snapshot rust baseline extractor output" {
  run_snapshot_case(
    "rust",
    "rust-crate",
    "lib.rs",
    (
      #|pub struct Counter {
      #|  value: i32,
      #|}
      #|
      #|pub fn increment(value: i32) -> i32 {
      #|  value + 1
      #|}
      #|
    ),
    "**/*.rs",
    "examples/rust-crate/full/snapshots/lsp",
  )
}

///|
test "snapshot terraform baseline extractor output" {
  run_snapshot_case(
    "terraform",
    "terraform-module",
    "main.tf",
    (
      #|provider "aws" {
      #|  region = "us-east-1"
      #|}
      #|
      #|variable "cidr" {
      #|  type = string
      #|}
      #|
      #|resource "aws_vpc" "main" {
      #|  cidr_block = var.cidr
      #|}
      #|
      #|output "vpc_id" {
      #|  value = aws_vpc.main.id
      #|}
      #|
    ),
    "**/*.tf",
    "examples/terraform-module/full/snapshots/lsp",
  )
}

///|
test "snapshot openapi baseline extractor output" {
  run_snapshot_case(
    "openapi",
    "openapi-spec",
    "openapi/payment.yaml",
    (
      #|openapi: 3.1.0
      #|info:
      #|  title: Payment API
      #|  version: 1.0.0
      #|paths:
      #|  /payments:
      #|    get:
      #|      operationId: listPayments
      #|      responses:
      #|        "200":
      #|          description: ok
      #|components:
      #|  schemas:
      #|    Payment:
      #|      type: object
      #|      properties:
      #|        id:
      #|          type: string
      #|
    ),
    "openapi/**/*.yaml",
    "examples/openapi-spec/full/snapshots/lsp",
  )
}
