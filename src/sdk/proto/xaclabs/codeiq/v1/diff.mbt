///|
pub(all) enum SeverityLevel {
  SeverityLevelUnspecified
  SeverityLevelNote
  SeverityLevelWarning
  SeverityLevelError
  SeverityLevelBreaking
} derive(Eq, Debug)

///|
pub fn SeverityLevel::to_json(self : SeverityLevel) -> Json {
  match self {
    SeverityLevel::SeverityLevelUnspecified => Json::string("SEVERITY_LEVEL_UNSPECIFIED")
    SeverityLevel::SeverityLevelNote => Json::string("SEVERITY_LEVEL_NOTE")
    SeverityLevel::SeverityLevelWarning => Json::string("SEVERITY_LEVEL_WARNING")
    SeverityLevel::SeverityLevelError => Json::string("SEVERITY_LEVEL_ERROR")
    SeverityLevel::SeverityLevelBreaking => Json::string("SEVERITY_LEVEL_BREAKING")
  }
}

///|
pub fn SeverityLevel::from_json(j : Json) -> SeverityLevel? {
  match j {
    String("SEVERITY_LEVEL_UNSPECIFIED") => Some(SeverityLevel::SeverityLevelUnspecified)
    String("SEVERITY_LEVEL_NOTE") => Some(SeverityLevel::SeverityLevelNote)
    String("SEVERITY_LEVEL_WARNING") => Some(SeverityLevel::SeverityLevelWarning)
    String("SEVERITY_LEVEL_ERROR") => Some(SeverityLevel::SeverityLevelError)
    String("SEVERITY_LEVEL_BREAKING") => Some(SeverityLevel::SeverityLevelBreaking)
    _ => None
  }
}

///|
pub(all) enum DiffChangeKind {
  DiffChangeKindUnspecified
  DiffChangeKindAdded
  DiffChangeKindRemoved
  DiffChangeKindChanged
  DiffChangeKindDeprecated
} derive(Eq, Debug)

///|
pub fn DiffChangeKind::to_json(self : DiffChangeKind) -> Json {
  match self {
    DiffChangeKind::DiffChangeKindUnspecified => Json::string("DIFF_CHANGE_KIND_UNSPECIFIED")
    DiffChangeKind::DiffChangeKindAdded => Json::string("DIFF_CHANGE_KIND_ADDED")
    DiffChangeKind::DiffChangeKindRemoved => Json::string("DIFF_CHANGE_KIND_REMOVED")
    DiffChangeKind::DiffChangeKindChanged => Json::string("DIFF_CHANGE_KIND_CHANGED")
    DiffChangeKind::DiffChangeKindDeprecated => Json::string("DIFF_CHANGE_KIND_DEPRECATED")
  }
}

///|
pub fn DiffChangeKind::from_json(j : Json) -> DiffChangeKind? {
  match j {
    String("DIFF_CHANGE_KIND_UNSPECIFIED") => Some(DiffChangeKind::DiffChangeKindUnspecified)
    String("DIFF_CHANGE_KIND_ADDED") => Some(DiffChangeKind::DiffChangeKindAdded)
    String("DIFF_CHANGE_KIND_REMOVED") => Some(DiffChangeKind::DiffChangeKindRemoved)
    String("DIFF_CHANGE_KIND_CHANGED") => Some(DiffChangeKind::DiffChangeKindChanged)
    String("DIFF_CHANGE_KIND_DEPRECATED") => Some(DiffChangeKind::DiffChangeKindDeprecated)
    _ => None
  }
}

///|
pub(all) enum TestChangeKind {
  TestChangeKindUnspecified
  TestChangeKindAdded
  TestChangeKindModified
  TestChangeKindRemoved
} derive(Eq, Debug)

///|
pub fn TestChangeKind::to_json(self : TestChangeKind) -> Json {
  match self {
    TestChangeKind::TestChangeKindUnspecified => Json::string("TEST_CHANGE_KIND_UNSPECIFIED")
    TestChangeKind::TestChangeKindAdded => Json::string("TEST_CHANGE_KIND_ADDED")
    TestChangeKind::TestChangeKindModified => Json::string("TEST_CHANGE_KIND_MODIFIED")
    TestChangeKind::TestChangeKindRemoved => Json::string("TEST_CHANGE_KIND_REMOVED")
  }
}

///|
pub fn TestChangeKind::from_json(j : Json) -> TestChangeKind? {
  match j {
    String("TEST_CHANGE_KIND_UNSPECIFIED") => Some(TestChangeKind::TestChangeKindUnspecified)
    String("TEST_CHANGE_KIND_ADDED") => Some(TestChangeKind::TestChangeKindAdded)
    String("TEST_CHANGE_KIND_MODIFIED") => Some(TestChangeKind::TestChangeKindModified)
    String("TEST_CHANGE_KIND_REMOVED") => Some(TestChangeKind::TestChangeKindRemoved)
    _ => None
  }
}

///|
pub(all) struct SemanticFinding {
  code : String
  message : String
} derive(Eq)

///|
pub fn SemanticFinding::to_json(self : SemanticFinding) -> Json {
  let obj : Map[String, Json] = {}
  obj["code"] = Json::string(self.code)
  obj["message"] = Json::string(self.message)
  Json::object(obj)
}

///|
pub fn SemanticFinding::from_json(j : Json) -> SemanticFinding? {
  guard j is Object(obj) else { return None }
  let code : String = match obj.get("code") {
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
  Some({ code, message })
}

///|
pub fn SemanticFinding::to_json_string(self : SemanticFinding) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn SemanticFinding::from_json_string(s : String) -> Result[SemanticFinding, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match SemanticFinding::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct SemanticDiff {
  findings : Array[SemanticFinding]
  changed_fields : Array[String]
  before_shape : DeclarationShape?
  after_shape : DeclarationShape?
  before_language_specific : LanguageSpecific?
  after_language_specific : LanguageSpecific?
} derive(Eq)

///|
pub fn SemanticDiff::to_json(self : SemanticDiff) -> Json {
  let obj : Map[String, Json] = {}
  obj["findings"] = Json::array(self.findings.map(fn(item) { item.to_json() }))
  obj["changedFields"] = Json::array(self.changed_fields.map(fn(item) { Json::string(item) }))
  match self.before_shape {
    Some(value) => obj["beforeShape"] = value.to_json()
    None => ()
  }
  match self.after_shape {
    Some(value) => obj["afterShape"] = value.to_json()
    None => ()
  }
  match self.before_language_specific {
    Some(value) => obj["beforeLanguageSpecific"] = value.to_json()
    None => ()
  }
  match self.after_language_specific {
    Some(value) => obj["afterLanguageSpecific"] = value.to_json()
    None => ()
  }
  Json::object(obj)
}

///|
pub fn SemanticDiff::from_json(j : Json) -> SemanticDiff? {
  guard j is Object(obj) else { return None }
  let findings : Array[SemanticFinding] = match obj.get("findings") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[SemanticFinding] = []
      for item in items {
        match (SemanticFinding::from_json(item)) {
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
  let changed_fields : Array[String] = match obj.get("changedFields") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[String] = []
      for item in items {
        match (match item { String(text) => Some(text) ; _ => None }) {
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
  let before_shape : DeclarationShape? = match obj.get("beforeShape") {
    Some(value) => (DeclarationShape::from_json(value))
    None => None
  }
  let after_shape : DeclarationShape? = match obj.get("afterShape") {
    Some(value) => (DeclarationShape::from_json(value))
    None => None
  }
  let before_language_specific : LanguageSpecific? = match obj.get("beforeLanguageSpecific") {
    Some(value) => (LanguageSpecific::from_json(value))
    None => None
  }
  let after_language_specific : LanguageSpecific? = match obj.get("afterLanguageSpecific") {
    Some(value) => (LanguageSpecific::from_json(value))
    None => None
  }
  Some({ findings, changed_fields, before_shape, after_shape, before_language_specific, after_language_specific })
}

///|
pub fn SemanticDiff::to_json_string(self : SemanticDiff) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn SemanticDiff::from_json_string(s : String) -> Result[SemanticDiff, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match SemanticDiff::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct ComponentDiff {
  changed_fields : Array[String]
  upgrade_kind : String
  before_version : String
  after_version : String
  before_purl : String
  after_purl : String
} derive(Eq)

///|
pub fn ComponentDiff::to_json(self : ComponentDiff) -> Json {
  let obj : Map[String, Json] = {}
  obj["changedFields"] = Json::array(self.changed_fields.map(fn(item) { Json::string(item) }))
  obj["upgradeKind"] = Json::string(self.upgrade_kind)
  obj["beforeVersion"] = Json::string(self.before_version)
  obj["afterVersion"] = Json::string(self.after_version)
  obj["beforePurl"] = Json::string(self.before_purl)
  obj["afterPurl"] = Json::string(self.after_purl)
  Json::object(obj)
}

///|
pub fn ComponentDiff::from_json(j : Json) -> ComponentDiff? {
  guard j is Object(obj) else { return None }
  let changed_fields : Array[String] = match obj.get("changedFields") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[String] = []
      for item in items {
        match (match item { String(text) => Some(text) ; _ => None }) {
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
  let upgrade_kind : String = match obj.get("upgradeKind") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let before_version : String = match obj.get("beforeVersion") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let after_version : String = match obj.get("afterVersion") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let before_purl : String = match obj.get("beforePurl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let after_purl : String = match obj.get("afterPurl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ changed_fields, upgrade_kind, before_version, after_version, before_purl, after_purl })
}

///|
pub fn ComponentDiff::to_json_string(self : ComponentDiff) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn ComponentDiff::from_json_string(s : String) -> Result[ComponentDiff, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match ComponentDiff::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct DiffBundleRef {
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
pub fn DiffBundleRef::to_json(self : DiffBundleRef) -> Json {
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
pub fn DiffBundleRef::from_json(j : Json) -> DiffBundleRef? {
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
pub fn DiffBundleRef::to_json_string(self : DiffBundleRef) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn DiffBundleRef::from_json_string(s : String) -> Result[DiffBundleRef, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match DiffBundleRef::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) enum DiffChangeBeforeRecord {
  BeforeDeclaration(Declaration)
  BeforeSymbol(Symbol)
  BeforeSoftwareComponent(SoftwareComponent)
} derive(Eq)

///|
pub(all) enum DiffChangeAfterRecord {
  AfterDeclaration(Declaration)
  AfterSymbol(Symbol)
  AfterSoftwareComponent(SoftwareComponent)
} derive(Eq)

///|
pub(all) struct DiffChange {
  kind : DiffChangeKind
  id : String
  path : String
  level : SeverityLevel
  before : String
  after : String
  semantic_diff : SemanticDiff?
  component_diff : ComponentDiff?
  before_record : DiffChangeBeforeRecord?
  after_record : DiffChangeAfterRecord?
} derive(Eq)

///|
pub fn DiffChange::to_json(self : DiffChange) -> Json {
  let obj : Map[String, Json] = {}
  obj["kind"] = self.kind.to_json()
  obj["id"] = Json::string(self.id)
  obj["path"] = Json::string(self.path)
  obj["level"] = self.level.to_json()
  obj["before"] = Json::string(self.before)
  obj["after"] = Json::string(self.after)
  match self.semantic_diff {
    Some(value) => obj["semanticDiff"] = value.to_json()
    None => ()
  }
  match self.component_diff {
    Some(value) => obj["componentDiff"] = value.to_json()
    None => ()
  }
  match self.before_record {
    Some(v) => {
      let oneof_obj = v.to_json()
      guard oneof_obj is Object(oneof_fields) else { return Json::object(obj) }
      for key, value in oneof_fields {
        obj[key] = value
      }
    }
    None => ()
  }
  match self.after_record {
    Some(v) => {
      let oneof_obj = v.to_json()
      guard oneof_obj is Object(oneof_fields) else { return Json::object(obj) }
      for key, value in oneof_fields {
        obj[key] = value
      }
    }
    None => ()
  }
  Json::object(obj)
}

///|
pub fn DiffChange::from_json(j : Json) -> DiffChange? {
  guard j is Object(obj) else { return None }
  let kind : DiffChangeKind = match obj.get("kind") {
    Some(value) => match (DiffChangeKind::from_json(value)) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let id : String = match obj.get("id") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let path : String = match obj.get("path") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let level : SeverityLevel = match obj.get("level") {
    Some(value) => match (SeverityLevel::from_json(value)) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let before : String = match obj.get("before") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let after : String = match obj.get("after") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let semantic_diff : SemanticDiff? = match obj.get("semanticDiff") {
    Some(value) => (SemanticDiff::from_json(value))
    None => None
  }
  let component_diff : ComponentDiff? = match obj.get("componentDiff") {
    Some(value) => (ComponentDiff::from_json(value))
    None => None
  }
  let before_record : DiffChangeBeforeRecord? = DiffChangeBeforeRecord::from_json(j)
  let after_record : DiffChangeAfterRecord? = DiffChangeAfterRecord::from_json(j)
  Some({ kind, id, path, level, before, after, semantic_diff, component_diff, before_record, after_record })
}

///|
pub fn DiffChange::to_json_string(self : DiffChange) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn DiffChange::from_json_string(s : String) -> Result[DiffChange, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match DiffChange::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub fn DiffChangeBeforeRecord::to_json(self : DiffChangeBeforeRecord) -> Json {
  match self {
    DiffChangeBeforeRecord::BeforeDeclaration(value) => {
      let obj : Map[String, Json] = {}
      obj["beforeDeclaration"] = value.to_json()
      Json::object(obj)
    }
    DiffChangeBeforeRecord::BeforeSymbol(value) => {
      let obj : Map[String, Json] = {}
      obj["beforeSymbol"] = value.to_json()
      Json::object(obj)
    }
    DiffChangeBeforeRecord::BeforeSoftwareComponent(value) => {
      let obj : Map[String, Json] = {}
      obj["beforeSoftwareComponent"] = value.to_json()
      Json::object(obj)
    }
  }
}

///|
pub fn DiffChangeBeforeRecord::from_json(j : Json) -> DiffChangeBeforeRecord? {
  guard j is Object(obj) else { return None }
  match obj.get("beforeDeclaration") {
    Some(value) => match (Declaration::from_json(value)) {
      Some(parsed) => return Some(DiffChangeBeforeRecord::BeforeDeclaration(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("beforeSymbol") {
    Some(value) => match (Symbol::from_json(value)) {
      Some(parsed) => return Some(DiffChangeBeforeRecord::BeforeSymbol(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("beforeSoftwareComponent") {
    Some(value) => match (SoftwareComponent::from_json(value)) {
      Some(parsed) => return Some(DiffChangeBeforeRecord::BeforeSoftwareComponent(parsed))
      None => return None
    }
    None => ()
  }
  None
}

///|
pub fn DiffChangeAfterRecord::to_json(self : DiffChangeAfterRecord) -> Json {
  match self {
    DiffChangeAfterRecord::AfterDeclaration(value) => {
      let obj : Map[String, Json] = {}
      obj["afterDeclaration"] = value.to_json()
      Json::object(obj)
    }
    DiffChangeAfterRecord::AfterSymbol(value) => {
      let obj : Map[String, Json] = {}
      obj["afterSymbol"] = value.to_json()
      Json::object(obj)
    }
    DiffChangeAfterRecord::AfterSoftwareComponent(value) => {
      let obj : Map[String, Json] = {}
      obj["afterSoftwareComponent"] = value.to_json()
      Json::object(obj)
    }
  }
}

///|
pub fn DiffChangeAfterRecord::from_json(j : Json) -> DiffChangeAfterRecord? {
  guard j is Object(obj) else { return None }
  match obj.get("afterDeclaration") {
    Some(value) => match (Declaration::from_json(value)) {
      Some(parsed) => return Some(DiffChangeAfterRecord::AfterDeclaration(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("afterSymbol") {
    Some(value) => match (Symbol::from_json(value)) {
      Some(parsed) => return Some(DiffChangeAfterRecord::AfterSymbol(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("afterSoftwareComponent") {
    Some(value) => match (SoftwareComponent::from_json(value)) {
      Some(parsed) => return Some(DiffChangeAfterRecord::AfterSoftwareComponent(parsed))
      None => return None
    }
    None => ()
  }
  None
}

///|
pub(all) struct DiffSummary {
  added : Int
  removed : Int
  changed : Int
  deprecated : Int
} derive(Eq)

///|
pub fn DiffSummary::to_json(self : DiffSummary) -> Json {
  let obj : Map[String, Json] = {}
  obj["added"] = Json::number((self.added).to_double(), repr="\{self.added}")
  obj["removed"] = Json::number((self.removed).to_double(), repr="\{self.removed}")
  obj["changed"] = Json::number((self.changed).to_double(), repr="\{self.changed}")
  obj["deprecated"] = Json::number((self.deprecated).to_double(), repr="\{self.deprecated}")
  Json::object(obj)
}

///|
pub fn DiffSummary::from_json(j : Json) -> DiffSummary? {
  guard j is Object(obj) else { return None }
  let added : Int = match obj.get("added") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let removed : Int = match obj.get("removed") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let changed : Int = match obj.get("changed") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let deprecated : Int = match obj.get("deprecated") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ added, removed, changed, deprecated })
}

///|
pub fn DiffSummary::to_json_string(self : DiffSummary) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn DiffSummary::from_json_string(s : String) -> Result[DiffSummary, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match DiffSummary::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct TestTracking {
  traceability_key : String
  external_ids : Array[String]
} derive(Eq)

///|
pub fn TestTracking::to_json(self : TestTracking) -> Json {
  let obj : Map[String, Json] = {}
  obj["traceabilityKey"] = Json::string(self.traceability_key)
  obj["externalIds"] = Json::array(self.external_ids.map(fn(item) { Json::string(item) }))
  Json::object(obj)
}

///|
pub fn TestTracking::from_json(j : Json) -> TestTracking? {
  guard j is Object(obj) else { return None }
  let traceability_key : String = match obj.get("traceabilityKey") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let external_ids : Array[String] = match obj.get("externalIds") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[String] = []
      for item in items {
        match (match item { String(text) => Some(text) ; _ => None }) {
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
  Some({ traceability_key, external_ids })
}

///|
pub fn TestTracking::to_json_string(self : TestTracking) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn TestTracking::from_json_string(s : String) -> Result[TestTracking, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match TestTracking::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct TestChange {
  kind : TestChangeKind
  language : String
  id : String
  path : String
  signature : String
  location : SourceLocation?
  tracking : TestTracking?
} derive(Eq)

///|
pub fn TestChange::to_json(self : TestChange) -> Json {
  let obj : Map[String, Json] = {}
  obj["kind"] = self.kind.to_json()
  obj["language"] = Json::string(self.language)
  obj["id"] = Json::string(self.id)
  obj["path"] = Json::string(self.path)
  obj["signature"] = Json::string(self.signature)
  match self.location {
    Some(value) => obj["location"] = value.to_json()
    None => ()
  }
  match self.tracking {
    Some(value) => obj["tracking"] = value.to_json()
    None => ()
  }
  Json::object(obj)
}

///|
pub fn TestChange::from_json(j : Json) -> TestChange? {
  guard j is Object(obj) else { return None }
  let kind : TestChangeKind = match obj.get("kind") {
    Some(value) => match (TestChangeKind::from_json(value)) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let language : String = match obj.get("language") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let id : String = match obj.get("id") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let path : String = match obj.get("path") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let signature : String = match obj.get("signature") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let location : SourceLocation? = match obj.get("location") {
    Some(value) => (SourceLocation::from_json(value))
    None => None
  }
  let tracking : TestTracking? = match obj.get("tracking") {
    Some(value) => (TestTracking::from_json(value))
    None => None
  }
  Some({ kind, language, id, path, signature, location, tracking })
}

///|
pub fn TestChange::to_json_string(self : TestChange) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn TestChange::from_json_string(s : String) -> Result[TestChange, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match TestChange::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct TestChangeSummary {
  added : Int
  modified : Int
  removed : Int
} derive(Eq)

///|
pub fn TestChangeSummary::to_json(self : TestChangeSummary) -> Json {
  let obj : Map[String, Json] = {}
  obj["added"] = Json::number((self.added).to_double(), repr="\{self.added}")
  obj["modified"] = Json::number((self.modified).to_double(), repr="\{self.modified}")
  obj["removed"] = Json::number((self.removed).to_double(), repr="\{self.removed}")
  Json::object(obj)
}

///|
pub fn TestChangeSummary::from_json(j : Json) -> TestChangeSummary? {
  guard j is Object(obj) else { return None }
  let added : Int = match obj.get("added") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let modified : Int = match obj.get("modified") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let removed : Int = match obj.get("removed") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ added, modified, removed })
}

///|
pub fn TestChangeSummary::to_json_string(self : TestChangeSummary) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn TestChangeSummary::from_json_string(s : String) -> Result[TestChangeSummary, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match TestChangeSummary::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct Diff {
  schema_version : String
  base_purl : String
  target_purl : String
  since : String
  summary : DiffSummary?
  changes : Array[DiffChange]
  include_test_changes : Bool
  test_summary : TestChangeSummary?
  test_changes : Array[TestChange]
  base_bundle : DiffBundleRef?
  target_bundle : DiffBundleRef?
} derive(Eq)

///|
pub fn Diff::to_json(self : Diff) -> Json {
  let obj : Map[String, Json] = {}
  obj["schemaVersion"] = Json::string(self.schema_version)
  obj["basePurl"] = Json::string(self.base_purl)
  obj["targetPurl"] = Json::string(self.target_purl)
  obj["since"] = Json::string(self.since)
  match self.summary {
    Some(value) => obj["summary"] = value.to_json()
    None => ()
  }
  obj["changes"] = Json::array(self.changes.map(fn(item) { item.to_json() }))
  obj["includeTestChanges"] = Json::boolean(self.include_test_changes)
  match self.test_summary {
    Some(value) => obj["testSummary"] = value.to_json()
    None => ()
  }
  obj["testChanges"] = Json::array(self.test_changes.map(fn(item) { item.to_json() }))
  match self.base_bundle {
    Some(value) => obj["baseBundle"] = value.to_json()
    None => ()
  }
  match self.target_bundle {
    Some(value) => obj["targetBundle"] = value.to_json()
    None => ()
  }
  Json::object(obj)
}

///|
pub fn Diff::from_json(j : Json) -> Diff? {
  guard j is Object(obj) else { return None }
  let schema_version : String = match obj.get("schemaVersion") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let base_purl : String = match obj.get("basePurl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let target_purl : String = match obj.get("targetPurl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let since : String = match obj.get("since") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let summary : DiffSummary? = match obj.get("summary") {
    Some(value) => (DiffSummary::from_json(value))
    None => None
  }
  let changes : Array[DiffChange] = match obj.get("changes") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[DiffChange] = []
      for item in items {
        match (DiffChange::from_json(item)) {
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
  let include_test_changes : Bool = match obj.get("includeTestChanges") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let test_summary : TestChangeSummary? = match obj.get("testSummary") {
    Some(value) => (TestChangeSummary::from_json(value))
    None => None
  }
  let test_changes : Array[TestChange] = match obj.get("testChanges") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[TestChange] = []
      for item in items {
        match (TestChange::from_json(item)) {
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
  let base_bundle : DiffBundleRef? = match obj.get("baseBundle") {
    Some(value) => (DiffBundleRef::from_json(value))
    None => None
  }
  let target_bundle : DiffBundleRef? = match obj.get("targetBundle") {
    Some(value) => (DiffBundleRef::from_json(value))
    None => None
  }
  Some({ schema_version, base_purl, target_purl, since, summary, changes, include_test_changes, test_summary, test_changes, base_bundle, target_bundle })
}

///|
pub fn Diff::to_json_string(self : Diff) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn Diff::from_json_string(s : String) -> Result[Diff, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match Diff::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct DiffInput {
  path : String
  base_version : VersionRef?
  target_version : VersionRef?
  include_test_changes : Bool
} derive(Eq)

///|
pub fn DiffInput::to_json(self : DiffInput) -> Json {
  let obj : Map[String, Json] = {}
  obj["path"] = Json::string(self.path)
  match self.base_version {
    Some(value) => obj["baseVersion"] = value.to_json()
    None => ()
  }
  match self.target_version {
    Some(value) => obj["targetVersion"] = value.to_json()
    None => ()
  }
  obj["includeTestChanges"] = Json::boolean(self.include_test_changes)
  Json::object(obj)
}

///|
pub fn DiffInput::from_json(j : Json) -> DiffInput? {
  guard j is Object(obj) else { return None }
  let path : String = match obj.get("path") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let base_version : VersionRef? = match obj.get("baseVersion") {
    Some(value) => (VersionRef::from_json(value))
    None => None
  }
  let target_version : VersionRef? = match obj.get("targetVersion") {
    Some(value) => (VersionRef::from_json(value))
    None => None
  }
  let include_test_changes : Bool = match obj.get("includeTestChanges") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ path, base_version, target_version, include_test_changes })
}

///|
pub fn DiffInput::to_json_string(self : DiffInput) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn DiffInput::from_json_string(s : String) -> Result[DiffInput, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match DiffInput::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct DiffOutput {
  success : Bool
  diff : Diff?
  base_bundle : DiffBundleRef?
  target_bundle : DiffBundleRef?
  error : ErrorResponse?
} derive(Eq)

///|
pub fn DiffOutput::to_json(self : DiffOutput) -> Json {
  let obj : Map[String, Json] = {}
  obj["success"] = Json::boolean(self.success)
  match self.diff {
    Some(value) => obj["diff"] = value.to_json()
    None => ()
  }
  match self.base_bundle {
    Some(value) => obj["baseBundle"] = value.to_json()
    None => ()
  }
  match self.target_bundle {
    Some(value) => obj["targetBundle"] = value.to_json()
    None => ()
  }
  match self.error {
    Some(value) => obj["error"] = value.to_json()
    None => ()
  }
  Json::object(obj)
}

///|
pub fn DiffOutput::from_json(j : Json) -> DiffOutput? {
  guard j is Object(obj) else { return None }
  let success : Bool = match obj.get("success") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let diff : Diff? = match obj.get("diff") {
    Some(value) => (Diff::from_json(value))
    None => None
  }
  let base_bundle : DiffBundleRef? = match obj.get("baseBundle") {
    Some(value) => (DiffBundleRef::from_json(value))
    None => None
  }
  let target_bundle : DiffBundleRef? = match obj.get("targetBundle") {
    Some(value) => (DiffBundleRef::from_json(value))
    None => None
  }
  let error : ErrorResponse? = match obj.get("error") {
    Some(value) => (ErrorResponse::from_json(value))
    None => None
  }
  Some({ success, diff, base_bundle, target_bundle, error })
}

///|
pub fn DiffOutput::to_json_string(self : DiffOutput) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn DiffOutput::from_json_string(s : String) -> Result[DiffOutput, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match DiffOutput::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}


