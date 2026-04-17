// Core implementation for the Diff API method.
// Returns a JSON value shaped like DiffResponse for the SDK layer to parse.

///|
/// Compute diff between base and target for the current project.
/// Returns a Json value shaped as { summary, changes, testChanges }.
pub fn diff(
  base : String?,
  target : String?,
  include_test_changes : Bool,
) -> Json {
  // TODO: delegate to @diff.run once project path context is wired
  ignore(base)
  ignore(target)
  ignore(include_test_changes)
  {
    "summary": {
      "added": (0 : Int).to_json(),
      "removed": (0 : Int).to_json(),
      "changed": (0 : Int).to_json(),
      "deprecated": (0 : Int).to_json(),
    },
    "changes": Json::array([]),
    "testChanges": Json::array([]),
  }
}
