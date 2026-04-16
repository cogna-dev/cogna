///|
pub(all) struct BuildInput {
  path : String
} derive(Eq)

///|
pub fn BuildInput::to_json(self : BuildInput) -> Json {
  let obj : Map[String, Json] = {}
  obj["path"] = Json::string(self.path)
  Json::object(obj)
}

///|
pub fn BuildInput::from_json(j : Json) -> BuildInput? {
  guard j is Object(obj) else { return None }
  let path : String = match obj.get("path") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ path, })
}

///|
pub fn BuildInput::to_json_string(self : BuildInput) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn BuildInput::from_json_string(s : String) -> Result[BuildInput, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match BuildInput::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct LogEntry {
  level : String
  message : String
} derive(Eq)

///|
pub fn LogEntry::to_json(self : LogEntry) -> Json {
  let obj : Map[String, Json] = {}
  obj["level"] = Json::string(self.level)
  obj["message"] = Json::string(self.message)
  Json::object(obj)
}

///|
pub fn LogEntry::from_json(j : Json) -> LogEntry? {
  guard j is Object(obj) else { return None }
  let level : String = match obj.get("level") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let message : String = match obj.get("message") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ level, message })
}

///|
pub fn LogEntry::to_json_string(self : LogEntry) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn LogEntry::from_json_string(s : String) -> Result[LogEntry, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match LogEntry::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct BuildBundleRef {
  purl : String
  profile : Profile
  version : VersionRef?
  bundle_id : String
  digest : String
  archive_path : String
  download_url : String
  etag : String
} derive(Eq)

///|
pub fn BuildBundleRef::to_json(self : BuildBundleRef) -> Json {
  let obj : Map[String, Json] = {}
  obj["purl"] = Json::string(self.purl)
  obj["profile"] = self.profile.to_json()
  match self.version {
    Some(value) => obj["version"] = value.to_json()
    None => ()
  }
  obj["bundleId"] = Json::string(self.bundle_id)
  obj["digest"] = Json::string(self.digest)
  obj["archivePath"] = Json::string(self.archive_path)
  obj["downloadUrl"] = Json::string(self.download_url)
  obj["etag"] = Json::string(self.etag)
  Json::object(obj)
}

///|
pub fn BuildBundleRef::from_json(j : Json) -> BuildBundleRef? {
  guard j is Object(obj) else { return None }
  let purl : String = match obj.get("purl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let profile : Profile = match obj.get("profile") {
    Some(value) => match (Profile::from_json(value)) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let version : VersionRef? = match obj.get("version") {
    Some(value) => (VersionRef::from_json(value))
    None => None
  }
  let bundle_id : String = match obj.get("bundleId") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let digest : String = match obj.get("digest") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let archive_path : String = match obj.get("archivePath") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let download_url : String = match obj.get("downloadUrl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let etag : String = match obj.get("etag") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ purl, profile, version, bundle_id, digest, archive_path, download_url, etag })
}

///|
pub fn BuildBundleRef::to_json_string(self : BuildBundleRef) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn BuildBundleRef::from_json_string(s : String) -> Result[BuildBundleRef, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match BuildBundleRef::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct BuildSummary {
  output_path : String
  manifest_path : String
  bundle_path : String
  declaration_count : Int
  symbol_count : Int
  software_component_count : Int
  metadata_path : String
  checksums_path : String
} derive(Eq)

///|
pub fn BuildSummary::to_json(self : BuildSummary) -> Json {
  let obj : Map[String, Json] = {}
  obj["outputPath"] = Json::string(self.output_path)
  obj["manifestPath"] = Json::string(self.manifest_path)
  obj["bundlePath"] = Json::string(self.bundle_path)
  obj["declarationCount"] = Json::number((self.declaration_count).to_double(), repr="\{self.declaration_count}")
  obj["symbolCount"] = Json::number((self.symbol_count).to_double(), repr="\{self.symbol_count}")
  obj["softwareComponentCount"] = Json::number((self.software_component_count).to_double(), repr="\{self.software_component_count}")
  obj["metadataPath"] = Json::string(self.metadata_path)
  obj["checksumsPath"] = Json::string(self.checksums_path)
  Json::object(obj)
}

///|
pub fn BuildSummary::from_json(j : Json) -> BuildSummary? {
  guard j is Object(obj) else { return None }
  let output_path : String = match obj.get("outputPath") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let manifest_path : String = match obj.get("manifestPath") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let bundle_path : String = match obj.get("bundlePath") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let declaration_count : Int = match obj.get("declarationCount") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let symbol_count : Int = match obj.get("symbolCount") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let software_component_count : Int = match obj.get("softwareComponentCount") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let metadata_path : String = match obj.get("metadataPath") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let checksums_path : String = match obj.get("checksumsPath") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ output_path, manifest_path, bundle_path, declaration_count, symbol_count, software_component_count, metadata_path, checksums_path })
}

///|
pub fn BuildSummary::to_json_string(self : BuildSummary) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn BuildSummary::from_json_string(s : String) -> Result[BuildSummary, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match BuildSummary::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct BuildOutput {
  success : Bool
  bundle : BuildBundleRef?
  summary : BuildSummary?
  logs : Array[LogEntry]
  error : ErrorResponse?
} derive(Eq)

///|
pub fn BuildOutput::to_json(self : BuildOutput) -> Json {
  let obj : Map[String, Json] = {}
  obj["success"] = Json::boolean(self.success)
  match self.bundle {
    Some(value) => obj["bundle"] = value.to_json()
    None => ()
  }
  match self.summary {
    Some(value) => obj["summary"] = value.to_json()
    None => ()
  }
  obj["logs"] = Json::array(self.logs.map(fn(item) { item.to_json() }))
  match self.error {
    Some(value) => obj["error"] = value.to_json()
    None => ()
  }
  Json::object(obj)
}

///|
pub fn BuildOutput::from_json(j : Json) -> BuildOutput? {
  guard j is Object(obj) else { return None }
  let success : Bool = match obj.get("success") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let bundle : BuildBundleRef? = match obj.get("bundle") {
    Some(value) => (BuildBundleRef::from_json(value))
    None => None
  }
  let summary : BuildSummary? = match obj.get("summary") {
    Some(value) => (BuildSummary::from_json(value))
    None => None
  }
  let logs : Array[LogEntry] = match obj.get("logs") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[LogEntry] = []
      for item in items {
        match (LogEntry::from_json(item)) {
          Some(value) => parsed.push(value)
          None => return None
        }
      }
      Some(parsed)
    }
    _ => None
  }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let error : ErrorResponse? = match obj.get("error") {
    Some(value) => (ErrorResponse::from_json(value))
    None => None
  }
  Some({ success, bundle, summary, logs, error })
}

///|
pub fn BuildOutput::to_json_string(self : BuildOutput) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn BuildOutput::from_json_string(s : String) -> Result[BuildOutput, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match BuildOutput::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}


