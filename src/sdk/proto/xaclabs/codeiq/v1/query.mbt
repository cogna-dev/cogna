///|
pub(all) enum BuiltinTable {
  BuiltinTableUnspecified
  BuiltinTableBundleManifest
  BuiltinTableBundleChecksums
  BuiltinTableDeclarations
  BuiltinTableDeclarationSourceRefs
  BuiltinTableDeclarationRelations
  BuiltinTableSymbols
  BuiltinTableSoftwareComponents
  BuiltinTableComponentHashes
  BuiltinTableCodeiqTables
  BuiltinTableCodeiqColumns
} derive(Eq, Debug)

///|
pub fn BuiltinTable::to_json(self : BuiltinTable) -> Json {
  match self {
    BuiltinTable::BuiltinTableUnspecified => Json::string("BUILTIN_TABLE_UNSPECIFIED")
    BuiltinTable::BuiltinTableBundleManifest => Json::string("BUILTIN_TABLE_BUNDLE_MANIFEST")
    BuiltinTable::BuiltinTableBundleChecksums => Json::string("BUILTIN_TABLE_BUNDLE_CHECKSUMS")
    BuiltinTable::BuiltinTableDeclarations => Json::string("BUILTIN_TABLE_DECLARATIONS")
    BuiltinTable::BuiltinTableDeclarationSourceRefs => Json::string("BUILTIN_TABLE_DECLARATION_SOURCE_REFS")
    BuiltinTable::BuiltinTableDeclarationRelations => Json::string("BUILTIN_TABLE_DECLARATION_RELATIONS")
    BuiltinTable::BuiltinTableSymbols => Json::string("BUILTIN_TABLE_SYMBOLS")
    BuiltinTable::BuiltinTableSoftwareComponents => Json::string("BUILTIN_TABLE_SOFTWARE_COMPONENTS")
    BuiltinTable::BuiltinTableComponentHashes => Json::string("BUILTIN_TABLE_COMPONENT_HASHES")
    BuiltinTable::BuiltinTableCodeiqTables => Json::string("BUILTIN_TABLE_CODEIQ_TABLES")
    BuiltinTable::BuiltinTableCodeiqColumns => Json::string("BUILTIN_TABLE_CODEIQ_COLUMNS")
  }
}

///|
pub fn BuiltinTable::from_json(j : Json) -> BuiltinTable? {
  match j {
    String("BUILTIN_TABLE_UNSPECIFIED") => Some(BuiltinTable::BuiltinTableUnspecified)
    String("BUILTIN_TABLE_BUNDLE_MANIFEST") => Some(BuiltinTable::BuiltinTableBundleManifest)
    String("BUILTIN_TABLE_BUNDLE_CHECKSUMS") => Some(BuiltinTable::BuiltinTableBundleChecksums)
    String("BUILTIN_TABLE_DECLARATIONS") => Some(BuiltinTable::BuiltinTableDeclarations)
    String("BUILTIN_TABLE_DECLARATION_SOURCE_REFS") => Some(BuiltinTable::BuiltinTableDeclarationSourceRefs)
    String("BUILTIN_TABLE_DECLARATION_RELATIONS") => Some(BuiltinTable::BuiltinTableDeclarationRelations)
    String("BUILTIN_TABLE_SYMBOLS") => Some(BuiltinTable::BuiltinTableSymbols)
    String("BUILTIN_TABLE_SOFTWARE_COMPONENTS") => Some(BuiltinTable::BuiltinTableSoftwareComponents)
    String("BUILTIN_TABLE_COMPONENT_HASHES") => Some(BuiltinTable::BuiltinTableComponentHashes)
    String("BUILTIN_TABLE_CODEIQ_TABLES") => Some(BuiltinTable::BuiltinTableCodeiqTables)
    String("BUILTIN_TABLE_CODEIQ_COLUMNS") => Some(BuiltinTable::BuiltinTableCodeiqColumns)
    _ => None
  }
}

///|
pub(all) enum ColumnType {
  ColumnTypeUnspecified
  ColumnTypeString
  ColumnTypeBool
  ColumnTypeInt64
  ColumnTypeDouble
  ColumnTypeBytes
  ColumnTypeJson
} derive(Eq, Debug)

///|
pub fn ColumnType::to_json(self : ColumnType) -> Json {
  match self {
    ColumnType::ColumnTypeUnspecified => Json::string("COLUMN_TYPE_UNSPECIFIED")
    ColumnType::ColumnTypeString => Json::string("COLUMN_TYPE_STRING")
    ColumnType::ColumnTypeBool => Json::string("COLUMN_TYPE_BOOL")
    ColumnType::ColumnTypeInt64 => Json::string("COLUMN_TYPE_INT64")
    ColumnType::ColumnTypeDouble => Json::string("COLUMN_TYPE_DOUBLE")
    ColumnType::ColumnTypeBytes => Json::string("COLUMN_TYPE_BYTES")
    ColumnType::ColumnTypeJson => Json::string("COLUMN_TYPE_JSON")
  }
}

///|
pub fn ColumnType::from_json(j : Json) -> ColumnType? {
  match j {
    String("COLUMN_TYPE_UNSPECIFIED") => Some(ColumnType::ColumnTypeUnspecified)
    String("COLUMN_TYPE_STRING") => Some(ColumnType::ColumnTypeString)
    String("COLUMN_TYPE_BOOL") => Some(ColumnType::ColumnTypeBool)
    String("COLUMN_TYPE_INT64") => Some(ColumnType::ColumnTypeInt64)
    String("COLUMN_TYPE_DOUBLE") => Some(ColumnType::ColumnTypeDouble)
    String("COLUMN_TYPE_BYTES") => Some(ColumnType::ColumnTypeBytes)
    String("COLUMN_TYPE_JSON") => Some(ColumnType::ColumnTypeJson)
    _ => None
  }
}

///|
pub(all) struct QueryTarget {
  purl : String
  bundle_id : String
  bundle_path : String
} derive(Eq)

///|
pub fn QueryTarget::to_json(self : QueryTarget) -> Json {
  let obj : Map[String, Json] = {}
  obj["purl"] = Json::string(self.purl)
  obj["bundleId"] = Json::string(self.bundle_id)
  obj["bundlePath"] = Json::string(self.bundle_path)
  Json::object(obj)
}

///|
pub fn QueryTarget::from_json(j : Json) -> QueryTarget? {
  guard j is Object(obj) else { return None }
  let purl : String = match obj.get("purl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let bundle_id : String = match obj.get("bundleId") {
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
  Some({ purl, bundle_id, bundle_path })
}

///|
pub fn QueryTarget::to_json_string(self : QueryTarget) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryTarget::from_json_string(s : String) -> Result[QueryTarget, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryTarget::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct QueryOptions {
  limit : Int
  cursor : String
  include_catalog : Bool
} derive(Eq)

///|
pub fn QueryOptions::to_json(self : QueryOptions) -> Json {
  let obj : Map[String, Json] = {}
  obj["limit"] = Json::number((self.limit).to_double(), repr="\{self.limit}")
  obj["cursor"] = Json::string(self.cursor)
  obj["includeCatalog"] = Json::boolean(self.include_catalog)
  Json::object(obj)
}

///|
pub fn QueryOptions::from_json(j : Json) -> QueryOptions? {
  guard j is Object(obj) else { return None }
  let limit : Int = match obj.get("limit") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let cursor : String = match obj.get("cursor") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let include_catalog : Bool = match obj.get("includeCatalog") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ limit, cursor, include_catalog })
}

///|
pub fn QueryOptions::to_json_string(self : QueryOptions) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryOptions::from_json_string(s : String) -> Result[QueryOptions, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryOptions::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct ColumnSchema {
  name : String
  type_ : ColumnType
  nullable : Bool
  description : String
  source_field : String
} derive(Eq)

///|
pub fn ColumnSchema::to_json(self : ColumnSchema) -> Json {
  let obj : Map[String, Json] = {}
  obj["name"] = Json::string(self.name)
  obj["type"] = self.type_.to_json()
  obj["nullable"] = Json::boolean(self.nullable)
  obj["description"] = Json::string(self.description)
  obj["sourceField"] = Json::string(self.source_field)
  Json::object(obj)
}

///|
pub fn ColumnSchema::from_json(j : Json) -> ColumnSchema? {
  guard j is Object(obj) else { return None }
  let name : String = match obj.get("name") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let type_ : ColumnType = match obj.get("type") {
    Some(value) => match (ColumnType::from_json(value)) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let nullable : Bool = match obj.get("nullable") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let description : String = match obj.get("description") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let source_field : String = match obj.get("sourceField") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ name, type_, nullable, description, source_field })
}

///|
pub fn ColumnSchema::to_json_string(self : ColumnSchema) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn ColumnSchema::from_json_string(s : String) -> Result[ColumnSchema, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match ColumnSchema::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct TableSchema {
  table : BuiltinTable
  name : String
  description : String
  columns : Array[ColumnSchema]
  primary_key : Array[String]
} derive(Eq)

///|
pub fn TableSchema::to_json(self : TableSchema) -> Json {
  let obj : Map[String, Json] = {}
  obj["table"] = self.table.to_json()
  obj["name"] = Json::string(self.name)
  obj["description"] = Json::string(self.description)
  obj["columns"] = Json::array(self.columns.map(fn(item) { item.to_json() }))
  obj["primaryKey"] = Json::array(self.primary_key.map(fn(item) { Json::string(item) }))
  Json::object(obj)
}

///|
pub fn TableSchema::from_json(j : Json) -> TableSchema? {
  guard j is Object(obj) else { return None }
  let table : BuiltinTable = match obj.get("table") {
    Some(value) => match (BuiltinTable::from_json(value)) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let name : String = match obj.get("name") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let description : String = match obj.get("description") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let columns : Array[ColumnSchema] = match obj.get("columns") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[ColumnSchema] = []
      for item in items {
        match (ColumnSchema::from_json(item)) {
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
  let primary_key : Array[String] = match obj.get("primaryKey") {
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
  Some({ table, name, description, columns, primary_key })
}

///|
pub fn TableSchema::to_json_string(self : TableSchema) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn TableSchema::from_json_string(s : String) -> Result[TableSchema, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match TableSchema::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct QueryCatalog {
  schema_version : String
  purl : String
  tables : Array[TableSchema]
} derive(Eq)

///|
pub fn QueryCatalog::to_json(self : QueryCatalog) -> Json {
  let obj : Map[String, Json] = {}
  obj["schemaVersion"] = Json::string(self.schema_version)
  obj["purl"] = Json::string(self.purl)
  obj["tables"] = Json::array(self.tables.map(fn(item) { item.to_json() }))
  Json::object(obj)
}

///|
pub fn QueryCatalog::from_json(j : Json) -> QueryCatalog? {
  guard j is Object(obj) else { return None }
  let schema_version : String = match obj.get("schemaVersion") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let purl : String = match obj.get("purl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let tables : Array[TableSchema] = match obj.get("tables") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[TableSchema] = []
      for item in items {
        match (TableSchema::from_json(item)) {
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
  Some({ schema_version, purl, tables })
}

///|
pub fn QueryCatalog::to_json_string(self : QueryCatalog) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryCatalog::from_json_string(s : String) -> Result[QueryCatalog, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryCatalog::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) enum QueryValueKind {
  NullValue(Json)
  BoolValue(Bool)
  Int64Value(Int64)
  DoubleValue(Double)
  StringValue(String)
  BytesValue(Bytes)
  JsonValue(Json)
} derive(Eq)

///|
pub(all) struct QueryValue {
  kind : QueryValueKind?
} derive(Eq)

///|
pub fn QueryValue::to_json(self : QueryValue) -> Json {
  let obj : Map[String, Json] = {}
  match self.kind {
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
pub fn QueryValue::from_json(j : Json) -> QueryValue? {
  guard j is Object(_) else { return None }
  let kind : QueryValueKind? = QueryValueKind::from_json(j)
  Some({ kind, })
}

///|
pub fn QueryValue::to_json_string(self : QueryValue) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryValue::from_json_string(s : String) -> Result[QueryValue, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryValue::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub fn QueryValueKind::to_json(self : QueryValueKind) -> Json {
  match self {
    QueryValueKind::NullValue(value) => {
      let obj : Map[String, Json] = {}
      obj["nullValue"] = value
      Json::object(obj)
    }
    QueryValueKind::BoolValue(value) => {
      let obj : Map[String, Json] = {}
      obj["boolValue"] = Json::boolean(value)
      Json::object(obj)
    }
    QueryValueKind::Int64Value(value) => {
      let obj : Map[String, Json] = {}
      obj["int64Value"] = Json::number((value).to_double(), repr="\{value}")
      Json::object(obj)
    }
    QueryValueKind::DoubleValue(value) => {
      let obj : Map[String, Json] = {}
      obj["doubleValue"] = Json::number(value, repr="\{value}")
      Json::object(obj)
    }
    QueryValueKind::StringValue(value) => {
      let obj : Map[String, Json] = {}
      obj["stringValue"] = Json::string(value)
      Json::object(obj)
    }
    QueryValueKind::BytesValue(value) => {
      let obj : Map[String, Json] = {}
      obj["bytesValue"] = Json::string(url_encode_bytes(value))
      Json::object(obj)
    }
    QueryValueKind::JsonValue(value) => {
      let obj : Map[String, Json] = {}
      obj["jsonValue"] = value
      Json::object(obj)
    }
  }
}

///|
pub fn QueryValueKind::from_json(j : Json) -> QueryValueKind? {
  guard j is Object(obj) else { return None }
  match obj.get("nullValue") {
    Some(value) => match (Some(value)) {
      Some(parsed) => return Some(QueryValueKind::NullValue(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("boolValue") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => return Some(QueryValueKind::BoolValue(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("int64Value") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int64()) ; _ => None }) {
      Some(parsed) => return Some(QueryValueKind::Int64Value(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("doubleValue") {
    Some(value) => match (match value { Number(value, ..) => Some(value) ; _ => None }) {
      Some(parsed) => return Some(QueryValueKind::DoubleValue(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("stringValue") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => return Some(QueryValueKind::StringValue(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("bytesValue") {
    Some(value) => match (match value { String(text) => decode_url_bytes(text) ; _ => None }) {
      Some(parsed) => return Some(QueryValueKind::BytesValue(parsed))
      None => return None
    }
    None => ()
  }
  match obj.get("jsonValue") {
    Some(value) => match (Some(value)) {
      Some(parsed) => return Some(QueryValueKind::JsonValue(parsed))
      None => return None
    }
    None => ()
  }
  None
}

///|
pub(all) struct QueryRow {
  values : Array[QueryValue]
} derive(Eq)

///|
pub fn QueryRow::to_json(self : QueryRow) -> Json {
  let obj : Map[String, Json] = {}
  obj["values"] = Json::array(self.values.map(fn(item) { item.to_json() }))
  Json::object(obj)
}

///|
pub fn QueryRow::from_json(j : Json) -> QueryRow? {
  guard j is Object(obj) else { return None }
  let values : Array[QueryValue] = match obj.get("values") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[QueryValue] = []
      for item in items {
        match (QueryValue::from_json(item)) {
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
  Some({ values, })
}

///|
pub fn QueryRow::to_json_string(self : QueryRow) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryRow::from_json_string(s : String) -> Result[QueryRow, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryRow::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct QueryResultSet {
  columns : Array[ColumnSchema]
  rows : Array[QueryRow]
  cursor : String
  row_count : Int64
  truncated : Bool
} derive(Eq)

///|
pub fn QueryResultSet::to_json(self : QueryResultSet) -> Json {
  let obj : Map[String, Json] = {}
  obj["columns"] = Json::array(self.columns.map(fn(item) { item.to_json() }))
  obj["rows"] = Json::array(self.rows.map(fn(item) { item.to_json() }))
  obj["cursor"] = Json::string(self.cursor)
  obj["rowCount"] = Json::number((self.row_count).to_double(), repr="\{self.row_count}")
  obj["truncated"] = Json::boolean(self.truncated)
  Json::object(obj)
}

///|
pub fn QueryResultSet::from_json(j : Json) -> QueryResultSet? {
  guard j is Object(obj) else { return None }
  let columns : Array[ColumnSchema] = match obj.get("columns") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[ColumnSchema] = []
      for item in items {
        match (ColumnSchema::from_json(item)) {
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
  let rows : Array[QueryRow] = match obj.get("rows") {
    Some(value) => match (match value {
    Array(items) => {
      let parsed : Array[QueryRow] = []
      for item in items {
        match (QueryRow::from_json(item)) {
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
  let cursor : String = match obj.get("cursor") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let row_count : Int64 = match obj.get("rowCount") {
    Some(value) => match (match value { Number(value, ..) => Some(value.to_int64()) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let truncated : Bool = match obj.get("truncated") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ columns, rows, cursor, row_count, truncated })
}

///|
pub fn QueryResultSet::to_json_string(self : QueryResultSet) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryResultSet::from_json_string(s : String) -> Result[QueryResultSet, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryResultSet::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct QueryExecution {
  dialect : String
  normalized_sql : String
  bundle_purl : String
} derive(Eq)

///|
pub fn QueryExecution::to_json(self : QueryExecution) -> Json {
  let obj : Map[String, Json] = {}
  obj["dialect"] = Json::string(self.dialect)
  obj["normalizedSql"] = Json::string(self.normalized_sql)
  obj["bundlePurl"] = Json::string(self.bundle_purl)
  Json::object(obj)
}

///|
pub fn QueryExecution::from_json(j : Json) -> QueryExecution? {
  guard j is Object(obj) else { return None }
  let dialect : String = match obj.get("dialect") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let normalized_sql : String = match obj.get("normalizedSql") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let bundle_purl : String = match obj.get("bundlePurl") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  Some({ dialect, normalized_sql, bundle_purl })
}

///|
pub fn QueryExecution::to_json_string(self : QueryExecution) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryExecution::from_json_string(s : String) -> Result[QueryExecution, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryExecution::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct QueryInput {
  target : QueryTarget?
  sql : String
  options : QueryOptions?
} derive(Eq)

///|
pub fn QueryInput::to_json(self : QueryInput) -> Json {
  let obj : Map[String, Json] = {}
  match self.target {
    Some(value) => obj["target"] = value.to_json()
    None => ()
  }
  obj["sql"] = Json::string(self.sql)
  match self.options {
    Some(value) => obj["options"] = value.to_json()
    None => ()
  }
  Json::object(obj)
}

///|
pub fn QueryInput::from_json(j : Json) -> QueryInput? {
  guard j is Object(obj) else { return None }
  let target : QueryTarget? = match obj.get("target") {
    Some(value) => (QueryTarget::from_json(value))
    None => None
  }
  let sql : String = match obj.get("sql") {
    Some(value) => match (match value { String(text) => Some(text) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let options : QueryOptions? = match obj.get("options") {
    Some(value) => (QueryOptions::from_json(value))
    None => None
  }
  Some({ target, sql, options })
}

///|
pub fn QueryInput::to_json_string(self : QueryInput) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryInput::from_json_string(s : String) -> Result[QueryInput, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryInput::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}

///|
pub(all) struct QueryOutput {
  success : Bool
  result_set : QueryResultSet?
  catalog : QueryCatalog?
  execution : QueryExecution?
  error : ErrorResponse?
} derive(Eq)

///|
pub fn QueryOutput::to_json(self : QueryOutput) -> Json {
  let obj : Map[String, Json] = {}
  obj["success"] = Json::boolean(self.success)
  match self.result_set {
    Some(value) => obj["resultSet"] = value.to_json()
    None => ()
  }
  match self.catalog {
    Some(value) => obj["catalog"] = value.to_json()
    None => ()
  }
  match self.execution {
    Some(value) => obj["execution"] = value.to_json()
    None => ()
  }
  match self.error {
    Some(value) => obj["error"] = value.to_json()
    None => ()
  }
  Json::object(obj)
}

///|
pub fn QueryOutput::from_json(j : Json) -> QueryOutput? {
  guard j is Object(obj) else { return None }
  let success : Bool = match obj.get("success") {
    Some(value) => match (match value { True => Some(true) ; False => Some(false) ; _ => None }) {
      Some(parsed) => parsed
      None => return None
    }
    None => return None
  }
  let result_set : QueryResultSet? = match obj.get("resultSet") {
    Some(value) => (QueryResultSet::from_json(value))
    None => None
  }
  let catalog : QueryCatalog? = match obj.get("catalog") {
    Some(value) => (QueryCatalog::from_json(value))
    None => None
  }
  let execution : QueryExecution? = match obj.get("execution") {
    Some(value) => (QueryExecution::from_json(value))
    None => None
  }
  let error : ErrorResponse? = match obj.get("error") {
    Some(value) => (ErrorResponse::from_json(value))
    None => None
  }
  Some({ success, result_set, catalog, execution, error })
}

///|
pub fn QueryOutput::to_json_string(self : QueryOutput) -> Result[String, String] {
  Ok(self.to_json().stringify())
}

///|
pub fn QueryOutput::from_json_string(s : String) -> Result[QueryOutput, String] {
  let parsed = try? @json.parse(s)
  guard parsed is Ok(value) else { return Err("invalid json") }
  match QueryOutput::from_json(value) {
    Some(out) => Ok(out)
    None => Err("type mismatch")
  }
}


