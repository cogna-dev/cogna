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
      "format": "ndjson",
      "model": "signature + shape + language_specific tagged union",
    },
    "source": {
      "repo": "https://github.com/acme/demo",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      { "path": "declarations.ndjson", "sha256": "x", "compression": "none" },
      { "path": "symbols.ndjson", "sha256": "y", "compression": "none" },
    ],
  }
  let declarations_text =
    #|{"id":"decl:a","kind":"function","path":"a.go","signature":"fn a","location":{"uri":"a.go","startLine":1,"endLine":1}}
    #|
  let symbols_text =
    #|{"id":"decl:a","selector":"pkg:generic/acme/demo@0.9.0#a.go#fn:a","name":"a","kind":"function"}
    #|
  let tar_payload = tar_archive([
    ("manifest.json", @utf8.encode(manifest.stringify(indent=2))),
    ("declarations.ndjson", @utf8.encode(declarations_text)),
    ("symbols.ndjson", @utf8.encode(symbols_text)),
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
  assert_true(@fs.path_exists("\{out_dir}/declarations.ndjson"))
  assert_true(@fs.path_exists("\{out_dir}/symbols.ndjson"))
  assert_true(@fs.path_exists("\{out_dir}/metadata.json"))
  assert_true(@fs.path_exists("\{out_dir}/checksums.txt"))

  dbt_cleanup_registry()
  @fs.remove_file("\{out_dir}/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{out_dir}/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{out_dir}/symbols.ndjson") catch {
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
