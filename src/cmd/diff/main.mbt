///|
pub(all) struct DiffParams {
  repo : String
  since : String?
  include_test_changes : Bool
} derive(Show, Eq)

///|
pub(all) struct DiffResult {
  repo : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for DiffResult with display(self : DiffResult) -> String {
  self.summary
}

///|
fn diff_error(message : String) -> @cli.CliError {
  @cli.command_error("diff failed: \{message}")
}

///|
fn read_manifest(path : String) -> Result[Json, @cli.CliError] {
  let text = @fs.read_file_to_string(path) catch {
    err =>
      return Err(diff_error("cannot read manifest \{path}: \{err.to_string()}"))
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err(diff_error("invalid manifest json in \\{path}"))
  }
  Ok(value)
}

///|
fn decode_utf8(bytes : Bytes, path : String) -> Result[String, @cli.CliError] {
  let text = @utf8.decode(bytes) catch {
    _ => return Err(diff_error("invalid utf-8 bytes in \{path}"))
  }
  Ok(text)
}

///|
fn read_ndjson(path : String) -> Result[Array[Json], @cli.CliError] {
  let file_bytes = @fs.read_file_to_bytes(path) catch {
    _ => return Err(diff_error("cannot read ndjson \{path}"))
  }
  let text_out = decode_utf8(file_bytes, path)
  guard text_out is Ok(text) else { return Err(text_out.unwrap_err()) }
  if text == "" {
    return Ok([])
  }

  let lines = text.split("\n").to_array()
  let records : Array[Json] = []
  for i in 0..<lines.length() {
    let line = lines[i].to_string().trim().to_string()
    if line == "" {
      continue
    }
    let parsed = try? @json.parse(line)
    guard parsed is Ok(value) else {
      return Err(diff_error("invalid ndjson line in \{path} at \{i + 1}"))
    }
    records.push(value)
  }
  Ok(records)
}

///|
fn validate_manifest_shape(
  manifest : Json,
  path : String,
) -> Result[Unit, @cli.CliError] {
  let out = @schema.validate_ciq_bundle_v1(manifest)
  guard out is Ok(_) else {
    return Err(
      diff_error(
        "manifest \{path} does not satisfy ciq-bundle/v1 schema: \{out.unwrap_err().to_string()}",
      ),
    )
  }
  Ok(())
}

///|
fn get_field_string(
  manifest : Json,
  field_name : String,
  path : String,
) -> Result[String, @cli.CliError] {
  guard manifest is Object(object) else {
    return Err(diff_error("manifest \{path} must be a JSON object"))
  }
  guard object.get(field_name) is Some(String(value)) else {
    return Err(
      diff_error("manifest \{path} missing string field \{field_name}"),
    )
  }
  Ok(value)
}

///|
fn record_string(record : Json, field : String) -> String? {
  guard record is Object(object) else { return None }
  match object.get(field) {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
}

///|
fn record_bool(record : Json, field : String) -> Bool {
  guard record is Object(object) else { return false }
  match object.get(field) {
    Some(True) => true
    _ => false
  }
}

///|
fn artifact_records(root : String) -> Result[Array[Json], @cli.CliError] {
  let decl_path_plain = "\{root}/declarations.ndjson"
  let decl_out = if @fs.path_exists(decl_path_plain) {
    read_ndjson(decl_path_plain)
  } else {
    Err(diff_error("cannot read ndjson \{decl_path_plain}"))
  }
  guard decl_out is Ok(declarations) else { return Err(decl_out.unwrap_err()) }

  let symbol_path_plain = "\{root}/symbols.ndjson"
  let symbol_out = if @fs.path_exists(symbol_path_plain) {
    read_ndjson(symbol_path_plain)
  } else {
    Err(diff_error("cannot read ndjson \{symbol_path_plain}"))
  }
  guard symbol_out is Ok(symbols) else { return Err(symbol_out.unwrap_err()) }

  let component_path_plain = "\{root}/software-components.ndjson"
  let component_out = if @fs.path_exists(component_path_plain) {
    read_ndjson(component_path_plain)
  } else {
    Ok([])
  }
  guard component_out is Ok(components) else {
    return Err(component_out.unwrap_err())
  }

  let records : Array[Json] = []
  for i in 0..<declarations.length() {
    records.push(declarations[i])
  }
  for i in 0..<symbols.length() {
    records.push(symbols[i])
  }
  for i in 0..<components.length() {
    records.push(components[i])
  }
  Ok(records)
}

///|
fn record_index(records : Array[Json]) -> Map[String, Json] {
  let index : Map[String, Json] = {}
  for i in 0..<records.length() {
    let key = record_match_key(records[i])
    guard key != "" else { continue }
    index[key] = records[i]
  }
  index
}

///|
fn record_path(record : Json) -> String {
  match record_string(record, "path") {
    Some(value) => value
    None => "unknown"
  }
}

///|
fn record_location(record : Json, path_fallback : String) -> Json {
  guard record is Object(object) else {
    return { "uri": path_fallback, "startLine": 1, "endLine": 1 }
  }
  match object.get("location") {
    Some(Object(location_object)) => {
      let uri = match location_object.get("uri") {
        Some(String(value)) if value != "" => value
        _ => path_fallback
      }
      let start_line = match location_object.get("startLine") {
        Some(Number(value, ..)) => value.to_int()
        _ => 1
      }
      let end_line = match location_object.get("endLine") {
        Some(Number(value, ..)) => value.to_int()
        _ => start_line
      }
      { "uri": uri, "startLine": start_line, "endLine": end_line }
    }
    _ => { "uri": path_fallback, "startLine": 1, "endLine": 1 }
  }
}

///|
fn location_key(record : Json) -> String {
  let fallback = record_path(record)
  let location = record_location(record, fallback)
  guard location is Object(location_object) else { return fallback }
  let uri = match location_object.get("uri") {
    Some(String(value)) if value != "" => value
    _ => fallback
  }
  let start_line = match location_object.get("startLine") {
    Some(Number(value, ..)) => value.to_int()
    _ => 1
  }
  let end_line = match location_object.get("endLine") {
    Some(Number(value, ..)) => value.to_int()
    _ => start_line
  }
  "\{uri}:\{start_line}:\{end_line}"
}

///|
fn record_language(record : Json) -> String {
  match record_string(record, "language") {
    Some(value) if value != "" => value
    _ => {
      let path = record_path(record)
      if path.has_suffix(".go") {
        "go"
      } else if path.has_suffix(".rs") {
        "rust"
      } else {
        let id = record_string(record, "id").unwrap_or("")
        if id.contains("go-module") {
          "go"
        } else if id.contains("rust-crate") {
          "rust"
        } else {
          "unknown"
        }
      }
    }
  }
}

///|
fn is_go_test_name(name : String) -> Bool {
  name.has_prefix("Test") ||
  name.has_prefix("Benchmark") ||
  name.has_prefix("Fuzz") ||
  name.has_prefix("Example")
}

///|
fn is_go_test_signature(signature : String) -> Bool {
  signature.has_prefix("func Test") ||
  signature.has_prefix("func Benchmark") ||
  signature.has_prefix("func Fuzz") ||
  signature.has_prefix("func Example")
}

///|
fn is_rust_test_signature(signature : String) -> Bool {
  signature.contains("#[test]") || signature.contains("# [test]")
}

///|
fn is_rust_test_name(name : String) -> Bool {
  name.has_prefix("test_") || name.has_suffix("_test")
}

///|
fn is_test_record(record : Json) -> Bool {
  let id = record_string(record, "id").unwrap_or("")
  if !id.has_prefix("decl:") {
    return false
  }
  let path = record_path(record)
  let signature = record_string(record, "signature").unwrap_or("")
  let name = record_string(record, "name").unwrap_or("")
  match record_language(record) {
    "go" =>
      path.has_suffix("_test.go") ||
      is_go_test_signature(signature) ||
      is_go_test_name(name)
    "rust" =>
      path.has_prefix("tests/") ||
      path.contains("/tests/") ||
      path.has_suffix("_test.rs") ||
      is_rust_test_signature(signature) ||
      is_rust_test_name(name)
    _ => false
  }
}

///|
fn test_change_id(record : Json) -> String {
  let id = record_string(record, "id").unwrap_or("")
  if id.has_prefix("decl:") {
    "test:\{id[5:].to_string()}"
  } else if id.has_prefix("sym:") {
    "test:\{id[4:].to_string()}"
  } else {
    "test:\{id}"
  }
}

///|
fn test_change_path(record : Json) -> String {
  match record_string(record, "canonical_name") {
    Some(value) => value
    None => record_path(record)
  }
}

///|
fn test_change_record(kind : String, record : Json) -> Json {
  let fallback = record_path(record)
  {
    "kind": kind,
    "language": record_language(record),
    "id": test_change_id(record),
    "path": test_change_path(record),
    "signature": record_string(record, "signature").unwrap_or("unknown"),
    "location": record_location(record, fallback),
  }
}

///|
fn test_change_sort_key(change : Json) -> String {
  guard change is Object(change_object) else { return "" }
  match change_object.get("id") {
    Some(String(id)) => id
    _ => ""
  }
}

///|
fn test_record_index(records : Array[Json]) -> Map[String, Json] {
  let index : Map[String, Json] = {}
  for i in 0..<records.length() {
    let record = records[i]
    if !is_test_record(record) {
      continue
    }
    let key = test_change_id(record)
    if key != "" && key != "test:" {
      index[key] = record
    }
  }
  index
}

///|
fn has_test_change(base : Json, target : Json) -> Bool {
  if has_shape_change(base, target) {
    return true
  }
  location_key(base) != location_key(target)
}

///|
fn test_changes(
  base_records : Array[Json],
  target_records : Array[Json],
) -> Array[Json] {
  let changes : Array[Json] = []
  let base_index = test_record_index(base_records)
  let target_index = test_record_index(target_records)

  for id, target in target_index {
    match base_index.get(id) {
      Some(base) =>
        if has_test_change(base, target) {
          changes.push(test_change_record("modified", target))
        }
      None => changes.push(test_change_record("added", target))
    }
  }

  for id, base in base_index {
    if !target_index.contains(id) {
      changes.push(test_change_record("removed", base))
    }
  }

  changes.sort_by((a, b) => {
    test_change_sort_key(a).compare(test_change_sort_key(b))
  })
  changes
}

///|
fn has_shape_change(base : Json, target : Json) -> Bool {
  guard base is Object(base_object) else { return base != target }
  guard target is Object(target_object) else { return true }
  if base_object.get("shape") != target_object.get("shape") {
    return true
  }
  if base_object.get("language_specific") != target_object.get("language_specific") {
    return true
  }
  let base_signature = record_string(base, "signature")
  let target_signature = record_string(target, "signature")
  if base_signature != target_signature {
    return true
  }
  let base_kind = record_string(base, "kind")
  let target_kind = record_string(target, "kind")
  if base_kind != target_kind {
    return true
  }
  let base_path = record_string(base, "path")
  let target_path = record_string(target, "path")
  base_path != target_path
}

///|
fn change_record_payload(record : Json) -> Json {
  record
}

///|
fn component_identity_name(record : Json) -> String {
  match record_string(record, "name") {
    Some(value) if value != "" => value
    _ => {
      let candidate = match record_string(record, "purl") {
        Some(value) if value != "" => value
        _ => record_string(record, "id").unwrap_or("unknown-component")
      }
      match candidate.find("@") {
        Some(index) if candidate.has_prefix("pkg:") => candidate[:index].to_string()
        _ => candidate
      }
    }
  }
}

///|
fn record_match_key(record : Json) -> String {
  if is_component_record(record) {
    let path = record_path(record)
    let component_type = record_string(record, "componentType").unwrap_or(
      "component",
    )
    let scope = record_string(record, "scope").unwrap_or("unknown")
    let name = component_identity_name(record)
    "component:\{path}:\{component_type}:\{scope}:\{name}"
  } else {
    record_string(record, "id").unwrap_or("")
  }
}

///|
fn json_object_get(obj : Json, key : String) -> Json? {
  guard obj is Object(m) else { return None }
  m.get(key)
}

///|
fn semantic_diff(base : Json, target : Json) -> Json {
  let changed_fields : Array[Json] = []

  // signature change
  let base_sig = record_string(base, "signature")
  let target_sig = record_string(target, "signature")
  if base_sig != target_sig {
    changed_fields.push(Json::string("signature"))
  }

  // kind change
  let base_kind = record_string(base, "kind")
  let target_kind = record_string(target, "kind")
  if base_kind != target_kind {
    changed_fields.push(Json::string("kind"))
  }

  // path/move change
  let base_path = record_string(base, "path")
  let target_path = record_string(target, "path")
  if base_path != target_path {
    changed_fields.push(Json::string("path"))
  }

  // shape change
  let base_shape = json_object_get(base, "shape")
  let target_shape = json_object_get(target, "shape")
  if base_shape != target_shape {
    changed_fields.push(Json::string("shape"))
  }

  // language_specific change
  let base_ls = json_object_get(base, "language_specific")
  let target_ls = json_object_get(target, "language_specific")
  if base_ls != target_ls {
    changed_fields.push(Json::string("language_specific"))
  }

  let result : Map[String, Json] = { "changedFields": Json::array(changed_fields) }

  // include shape before/after when changed
  if base_shape != target_shape {
    result["shapeDiff"] = {
      "before": match base_shape {
        Some(v) => v
        None => Json::null()
      },
      "after": match target_shape {
        Some(v) => v
        None => Json::null()
      },
    }
  }

  // include language_specific before/after when changed
  if base_ls != target_ls {
    result["languageSpecificDiff"] = {
      "before": match base_ls {
        Some(v) => v
        None => Json::null()
      },
      "after": match target_ls {
        Some(v) => v
        None => Json::null()
      },
    }
  }

  Json::object(result)
}

///|
fn is_component_record(record : Json) -> Bool {
  match record_string(record, "kind") {
    Some("component") => true
    _ => false
  }
}

///|
fn component_diff(base : Json, target : Json) -> Json {
  let changed_fields : Array[Json] = []

  // version change
  let base_version = record_string(base, "version")
  let target_version = record_string(target, "version")
  if base_version != target_version {
    changed_fields.push(Json::string("version"))
  }

  // purl change (covers version + name change)
  let base_purl = record_string(base, "purl")
  let target_purl = record_string(target, "purl")
  if base_purl != target_purl {
    changed_fields.push(Json::string("purl"))
  }

  // componentType change
  let base_type = record_string(base, "componentType")
  let target_type = record_string(target, "componentType")
  if base_type != target_type {
    changed_fields.push(Json::string("componentType"))
  }

  // scope change
  let base_scope = record_string(base, "scope")
  let target_scope = record_string(target, "scope")
  if base_scope != target_scope {
    changed_fields.push(Json::string("scope"))
  }

  // determine upgrade kind
  let upgrade_kind = if base_version != target_version {
    "version-upgrade"
  } else if base_purl != target_purl {
    "purl-change"
  } else {
    "metadata-change"
  }

  {
    "changedFields": Json::array(changed_fields),
    "upgradeKind": upgrade_kind,
    "beforeVersion": match base_version {
      Some(v) => Json::string(v)
      None => Json::null()
    },
    "afterVersion": match target_version {
      Some(v) => Json::string(v)
      None => Json::null()
    },
    "beforePurl": match base_purl {
      Some(v) => Json::string(v)
      None => Json::null()
    },
    "afterPurl": match target_purl {
      Some(v) => Json::string(v)
      None => Json::null()
    },
  }
}

///|
fn json_bool_val(obj : Json, key : String) -> Bool {
  guard obj is Object(m) else { return false }
  match m.get(key) {
    Some(True) => true
    _ => false
  }
}

///|
fn json_array_len(obj : Json, key : String) -> Int {
  guard obj is Object(m) else { return 0 }
  match m.get(key) {
    Some(Array(arr)) => arr.length()
    _ => 0
  }
}

///|
fn get_lang_specific(record : Json, lang : String) -> Json {
  guard record is Object(m) else { return Json::null() }
  match m.get("language_specific") {
    Some(Object(ls)) =>
      match ls.get(lang) {
        Some(v) => v
        None => Json::null()
      }
    _ => Json::null()
  }
}

///|
fn go_method_set_len(go_obj : Json) -> Int {
  guard go_obj is Object(m) else { return 0 }
  match m.get("methodSetTypes") {
    Some(Array(arr)) => arr.length()
    _ => 0
  }
}

///|
fn classify_rust_change(base : Json, target : Json) -> (String, String) {
  let base_rust = get_lang_specific(base, "rust")
  let target_rust = get_lang_specific(target, "rust")
  let base_unsafe = json_bool_val(base_rust, "unsafe")
  let target_unsafe = json_bool_val(target_rust, "unsafe")
  if !base_unsafe && target_unsafe {
    return ("breaking", "rust-became-unsafe")
  }
  let base_abi = record_string(base_rust, "externAbi")
  let target_abi = record_string(target_rust, "externAbi")
  if base_abi is None && target_abi is Some(_) {
    return ("breaking", "rust-extern-abi-added")
  }
  if base_abi != target_abi && target_abi is Some(_) {
    return ("breaking", "rust-extern-abi-changed")
  }
  let base_where = record_string(base_rust, "whereClause")
  let target_where = record_string(target_rust, "whereClause")
  if base_where != target_where {
    return ("warning", "rust-where-clause-changed")
  }
  ("warning", "rust-signature-changed")
}

///|
fn classify_go_change(base : Json, target : Json) -> (String, String) {
  let base_go = get_lang_specific(base, "go")
  let target_go = get_lang_specific(target, "go")
  let base_ptr = json_bool_val(base_go, "pointerReceiver")
  let target_ptr = json_bool_val(target_go, "pointerReceiver")
  if base_ptr != target_ptr {
    return ("breaking", "go-pointer-receiver-changed")
  }
  let base_recv = record_string(base_go, "receiver")
  let target_recv = record_string(target_go, "receiver")
  if base_recv != target_recv {
    return ("breaking", "go-receiver-changed")
  }
  let base_ms = go_method_set_len(base_go)
  let target_ms = go_method_set_len(target_go)
  if target_ms < base_ms {
    return ("breaking", "go-method-set-shrunk")
  }
  if target_ms > base_ms {
    return ("warning", "go-method-set-expanded")
  }
  ("warning", "go-signature-changed")
}

///|
fn classify_terraform_change(base : Json, target : Json) -> (String, String) {
  let base_tf = get_lang_specific(base, "terraform")
  let target_tf = get_lang_specific(target, "terraform")
  let base_pref = record_string(base_tf, "providerRef")
  let target_pref = record_string(target_tf, "providerRef")
  if base_pref != target_pref {
    return ("breaking", "terraform-provider-ref-changed")
  }
  let base_pd = json_bool_val(base_tf, "preventDestroy")
  let target_pd = json_bool_val(target_tf, "preventDestroy")
  if !base_pd && target_pd {
    return ("warning", "terraform-prevent-destroy-added")
  }
  let base_cbd = json_bool_val(base_tf, "createBeforeDestroy")
  let target_cbd = json_bool_val(target_tf, "createBeforeDestroy")
  if !base_cbd && target_cbd {
    return ("warning", "terraform-create-before-destroy-added")
  }
  let base_ic = json_array_len(base_tf, "ignoreChanges")
  let target_ic = json_array_len(target_tf, "ignoreChanges")
  if target_ic > base_ic {
    return ("note", "terraform-ignore-changes-expanded")
  }
  ("warning", "terraform-lifecycle-changed")
}

///|
fn classify_openapi_change(base : Json, target : Json) -> (String, String) {
  let base_oa = get_lang_specific(base, "openapi")
  let target_oa = get_lang_specific(target, "openapi")
  let base_method = record_string(base_oa, "httpMethod")
  let target_method = record_string(target_oa, "httpMethod")
  if base_method != target_method && target_method is Some(_) {
    return ("breaking", "openapi-http-method-changed")
  }
  let base_req = json_bool_val(base_oa, "required")
  let target_req = json_bool_val(target_oa, "required")
  if !base_req && target_req {
    return ("breaking", "openapi-became-required")
  }
  let base_sc = json_array_len(base_oa, "statusCodes")
  let target_sc = json_array_len(target_oa, "statusCodes")
  if target_sc > base_sc {
    return ("warning", "openapi-status-codes-added")
  }
  let base_mt = json_array_len(base_oa, "mediaTypes")
  let target_mt = json_array_len(target_oa, "mediaTypes")
  if target_mt > base_mt {
    return ("note", "openapi-media-types-added")
  }
  ("warning", "openapi-operation-changed")
}

///|
// Classify the semantic level for a "changed" diff entry based on provider-specific rules.
// Returns (level, semanticCategory) where level is "breaking"/"warning"/"note".
fn classify_change_level(base : Json, target : Json) -> (String, String) {
  if is_component_record(target) {
    let base_version = record_string(base, "version")
    let target_version = record_string(target, "version")
    if base_version != target_version {
      return ("warning", "component-version-upgrade")
    }
    return ("warning", "component-metadata-changed")
  }
  let profile = match json_object_get(target, "language_specific") {
    Some(Object(ls)) =>
      match ls.get("profile") {
        Some(String(p)) => p
        _ => ""
      }
    _ => ""
  }
  match profile {
    "rust-crate" => classify_rust_change(base, target)
    "go-module" => classify_go_change(base, target)
    "terraform-module" => classify_terraform_change(base, target)
    "openapi-spec" => classify_openapi_change(base, target)
    _ => ("warning", "generic-change")
  }
}

///|
fn declaration_changes(
  base_records : Array[Json],
  target_records : Array[Json],
) -> Array[Json] {
  let changes : Array[Json] = []
  let base_index = record_index(base_records)
  let target_index = record_index(target_records)

  for id, target in target_index {
    let target_id = record_string(target, "id").unwrap_or(id)
    match base_index.get(id) {
      Some(base) => {
        let base_id = record_string(base, "id").unwrap_or(id)
        if has_shape_change(base, target) {
          let (level, sem_cat) = classify_change_level(base, target)
          let change_obj : Map[String, Json] = {
            "kind": "changed",
            "id": target_id,
            "path": record_path(target),
            "level": level,
            "semanticCategory": sem_cat,
            "before": record_string(base, "signature").unwrap_or("unknown"),
            "after": record_string(target, "signature").unwrap_or("unknown"),
            "beforeRecord": change_record_payload(base),
            "afterRecord": change_record_payload(target),
            "semanticDiff": semantic_diff(base, target),
          }
          if is_component_record(target) {
            change_obj["componentDiff"] = component_diff(base, target)
          }
          changes.push(Json::object(change_obj))
        }
        if record_bool(target, "deprecated") && !record_bool(base, "deprecated") {
          changes.push({
            "kind": "deprecated",
            "id": if target_id != "" { target_id } else { base_id },
            "path": record_path(target),
            "level": "warning",
            "semanticCategory": "deprecated-declaration",
            "afterRecord": change_record_payload(target),
          })
        }
      }
      None =>
        changes.push({
          "kind": "added",
          "id": target_id,
          "path": record_path(target),
          "level": "note",
          "semanticCategory": "new-declaration",
          "afterRecord": change_record_payload(target),
        })
    }
  }

  for id, base in base_index {
    if !target_index.contains(id) {
      let base_id = record_string(base, "id").unwrap_or(id)
      changes.push({
        "kind": "removed",
        "id": base_id,
        "path": record_path(base),
        "level": "breaking",
        "semanticCategory": "removed-declaration",
        "beforeRecord": change_record_payload(base),
      })
    }
  }

  changes
}

///|
fn count_changes(changes : Array[Json], kind : String) -> Int {
  let mut count = 0
  for i in 0..<changes.length() {
    guard changes[i] is Object(change) else { continue }
    match change.get("kind") {
      Some(String(change_kind)) if change_kind == kind => count = count + 1
      _ => ()
    }
  }
  count
}

///|
fn field_or_unknown(
  manifest : Json,
  field_name : String,
  path : String,
) -> String {
  match get_field_string(manifest, field_name, path) {
    Ok(value) => value
    Err(_) => "unknown"
  }
}

///|
fn write_diff(path : String, diff : Json) -> Result[Unit, @cli.CliError] {
  let serialized = diff.stringify(indent=2)
  @fs.write_string_to_file(path, serialized) catch {
    err =>
      return Err(
        diff_error("cannot write diff file \{path}: \{err.to_string()}"),
      )
  }
  Ok(())
}

///|
pub fn run(params : DiffParams) -> @cli.CliResult[DiffResult, @cli.CliError] {
  let base_manifest_path = "\{params.repo}/dist/base/manifest.json"
  let target_manifest_path = "\{params.repo}/dist/target/manifest.json"
  let output_path = "\{params.repo}/dist/diff.json"

  let base_manifest_out = read_manifest(base_manifest_path)
  guard base_manifest_out is Ok(base_manifest) else {
    return Err(base_manifest_out.unwrap_err())
  }
  let base_schema_out = validate_manifest_shape(
    base_manifest, base_manifest_path,
  )
  guard base_schema_out is Ok(_) else {
    return Err(base_schema_out.unwrap_err())
  }

  let target_manifest_out = read_manifest(target_manifest_path)
  guard target_manifest_out is Ok(target_manifest) else {
    return Err(target_manifest_out.unwrap_err())
  }
  let target_schema_out = validate_manifest_shape(
    target_manifest, target_manifest_path,
  )
  guard target_schema_out is Ok(_) else {
    return Err(target_schema_out.unwrap_err())
  }

  let base_records_out = artifact_records("\{params.repo}/dist/base")
  guard base_records_out is Ok(base_records) else {
    return Err(base_records_out.unwrap_err())
  }
  let target_records_out = artifact_records("\{params.repo}/dist/target")
  guard target_records_out is Ok(target_records) else {
    return Err(target_records_out.unwrap_err())
  }

  let changes = declaration_changes(base_records, target_records)
  let diff : Json = {
    "schemaVersion": "ciq-diff/v1",
    "basePurl": field_or_unknown(base_manifest, "purl", "base"),
    "targetPurl": field_or_unknown(target_manifest, "purl", "target"),
    "summary": {
      "added": count_changes(changes, "added"),
      "removed": count_changes(changes, "removed"),
      "changed": count_changes(changes, "changed"),
      "deprecated": count_changes(changes, "deprecated"),
    },
    "changes": changes,
  }
  guard diff is Object(diff_object) else {
    return Err(diff_error("generated diff must be a JSON object"))
  }
  if params.since is Some(since) {
    diff_object["since"] = Json::string(since)
  }
  if params.include_test_changes {
    let all_test_changes = test_changes(base_records, target_records)
    diff_object["includeTestChanges"] = true
    diff_object["testSummary"] = {
      "added": count_changes(all_test_changes, "added"),
      "modified": count_changes(all_test_changes, "modified"),
      "removed": count_changes(all_test_changes, "removed"),
    }
    diff_object["testChanges"] = Json::array(all_test_changes)
  }
  let diff_schema_out = @schema.validate_ciq_diff_v1(diff)
  guard diff_schema_out is Ok(_) else {
    return Err(
      diff_error(
        "generated diff does not satisfy ciq-diff/v1 schema: \{diff_schema_out.unwrap_err().to_string()}",
      ),
    )
  }

  let write_out = write_diff(output_path, diff)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    repo: params.repo,
    summary: "Generated CIQ declaration diff at \{output_path}",
  })
}
