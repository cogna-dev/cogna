///|
fn parse_bool_literal(value : String) -> Bool? {
  match trim_quotes(trim_spaces(value)) {
    "true" => Some(true)
    "false" => Some(false)
    _ => None
  }
}

///|
pub fn last_record(records : Array[Json]) -> Json? {
  if records.is_empty() {
    None
  } else {
    Some(records[records.length() - 1])
  }
}

///|
pub fn ensure_shape_object(record : Json) -> Map[String, Json]? {
  guard record is Object(record_object) else { return None }
  match record_object.get("shape") {
    Some(Object(shape)) => Some(shape)
    _ => None
  }
}

///|
pub fn ensure_language_specific_profile(
  record : Json,
  profile_key : String,
) -> Map[String, Json]? {
  guard record is Object(record_object) else { return None }
  guard record_object.get("language_specific")
    is Some(Object(language_specific)) else {
    return None
  }
  match language_specific.get(profile_key) {
    Some(Object(profile_object)) => Some(profile_object)
    _ => {
      let profile_object : Map[String, Json] = {}
      language_specific[profile_key] = Json::object(profile_object)
      Some(profile_object)
    }
  }
}

///|
pub fn set_shape_string(record : Json, key : String, value : String) -> Unit {
  if value == "" {
    return
  }
  guard ensure_shape_object(record) is Some(shape) else { return }
  shape[key] = Json::string(value)
}

///|
pub fn set_shape_string_array(
  record : Json,
  key : String,
  values : Array[String],
) -> Unit {
  if values.is_empty() {
    return
  }
  guard ensure_shape_object(record) is Some(shape) else { return }
  shape[key] = Json::array(values.map(Json::string))
}

///|
pub fn put_shape_string_array(
  record : Json,
  key : String,
  values : Array[String],
) -> Unit {
  guard ensure_shape_object(record) is Some(shape) else { return }
  shape[key] = Json::array(values.map(Json::string))
}

///|
pub fn set_language_specific_string(
  record : Json,
  profile_key : String,
  key : String,
  value : String,
) -> Unit {
  if value == "" {
    return
  }
  guard ensure_language_specific_profile(record, profile_key)
    is Some(profile_object) else {
    return
  }
  profile_object[key] = Json::string(value)
}

///|
pub fn set_language_specific_bool(
  record : Json,
  profile_key : String,
  key : String,
  value : Bool,
) -> Unit {
  guard ensure_language_specific_profile(record, profile_key)
    is Some(profile_object) else {
    return
  }
  profile_object[key] = Json::boolean(value)
}

///|
pub fn set_language_specific_string_array(
  record : Json,
  profile_key : String,
  key : String,
  values : Array[String],
) -> Unit {
  if values.is_empty() {
    return
  }
  guard ensure_language_specific_profile(record, profile_key)
    is Some(profile_object) else {
    return
  }
  profile_object[key] = Json::array(values.map(Json::string))
}

///|
pub fn shape_string(record : Json, key : String) -> String {
  guard ensure_shape_object(record) is Some(shape) else { return "" }
  match shape.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
pub fn language_specific_profile_string(
  record : Json,
  profile_key : String,
  key : String,
) -> String {
  guard record is Object(record_object) else { return "" }
  guard record_object.get("language_specific")
    is Some(Object(language_specific)) else {
    return ""
  }
  guard language_specific.get(profile_key) is Some(Object(profile_object)) else {
    return ""
  }
  match profile_object.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
pub fn language_specific_profile_bool(
  record : Json,
  profile_key : String,
  key : String,
) -> Bool? {
  guard record is Object(record_object) else { return None }
  guard record_object.get("language_specific")
    is Some(Object(language_specific)) else {
    return None
  }
  guard language_specific.get(profile_key) is Some(Object(profile_object)) else {
    return None
  }
  match profile_object.get(key) {
    Some(value) => parse_bool_literal(value.stringify())
    _ => None
  }
}

///|
pub fn set_record_relations(record : Json, relations : Array[Json]) -> Unit {
  guard record is Object(record_object) else { return }
  record_object["relations"] = Json::array(relations)
}

///|
pub fn filter_record_relations(
  record : Json,
  removed_kinds : Array[String],
) -> Array[Json] {
  let filtered : Array[Json] = []
  guard record is Object(record_object) else { return filtered }
  guard record_object.get("relations") is Some(Array(relations)) else {
    return filtered
  }
  for i in 0..<relations.length() {
    guard relations[i] is Object(relation_object) else { continue }
    let kind = match relation_object.get("kind") {
      Some(String(value)) => value
      _ => ""
    }
    let mut removed = false
    for j in 0..<removed_kinds.length() {
      if kind == removed_kinds[j] {
        removed = true
        break
      }
    }
    if !removed {
      filtered.push(relations[i])
    }
  }
  filtered
}

///|
pub fn append_relation(record : Json, kind : String, target : String) -> Unit {
  guard record is Object(record_object) else { return }
  match record_object.get("relations") {
    Some(Array(relations)) => push_unique_relation(relations, kind, target)
    _ => ()
  }
}

///|
pub fn append_relation_to_record_by_id(
  declarations : Array[Json],
  id : String,
  kind : String,
  target : String,
) -> Unit {
  if id == "" || kind == "" || target == "" {
    return
  }
  for i in 0..<declarations.length() {
    if field_string(declarations[i], "id") == id {
      append_relation(declarations[i], kind, target)
      return
    }
  }
}

///|
pub fn append_unique_string(values : Array[String], value : String) -> Unit {
  let trimmed = trim_spaces(value)
  if trimmed == "" {
    return
  }
  for i in 0..<values.length() {
    if values[i] == trimmed {
      return
    }
  }
  values.push(trimmed)
}

///|
pub fn contains_string(values : Array[String], target : String) -> Bool {
  for i in 0..<values.length() {
    if values[i] == target {
      return true
    }
  }
  false
}
