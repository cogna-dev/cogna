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
test "parse invocation supports registry upload-local" {
  let argv = ["codeiq", "registry", "upload-local", "./dist/upload.json"]
  let out = parse_cli_args(argv)
  guard out is Ok(RegistryUploadLocal(params)) else {
    fail("expected registry upload-local invocation to parse")
  }

  inspect(params.upload_request_file, content="./dist/upload.json")
}

///|
test "parse invocation supports registry download-local" {
  let argv = [
    "codeiq", "registry", "download-local", "pkg:generic/acme/demo@0.1.0",
  ]
  let out = parse_cli_args(argv)
  guard out is Ok(RegistryDownloadLocal(params)) else {
    fail("expected registry download-local invocation to parse")
  }

  inspect(params.purl, content="pkg:generic/acme/demo@0.1.0")
}

///|
test "parse invocation supports registry download with output" {
  let argv = [
    "codeiq", "registry", "download", "pkg:generic/acme/demo@0.1.0", "--output",
    "./cache/demo",
  ]
  let out = parse_cli_args(argv)
  guard out is Ok(RegistryDownloadBundle(params)) else {
    fail("expected registry download invocation to parse")
  }

  inspect(params.purl, content="pkg:generic/acme/demo@0.1.0")
  inspect(params.output_dir, content="./cache/demo")
}

///|
test "parse invocation supports mcp start with custom port" {
  let argv = ["codeiq", "mcp", "start", "--port", "9090"]
  let out = parse_cli_args(argv)
  guard out is Ok(McpStart(params)) else {
    fail("expected mcp start invocation to parse")
  }

  inspect(params.port, content="9090")
  inspect(params.stdio, content="true")
}

///|
test "parse invocation supports mcp start stdio flag" {
  let argv = ["codeiq", "mcp", "start", "--stdio", "true"]
  let out = parse_cli_args(argv)
  guard out is Ok(McpStart(params)) else {
    fail("expected mcp start invocation to parse")
  }

  inspect(params.port, content="3000")
  inspect(params.stdio, content="true")
}

///|
test "parse invocation supports build positional repo" {
  let argv = ["codeiq", "build", "./sdk"]
  let out = parse_cli_args(argv)
  guard out is Ok(Build(params)) else {
    fail("expected build invocation to parse")
  }

  inspect(params.repo, content="./sdk")
}

///|
test "parse invocation supports diff positional repo" {
  let argv = ["codeiq", "diff", "./sdk"]
  let out = parse_cli_args(argv)
  guard out is Ok(Diff(params)) else {
    fail("expected diff invocation to parse")
  }

  inspect(params.repo, content="./sdk")
}

///|
test "parse invocation supports diff since and test-changes options" {
  let argv = [
    "codeiq", "diff", "./sdk", "--since", "2026-03-01T00:00:00Z", "--test-changes",
    "true",
  ]
  let out = parse_cli_args(argv)
  guard out is Ok(Diff(params)) else {
    fail("expected diff invocation with options to parse")
  }

  inspect(params.repo, content="./sdk")
  inspect(params.since.unwrap_or(""), content="2026-03-01T00:00:00Z")
  inspect(params.include_test_changes, content="true")
}

///|
test "parse invocation supports mcp status and stop" {
  let status_out = parse_cli_args(["codeiq", "mcp", "status"])
  guard status_out is Ok(McpStatus) else {
    fail("expected mcp status to parse")
  }

  let stop_out = parse_cli_args(["codeiq", "mcp", "stop"])
  guard stop_out is Ok(McpStop) else { fail("expected mcp stop to parse") }
}
