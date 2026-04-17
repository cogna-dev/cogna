///|
fn dependency_bundles_dir(bundle_file : String) -> String {
  "\{parent_dir(bundle_file)}/dependencies"
}

///|
fn dependency_bundle_files(bundle_file : String) -> Array[String] {
  let root = dependency_bundles_dir(bundle_file)
  if !@fs.path_exists(root) {
    return []
  }
  let entries = @fs.read_dir(root) catch { _ => return [] }
  let bundle_files : Array[String] = []
  for i in 0..<entries.length() {
    let entry = entries[i]
    let candidate = "\{root}/\{entry}/bundle.ciq.tgz"
    if @fs.path_exists(candidate) {
      bundle_files.push(candidate)
    }
  }
  bundle_files.sort()
  bundle_files
}

///|
fn aggregate_receipt(
  receipt : Json,
  dependency_receipts : Array[Json],
) -> Result[Json, @cli.CliError] {
  guard receipt is Object(receipt_object) else {
    return Err(publish_error("publish receipt must be object"))
  }
  let aggregated : Map[String, Json] = {}
  for key, value in receipt_object {
    aggregated[key] = value
  }
  aggregated["dependencyCount"] = Json::number(
    dependency_receipts.length().to_double(),
    repr="\{dependency_receipts.length()}",
  )
  aggregated["dependencyReceipts"] = Json::array(dependency_receipts)
  Ok(Json::object(aggregated))
}
