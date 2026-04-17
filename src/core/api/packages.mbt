// High-level wrappers over core query functions for the SDK layer.

///|
/// Extract a string field from a JSON object, returning empty string if missing.
fn obj_str(obj : Map[String, Json], field : String) -> String {
  match obj.get(field) {
    Some(String(s)) if s != "" => s
    _ => ""
  }
}

///|
fn spdx_cache_path() -> String {
  "./.cogna/sbom.spdx.json"
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

///|
/// Return package tree for the current project context.
/// Attempts to read manifest.json and software-components.ndjson from ./dist/.
/// Falls back to a minimal root stub if no data is available.
pub fn fetch_packages() -> Json {
  match fetch_packages_from_spdx() {
    Some(value) => return value
    None => ()
  }

  // Try to read the manifest for root purl / name
  let root_name = match read_repo_records(".", "manifest") {
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

  // Try to build children from software-components
  let children : Array[Json] = []
  match read_repo_records(".", "software-components") {
    Ok(records) =>
      for i in 0..<records.length() {
        guard records[i] is Object(obj) else { continue }
        let name = obj_str(obj, "name")
        let relation = obj_str(obj, "scope")
        if name == "" || relation == "" {
          continue
        }
        let version = match obj.get("version") {
          Some(String(v)) if v != "" => v
          _ => ""
        }
        children.push(
          package_node_json(
            name,
            if version != "" {
              Some(version)
            } else {
              None
            },
            None,
            relation,
            None,
            [],
          ),
        )
      }
    Err(_) => ()
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
/// Reads ndjson records and maps them to the Outline format expected by the SDK.
pub fn query_outlines_for_package(pkg : String) -> Json {
  let records = all_bundle_records(pkg)
  let outlines : Array[Json] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<records.length() {
    guard records[i] is Object(obj) else { continue }
    let id = obj_str(obj, "id")
    let kind = obj_str(obj, "kind")
    if id == "" || kind == "" {
      continue
    }
    if seen.contains(id) {
      continue
    }
    seen[id] = true
    let symbol = {
      let cn = obj_str(obj, "canonical_name")
      if cn != "" {
        cn
      } else {
        obj_str(obj, "name")
      }
    }
    // Use docs as summary; fall back to signature
    let summary_str = {
      let d = obj_str(obj, "docs")
      if d != "" {
        d
      } else {
        obj_str(obj, "signature")
      }
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
    // Pass through the raw location object (SourceLocation::from_json handles camelCase)
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
  let raw_matches = query_matches(pkg, selector, None)

  // Enrich each match with a `symbol` field (required by QueryMatch::from_json)
  let enriched : Array[Json] = []
  for i in 0..<raw_matches.length() {
    guard raw_matches[i] is Object(obj) else {
      enriched.push(raw_matches[i])
      continue
    }
    // symbol: canonical_name → name → id-derived
    let symbol = {
      let cn = obj_str(obj, "canonical_name")
      if cn != "" {
        cn
      } else {
        let n = obj_str(obj, "name")
        if n != "" {
          n
        } else {
          obj_str(obj, "id")
        }
      }
    }
    let enriched_obj : Map[String, Json] = {}
    for key, val in obj {
      enriched_obj[key] = val
    }
    enriched_obj["symbol"] = Json::string(symbol)
    // Promote docs to summary if summary absent
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
