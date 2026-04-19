// ── Package helpers ────────────────────────────────────────────────────────────

///|
fn obj_str(obj : Map[String, Json], field : String) -> String {
  match obj.get(field) {
    Some(String(s)) if s != "" => s
    _ => ""
  }
}

///|
fn resolved_root_dir() -> String {
  match @config.resolve(".") {
    Ok(resolved) => resolved.root_dir
    Err(_) => "."
  }
}

///|
fn repo_for_package(pkg : String) -> String {
  if pkg != "" && @fs.path_exists(pkg) {
    pkg
  } else {
    resolved_root_dir()
  }
}

///|
fn spdx_cache_path() -> String {
  "\{resolved_root_dir()}/.cogna/sbom.spdx.json"
}

///|
fn package_name_from_purl(purl : String) -> String {
  let prefix = if purl.has_prefix("pkg:") { purl[4:].to_string() } else { purl }
  let no_version = match prefix.split("@").to_array() {
    [first, ..] => first.to_string()
    [] => prefix
  }
  let parts = no_version.split("/").to_array()
  if parts.length() == 0 {
    no_version
  } else {
    parts[parts.length() - 1].to_string()
  }
}

///|
fn package_ecosystem_from_purl(purl : String) -> String? {
  let prefix = if purl.has_prefix("pkg:") { purl[4:].to_string() } else { purl }
  let parts = prefix.split("/").to_array()
  if parts.length() == 0 {
    None
  } else {
    Some(parts[0].to_string())
  }
}

///|
fn package_node_json(
  name : String,
  version : String?,
  ecosystem : String?,
  relation : String,
  summary : String?,
  children : Array[Json],
) -> Json {
  let obj : Map[String, Json] = {
    "name": name,
    "relation": relation,
    "children": Json::array(children),
  }
  match version {
    Some(value) if value != "" => obj["version"] = Json::string(value)
    _ => ()
  }
  match ecosystem {
    Some(value) if value != "" => obj["ecosystem"] = Json::string(value)
    _ => ()
  }
  match summary {
    Some(value) if value != "" => obj["summary"] = Json::string(value)
    _ => ()
  }
  Json::object(obj)
}

///|
fn fetch_packages_from_spdx() -> Json? {
  if !@fs.path_exists(spdx_cache_path()) {
    return None
  }
  let text = @fs.read_file_to_string(spdx_cache_path()) catch {
    _ => return None
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(doc)) else { return None }
  guard doc.get("packages") is Some(Array(packages)) else { return None }
  let root_id_ref : Ref[String?] = Ref::new(None)
  let root_name_ref : Ref[String?] = Ref::new(None)
  let root_version_ref : Ref[String?] = Ref::new(None)
  let pkg_by_id : Map[String, Json] = {}
  for i in 0..<packages.length() {
    guard packages[i] is Object(pkg) else { continue }
    let spdx_id = obj_str(pkg, "SPDXID")
    if spdx_id == "" {
      continue
    }
    pkg_by_id[spdx_id] = packages[i]
    if root_id_ref.val is None && !spdx_id.contains("-Package-") {
      root_id_ref.val = Some(spdx_id)
      root_name_ref.val = Some(obj_str(pkg, "name"))
      let root_version = obj_str(pkg, "versionInfo")
      root_version_ref.val = if root_version == "" {
        None
      } else {
        Some(root_version)
      }
    }
  }
  let root_id = match root_id_ref.val {
    Some(value) => value
    None => return None
  }
  let relation_map : Map[String, String] = {}
  if doc.get("relationships") is Some(Array(relationships)) {
    for i in 0..<relationships.length() {
      guard relationships[i] is Object(rel) else { continue }
      if obj_str(rel, "relationshipType") != "DEPENDS_ON" {
        continue
      }
      let source = obj_str(rel, "spdxElementId")
      let target = obj_str(rel, "relatedSpdxElement")
      if source == root_id && target != "" {
        relation_map[target] = "direct"
      } else if target != "" && !relation_map.contains(target) {
        relation_map[target] = "transitive"
      }
    }
  }
  let children : Array[Json] = []
  for spdx_id, pkg_json in pkg_by_id {
    if spdx_id == root_id {
      continue
    }
    guard pkg_json is Object(pkg) else { continue }
    let name = obj_str(pkg, "name")
    if name == "" {
      continue
    }
    let version_text = obj_str(pkg, "versionInfo")
    let ecosystem = if pkg.get("externalRefs") is Some(Array(ext_refs)) {
      let mut found : String? = None
      for j in 0..<ext_refs.length() {
        guard ext_refs[j] is Object(ext_ref) else { continue }
        if obj_str(ext_ref, "referenceType") != "purl" {
          continue
        }
        let locator = obj_str(ext_ref, "referenceLocator")
        if locator != "" {
          found = package_ecosystem_from_purl(locator)
          break
        }
      }
      found
    } else {
      None
    }
    let summary = {
      let desc = obj_str(pkg, "description")
      if desc != "" {
        Some(desc)
      } else {
        None
      }
    }
    let relation = relation_map.get(spdx_id).unwrap_or("transitive")
    children.push(
      package_node_json(
        name,
        if version_text == "" {
          None
        } else {
          Some(version_text)
        },
        ecosystem,
        relation,
        summary,
        [],
      ),
    )
  }
  Some({
    "root": package_node_json(
      root_name_ref.val.unwrap_or("."),
      root_version_ref.val,
      Some("workspace"),
      "root",
      None,
      children,
    ),
  })
}

// ── Query helpers ──────────────────────────────────────────────────────────────

///|
pub fn validate_query_shape(
  query : Json,
  query_file : String,
) -> Result[Unit, String] {
  guard query is Object(query_object) else {
    return Err("query file \{query_file} must be a JSON object")
  }
  guard query_object.get("schemaVersion") is Some(String("ciq-query/v1")) else {
    return Err("query file \{query_file} must declare ciq-query/v1 schema")
  }
  Ok(())
}

///|
pub fn validate_result_shape(result_json : Json) -> Result[Unit, String] {
  guard result_json is Object(_) else {
    return Err("generated result must be a JSON object")
  }
  Ok(())
}

///|
pub fn query_value(query : Json, field : String, fallback : String) -> String {
  guard query is Object(query_object) else { return fallback }
  match query_object.get(field) {
    Some(String(value)) => value
    _ => fallback
  }
}

///|
pub fn query_repo(query : Json) -> String {
  query_value(query, "repo", ".")
}

///|
fn decode_utf8(bytes : Bytes, path : String) -> Result[String, String] {
  let text = @utf8.decode(bytes) catch {
    _ => return Err("invalid utf-8 bytes in \{path}")
  }
  Ok(text)
}

///|
fn parse_json_text(text : String, label : String) -> Result[Json, String] {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { return Err("invalid json in \{label}") }
  Ok(value)
}

///|
pub fn read_ndjson(path : String) -> Result[Array[Json], String] {
  let file_bytes = @fs.read_file_to_bytes(path) catch {
    _ => return Err("cannot read ndjson \{path}")
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
      return Err("invalid ndjson line in \{path} at \{i + 1}")
    }
    records.push(value)
  }
  Ok(records)
}

///|
fn query_deadline_exceeded(cancelled : () -> Bool) -> Bool {
  cancelled()
}

///|
pub fn parent_dir(path : String) -> String {
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
pub fn selector_value(
  query : Json,
  field : String,
  fallback : String,
) -> String {
  guard query is Object(query_object) else { return fallback }
  guard query_object.get("selector") is Some(Object(selector_object)) else {
    return fallback
  }
  match selector_object.get(field) {
    Some(String(value)) => value
    _ => fallback
  }
}

///|
pub fn selector_kind_hint(query : Json) -> String? {
  guard query is Object(query_object) else { return None }
  guard query_object.get("selector") is Some(Object(selector_object)) else {
    return None
  }
  match selector_object.get("kind") {
    Some(String(value)) if value != "" => Some(value)
    _ => None
  }
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
fn record_symbol(record : Json) -> String {
  match record_string(record, "symbol") {
    Some(value) => value
    None =>
      match record_string(record, "canonical_name") {
        Some(value) => value
        None =>
          match record_string(record, "name") {
            Some(value) => value
            None => record_string(record, "id").unwrap_or("")
          }
      }
  }
}

///|
fn selector_match_rank(record : Json, selector_path : String) -> Int? {
  let path = record_string(record, "location").unwrap_or("")
  let symbol = record_symbol(record)
  let id = record_string(record, "id").unwrap_or("")
  let signature = record_string(record, "signature").unwrap_or("")
  if path == selector_path {
    Some(0)
  } else if symbol == selector_path {
    Some(1)
  } else if id.contains(selector_path) {
    Some(2)
  } else if signature.contains(selector_path) {
    Some(3)
  } else {
    None
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
fn append_record_field(
  target : Map[String, Json],
  record_object : Map[String, Json],
  field : String,
) -> Unit {
  match record_object.get(field) {
    Some(value) => target[field] = value
    None => ()
  }
}

///|
fn append_result_passthrough_fields(
  target : Map[String, Json],
  record_object : Map[String, Json],
) -> Unit {
  let fields = ["docs", "location"]
  for i in 0..<fields.length() {
    append_record_field(target, record_object, fields[i])
  }
}

///|
fn append_records(
  records : Array[Json],
  source : Result[Array[Json], String],
) -> Unit {
  guard source is Ok(values) else { return }
  for i in 0..<values.length() {
    records.push(values[i])
  }
}

///|
fn append_json_values(target : Array[Json], values : Array[Json]) -> Unit {
  for i in 0..<values.length() {
    target.push(values[i])
  }
}

///|
fn append_handle_records(
  target : Array[Json],
  handle_object : Map[String, Json],
  field : String,
) -> Unit {
  match handle_object.get(field) {
    Some(Array(values)) => append_json_values(target, values)
    _ => ()
  }
}

///|
fn records_from_handle(handle : Json) -> Array[Json] {
  let records : Array[Json] = []
  guard handle is Object(handle_object) else { return records }
  append_handle_records(records, handle_object, "declarations")
  append_handle_records(records, handle_object, "softwareComponents")
  append_handle_records(records, handle_object, "software_components")
  records
}

///|
pub fn read_repo_records(
  repo : String,
  name : String,
) -> Result[Array[Json], String] {
  let plain_path = "\{repo}/dist/\{name}.ndjson"
  if @fs.path_exists(plain_path) {
    read_ndjson(plain_path)
  } else {
    Err("cannot read ndjson \{plain_path}")
  }
}

///|
fn spdx_component_records(repo : String) -> Result[Array[Json], String] {
  let path = "\{repo}/.cogna/sbom.spdx.json"
  if !@fs.path_exists(path) {
    return Err("cannot read json \{path}")
  }
  let text = @fs.read_file_to_string(path) catch {
    _ => return Err("cannot read json \{path}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(root)) else {
    return Err("invalid json in \{path}")
  }
  guard root.get("packages") is Some(Array(packages)) else { return Ok([]) }
  let records : Array[Json] = []
  for i in 0..<packages.length() {
    guard packages[i] is Object(pkg) else { continue }
    let spdx_id = obj_str(pkg, "SPDXID")
    if spdx_id == "" || !spdx_id.contains("-Package-") {
      continue
    }
    let name = obj_str(pkg, "name")
    if name == "" {
      continue
    }
    let version = {
      let value = obj_str(pkg, "versionInfo")
      if value == "" { None } else { Some(value) }
    }
    let purl = match pkg.get("externalRefs") {
      Some(Array(refs)) => {
        let mut found : String? = None
        for j in 0..<refs.length() {
          guard refs[j] is Object(ref_obj) else { continue }
          if obj_str(ref_obj, "referenceType") != "purl" {
            continue
          }
          let locator = obj_str(ref_obj, "referenceLocator")
          if locator != "" {
            found = Some(locator)
            break
          }
        }
        found
      }
      _ => None
    }
    let id = match purl {
      Some(value) => value
      None => "pkg:unknown/\{name}"
    }
    let signature = match version {
      Some(value) => "library \{name}@\{value}"
      None => "library \{name}"
    }
    let record : Map[String, Json] = {
      "id": Json::string(id),
      "kind": Json::string("component"),
      "path": Json::string("sbom.spdx.json"),
      "signature": Json::string(signature),
      "name": Json::string(name),
      "componentType": Json::string("library"),
      "scope": Json::string("dependency"),
      "location": {
        "uri": "sbom.spdx.json",
        "startLine": 1,
        "endLine": 1,
      },
    }
    match version {
      Some(value) => record["version"] = Json::string(value)
      None => ()
    }
    match purl {
      Some(value) => record["purl"] = Json::string(value)
      None => ()
    }
    records.push(Json::object(record))
  }
  Ok(records)
}

///|
fn read_component_records(repo : String) -> Array[Json] {
  match read_repo_records(repo, "software-components") {
    Ok(records) => records
    Err(_) =>
      match spdx_component_records(repo) {
        Ok(records) => records
        Err(_) => []
      }
  }
}

///|
pub fn all_bundle_records(repo : String) -> Array[Json] {
  let records : Array[Json] = []
  append_records(records, read_repo_records(repo, "declarations"))
  let components = read_component_records(repo)
  for i in 0..<components.length() {
    records.push(components[i])
  }
  records
}

///|
pub fn all_bundle_records_with_cancel(
  repo : String,
  cancelled : () -> Bool,
) -> Result[Array[Json], String] {
  if query_deadline_exceeded(cancelled) {
    return Err("request cancelled")
  }
  let declarations = match read_repo_records(repo, "declarations") {
    Ok(values) => values
    Err(_) => []
  }
  if query_deadline_exceeded(cancelled) {
    return Err("request cancelled")
  }
  let components = read_component_records(repo)
  if query_deadline_exceeded(cancelled) {
    return Err("request cancelled")
  }
  let records : Array[Json] = []
  for i in 0..<declarations.length() {
    records.push(declarations[i])
  }
  for i in 0..<components.length() {
    records.push(components[i])
  }
  Ok(records)
}

///|
fn record_matches_selector(
  record : Json,
  selector_path : String,
  selector_kind : String?,
  expected_rank : Int,
) -> Json? {
  let path = match record_string(record, "path") {
    Some(value) => value
    None => ""
  }
  let kind = match record_string(record, "kind") {
    Some(value) => value
    None => ""
  }
  let id = match record_string(record, "id") {
    Some(value) => value
    None => ""
  }
  let signature = match record_string(record, "signature") {
    Some(value) => value
    None => ""
  }
  if id == "" || kind == "" || signature == "" {
    return None
  }
  if kind == "component" {
    return None
  }
  let symbol = record_symbol(record)
  if symbol == "" {
    return None
  }
  match selector_kind {
    Some(kind_hint) if kind != kind_hint => return None
    _ => ()
  }
  guard selector_match_rank(record, selector_path) is Some(rank) else {
    return None
  }
  if rank != expected_rank {
    return None
  }
  let location_path = if path == "" { selector_path } else { path }
  let match_record : Map[String, Json] = {
    "id": id,
    "kind": kind,
    "symbol": symbol,
    "signature": signature,
    "location": record_location(record, location_path),
  }
  guard record is Object(record_object) else {
    return Some(Json::object(match_record))
  }
  append_result_passthrough_fields(match_record, record_object)
  Some(Json::object(match_record))
}

///|
fn query_matches_from_records(
  records : Array[Json],
  selector_path : String,
  selector_kind : String?,
) -> Array[Json] {
  let selected : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for rank in 0..<4 {
    for i in 0..<records.length() {
      let match_out = record_matches_selector(
        records[i],
        selector_path,
        selector_kind,
        rank,
      )
      guard match_out is Some(found) else { continue }
      guard found is Object(found_object) else { continue }
      guard found_object.get("id") is Some(String(id)) else { continue }
      if !seen.contains(id) {
        seen[id] = true
        selected.push(found)
      }
    }
  }
  selected
}

///|
pub fn query_matches(
  repo : String,
  selector_path : String,
  selector_kind : String?,
) -> Array[Json] {
  let records = all_bundle_records(repo)
  query_matches_from_records(records, selector_path, selector_kind)
}

///|
pub fn query_matches_with_cancel(
  repo : String,
  selector_path : String,
  selector_kind : String?,
  cancelled : () -> Bool,
) -> Result[Array[Json], String] {
  let records_out = all_bundle_records_with_cancel(repo, cancelled)
  guard records_out is Ok(records) else { return Err(records_out.unwrap_err()) }
  let selected : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for rank in 0..<4 {
    for i in 0..<records.length() {
      if query_deadline_exceeded(cancelled) {
        return Err("request cancelled")
      }
      let match_out = record_matches_selector(
        records[i],
        selector_path,
        selector_kind,
        rank,
      )
      guard match_out is Some(found) else { continue }
      guard found is Object(found_object) else { continue }
      guard found_object.get("id") is Some(String(id)) else { continue }
      if !seen.contains(id) {
        seen[id] = true
        selected.push(found)
      }
    }
  }
  Ok(selected)
}

///|
fn build_ciq_result_from_records(query : Json, records : Array[Json]) -> Json {
  let path = selector_value(query, "path", "unknown")
  let kind = selector_kind_hint(query)
  let final_matches = query_matches_from_records(records, path, kind)
  {
    "schemaVersion": "ciq-result/v1",
    "purl": query_value(query, "purl", "unknown"),
    "matches": final_matches,
  }
}

///|
fn parse_cursor(cursor : String?) -> Int {
  match cursor {
    Some(value) if value.has_prefix("cursor:") => {
      let suffix = value.split(":").to_array()
      if suffix.length() == 2 {
        let parsed = try? @string.parse_int(suffix[1])
        match parsed {
          Ok(number) if number >= 0 => number
          _ => 0
        }
      } else {
        0
      }
    }
    _ => 0
  }
}

///|
pub fn query_outlines_paginated(
  repo : String,
  purl : String,
  limit : Int,
  cursor : String?,
) -> (Array[Json], String?) {
  let records = all_bundle_records(repo)
  let outlines : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<records.length() {
    let path = match record_string(records[i], "path") {
      Some(value) => value
      None => continue
    }
    let kind = match record_string(records[i], "kind") {
      Some(value) => value
      None => continue
    }
    let signature = match record_string(records[i], "signature") {
      Some(value) => value
      None => continue
    }
    if kind == "component" {
      continue
    }
    let key = "\{path}::\{kind}::\{signature}"
    if seen.contains(key) {
      continue
    }
    seen[key] = true
    outlines.push({
      "purl": purl,
      "path": path,
      "kind": kind,
      "summary": signature,
    })
  }
  let start = parse_cursor(cursor)
  let max_limit = if limit <= 0 { 20 } else { limit }
  let end = if start + max_limit > outlines.length() {
    outlines.length()
  } else {
    start + max_limit
  }
  let page : Array[Json] = []
  for i in start..<end {
    page.push(outlines[i])
  }
  if end < outlines.length() {
    (page, Some("cursor:\{end}"))
  } else {
    (page, None)
  }
}

///|
pub fn query_outlines_with_cancel(
  repo : String,
  purl : String,
  limit : Int,
  cursor : String?,
  cancelled : () -> Bool,
) -> Result[(Array[Json], String?), String] {
  let records_out = all_bundle_records_with_cancel(repo, cancelled)
  guard records_out is Ok(records) else { return Err(records_out.unwrap_err()) }
  let outlines : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<records.length() {
    if query_deadline_exceeded(cancelled) {
      return Err("request cancelled")
    }
    let path = match record_string(records[i], "path") {
      Some(value) => value
      None => continue
    }
    let kind = match record_string(records[i], "kind") {
      Some(value) => value
      None => continue
    }
    let signature = match record_string(records[i], "signature") {
      Some(value) => value
      None => continue
    }
    if kind == "component" {
      continue
    }
    let key = "\{path}::\{kind}::\{signature}"
    if seen.contains(key) {
      continue
    }
    seen[key] = true
    outlines.push({
      "purl": purl,
      "path": path,
      "kind": kind,
      "summary": signature,
    })
  }
  let start = parse_cursor(cursor)
  let max_limit = if limit <= 0 { 20 } else { limit }
  let end = if start + max_limit > outlines.length() {
    outlines.length()
  } else {
    start + max_limit
  }
  let page : Array[Json] = []
  for i in start..<end {
    if query_deadline_exceeded(cancelled) {
      return Err("request cancelled")
    }
    page.push(outlines[i])
  }
  if end < outlines.length() {
    Ok((page, Some("cursor:\{end}")))
  } else {
    Ok((page, None))
  }
}

///|
pub fn build_ciq_result(query : Json, query_file : String) -> Json {
  let query_repo_value = query_repo(query)
  let repo = if query_repo_value == "." {
    parent_dir(query_file)
  } else {
    query_repo_value
  }
  build_ciq_result_from_records(query, all_bundle_records(repo))
}

///|
pub fn run_query_json(
  index_text : String,
  query_text : String,
) -> Result[String, String] {
  let index_out = parse_json_text(index_text, "local index")
  guard index_out is Ok(index_value) else { return Err(index_out.unwrap_err()) }
  let query_out = parse_json_text(query_text, "query")
  guard query_out is Ok(query_value) else { return Err(query_out.unwrap_err()) }
  let query_shape_out = validate_query_shape(query_value, "<memory>")
  guard query_shape_out is Ok(_) else {
    return Err(query_shape_out.unwrap_err())
  }
  let result_json = build_ciq_result_from_records(
    query_value,
    records_from_handle(index_value),
  )
  let result_shape_out = validate_result_shape(result_json)
  guard result_shape_out is Ok(_) else {
    return Err(result_shape_out.unwrap_err())
  }
  Ok(result_json.stringify())
}

// ── Public SDK API ─────────────────────────────────────────────────────────────

///|
/// Return package tree for the current project context.
pub fn fetch_packages_json() -> Json {
  match fetch_packages_from_spdx() {
    Some(value) => return value
    None => ()
  }
  let root = resolved_root_dir()
  let root_name = match read_repo_records(root, "manifest") {
    Ok(records) if records.length() > 0 => {
      guard records[0] is Object(obj) else { "." }
      let purl = obj_str(obj, "purl")
      if purl != "" {
        package_name_from_purl(purl)
      } else {
        "."
      }
    }
    _ => "."
  }
  let children : Array[Json] = []
  let records = read_component_records(root)
  for i in 0..<records.length() {
    guard records[i] is Object(obj) else { continue }
    let name = obj_str(obj, "name")
    let relation = {
      let scope = obj_str(obj, "scope")
      if scope == "" { "dependency" } else { scope }
    }
    if name == "" {
      continue
    }
    let version = match obj.get("version") {
      Some(String(v)) if v != "" => v
      _ => ""
    }
    children.push(
      package_node_json(
        name,
        if version != "" { Some(version) } else { None },
        None,
        relation,
        None,
        [],
      ),
    )
  }
  {
    "root": package_node_json(
      root_name,
      None,
      Some("workspace"),
      "root",
      None,
      children,
    ),
  }
}

///|
/// Return public API outlines for the given package.
pub fn query_outlines_for_package(pkg : String) -> Json {
  let records = all_bundle_records(repo_for_package(pkg))
  let outlines : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<records.length() {
    guard records[i] is Object(obj) else { continue }
    let id = obj_str(obj, "id")
    let kind = obj_str(obj, "kind")
    if id == "" || kind == "" {
      continue
    }
    if kind == "component" {
      continue
    }
    if seen.contains(id) {
      continue
    }
    seen[id] = true
    let symbol = {
      let s = obj_str(obj, "symbol")
      if s != "" {
        s
      } else {
        let canonical = obj_str(obj, "canonical_name")
        if canonical != "" {
          canonical
        } else {
          let name = obj_str(obj, "name")
          if name != "" { name } else { obj_str(obj, "id") }
        }
      }
    }
    let summary_str = {
      let d = obj_str(obj, "docs")
      if d != "" { d } else { obj_str(obj, "signature") }
    }
    let outline : Map[String, Json] = {
      "id": id,
      "symbol": symbol,
      "kind": kind,
      "deprecated": false,
    }
    if summary_str != "" {
      outline["summary"] = Json::string(summary_str)
    }
    match obj.get("location") {
      Some(loc) => outline["location"] = loc
      None => ()
    }
    outlines.push(Json::object(outline))
  }
  { "package": pkg, "outlines": Json::array(outlines) }
}

///|
/// Exact or fuzzy search over a package's public API.
pub fn query_package(
  pkg : String,
  exact_id : String?,
  exact_symbol : String?,
  text : String?,
  limit : Int?,
  _cursor : String?,
) -> Json {
  let (mode, selector) = match exact_id {
    Some(id) if id != "" => ("exact-id", id)
    _ =>
      match exact_symbol {
        Some(sym) if sym != "" => ("exact-symbol", sym)
        _ =>
          match text {
            Some(t) if t != "" => ("fuzzy-text", t)
            _ => ("fuzzy-text", "")
          }
      }
  }
  let max = match limit {
    Some(n) if n > 0 => n
    _ => 20
  }
  let raw_matches = query_matches(repo_for_package(pkg), selector, None)
  let enriched : Array[Json] = []
  for i in 0..<raw_matches.length() {
    guard raw_matches[i] is Object(obj) else {
      enriched.push(raw_matches[i])
      continue
    }
    let symbol = {
      let s = obj_str(obj, "symbol")
      if s != "" {
        s
      } else {
        obj_str(obj, "id")
      }
    }
    let enriched_obj : Map[String, Json] = {}
    for key, val in obj {
      enriched_obj[key] = val
    }
    enriched_obj["symbol"] = Json::string(symbol)
    if !obj.contains("summary") {
      let d = obj_str(obj, "docs")
      if d != "" {
        enriched_obj["summary"] = Json::string(d)
      }
    }
    enriched.push(Json::object(enriched_obj))
  }
  let page : Array[Json] = if enriched.length() > max {
    let out : Array[Json] = []
    for i in 0..<max {
      out.push(enriched[i])
    }
    out
  } else {
    enriched
  }
  { "package": pkg, "mode": mode, "matches": Json::array(page) }
}

///|
/// FetchPackages: return the package tree for the current project.
pub fn fetch_packages(
  req : @generated.FetchPackagesRequest,
) -> @generated.FetchPackagesResponse? {
  ignore(req)
  @generated.FetchPackagesResponse::from_json(fetch_packages_json())
}

///|
/// QueryOutlines: return public API outlines for the given package.
pub fn query_outlines(
  req : @generated.QueryOutlinesRequest,
) -> @generated.QueryOutlinesResponse? {
  @generated.QueryOutlinesResponse::from_json(
    query_outlines_for_package(req.package_name),
  )
}

///|
/// Query: exact or fuzzy search over a package's public API.
pub fn query(req : @generated.QueryRequest) -> @generated.QueryResponse? {
  @generated.QueryResponse::from_json(
    query_package(
      req.package_name,
      req.exact_id,
      req.exact_symbol,
      req.text,
      req.limit,
      req.cursor,
    ),
  )
}
