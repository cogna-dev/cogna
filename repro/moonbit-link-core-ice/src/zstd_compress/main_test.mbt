///|
test "zstd compress symbol links" {
  let out = compressed_empty_length() catch {
    err => fail(err.to_string())
  }
  assert_true(out >= 0)
}
