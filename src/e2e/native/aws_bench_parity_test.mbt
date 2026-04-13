///|
fn remove_file_if_exists(path : String) -> Unit {
  @fs.remove_file(path) catch {
    _ => ()
  }
}

///|
fn remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn clear_dir_contents(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  let is_dir = try? @fs.is_dir(path)
  guard is_dir is Ok(true) else { return }
  let entries = @fs.read_dir(path) catch {
    _ => return
  }
  for entry in entries {
    let child = "\{path}/\{entry}"
    let child_is_dir = try? @fs.is_dir(child)
    match child_is_dir {
      Ok(true) => {
        clear_dir_contents(child)
        @fs.remove_dir(child) catch {
          _ => ()
        }
      }
      _ => @fs.remove_file(child) catch {
        _ => ()
      }
    }
  }
}

///|
fn bench_fixture_size_summary(path : String) -> (Int, Int) {
  let metadata = @fs.read_file_to_string(path) catch {
    _ => return (0, 0)
  }
  let combined = metadata.trim().to_string()
  let raw = @utf8.encode(combined).length()
  let gz = @build_cmd.gzip_size_of(combined)
  (raw, gz)
}

///|
fn ensure_clean_dir(path : String) -> Unit {
  if @fs.path_exists(path) {
    clear_dir_contents(path)
  } else {
    @fs.create_dir(path) catch {
      _ => abort("failed to create benchmark dir")
    }
  }
}

///|
fn bench_repo_root() -> String {
  @env.current_dir().unwrap_or(".")
}

///|
fn configured_bench_warmup_runs() -> Int {
  match @sys.get_env_var("CODEIQ_BENCH_WARMUP_RUNS") {
    Some(value) => {
      let parsed = try? @string.parse_int(value.trim())
      match parsed {
        Ok(v) if v >= 0 => v
        _ => 1
      }
    }
    None => 1
  }
}

///|
fn configured_bench_measure_runs() -> Int {
  match @sys.get_env_var("CODEIQ_BENCH_MEASURE_RUNS") {
    Some(value) => {
      let parsed = try? @string.parse_int(value.trim())
      match parsed {
        Ok(v) if v > 0 => v
        _ => 9
      }
    }
    None => 9
  }
}

///|
fn parse_bench_json(stdout : String) -> Json {
  let parsed = try? @json.parse(stdout.trim().to_string())
  match parsed {
    Ok(value) => value
    Err(_) => Json::null()
  }
}

///|
fn run_bench_command(command : String) -> Result[Json, String] {
  let (exit_code, stdout, stderr) = @e2e_shell.run_command_capture(command)
  if exit_code != 0 {
    Err(if stderr != "" { stderr } else { stdout })
  } else {
    Ok(parse_bench_json(stdout))
  }
}

///|
fn write_bench_summary(path : String, summary : Json) -> Unit {
  @fs.write_string_to_file(path, summary.stringify(indent=2)) catch {
    _ => abort("failed to write benchmark summary")
  }
}

///|
test "aws bench parity summary stays JSON-shaped" {
  let bench_dir = "src/e2e/tmp_codeiq_e2e_aws_bench"
  ensure_clean_dir(bench_dir)
  let warmup_runs = configured_bench_warmup_runs()
  let measure_runs = configured_bench_measure_runs()
  assert_true(warmup_runs >= 0)
  assert_true(measure_runs > 0)

  let repo_root = bench_repo_root()
  let benchmarked_command =
    "python3 'src/e2e/bench.py' --help >/dev/null 2>&1"
  let command = (
    "python3 'src/e2e/bench.py' --cwd '") +
    repo_root +
    ("' --warmup-runs ") +
    warmup_runs.to_string() +
    (" --measure-runs ") +
    measure_runs.to_string() +
    " \"" + benchmarked_command + "\""
  let out = run_bench_command(command)
  guard out is Ok(summary) else {
    fail("aws bench command should succeed: \{out.unwrap_err()}")
  }

  inspect(summary is Object(_), content="true")
  let summary_text = summary.stringify(indent=2)
  assert_true(summary_text.contains("\"warmupRuns\""))
  assert_true(summary_text.contains("\"measureRuns\""))
  assert_true(summary_text.contains("\"samples\""))

  let summary_file = "\{bench_dir}/summary.json"
  write_bench_summary(summary_file, summary)
  let (raw, gz) = bench_fixture_size_summary(summary_file)
  assert_true(raw >= 0)
  assert_true(gz >= 0)
  remove_file_if_exists(summary_file)
  remove_dir_if_exists(bench_dir)
}
