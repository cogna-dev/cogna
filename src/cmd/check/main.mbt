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
fn shell_escape(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn policy_rules_from_opa_json(value : Json) -> Array[Json] {
  guard value is Object(root) else { return [] }
  guard root.get("result") is Some(Array(results)) else { return [] }
  let out : Array[Json] = []
  for i in 0..<results.length() {
    guard results[i] is Object(result_object) else { continue }
    guard result_object.get("expressions") is Some(Array(expressions)) else {
      continue
    }
    for j in 0..<expressions.length() {
      guard expressions[j] is Object(expression_object) else { continue }
      guard expression_object.get("value") is Some(Array(items)) else {
        continue
      }
      for k in 0..<items.length() {
        if items[k] is Object(_) {
          out.push(items[k])
        }
      }
    }
  }
  out
}

///|
fn map_policy_level(level : String) -> String {
  match level {
    "error" => "error"
    "warning" => "warning"
    _ => "note"
  }
}

///|
fn rules_from_policy_results(policy_results : Array[Json]) -> Array[Json] {
  let rules : Array[Json] = [
    {
      "id": "compat.changed",
      "shortDescription": {
        "text": "Compatibility change requires policy review",
      },
      "fullDescription": {
        "text": "Maps declaration-level compatibility diff entries to SARIF diagnostics.",
      },
      "helpUri": "https://github.com/yufeiminds/codeiq/blob/main/spec/proposal.typ",
      "properties": { "source": "codeiq-diff", "category": "compatibility" },
    },
  ]
  let seen : Map[String, Unit] = { "compat.changed": () }
  for i in 0..<policy_results.length() {
    guard policy_results[i] is Object(policy) else { continue }
    guard policy.get("rule_id") is Some(String(rule_id)) else { continue }
    if seen.contains(rule_id) {
      continue
    }
    let message = match policy.get("message") {
      Some(String(text)) => text
      _ => "Policy rule triggered"
    }
    let docs = match policy.get("docs") {
      Some(String(value)) if value != "" => value
      _ => "https://github.com/yufeiminds/codeiq/blob/main/spec/proposal.typ"
    }
    rules.push({
      "id": rule_id,
      "shortDescription": { "text": message },
      "fullDescription": {
        "text": "Policy decision produced by OPA evaluation for CIQ diff entries.",
      },
      "helpUri": docs,
      "properties": { "source": "opa-policy", "category": "policy" },
    })
    seen[rule_id] = ()
  }
  rules
}

///|
fn sarif_results_from_policy(policy_results : Array[Json]) -> Array[Json] {
  let out : Array[Json] = []
  for i in 0..<policy_results.length() {
    guard policy_results[i] is Object(policy) else { continue }
    let rule_id = match policy.get("rule_id") {
      Some(String(value)) if value != "" => value
      _ => "policy.generic"
    }
    let level = match policy.get("level") {
      Some(String(value)) => map_policy_level(value)
      _ => "warning"
    }
    let message = match policy.get("message") {
      Some(String(value)) if value != "" => value
      _ => "Policy decision triggered"
    }
    let path = match policy.get("path") {
      Some(String(value)) if value != "" => value
      _ => "unknown"
    }
    out.push({
      "ruleId": rule_id,
      "level": level,
      "message": { "text": message },
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
  out
}

///|
/// Shapes a ciq-diff/v1 Json document into a flat OPA-friendly input envelope.
///
/// Produces:
/// ```json
/// {
///   "schemaVersion": "ciq-diff/v1",
///   "basePurl": "...",
///   "targetPurl": "...",
///   "summary": { ... },
///   "changes": [
///     {
///       "id": "...", "kind": "...", "level": "...",
///       "semanticCategory": "...",
///       "path": "...", "before": "...", "after": "...",
///       "semanticDiff": { ... }
///     }
///   ],
///   "componentChanges": [
///     {
///       "id": "...", "kind": "...", "level": "...",
///       "semanticCategory": "...",
///       "path": "...",
///       "upgradeKind": "...",
///       "beforeVersion": "...", "afterVersion": "...",
///       "beforePurl": "...", "afterPurl": "..."
///     }
///   ]
/// }
/// ```
fn prepare_opa_input(diff : Json) -> Json {
  guard diff is Object(diff_object) else { return diff }

  let changes : Array[Json] = []
  let component_changes : Array[Json] = []

  match diff_object.get("changes") {
    Some(Array(raw_changes)) =>
      for change in raw_changes {
        guard change is Object(co) else { continue }
        let id = match co.get("id") {
          Some(String(v)) => v
          _ => "unknown"
        }
        let kind = match co.get("kind") {
          Some(String(v)) => v
          _ => "changed"
        }
        let level = match co.get("level") {
          Some(String(v)) => v
          _ => "warning"
        }
        let path = match co.get("path") {
          Some(String(v)) => v
          _ => "unknown"
        }
        let semantic_category = match co.get("semanticCategory") {
          Some(String(v)) => v
          _ => ""
        }
        let before = match co.get("before") {
          Some(v) => v
          None => Json::null()
        }
        let after = match co.get("after") {
          Some(v) => v
          None => Json::null()
        }
        let semantic_diff = match co.get("semanticDiff") {
          Some(v) => v
          None => Json::null()
        }
        // Component-level changes go to componentChanges
        if co.get("componentDiff") is Some(Object(cd)) {
          let upgrade_kind = match cd.get("upgradeKind") {
            Some(String(v)) => v
            _ => "unknown"
          }
          component_changes.push({
            "id": id,
            "kind": kind,
            "level": level,
            "semanticCategory": semantic_category,
            "path": path,
            "upgradeKind": upgrade_kind,
            "beforeVersion": match cd.get("beforeVersion") {
              Some(v) => v
              None => Json::null()
            },
            "afterVersion": match cd.get("afterVersion") {
              Some(v) => v
              None => Json::null()
            },
            "beforePurl": match cd.get("beforePurl") {
              Some(v) => v
              None => Json::null()
            },
            "afterPurl": match cd.get("afterPurl") {
              Some(v) => v
              None => Json::null()
            },
          })
        } else {
          changes.push({
            "id": id,
            "kind": kind,
            "level": level,
            "semanticCategory": semantic_category,
            "path": path,
            "before": before,
            "after": after,
            "semanticDiff": semantic_diff,
          })
        }
      }
    _ => ()
  }

  // Build output preserving top-level fields and replacing changes
  let out : Map[String, Json] = {}
  for k, v in diff_object {
    if k != "changes" {
      out[k] = v
    }
  }
  out["changes"] = Json::array(changes)
  out["componentChanges"] = Json::array(component_changes)
  Json::object(out)
}

///|
fn write_temp_json(
  path : String,
  content : Json,
) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, content.stringify(indent=2)) catch {
    err =>
      return Err(
        check_error("cannot write temp file \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
fn evaluate_policy_with_opa(
  policy_bundle : String,
  diff_file : String,
  diff : Json,
) -> Result[Array[Json], @cli.CliError] {
  let eval_json_override = @sys.get_env_var("CODEIQ_OPA_EVAL_JSON")
  if eval_json_override is Some(text) {
    let parsed = try? @json.parse(text)
    guard parsed is Ok(value) else {
      return Err(check_error("invalid json in CODEIQ_OPA_EVAL_JSON"))
    }
    return Ok(policy_rules_from_opa_json(value))
  }

  if !@fs.path_exists(policy_bundle) {
    return Err(check_error("missing policy bundle file: \{policy_bundle}"))
  }

  // Write OPA-shaped input to a temp file for OPA eval
  let enriched = prepare_opa_input(diff)
  let temp_input = "\{diff_file}.opa-input.json"
  let write_out = write_temp_json(temp_input, enriched)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  let command = "opa eval --bundle \{shell_escape(policy_bundle)} --input \{shell_escape(temp_input)} --format json data.codeiq.compat.deny"
  let (exit_code, stdout, stderr) = @shell.run_command_capture(command)
  @fs.remove_file(temp_input) catch { _ => () }
  if exit_code != 0 {
    let details = if stderr != "" { stderr } else { stdout }
    return Err(check_error("opa eval failed (exit \{exit_code}): \{details}"))
  }
  let parsed = try? @json.parse(stdout)
  guard parsed is Ok(value) else {
    return Err(check_error("opa eval returned non-json output"))
  }
  Ok(policy_rules_from_opa_json(value))
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
  let out = @schema.validate_ciq_diff_v1(diff)
  guard out is Ok(_) else {
    return Err(
      check_error(
        "diff \{diff_path} does not satisfy ciq-diff/v1 schema: \{out.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(())
}

///|
/// Extract source file URI from a declaration record's `location` field.
/// Falls back to `path` if no location is present in the record.
fn location_uri_from_record(record : Json, fallback : String) -> String {
  guard record is Object(obj) else { return fallback }
  match obj.get("location") {
    Some(Object(loc)) =>
      match loc.get("uri") {
        Some(String(uri)) if uri != "" => uri
        _ =>
          match loc.get("file") {
            Some(String(f)) if f != "" => f
            _ => fallback
          }
      }
    Some(String(f)) if f != "" => f
    _ => fallback
  }
}

///|
/// Extract start line from a declaration record's `location` field.
fn location_line_from_record(record : Json) -> Int {
  guard record is Object(obj) else { return 1 }
  match obj.get("location") {
    Some(Object(loc)) =>
      match loc.get("startLine") {
        Some(Number(n, ..)) => n.to_int()
        _ =>
          match loc.get("line") {
            Some(Number(n, ..)) => n.to_int()
            _ => 1
          }
      }
    _ => 1
  }
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
    let semantic_category = match change_object.get("semanticCategory") {
      Some(String(value)) if value != "" => value
      _ => ""
    }

    // Prefer location from beforeRecord (for changed/removed) or afterRecord (for added)
    let before_record = match change_object.get("beforeRecord") {
      Some(v) => v
      None => Json::null()
    }
    let after_record = match change_object.get("afterRecord") {
      Some(v) => v
      None => Json::null()
    }
    let location_uri = if before_record != Json::null() {
      location_uri_from_record(before_record, path)
    } else if after_record != Json::null() {
      location_uri_from_record(after_record, path)
    } else {
      path
    }
    let start_line = if before_record != Json::null() {
      location_line_from_record(before_record)
    } else if after_record != Json::null() {
      location_line_from_record(after_record)
    } else {
      1
    }

    // Build semantic-aware message
    let base_msg = if semantic_category != "" {
      "Detected \{kind} change for \{path} (\{id}) [\{semantic_category}]"
    } else {
      "Detected \{kind} change for \{path} (\{id})"
    }

    results.push({
      "ruleId": "compat.\{kind}",
      "level": level,
      "message": { "text": base_msg },
      "locations": [
        {
          "physicalLocation": {
            "artifactLocation": { "uri": location_uri },
            "region": { "startLine": start_line, "endLine": start_line },
          },
        },
      ],
    })
  }
  results
}

///|
fn sarif_from_diff(
  diff : Json,
  policy_bundle : String,
  policy_results : Array[Json],
) -> Json {
  let results = sarif_results_from_diff(diff)
  let from_policy = sarif_results_from_policy(policy_results)
  for i in 0..<from_policy.length() {
    results.push(from_policy[i])
  }

  {
    "version": "2.1.0",
    "runs": [
      {
        "tool": {
          "driver": {
            "name": "codeiq-check",
            "rules": rules_from_policy_results(policy_results),
          },
        },
        "invocation": {
          "executionSuccessful": true,
          "commandLine": "codeiq check --policy \{policy_bundle}",
        },
        "results": results,
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

  let policy_results_out = evaluate_policy_with_opa(
    params.policy_bundle,
    params.diff_file,
    diff,
  )
  guard policy_results_out is Ok(policy_results) else {
    return Err(policy_results_out.unwrap_err())
  }

  let sarif_path = "\{parent_dir(params.diff_file)}/check.sarif.json"
  let sarif = sarif_from_diff(diff, params.policy_bundle, policy_results)
  let sarif_shape_out = @schema.validate_sarif_v2_1_0_min(sarif)
  guard sarif_shape_out is Ok(_) else {
    return Err(
      check_error(
        "generated sarif does not satisfy minimal SARIF schema: \{sarif_shape_out.unwrap_err().to_string()}",
      ),
    )
  }

  let write_out = write_sarif(sarif_path, sarif)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    diff_file: params.diff_file,
    policy_bundle: params.policy_bundle,
    summary: "Generated SARIF report at \{sarif_path}",
  })
}
