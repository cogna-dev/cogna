///|
test "extract make_declaration adds canonical relations" {
  let record = make_declaration(
    "go-module", "gopls", "go", "pkg/main.go", 7, "function", "hello", "func hello(name string) string",
    "docs",
  )
  inspect(
    field_string(record, "id"),
    content="decl:go-module:go-module::pkg::main.go::hello",
  )
  inspect(shape_string(record, "form"), content="callable")
  inspect(
    language_specific_profile_string(record, "profile", "server"),
    content="",
  )
}

///|
test "extract state and emit helpers stay stable" {
  let records : Array[Json] = [
    { "id": "b", "name": "two" },
    { "id": "a", "name": "one" },
    { "id": "a", "name": "one-dup" },
  ]
  let sorted = sort_and_dedup(records, "id")
  inspect(sorted.length(), content="2")
  inspect(to_ndjson(sorted).contains("\"id\":\"a\""), content="true")
}
