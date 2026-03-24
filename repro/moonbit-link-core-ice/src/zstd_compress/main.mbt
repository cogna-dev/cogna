///|
pub fn compressed_empty_length() -> Int raise {
  @zstd.compress(b"").length()
}
