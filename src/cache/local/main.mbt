///|
fn key_hash(key : String) -> String {
  @sha256.sha256_hexdigest(@utf8.encode(key))
}

///|
fn object_path(root : String, key : String) -> String {
  "\{root}/objects/\{key_hash(key)}.bin"
}

///|
fn metadata_path(root : String, key : String) -> String {
  "\{root}/meta/\{key_hash(key)}.json"
}

///|
fn keys_index_path(root : String) -> String {
  "\{root}/index/keys.jsonl"
}

///|
fn ensure_dir(path : String) -> Result[Unit, String] {
  if @fs.path_exists(path) {
    Ok(())
  } else {
    @fs.create_dir(path) catch {
      err => return Err("cannot create directory \{path}: \{err.to_string()}")
    }
    Ok(())
  }
}

///|
fn ensure_nested_dir(path : String) -> Result[Unit, String] {
  let parts = path.split("/").to_array()
  let mut current = if path.has_prefix("/") { "/" } else { "" }
  for i in 0..<parts.length() {
    let segment = parts[i].to_string()
    if segment == "" {
      continue
    }
    current = if current == "" || current == "/" {
      if current == "/" {
        "/\{segment}"
      } else {
        segment
      }
    } else {
      "\{current}/\{segment}"
    }
    let out = ensure_dir(current)
    guard out is Ok(_) else { return Err(out.unwrap_err()) }
  }
  Ok(())
}

///|
pub fn ensure_store(root : String) -> Result[Unit, String] {
  let root_out = ensure_nested_dir(root)
  guard root_out is Ok(_) else { return Err(root_out.unwrap_err()) }
  let objects_out = ensure_dir("\{root}/objects")
  guard objects_out is Ok(_) else { return Err(objects_out.unwrap_err()) }
  let meta_out = ensure_dir("\{root}/meta")
  guard meta_out is Ok(_) else { return Err(meta_out.unwrap_err()) }
  let index_out = ensure_dir("\{root}/index")
  guard index_out is Ok(_) else { return Err(index_out.unwrap_err()) }
  if !@fs.path_exists(keys_index_path(root)) {
    @fs.write_string_to_file(keys_index_path(root), "") catch {
      err =>
        return Err(
          "cannot initialize cache index \{keys_index_path(root)}: \{err.to_string()}"
        )
    }
  }
  Ok(())
}

///|
fn metadata_json(key : String, body : Bytes, content_type : String) -> Json {
  {
    "key": key,
    "size": body.length(),
    "contentType": content_type,
    "digest": @sha256.sha256_hexdigest(body),
  }
}

///|
fn append_key(root : String, key : String) -> Result[Unit, String] {
  let current = @fs.read_file_to_string(keys_index_path(root)) catch {
    err => return Err("cannot read cache index: \{err.to_string()}")
  }
  let lines = if current == "" { [] } else { current.split("\n").to_array() }
  for i in 0..<lines.length() {
    if lines[i] == key {
      return Ok(())
    }
  }
  let next = if current == "" { "\{key}\n" } else { "\{current}\{key}\n" }
  @fs.write_string_to_file(keys_index_path(root), next) catch {
    err => return Err("cannot update cache index: \{err.to_string()}")
  }
  Ok(())
}

///|
pub fn put(
  root : String,
  key : String,
  body : Bytes,
  content_type? : String = @cache.default_content_type(),
) -> Result[@cache.CacheEntry, String] {
  let store_out = ensure_store(root)
  guard store_out is Ok(_) else { return Err(store_out.unwrap_err()) }
  @fs.write_bytes_to_file(object_path(root, key), body) catch {
    err => return Err("cannot write cache object \{key}: \{err.to_string()}")
  }
  @fs.write_string_to_file(
    metadata_path(root, key),
    metadata_json(key, body, content_type).stringify(indent=2),
  ) catch {
    err => return Err("cannot write cache metadata \{key}: \{err.to_string()}")
  }
  let index_out = append_key(root, key)
  guard index_out is Ok(_) else { return Err(index_out.unwrap_err()) }
  Ok({
    key,
    size: body.length(),
    content_type,
    digest: @sha256.sha256_hexdigest(body),
  })
}

///|
pub fn get(root : String, key : String) -> Result[@cache.CacheObject?, String] {
  let body_path = object_path(root, key)
  let meta_path = metadata_path(root, key)
  if !@fs.path_exists(body_path) || !@fs.path_exists(meta_path) {
    return Ok(None)
  }
  let body = @fs.read_file_to_bytes(body_path) catch {
    err => return Err("cannot read cache object \{key}: \{err.to_string()}")
  }
  let metadata_text = @fs.read_file_to_string(meta_path) catch {
    err => return Err("cannot read cache metadata \{key}: \{err.to_string()}")
  }
  let parsed = try? @json.parse(metadata_text)
  guard parsed is Ok(Object(metadata)) else {
    return Err("invalid cache metadata for \{key}")
  }
  let content_type = match metadata.get("contentType") {
    Some(String(value)) if value != "" => value
    _ => @cache.default_content_type()
  }
  let digest = match metadata.get("digest") {
    Some(String(value)) => value
    _ => @sha256.sha256_hexdigest(body)
  }
  Ok(Some({ key, body, content_type, digest }))
}

///|
fn parse_entry(root : String, key : String) -> @cache.CacheEntry? {
  let path = metadata_path(root, key)
  if !@fs.path_exists(path) {
    return None
  }
  let text = @fs.read_file_to_string(path) catch { _ => return None }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(Object(metadata)) else { return None }
  let size = match metadata.get("size") {
    Some(Number(value, ..)) => value.to_int()
    _ => 0
  }
  let content_type = match metadata.get("contentType") {
    Some(String(value)) if value != "" => value
    _ => @cache.default_content_type()
  }
  let digest = match metadata.get("digest") {
    Some(String(value)) => value
    _ => ""
  }
  Some({ key, size, content_type, digest })
}

///|
pub fn list(root : String, prefix? : String = "") -> Result[Array[@cache.CacheEntry], String] {
  let store_out = ensure_store(root)
  guard store_out is Ok(_) else { return Err(store_out.unwrap_err()) }
  let text = @fs.read_file_to_string(keys_index_path(root)) catch {
    err => return Err("cannot read cache index: \{err.to_string()}")
  }
  let seen : Map[String, Bool] = {}
  let entries : Array[@cache.CacheEntry] = []
  for raw_key in text.split("\n") {
    let key = raw_key.to_string().trim().to_string()
    if key == "" || seen.contains(key) {
      continue
    }
    seen[key] = true
    if prefix != "" && !key.has_prefix(prefix) {
      continue
    }
    match parse_entry(root, key) {
      Some(entry) => entries.push(entry)
      None => ()
    }
  }
  entries.sort_by(fn(a, b) { a.key.compare(b.key) })
  Ok(entries)
}

///|
pub fn remove(root : String, key : String) -> Result[Bool, String] {
  let store_out = ensure_store(root)
  guard store_out is Ok(_) else { return Err(store_out.unwrap_err()) }
  let existed = @fs.path_exists(object_path(root, key)) ||
    @fs.path_exists(metadata_path(root, key))
  if @fs.path_exists(object_path(root, key)) {
    @fs.remove_file(object_path(root, key)) catch {
      err => return Err("cannot remove cache object \{key}: \{err.to_string()}")
    }
  }
  if @fs.path_exists(metadata_path(root, key)) {
    @fs.remove_file(metadata_path(root, key)) catch {
      err =>
        return Err("cannot remove cache metadata \{key}: \{err.to_string()}")
    }
  }
  let text = @fs.read_file_to_string(keys_index_path(root)) catch {
    err => return Err("cannot read cache index: \{err.to_string()}")
  }
  let kept : Array[String] = []
  for raw_key in text.split("\n") {
    let current = raw_key.to_string().trim().to_string()
    if current != "" && current != key {
      kept.push(current)
    }
  }
  let next = if kept.is_empty() { "" } else { kept.join("\n") + "\n" }
  @fs.write_string_to_file(keys_index_path(root), next) catch {
    err => return Err("cannot rewrite cache index: \{err.to_string()}")
  }
  Ok(existed)
}
