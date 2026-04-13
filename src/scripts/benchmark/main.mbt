///|
pub(all) struct ExtractorBenchParams {
  profile : String
  fixture : String
  backend : String
} derive(Eq)

///|
pub impl Show for ExtractorBenchParams with output(self, logger) {
  logger.write_string("{profile: ")
  logger.write_object(self.profile)
  logger.write_string(", fixture: ")
  logger.write_object(self.fixture)
  logger.write_string(", backend: ")
  logger.write_object(self.backend)
  logger.write_char('}')
}

///|
pub(all) struct ExtractorBenchResult {
  profile : String
  fixture : String
  backend : String
  summary : String
} derive(Eq)

///|
pub impl Show for ExtractorBenchResult with output(self, logger) {
  logger.write_string("{profile: ")
  logger.write_object(self.profile)
  logger.write_string(", fixture: ")
  logger.write_object(self.fixture)
  logger.write_string(", backend: ")
  logger.write_object(self.backend)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

///|
pub impl @cli.Display for ExtractorBenchResult with display(
  self : ExtractorBenchResult,
) -> String {
  self.summary
}

///|
fn extractor_bench_error(message : String) -> @cli.CliError {
  @cli.command_error("extractor-bench failed: \{message}")
}

///|
fn parse_value(
  values : Map[String, Array[String]],
  key : String,
  fallback : String,
) -> String {
  match values.get(key) {
    Some(v) if v.length() > 0 => v[0]
    _ => fallback
  }
}

///|
fn normalize_cli_args(argv : Array[String]) -> Array[String] {
  if argv.is_empty() {
    return argv
  }
  let mut normalized = argv
  if !normalized[0].has_prefix("-") {
    normalized = normalized.view(start=1).to_array()
  }
  if !normalized.is_empty() && normalized[0] == "--" {
    normalized.view(start=1).to_array()
  } else {
    normalized
  }
}

///|
fn parse_cli_args(
  argv : Array[String],
) -> Result[ExtractorBenchParams, @cli.CliError] {
  let command = @argparse.Command::new(
    "extractor-bench",
    about="Run parity-first extractor benchmark",
    options=[
      @argparse.OptionArg::new(
        "profile",
        long="profile",
        action=@argparse.OptionAction::Set,
        default_values=["go-module"],
      ),
      @argparse.OptionArg::new(
        "fixture",
        long="fixture",
        action=@argparse.OptionAction::Set,
        default_values=["full"],
      ),
        @argparse.OptionArg::new(
          "backend",
          long="backend",
          action=@argparse.OptionAction::Set,
          default_values=["native"],
        ),
      ],
  )
  let parsed = try? @argparse.parse(command, argv=normalize_cli_args(argv))
  guard parsed is Ok(matches) else {
    return Err(@cli.usage_error(command.render_help()))
  }
  let profile = parse_value(matches.values, "profile", "go-module")
  let fixture = parse_value(matches.values, "fixture", "full")
  let backend = parse_value(matches.values, "backend", "native")
  Ok({ profile, fixture, backend })
}

///|
fn fixture_source_file(profile : String) -> Result[String, @cli.CliError] {
  match profile {
    "go-module" => Ok("main.go")
    "rust-crate" => Ok("lib.rs")
    _ => Err(extractor_bench_error("unsupported profile \{profile}"))
  }
}

///|
fn fixture_include_glob(profile : String) -> Result[String, @cli.CliError] {
  match profile {
    "go-module" => Ok("**/*.go")
    "rust-crate" => Ok("**/*.rs")
    _ => Err(extractor_bench_error("unsupported profile \{profile}"))
  }
}

///|
fn fixture_root(profile : String, fixture : String) -> Result[String, @cli.CliError] {
  match (profile, fixture) {
    ("go-module", "full") => Ok("examples/go-module/full")
    ("rust-crate", "full") => Ok("examples/rust-crate/full")
    _ => Err(
      extractor_bench_error(
        "unsupported benchmark fixture profile=\{profile} fixture=\{fixture}",
      ),
    )
  }
}

///|
fn ensure_repo(path : String) -> Result[Unit, @cli.CliError] {
  if @fs.path_exists(path) {
    return Ok(())
  }
  @fs.create_dir(path) catch {
    err =>
      return Err(extractor_bench_error("cannot create benchmark repo \{path}: \{err}"))
  }
  Ok(())
}

///|
fn cleanup_repo(path : String, target_name : String) -> Unit {
  @fs.remove_file("\{path}/codeiq.yaml") catch { _ => () }
  @fs.remove_file("\{path}/\{target_name}") catch { _ => () }
  @fs.remove_file("\{path}/dist/manifest.json") catch { _ => () }
  @fs.remove_file("\{path}/dist/declarations.ndjson") catch { _ => () }
  @fs.remove_file("\{path}/dist/symbols.ndjson") catch { _ => () }
  @fs.remove_file("\{path}/dist/software-components.ndjson") catch { _ => () }
  @fs.remove_file("\{path}/dist/sbom.spdx.json") catch { _ => () }
  @fs.remove_file("\{path}/dist/metadata.json") catch { _ => () }
  @fs.remove_file("\{path}/dist/checksums.txt") catch { _ => () }
  @fs.remove_file("\{path}/dist/bundle.ciq.tgz") catch { _ => () }
  @fs.remove_dir("\{path}/dist") catch { _ => () }
  @fs.remove_dir(path) catch { _ => () }
}

///|
fn write_repo_source(
  repo : String,
  source_path : String,
  target_name : String,
) -> Result[Unit, @cli.CliError] {
  let content = @fs.read_file_to_string(source_path) catch {
    err =>
      return Err(
        extractor_bench_error("cannot read fixture source \{source_path}: \{err}"),
      )
  }
  @fs.write_string_to_file("\{repo}/\{target_name}", content) catch {
    err =>
      return Err(
        extractor_bench_error("cannot write benchmark source \{target_name}: \{err}"),
      )
  }
  Ok(())
}

///|
fn write_repo_config(
  repo : String,
  profile : String,
  include_glob : String,
  validation : String,
) -> Result[Unit, @cli.CliError] {
  let purl = "pkg:\{profile}/bench@0.0.0"
  let content = (
    #|schemaVersion: ciq-config/v1
    #|profile: 
    #|validation: 
    #|purl: 
    #|source:
    #|  repo: https://github.com/example/bench
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
    .replace(old="validation: ", new="validation: \{validation}")
    .replace(old="purl: ", new="purl: \{purl}")
    .replace(old="    - ", new="    - \{include_glob}")
  @fs.write_string_to_file("\{repo}/codeiq.yaml", content) catch {
    err =>
      return Err(
        extractor_bench_error("cannot write benchmark config: \{err}"),
      )
  }
  Ok(())
}

///|
pub fn run(params : ExtractorBenchParams) -> Result[ExtractorBenchResult, @cli.CliError] {
  if params.backend != "native" && params.backend != "lsp" {
    return Err(
      extractor_bench_error(
        "backend must be one of: native, lsp (got \{params.backend})",
      ),
    )
  }
  let fixture_root_path = match fixture_root(params.profile, params.fixture) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let target_name = match fixture_source_file(params.profile) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let include_glob = match fixture_include_glob(params.profile) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let repo = "/tmp/extractor_bench_cli_\{params.profile}_\{params.fixture}_\{params.backend}"
  cleanup_repo(repo, target_name)
  let ensure_out = ensure_repo(repo)
  guard ensure_out is Ok(_) else { return Err(ensure_out.unwrap_err()) }
  let source_path = "\{fixture_root_path}/repo/\{target_name}"
  let source_out = write_repo_source(repo, source_path, target_name)
  guard source_out is Ok(_) else { return Err(source_out.unwrap_err()) }
  let config_out = write_repo_config(repo, params.profile, include_glob, "none")
  guard config_out is Ok(_) else { return Err(config_out.unwrap_err()) }
  @bench_shell.run_command_capture(
    "git -C '\{repo}' init -q && git -C '\{repo}' add . && git -C '\{repo}' commit -q -m init --allow-empty",
  )
  |> ignore
  @sys.set_env_var("CODEIQ_EXTRACTOR_BACKEND", params.backend)
  let out = @build.run({ repo, })
  @sys.unset_env_var("CODEIQ_EXTRACTOR_BACKEND")
  cleanup_repo(repo, target_name)
  guard out is Ok(_) else { return Err(out.unwrap_err()) }
  Ok({
    profile: params.profile,
    fixture: params.fixture,
    backend: params.backend,
    summary: "Completed extractor benchmark fixture \{params.profile}/\{params.fixture} with backend=\{params.backend}",
  })
}

///|
fn main {
  let argv = @env.args()
  let parsed = parse_cli_args(argv)
  if parsed is Ok(params) {
    let out = run(params)
    if out is Ok(result) {
      println(@cli.display(result))
    } else {
      let err = out.unwrap_err()
      println(@cli.to_text(err))
    }
  } else {
    let err = parsed.unwrap_err()
    println(@cli.to_text(err))
  }
}
