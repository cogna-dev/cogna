///|
pub(all) enum CliInvocation {
  Init(@init_cmd.InitParams)
  Build(@build_cmd.BuildParams)
  Diff(@diff_cmd.DiffParams)
  Check(@check_cmd.CheckParams)
  Query(@query_cmd.QueryParams)
  Publish(@publish_cmd.PublishParams)
  RegistryUploadLocal(@registry_cmd.RegistryUploadParams)
  RegistryDownloadLocal(@registry_cmd.RegistryDownloadParams)
  RegistryDownloadBundle(@registry_cmd.RegistryDownloadBundleParams)
  McpStart(@mcp_cmd.McpStartParams)
  McpServe(@mcp_core.McpServeParams)
  McpStatus
  McpStop
} derive(Show, Eq)

///|
fn is_known_subcommand(name : String) -> Bool {
  match name {
    "init"
    | "build"
    | "diff"
    | "check"
    | "query"
    | "publish"
    | "registry"
    | "mcp"
    | "help" => true
    _ => false
  }
}

///|
fn normalize_cli_args(argv : Array[String]) -> Array[String] {
  for i in 0..<argv.length() {
    if is_known_subcommand(argv[i]) {
      return argv.view(start=i).to_array()
    }
  }
  argv
}

///|
fn parse_invocation(
  argv : Array[String],
) -> @cli.CliResult[CliInvocation, @cli.CliError] {
  let command = @argparse.Command::new(
    "codeiq",
    about="CodeIQ declaration-aware CLI",
    subcommands=[
      @argparse.Command::new("init", about="Initialize codeiq.yaml", options=[
        @argparse.OptionArg::new(
          "output",
          long="output",
          action=@argparse.OptionAction::Set,
          default_values=["./codeiq.yaml"],
        ),
      ]),
      @argparse.Command::new("build", about="Build CIQ bundle", positionals=[
        @argparse.PositionArg::new(
          "repo",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
      @argparse.Command::new(
        "diff",
        about="Compute CIQ diff",
        positionals=[
          @argparse.PositionArg::new(
            "repo",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
        options=[
          @argparse.OptionArg::new(
            "since",
            long="since",
            action=@argparse.OptionAction::Set,
          ),
          @argparse.OptionArg::new(
            "test-changes",
            long="test-changes",
            action=@argparse.OptionAction::Set,
            default_values=["false"],
          ),
        ],
      ),
      @argparse.Command::new(
        "check",
        about="Run policy checks",
        positionals=[
          @argparse.PositionArg::new(
            "diff_file",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
        options=[
          @argparse.OptionArg::new(
            "policy",
            long="policy",
            action=@argparse.OptionAction::Set,
            default_values=["./dist/policy.ciq.tgz"],
          ),
        ],
      ),
      @argparse.Command::new("query", about="Query CIQ bundle", positionals=[
        @argparse.PositionArg::new(
          "query_file",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
      @argparse.Command::new("publish", about="Publish CIQ bundle", positionals=[
        @argparse.PositionArg::new(
          "bundle_file",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
      @argparse.Command::new(
        "registry",
        about="Run local registry operations",
        subcommands=[
          @argparse.Command::new(
            "upload-local",
            about="Upload bundle into local registry",
            positionals=[
              @argparse.PositionArg::new(
                "upload_request_file",
                num_args=@argparse.ValueRange::single(),
              ),
            ],
          ),
          @argparse.Command::new(
            "download-local",
            about="Download local registry metadata by purl",
            positionals=[
              @argparse.PositionArg::new(
                "purl",
                num_args=@argparse.ValueRange::single(),
              ),
            ],
          ),
          @argparse.Command::new(
            "download",
            about="Download and materialize bundle by purl",
            positionals=[
              @argparse.PositionArg::new(
                "purl",
                num_args=@argparse.ValueRange::single(),
              ),
            ],
            options=[
              @argparse.OptionArg::new(
                "output",
                long="output",
                action=@argparse.OptionAction::Set,
                default_values=["./dist"],
              ),
            ],
          ),
        ],
        subcommand_required=true,
      ),
      @argparse.Command::new(
        "mcp",
        about="Run local MCP agent",
        subcommands=[
          @argparse.Command::new("start", about="Start MCP agent", options=[
            @argparse.OptionArg::new(
              "port",
              long="port",
              action=@argparse.OptionAction::Set,
              default_values=["3000"],
            ),
            @argparse.OptionArg::new(
              "stdio",
              long="stdio",
              action=@argparse.OptionAction::Set,
              default_values=["true"],
            ),
          ]),
          @argparse.Command::new("serve", about="Run MCP agent foreground loop", options=[
            @argparse.OptionArg::new(
              "port",
              long="port",
              action=@argparse.OptionAction::Set,
              default_values=["3000"],
            ),
          ]),
          @argparse.Command::new("status", about="Show MCP agent status"),
          @argparse.Command::new("stop", about="Stop MCP agent"),
        ],
        subcommand_required=true,
      ),
    ],
    subcommand_required=true,
  )
  let parse_result = try? @argparse.parse(command, argv~)
  guard parse_result is Ok(matches) else {
    return Err(@cli.usage_error(command.render_help()))
  }
  match matches.subcommand {
    Some(("init", init_matches)) => {
      let output_values = init_matches.values["output"]
      let output_path = output_values[0]
      Ok(Init(@init_cmd.InitParams::{ output_path, }))
    }
    Some(("build", build_matches)) => {
      let repo_values = build_matches.values["repo"]
      Ok(Build(@build_cmd.BuildParams::{ repo: repo_values[0] }))
    }
    Some(("diff", diff_matches)) => {
      let repo_values = diff_matches.values["repo"]
      let since = match diff_matches.values.get("since") {
        Some(values) if !values.is_empty() => Some(values[0])
        _ => None
      }
      let include_test_changes = match diff_matches.values.get("test-changes") {
        Some(values) if !values.is_empty() => values[0] == "true"
        _ => false
      }
      Ok(
        Diff(@diff_cmd.DiffParams::{
          repo: repo_values[0],
          since,
          include_test_changes,
        }),
      )
    }
    Some(("check", check_matches)) => {
      let diff_values = check_matches.values["diff_file"]
      let policy_values = check_matches.values["policy"]
      let diff_file = diff_values[0]
      let policy_bundle = policy_values[0]
      Ok(Check(@check_cmd.CheckParams::{ diff_file, policy_bundle }))
    }
    Some(("query", query_matches)) => {
      let query_values = query_matches.values["query_file"]
      let query_file = query_values[0]
      Ok(Query(@query_cmd.QueryParams::{ query_file, }))
    }
    Some(("publish", publish_matches)) => {
      let bundle_values = publish_matches.values["bundle_file"]
      let bundle_file = bundle_values[0]
      Ok(Publish(@publish_cmd.PublishParams::{ bundle_file, }))
    }
    Some(("registry", registry_matches)) =>
      match registry_matches.subcommand {
        Some(("upload-local", upload_matches)) => {
          let values = upload_matches.values["upload_request_file"]
          Ok(
            RegistryUploadLocal(@registry_cmd.RegistryUploadParams::{
              upload_request_file: values[0],
            }),
          )
        }
        Some(("download-local", download_matches)) => {
          let values = download_matches.values["purl"]
          Ok(
            RegistryDownloadLocal(@registry_cmd.RegistryDownloadParams::{
              purl: values[0],
            }),
          )
        }
        Some(("download", download_matches)) => {
          let purl_values = download_matches.values["purl"]
          let output_values = download_matches.values["output"]
          Ok(
            RegistryDownloadBundle(@registry_cmd.RegistryDownloadBundleParams::{
              purl: purl_values[0],
              output_dir: output_values[0],
            }),
          )
        }
        _ => Err(@cli.usage_error(command.render_help()))
      }
    Some(("mcp", mcp_matches)) =>
      match mcp_matches.subcommand {
        Some(("start", start_matches)) => {
          let port_values = start_matches.values["port"]
          let parsed_port = try? @strconv.parse_int(port_values[0])
          guard parsed_port is Ok(port) else {
            return Err(@cli.usage_error("--port must be an integer"))
          }
          let stdio_values = start_matches.values["stdio"]
          let stdio = stdio_values[0] == "true"
          Ok(McpStart(@mcp_cmd.McpStartParams::{ port, stdio }))
        }
        Some(("serve", serve_matches)) => {
          let port_values = serve_matches.values["port"]
          let parsed_port = try? @strconv.parse_int(port_values[0])
          guard parsed_port is Ok(port) else {
            return Err(@cli.usage_error("--port must be an integer"))
          }
          Ok(McpServe(@mcp_core.McpServeParams::{ port }))
        }
        Some(("status", _)) => Ok(McpStatus)
        Some(("stop", _)) => Ok(McpStop)
        _ => Err(@cli.usage_error(command.render_help()))
      }
    _ => Err(@cli.usage_error(command.render_help()))
  }
}

///|
pub fn parse_cli_args(
  argv : Array[String],
) -> @cli.CliResult[CliInvocation, @cli.CliError] {
  parse_invocation(normalize_cli_args(argv))
}

///|
pub fn run(command : CliInvocation) -> @cli.CliResult[String, @cli.CliError] {
  match command {
    Init(params) =>
      match @init_cmd.run(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    Build(params) =>
      match @build_cmd.run(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    Diff(params) =>
      match @diff_cmd.run(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    Check(params) =>
      match @check_cmd.run(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    Query(params) =>
      match @query_cmd.run(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    Publish(params) =>
      match @publish_cmd.run(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    RegistryUploadLocal(params) =>
      match @registry_cmd.run_upload_local(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    RegistryDownloadLocal(params) =>
      match @registry_cmd.run_download_local(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    RegistryDownloadBundle(params) =>
      match @registry_cmd.run_download_bundle(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    McpStart(params) =>
      match @mcp_cmd.run_start(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    McpServe(params) =>
      match @mcp_core.run_serve(params) {
        Ok(_) => Ok("")
        Err(error) => Err(error)
      }
    McpStatus =>
      match @mcp_cmd.run_status() {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    McpStop =>
      match @mcp_cmd.run_stop() {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
  }
}

///|
pub fn banner() -> String {
  (
    #|  ____          _      ___ ____
    #| / ___|___   __| | ___|_ _/ ___|
    #|| |   / _ \ / _` |/ _ \| | |  _
    #|| |__| (_) | (_| |  __/| | |_| |
    #| \____\___/ \__,_|\___|___\____|
    #|
  )
}

///|
fn main {
  let logger = @cli.new_logger()
  let all_args = @env.args()
  println(banner())

  let parse_out = parse_cli_args(all_args)
  if parse_out is Ok(invocation) {
    let run_out = run(invocation)
    if run_out is Ok(result) {
      logger.success(result)
    } else {
      let error = run_out.unwrap_err()
      logger.error("[\{@cli.exit_code(error)}] \{@cli.to_text(error)}")
    }
  } else {
    let error = parse_out.unwrap_err()
    logger.error("[\{@cli.exit_code(error)}] \{@cli.to_text(error)}")
  }
}
