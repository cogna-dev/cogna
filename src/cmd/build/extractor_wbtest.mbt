///|
fn validation_decl(path : String, kind : String, name : String) -> Json {
  { "path": path, "kind": kind, "name": name }
}

///|
test "inventory validation declarations ignore Go test files only" {
  let declarations : Array[Json] = [
    validation_decl("main.go", "function", "Hello"),
    validation_decl("helper_test.go", "function", "TestOnly"),
    validation_decl("nested/example_test.go", "struct", "Example"),
  ]
  let filtered = inventory_validation_declarations("go-module", declarations)
  assert_eq(filtered.length(), 1)
  assert_eq(@extract.field_string(filtered[0], "path"), "main.go")
  assert_eq(@extract.field_string(filtered[0], "name"), "Hello")
}

///|
test "inventory validation declarations keep non-Go profiles unchanged" {
  let declarations : Array[Json] = [
    validation_decl("lib.rs", "function", "hello"),
    validation_decl("helper_test.go", "function", "still_here"),
  ]
  let filtered = inventory_validation_declarations("rust-crate", declarations)
  assert_eq(filtered.length(), 2)
}


