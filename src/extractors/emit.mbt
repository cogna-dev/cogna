///|
pub fn sort_and_dedup(records : Array[Json], key : String) -> Array[Json] {
  records.sort_by((a, b) => field_string(a, key).compare(field_string(b, key)))
  let deduped : Array[Json] = []
  for i in 0..<records.length() {
    let value = records[i]
    if deduped.is_empty() ||
      field_string(deduped[deduped.length() - 1], key) != field_string(value, key) {
      deduped.push(value)
    }
  }
  deduped
}

///|
pub fn to_ndjson(records : Array[Json]) -> String {
  if records.is_empty() {
    return ""
  }
  records.map(record => record.stringify()).join("\n") + "\n"
}
