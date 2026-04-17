///|
test "parse invocation uses config-driven check defaults" {
  let argv = ["cogna", "check"]
  let out = parse_cli_args(argv)
  guard out is Ok(Check(params)) else {
    fail("expected check invocation to parse")
  }

  inspect(params.diff_file, content="")
  inspect(params.policies_dir, content="")
}

///|
test "parse invocation supports query positional file" {
  let argv = ["cogna", "query", "./query.json"]
  let out = parse_cli_args(argv)
  guard out is Ok(Query(params)) else {
    fail("expected query invocation to parse")
  }

  inspect(params.query_file, content="./query.json")
}

///|
test "parse invocation supports open positional folder" {
  let argv = ["cogna", "open", "./workspace"]
  let out = parse_cli_args(argv)
  guard out is Ok(Open(params)) else {
    fail("expected open invocation to parse")
  }

  inspect(params.folder, content="./workspace")
}

///|
test "parse invocation supports serve with custom port" {
  let argv = ["cogna", "serve", "--port", "8788"]
  let out = parse_cli_args(argv)
  guard out is Ok(Serve(params)) else {
    fail("expected serve invocation to parse")
  }

  inspect(params.port, content="8788")
}

///|
test "parse invocation supports cache list" {
  let argv = ["cogna", "cache", "list", "--prefix", "blob/"]
  let out = parse_cli_args(argv)
  guard out is Ok(CacheList(params)) else {
    fail("expected cache list invocation to parse")
  }

  inspect(params.prefix, content="blob/")
}

///|
test "parse invocation supports cache add" {
  let argv = [
    "cogna",
    "cache",
    "add",
    "--key",
    "blob/sha256/abc",
    "--file",
    "./dist/out.bin",
  ]
  let out = parse_cli_args(argv)
  guard out is Ok(CacheAdd(params)) else {
    fail("expected cache add invocation to parse")
  }

  inspect(params.key, content="blob/sha256/abc")
  inspect(params.file_path, content="./dist/out.bin")
}

///|
test "parse invocation supports cache remove" {
  let argv = ["cogna", "cache", "remove", "--key", "blob/sha256/abc"]
  let out = parse_cli_args(argv)
  guard out is Ok(CacheRemove(params)) else {
    fail("expected cache remove invocation to parse")
  }

  inspect(params.key, content="blob/sha256/abc")
}

///|
test "parse invocation supports mcp serve with custom port" {
  let argv = ["cogna", "mcp", "serve", "--port", "9090"]
  let out = parse_cli_args(argv)
  guard out is Ok(McpServe(params)) else {
    fail("expected mcp serve invocation to parse")
  }

  inspect(params.port, content="9090")
}

///|
test "parse invocation supports config-driven build defaults" {
  let argv = ["cogna", "build"]
  let out = parse_cli_args(argv)
  guard out is Ok(Build(params)) else {
    fail("expected build invocation to parse")
  }

  inspect(params.repo, content="")
}

///|
test "parse invocation supports config-driven diff defaults" {
  let argv = ["cogna", "diff"]
  let out = parse_cli_args(argv)
  guard out is Ok(Diff(params)) else {
    fail("expected diff invocation to parse")
  }

  inspect(params.repo, content="")
}

///|
test "parse invocation leaves diff overrides empty for config resolution" {
  let argv = ["cogna", "diff"]
  let out = parse_cli_args(argv)
  guard out is Ok(Diff(params)) else {
    fail("expected diff invocation with options to parse")
  }

  inspect(params.repo, content="")
  inspect(params.since.unwrap_or(""), content="")
  inspect(params.include_test_changes, content="false")
}

///|
test "parse invocation supports mcp status" {
  let status_out = parse_cli_args(["cogna", "mcp", "status"])
  guard status_out is Ok(McpStatus) else {
    fail("expected mcp status to parse")
  }
}
