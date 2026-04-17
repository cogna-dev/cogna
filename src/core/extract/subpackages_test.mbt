///|
test "extract go enrichment sets receiver metadata" {
  let record = make_declaration(
    "go-module", "gopls", "go", "pkg/main.go", 10, "method", "Hello", "func (s *Server) Hello(name string) error",
    "",
  )
  @go.enrich_record(record)
  inspect(
    language_specific_profile_string(record, "go", "receiver"),
    content="Server",
  )
  inspect(shape_string(record, "owner"), content="Server")
}

///|
test "extract rust enrichment sets impl metadata" {
  let record = make_declaration(
    "rust-crate", "rust-analyzer", "rust", "src/lib.rs", 12, "impl", "Display for User",
    "impl Display for User {", "",
  )
  @rust.enrich_record(record)
  inspect(
    language_specific_profile_string(record, "rust", "traitTarget"),
    content="Display",
  )
  inspect(
    language_specific_profile_string(record, "rust", "implTarget"),
    content="User",
  )
}
