///|
test "parse schema text accepts valid schema" {
  let schema_text =
    #|{
    #|  "type": "object",
    #|  "required": ["name"],
    #|  "properties": {
    #|    "name": { "type": "string" }
    #|  },
    #|  "additionalProperties": false
    #|}
  let parsed = parse_schema_text(schema_text)
  guard parsed is Ok(_) else { fail("expected valid schema to parse") }
}

///|
test "parse schema text rejects invalid type keyword" {
  let schema_text =
    #|{
    #|  "type": "something-else"
    #|}
  let parsed = parse_schema_text(schema_text)
  guard parsed is Err(error) else { fail("expected parse failure") }
  guard error.to_string().contains("invalid type value something-else") else {
    fail("expected invalid type error")
  }
}

///|
test "parse schema text rejects invalid required keyword" {
  let schema_text =
    #|{
    #|  "type": "object",
    #|  "required": [1]
    #|}
  let parsed = parse_schema_text(schema_text)
  guard parsed is Err(error) else { fail("expected parse failure") }
  guard error.to_string().contains("required items must be strings") else {
    fail("expected invalid required error")
  }
}

///|
test "parse schema text accepts boolean schema" {
  let parsed = parse_schema_text("false")
  guard parsed is Ok(False) else { fail("expected boolean schema") }
}
