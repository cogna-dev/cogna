///|
pub(all) struct McpStartParams {
  port : Int
} derive(Show, Eq)

///|
pub(all) struct McpStartResult {
  port : Int
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for McpStartResult with display(self : McpStartResult) -> String {
  self.summary
}

///|
fn mcp_error(message : String) -> @cli.CliError {
  @cli.command_error("mcp failed: \{message}")
}

///|
fn validate_port(port : Int) -> Result[Unit, @cli.CliError] {
  if port <= 0 || port > 65535 {
    Err(mcp_error("port must be in range 1..65535"))
  } else {
    Ok(())
  }
}

///|
fn mcp_server_info(port : Int) -> Json {
  {
    "name": "codeiq-mcp",
    "version": "0.1.0",
    "transport": "stdio",
    "port": port,
    "tools": [
      {
        "name": "codeiq.query.outlines",
        "description": "List high-level outlines for a local CIQ bundle",
      },
      {
        "name": "codeiq.query.symbol",
        "description": "Query declaration details by selector",
      },
    ],
  }
}

///|
fn write_mcp_info(path : String, info : Json) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, info.stringify(indent=2)) catch {
    err =>
      return Err(mcp_error("cannot write mcp info \{path}: \{err.to_string()}"))
  }
  Ok(())
}

///|
pub fn run_start(
  params : McpStartParams,
) -> @cli.CliResult[McpStartResult, @cli.CliError] {
  let port_out = validate_port(params.port)
  guard port_out is Ok(_) else { return Err(port_out.unwrap_err()) }

  if !@fs.path_exists("./dist") {
    @fs.create_dir("./dist") catch {
      err =>
        return Err(
          mcp_error("cannot create ./dist directory: \{err.to_string()}"),
        )
    }
  }

  let info_path = "./dist/mcp-server.json"
  let write_out = write_mcp_info(info_path, mcp_server_info(params.port))
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    port: params.port,
    summary: "Generated MCP server descriptor at \{info_path} (port \{params.port})",
  })
}
