///|
pub(all) enum E2eSource {
  CargoPackage(String, String)
  GitRepo(String)
} derive(Eq)

///|
pub(all) struct E2eCase {
  id : String
  extractor : String
  source : E2eSource
} derive(Eq)

///|
fn normalize_case_id(value : String) -> String {
  let mut id = value.trim().to_string()
  if id == "" {
    id = "unknown"
  }
  id = id.replace_all(old=" ", new="-")
  id = id.replace_all(old="/", new="-")
  id = id.replace_all(old=":", new="-")
  id = id.replace_all(old="@", new="-")
  while id.contains("--") {
    id = id.replace_all(old="--", new="-")
  }
  id
}

///|
fn read_manifest(path : String) -> Result[Json, String] {
  let text = @fs.read_file_to_string(path) catch {
    err => return Err("cannot read manifest \{path}: \{err.to_string()}")
  }
  let parsed = try? @json.parse(text)
  guard parsed is Ok(value) else {
    return Err("invalid json in manifest \{path}")
  }
  Ok(value)
}

///|
fn extract_cases_from_manifest(path : String) -> Result[Array[E2eCase], String] {
  let manifest_out = read_manifest(path)
  guard manifest_out is Ok(manifest) else { return Err(manifest_out.unwrap_err()) }
  guard manifest is Object(root) else {
    return Err("manifest root must be object: \{path}")
  }
  guard root.get("cases") is Some(Array(cases_json)) else {
    return Err("manifest missing cases array: \{path}")
  }
  let cases : Array[E2eCase] = []
  for i in 0..<cases_json.length() {
    guard cases_json[i] is Object(case_obj) else { continue }
    let extractor = match case_obj.get("extractor") {
      Some(String(value)) => value.trim().to_string()
      _ => ""
    }
    if extractor == "" {
      continue
    }
    match case_obj.get("package") {
      Some(String(name_raw)) => {
        let name = name_raw.trim().to_string()
        let version = match case_obj.get("version") {
          Some(String(value)) => value.trim().to_string()
          _ => ""
        }
        if name == "" || version == "" {
          continue
        }
        let raw_id = "\{extractor}:\{name}@\{version}"
        cases.push({
          id: normalize_case_id(raw_id),
          extractor,
          source: E2eSource::CargoPackage(name, version),
        })
      }
      _ =>
        match case_obj.get("repo") {
          Some(String(url_raw)) => {
            let url = url_raw.trim().to_string()
            if url == "" {
              continue
            }
            let raw_id = "\{extractor}:\{url}"
            cases.push({
              id: normalize_case_id(raw_id),
              extractor,
              source: E2eSource::GitRepo(url),
            })
          }
          _ => ()
        }
    }
  }
  Ok(cases)
}

///|
pub fn load_cases() -> Result[Array[E2eCase], String] {
  let manifests = @fs.read_dir("./e2e/extractors") catch {
    err => return Err("cannot read e2e manifest directory: \{err.to_string()}")
  }
  let all_cases : Array[E2eCase] = []
  manifests.sort()
  for i in 0..<manifests.length() {
    let file_name = manifests[i]
    if !file_name.has_suffix(".json") {
      continue
    }
    let path = "./e2e/extractors/\{file_name}"
    let extracted_out = extract_cases_from_manifest(path)
    guard extracted_out is Ok(cases) else {
      return Err(extracted_out.unwrap_err())
    }
    for j in 0..<cases.length() {
      all_cases.push(cases[j])
    }
  }
  if all_cases.is_empty() {
    return Err("no e2e extractor cases found")
  }
  Ok(all_cases)
}
