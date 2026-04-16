///|
pub(all) enum CliInvocation {
  Init(@init_cmd.InitParams)
  Build(@build_cmd.BuildParams)
  Diff(@diff_cmd.DiffParams)
  Check(@check_cmd.CheckParams)
  Query(@query_cmd.QueryParams)
  Publish(@publish_cmd.PublishParams)
  RegistryServe(@registry_cmd.RegistryServeParams)
  RegistryStatus
  McpServe(@mcp_core.McpServeParams)
  McpStatus
} derive(Eq)

///|
pub impl Show for CliInvocation with output(self, logger) {
  match self {
    Init(params) => {
      logger.write_string("Init(")
      logger.write_object(params)
      logger.write_char(')')
    }
    Build(params) => {
      logger.write_string("Build(")
      logger.write_object(params)
      logger.write_char(')')
    }
    Diff(params) => {
      logger.write_string("Diff(")
      logger.write_object(params)
      logger.write_char(')')
    }
    Check(params) => {
      logger.write_string("Check(")
      logger.write_object(params)
      logger.write_char(')')
    }
    Query(params) => {
      logger.write_string("Query(")
      logger.write_object(params)
      logger.write_char(')')
    }
    Publish(params) => {
      logger.write_string("Publish(")
      logger.write_object(params)
      logger.write_char(')')
    }
    RegistryServe(params) => {
      logger.write_string("RegistryServe(")
      logger.write_object(params)
      logger.write_char(')')
    }
    RegistryStatus => logger.write_string("RegistryStatus")
    McpServe(params) => {
      logger.write_string("McpServe(")
      logger.write_object(params)
      logger.write_char(')')
    }
    McpStatus => logger.write_string("McpStatus")
  }
}

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
fn grouped_help() -> String {
  (
    #|CodeIQ declaration-aware CLI
    #|
    #|Usage: codeiq <command> [options]
    #|
    #|Core
    #|  init                Initialize codeiq.yml
    #|  build               Build CIQ bundle
    #|  diff                Compute CIQ diff
    #|  check               Run policy checks
    #|  query <query-file>  Query CIQ bundle
    #|
    #|Remote
    #|  publish             Publish CIQ bundle
    #|  registry serve      Run local registry HTTP server
    #|  registry status     Show registry server status
    #|
    #|AI
    #|  mcp serve           Run MCP agent foreground loop
    #|  mcp status          Show MCP agent status
  )
}

///|
fn usage_error(message? : String = "") -> @cli.CliError {
  if message == "" {
    @cli.usage_error(grouped_help())
  } else {
    @cli.usage_error("\{message}\n\n\{grouped_help()}")
  }
}

///|
fn parse_invocation(
  argv : Array[String],
) -> @cli.CliResult[CliInvocation, @cli.CliError] {
  let command = @argparse.Command::new(
    "codeiq",
    about="CodeIQ declaration-aware CLI",
    subcommands=[
      @argparse.Command::new("init", about="Initialize codeiq.yml", options=[
        @argparse.OptionArg::new(
          "output",
          long="output",
          action=@argparse.OptionAction::Set,
          default_values=["./codeiq.yml"],
        ),
      ]),
      @argparse.Command::new("build", about="Build CIQ bundle"),
      @argparse.Command::new("diff", about="Compute CIQ diff"),
      @argparse.Command::new("check", about="Run policy checks"),
      @argparse.Command::new("query", about="Query CIQ bundle", positionals=[
        @argparse.PositionArg::new(
          "query_file",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
      @argparse.Command::new("publish", about="Publish CIQ bundle"),
      @argparse.Command::new(
        "registry",
        about="Run local registry operations",
        subcommands=[
          @argparse.Command::new(
            "serve",
            about="Run local registry HTTP server",
            options=[
              @argparse.OptionArg::new(
                "port",
                long="port",
                action=@argparse.OptionAction::Set,
                default_values=["8787"],
              ),
            ],
          ),
          @argparse.Command::new("status", about="Show registry server status"),
        ],
        subcommand_required=true,
      ),
      @argparse.Command::new(
        "mcp",
        about="Run local MCP agent",
        subcommands=[
          @argparse.Command::new(
            "serve",
            about="Run MCP agent foreground loop",
            options=[
              @argparse.OptionArg::new(
                "port",
                long="port",
                action=@argparse.OptionAction::Set,
                default_values=["3000"],
              ),
            ],
          ),
          @argparse.Command::new("status", about="Show MCP agent status"),
        ],
        subcommand_required=true,
      ),
    ],
    subcommand_required=true,
  )
  let parse_result = try? @argparse.parse(command, argv~)
  guard parse_result is Ok(matches) else {
    return Err(usage_error())
  }
  match matches.subcommand {
    Some(("init", init_matches)) => {
      let output_values = init_matches.values["output"]
      let output_path = output_values[0]
      Ok(Init(@init_cmd.InitParams::{ output_path, }))
    }
    Some(("build", build_matches)) => {
      ignore(build_matches)
      Ok(Build(@build_cmd.BuildParams::{ repo: "" }))
    }
    Some(("diff", diff_matches)) => {
      ignore(diff_matches)
      Ok(
        Diff(@diff_cmd.DiffParams::{
          repo: "",
          since: None,
          include_test_changes: false,
        }),
      )
    }
    Some(("check", check_matches)) => {
      ignore(check_matches)
      Ok(Check(@check_cmd.CheckParams::{ diff_file: "", policy_bundle: "" }))
    }
    Some(("query", query_matches)) => {
      let query_values = query_matches.values["query_file"]
      let query_file = query_values[0]
      Ok(Query(@query_cmd.QueryParams::{ query_file, }))
    }
    Some(("publish", publish_matches)) => {
      ignore(publish_matches)
      Ok(Publish(@publish_cmd.PublishParams::{ bundle_file: "" }))
    }
    Some(("registry", registry_matches)) =>
      match registry_matches.subcommand {
        Some(("serve", serve_matches)) => {
          let port_values = serve_matches.values["port"]
          let parsed_port = try? @string.parse_int(port_values[0])
          guard parsed_port is Ok(port) else {
            return Err(usage_error(message="--port must be an integer"))
          }
          Ok(RegistryServe(@registry_cmd.RegistryServeParams::{ port, }))
        }
        Some(("status", _)) => Ok(RegistryStatus)
        _ => Err(usage_error())
      }
    Some(("mcp", mcp_matches)) =>
      match mcp_matches.subcommand {
        Some(("serve", serve_matches)) => {
          let port_values = serve_matches.values["port"]
          let parsed_port = try? @string.parse_int(port_values[0])
          guard parsed_port is Ok(port) else {
            return Err(usage_error(message="--port must be an integer"))
          }
          Ok(McpServe(@mcp_core.McpServeParams::{ port, }))
        }
        Some(("status", _)) => Ok(McpStatus)
        _ => Err(usage_error())
      }
    _ => Err(usage_error())
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
    RegistryServe(params) =>
      match @registry_cmd.run_serve(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    RegistryStatus =>
      match @registry_cmd.run_status() {
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
  }
}

///|
fn main {
  let logger = @cli.new_logger()
  let all_args = @env.args()
  println(@cli.banner())

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
