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
  "https://cogna.xaclabs.dev"
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
  ignore(family)
  let anchor = rule_id.replace_all(old=".", new="-")
  "/docs/policies#rule-\{anchor}"
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
fn custom_rule(
  id : String,
  family : String,
  default_level : String,
  summary : String,
  docs : String,
  entrypoint? : String = "data.cogna.compat.deny",
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
      "schemaVersion": "cogna-policy-rules/v1",
      "rules": Json::array(catalog_rules),
    } : Json).stringify(indent=2)
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
    _ =>
      Err(
        policy_catalog_error(
          "rule \{rule_id} missing literal \{field_name} metadata",
        ),
      )
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
    return Err(
      policy_catalog_error("rule \{rule_id} has unsupported level \{level}"),
    )
  }
  let summary_out = require_catalog_field(rule_id, "message", current_message)
  guard summary_out is Ok(summary) else { return Err(summary_out.unwrap_err()) }
  let docs_out = require_catalog_field(rule_id, "docs", current_docs)
  guard docs_out is Ok(docs) else { return Err(docs_out.unwrap_err()) }
  rules.push(
    custom_rule(rule_id, rule_family_from_id(rule_id), level, summary, docs),
  )
  seen_rule_ids[rule_id] = true
  Ok(())
}

///|
pub fn from_rego_text(
  policy_text : String,
) -> Result[Array[Rule], @cli.CliError] {
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
          rules, seen_rule_ids, current_id, current_level, current_message, current_docs,
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
    rules, seen_rule_ids, current_id, current_level, current_message, current_docs,
  )
  guard push_out is Ok(_) else { return Err(push_out.unwrap_err()) }
  if rules.is_empty() {
    return Err(
      policy_catalog_error("no rules extracted from repository .rego files"),
    )
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
    "properties": { "source": "cogna-diff", "category": "compatibility" },
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

///|
pub fn builtin_rego_text() -> String {
  #|package cogna.compat
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
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "removed-declaration")
  #|  out := {
  #|    "rule_id": "compat.core.removed-declaration",
  #|    "level": "error",
  #|    "message": "Public declaration was removed and callers will break.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-core-removed-declaration"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "new-declaration")
  #|  out := {
  #|    "rule_id": "compat.core.new-declaration",
  #|    "level": "note",
  #|    "message": "Public declaration was added.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-core-new-declaration"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "deprecated-declaration")
  #|  out := {
  #|    "rule_id": "compat.core.deprecated-declaration",
  #|    "level": "note",
  #|    "message": "Public declaration became deprecated.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-core-deprecated-declaration"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "go-pointer-receiver-changed")
  #|  out := {
  #|    "rule_id": "compat.go.pointer-receiver-changed",
  #|    "level": "error",
  #|    "message": "Go pointer receiver compatibility changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-pointer-receiver-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "go-receiver-changed")
  #|  out := {
  #|    "rule_id": "compat.go.receiver-changed",
  #|    "level": "error",
  #|    "message": "Go receiver type changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-receiver-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "go-method-set-shrunk")
  #|  out := {
  #|    "rule_id": "compat.go.method-set-shrunk",
  #|    "level": "error",
  #|    "message": "Go method set shrank.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-method-set-shrunk"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "go-method-set-expanded")
  #|  out := {
  #|    "rule_id": "compat.go.method-set-expanded",
  #|    "level": "warning",
  #|    "message": "Go method set expanded and needs review.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-method-set-expanded"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "go-signature-changed")
  #|  out := {
  #|    "rule_id": "compat.go.signature-changed",
  #|    "level": "warning",
  #|    "message": "Go public signature changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-go-signature-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "rust-became-unsafe")
  #|  out := {
  #|    "rule_id": "compat.rust.became-unsafe",
  #|    "level": "error",
  #|    "message": "Rust public item became unsafe.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-became-unsafe"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "rust-extern-abi-added")
  #|  out := {
  #|    "rule_id": "compat.rust.extern-abi-added",
  #|    "level": "error",
  #|    "message": "Rust extern ABI was added.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-extern-abi-added"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "rust-extern-abi-changed")
  #|  out := {
  #|    "rule_id": "compat.rust.extern-abi-changed",
  #|    "level": "error",
  #|    "message": "Rust extern ABI changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-extern-abi-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "rust-where-clause-changed")
  #|  out := {
  #|    "rule_id": "compat.rust.where-clause-changed",
  #|    "level": "warning",
  #|    "message": "Rust where-clause changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-where-clause-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "rust-signature-changed")
  #|  out := {
  #|    "rule_id": "compat.rust.signature-changed",
  #|    "level": "warning",
  #|    "message": "Rust public signature changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-signature-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "terraform-provider-ref-changed")
  #|  out := {
  #|    "rule_id": "compat.terraform.provider-ref-changed",
  #|    "level": "error",
  #|    "message": "Terraform provider reference changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-provider-ref-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "terraform-prevent-destroy-added")
  #|  out := {
  #|    "rule_id": "compat.terraform.prevent-destroy-added",
  #|    "level": "warning",
  #|    "message": "Terraform prevent_destroy was added.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-prevent-destroy-added"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "terraform-create-before-destroy-added")
  #|  out := {
  #|    "rule_id": "compat.terraform.create-before-destroy-added",
  #|    "level": "warning",
  #|    "message": "Terraform create_before_destroy was added.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-create-before-destroy-added"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "terraform-ignore-changes-expanded")
  #|  out := {
  #|    "rule_id": "compat.terraform.ignore-changes-expanded",
  #|    "level": "note",
  #|    "message": "Terraform ignore_changes expanded.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-ignore-changes-expanded"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "terraform-lifecycle-changed")
  #|  out := {
  #|    "rule_id": "compat.terraform.lifecycle-changed",
  #|    "level": "warning",
  #|    "message": "Terraform lifecycle metadata changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-lifecycle-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "terraform-input-became-required")
  #|  out := {
  #|    "rule_id": "compat.terraform.input-became-required",
  #|    "level": "error",
  #|    "message": "Terraform input became required and callers must update configuration.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-input-became-required"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "terraform-output-removed")
  #|  out := {
  #|    "rule_id": "compat.terraform.output-removed",
  #|    "level": "error",
  #|    "message": "Terraform output was removed and downstream references can break.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-output-removed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "openapi-http-method-changed")
  #|  out := {
  #|    "rule_id": "compat.openapi.http-method-changed",
  #|    "level": "error",
  #|    "message": "OpenAPI HTTP method changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-http-method-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "openapi-became-required")
  #|  out := {
  #|    "rule_id": "compat.openapi.became-required",
  #|    "level": "error",
  #|    "message": "OpenAPI field or parameter became required.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-became-required"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "openapi-status-codes-added")
  #|  out := {
  #|    "rule_id": "compat.openapi.status-codes-added",
  #|    "level": "warning",
  #|    "message": "OpenAPI status codes were added.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-status-codes-added"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "openapi-media-types-added")
  #|  out := {
  #|    "rule_id": "compat.openapi.media-types-added",
  #|    "level": "note",
  #|    "message": "OpenAPI media types were added.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-media-types-added"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "openapi-operation-changed")
  #|  out := {
  #|    "rule_id": "compat.openapi.operation-changed",
  #|    "level": "warning",
  #|    "message": "OpenAPI operation changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-operation-changed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "openapi-response-status-removed")
  #|  out := {
  #|    "rule_id": "compat.openapi.response-status-removed",
  #|    "level": "error",
  #|    "message": "OpenAPI response status code was removed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-response-status-removed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.changes[_]
  #|  has_finding(change, "openapi-response-schema-narrowed")
  #|  out := {
  #|    "rule_id": "compat.openapi.response-schema-narrowed",
  #|    "level": "error",
  #|    "message": "OpenAPI response schema narrowed and clients may fail to parse it.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-response-schema-narrowed"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.componentChanges[_]
  #|  component_upgrade(change, "version-upgrade")
  #|  out := {
  #|    "rule_id": "compat.component.version-upgrade",
  #|    "level": "warning",
  #|    "message": "Software component version changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-component-version-upgrade"
  #|  }
  #|}
  #|
  #|deny contains out if {
  #|  change := input.componentChanges[_]
  #|  component_upgrade(change, "metadata-change")
  #|  out := {
  #|    "rule_id": "compat.component.metadata-changed",
  #|    "level": "warning",
  #|    "message": "Software component metadata changed.",
  #|    "path": change.path,
  #|    "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-component-metadata-changed"
  #|  }
  #|}
}
