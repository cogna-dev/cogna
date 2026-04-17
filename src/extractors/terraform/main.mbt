///|
priv struct TerraformProviderInfo {
  name : String
  source : String
  version : String
  provider_alias : String
}

///|
priv struct HclAttr {
  name : String
  value : String
}

///|
priv struct HclBlock {
  kind : String
  name : String
  signature : String
  line_no : Int
  col_no : Int
  attrs : Array[HclAttr]
}

///|
priv struct HclFile {
  blocks : Array[HclBlock]
}

///|
fn segment_after(value : String, marker : String) -> String? {
  match value.find(marker) {
    Some(idx) => Some(value[idx + marker.length():].to_string())
    None => None
  }
}

///|
fn parse_bool_literal(value : String) -> Bool? {
  match @extract.trim_quotes(@extract.trim_spaces(value)) {
    "true" => Some(true)
    "false" => Some(false)
    _ => None
  }
}

///|
fn trim_line(s : String) -> String {
  let mut start = 0
  while start < s.length() &&
        (
          s.code_unit_at(start) == ' ' ||
          s.code_unit_at(start) == '\t' ||
          s.code_unit_at(start) == '\r'
        ) {
    start = start + 1
  }
  let mut end = s.length()
  while end > start &&
        (
          s.code_unit_at(end - 1) == ' ' ||
          s.code_unit_at(end - 1) == '\t' ||
          s.code_unit_at(end - 1) == '\r' ||
          s.code_unit_at(end - 1) == '\n'
        ) {
    end = end - 1
  }
  if start >= end {
    ""
  } else {
    s[start:end].to_string()
  }
}

///|
fn parse_inline_comment_start(line : String) -> Int? {
  let mut i = 0
  let mut in_string = false
  let mut escaped = false
  while i < line.length() {
    let c = line.code_unit_at(i)
    if in_string {
      if escaped {
        escaped = false
      } else if c == '\\' {
        escaped = true
      } else if c == '"' {
        in_string = false
      }
      i += 1
      continue
    }
    if c == '"' {
      in_string = true
      i += 1
      continue
    }
    if c == '#' {
      return Some(i)
    }
    if c == '/' && i + 1 < line.length() && line.code_unit_at(i + 1) == '/' {
      return Some(i)
    }
    i += 1
  }
  None
}

///|
fn strip_inline_comment(line : String) -> String {
  match parse_inline_comment_start(line) {
    Some(idx) => line[0:idx].to_string() |> trim_line
    None => trim_line(line)
  }
}

///|
fn hcl_block_name(kind : String, labels : Array[String]) -> String {
  match kind {
    "locals" | "terraform" => kind
    "resource" | "data" if labels.length() >= 2 => "\{labels[0]}.\{labels[1]}"
    "variable" | "output" | "module" | "provider" | "dynamic" | "check" if labels.length() >=
      1 => labels[0]
    _ => ""
  }
}

///|
fn reconstruct_signature(kind : String, labels : Array[String]) -> String {
  if labels.is_empty() {
    "\{kind} {"
  } else {
    let quoted = labels.map(label => "\"\{label}\"").join(" ")
    "\{kind} \{quoted} {"
  }
}

///|
fn block_signature(
  lines : Array[String],
  line_no : Int,
  kind : String,
  labels : Array[String],
) -> String {
  if line_no > 0 && line_no <= lines.length() {
    strip_inline_comment(lines[line_no - 1].to_string())
  } else {
    reconstruct_signature(kind, labels)
  }
}

///|
fn expression_to_text(expr : @hcl.Expression) -> String {
  match expr {
    @hcl.Expression::String(value) => "\"\{value}\""
    @hcl.Expression::Number(value) => "\{value}"
    @hcl.Expression::Bool(value) => if value { "true" } else { "false" }
    @hcl.Expression::Null => "null"
    @hcl.Expression::Identifier(value) => value
    @hcl.Expression::List(values) => {
      let rendered = values.map(expression_to_text).join(", ")
      "[\{rendered}]"
    }
    @hcl.Expression::Object(entries) => {
      let parts : Array[String] = []
      for key, value in entries {
        parts.push("\{key} = \{expression_to_text(value)}")
      }
      let rendered = parts.join(", ")
      "{ \{rendered} }"
    }
  }
}

///|
fn collect_hcl_attrs(body : @hcl.Body) -> Array[HclAttr] {
  let attrs : Array[HclAttr] = []
  for item in body.items {
    match item {
      @hcl.BodyItem::Attribute(attr) =>
        attrs.push({
          name: attr.key,
          value: expression_to_text(attr.value),
        })
      @hcl.BodyItem::Block(_) => ()
    }
  }
  attrs
}

///|
fn collect_hcl_block(
  block : @hcl.Block,
  lines : Array[String],
  blocks : Array[HclBlock],
) -> Unit {
  for item in block.body.items {
    match item {
      @hcl.BodyItem::Attribute(_) => ()
      @hcl.BodyItem::Block(nested) => collect_hcl_block(nested, lines, blocks)
    }
  }
  let kind = block.type_
  let name = hcl_block_name(kind, block.labels)
  if name == "" {
    return
  }
  blocks.push({
    kind,
    name,
    signature: block_signature(lines, block.pos.line, kind, block.labels),
    line_no: block.pos.line,
    col_no: block.pos.col,
    attrs: collect_hcl_attrs(block.body),
  })
}

///|
fn parse_hcl_file(lines : Array[String]) -> HclFile {
  let text = lines.join("\n")
  let parsed : Result[@hcl.Document, @hcl.ParseHclError] = try? @hcl.parse(text)
  match parsed {
    Ok(doc) => {
      let blocks : Array[HclBlock] = []
      for item in doc.body.items {
        match item {
          @hcl.BodyItem::Attribute(_) => ()
          @hcl.BodyItem::Block(block) => collect_hcl_block(block, lines, blocks)
        }
      }
      { blocks, }
    }
    Err(_) => { blocks: [] }
  }
}

///|
fn push_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  language : String,
  path : String,
  line_no : Int,
  col_no : Int,
  kind : String,
  name : String,
  signature : String,
  docs : String,
) -> Unit {
  if name == "" {
    return
  }
  declarations.push(
    @extract.make_declaration(
      profile, server, language, path, line_no, kind, name, signature, docs,
    ),
  )
  guard @extract.last_record(declarations) is Some(record) else {
    let symbol = @extract.make_symbol(profile, path, line_no, kind, name, signature)
    set_column_position(symbol, col_no)
    symbols.push(symbol)
    return
  }
  set_column_position(record, col_no)
  enrich_record(record)
  let symbol = @extract.make_symbol(profile, path, line_no, kind, name, signature)
  set_column_position(symbol, col_no)
  symbols.push(symbol)
}

///|
fn push_simple_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  language : String,
  path : String,
  line_no : Int,
  col_no : Int,
  kind : String,
  name : String,
  signature : String,
) -> Unit {
  push_record(
    declarations,
    symbols,
    profile,
    server,
    language,
    path,
    line_no,
    col_no,
    kind,
    name,
    signature,
    "",
  )
}

///|
fn set_column_position(record : Json, col_no : Int) -> Unit {
  if col_no <= 0 {
    return
  }
  guard record is Object(record_object) else { return }
  match record_object.get("location") {
    Some(Object(location)) => {
      location["startColumn"] = col_no.to_json()
      location["endColumn"] = col_no.to_json()
    }
    _ => ()
  }
  match record_object.get("source_refs") {
    Some(Array(source_refs)) if source_refs.length() > 0 =>
      match source_refs[0] {
        Object(source_ref) => {
          source_ref["startColumn"] = col_no.to_json()
          source_ref["endColumn"] = col_no.to_json()
        }
        _ => ()
      }
    _ => ()
  }
}

///|
fn find_declaration_index(
  declarations : Array[Json],
  id : String,
  start : Int,
) -> Int? {
  for i in start..<declarations.length() {
    if @extract.field_string(declarations[i], "id") == id {
      return Some(i)
    }
  }
  None
}

///|
fn terraform_provider_json(info : TerraformProviderInfo) -> Json {
  let object : Map[String, Json] = { "name": Json::string(info.name) }
  if info.source != "" {
    object["source"] = Json::string(info.source)
  }
  if info.version != "" {
    object["version"] = Json::string(info.version)
  }
  if info.provider_alias != "" {
    object["alias"] = Json::string(info.provider_alias)
  }
  Json::object(object)
}

///|
fn set_terraform_providers(
  record : Json,
  providers : Array[TerraformProviderInfo],
) -> Unit {
  if providers.is_empty() {
    return
  }
  guard record is Object(record_object) else { return }
  guard record_object.get("language_specific")
    is Some(Object(language_specific)) else {
    return
  }
  let providers_object : Map[String, Json] = {}
  providers_object["terraform"] = Json::array(
    providers.map(info => terraform_provider_json(info)),
  )
  language_specific["providers"] = Json::object(providers_object)
}

///|
fn kind_name(line : String) -> (String, String) {
  if line.has_prefix("resource ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 2 {
      return ("resource", "\{parts[0]}.\{parts[1]}")
    }
  }
  if line.has_prefix("data ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 2 {
      return ("data", "\{parts[0]}.\{parts[1]}")
    }
  }
  if line.has_prefix("variable ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 1 {
      return ("variable", parts[0])
    }
  }
  if line.has_prefix("output ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 1 {
      return ("output", parts[0])
    }
  }
  if line.has_prefix("module ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 1 {
      return ("module", parts[0])
    }
  }
  if line.has_prefix("provider ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 1 {
      return ("provider", parts[0])
    }
  }
  if line.has_prefix("locals") && line.has_suffix("{") {
    return ("locals", "locals")
  }
  if line.has_prefix("dynamic ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 1 {
      return ("dynamic", parts[0])
    }
  }
  if line.has_prefix("check ") {
    let parts = @extract.quoted_parts(line)
    if parts.length() >= 1 {
      return ("check", parts[0])
    }
  }
  if line.has_prefix("terraform") && line.has_suffix("{") {
    return ("terraform", "terraform")
  }
  ("", "")
}

///|
fn language_record_name(active_block : String) -> String {
  match active_block.find(".") {
    Some(idx) if idx + 1 < active_block.length() =>
      active_block[idx + 1:].to_string()
    _ => active_block
  }
}

///|
fn set_metadata(
  declarations : Array[Json],
  profile : String,
  path : String,
  declaration_start : Int,
  target_name : String,
  key : String,
  value : Json,
) -> Unit {
  if target_name == "" {
    return
  }
  let decl_id = @extract.declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) => {
      guard @extract.ensure_language_specific_profile(
          declarations[idx],
          "terraform",
        )
        is Some(terraform) else {
        return
      }
      terraform[key] = value
    }
    None => ()
  }
}

///|
fn list_values(value : String) -> Array[String] {
  let body = @extract.trim_spaces(value)
  if body == "" {
    []
  } else {
    let trimmed = if body.has_prefix("[") && body.has_suffix("]") {
      body[1:body.length() - 1].to_string() |> @extract.trim_spaces
    } else {
      body
    }
    if trimmed == "" {
      []
    } else {
      @extract.split_top_level(trimmed, ',').map(part => {
        @extract.trim_quotes(@extract.trim_spaces(part))
      })
      |> @extract.unique_trimmed_strings
    }
  }
}

///|
fn provider_map_refs(value : String) -> Array[String] {
  let body = @extract.trim_spaces(value)
  if body == "" {
    []
  } else {
    let trimmed = body.strip_prefix("{").unwrap_or(body).to_string()
      |> @extract.trim_spaces
    let inner = trimmed.strip_suffix("}").unwrap_or(trimmed).to_string()
      |> @extract.trim_spaces
    let refs : Array[String] = []
    if inner == "" {
      return refs
    }
    for entry in @extract.split_top_level(inner, ',') {
      match segment_after(entry, "=") {
        Some(provider_ref) =>
          @extract.append_unique_string(
            refs,
            @extract.trim_quotes(@extract.trim_spaces(provider_ref)),
          )
        None => ()
      }
    }
    refs
  }
}

///|
fn depends_on_values(clean : String) -> Array[String] {
  segment_after(clean, "=").map(list_values).unwrap_or([])
}

///|
fn provider_attr(block : HclBlock, name : String) -> String {
  for i in 0..<block.attrs.length() {
    let attr = block.attrs[i]
    if attr.name == name {
      return @extract.trim_quotes(@extract.trim_spaces(attr.value))
    }
  }
  ""
}

///|
fn attr_value(block : HclBlock, name : String) -> String {
  for i in 0..<block.attrs.length() {
    let attr = block.attrs[i]
    if attr.name == name {
      return @extract.trim_spaces(attr.value)
    }
  }
  ""
}

///|
fn provider_ref_parts(value : String) -> (String, String) {
  let trimmed = @extract.trim_quotes(@extract.trim_spaces(value))
  match trimmed.find(".") {
    Some(idx) =>
      (
        trimmed[0:idx].to_string() |> @extract.trim_spaces,
        trimmed[idx + 1:].to_string() |> @extract.trim_spaces,
      )
    None => (trimmed, "")
  }
}

///|
fn default_provider_name(name : String) -> String {
  let head = match name.find(".") {
    Some(idx) => name[0:idx].to_string()
    None => name
  }
  match head.find("_") {
    Some(idx) => head[0:idx].to_string()
    None => head
  }
}

///|
fn provider_info(
  provider_name : String,
  provider_alias : String,
  required_providers : Map[String, TerraformProviderInfo],
) -> TerraformProviderInfo {
  match required_providers.get(provider_name) {
    Some(info) => {
      let resolved_alias = if provider_alias != "" {
        provider_alias
      } else {
        info.provider_alias
      }
      {
        name: info.name,
        source: info.source,
        version: info.version,
        provider_alias: resolved_alias,
      }
    }
    None => { name: provider_name, source: "", version: "", provider_alias }
  }
}

///|
fn scan_attributes(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  line : String,
  active_block : String,
  declaration_start : Int,
) -> Unit {
  let clean = @extract.trim_spaces(line)
  if clean == "" {
    return
  }
  let target_name = language_record_name(active_block)

  if clean.has_prefix("type ") || clean.has_prefix("type=") {
    let ty = segment_after(clean, "=")
      .map(part => @extract.strip_braces(part))
      .unwrap_or(@extract.strip_braces(clean[4:].to_string()))
    let name = if active_block == "" { "type" } else { "\{active_block}.type" }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "type_constraint",
      name,
      "type = \{ty}",
    )
  }

  if clean.has_prefix("validation") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "validation"
    } else {
      "\{active_block}.validation"
    }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "validation",
      name,
      clean,
    )
  }

  if clean.has_prefix("precondition") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "precondition"
    } else {
      "\{active_block}.precondition"
    }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "precondition",
      name,
      clean,
    )
  }

  if clean.has_prefix("postcondition") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "postcondition"
    } else {
      "\{active_block}.postcondition"
    }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "postcondition",
      name,
      clean,
    )
  }

  if clean.has_prefix("count ") || clean.has_prefix("count=") {
    let name = if active_block == "" {
      "count"
    } else {
      "\{active_block}.count"
    }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "meta_count",
      name,
      clean,
    )
  }

  if clean.has_prefix("for_each ") || clean.has_prefix("for_each=") {
    let name = if active_block == "" {
      "for_each"
    } else {
      "\{active_block}.for_each"
    }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "meta_for_each",
      name,
      clean,
    )
  }

  if clean.has_prefix("depends_on ") || clean.has_prefix("depends_on=") {
    let name = if active_block == "" {
      "depends_on"
    } else {
      "\{active_block}.depends_on"
    }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "meta_depends_on",
      name,
      clean,
    )
    set_metadata(
      declarations,
      profile,
      path,
      declaration_start,
      target_name,
      "dependsOn",
      Json::array(depends_on_values(clean).map(Json::string)),
    )
  }

  if clean.has_prefix("lifecycle") && clean.has_suffix("{") {
    let name = if active_block == "" {
      "lifecycle"
    } else {
      "\{active_block}.lifecycle"
    }
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "lifecycle",
      name,
      clean,
    )
  }

  if clean.has_prefix("required_providers") && clean.has_suffix("{") {
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      line_no,
      1,
      "required_providers",
      "required_providers",
      clean,
    )
  }

  if clean.has_prefix("sensitive ") || clean.has_prefix("sensitive=") {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "sensitive",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if clean.has_prefix("required ") || clean.has_prefix("required=") {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "required",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if active_block.has_prefix("resource.") &&
    (
      clean.has_prefix("prevent_destroy ") ||
      clean.has_prefix("prevent_destroy=")
    ) {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "preventDestroy",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if active_block.has_prefix("resource.") &&
    (
      clean.has_prefix("create_before_destroy ") ||
      clean.has_prefix("create_before_destroy=")
    ) {
    match segment_after(clean, "=") {
      Some(value) =>
        match parse_bool_literal(value) {
          Some(flag) =>
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              target_name,
              "createBeforeDestroy",
              Json::boolean(flag),
            )
          None => ()
        }
      None => ()
    }
  }

  if active_block.has_prefix("resource.") &&
    (clean.has_prefix("ignore_changes ") || clean.has_prefix("ignore_changes=")) {
    match segment_after(clean, "=") {
      Some(value) =>
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          target_name,
          "ignoreChanges",
          Json::array(list_values(value).map(Json::string)),
        )
      None => ()
    }
  }

  if (clean.has_prefix("source ") || clean.has_prefix("source=")) &&
    active_block.has_prefix("module.") {
    match segment_after(clean, "=") {
      Some(value) =>
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          target_name,
          "moduleSource",
          Json::string(@extract.trim_quotes(@extract.trim_spaces(value))),
        )
      None => ()
    }
  }

  if (clean.has_prefix("provider ") || clean.has_prefix("provider=")) &&
    (
      active_block.has_prefix("resource.") ||
      active_block.has_prefix("data.") ||
      active_block.has_prefix("provider.")
    ) {
    match segment_after(clean, "=") {
      Some(value) =>
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          target_name,
          "providerRef",
          Json::string(@extract.trim_quotes(@extract.trim_spaces(value))),
        )
      None => ()
    }
  }
}

///|
pub fn enrich_record(record : Json) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let name = @extract.field_string(record, "name")
  let signature = @extract.field_string(record, "signature")
  if kind == "module" {
    @extract.set_shape_string(record, "owner", name)
  }
  if kind == "type_constraint" {
    let ty = segment_after(signature, "=")
      .map(part => @extract.trim_spaces(part))
      .unwrap_or("")
    @extract.set_shape_string_array(
      record,
      "returns",
      if ty == "" {
        []
      } else {
        [ty]
      },
    )
  }
}

///|
fn collect_required_providers(
  lines : Array[String],
) -> Map[String, TerraformProviderInfo] {
  let providers : Map[String, TerraformProviderInfo] = {}
  let mut terraform_depth = 0
  let mut required_depth = 0
  let mut current_provider = ""
  let mut current_source = ""
  let mut current_version = ""

  for i in 0..<lines.length() {
    let line = @extract.trim_spaces(
      @extract.line_before_comment(lines[i].to_string()),
    )
    if line == "" {
      continue
    }

    let terraform_starts = line.has_prefix("terraform") && line.has_suffix("{")
    let required_starts = terraform_depth > 0 &&
      current_provider == "" &&
      line.has_prefix("required_providers") &&
      line.has_suffix("{")
    let provider_starts = required_depth > 0 &&
      current_provider == "" &&
      line.has_suffix("{") &&
      line.contains("=")

    if provider_starts {
      let provider_name = @extract.token_before(line, "=")
      if provider_name != "" {
        current_provider = provider_name
        current_source = ""
        current_version = ""
      }
    } else if current_provider != "" {
      if line.has_prefix("source") {
        current_source = segment_after(line, "=")
          .map(part => @extract.trim_quotes(@extract.trim_spaces(part)))
          .unwrap_or("")
      } else if line.has_prefix("version") {
        current_version = segment_after(line, "=")
          .map(part => @extract.trim_quotes(@extract.trim_spaces(part)))
          .unwrap_or("")
      }
    }

    if line == "}" {
      if current_provider != "" {
        providers[current_provider] = {
          name: current_provider,
          source: current_source,
          version: current_version,
          provider_alias: "",
        }
        current_provider = ""
        current_source = ""
        current_version = ""
      } else if required_depth > 0 {
        required_depth = required_depth - 1
      } else if terraform_depth > 0 {
        terraform_depth = terraform_depth - 1
      }
      continue
    }

    if terraform_starts {
      terraform_depth = terraform_depth + 1
      continue
    }
    if required_starts {
      required_depth = required_depth + 1
      continue
    }
  }

  providers
}

///|
fn enrich_declarations(
  declarations : Array[Json],
  profile : String,
  path : String,
  declaration_start : Int,
  hcl_file : HclFile,
  required_providers : Map[String, TerraformProviderInfo],
) -> Unit {
  let required_decl_id = @extract.declaration_id(
    profile, path, "required_providers",
  )
  let provider_decl_ids : Map[String, String] = {}

  match
    find_declaration_index(declarations, required_decl_id, declaration_start) {
    Some(idx) => {
      let providers : Array[TerraformProviderInfo] = []
      for name, info in required_providers {
        ignore(name)
        providers.push(info)
      }
      providers.sort_by((a, b) => a.name.compare(b.name))
      set_terraform_providers(declarations[idx], providers)
    }
    None => ()
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "provider" {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    provider_decl_ids[block.name] = decl_id
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        let provider_alias = provider_attr(block, "alias")
        let info = provider_info(block.name, provider_alias, required_providers)
        set_terraform_providers(declarations[idx], [info])
        if provider_alias != "" {
          match
            @extract.ensure_language_specific_profile(
              declarations[idx],
              "terraform",
            ) {
            Some(terraform) =>
              terraform["providerRef"] = Json::string(
                "\{block.name}.\{provider_alias}",
              )
            None => ()
          }
        }
        if required_providers.get(block.name) is Some(_) {
          @extract.append_relation(
            declarations[idx],
            "provided_by",
            required_decl_id,
          )
        }
      }
      None => ()
    }
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "variable" {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) =>
        @extract.set_language_specific_bool(
          declarations[idx],
          "terraform",
          "required",
          attr_value(block, "default") == "",
        )
      None => ()
    }
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "module" {
      continue
    }
    let provider_refs = provider_map_refs(attr_value(block, "providers"))
    if provider_refs.is_empty() {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        let providers : Array[TerraformProviderInfo] = []
        for j in 0..<provider_refs.length() {
          let provider_ref = provider_refs[j]
          let (provider_name, provider_alias) = provider_ref_parts(provider_ref)
          if provider_name == "" {
            continue
          }
          let info = provider_info(
            provider_name, provider_alias, required_providers,
          )
          providers.push(info)
          let provider_decl_id = provider_decl_ids
            .get(provider_name)
            .unwrap_or(@extract.declaration_id(profile, path, provider_name))
          @extract.append_relation(
            declarations[idx],
            "uses_provider",
            provider_decl_id,
          )
          if j == 0 {
            @extract.set_language_specific_string(
              declarations[idx],
              "terraform",
              "providerRef",
              provider_ref,
            )
          }
        }
        set_terraform_providers(declarations[idx], providers)
      }
      None => ()
    }
  }

  for i in 0..<hcl_file.blocks.length() {
    let block = hcl_file.blocks[i]
    if block.kind != "resource" && block.kind != "data" {
      continue
    }
    let decl_id = @extract.declaration_id(profile, path, block.name)
    let explicit_provider = provider_attr(block, "provider")
    let (provider_name, provider_alias) = if explicit_provider != "" {
      provider_ref_parts(explicit_provider)
    } else {
      (default_provider_name(block.name), "")
    }
    if provider_name == "" {
      continue
    }
    let info = provider_info(provider_name, provider_alias, required_providers)
    let provider_decl_id = provider_decl_ids
      .get(provider_name)
      .unwrap_or(@extract.declaration_id(profile, path, provider_name))
    match find_declaration_index(declarations, decl_id, declaration_start) {
      Some(idx) => {
        set_terraform_providers(declarations[idx], [info])
        let provider_ref = if provider_alias == "" {
          provider_name
        } else {
          "\{provider_name}.\{provider_alias}"
        }
        @extract.set_language_specific_string(
          declarations[idx],
          "terraform",
          "providerRef",
          provider_ref,
        )
        @extract.append_relation(
          declarations[idx],
          "uses_provider",
          provider_decl_id,
        )
      }
      None => ()
    }
  }
}

///|
pub fn extract_file(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
) -> Unit {
  let declaration_start = declarations.length()
  let hcl_file = parse_hcl_file(lines)
  for block in hcl_file.blocks {
    push_simple_record(
      declarations,
      symbols,
      profile,
      server,
      "terraform",
      path,
      block.line_no,
      block.col_no,
      block.kind,
      block.name,
      block.signature,
    )
  }

  let mut active_block = ""
  let block_stack : Array[String] = []

  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = @extract.trim_spaces(lines[i].to_string())

    if line.has_suffix("{") {
      let (kind, name) = kind_name(line)
      let next_active = if kind == "" {
        active_block
      } else {
        "\{kind}.\{name}"
      }
      block_stack.push(next_active)
      active_block = next_active
      if kind != "" {
        continue
      }
    }

    if line == "}" {
      if !block_stack.is_empty() {
        ignore(block_stack.pop())
      }
      active_block = if block_stack.is_empty() {
        ""
      } else {
        block_stack[block_stack.length() - 1]
      }
      continue
    }

    scan_attributes(
      declarations, symbols, profile, server, path, line_no, line, active_block,
      declaration_start,
    )
  }

  enrich_declarations(
    declarations,
    profile,
    path,
    declaration_start,
    hcl_file,
    collect_required_providers(lines),
  )
}
