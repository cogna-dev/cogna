///|
test "virtual package view reads normalized text paths" {
  let file_out = virtual_file("./src/main.go", @utf8.encode("package main\n"))
  guard file_out is Ok(file) else { fail("virtual file should normalize path") }
  let package_view = view_of({
    source_kind: "local",
    source_id: "/tmp/pkg",
    display_name: "pkg",
    root_hint: "/tmp/pkg",
    files: [file],
  })
  inspect(package_view.list_paths()[0], content="src/main.go")
  assert_true(package_view.exists("src/main.go"))
  guard package_view.read_text("./src/main.go") is Ok(text) else {
    fail("view should read text")
  }
  inspect(text, content="package main\n")
}

///|
test "virtual package archive strips shared root prefix" {
  let files_out = archive_files([
    ("crate-1.0.0/src/lib.rs", @utf8.encode("pub fn a() {}\n")),
    ("crate-1.0.0/Cargo.toml", @utf8.encode("[package]\n")),
  ])
  guard files_out is Ok(files) else { fail("archive files should normalize") }
  inspect(files.length(), content="2")
  inspect(files[0].path, content="src/lib.rs")
  inspect(files[1].path, content="Cargo.toml")
}

///|
test "virtual package normalize path rejects root escape" {
  let out = normalize_path("../secret.txt")
  guard out is Err(message) else { fail("root escape should fail") }
  inspect(message, content="path must not escape package root: ../secret.txt")
}
