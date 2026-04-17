///|
pub(all) enum CliInvocation {
  Init(@init_cmd.InitParams)
  Open(@open_cmd.OpenParams)
  Build(@build_cmd.BuildParams)
  Diff(@diff_cmd.DiffParams)
  Check(@check_cmd.CheckParams)
  Query(@query_cmd.QueryParams)
  Serve(@serve_cmd.ServeParams)
  CacheList(@cache_cmd.CacheListParams)
  CacheAdd(@cache_cmd.CacheAddParams)
  CacheRemove(@cache_cmd.CacheRemoveParams)
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
    Open(params) => {
      logger.write_string("Open(")
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
    Serve(params) => {
      logger.write_string("Serve(")
      logger.write_object(params)
      logger.write_char(')')
    }
    CacheList(params) => {
      logger.write_string("CacheList(")
      logger.write_object(params)
      logger.write_char(')')
    }
    CacheAdd(params) => {
      logger.write_string("CacheAdd(")
      logger.write_object(params)
      logger.write_char(')')
    }
    CacheRemove(params) => {
      logger.write_string("CacheRemove(")
      logger.write_object(params)
      logger.write_char(')')
    }
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
    | "open"
    | "build"
    | "diff"
    | "check"
    | "query"
    | "serve"
    | "cache"
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
    #|Cogna declaration-aware CLI
    #|
    #|Usage: cogna <command> [options]
    #|
    #|Core
    #|  init                Initialize cogna.yml
    #|  open <folder>       Open workspace in desktop app
    #|  build               Build CIQ bundle
    #|  diff                Compute CIQ diff
    #|  check               Run policy checks
    #|  query <query-file>  Query CIQ bundle
    #|
    #|Cache
    #|  serve               Run cache proxy command
    #|  cache list          List local cache entries
    #|  cache add           Add object to local cache
    #|  cache remove        Remove object from local cache
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
    "cogna",
    about="Cogna declaration-aware CLI",
    subcommands=[
      @argparse.Command::new("init", about="Initialize cogna.yml", options=[
        @argparse.OptionArg::new(
          "output",
          long="output",
          action=@argparse.OptionAction::Set,
          default_values=["./cogna.yml"],
        ),
      ]),
      @argparse.Command::new("open", about="Open workspace in desktop app", positionals=[
        @argparse.PositionArg::new(
          "folder",
          num_args=@argparse.ValueRange::single(),
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
      @argparse.Command::new(
        "serve",
        about="Run cache proxy command",
        options=[
          @argparse.OptionArg::new(
            "port",
            long="port",
            action=@argparse.OptionAction::Set,
            default_values=["8787"],
          ),
        ],
      ),
      @argparse.Command::new(
        "cache",
        about="Manage local cache objects",
        subcommands=[
          @argparse.Command::new(
            "list",
            about="List local cache entries",
            options=[
              @argparse.OptionArg::new(
                "prefix",
                long="prefix",
                action=@argparse.OptionAction::Set,
                default_values=[""],
              ),
            ],
          ),
          @argparse.Command::new(
            "add",
            about="Add object to local cache",
            options=[
              @argparse.OptionArg::new(
                "key",
                long="key",
                action=@argparse.OptionAction::Set,
                default_values=[""],
              ),
              @argparse.OptionArg::new(
                "file",
                long="file",
                action=@argparse.OptionAction::Set,
                default_values=[""],
              ),
            ],
          ),
          @argparse.Command::new(
            "remove",
            about="Remove object from local cache",
            options=[
              @argparse.OptionArg::new(
                "key",
                long="key",
                action=@argparse.OptionAction::Set,
                default_values=[""],
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
  guard parse_result is Ok(matches) else { return Err(usage_error()) }
  match matches.subcommand {
    Some(("init", init_matches)) => {
      let output_values = init_matches.values["output"]
      let output_path = output_values[0]
      Ok(Init(@init_cmd.InitParams::{ output_path, }))
    }
    Some(("open", open_matches)) => {
      let folder_values = open_matches.values["folder"]
      Ok(Open(@open_cmd.OpenParams::{ folder: folder_values[0], }))
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
      Ok(Check(@check_cmd.CheckParams::{ diff_file: "", policies_dir: "" }))
    }
    Some(("query", query_matches)) => {
      let query_values = query_matches.values["query_file"]
      let query_file = query_values[0]
      Ok(Query(@query_cmd.QueryParams::{ query_file, }))
    }
    Some(("serve", serve_matches)) => {
      let port_values = serve_matches.values["port"]
      let parsed_port = try? @string.parse_int(port_values[0])
      guard parsed_port is Ok(port) else {
        return Err(usage_error(message="--port must be an integer"))
      }
      Ok(Serve(@serve_cmd.ServeParams::{ port, }))
    }
    Some(("cache", cache_matches)) =>
      match cache_matches.subcommand {
        Some(("list", list_matches)) => {
          let prefix_values = list_matches.values["prefix"]
          Ok(CacheList(@cache_cmd.CacheListParams::{ prefix: prefix_values[0], }))
        }
        Some(("add", add_matches)) => {
          let key_values = add_matches.values["key"]
          let file_values = add_matches.values["file"]
          if key_values[0] == "" {
            return Err(usage_error(message="cache add requires --key"))
          }
          if file_values[0] == "" {
            return Err(usage_error(message="cache add requires --file"))
          }
          Ok(
            CacheAdd(@cache_cmd.CacheAddParams::{
              key: key_values[0],
              file_path: file_values[0],
            }),
          )
        }
        Some(("remove", remove_matches)) => {
          let key_values = remove_matches.values["key"]
          if key_values[0] == "" {
            return Err(usage_error(message="cache remove requires --key"))
          }
          Ok(CacheRemove(@cache_cmd.CacheRemoveParams::{ key: key_values[0], }))
        }
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
    Open(params) =>
      match @open_cmd.run(params) {
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
    Serve(params) =>
      match @serve_cmd.run(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    CacheList(params) =>
      match @cache_cmd.run_list(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    CacheAdd(params) =>
      match @cache_cmd.run_add(params) {
        Ok(result) => Ok(@cli.display(result))
        Err(error) => Err(error)
      }
    CacheRemove(params) =>
      match @cache_cmd.run_remove(params) {
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
