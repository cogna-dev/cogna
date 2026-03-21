///|
fn issue(path : String, message : String) -> Result[Unit, SchemaError] {
  Err(ValidationFailed([{ path, message }]))
}

///|
fn child_property_path(base : String, key : String) -> String {
  if base == "$" {
    "$.\{key}"
  } else {
    "\{base}.\{key}"
  }
}

///|
fn child_index_path(base : String, index : Int) -> String {
  "\{base}[\{index}]"
}

///|
fn is_integer_number(value : Double) -> Bool {
  value == value.to_int().to_double()
}

///|
fn matches_type_name(type_name : String, instance : Json) -> Bool {
  match type_name {
    "null" => instance is Null
    "boolean" => instance is True || instance is False
    "object" => instance is Object(_)
    "array" => instance is Array(_)
    "number" => instance is Number(_, ..)
    "string" => instance is String(_)
    "integer" =>
      match instance {
        Number(number_value, ..) => is_integer_number(number_value)
        _ => false
      }
    _ => false
  }
}

///|
fn validate_type_constraint(
  type_schema : Json,
  instance : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  match type_schema {
    String(type_name) =>
      if matches_type_name(type_name, instance) {
        Ok(())
      } else {
        issue(path, "expected type \{type_name}")
      }
    Array(type_names) => {
      for type_name_json in type_names {
        guard type_name_json is String(type_name) else {
          return issue(path, "schema type array contains non-string")
        }
        if matches_type_name(type_name, instance) {
          return Ok(())
        }
      }
      issue(path, "instance does not match any type in type array")
    }
    _ => issue(path, "schema type must be string or array")
  }
}

///|
fn validate_enum_constraint(
  enum_schema : Json,
  instance : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard enum_schema is Array(options) else {
    return issue(path, "schema enum must be array")
  }
  for option in options {
    if option == instance {
      return Ok(())
    }
  }
  issue(path, "value is not in enum")
}

///|
fn validate_const_constraint(
  const_schema : Json,
  instance : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  if const_schema == instance {
    Ok(())
  } else {
    issue(path, "value does not match const")
  }
}

///|
fn validate_string_keywords(
  schema_object : Map[String, Json],
  instance : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard instance is String(string_value) else { return Ok(()) }
  if schema_object.get("minLength") is Some(Number(min_length, ..)) {
    if string_value.length() < min_length.to_int() {
      return issue(path, "string length is less than minLength")
    }
  }
  Ok(())
}

///|
fn validate_array_keywords(
  schema_object : Map[String, Json],
  instance : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard instance is Array(items) else { return Ok(()) }

  if schema_object.get("minItems") is Some(Number(min_items, ..)) {
    if items.length() < min_items.to_int() {
      return issue(path, "array length is less than minItems")
    }
  }

  if schema_object.get("items") is Some(item_schema) {
    for i in 0..<items.length() {
      let child_path = child_index_path(path, i)
      let validated = validate_json(item_schema, items[i], path=child_path)
      guard validated is Ok(_) else { return Err(validated.unwrap_err()) }
    }
  }

  Ok(())
}

///|
fn validate_object_keywords(
  schema_object : Map[String, Json],
  instance : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  guard instance is Object(object_instance) else { return Ok(()) }

  if schema_object.get("required") is Some(Array(required_fields)) {
    for required_field in required_fields {
      guard required_field is String(required_name) else {
        return issue(path, "schema required entries must be strings")
      }
      if object_instance.get(required_name) is None {
        return issue(path, "missing required property \{required_name}")
      }
    }
  }

  let property_schema_map = match schema_object.get("properties") {
    Some(Object(property_schema_map)) => property_schema_map
    _ => Map::new()
  }

  for name, value in object_instance {
    if property_schema_map.get(name) is Some(property_schema) {
      let child_path = child_property_path(path, name)
      let validated = validate_json(property_schema, value, path=child_path)
      guard validated is Ok(_) else { return Err(validated.unwrap_err()) }
      continue
    }

    if schema_object.get("additionalProperties") is Some(additional_schema) {
      match additional_schema {
        False =>
          return issue(path, "additional property \{name} is not allowed")
        True => ()
        _ => {
          let child_path = child_property_path(path, name)
          let validated = validate_json(
            additional_schema,
            value,
            path=child_path,
          )
          guard validated is Ok(_) else { return Err(validated.unwrap_err()) }
        }
      }
    }
  }

  Ok(())
}

///|
fn validate_object_schema(
  schema_object : Map[String, Json],
  instance : Json,
  path : String,
) -> Result[Unit, SchemaError] {
  if schema_object.get("type") is Some(type_schema) {
    let out = validate_type_constraint(type_schema, instance, path)
    guard out is Ok(_) else { return Err(out.unwrap_err()) }
  }

  if schema_object.get("enum") is Some(enum_schema) {
    let out = validate_enum_constraint(enum_schema, instance, path)
    guard out is Ok(_) else { return Err(out.unwrap_err()) }
  }

  if schema_object.get("const") is Some(const_schema) {
    let out = validate_const_constraint(const_schema, instance, path)
    guard out is Ok(_) else { return Err(out.unwrap_err()) }
  }

  let string_out = validate_string_keywords(schema_object, instance, path)
  guard string_out is Ok(_) else { return Err(string_out.unwrap_err()) }

  let array_out = validate_array_keywords(schema_object, instance, path)
  guard array_out is Ok(_) else { return Err(array_out.unwrap_err()) }

  let object_out = validate_object_keywords(schema_object, instance, path)
  guard object_out is Ok(_) else { return Err(object_out.unwrap_err()) }

  Ok(())
}

///|
pub fn validate_json(
  schema : JsonSchema,
  instance : Json,
  path? : String = "$",
) -> Result[Unit, SchemaError] {
  match schema {
    True => Ok(())
    False => issue(path, "schema is false")
    Object(schema_object) =>
      validate_object_schema(schema_object, instance, path)
    _ => issue(path, "schema must be object or boolean")
  }
}
