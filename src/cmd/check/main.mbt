///|
pub(all) struct CheckParams {
  diff_file : String
  policies_dir : String
} derive(Eq)

///|
pub impl Show for CheckParams with output(self, logger) {
  logger.write_string("{diff_file: ")
  logger.write_object(self.diff_file)
  logger.write_string(", policies_dir: ")
  logger.write_object(self.policies_dir)
  logger.write_char('}')
}

///|
pub(all) struct CheckResult {
  diff_file : String
  policies_dir : String
  summary : String
} derive(Eq)

///|
pub impl Show for CheckResult with output(self, logger) {
  logger.write_string("{diff_file: ")
  logger.write_object(self.diff_file)
  logger.write_string(", policies_dir: ")
  logger.write_object(self.policies_dir)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_char('}')
}

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
fn read_rego_from_dir(policies_dir : String) -> Result[String, @cli.CliError] {
  let entries = @fs.read_dir(policies_dir) catch {
    err =>
      return Err(
        check_error("cannot read policies directory: \{err.to_string()}"),
      )
  }
  let rego_files : Array[String] = []
  for entry in entries {
    if entry.has_suffix(".rego") {
      rego_files.push(entry)
    }
  }
  rego_files.sort()
  let mut text = ""
  for filename in rego_files {
    let content = @fs.read_file_to_string("\{policies_dir}/\{filename}") catch {
      err =>
        return Err(
          check_error("cannot read policy file \{filename}: \{err.to_string()}"),
        )
    }
    text = text + content + "\n"
  }
  Ok(text)
}

///|
fn read_catalog_rego_text(
  policies_dir : String,
) -> Result[String, @cli.CliError] {
  let primary_out = read_rego_from_dir(policies_dir)
  guard primary_out is Ok(primary_text) else {
    return Err(primary_out.unwrap_err())
  }
  if primary_text != "" || policies_dir == "./policies" {
    return Ok(primary_text)
  }
  read_rego_from_dir("./policies")
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
fn finding_codes_from_semantic_diff(semantic_diff : Json) -> Array[String] {
  let codes : Array[String] = []
  guard semantic_diff is Object(obj) else { return codes }
  guard obj.get("findings") is Some(Array(findings)) else { return codes }
  for finding in findings {
    guard finding is Object(finding_object) else { continue }
    match finding_object.get("code") {
      Some(String(code)) if code != "" => codes.push(code)
      _ => ()
    }
  }
  codes
}

///|
fn normalized_semantic_diff(semantic_diff : Json) -> Json {
  let normalized_findings : Array[Json] = []
  let existing_codes = finding_codes_from_semantic_diff(semantic_diff)
  for code in existing_codes {
    normalized_findings.push({ "code": code })
  }
  match semantic_diff {
    Object(obj) => {
      let out : Map[String, Json] = {}
      for key, value in obj {
        if key != "findings" {
          out[key] = value
        }
      }
      out["findings"] = Json::array(normalized_findings)
      Json::object(out)
    }
    _ => { "findings": Json::array(normalized_findings) }
  }
}

///|
fn primary_finding_code(semantic_diff : Json) -> String {
  let codes = finding_codes_from_semantic_diff(semantic_diff)
  match codes.get(0) {
    Some(code) => code
    None => ""
  }
}

///|
fn rules_from_policy_results(policy_results : Array[Json]) -> Array[Json] {
  let rules : Array[Json] = [@policy_rules.diff_driver_rule()]
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
      _ => @policy_rules.index_uri()
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
fn merge_sarif_rules(
  catalog_rules : Array[Json],
  policy_rules : Array[Json],
) -> Array[Json] {
  let merged : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<policy_rules.length() {
    guard policy_rules[i] is Object(rule_object) else { continue }
    guard rule_object.get("id") is Some(String(rule_id)) else { continue }
    if seen.contains(rule_id) {
      continue
    }
    merged.push(policy_rules[i])
    seen[rule_id] = true
  }
  for i in 0..<catalog_rules.length() {
    guard catalog_rules[i] is Object(rule_object) else { continue }
    guard rule_object.get("id") is Some(String(rule_id)) else { continue }
    if seen.contains(rule_id) {
      continue
    }
    merged.push(catalog_rules[i])
    seen[rule_id] = true
  }
  merged
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
///       "path": "...", "before": "...", "after": "...",
///       "semanticDiff": { "findings": [ { "code": "..." } ], ... }
///     }
///   ],
///   "componentChanges": [
///     {
///       "id": "...", "kind": "...", "level": "...",
///       "path": "...",
///       "componentDiff": { "upgradeKind": "..." },
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
        let normalized_diff = normalized_semantic_diff(semantic_diff)
        let before_record = match co.get("beforeRecord") {
          Some(v) => v
          None => Json::null()
        }
        let after_record = match co.get("afterRecord") {
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
            "path": path,
            "componentDiff": Json::object(cd),
            "semanticDiff": normalized_diff,
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
            "beforeRecord": before_record,
            "afterRecord": after_record,
          })
        } else {
          changes.push({
            "id": id,
            "kind": kind,
            "level": level,
            "path": path,
            "before": before,
            "after": after,
            "semanticDiff": normalized_diff,
            "beforeRecord": before_record,
            "afterRecord": after_record,
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
  policies_dir : String,
  diff_file : String,
  diff : Json,
) -> Result[Array[Json], @cli.CliError] {
  let eval_json_override = @sys.get_env_var("COGNA_OPA_EVAL_JSON")
  if eval_json_override is Some(text) {
    let parsed = try? @json.parse(text)
    guard parsed is Ok(value) else {
      return Err(check_error("invalid json in COGNA_OPA_EVAL_JSON"))
    }
    return Ok(policy_rules_from_opa_json(value))
  }

  // Write OPA-shaped input to a temp file for OPA eval
  let enriched = prepare_opa_input(diff)
  let temp_input = "\{diff_file}.opa-input.json"
  let write_out = write_temp_json(temp_input, enriched)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  let command = "opa eval --bundle \{shell_escape(policies_dir)} --input \{shell_escape(temp_input)} --format json data.cogna.compat.deny"
  let (exit_code, stdout, stderr) = @shell.run_command_capture(command)
  @fs.remove_file(temp_input) catch {
    _ => ()
  }
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
  guard diff is Object(diff_object) else {
    return Err(check_error("diff \{diff_path} must be a JSON object"))
  }
  guard diff_object.get("schemaVersion") is Some(String("ciq-diff/v1")) else {
    return Err(
      check_error("diff \{diff_path} missing schemaVersion ciq-diff/v1"),
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
    let semantic_diff = match change_object.get("semanticDiff") {
      Some(value) => value
      None => Json::null()
    }
    let finding_code = primary_finding_code(semantic_diff)

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
    let base_msg = if finding_code != "" {
      "Detected \{kind} change for \{path} (\{id}) [\{finding_code}]"
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
  policies_dir : String,
  policy_results : Array[Json],
) -> Json {
  let results = sarif_results_from_diff(diff)
  let from_policy = sarif_results_from_policy(policy_results)
  for i in 0..<from_policy.length() {
    results.push(from_policy[i])
  }

  let catalog_rules = {
    let rego_out = read_catalog_rego_text(policies_dir)
    match rego_out {
      Ok(text) =>
        match @policy_rules.from_rego_text(text) {
          Ok(rules) => {
            let catalog_text = @policy_rules.catalog_json(rules)
            let parsed = try? @json.parse(catalog_text)
            match parsed {
              Ok(catalog) => @policy_rules.sarif_rules_from_catalog(catalog)
              Err(_) => []
            }
          }
          Err(_) => []
        }
      Err(_) => []
    }
  }
  let driver_rules = merge_sarif_rules(
    catalog_rules,
    rules_from_policy_results(policy_results),
  )

  {
    "version": "2.1.0",
    "runs": [
      {
        "tool": { "driver": { "name": "cogna-check", "rules": driver_rules } },
        "invocation": {
          "executionSuccessful": true,
          "commandLine": "cogna check --policies \{policies_dir}",
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
  let (diff_file, policies_dir) = if params.diff_file == "" &&
    params.policies_dir == "" {
    let resolved_out = @config.resolve(".")
    guard resolved_out is Ok(resolved) else {
      return Err(@cli.config_error(resolved_out.unwrap_err().to_string()))
    }
    (
      "\{resolved.root_dir}/dist/diff.json",
      @config.resolve_project_path(
        resolved.root_dir,
        resolved.config.checks.policy,
      ),
    )
  } else {
    (params.diff_file, params.policies_dir)
  }
  if !@fs.path_exists(policies_dir) {
    return Err(check_error("missing policies directory: \{policies_dir}"))
  }

  let diff_out = read_json_file(diff_file, "diff")
  guard diff_out is Ok(diff) else { return Err(diff_out.unwrap_err()) }
  let diff_shape_out = ensure_diff_shape(diff, diff_file)
  guard diff_shape_out is Ok(_) else { return Err(diff_shape_out.unwrap_err()) }

  let policy_results_out = evaluate_policy_with_opa(
    policies_dir, diff_file, diff,
  )
  guard policy_results_out is Ok(policy_results) else {
    return Err(policy_results_out.unwrap_err())
  }

  let sarif_path = "\{parent_dir(diff_file)}/check.sarif.json"
  let sarif = sarif_from_diff(diff, policies_dir, policy_results)
  let write_out = write_sarif(sarif_path, sarif)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    diff_file,
    policies_dir,
    summary: "Generated SARIF report at \{sarif_path}",
  })
}
