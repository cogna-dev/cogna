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
      "format": "ndjson.zst",
      "model": "signature + shape + language_specific tagged union",
    },
    "source": {
      "repo": "https://github.com/acme/payment-api",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      {
        "path": "declarations.ndjson.zst",
        "sha256": "x",
        "compression": "zstd",
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
test "bundle reader parses ndjson" {
  let repo = "src/cmd/bundle/tmp_bundle_reader_ndjson"
  @fs.remove_file("\{repo}/dist/declarations.ndjson.zst") catch {
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
  let compressed = @zstd.compress(@utf8.encode(declarations)) catch {
    _ => fail("failed to compress declarations")
  }
  @fs.write_bytes_to_file("\{repo}/dist/declarations.ndjson.zst", compressed) catch {
    _ => fail("failed to write declarations")
  }

  let out = read_bundle_declarations(repo)
  guard out is Ok(records) else { fail("expected records") }
  inspect(records.length(), content="2")

  @fs.remove_file("\{repo}/dist/declarations.ndjson.zst") catch {
    _ => ()
  }
  @fs.remove_dir("\{repo}/dist") catch {
    _ => ()
  }
  @fs.remove_dir(repo) catch {
    _ => ()
  }
}
