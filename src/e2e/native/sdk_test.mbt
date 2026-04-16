///|
fn sdk_acceptance_fixture_root() -> String {
  "examples/sdk-acceptance/full/repo"
}

///|
fn sdk_acceptance_tmp_repo() -> String {
  "/tmp/codeiq-sdk-acceptance-repo"
}

///|
fn sdk_acceptance_node_script_path() -> String {
  "/tmp/codeiq-sdk-acceptance-node.mjs"
}

///|
fn sdk_acceptance_purl() -> String {
  "pkg:golang/example/sdkacceptance@0.1.0"
}

///|
fn sdk_shell_quote(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn sdk_cleanup_path(path : String) -> Unit {
  @e2e_shell.run_command_capture("rm -rf \{sdk_shell_quote(path)}") |> ignore
}

///|
fn sdk_copy_fixture_tree(source : String, target : String) -> Unit {
  if !@fs.path_exists(source) {
    abort("missing sdk fixture source: \{source}")
  }
  if !@fs.path_exists(target) {
    @fs.create_dir(target) catch {
      _ => abort("failed to create sdk fixture directory: \{target}")
    }
  }
  let entries = @fs.read_dir(source) catch {
    _ => abort("failed to read sdk fixture directory: \{source}")
  }
  for entry in entries {
    let source_path = "\{source}/\{entry}"
    let target_path = "\{target}/\{entry}"
    let is_dir_out = try? @fs.is_dir(source_path)
    match is_dir_out {
      Ok(true) => sdk_copy_fixture_tree(source_path, target_path)
      _ => {
        let bytes = @fs.read_file_to_bytes(source_path) catch {
          _ => abort("failed to read sdk fixture file: \{source_path}")
        }
        @fs.write_bytes_to_file(target_path, bytes) catch {
          _ => abort("failed to write sdk fixture file: \{target_path}")
        }
      }
    }
  }
}

///|
fn sdk_acceptance_config() -> @config.Config {
  let defaults = @config.default_config()
  {
    schema_version: defaults.schema_version,
    profile: "go-module",
    validation: defaults.validation,
    purl: sdk_acceptance_purl(),
    source: { repo: "https://github.com/example/codeiq-sdkacceptance", source_ref: "main" },
    inputs: { include_paths: ["**/*.go"] },
    checks: defaults.checks,
    diff: defaults.diff,
    sbom: defaults.sbom,
    publish: defaults.publish,
    registry: defaults.registry,
    mcp: defaults.mcp,
  }
}

fn sdk_repo_root() -> String {
  let mut current = @env.current_dir().unwrap_or(".")
  for _ in 0..<16 {
    if @fs.path_exists("\{current}/moon.mod.json") &&
      @fs.path_exists("\{current}/integrations/sdk/node/package.json") {
      return current
    }
    let parts = current.split("/").to_array()
    if parts.length() <= 1 {
      break
    }
    let next = parts[0:parts.length() - 1].join("/")
    if next == "" || next == current {
      break
    }
    current = next
  }
  abort("failed to locate codeiq workspace root")
}

///|
fn sdk_node_file_url(path : String) -> String {
  "file://\{path}"
}

///|
fn sdk_node_script(repo_root : String) -> String {
  let dist_index = sdk_node_file_url(
    "\{repo_root}/integrations/sdk/node/dist/index.js",
  )
  let dist_generated = sdk_node_file_url(
    "\{repo_root}/integrations/sdk/node/dist/generated/index.js",
  )
  let purl = sdk_acceptance_purl()
  (
    #|import { buildLocalIndex, runQuery } from "SDK_INDEX";
    #|import { parseQueryInput, serializeQueryInput } from "SDK_GENERATED";
    #|
    #|const repoRoot = process.argv[2];
    #|const purl = "SDK_PURL";
    #|const dto = parseQueryInput({
    #|  target: { purl, bundleId: "fixture", bundlePath: repoRoot },
    #|  sql: "select * from declarations limit 5",
    #|  options: { limit: 5, cursor: "", includeCatalog: true },
    #|});
    #|const serialized = serializeQueryInput(dto);
    #|const buildOut = buildLocalIndex({
    #|  rootDir: repoRoot,
    #|  profile: "go-module",
    #|  include: ["**/*.go"],
    #|  purl,
    #|});
    #|if (!buildOut.ok) {
    #|  throw new Error(buildOut.error.message);
    #|}
    #|const queryOut = runQuery(buildOut.value, {
    #|  schemaVersion: "ciq-query/v1",
    #|  purl,
    #|  selector: { path: "NewRequestID", kind: "function" },
    #|  intent: "review",
    #|});
    #|if (!queryOut.ok) {
    #|  throw new Error(queryOut.error.message);
    #|}
    #|console.log(JSON.stringify({
    #|  declarations: buildOut.value.declarations.length,
    #|  symbols: buildOut.value.symbols.length,
    #|  matches: Array.isArray(queryOut.value.matches) ? queryOut.value.matches.length : 0,
    #|  dtoSql: dto.sql,
    #|  targetPurl: serialized.target?.purl ?? null,
    #|}));
    #|
  )
  .replace(old="SDK_INDEX", new=dist_index)
  .replace(old="SDK_GENERATED", new=dist_generated)
  .replace(old="SDK_PURL", new=purl)
}

///|
fn ensure_node_sdk_dist() -> Unit {
  let node_root = "\{sdk_repo_root()}/integrations/sdk/node"
  let required_paths = [
    "\{node_root}/dist/index.js",
    "\{node_root}/dist/query.js",
    "\{node_root}/dist/generated/index.js",
    "\{node_root}/dist/generated/query.js",
  ]
  for path in required_paths {
    if !@fs.path_exists(path) {
      abort(
        "missing prebuilt Node SDK artifact: \{path}; run npm install && npm run build in integrations/sdk/node before MoonBit native SDK acceptance tests",
      )
    }
  }
}

///|
test "e2e MoonBit SDK accepts fixture repo and generated DTOs under src/sdk" {
  let repo = sdk_acceptance_tmp_repo()
  sdk_cleanup_path(repo)
  sdk_copy_fixture_tree(sdk_acceptance_fixture_root(), repo)

  let config = sdk_acceptance_config()
  let build_out = @sdk_index.build_local_index_native(config, repo)
  guard build_out is Ok(index) else {
    sdk_cleanup_path(repo)
    fail("MoonBit SDK build_local_index_native should succeed: \{build_out.unwrap_err()}")
  }

  assert_true(index.declaration_count > 0)
  assert_true(index.symbol_count > 0)
  assert_true(index.declarations_text.contains("NewRequestID"))
  assert_true(index.declarations_text.contains("BuildLabels"))

  @fs.create_dir("\{repo}/dist") catch {
    _ => abort("failed to create sdk acceptance dist directory")
  }
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", index.declarations_text) catch {
    _ => abort("failed to write sdk acceptance declarations")
  }
  @fs.write_string_to_file("\{repo}/dist/symbols.ndjson", index.symbols_text) catch {
    _ => abort("failed to write sdk acceptance symbols")
  }
  let matches = @sdk_query.query_matches(repo, "NewRequestID", Some("function"))
  let matches_json = Json::array(matches).stringify()
  assert_true(matches.length() > 0)
  assert_true(matches_json.contains("NewRequestID"))

  let proto_input = @sdk_proto.QueryInput::{
    target: Some(@sdk_proto.QueryTarget::{
      purl: sdk_acceptance_purl(),
      bundle_id: "fixture",
      bundle_path: repo,
    }),
    sql: "select * from declarations limit 5",
    options: Some(@sdk_proto.QueryOptions::{
      limit: 5,
      cursor: "",
      include_catalog: true,
    }),
  }
  let proto_json_out = proto_input.to_json_string()
  guard proto_json_out is Ok(proto_json) else {
    sdk_cleanup_path(repo)
    fail("generated MoonBit DTO should serialize: \{proto_json_out.unwrap_err()}")
  }
  let parsed_input_out = @sdk_proto.QueryInput::from_json_string(proto_json)
  guard parsed_input_out is Ok(parsed_input) else {
    sdk_cleanup_path(repo)
    fail("generated MoonBit DTO should round-trip: \{parsed_input_out.unwrap_err()}")
  }
  assert_eq(parsed_input.sql, "select * from declarations limit 5")
  assert_true(parsed_input.target is Some(_))

  let proto_value = @sdk_proto.QueryValue::{
    kind: Some(@sdk_proto.QueryValueKind::StringValue("sdk-acceptance")),
  }
  assert_true(proto_value.to_json().stringify().contains("stringValue"))

  sdk_cleanup_path(repo)
}

///|
test "e2e Node SDK accepts fixture repo and generated DTOs under integrations/sdk" {
  let repo = sdk_acceptance_tmp_repo()
  let script_path = sdk_acceptance_node_script_path()
  sdk_cleanup_path(repo)
  sdk_cleanup_path(script_path)
  sdk_copy_fixture_tree(sdk_acceptance_fixture_root(), repo)
  ensure_node_sdk_dist()

  @fs.write_string_to_file(script_path, sdk_node_script(sdk_repo_root())) catch {
    _ => {
      sdk_cleanup_path(repo)
      fail("failed to write Node SDK acceptance script")
    }
  }

  let command = "node \{sdk_shell_quote(script_path)} \{sdk_shell_quote(repo)}"
  let (exit_code, stdout, stderr) = @e2e_shell.run_command_capture(command)
  if exit_code != 0 {
    let command_error_text = if stderr != "" { stderr } else { stdout }
    sdk_cleanup_path(script_path)
    sdk_cleanup_path(repo)
    fail(
      "Node SDK acceptance script should succeed: \{command_error_text}",
    )
  }

  let summary = read_json_from_text(stdout)
  guard summary is Object(summary_object) else {
    sdk_cleanup_path(script_path)
    sdk_cleanup_path(repo)
    fail("Node SDK acceptance output should be a JSON object")
  }
  assert_true(summary_object.get("declarations") is Some(Number(value, ..)) && value.to_int() > 0)
  assert_true(summary_object.get("symbols") is Some(Number(value, ..)) && value.to_int() > 0)
  assert_true(summary_object.get("matches") is Some(Number(value, ..)) && value.to_int() >= 0)
  assert_true(summary.stringify().contains("select * from declarations limit 5"))
  assert_true(summary.stringify().contains(sdk_acceptance_purl()))

  sdk_cleanup_path(script_path)
  sdk_cleanup_path(repo)
}

///|
fn read_json_from_text(text : String) -> Json {
  let parsed = try? @json.parse(text.trim().to_string())
  match parsed {
    Ok(value) => value
    Err(_) => abort("failed to parse json text")
  }
}
