///|
pub(all) enum CliInvocation {
  Init(@init_cmd.InitParams)
  Build(@build_cmd.BuildParams)
  Diff(@diff_cmd.DiffParams)
  Check(@check_cmd.CheckParams)
  Query(@query_cmd.QueryParams)
  Publish(@publish_cmd.PublishParams)
  McpStart(@mcp_cmd.McpStartParams)
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
      @argparse.Command::new("build", about="Build CIQ bundle"),
      @argparse.Command::new("diff", about="Compute CIQ diff"),
      @argparse.Command::new("check", about="Run policy checks"),
      @argparse.Command::new("query", about="Query CIQ bundle"),
      @argparse.Command::new("publish", about="Publish CIQ bundle"),
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
          ]),
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
    Some(("build", _)) => Ok(Build(@build_cmd.BuildParams::{ repo: "./" }))
    Some(("diff", _)) => Ok(Diff(@diff_cmd.DiffParams::{ repo: "./" }))
    Some(("check", _)) =>
      Ok(
        Check(@check_cmd.CheckParams::{
          diff_file: "./dist/diff.json",
          policy_bundle: "./dist/policy.ciq.tgz",
        }),
      )
    Some(("query", _)) =>
      Ok(Query(@query_cmd.QueryParams::{ query_file: "./dist/query.json" }))
    Some(("publish", _)) =>
      Ok(
        Publish(@publish_cmd.PublishParams::{
          bundle_file: "./dist/bundle.ciq.tgz",
        }),
      )
    Some(("mcp", mcp_matches)) =>
      match mcp_matches.subcommand {
        Some(("start", start_matches)) => {
          let port_values = start_matches.values["port"]
          let parsed_port = try? @strconv.parse_int(port_values[0])
          guard parsed_port is Ok(port) else {
            return Err(@cli.usage_error("--port must be an integer"))
          }
          Ok(McpStart(@mcp_cmd.McpStartParams::{ port, }))
        }
        _ => Err(@cli.usage_error(command.render_help()))
      }
    _ => Err(@cli.usage_error(command.render_help()))
  }
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
    McpStart(params) =>
      match @mcp_cmd.run_start(params) {
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

  let parse_out = parse_invocation(normalize_cli_args(all_args))
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
