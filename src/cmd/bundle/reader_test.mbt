///|
test "bundle reader parses valid manifest" {
  let repo = "src/cmd/bundle/tmp_bundle_reader"
  @fs.remove_file("\{repo}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo) catch {
    _ => fail("failed to create repo")
  }
  @fs.create_dir("\{repo}/dist") catch {
    _ => fail("failed to create dist")
  }

  let manifest : Json = {
    "schemaVersion": "ciq-bundle/v1",
    "purl": "pkg:openapi/acme/payment-api@2026.03.01",
      "profile": "openapi-spec",
      "declarationSchema": {
        "version": "ciq-declarations/v1",
        "format": "ndjson",
        "model": "signature + shape + language_specific tagged union",
      },
    "source": {
      "repo": "https://github.com/acme/payment-api",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      {
        "path": "declarations.ndjson",
        "sha256": "x",
        "compression": "none",
      },
    ],
  }
  @fs.write_string_to_file(
    "\{repo}/dist/manifest.json",
    manifest.stringify(indent=2),
  ) catch {
    _ => fail("failed to write manifest")
  }

  let out = read_manifest("\{repo}/dist/manifest.json")
  guard out is Ok(parsed) else { fail("expected manifest to parse") }
  inspect(parsed.purl, content="pkg:openapi/acme/payment-api@2026.03.01")
  inspect(parsed.artifacts.length(), content="1")

  @fs.remove_file("\{repo}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "bundle reader parses valid opa manifest" {
  let repo = "src/cmd/bundle/tmp_bundle_reader_opa"
  @fs.remove_file("\{repo}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo) catch {
    _ => fail("failed to create repo")
  }
  @fs.create_dir("\{repo}/dist") catch {
    _ => fail("failed to create dist")
  }

  let manifest : Json = {
    "schemaVersion": "ciq-opa-bundle/v1",
    "purl": "pkg:generic/acme/compat-policy@2026.03.01",
    "profile": "policy-bundle",
    "source": {
      "repo": "https://github.com/acme/compat-policy",
      "ref": "main",
      "commit": "abc",
    },
    "opa": {
      "entrypoint": "codeiq/compat/deny",
      "format": "opa-bundle.tar.gz",
    },
    "provenance": {
      "checksums": "checksums.txt",
      "signature": {
        "status": "unsigned",
        "algorithm": "sha256",
      },
    },
    "artifacts": [
      {
        "path": "declarations.ndjson",
        "sha256": "x",
        "compression": "none",
      },
      { "path": "opa-bundle.tar.gz", "sha256": "y", "compression": "gzip" },
    ],
  }
  @fs.write_string_to_file(
    "\{repo}/dist/manifest.json",
    manifest.stringify(indent=2),
  ) catch {
    _ => fail("failed to write manifest")
  }

  let out = read_manifest("\{repo}/dist/manifest.json")
  guard out is Ok(parsed) else { fail("expected opa manifest to parse") }
  inspect(parsed.schema_version, content="ciq-opa-bundle/v1")
  inspect(parsed.profile, content="policy-bundle")
  inspect(parsed.artifacts.length(), content="2")

  @fs.remove_file("\{repo}/dist/manifest.json") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}

///|
test "bundle reader parses ndjson" {
  let repo = "src/cmd/bundle/tmp_bundle_reader_ndjson"
  @fs.remove_file("\{repo}/dist/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo) catch {
    _ => fail("failed to create repo")
  }
  @fs.create_dir("\{repo}/dist") catch {
    _ => fail("failed to create dist")
  }

  let declarations =
    #|{"id":"decl:a","kind":"function","path":"a.go","signature":"fn a","location":{"uri":"a.go","startLine":1,"endLine":1}}
    #|{"id":"decl:b","kind":"function","path":"b.go","signature":"fn b","location":{"uri":"b.go","startLine":2,"endLine":2}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => fail("failed to write declarations")
  }

  let out = read_bundle_declarations(repo)
  guard out is Ok(records) else { fail("expected records") }
  inspect(records.length(), content="2")

  @fs.remove_file("\{repo}/dist/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
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
test "bundle reader materializes bundle tar.gz into dist" {
  let repo = "src/cmd/bundle/tmp_bundle_materialize"
  @fs.remove_file("\{repo}/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/out") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
  @fs.create_dir(repo) catch {
    _ => fail("failed to create repo")
  }

  let manifest : Json = {
    "schemaVersion": "ciq-bundle/v1",
    "purl": "pkg:generic/acme/demo@0.5.0",
    "profile": "openapi-spec",
    "declarationSchema": {
      "version": "ciq-declarations/v1",
      "format": "ndjson",
      "model": "signature + shape + language_specific tagged union",
    },
    "source": {
      "repo": "https://github.com/acme/demo",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      {
        "path": "declarations.ndjson",
        "sha256": "x",
        "compression": "none",
      },
      { "path": "symbols.ndjson", "sha256": "y", "compression": "none" },
    ],
  }
  let declarations_text =
    #|{"id":"decl:a","kind":"function","path":"a.go","signature":"fn a","location":{"uri":"a.go","startLine":1,"endLine":1}}
    #|
  let symbols_text =
    #|{"id":"decl:a","selector":"pkg:generic/acme/demo@0.5.0#a.go#fn:a","name":"a","kind":"function"}
    #|
  let tar_payload = tar_archive([
    ("manifest.json", @utf8.encode(manifest.stringify(indent=2))),
    ("declarations.ndjson", @utf8.encode(declarations_text)),
    ("symbols.ndjson", @utf8.encode(symbols_text)),
    ("metadata.json", @utf8.encode("{}\n")),
    ("checksums.txt", @utf8.encode("manifest.json  x\n")),
  ])
  let bundle_bytes = gzip_compress(tar_payload)
  let bundle_path = "\{repo}/bundle.ciq.tgz"
  @fs.write_bytes_to_file(bundle_path, bundle_bytes) catch {
    _ => fail("failed to write bundle")
  }

  let materialize_out = materialize_bundle_tar_gz(bundle_path, "\{repo}/out")
  guard materialize_out is Ok(_) else { fail("materialize should succeed") }
  assert_true(@fs.path_exists("\{repo}/out/manifest.json"))
  assert_true(@fs.path_exists("\{repo}/out/declarations.ndjson"))
  assert_true(@fs.path_exists("\{repo}/out/symbols.ndjson"))
  assert_true(@fs.path_exists("\{repo}/out/metadata.json"))
  assert_true(@fs.path_exists("\{repo}/out/checksums.txt"))

  @fs.remove_file("\{repo}/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/symbols.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/metadata.json") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/checksums.txt") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/out") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}
