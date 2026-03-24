///|
test "direct zstd compress in blackbox test" {
  let out : Result[Bytes, Error] = try? @zstd.compress(b"")
  guard out is Ok(compressed) else {
    fail("compress failed")
  }
  assert_true(compressed.length() >= 0)
}
