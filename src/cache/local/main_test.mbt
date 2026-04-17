///|
fn tmp_cache_root(name : String) -> String {
  "/tmp/cogna-cache-local-\{name}"
}

///|
fn cleanup_cache_root(root : String) -> Unit {
  @fs.remove_file("\{root}/objects") catch {
    _ => ()
  }
  @fs.remove_file("\{root}/meta") catch {
    _ => ()
  }
  @fs.remove_file("\{root}/index/keys.jsonl") catch {
    _ => ()
  }
  @fs.remove_dir("\{root}/index") catch {
    _ => ()
  }
  let object_hash = @sha256.sha256_hexdigest(@utf8.encode("blob/sha256/test"))
  @fs.remove_file("\{root}/objects/\{object_hash}.bin") catch {
    _ => ()
  }
  @fs.remove_file("\{root}/meta/\{object_hash}.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{root}/objects") catch {
    _ => ()
  }
  @fs.remove_dir("\{root}/meta") catch {
    _ => ()
  }
  @fs.remove_dir(root) catch {
    _ => ()
  }
}

///|
test "local cache put get list remove roundtrip" {
  let root = tmp_cache_root("roundtrip")
  cleanup_cache_root(root)

  let put_out = put(root, "blob/sha256/test", @utf8.encode("hello"))
  guard put_out is Ok(entry) else {
    cleanup_cache_root(root)
    fail("put should succeed")
  }
  inspect(entry.key, content="blob/sha256/test")

  let get_out = get(root, "blob/sha256/test")
  guard get_out is Ok(Some(object)) else {
    cleanup_cache_root(root)
    fail("get should return stored object")
  }
  inspect(@cache.bytes_to_string(object.body), content="hello")

  let list_out = list(root, prefix="blob/")
  guard list_out is Ok(entries) else {
    cleanup_cache_root(root)
    fail("list should succeed")
  }
  inspect(entries.length(), content="1")

  let remove_out = remove(root, "blob/sha256/test")
  guard remove_out is Ok(true) else {
    cleanup_cache_root(root)
    fail("remove should delete existing object")
  }

  let missing_out = get(root, "blob/sha256/test")
  guard missing_out is Ok(None) else {
    cleanup_cache_root(root)
    fail("removed object should be missing")
  }

  cleanup_cache_root(root)
}
