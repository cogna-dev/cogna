///|
pub fn compressed_empty() -> Bytes raise {
  @zstd.compress(b"")
}
