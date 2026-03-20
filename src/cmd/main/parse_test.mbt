///|
test "parse invocation uses positional diff and policy paths" {
  let argv = [
    "codeiq", "check", "./dist/tokio.diff.json", "--policy", "./dist/compat-policy.ciq.tgz",
  ]
  let out = parse_cli_args(argv)
  guard out is Ok(Check(params)) else {
    fail("expected check invocation to parse")
  }

  inspect(params.diff_file, content="./dist/tokio.diff.json")
  inspect(params.policy_bundle, content="./dist/compat-policy.ciq.tgz")
}

///|
test "parse invocation supports query positional file" {
  let argv = ["codeiq", "query", "./query.json"]
  let out = parse_cli_args(argv)
  guard out is Ok(Query(params)) else {
    fail("expected query invocation to parse")
  }

  inspect(params.query_file, content="./query.json")
}

///|
test "parse invocation supports publish positional bundle" {
  let argv = ["codeiq", "publish", "./dist/tokio@1.43.0.ciq.tgz"]
  let out = parse_cli_args(argv)
  guard out is Ok(Publish(params)) else {
    fail("expected publish invocation to parse")
  }

  inspect(params.bundle_file, content="./dist/tokio@1.43.0.ciq.tgz")
}

///|
test "parse invocation supports mcp start with custom port" {
  let argv = ["codeiq", "mcp", "start", "--port", "9090"]
  let out = parse_cli_args(argv)
  guard out is Ok(McpStart(params)) else {
    fail("expected mcp start invocation to parse")
  }

  inspect(params.port, content="9090")
}
