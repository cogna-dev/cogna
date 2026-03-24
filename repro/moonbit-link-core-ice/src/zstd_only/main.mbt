///|
pub fn roundtrip(input : String) -> String raise {
  let compressed = @zstd.compress(@utf8.encode(input))
  let decompressed = @zstd.decompress(compressed)
  @utf8.decode(decompressed)
}
