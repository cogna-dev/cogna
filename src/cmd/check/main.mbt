///|
pub(all) struct CheckParams {
  diff_file : String
  policy_bundle : String
} derive(Show, Eq)

///|
pub(all) struct CheckResult {
  diff_file : String
  policy_bundle : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for CheckResult with display(self : CheckResult) -> String {
  self.summary
}

///|
fn check_error(message : String) -> @cli.CliError {
  @cli.command_error("check failed: \{message}")
}

///|
fn read_json_file(path : String, kind : String) -> Result[Json, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(check_error("cannot read \{kind} \{path}: \{err.to_string()}"))
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(check_error("invalid json in \{kind} \{path}"))
  }
  Ok(value)
}

///|
fn ensure_file_exists(
  path : String,
  kind : String,
) -> Result[Unit, @cli.CliError] {
  if @fs.path_exists(path) {
    Ok(())
  } else {
    Err(check_error("missing \{kind} file: \{path}"))
  }
}

///|
fn parent_dir(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() <= 1 {
    "."
  } else {
    let mut out = ""
    for i in 0..<(parts.length() - 1) {
      if i > 0 {
        out = "\{out}/"
      }
      out = "\{out}\{parts[i]}"
    }
    out
  }
}

///|
fn ensure_diff_shape(
  diff : Json,
  diff_path : String,
) -> Result[Unit, @cli.CliError] {
  guard diff is Object(diff_object) else {
    return Err(check_error("diff \{diff_path} must be a JSON object"))
  }
  guard diff_object.get("schemaVersion") is Some(String("ciq-diff/v1")) else {
    return Err(
      check_error("diff \{diff_path} must use schemaVersion ciq-diff/v1"),
    )
  }
  guard diff_object.get("changes") is Some(Array(_)) else {
    return Err(check_error("diff \{diff_path} missing changes array"))
  }
  Ok(())
}

///|
fn sarif_results_from_diff(diff : Json) -> Array[Json] {
  guard diff is Object(diff_object) else { return [] }
  guard diff_object.get("changes") is Some(Array(changes)) else { return [] }

  let results : Array[Json] = []
  for change in changes {
    guard change is Object(change_object) else { continue }

    let kind = match change_object.get("kind") {
      Some(String(value)) => value
      _ => "changed"
    }
    let level = match change_object.get("level") {
      Some(String("breaking")) => "error"
      Some(String("warning")) => "warning"
      _ => "note"
    }
    let path = match change_object.get("path") {
      Some(String(value)) => value
      _ => "unknown"
    }
    let id = match change_object.get("id") {
      Some(String(value)) => value
      _ => "unknown"
    }

    results.push({
      "ruleId": "compat.\{kind}",
      "level": level,
      "message": { "text": "Detected \{kind} change for \{path} (\{id})" },
      "locations": [
        {
          "physicalLocation": {
            "artifactLocation": { "uri": path },
            "region": { "startLine": 1, "endLine": 1 },
          },
        },
      ],
    })
  }
  results
}

///|
fn sarif_from_diff(diff : Json, policy_bundle : String) -> Json {
  {
    "version": "2.1.0",
    "runs": [
      {
        "tool": {
          "driver": {
            "name": "codeiq-check",
            "rules": [
              {
                "id": "compat.changed",
                "shortDescription": {
                  "text": "Compatibility change requires policy review",
                },
              },
            ],
          },
        },
        "invocation": {
          "executionSuccessful": true,
          "commandLine": "codeiq check --policy \{policy_bundle}",
        },
        "results": sarif_results_from_diff(diff),
      },
    ],
  }
}

///|
fn write_sarif(path : String, sarif : Json) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, sarif.stringify(indent=2)) catch {
    err =>
      return Err(
        check_error("cannot write sarif file \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
pub fn run(params : CheckParams) -> @cli.CliResult[CheckResult, @cli.CliError] {
  let policy_exists = ensure_file_exists(params.policy_bundle, "policy bundle")
  guard policy_exists is Ok(_) else { return Err(policy_exists.unwrap_err()) }

  let diff_out = read_json_file(params.diff_file, "diff")
  guard diff_out is Ok(diff) else { return Err(diff_out.unwrap_err()) }
  let diff_shape_out = ensure_diff_shape(diff, params.diff_file)
  guard diff_shape_out is Ok(_) else { return Err(diff_shape_out.unwrap_err()) }

  let sarif_path = "\{parent_dir(params.diff_file)}/check.sarif.json"
  let sarif = sarif_from_diff(diff, params.policy_bundle)
  let write_out = write_sarif(sarif_path, sarif)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    diff_file: params.diff_file,
    policy_bundle: params.policy_bundle,
    summary: "Generated SARIF report at \{sarif_path}",
  })
}
