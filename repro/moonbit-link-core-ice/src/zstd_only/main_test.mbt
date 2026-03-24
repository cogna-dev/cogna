///|
test "zstd roundtrip works" {
  let out = roundtrip("hello link core") catch {
    err => fail(err.to_string())
  }
  inspect(out, content="hello link core")
}
