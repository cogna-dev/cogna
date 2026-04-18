///|
test "bundle reader parses valid manifest" {
  let repo = "/tmp/cogna-bundle-reader"
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
    "source": {
      "repo": "https://github.com/acme/payment-api",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      { "path": "declarations.ndjson", "sha256": "x", "compression": "none" },
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
  let repo = "/tmp/cogna-bundle-reader-opa"
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
    "opa": { "entrypoint": "cogna/compat/deny", "format": "opa-bundle.tar.gz" },
    "provenance": {
      "checksums": "checksums.txt",
      "signature": { "status": "unsigned", "algorithm": "sha256" },
    },
    "artifacts": [
      { "path": "declarations.ndjson", "sha256": "x", "compression": "none" },
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
  let repo = "/tmp/cogna-bundle-reader-ndjson"
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
test "bundle reader accepts richer declaration ndjson" {
  let repo = "/tmp/cogna-bundle-reader-rich-ndjson"
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
    #|{"id":"decl:go-module:go-module::main.go::Greet","kind":"method","name":"Greet","canonical_name":"go-module::main.go::Greet","path":"main.go","signature":"func (g *Greeter) Greet(name string) Message {","shape":{"kind":"method","subkind":"method","form":"callable","signature":"func (g *Greeter) Greet(name string) Message {","owner":"Greeter","parameters":["string"],"returns":["Message"]},"visibility":"public","docs":"","baselineRole":"baseline","language":"go","source_refs":[{"uri":"main.go","startLine":58,"endLine":58}],"relations":[{"kind":"declared_in","target":"file:main.go"},{"kind":"has_parameter","target":"type:go-module::string"},{"kind":"returns","target":"type:go-module::Message"}],"location":{"uri":"main.go","startLine":58,"endLine":58},"language_specific":{"profile":"go-module","server":"gopls","go":{"receiver":"Greeter","pointerReceiver":true,"owner":"Greeter","methodSetTypes":["*Greeter","*Box"]}}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => fail("failed to write declarations")
  }

  let out = read_bundle_declarations(repo)
  guard out is Ok(records) else { fail("expected richer declaration records") }
  inspect(records.length(), content="1")
  guard records[0] is Object(record) else {
    fail("expected declaration object")
  }
  guard record.get("canonical_name") is Some(String(canonical_name)) else {
    fail("expected canonical_name")
  }
  assert_eq(canonical_name, "go-module::main.go::Greet")
  guard record.get("source_refs") is Some(Array(source_refs)) else {
    fail("expected source_refs")
  }
  inspect(source_refs.length(), content="1")
  guard record.get("relations") is Some(Array(relations)) else {
    fail("expected relations")
  }
  inspect(relations.length(), content="3")
  guard record.get("language_specific") is Some(Object(language_specific)) else {
    fail("expected language_specific")
  }
  guard language_specific.get("go") is Some(Object(go_fields)) else {
    fail("expected go language_specific fields")
  }
  guard go_fields.get("receiver") is Some(String(receiver)) else {
    fail("expected receiver")
  }
  assert_eq(receiver, "Greeter")
  guard go_fields.get("methodSetTypes") is Some(Array(method_set_types)) else {
    fail("expected methodSetTypes")
  }
  inspect(method_set_types.length(), content="2")

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
test "bundle reader parses component records from spdx" {
  let repo = "/tmp/cogna-bundle-reader-components"
  @fs.remove_file("\{repo}/dist/sbom.spdx.json") catch {
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

  let components =
    #|{
    #|  "spdxVersion": "SPDX-2.3",
    #|  "SPDXID": "SPDXRef-DOCUMENT",
    #|  "name": "bundle-reader",
    #|  "packages": [
    #|    {
    #|      "SPDXID": "SPDXRef-Root",
    #|      "name": "bundle-reader",
    #|      "versionInfo": "0.1.0"
    #|    },
    #|    {
    #|      "SPDXID": "SPDXRef-Package-UUID",
    #|      "name": "github.com/google/uuid",
    #|      "versionInfo": "1.6.0",
    #|      "externalRefs": [
    #|        {
    #|          "referenceCategory": "PACKAGE-MANAGER",
    #|          "referenceType": "purl",
    #|          "referenceLocator": "pkg:golang/github.com/google/uuid@1.6.0"
    #|        }
    #|      ]
    #|    },
    #|    {
    #|      "SPDXID": "SPDXRef-Package-LO",
    #|      "name": "github.com/samber/lo",
    #|      "versionInfo": "1.49.1",
    #|      "externalRefs": [
    #|        {
    #|          "referenceCategory": "PACKAGE-MANAGER",
    #|          "referenceType": "purl",
    #|          "referenceLocator": "pkg:golang/github.com/samber/lo@1.49.1"
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  @fs.write_string_to_file(
    "\{repo}/dist/sbom.spdx.json",
    components,
  ) catch {
    _ => fail("failed to write spdx")
  }

  let out = read_bundle_components(repo)
  guard out is Ok(records) else { fail("expected component records") }
  inspect(records.length(), content="2")
  guard records[0] is Object(first) else { fail("expected first record object") }
  guard first.get("kind") is Some(String(kind)) else {
    fail("expected kind on first record")
  }
  assert_eq(kind, "component")

  @fs.remove_file("\{repo}/dist/sbom.spdx.json") catch {
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
  let repo = "/tmp/cogna-bundle-materialize"
  @fs.remove_file("\{repo}/bundle.ciq.tgz") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/manifest.json") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/declarations.ndjson") catch {
    _ => ()
  }
  @fs.remove_file("\{repo}/out/sbom.spdx.json") catch {
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
    "source": {
      "repo": "https://github.com/acme/demo",
      "ref": "main",
      "commit": "abc",
    },
    "artifacts": [
      { "path": "declarations.ndjson", "sha256": "x", "compression": "none" },
      { "path": "sbom.spdx.json", "sha256": "y", "compression": "none" },
    ],
  }
  let declarations_text =
    #|{"id":"decl:a","kind":"function","path":"a.go","signature":"fn a","location":{"uri":"a.go","startLine":1,"endLine":1}}
    #|
  let spdx_text =
    #|{"spdxVersion":"SPDX-2.3","SPDXID":"SPDXRef-DOCUMENT","name":"demo","packages":[{"SPDXID":"SPDXRef-Root","name":"demo"},{"SPDXID":"SPDXRef-Package-Demo","name":"demo-lib","versionInfo":"0.5.0","externalRefs":[{"referenceCategory":"PACKAGE-MANAGER","referenceType":"purl","referenceLocator":"pkg:generic/acme/demo-lib@0.5.0"}]}]}
    #|
  let tar_payload = tar_archive([
    ("manifest.json", @utf8.encode(manifest.stringify(indent=2))),
    ("declarations.ndjson", @utf8.encode(declarations_text)),
    ("sbom.spdx.json", @utf8.encode(spdx_text)),
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
  assert_true(@fs.path_exists("\{repo}/out/sbom.spdx.json"))
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
  @fs.remove_file("\{repo}/out/sbom.spdx.json") catch {
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

///|
test "bundle reader accepts richer rust declaration ndjson" {
  let repo = "/tmp/cogna-bundle-reader-rust-ndjson"
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
    #|{"id":"decl:rust-crate:rust-crate::lib.rs::c_add","kind":"function","name":"c_add","canonical_name":"rust-crate::lib.rs::c_add","path":"lib.rs","signature":"pub extern \"C\" fn c_add(a: i32, b: i32) -> i32 {","shape":{"kind":"function","subkind":"function","form":"callable","signature":"pub extern \"C\" fn c_add(a: i32, b: i32) -> i32 {","parameters":["i32","i32"],"returns":["i32"],"type_params":[]},"visibility":"public","docs":"","baselineRole":"baseline","language":"rust","source_refs":[{"uri":"lib.rs","startLine":74,"endLine":74}],"relations":[{"kind":"declared_in","target":"file:lib.rs"},{"kind":"has_parameter","target":"type:rust-crate::i32"},{"kind":"returns","target":"type:rust-crate::i32"}],"location":{"uri":"lib.rs","startLine":74,"endLine":74},"language_specific":{"profile":"rust-crate","server":"rust-analyzer","rust":{"typeParams":[],"externAbi":"C"}}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => fail("failed to write rust declarations")
  }

  let out = read_bundle_declarations(repo)
  guard out is Ok(records) else {
    fail("expected richer rust declaration records")
  }
  inspect(records.length(), content="1")
  guard records[0] is Object(record) else {
    fail("expected rust declaration object")
  }
  guard record.get("language") is Some(String(language)) else {
    fail("expected language")
  }
  assert_eq(language, "rust")
  guard record.get("language_specific") is Some(Object(language_specific)) else {
    fail("expected language_specific")
  }
  guard language_specific.get("rust") is Some(Object(rust_fields)) else {
    fail("expected rust language_specific fields")
  }
  guard rust_fields.get("externAbi") is Some(String(extern_abi)) else {
    fail("expected externAbi")
  }
  assert_eq(extern_abi, "C")

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
test "bundle reader accepts richer terraform declaration ndjson" {
  let repo = "/tmp/cogna-bundle-reader-terraform-ndjson"
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
    #|{"id":"decl:terraform-module:terraform-module::main.tf::aws_vpc.main","kind":"resource","name":"aws_vpc.main","canonical_name":"terraform-module::main.tf::aws_vpc.main","path":"main.tf","signature":"resource \"aws_vpc\" \"main\" {","shape":{"kind":"resource","subkind":"resource","form":"symbol","signature":"resource \"aws_vpc\" \"main\" {"},"visibility":"public","docs":"","baselineRole":"baseline","language":"terraform","source_refs":[{"uri":"main.tf","startLine":56,"endLine":56}],"relations":[{"kind":"declared_in","target":"file:main.tf"},{"kind":"uses_provider","target":"decl:terraform-module:terraform-module::main.tf::aws"}],"location":{"uri":"main.tf","startLine":56,"endLine":56},"language_specific":{"profile":"terraform-module","server":"hcl-parser","providers":{"terraform":[{"name":"aws","source":"hashicorp/aws","version":">= 5.0.0","alias":"east"}]},"terraform":{"providerRef":"aws.east","dependsOn":["module.network_labels"],"preventDestroy":true,"createBeforeDestroy":true,"ignoreChanges":["tags"]}}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => fail("failed to write terraform declarations")
  }

  let out = read_bundle_declarations(repo)
  guard out is Ok(records) else {
    fail("expected richer terraform declaration records")
  }
  inspect(records.length(), content="1")
  guard records[0] is Object(record) else {
    fail("expected terraform declaration object")
  }
  guard record.get("language_specific") is Some(Object(language_specific)) else {
    fail("expected language_specific")
  }
  guard language_specific.get("terraform") is Some(Object(terraform_fields)) else {
    fail("expected terraform fields")
  }
  guard terraform_fields.get("providerRef") is Some(String(provider_ref)) else {
    fail("expected providerRef")
  }
  assert_eq(provider_ref, "aws.east")
  guard terraform_fields.get("ignoreChanges") is Some(Array(ignore_changes)) else {
    fail("expected ignoreChanges")
  }
  inspect(ignore_changes.length(), content="1")
  guard terraform_fields.get("preventDestroy") is Some(True) else {
    fail("expected preventDestroy true")
  }

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
test "bundle reader accepts richer openapi declaration ndjson" {
  let repo = "/tmp/cogna-bundle-reader-openapi-ndjson"
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
    #|{"id":"decl:openapi-spec:openapi-spec::openapi::payment.yaml::createPayment","kind":"operation","name":"createPayment","canonical_name":"openapi-spec::openapi::payment.yaml::createPayment","path":"openapi/payment.yaml","signature":"operation createPayment","shape":{"kind":"operation","subkind":"operation","form":"symbol","signature":"operation createPayment"},"visibility":"public","docs":"","baselineRole":"baseline","language":"openapi","source_refs":[{"uri":"openapi/payment.yaml","startLine":26,"endLine":26}],"relations":[{"kind":"declared_in","target":"file:openapi/payment.yaml"}],"location":{"uri":"openapi/payment.yaml","startLine":26,"endLine":26},"language_specific":{"profile":"openapi-spec","server":"none","openapi":{"httpMethod":"POST","operationId":"createPayment","required":true,"mediaTypes":["application/json"],"statusCodes":["201"],"callbackExpression":"{$request.body#/callbackUrl}","discriminatorMapping":{"card":"#/components/schemas/CardPayment"},"memberRefs":["#/components/schemas/CardPayment"]}}}
    #|
  @fs.write_string_to_file("\{repo}/dist/declarations.ndjson", declarations) catch {
    _ => fail("failed to write openapi declarations")
  }

  let out = read_bundle_declarations(repo)
  guard out is Ok(records) else {
    fail("expected richer openapi declaration records")
  }
  inspect(records.length(), content="1")
  guard records[0] is Object(record) else {
    fail("expected openapi declaration object")
  }
  guard record.get("language_specific") is Some(Object(language_specific)) else {
    fail("expected language_specific")
  }
  guard language_specific.get("openapi") is Some(Object(openapi_fields)) else {
    fail("expected openapi fields")
  }
  guard openapi_fields.get("statusCodes") is Some(Array(status_codes)) else {
    fail("expected statusCodes")
  }
  inspect(status_codes.length(), content="1")
  guard openapi_fields.get("mediaTypes") is Some(Array(media_types)) else {
    fail("expected mediaTypes")
  }
  inspect(media_types.length(), content="1")
  guard openapi_fields.get("callbackExpression")
    is Some(String(callback_expression)) else {
    fail("expected callbackExpression")
  }
  assert_true(callback_expression.contains("callbackUrl"))
  guard openapi_fields.get("memberRefs") is Some(Array(member_refs)) else {
    fail("expected memberRefs")
  }
  inspect(member_refs.length(), content="1")

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
