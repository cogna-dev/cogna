///|
/// Diff: compare current project against a baseline.
/// Reads the pre-computed diff artifact at dist/diff.json and surfaces
/// the summary, changes, and (optionally) test changes.
pub fn diff(req : @generated.DiffRequest) -> @generated.DiffResponse? {
  let include_test = match req.include_test_changes {
    Some(v) => v
    None => false
  }
  let empty_summary : Json = {
    "added": (0 : Int).to_json(),
    "removed": (0 : Int).to_json(),
    "changed": (0 : Int).to_json(),
    "deprecated": (0 : Int).to_json(),
  }
  let empty : Json = {
    "summary": empty_summary,
    "changes": Json::array([]),
    "testChanges": Json::array([]),
  }
  let text = @fs.read_file_to_string("./dist/diff.json") catch {
    _ => return @generated.DiffResponse::from_json(empty)
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(obj)) else {
    return @generated.DiffResponse::from_json(empty)
  }
  let summary : Json = match obj.get("summary") {
    Some(s) => s
    None => empty_summary
  }
  let changes : Json = match obj.get("changes") {
    Some(Array(items)) => Json::array(items)
    _ => Json::array([])
  }
  let test_changes : Json = if include_test {
    match obj.get("testChanges") {
      Some(Array(items)) => Json::array(items)
      _ => Json::array([])
    }
  } else {
    Json::array([])
  }
  @generated.DiffResponse::from_json({
    "summary": summary,
    "changes": changes,
    "testChanges": test_changes,
  })
}
