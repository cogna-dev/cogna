///|
pub(all) struct CacheObject {
  key : String
  body : Bytes
  content_type : String
  digest : String
} derive(Eq)

///|
pub impl Show for CacheObject with output(self, logger) {
  logger.write_string("{key: ")
  logger.write_object(self.key)
  logger.write_string(", body_size: ")
  logger.write_object(self.body.length())
  logger.write_string(", content_type: ")
  logger.write_object(self.content_type)
  logger.write_string(", digest: ")
  logger.write_object(self.digest)
  logger.write_char('}')
}

///|
pub(all) struct CacheEntry {
  key : String
  size : Int
  content_type : String
  digest : String
} derive(Eq)

///|
pub impl Show for CacheEntry with output(self, logger) {
  logger.write_string("{key: ")
  logger.write_object(self.key)
  logger.write_string(", size: ")
  logger.write_object(self.size)
  logger.write_string(", content_type: ")
  logger.write_object(self.content_type)
  logger.write_string(", digest: ")
  logger.write_object(self.digest)
  logger.write_char('}')
}

///|
pub fn default_content_type() -> String {
  "application/octet-stream"
}

///|
pub fn bytes_to_string(value : Bytes) -> String {
  @utf8.decode(value) catch {
    _ => ""
  }
}
