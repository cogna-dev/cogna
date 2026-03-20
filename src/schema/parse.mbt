///|
fn is_valid_type_name(name : String) -> Bool {
  name == "null" ||
  name == "boolean" ||
  name == "object" ||
  name == "array" ||
  name == "number" ||
  name == "string" ||
  name == "integer"
}

///|
fn join_path(base : String, key : String) -> String {
  if base == "$" {
    "$[\"\{key}\"]"
  } else {
    "\{base}[\"\{key}\"]"
  }
}

///|
fn validate_type_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  match value {
    String(type_name) =>
      if is_valid_type_name(type_name) {
        Ok(())
      } else {
        Err(InvalidSchema("\{path}: invalid type value \{type_name}"))
      }
    Array(type_names) => {
      if type_names.length() == 0 {
        return Err(InvalidSchema("\{path}: type array must be non-empty"))
      }
      for type_value in type_names {
        guard type_value is String(type_name) else {
          return Err(InvalidSchema("\{path}: type array must contain strings"))
        }
        if !is_valid_type_name(type_name) {
          return Err(InvalidSchema("\{path}: invalid type value \{type_name}"))
        }
      }
      Ok(())
    }
    _ => Err(InvalidSchema("\{path}: type must be string or array"))
  }
}

///|
fn validate_required_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard value is Array(names) else {
    return Err(InvalidSchema("\{path}: required must be array"))
  }
  for name in names {
    guard name is String(_) else {
      return Err(InvalidSchema("\{path}: required items must be strings"))
    }
  }
  Ok(())
}

///|
fn validate_properties_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard value is Object(properties) else {
    return Err(InvalidSchema("\{path}: properties must be object"))
  }
  for name, child_schema in properties {
    let child_path = join_path(path, name)
    let checked = validate_schema_json(child_schema, path=child_path)
    guard checked is Ok(_) else { return Err(checked.unwrap_err()) }
  }
  Ok(())
}

///|
fn validate_items_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  validate_schema_json(value, path~)
}

///|
fn validate_additional_properties_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  match value {
    True | False => Ok(())
    _ => validate_schema_json(value, path~)
  }
}

///|
fn validate_enum_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard value is Array(values) else {
    return Err(InvalidSchema("\{path}: enum must be array"))
  }
  if values.length() == 0 {
    return Err(InvalidSchema("\{path}: enum array must be non-empty"))
  }
  Ok(())
}

///|
fn validate_min_length_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard value is Number(number_value, ..) else {
    return Err(InvalidSchema("\{path}: minLength must be number"))
  }
  if number_value < 0.0 || number_value != number_value.to_int().to_double() {
    return Err(InvalidSchema("\{path}: minLength must be non-negative integer"))
  }
  Ok(())
}

///|
fn validate_min_items_keyword(
  value : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard value is Number(number_value, ..) else {
    return Err(InvalidSchema("\{path}: minItems must be number"))
  }
  if number_value < 0.0 || number_value != number_value.to_int().to_double() {
    return Err(InvalidSchema("\{path}: minItems must be non-negative integer"))
  }
  Ok(())
}

///|
pub fn validate_schema_json(
  schema : Json,
  path? : String = "$",
) -> Result[Unit, SchemaError] {
  match schema {
    True | False => Ok(())
    Object(object_schema) => {
      for key, value in object_schema {
        let key_path = join_path(path, key)
        let out = match key {
          "type" => validate_type_keyword(value, key_path)
          "required" => validate_required_keyword(value, key_path)
          "properties" => validate_properties_keyword(value, key_path)
          "items" => validate_items_keyword(value, key_path)
          "additionalProperties" =>
            validate_additional_properties_keyword(value, key_path)
          "enum" => validate_enum_keyword(value, key_path)
          "const" => Ok(())
          "minLength" => validate_min_length_keyword(value, key_path)
          "minItems" => validate_min_items_keyword(value, key_path)
          _ => Ok(())
        }
        guard out is Ok(_) else { return Err(out.unwrap_err()) }
      }
      Ok(())
    }
    _ => Err(InvalidSchema("\{path}: schema must be object or boolean"))
  }
}

///|
pub fn parse_schema_text(
  schema_text : String,
) -> Result[JsonSchema, SchemaError] {
  let parsed = try? @json.parse(schema_text)
  guard parsed is Ok(schema_json) else {
    return Err(SchemaParseError(parsed.unwrap_err().to_string()))
  }
  let checked = validate_schema_json(schema_json)
  guard checked is Ok(_) else { return Err(checked.unwrap_err()) }
  Ok(schema_json)
}
