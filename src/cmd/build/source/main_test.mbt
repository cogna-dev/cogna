///|
fn ensure_tree_removed(path : String) -> Unit {
  if !@fs.path_exists(path) {
    return
  }
  let is_dir = try? @fs.is_dir(path)
  if is_dir is Ok(true) {
    let entries = @fs.read_dir(path) catch { _ => [] }
    for i in 0..<entries.length() {
      ensure_tree_removed("\{path}/\{entries[i]}")
    }
    @fs.remove_dir(path) catch { _ => () }
  } else {
    @fs.remove_file(path) catch { _ => () }
  }
}

///|
fn shell_quote(value : String) -> String {
  let escaped = value.replace_all(old="'", new="'\"'\"'")
  "'\{escaped}'"
}

///|
fn run_shell(command : String) -> Result[Unit, String] {
  let (exit_code, _, stderr) = @process.run_command_capture(command)
  if exit_code != 0 {
    Err("command failed: \{command}\nstderr: \{stderr}")
  } else {
    Ok(())
  }
}

///|
test "local source resolver builds readonly package without dist or git" {
  let root = "/tmp/cogna-vp-local"
  ensure_tree_removed(root)
  @fs.create_dir(root)
  @fs.create_dir("\{root}/src")
  @fs.create_dir("\{root}/dist")
  @fs.create_dir("\{root}/.git")
  @fs.write_string_to_file("\{root}/src/main.go", "package main\n") catch {
    _ => fail("failed to write source file")
  }
  @fs.write_string_to_file("\{root}/dist/out.txt", "ignored\n") catch {
    _ => fail("failed to write dist file")
  }
  @fs.write_string_to_file("\{root}/.git/HEAD", "ref: refs/heads/main\n") catch {
    _ => fail("failed to write git file")
  }
  let package_out = resolve_local_workspace(root)
  guard package_out is Ok(package_) else {
    ensure_tree_removed(root)
    fail("local workspace should resolve")
  }
  inspect(package_.source_kind, content="local")
  inspect(package_.files.length(), content="1")
  inspect(package_.files[0].path, content="src/main.go")
  ensure_tree_removed(root)
}

///|
test "cargo source resolver prefers vendor over cargo home registry" {
  let root = "/tmp/cogna-vp-cargo-vendor-priority"
  ensure_tree_removed(root)
  @fs.create_dir(root)
  @fs.create_dir("\{root}/vendor")
  @fs.create_dir("\{root}/vendor/demo")
  @fs.create_dir("\{root}/vendor/demo/src")
  @fs.write_string_to_file("\{root}/vendor/demo/Cargo.toml", "[package]\nname = \"demo\"\n") catch {
    _ => fail("failed to write vendor Cargo.toml")
  }
  @fs.write_string_to_file("\{root}/vendor/demo/src/lib.rs", "pub fn source() -> &'static str { \"vendor\" }\n") catch {
    _ => fail("failed to write vendor source")
  }

  let cargo_home = "\{root}/cargo-home"
  @fs.create_dir(cargo_home)
  @fs.create_dir("\{cargo_home}/registry")
  @fs.create_dir("\{cargo_home}/registry/src")
  @fs.create_dir("\{cargo_home}/registry/src/index.crates.io-local")
  @fs.create_dir("\{cargo_home}/registry/src/index.crates.io-local/demo-1.0.0")
  @fs.create_dir("\{cargo_home}/registry/src/index.crates.io-local/demo-1.0.0/src")
  @fs.write_string_to_file("\{cargo_home}/registry/src/index.crates.io-local/demo-1.0.0/Cargo.toml", "[package]\nname = \"demo\"\nversion = \"1.0.0\"\n") catch {
    _ => fail("failed to write registry Cargo.toml")
  }
  @fs.write_string_to_file("\{cargo_home}/registry/src/index.crates.io-local/demo-1.0.0/src/lib.rs", "pub fn source() -> &'static str { \"registry\" }\n") catch {
    _ => fail("failed to write registry source")
  }

  let previous_cargo_home = @sys.get_env_var("CARGO_HOME")
  @sys.set_env_var("CARGO_HOME", cargo_home)

  let package_out = resolve_source_in_workspace(
    root,
    @vp.SourceSpec::CargoPackage({
      name: "demo",
      version: "1.0.0",
      registry: None,
    }),
  )
  guard package_out is Ok(package_) else {
    match previous_cargo_home {
      Some(value) => @sys.set_env_var("CARGO_HOME", value)
      None => @sys.unset_env_var("CARGO_HOME")
    }
    ensure_tree_removed(root)
    fail("cargo source should resolve")
  }
  inspect(package_.source_kind, content="cargo")
  inspect(package_.source_id, content="demo@1.0.0")
  let view = @vp.view_of(package_)
  guard view.read_text("src/lib.rs") is Ok(content) else {
    match previous_cargo_home {
      Some(value) => @sys.set_env_var("CARGO_HOME", value)
      None => @sys.unset_env_var("CARGO_HOME")
    }
    ensure_tree_removed(root)
    fail("expected cargo source file")
  }
  assert_true(content.contains("vendor"))

  match previous_cargo_home {
    Some(value) => @sys.set_env_var("CARGO_HOME", value)
    None => @sys.unset_env_var("CARGO_HOME")
  }
  ensure_tree_removed(root)
}

///|
test "cargo source resolver falls back to cargo home registry" {
  let root = "/tmp/cogna-vp-cargo-registry-fallback"
  ensure_tree_removed(root)
  @fs.create_dir(root)

  let cargo_home = "\{root}/cargo-home"
  @fs.create_dir(cargo_home)
  @fs.create_dir("\{cargo_home}/registry")
  @fs.create_dir("\{cargo_home}/registry/src")
  @fs.create_dir("\{cargo_home}/registry/src/index.crates.io-local")
  @fs.create_dir("\{cargo_home}/registry/src/index.crates.io-local/demo-2.0.0")
  @fs.create_dir("\{cargo_home}/registry/src/index.crates.io-local/demo-2.0.0/src")
  @fs.write_string_to_file("\{cargo_home}/registry/src/index.crates.io-local/demo-2.0.0/Cargo.toml", "[package]\nname = \"demo\"\nversion = \"2.0.0\"\n") catch {
    _ => fail("failed to write registry Cargo.toml")
  }
  @fs.write_string_to_file("\{cargo_home}/registry/src/index.crates.io-local/demo-2.0.0/src/lib.rs", "pub fn source() -> &'static str { \"registry\" }\n") catch {
    _ => fail("failed to write registry source")
  }

  let previous_cargo_home = @sys.get_env_var("CARGO_HOME")
  @sys.set_env_var("CARGO_HOME", cargo_home)

  let package_out = resolve_cargo_package(
    root,
    {
      name: "demo",
      version: "2.0.0",
      registry: None,
    },
  )
  guard package_out is Ok(package_) else {
    match previous_cargo_home {
      Some(value) => @sys.set_env_var("CARGO_HOME", value)
      None => @sys.unset_env_var("CARGO_HOME")
    }
    ensure_tree_removed(root)
    fail("cargo registry fallback should resolve")
  }
  inspect(package_.source_kind, content="cargo")
  let view = @vp.view_of(package_)
  guard view.read_text("src/lib.rs") is Ok(content) else {
    match previous_cargo_home {
      Some(value) => @sys.set_env_var("CARGO_HOME", value)
      None => @sys.unset_env_var("CARGO_HOME")
    }
    ensure_tree_removed(root)
    fail("expected cargo registry source file")
  }
  assert_true(content.contains("registry"))

  match previous_cargo_home {
    Some(value) => @sys.set_env_var("CARGO_HOME", value)
    None => @sys.unset_env_var("CARGO_HOME")
  }
  ensure_tree_removed(root)
}

///|
test "cargo source resolver returns local-install guidance when missing" {
  let root = "/tmp/cogna-vp-cargo-missing"
  ensure_tree_removed(root)
  @fs.create_dir(root)

  let cargo_home = "\{root}/cargo-home"
  @fs.create_dir(cargo_home)

  let previous_cargo_home = @sys.get_env_var("CARGO_HOME")
  @sys.set_env_var("CARGO_HOME", cargo_home)

  let package_out = resolve_cargo_package(
    root,
    {
      name: "missing",
      version: "9.9.9",
      registry: None,
    },
  )
  guard package_out is Err(message) else {
    match previous_cargo_home {
      Some(value) => @sys.set_env_var("CARGO_HOME", value)
      None => @sys.unset_env_var("CARGO_HOME")
    }
    ensure_tree_removed(root)
    fail("missing cargo package should fail")
  }
  inspect(
    message,
    content="Cargo dependency missing@9.9.9 is not available locally. Run `cargo fetch` or `cargo vendor`.",
  )

  match previous_cargo_home {
    Some(value) => @sys.set_env_var("CARGO_HOME", value)
    None => @sys.unset_env_var("CARGO_HOME")
  }
  ensure_tree_removed(root)
}

///|
test "go source resolver prefers vendor over module cache" {
  let root = "/tmp/cogna-vp-go-vendor-priority"
  ensure_tree_removed(root)
  @fs.create_dir(root)
  @fs.create_dir("\{root}/vendor")
  @fs.create_dir("\{root}/vendor/github.com")
  @fs.create_dir("\{root}/vendor/github.com/acme")
  @fs.create_dir("\{root}/vendor/github.com/acme/lib")
  @fs.write_string_to_file("\{root}/vendor/github.com/acme/lib/lib.go", "package lib\nfunc Source() string { return \"vendor\" }\n") catch {
    _ => fail("failed to write vendor go source")
  }

  let gomodcache = "\{root}/gomodcache"
  @fs.create_dir(gomodcache)
  @fs.create_dir("\{gomodcache}/github.com")
  @fs.create_dir("\{gomodcache}/github.com/acme")
  @fs.create_dir("\{gomodcache}/github.com/acme/lib@v1.2.3")
  @fs.write_string_to_file("\{gomodcache}/github.com/acme/lib@v1.2.3/lib.go", "package lib\nfunc Source() string { return \"cache\" }\n") catch {
    _ => fail("failed to write go cache source")
  }

  let previous_gomodcache = @sys.get_env_var("GOMODCACHE")
  let previous_gopath = @sys.get_env_var("GOPATH")
  @sys.set_env_var("GOMODCACHE", gomodcache)
  @sys.unset_env_var("GOPATH")

  let package_out = resolve_source_in_workspace(
    root,
    @vp.SourceSpec::GoModule({
      module_path: "github.com/acme/lib",
      version: "v1.2.3",
      proxy: None,
    }),
  )
  guard package_out is Ok(package_) else {
    match previous_gomodcache {
      Some(value) => @sys.set_env_var("GOMODCACHE", value)
      None => @sys.unset_env_var("GOMODCACHE")
    }
    match previous_gopath {
      Some(value) => @sys.set_env_var("GOPATH", value)
      None => @sys.unset_env_var("GOPATH")
    }
    ensure_tree_removed(root)
    fail("go source should resolve")
  }
  inspect(package_.source_kind, content="gomod")
  let view = @vp.view_of(package_)
  guard view.read_text("lib.go") is Ok(content) else {
    match previous_gomodcache {
      Some(value) => @sys.set_env_var("GOMODCACHE", value)
      None => @sys.unset_env_var("GOMODCACHE")
    }
    match previous_gopath {
      Some(value) => @sys.set_env_var("GOPATH", value)
      None => @sys.unset_env_var("GOPATH")
    }
    ensure_tree_removed(root)
    fail("expected go source file")
  }
  assert_true(content.contains("vendor"))

  match previous_gomodcache {
    Some(value) => @sys.set_env_var("GOMODCACHE", value)
    None => @sys.unset_env_var("GOMODCACHE")
  }
  match previous_gopath {
    Some(value) => @sys.set_env_var("GOPATH", value)
    None => @sys.unset_env_var("GOPATH")
  }
  ensure_tree_removed(root)
}

///|
test "go source resolver falls back to module cache with escaped path" {
  let root = "/tmp/cogna-vp-go-cache-fallback"
  ensure_tree_removed(root)
  @fs.create_dir(root)

  let gomodcache = "\{root}/gomodcache"
  @fs.create_dir(gomodcache)
  @fs.create_dir("\{gomodcache}/github.com")
  @fs.create_dir("\{gomodcache}/github.com/!azure")
  @fs.create_dir("\{gomodcache}/github.com/!azure/azure-sdk-for-go@v1.0.0")
  @fs.write_string_to_file("\{gomodcache}/github.com/!azure/azure-sdk-for-go@v1.0.0/sdk.go", "package sdk\nfunc Source() string { return \"cache\" }\n") catch {
    _ => fail("failed to write escaped go cache source")
  }

  let previous_gomodcache = @sys.get_env_var("GOMODCACHE")
  let previous_gopath = @sys.get_env_var("GOPATH")
  @sys.set_env_var("GOMODCACHE", gomodcache)
  @sys.unset_env_var("GOPATH")

  let package_out = resolve_go_module(
    root,
    {
      module_path: "github.com/Azure/azure-sdk-for-go",
      version: "v1.0.0",
      proxy: None,
    },
  )
  guard package_out is Ok(package_) else {
    match previous_gomodcache {
      Some(value) => @sys.set_env_var("GOMODCACHE", value)
      None => @sys.unset_env_var("GOMODCACHE")
    }
    match previous_gopath {
      Some(value) => @sys.set_env_var("GOPATH", value)
      None => @sys.unset_env_var("GOPATH")
    }
    ensure_tree_removed(root)
    fail("go cache fallback should resolve")
  }
  inspect(package_.source_kind, content="gomod")
  inspect(
    package_.source_id,
    content="github.com/Azure/azure-sdk-for-go@v1.0.0",
  )
  let view = @vp.view_of(package_)
  guard view.read_text("sdk.go") is Ok(content) else {
    match previous_gomodcache {
      Some(value) => @sys.set_env_var("GOMODCACHE", value)
      None => @sys.unset_env_var("GOMODCACHE")
    }
    match previous_gopath {
      Some(value) => @sys.set_env_var("GOPATH", value)
      None => @sys.unset_env_var("GOPATH")
    }
    ensure_tree_removed(root)
    fail("expected escaped go cache source file")
  }
  assert_true(content.contains("cache"))

  match previous_gomodcache {
    Some(value) => @sys.set_env_var("GOMODCACHE", value)
    None => @sys.unset_env_var("GOMODCACHE")
  }
  match previous_gopath {
    Some(value) => @sys.set_env_var("GOPATH", value)
    None => @sys.unset_env_var("GOPATH")
  }
  ensure_tree_removed(root)
}

///|
test "go source resolver returns local-install guidance when missing" {
  let root = "/tmp/cogna-vp-go-missing"
  ensure_tree_removed(root)
  @fs.create_dir(root)

  let gomodcache = "\{root}/gomodcache"
  @fs.create_dir(gomodcache)

  let previous_gomodcache = @sys.get_env_var("GOMODCACHE")
  let previous_gopath = @sys.get_env_var("GOPATH")
  @sys.set_env_var("GOMODCACHE", gomodcache)
  @sys.unset_env_var("GOPATH")

  let package_out = resolve_go_module(
    root,
    {
      module_path: "github.com/acme/missing",
      version: "v9.9.9",
      proxy: None,
    },
  )
  guard package_out is Err(message) else {
    match previous_gomodcache {
      Some(value) => @sys.set_env_var("GOMODCACHE", value)
      None => @sys.unset_env_var("GOMODCACHE")
    }
    match previous_gopath {
      Some(value) => @sys.set_env_var("GOPATH", value)
      None => @sys.unset_env_var("GOPATH")
    }
    ensure_tree_removed(root)
    fail("missing go module should fail")
  }
  inspect(
    message,
    content="Go module github.com/acme/missing@v9.9.9 is not available locally. Run `go mod download` or `go mod vendor`.",
  )

  match previous_gomodcache {
    Some(value) => @sys.set_env_var("GOMODCACHE", value)
    None => @sys.unset_env_var("GOMODCACHE")
  }
  match previous_gopath {
    Some(value) => @sys.set_env_var("GOPATH", value)
    None => @sys.unset_env_var("GOPATH")
  }
  ensure_tree_removed(root)
}

///|
test "terraform module source resolver reads installed modules manifest" {
  let root = "/tmp/cogna-vp-terraform-module"
  ensure_tree_removed(root)
  @fs.create_dir(root)
  @fs.create_dir("\{root}/.terraform")
  @fs.create_dir("\{root}/.terraform/modules")
  @fs.create_dir("\{root}/.terraform/modules/vpc")
  @fs.write_string_to_file("\{root}/.terraform/modules/vpc/main.tf", "resource \"aws_vpc\" \"main\" {}\n") catch {
    _ => fail("failed to write module file")
  }
  let modules_manifest = #|{
  #|  "Modules": [
  #|    {
  #|      "Key": "vpc",
  #|      "Source": "terraform-aws-modules/vpc/aws",
  #|      "Dir": ".terraform/modules/vpc",
  #|      "Version": "5.0.0"
  #|    }
  #|  ]
  #|}
  #|
  @fs.write_string_to_file(
    "\{root}/.terraform/modules/modules.json",
    modules_manifest,
  ) catch {
    _ => fail("failed to write modules manifest")
  }

  let package_out = resolve_source_in_workspace(
    root,
    @vp.SourceSpec::TerraformPackage({
      kind: "module",
      source: "terraform-aws-modules/vpc/aws",
      version: Some("5.0.0"),
    }),
  )
  guard package_out is Ok(package_) else {
    let message = package_out.unwrap_err()
    ensure_tree_removed(root)
    fail("terraform module should resolve: \{message}")
  }
  inspect(package_.source_kind, content="terraform")
  let view = @vp.view_of(package_)
  assert_true(view.exists("main.tf"))
  ensure_tree_removed(root)
}

///|
test "terraform provider source resolver requires lockfile" {
  let root = "/tmp/cogna-vp-terraform-provider-missing"
  ensure_tree_removed(root)
  @fs.create_dir(root)

  let package_out = resolve_source_in_workspace(
    root,
    @vp.SourceSpec::TerraformPackage({
      kind: "provider",
      source: "hashicorp/aws",
      version: Some("5.0.0"),
    }),
  )
  guard package_out is Err(message) else {
    ensure_tree_removed(root)
    fail("provider without lockfile should fail")
  }
  inspect(
    message,
    content="Terraform providers are not initialized. Run `terraform init`.",
  )
  ensure_tree_removed(root)
}

///|
test "terraform provider source resolver returns lockfile package" {
  let root = "/tmp/cogna-vp-terraform-provider"
  ensure_tree_removed(root)
  @fs.create_dir(root)
  let lock_file = #|provider "registry.terraform.io/hashicorp/aws" {
  #|  version = "5.0.0"
  #|}
  #|
  @fs.write_string_to_file(
    "\{root}/.terraform.lock.hcl",
    lock_file,
  ) catch {
    _ => fail("failed to write terraform lockfile")
  }

  let package_out = resolve_terraform_package(
    root,
    {
      kind: "provider",
      source: "hashicorp/aws",
      version: Some("5.0.0"),
    },
  )
  guard package_out is Ok(package_) else {
    ensure_tree_removed(root)
    fail("provider with lockfile should resolve")
  }
  inspect(package_.source_kind, content="terraform")
  inspect(package_.files.length(), content="1")
  inspect(package_.files[0].path, content=".terraform.lock.hcl")
  ensure_tree_removed(root)
}

///|
test "terraform module source resolver returns init guidance when missing" {
  let root = "/tmp/cogna-vp-terraform-module-missing"
  ensure_tree_removed(root)
  @fs.create_dir(root)

  let package_out = resolve_terraform_package(
    root,
    {
      kind: "module",
      source: "terraform-aws-modules/vpc/aws",
      version: Some("5.0.0"),
    },
  )
  guard package_out is Err(message) else {
    ensure_tree_removed(root)
    fail("missing terraform module should fail")
  }
  inspect(
    message,
    content="Terraform modules are not initialized. Run `terraform init`.",
  )
  ensure_tree_removed(root)
}

///|
test "git source resolver clones local repository" {
  let root = "/tmp/cogna-vp-git-local"
  ensure_tree_removed(root)
  @fs.create_dir(root)
  @fs.create_dir("\{root}/repo")
  @fs.create_dir("\{root}/repo/src")
  @fs.write_string_to_file("\{root}/repo/src/lib.rs", "pub fn answer() -> i32 { 42 }\n") catch {
    _ => fail("failed to write git source file")
  }
  let repo_path = "\{root}/repo"
  let repo_quoted = shell_quote(repo_path)
  let init_out = run_shell("git -C \{repo_quoted} init -q")
  guard init_out is Ok(_) else {
    let message = init_out.unwrap_err()
    ensure_tree_removed(root)
    fail(message)
  }
  let add_out = run_shell("git -C \{repo_quoted} add .")
  guard add_out is Ok(_) else {
    let message = add_out.unwrap_err()
    ensure_tree_removed(root)
    fail(message)
  }
  let commit_out = run_shell(
    "git -C \{repo_quoted} -c user.name='Cogna Test' -c user.email='test@example.com' commit -q -m 'initial'",
  )
  guard commit_out is Ok(_) else {
    let message = commit_out.unwrap_err()
    ensure_tree_removed(root)
    fail(message)
  }

  let package_out = resolve_source_in_workspace(
    root,
    @vp.SourceSpec::GitRepo({
      url: "\{root}/repo",
      ref_: None,
    }),
  )
  guard package_out is Ok(package_) else {
    ensure_tree_removed(root)
    fail("git source should resolve")
  }
  inspect(package_.source_kind, content="git")
  let view = @vp.view_of(package_)
  guard view.read_text("src/lib.rs") is Ok(content) else {
    ensure_tree_removed(root)
    fail("expected cloned git file")
  }
  assert_true(content.contains("answer"))
  ensure_tree_removed(root)
}

///|
test "git source resolver fails on missing repository" {
  let root = "/tmp/cogna-vp-git-missing"
  ensure_tree_removed(root)
  @fs.create_dir(root)

  let package_out = resolve_source_in_workspace(
    root,
    @vp.SourceSpec::GitRepo({
      url: "\{root}/does-not-exist",
      ref_: None,
    }),
  )
  guard package_out is Err(message) else {
    ensure_tree_removed(root)
    fail("missing git repository should fail")
  }
  assert_true(message.contains("git clone failed"))
  ensure_tree_removed(root)
}
