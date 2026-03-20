///|
pub(all) struct PublishParams {
  bundle_file : String
} derive(Show, Eq)

///|
pub(all) struct PublishResult {
  bundle_file : String
  summary : String
} derive(Show, Eq)

///|
pub impl @cli.Display for PublishResult with display(self : PublishResult) -> String {
  self.summary
}

///|
fn publish_error(message : String) -> @cli.CliError {
  @cli.command_error("publish failed: \{message}")
}

///|
fn ensure_bundle_exists(path : String) -> Result[Unit, @cli.CliError] {
  if @fs.path_exists(path) {
    Ok(())
  } else {
    Err(publish_error("bundle file does not exist: \{path}"))
  }
}

///|
fn parent_dir(path : String) -> String {
  let parts = path.split("/").to_array()
  if parts.length() <= 1 {
    "."
  } else {
    let mut out = ""
    for i in 0..<(parts.length() - 1) {
      if i > 0 {
        out = "\{out}/"
      }
      out = "\{out}\{parts[i]}"
    }
    out
  }
}

///|
fn bundle_id(bundle_file : String) -> String {
  let normalized = bundle_file.replace_all(old="/", new="_")
  "bundle_\{normalized}"
}

///|
fn publish_receipt(bundle_file : String) -> Json {
  {
    "publishId": "pub-skeleton-001",
    "bundleId": bundle_id(bundle_file),
    "bundleFile": bundle_file,
    "bundleType": "ciq-bundle",
    "status": "published-local-skeleton",
    "downloadUrl": "local://\{bundle_file}",
  }
}

///|
fn write_receipt(path : String, receipt : Json) -> Result[Unit, @cli.CliError] {
  @fs.write_string_to_file(path, receipt.stringify(indent=2)) catch {
    err =>
      return Err(
        publish_error(
          "cannot write publish receipt \{path}: \{err.to_string()}",
        ),
      )
  }
  Ok(())
}

///|
pub fn run(
  params : PublishParams,
) -> @cli.CliResult[PublishResult, @cli.CliError] {
  let exists_out = ensure_bundle_exists(params.bundle_file)
  guard exists_out is Ok(_) else { return Err(exists_out.unwrap_err()) }

  let receipt_path = "\{parent_dir(params.bundle_file)}/publish.json"
  let receipt = publish_receipt(params.bundle_file)
  let write_out = write_receipt(receipt_path, receipt)
  guard write_out is Ok(_) else { return Err(write_out.unwrap_err()) }

  Ok({
    bundle_file: params.bundle_file,
    summary: "Generated publish receipt at \{receipt_path}",
  })
}
