///|
fn dbt_remove_dir_if_exists(path : String) -> Unit {
  @fs.remove_dir(path) catch {
    _ => ()
  }
}

///|
fn dbt_cleanup_registry() -> Unit {
  dbt_remove_dir_if_exists(".codeiq/registry/index")
  dbt_remove_dir_if_exists(".codeiq/registry/bundles")
  dbt_remove_dir_if_exists(".codeiq/registry/http")
  dbt_remove_dir_if_exists(".codeiq/registry")
  dbt_remove_dir_if_exists(".codeiq/cache/registry/index")
  dbt_remove_dir_if_exists(".codeiq/cache/registry/bundles")
  dbt_remove_dir_if_exists(".codeiq/cache/registry")
  dbt_remove_dir_if_exists(".codeiq/cache")
  dbt_remove_dir_if_exists(".codeiq")
  @sys.unset_env_var("CODEIQ_REGISTRY_BASE_URL")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_DOWNLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_REMOTE_UPLOAD_RESPONSE_JSON")
  @sys.unset_env_var("CODEIQ_REGISTRY_HEADER_If-None-Match")
}

///|
fn gzip_compress(payload : Bytes) -> Bytes {
  let gz = @gio.Buffer::new()
  let writer = @gzip.Writer::new(gz)
  let (_, write_out) = writer.write(@gio.Slice::new(payload.to_array()))
  guard write_out is None else { abort("failed to write gzip payload") }
  let close_out = writer.close()
  guard close_out is None else { abort("failed to close gzip payload") }
  gz.to_bytes()
}

///|
fn octal_field(value : Int, width : Int) -> String {
  let digits = value.reinterpret_as_uint().to_string(radix=8)
  if digits.length() + 1 >= width {
    digits + "\u0000"
  } else {
    let padding = String::make(width - digits.length() - 1, '0')
    padding + digits + "\u0000"
  }
}

///|
fn str_field(value : String, width : Int) -> String {
  let bytes = @utf8.encode(value)
  if bytes.length() >= width {
    let truncated = bytes[:width].to_bytes()
    @utf8.decode(truncated) catch {
      _ => value
    }
  } else {
    let padding = String::make(width - bytes.length(), '\u0000')
    value + padding
  }
}

///|
fn sum_header_bytes(header : Bytes) -> Int {
  let mut total = 0
  for i in 0..<header.length() {
    total = total + header[i].to_int()
  }
  total
}

///|
fn tar_header(name : String, size : Int) -> Bytes {
  let name_field = str_field(name, 100)
  let mode_field = octal_field(420, 8)
  let uid_field = octal_field(0, 8)
  let gid_field = octal_field(0, 8)
  let size_field = octal_field(size, 12)
  let mtime_field = octal_field(0, 12)
  let checksum_placeholder = "        "
  let type_flag = "0"
  let link_name = str_field("", 100)
  let magic = "ustar\u0000"
  let version = "00"
  let uname = str_field("", 32)
  let gname = str_field("", 32)
  let devmajor = octal_field(0, 8)
  let devminor = octal_field(0, 8)
  let prefix = str_field("", 155)
  let pad = String::make(12, '\u0000')
  let without_checksum = name_field +
    mode_field +
    uid_field +
    gid_field +
    size_field +
    mtime_field +
    checksum_placeholder +
    type_flag +
    link_name +
    magic +
    version +
    uname +
    gname +
    devmajor +
    devminor +
    prefix +
    pad
  let bytes = @utf8.encode(without_checksum)
  let checksum = sum_header_bytes(bytes)
  let checksum_field = octal_field(checksum, 8)
  let finalized = name_field +
    mode_field +
    uid_field +
    gid_field +
    size_field +
    mtime_field +
    checksum_field +
    type_flag +
    link_name +
    magic +
    version +
    uname +
    gname +
    devmajor +
    devminor +
    prefix +
    pad
  @utf8.encode(finalized)
}

///|
fn tar_entry(name : String, content : Bytes) -> Bytes {
  let header = tar_header(name, content.length())
  let payload = header.to_array()
  let content_array = content.to_array()
  for i in 0..<content_array.length() {
    payload.push(content_array[i])
  }
  let remainder = content.length() % 512
  if remainder != 0 {
    let pad = 512 - remainder
    for _ in 0..<pad {
      payload.push(b'\x00')
    }
  }
  Bytes::from_array(payload)
}

///|
fn tar_archive(entries : Array[(String, Bytes)]) -> Bytes {
  let out : Array[Byte] = []
  for i in 0..<entries.length() {
    let (name, content) = entries[i]
    let entry_bytes = tar_entry(name, content).to_array()
    for j in 0..<entry_bytes.length() {
      out.push(entry_bytes[j])
    }
  }
  for _ in 0..<1024 {
    out.push(b'\x00')
  }
  Bytes::from_array(out)
}

///|
test "registry run_download_bundle materializes local download into output directory" {
  let repo = "src/cmd/registry/tmp_registry_download_bundle"
  dbt_cleanup_registry()
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo)
  @fs.create_dir("\{repo}/dist")

  let purl = "pkg:generic/acme/demo@0.9.0"
  let manifest : Json = {
    "schemaVersion": "ciq-bundle/v1",
    "purl": purl,
    "profile": "openapi-spec",
    "declarationSchema": {
      "version": "ciq-declarations/v1",
      "format": "ndjson.zst",
      "model": "signature + shape + language_specific tagged union",
    },
    "source": {
      "repo": "https://github.com/acme/demo",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      {
        "path": "declarations.ndjson.zst",
        "sha256": "x",
        "compression": "zstd",
      },
      { "path": "symbols.ndjson.zst", "sha256": "y", "compression": "zstd" },
    ],
  }
  let declarations_text =
    #|{"id":"decl:a","kind":"function","path":"a.go","signature":"fn a","location":{"uri":"a.go","startLine":1,"endLine":1}}
    #|
  let symbols_text =
    #|{"id":"decl:a","selector":"pkg:generic/acme/demo@0.9.0#a.go#fn:a","name":"a","kind":"function"}
    #|
  let declarations = @zstd.compress(@utf8.encode(declarations_text))
  let symbols = @zstd.compress(@utf8.encode(symbols_text))
  let tar_payload = tar_archive([
    ("manifest.json", @utf8.encode(manifest.stringify(indent=2))),
    ("declarations.ndjson.zst", declarations),
    ("symbols.ndjson.zst", symbols),
    ("metadata.json", @utf8.encode("{}\n")),
    ("checksums.txt", @utf8.encode("manifest.json  x\n")),
  ])
  let bundle_bytes = gzip_compress(tar_payload)
  let bundle_path = "\{repo}/dist/bundle.ciq.tgz"
  @fs.write_bytes_to_file(bundle_path, bundle_bytes) catch {
    _ => abort("failed to write bundle fixture")
  }

  let request : Json = {
    "schemaVersion": "codeiq-registry-upload/v1",
    "endpoint": "POST /api/v1/bundles",
    "bundleFile": bundle_path,
    "bundleType": "ciq-bundle",
    "purl": purl,
    "digest": "sha256:\{@sha256.sha256_hexdigest(bundle_bytes)}",
    "size": bundle_bytes.length(),
  }
  let upload_out = upload_local(request)
  guard upload_out is Ok(_) else {
    dbt_cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("upload_local should succeed")
  }

  let out_dir = "\{repo}/out"
  let run_out = run_download_bundle({ purl, output_dir: out_dir })
  guard run_out is Ok(result) else {
    dbt_cleanup_registry()
    @fs.remove_dir(repo) catch {
      _ => ()
    }
    fail("run_download_bundle should succeed")
  }
  assert_true(result.summary.contains("Downloaded and materialized bundle"))
  assert_true(@fs.path_exists("\{out_dir}/manifest.json"))
  assert_true(@fs.path_exists("\{out_dir}/declarations.ndjson.zst"))
  assert_true(@fs.path_exists("\{out_dir}/symbols.ndjson.zst"))
  assert_true(@fs.path_exists("\{out_dir}/metadata.json"))
  assert_true(@fs.path_exists("\{out_dir}/checksums.txt"))

  dbt_cleanup_registry()
  @fs.remove_file("\{out_dir}/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{out_dir}/declarations.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{out_dir}/symbols.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_file("\{out_dir}/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{out_dir}/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_dir(out_dir) catch {
    _ => ()
  }
  @fs.remove_file(bundle_path) catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}
