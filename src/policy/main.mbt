///|
pub struct Rule {
  id : String
  family : String
  default_level : String
  summary : String
  docs : String
  entrypoint : String
  finding_code : String?
  component_upgrade_kind : String?
} derive(Eq)

///|
pub impl Show for Rule with output(self, logger) {
  logger.write_string("{id: ")
  logger.write_object(self.id)
  logger.write_string(", family: ")
  logger.write_object(self.family)
  logger.write_string(", default_level: ")
  logger.write_object(self.default_level)
  logger.write_string(", summary: ")
  logger.write_object(self.summary)
  logger.write_string(", docs: ")
  logger.write_object(self.docs)
  logger.write_string(", entrypoint: ")
  logger.write_object(self.entrypoint)
  logger.write_string(", finding_code: ")
  logger.write_object(self.finding_code)
  logger.write_string(", component_upgrade_kind: ")
  logger.write_object(self.component_upgrade_kind)
  logger.write_char('}')
}

///|
pub fn docs_host() -> String {
  "https://codeiq.xaclabs.dev"
}

///|
pub fn index_path() -> String {
  "/docs/policies"
}

///|
pub fn index_uri() -> String {
  "\{docs_host()}\{index_path()}"
}

///|
pub fn rule_slug(rule_id : String) -> String {
  let parts = rule_id.split(".").to_array()
  if parts.length() == 0 {
    rule_id.replace_all(old=".", new="-")
  } else {
    match parts.get(parts.length() - 1) {
      Some(value) if value != "" => value.to_string()
      _ => rule_id.replace_all(old=".", new="-")
    }
  }
}

///|
fn rule_path_from_parts(family : String, rule_id : String) -> String {
  "/docs/policies/generated/\{family}/\{rule_slug(rule_id)}"
}

///|
pub fn rule_path(rule : Rule) -> String {
  rule_path_from_parts(rule.family, rule.id)
}

///|
pub fn rule_uri(rule : Rule) -> String {
  "\{docs_host()}\{rule_path(rule)}"
}

///|
fn policy_catalog_error(message : String) -> @cli.CliError {
  @cli.command_error("policy catalog parse error: \{message}")
}

///|
fn builtin_rule(
  id : String,
  family : String,
  default_level : String,
  summary : String,
  entrypoint? : String = "data.codeiq.compat.deny",
  finding_code? : String,
  component_upgrade_kind? : String,
) -> Rule {
  {
    id,
    family,
    default_level,
    summary,
    docs: "\{docs_host()}\{rule_path_from_parts(family, id)}",
    entrypoint,
    finding_code,
    component_upgrade_kind,
  }
}

///|
fn custom_rule(
  id : String,
  family : String,
  default_level : String,
  summary : String,
  docs : String,
  entrypoint? : String = "data.codeiq.compat.deny",
  finding_code? : String,
  component_upgrade_kind? : String,
) -> Rule {
  {
    id,
    family,
    default_level,
    summary,
    docs,
    entrypoint,
    finding_code,
    component_upgrade_kind,
  }
}

///|
pub fn builtin_rules() -> Array[Rule] {
  [
    builtin_rule(
      "compat.core.removed-declaration",
      "core",
      "error",
      "Public declaration was removed and callers will break.",
      finding_code="removed-declaration",
    ),
    builtin_rule(
      "compat.core.new-declaration",
      "core",
      "note",
      "Public declaration was added.",
      finding_code="new-declaration",
    ),
    builtin_rule(
      "compat.core.deprecated-declaration",
      "core",
      "note",
      "Public declaration became deprecated.",
      finding_code="deprecated-declaration",
    ),
    builtin_rule(
      "compat.go.pointer-receiver-changed",
      "go",
      "error",
      "Go pointer receiver compatibility changed.",
      finding_code="go-pointer-receiver-changed",
    ),
    builtin_rule(
      "compat.go.receiver-changed",
      "go",
      "error",
      "Go receiver type changed.",
      finding_code="go-receiver-changed",
    ),
    builtin_rule(
      "compat.go.method-set-shrunk",
      "go",
      "error",
      "Go method set shrank.",
      finding_code="go-method-set-shrunk",
    ),
    builtin_rule(
      "compat.go.method-set-expanded",
      "go",
      "warning",
      "Go method set expanded and needs review.",
      finding_code="go-method-set-expanded",
    ),
    builtin_rule(
      "compat.go.signature-changed",
      "go",
      "warning",
      "Go public signature changed.",
      finding_code="go-signature-changed",
    ),
    builtin_rule(
      "compat.rust.became-unsafe",
      "rust",
      "error",
      "Rust public item became unsafe.",
      finding_code="rust-became-unsafe",
    ),
    builtin_rule(
      "compat.rust.extern-abi-added",
      "rust",
      "error",
      "Rust extern ABI was added.",
      finding_code="rust-extern-abi-added",
    ),
    builtin_rule(
      "compat.rust.extern-abi-changed",
      "rust",
      "error",
      "Rust extern ABI changed.",
      finding_code="rust-extern-abi-changed",
    ),
    builtin_rule(
      "compat.rust.where-clause-changed",
      "rust",
      "warning",
      "Rust where-clause changed.",
      finding_code="rust-where-clause-changed",
    ),
    builtin_rule(
      "compat.rust.signature-changed",
      "rust",
      "warning",
      "Rust public signature changed.",
      finding_code="rust-signature-changed",
    ),
    builtin_rule(
      "compat.terraform.provider-ref-changed",
      "terraform",
      "error",
      "Terraform provider reference changed.",
      finding_code="terraform-provider-ref-changed",
    ),
    builtin_rule(
      "compat.terraform.prevent-destroy-added",
      "terraform",
      "warning",
      "Terraform prevent_destroy was added.",
      finding_code="terraform-prevent-destroy-added",
    ),
    builtin_rule(
      "compat.terraform.create-before-destroy-added",
      "terraform",
      "warning",
      "Terraform create_before_destroy was added.",
      finding_code="terraform-create-before-destroy-added",
    ),
    builtin_rule(
      "compat.terraform.ignore-changes-expanded",
      "terraform",
      "note",
      "Terraform ignore_changes expanded.",
      finding_code="terraform-ignore-changes-expanded",
    ),
    builtin_rule(
      "compat.terraform.lifecycle-changed",
      "terraform",
      "warning",
      "Terraform lifecycle metadata changed.",
      finding_code="terraform-lifecycle-changed",
    ),
    builtin_rule(
      "compat.terraform.input-became-required",
      "terraform",
      "error",
      "Terraform input became required and callers must update configuration.",
      finding_code="terraform-input-became-required",
    ),
    builtin_rule(
      "compat.terraform.output-removed",
      "terraform",
      "error",
      "Terraform output was removed and downstream references can break.",
      finding_code="terraform-output-removed",
    ),
    builtin_rule(
      "compat.openapi.http-method-changed",
      "openapi",
      "error",
      "OpenAPI HTTP method changed.",
      finding_code="openapi-http-method-changed",
    ),
    builtin_rule(
      "compat.openapi.became-required",
      "openapi",
      "error",
      "OpenAPI field or parameter became required.",
      finding_code="openapi-became-required",
    ),
    builtin_rule(
      "compat.openapi.status-codes-added",
      "openapi",
      "warning",
      "OpenAPI status codes were added.",
      finding_code="openapi-status-codes-added",
    ),
    builtin_rule(
      "compat.openapi.media-types-added",
      "openapi",
      "note",
      "OpenAPI media types were added.",
      finding_code="openapi-media-types-added",
    ),
    builtin_rule(
      "compat.openapi.operation-changed",
      "openapi",
      "warning",
      "OpenAPI operation changed.",
      finding_code="openapi-operation-changed",
    ),
    builtin_rule(
      "compat.openapi.response-status-removed",
      "openapi",
      "error",
      "OpenAPI response status code was removed.",
      finding_code="openapi-response-status-removed",
    ),
    builtin_rule(
      "compat.openapi.response-schema-narrowed",
      "openapi",
      "error",
      "OpenAPI response schema narrowed and clients may fail to parse it.",
      finding_code="openapi-response-schema-narrowed",
    ),
    builtin_rule(
      "compat.component.version-upgrade",
      "component",
      "warning",
      "Software component version changed.",
      component_upgrade_kind="version-upgrade",
    ),
    builtin_rule(
      "compat.component.metadata-changed",
      "component",
      "warning",
      "Software component metadata changed.",
      component_upgrade_kind="metadata-change",
    ),
  ]
}

///|
pub fn catalog_rule_to_json(rule : Rule) -> Json {
  {
    "id": rule.id,
    "family": rule.family,
    "defaultLevel": rule.default_level,
    "summary": rule.summary,
    "docs": rule.docs,
    "entrypoint": rule.entrypoint,
  }
}

///|
pub fn catalog_json(rules : Array[Rule]) -> String {
  let catalog_rules = rules.map(rule => catalog_rule_to_json(rule))
  (
    {
      "schemaVersion": "codeiq-policy-rules/v1",
      "rules": Json::array(catalog_rules),
    } : Json).stringify(indent=2)
}

///|
fn render_rego_rule(rule : Rule) -> String {
  let source = if rule.family == "component" {
    "input.componentChanges[_]"
  } else {
    "input.changes[_]"
  }
  let predicate = match rule.finding_code {
    Some(code) => "has_finding(change, \"\{code}\")"
    None =>
      match rule.component_upgrade_kind {
        Some(kind) => "component_upgrade(change, \"\{kind}\")"
        None => "false"
      }
  }
  (
    $|deny contains out if {
    $|  change := \{source}
    $|  \{predicate}
    $|  out := {
    $|    "rule_id": "\{rule.id}",
    $|    "level": "\{rule.default_level}",
    $|    "message": "\{rule.summary}",
    $|    "path": change.path,
    $|    "docs": "\{rule.docs}"
    $|  }
    $|}
  )
}

///|
pub fn builtin_rego() -> String {
  let header =
    #|package codeiq.compat
    #|
    #|default deny = []
    #|
    #|has_finding(change, code) if {
    #|  some finding in change.semanticDiff.findings
    #|  finding.code == code
    #|}
    #|
    #|component_upgrade(change, kind) if {
    #|  change.componentDiff.upgradeKind == kind
    #|}
    #|
  header + builtin_rules().map(rule => render_rego_rule(rule)).join("\n")
}

///|
fn extract_quoted_json_value(fragment : String) -> String? {
  let trimmed = fragment.trim().to_string()
  if !trimmed.has_prefix("\"") {
    return None
  }
  let rest = trimmed[1:].to_string()
  match rest.find("\"") {
    Some(index) => Some(rest[:index].to_string())
    None => None
  }
}

///|
fn extract_json_field(line : String, field : String) -> String? {
  let marker = "\"\{field}\":"
  match line.find(marker) {
    Some(index) =>
      extract_quoted_json_value(line[index + marker.length():].to_string())
    None => None
  }
}

///|
fn rule_family_from_id(rule_id : String) -> String {
  let parts = rule_id.split(".").to_array()
  match parts.get(1) {
    Some(value) if value != "" => value.to_string()
    _ => "custom"
  }
}

///|
fn require_catalog_field(
  rule_id : String,
  field_name : String,
  value : String?,
) -> Result[String, @cli.CliError] {
  match value {
    Some(text) if text != "" => Ok(text)
    _ => Err(policy_catalog_error("rule \{rule_id} missing literal \{field_name} metadata"))
  }
}

///|
fn valid_catalog_level(level : String) -> Bool {
  level == "error" || level == "warning" || level == "note"
}

///|
fn push_rule_if_present(
  rules : Array[Rule],
  seen_rule_ids : Map[String, Bool],
  current_id : String?,
  current_level : String?,
  current_message : String?,
  current_docs : String?,
) -> Result[Unit, @cli.CliError] {
  guard current_id is Some(rule_id) else { return Ok(()) }
  if seen_rule_ids.contains(rule_id) {
    return Err(policy_catalog_error("duplicate rule_id \{rule_id}"))
  }
  let level_out = require_catalog_field(rule_id, "level", current_level)
  guard level_out is Ok(level) else { return Err(level_out.unwrap_err()) }
  if !valid_catalog_level(level) {
    return Err(policy_catalog_error("rule \{rule_id} has unsupported level \{level}"))
  }
  let summary_out = require_catalog_field(rule_id, "message", current_message)
  guard summary_out is Ok(summary) else { return Err(summary_out.unwrap_err()) }
  let docs_out = require_catalog_field(rule_id, "docs", current_docs)
  guard docs_out is Ok(docs) else { return Err(docs_out.unwrap_err()) }
  rules.push(custom_rule(rule_id, rule_family_from_id(rule_id), level, summary, docs))
  seen_rule_ids[rule_id] = true
  Ok(())
}

///|
pub fn from_rego_text(policy_text : String) -> Result[Array[Rule], @cli.CliError] {
  let rules : Array[Rule] = []
  let seen_rule_ids : Map[String, Bool] = {}
  let mut current_id : String? = None
  let mut current_level : String? = None
  let mut current_message : String? = None
  let mut current_docs : String? = None
  for raw_line in policy_text.split("\n") {
    let line = raw_line.to_string()
    match extract_json_field(line, "rule_id") {
      Some(rule_id) => {
        let push_out = push_rule_if_present(
          rules,
          seen_rule_ids,
          current_id,
          current_level,
          current_message,
          current_docs,
        )
        guard push_out is Ok(_) else { return Err(push_out.unwrap_err()) }
        current_id = Some(rule_id)
        current_level = None
        current_message = None
        current_docs = None
      }
      None => ()
    }
    match extract_json_field(line, "level") {
      Some(value) => current_level = Some(value)
      None => ()
    }
    match extract_json_field(line, "message") {
      Some(value) => current_message = Some(value)
      None => ()
    }
    match extract_json_field(line, "docs") {
      Some(value) => current_docs = Some(value)
      None => ()
    }
  }
  let push_out = push_rule_if_present(
    rules,
    seen_rule_ids,
    current_id,
    current_level,
    current_message,
    current_docs,
  )
  guard push_out is Ok(_) else { return Err(push_out.unwrap_err()) }
  if rules.is_empty() {
    return Err(policy_catalog_error("no rules extracted from repository .rego files"))
  }
  Ok(rules)
}

///|
pub fn diff_driver_rule() -> Json {
  {
    "id": "compat.changed",
    "shortDescription": {
      "text": "Compatibility change requires policy review",
    },
    "fullDescription": {
      "text": "Maps declaration-level compatibility diff entries to SARIF diagnostics.",
    },
    "helpUri": index_uri(),
    "properties": { "source": "codeiq-diff", "category": "compatibility" },
  }
}

///|
pub fn sarif_rules_from_catalog(catalog : Json) -> Array[Json] {
  let rules : Array[Json] = []
  guard catalog is Object(root) else { return rules }
  guard root.get("rules") is Some(Array(items)) else { return rules }
  for item in items {
    guard item is Object(rule_object) else { continue }
    guard rule_object.get("id") is Some(String(rule_id)) else { continue }
    let summary = match rule_object.get("summary") {
      Some(String(text)) if text != "" => text
      _ => "Policy rule triggered"
    }
    let docs = match rule_object.get("docs") {
      Some(String(value)) if value != "" => value
      _ => index_uri()
    }
    rules.push({
      "id": rule_id,
      "shortDescription": { "text": summary },
      "fullDescription": {
        "text": "Built-in or generated policy catalog rule shipped with the CIQ policy bundle.",
      },
      "helpUri": docs,
      "properties": { "source": "policy-catalog", "category": "policy" },
    })
  }
  rules
}
