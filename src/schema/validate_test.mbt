///|
fn must_parse_schema(text : String) -> JsonSchema {
  let parsed = parse_schema_text(text)
  guard parsed is Ok(schema) else { abort("schema parse failed") }
  schema
}

///|
fn must_parse_json(text : String) -> Json {
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else { abort("json parse failed") }
  value
}

///|
fn expect_validation_failure_contains(
  schema : JsonSchema,
  instance : Json,
  expected : String,
) -> Unit {
  let out = validate_json(schema, instance)
  guard out is Err(error) else { abort("expected validation failure") }
  guard error.to_string().contains(expected) else {
    abort("expected error to contain message")
  }
}

///|
test "validate type string and integer" {
  let schema = must_parse_schema("{\"type\":\"integer\"}")
  let int_value = must_parse_json("10")
  let float_value = must_parse_json("10.5")
  guard validate_json(schema, int_value) is Ok(_) else {
    fail("integer should pass integer schema")
  }
  expect_validation_failure_contains(
    schema, float_value, "expected type integer",
  )
}

///|
test "validate type array" {
  let schema = must_parse_schema("{\"type\":[\"string\",\"number\"]}")
  let value_ok = must_parse_json("\"abc\"")
  let value_bad = must_parse_json("true")
  guard validate_json(schema, value_ok) is Ok(_) else {
    fail("string should pass union type")
  }
  expect_validation_failure_contains(
    schema, value_bad, "instance does not match any type in type array",
  )
}

///|
test "validate enum and const" {
  let enum_schema = must_parse_schema("{\"enum\":[\"a\",\"b\"]}")
  let const_schema = must_parse_schema("{\"const\":\"fixed\"}")
  guard validate_json(enum_schema, must_parse_json("\"a\"")) is Ok(_) else {
    fail("enum value should pass")
  }
  expect_validation_failure_contains(
    enum_schema,
    must_parse_json("\"c\""),
    "value is not in enum",
  )
  guard validate_json(const_schema, must_parse_json("\"fixed\"")) is Ok(_) else {
    fail("const value should pass")
  }
  expect_validation_failure_contains(
    const_schema,
    must_parse_json("\"other\""),
    "value does not match const",
  )
}

///|
test "validate object required properties and additionalProperties false" {
  let schema = must_parse_schema(
    (
      #|{
      #|  "type": "object",
      #|  "required": ["name"],
      #|  "properties": {
      #|    "name": { "type": "string", "minLength": 1 },
      #|    "age": { "type": "integer" }
      #|  },
      #|  "additionalProperties": false
      #|}
    ),
  )

  guard validate_json(
      schema,
      must_parse_json("{\"name\":\"Alice\",\"age\":10}"),
    )
    is Ok(_) else {
    fail("object with expected fields should pass")
  }

  expect_validation_failure_contains(
    schema,
    must_parse_json("{\"age\":10}"),
    "missing required property name",
  )

  expect_validation_failure_contains(
    schema,
    must_parse_json("{\"name\":\"Alice\",\"extra\":1}"),
    "additional property extra is not allowed",
  )
}

///|
test "validate array items and minItems" {
  let schema = must_parse_schema(
    (
      #|{
      #|  "type": "array",
      #|  "minItems": 2,
      #|  "items": { "type": "string", "minLength": 2 }
      #|}
    ),
  )

  guard validate_json(schema, must_parse_json("[\"ab\",\"cd\"]")) is Ok(_) else {
    fail("valid array should pass")
  }

  expect_validation_failure_contains(
    schema,
    must_parse_json("[\"ab\"]"),
    "array length is less than minItems",
  )

  expect_validation_failure_contains(
    schema,
    must_parse_json("[\"a\",\"cd\"]"),
    "string length is less than minLength",
  )
}

///|
test "validate additionalProperties schema object" {
  let schema = must_parse_schema(
    (
      #|{
      #|  "type": "object",
      #|  "properties": {
      #|    "name": { "type": "string" }
      #|  },
      #|  "additionalProperties": { "type": "string" }
      #|}
    ),
  )

  guard validate_json(schema, must_parse_json("{\"name\":\"A\",\"x\":\"ok\"}"))
    is Ok(_) else {
    fail("string additional property should pass")
  }

  expect_validation_failure_contains(
    schema,
    must_parse_json("{\"name\":\"A\",\"x\":1}"),
    "expected type string",
  )
}
