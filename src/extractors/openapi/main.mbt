///|
fn leading_spaces(line : String) -> Int {
  let mut count = 0
  while count < line.length() && line.code_unit_at(count) == ' ' {
    count = count + 1
  }
  count
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
fn normalize_reference_target(value : String) -> String {
  match value.find("$ref:") {
    Some(idx) =>
      @extract.trim_quotes(@extract.trim_spaces(value[idx + 5:].to_string()))
    None => @extract.trim_quotes(@extract.trim_spaces(value))
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
    symbols.push(
      @extract.make_symbol(profile, path, line_no, kind, name, signature),
    )
    return
  }
  enrich_record(record)
  symbols.push(
    @extract.make_symbol(profile, path, line_no, kind, name, signature),
  )
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
  kind : String,
  name : String,
  signature : String,
) -> Unit {
  push_record(
    declarations, symbols, profile, server, language, path, line_no, kind, name,
    signature, "",
  )
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
          "openapi",
        )
        is Some(openapi) else {
        return
      }
      openapi[key] = value
    }
    None => ()
  }
}

///|
fn append_relation(
  declarations : Array[Json],
  profile : String,
  path : String,
  declaration_start : Int,
  target_name : String,
  kind : String,
  relation_target : String,
) -> Unit {
  if target_name == "" || kind == "" || relation_target == "" {
    return
  }
  let decl_id = @extract.declaration_id(profile, path, target_name)
  match find_declaration_index(declarations, decl_id, declaration_start) {
    Some(idx) =>
      @extract.append_relation(declarations[idx], kind, relation_target)
    None => ()
  }
}

///|
fn operation(line : String) -> String {
  match line {
    "get:" => "GET"
    "post:" => "POST"
    "put:" => "PUT"
    "delete:" => "DELETE"
    "patch:" => "PATCH"
    "head:" => "HEAD"
    "options:" => "OPTIONS"
    "trace:" => "TRACE"
    _ => ""
  }
}

///|
fn component_kind(section : String) -> String {
  match section {
    "schemas" => "schema"
    "parameters" => "parameter"
    "responses" => "response"
    "requestBodies" => "requestBody"
    "headers" => "header"
    "securitySchemes" => "security_scheme"
    "links" => "link"
    "callbacks" => "callback"
    "pathItems" => "path_item"
    "webhooks" => "webhook"
    _ => "component"
  }
}

///|
fn component_signature(section : String, name : String) -> String {
  if section == "" {
    "component \{name}"
  } else {
    "\{section} \{name}"
  }
}

///|
fn block_end(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Int {
  for i in (start_index + 1)..<lines.length() {
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    if line == "" {
      continue
    }
    if leading_spaces(raw_line) <= start_indent {
      return i
    }
  }
  lines.length()
}

///|
fn line_key(line : String) -> String {
  @extract.trim_quotes(
    @extract.trim_spaces(line.strip_suffix(":").unwrap_or(line).to_string()),
  )
}

///|
fn value_after_colon(line : String) -> String {
  match line.find(":") {
    Some(idx) =>
      @extract.trim_quotes(@extract.trim_spaces(line[idx + 1:].to_string()))
    None => ""
  }
}

///|
fn required_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Bool? {
  let end_index = block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = @extract.trim_spaces(lines[i].to_string())
    if line.has_prefix("required:") {
      return parse_bool_literal(value_after_colon(line))
    }
  }
  None
}

///|
fn parameter_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> String {
  let end_index = block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = @extract.trim_spaces(lines[i].to_string())
    if line.has_prefix("in:") {
      return value_after_colon(line)
    }
  }
  ""
}

///|
fn media_types_in_range(
  lines : Array[String],
  start_index : Int,
  end_index : Int,
) -> Array[String] {
  let media_types : Array[String] = []
  let mut content_indent = -1
  for i in start_index..<end_index {
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    if line == "" {
      continue
    }
    let indent = leading_spaces(raw_line)
    if line == "content:" {
      content_indent = indent
      continue
    }
    if content_indent >= 0 {
      if indent <= content_indent {
        content_indent = -1
      } else if indent == content_indent + 2 && line.has_suffix(":") {
        let media_type = line_key(line)
        if media_type.contains("/") {
          @extract.append_unique_string(media_types, media_type)
        }
      }
    }
  }
  media_types
}

///|
fn media_types_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Array[String] {
  media_types_in_range(
    lines,
    start_index + 1,
    block_end(lines, start_index, start_indent),
  )
}

///|
fn component_response_name(ref_target : String) -> String {
  let prefix = "#/components/responses/"
  if ref_target.has_prefix(prefix) {
    ref_target[prefix.length():].to_string()
  } else {
    ""
  }
}

///|
fn collect_component_response_media_types(
  lines : Array[String],
) -> Map[String, Array[String]] {
  let responses : Map[String, Array[String]] = {}
  let mut in_components = false
  let mut components_indent = -1
  let mut in_responses = false
  let mut responses_indent = -1
  for i in 0..<lines.length() {
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    let indent = leading_spaces(raw_line)
    if line == "components:" {
      in_components = true
      components_indent = indent
      in_responses = false
      continue
    }
    if in_components &&
      line != "" &&
      indent <= components_indent &&
      line != "components:" {
      in_components = false
      in_responses = false
    }
    if !in_components {
      continue
    }
    if indent == components_indent + 2 && line.has_suffix(":") {
      let section = line_key(line)
      in_responses = section == "responses"
      responses_indent = indent
      continue
    }
    if in_responses && indent == responses_indent + 2 && line.has_suffix(":") {
      let name = line_key(line)
      responses[name] = media_types_in_block(lines, i, indent)
    }
  }
  responses
}

///|
fn status_codes_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Array[String] {
  let status_codes : Array[String] = []
  let end_index = block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    if line == "" {
      continue
    }
    if leading_spaces(raw_line) == start_indent + 2 && line.has_suffix(":") {
      @extract.append_unique_string(status_codes, line_key(line))
    }
  }
  status_codes
}

///|
fn response_media_types_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
  component_response_media_types : Map[String, Array[String]],
) -> Array[String] {
  let media_types : Array[String] = []
  let end_index = block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    if line == "" {
      continue
    }
    let indent = leading_spaces(raw_line)
    if indent == start_indent + 2 && line.has_suffix(":") {
      let status_end = block_end(lines, i, indent)
      let status_media_types = media_types_in_range(lines, i + 1, status_end)
      for media_type in status_media_types {
        @extract.append_unique_string(media_types, media_type)
      }
      for j in (i + 1)..<status_end {
        let status_line = @extract.trim_spaces(lines[j].to_string())
        if !status_line.contains("$ref:") {
          continue
        }
        let response_name = component_response_name(
          normalize_reference_target(status_line),
        )
        if response_name == "" {
          continue
        }
        match component_response_media_types.get(response_name) {
          Some(response_media_types) =>
            for media_type in response_media_types {
              @extract.append_unique_string(media_types, media_type)
            }
          None => ()
        }
      }
    }
  }
  media_types
}

///|
fn callback_expression_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> String {
  let end_index = block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    if line == "" || !line.has_suffix(":") {
      continue
    }
    let key = line_key(line)
    if key.has_prefix("{") {
      return key
    }
  }
  ""
}

///|
fn member_refs_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Array[String] {
  let refs : Array[String] = []
  let end_index = block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = @extract.trim_spaces(lines[i].to_string())
    if line.contains("$ref:") {
      @extract.append_unique_string(refs, normalize_reference_target(line))
    }
  }
  refs
}

///|
fn discriminator_property_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> String {
  let end_index = block_end(lines, start_index, start_indent)
  for i in (start_index + 1)..<end_index {
    let line = @extract.trim_spaces(lines[i].to_string())
    if line.has_prefix("propertyName:") {
      return value_after_colon(line)
    }
  }
  ""
}

///|
fn discriminator_mapping_in_block(
  lines : Array[String],
  start_index : Int,
  start_indent : Int,
) -> Map[String, String] {
  let mapping : Map[String, String] = {}
  let end_index = block_end(lines, start_index, start_indent)
  let mut mapping_indent = -1
  for i in (start_index + 1)..<end_index {
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    if line == "" {
      continue
    }
    let indent = leading_spaces(raw_line)
    if line == "mapping:" {
      mapping_indent = indent
      continue
    }
    if mapping_indent >= 0 {
      if indent <= mapping_indent {
        mapping_indent = -1
      } else if indent == mapping_indent + 2 && line.contains(":") {
        mapping[@extract.token_before(line, ":")] = value_after_colon(line)
      }
    }
  }
  mapping
}

///|
fn string_map_json(mapping : Map[String, String]) -> Json {
  let object : Map[String, Json] = {}
  for key, value in mapping {
    if value != "" {
      object[key] = Json::string(value)
    }
  }
  Json::object(object)
}

///|
pub fn enrich_record(record : Json) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let name = @extract.field_string(record, "name")
  if kind == "operation" {
    match name.find(" ") {
      Some(idx) if idx > 0 =>
        @extract.set_language_specific_string(
          record,
          "openapi",
          "httpMethod",
          name[0:idx].to_string() |> @extract.trim_spaces,
        )
      _ => ()
    }
  }
  if kind == "reference" {
    @extract.set_language_specific_string(record, "openapi", "ref", name)
  }
  if kind == "security_scheme" {
    @extract.set_language_specific_string(
      record, "openapi", "securitySchemeName", name,
    )
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
  let component_response_media_types = collect_component_response_media_types(
    lines,
  )
  let mut in_paths = false
  let mut in_webhooks = false
  let mut current_path = ""
  let mut in_components = false
  let mut components_indent = -1
  let mut current_component_section = ""
  let mut current_component_name = ""
  let mut current_operation = ""
  let mut active_callback_expression = ""
  let mut active_callback_expression_indent = -1

  for i in 0..<lines.length() {
    let line_no = i + 1
    let raw_line = lines[i].to_string()
    let line = @extract.trim_spaces(raw_line)
    let indent = leading_spaces(raw_line)

    if active_callback_expression != "" &&
      indent <= active_callback_expression_indent &&
      !line_key(line).has_prefix("{") {
      active_callback_expression = ""
      active_callback_expression_indent = -1
    }

    if line == "paths:" {
      in_paths = true
      in_webhooks = false
      in_components = false
      continue
    }
    if line == "components:" {
      in_paths = false
      in_webhooks = false
      in_components = true
      components_indent = indent
      current_component_section = ""
      current_component_name = ""
      continue
    }
    if line == "webhooks:" {
      in_paths = false
      in_components = false
      in_webhooks = true
      current_path = ""
      current_operation = ""
      active_callback_expression = ""
      active_callback_expression_indent = -1
      continue
    }

    if line.has_suffix(":") {
      let key = line_key(line)
      if key.has_prefix("{") {
        active_callback_expression = key
        active_callback_expression_indent = indent
      }
    }

    if indent == 0 &&
      line.has_suffix(":") &&
      line != "paths:" &&
      line != "components:" &&
      line != "webhooks:" {
      in_paths = false
      in_webhooks = false
      in_components = false
      current_component_section = ""
      current_component_name = ""
      current_path = ""
      current_operation = ""
    }

    if in_components &&
      indent <= components_indent &&
      !(line == "components:" || line == "webhooks:") {
      in_components = false
      current_component_section = ""
      current_component_name = ""
    }

    if in_components && indent == components_indent + 2 && line.has_suffix(":") {
      current_component_section = line
        .strip_suffix(":")
        .unwrap_or(line)
        .to_string()
      current_component_name = ""
      continue
    }

    if in_paths && indent == 2 && line.has_prefix("/") && line.has_suffix(":") {
      match line.strip_suffix(":") {
        Some(value) => current_path = value.to_string()
        None => current_path = line
      }
      current_operation = ""
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "path",
        current_path,
        "path \{current_path}",
      )
      continue
    }
    if in_webhooks &&
      indent == 2 &&
      line.has_suffix(":") &&
      operation(line) == "" {
      match line.strip_suffix(":") {
        Some(value) => current_path = value.to_string()
        None => current_path = line
      }
      current_operation = ""
      continue
    }

    if (in_paths || in_webhooks) && indent == 4 {
      let http_method = operation(line)
      if http_method != "" {
        let name = "\{http_method} \{current_path}"
        current_operation = name
        push_simple_record(
          declarations, symbols, profile, server, "openapi", path, line_no, "operation",
          name, name,
        )
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "httpMethod",
          Json::string(http_method),
        )
      }
    }

    if in_components &&
      current_component_section != "" &&
      line.has_suffix(":") &&
      indent == components_indent + 4 {
      let name = line.strip_suffix(":").unwrap_or(line).to_string()
      if name != "properties" && name != "required" {
        current_component_name = name
        let kind = component_kind(current_component_section)
        push_simple_record(
          declarations,
          symbols,
          profile,
          server,
          "openapi",
          path,
          line_no,
          kind,
          name,
          component_signature(current_component_section, name),
        )
        if kind == "parameter" {
          let parameter_in = parameter_in_block(lines, i, indent)
          if parameter_in != "" {
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              name,
              "parameterIn",
              Json::string(parameter_in),
            )
          }
          match required_in_block(lines, i, indent) {
            Some(required) =>
              set_metadata(
                declarations,
                profile,
                path,
                declaration_start,
                name,
                "required",
                Json::boolean(required),
              )
            None => ()
          }
        }
        if kind == "requestBody" {
          match required_in_block(lines, i, indent) {
            Some(required) =>
              set_metadata(
                declarations,
                profile,
                path,
                declaration_start,
                name,
                "required",
                Json::boolean(required),
              )
            None => ()
          }
          let media_types = media_types_in_block(lines, i, indent)
          if !media_types.is_empty() {
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              name,
              "mediaTypes",
              Json::array(media_types.map(Json::string)),
            )
          }
        }
        if kind == "response" {
          let media_types = media_types_in_block(lines, i, indent)
          if !media_types.is_empty() {
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              name,
              "mediaTypes",
              Json::array(media_types.map(Json::string)),
            )
          }
        }
        if kind == "security_scheme" {
          let end_index = block_end(lines, i, indent)
          for j in (i + 1)..<end_index {
            let child_line = @extract.trim_spaces(lines[j].to_string())
            if child_line.has_prefix("type:") {
              let value = value_after_colon(child_line)
              if value != "" {
                set_metadata(
                  declarations,
                  profile,
                  path,
                  declaration_start,
                  name,
                  "securitySchemeType",
                  Json::string(value),
                )
              }
            } else if child_line.has_prefix("in:") {
              let value = value_after_colon(child_line)
              if value != "" {
                set_metadata(
                  declarations,
                  profile,
                  path,
                  declaration_start,
                  name,
                  "securitySchemeIn",
                  Json::string(value),
                )
              }
            } else if child_line.has_prefix("name:") {
              let value = value_after_colon(child_line)
              if value != "" {
                set_metadata(
                  declarations,
                  profile,
                  path,
                  declaration_start,
                  name,
                  "securitySchemeName",
                  Json::string(value),
                )
              }
            }
          }
        }
      }
    }

    if (in_paths || in_webhooks) && line.has_prefix("parameters:") {
      let scope = if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      if scope != "" {
        push_simple_record(
          declarations,
          symbols,
          profile,
          server,
          "openapi",
          path,
          line_no,
          "parameters",
          scope,
          "parameters \{scope}",
        )
        let end_index = block_end(lines, i, indent)
        for j in (i + 1)..<end_index {
          let child_raw = lines[j].to_string()
          let child_line = @extract.trim_spaces(child_raw)
          if leading_spaces(child_raw) != indent + 2 ||
            !child_line.has_prefix("- name:") {
            continue
          }
          let parameter_name = value_after_colon(child_line[1:].to_string())
          if parameter_name == "" {
            continue
          }
          push_simple_record(
            declarations,
            symbols,
            profile,
            server,
            "openapi",
            path,
            j + 1,
            "parameter",
            parameter_name,
            "parameters \{parameter_name}",
          )
          let parameter_in = parameter_in_block(lines, j, indent + 2)
          if parameter_in != "" {
            set_metadata(
              declarations,
              profile,
              path,
              declaration_start,
              parameter_name,
              "parameterIn",
              Json::string(parameter_in),
            )
          }
          let required = match required_in_block(lines, j, indent + 2) {
            Some(value) => Some(value)
            None => if parameter_in == "path" { Some(true) } else { None }
          }
          match required {
            Some(value) =>
              set_metadata(
                declarations,
                profile,
                path,
                declaration_start,
                parameter_name,
                "required",
                Json::boolean(value),
              )
            None => ()
          }
          append_relation(
            declarations,
            profile,
            path,
            declaration_start,
            scope,
            "has_parameter",
            @extract.declaration_id(profile, path, parameter_name),
          )
        }
      }
    }

    if (in_paths || in_webhooks) &&
      line.has_prefix("requestBody:") &&
      current_operation != "" {
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "requestBody",
        current_operation,
        "requestBody \{current_operation}",
      )
      match required_in_block(lines, i, indent) {
        Some(required) =>
          set_metadata(
            declarations,
            profile,
            path,
            declaration_start,
            current_operation,
            "required",
            Json::boolean(required),
          )
        None => ()
      }
      let media_types = media_types_in_block(lines, i, indent)
      if !media_types.is_empty() {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          current_operation,
          "mediaTypes",
          Json::array(media_types.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks) &&
      line == "responses:" &&
      current_operation != "" {
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "responses",
        current_operation,
        "responses \{current_operation}",
      )
      let status_codes = status_codes_in_block(lines, i, indent)
      if !status_codes.is_empty() {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          current_operation,
          "statusCodes",
          Json::array(status_codes.map(Json::string)),
        )
      }
      let media_types = response_media_types_in_block(
        lines, i, indent, component_response_media_types,
      )
      if !media_types.is_empty() {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          current_operation,
          "mediaTypes",
          Json::array(media_types.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks || in_components) && line.contains("allOf:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" { "allOf" } else { "\{scope}.allOf" }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "allOf",
        name, line,
      )
      let member_refs = member_refs_in_block(lines, i, indent)
      if !member_refs.is_empty() {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "memberRefs",
          Json::array(member_refs.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks || in_components) && line.contains("oneOf:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" { "oneOf" } else { "\{scope}.oneOf" }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "oneOf",
        name, line,
      )
      let member_refs = member_refs_in_block(lines, i, indent)
      if !member_refs.is_empty() {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "memberRefs",
          Json::array(member_refs.map(Json::string)),
        )
      }
    }

    if (in_paths || in_webhooks || in_components) && line.contains("anyOf:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" { "anyOf" } else { "\{scope}.anyOf" }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "anyOf",
        name, line,
      )
      let member_refs = member_refs_in_block(lines, i, indent)
      if !member_refs.is_empty() {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "memberRefs",
          Json::array(member_refs.map(Json::string)),
        )
      }
    }

    if line.has_prefix("discriminator:") {
      let scope = if in_components && current_component_name != "" {
        current_component_name
      } else if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" {
        "discriminator"
      } else {
        "\{scope}.discriminator"
      }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "discriminator",
        name, line,
      )
      set_metadata(
        declarations,
        profile,
        path,
        declaration_start,
        name,
        "discriminatorProperty",
        Json::string(discriminator_property_in_block(lines, i, indent)),
      )
      let mapping = discriminator_mapping_in_block(lines, i, indent)
      if !mapping.is_empty() {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "discriminatorMapping",
          string_map_json(mapping),
        )
      }
    }

    if line.has_prefix("security:") {
      let scope = if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      let name = if scope == "" { "security" } else { scope }
      push_simple_record(
        declarations, symbols, profile, server, "openapi", path, line_no, "security",
        name, line,
      )
      let callback_expression = callback_expression_in_block(lines, i, indent)
      if callback_expression != "" {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          if scope == "" {
            "callbacks"
          } else {
            scope
          },
          "callbackExpression",
          Json::string(callback_expression),
        )
      }
    }

    if line.has_prefix("callbacks:") {
      let scope = if current_operation == "" {
        current_path
      } else {
        current_operation
      }
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "callbacks",
        if scope == "" {
          "callbacks"
        } else {
          scope
        },
        line,
      )
    }

    if line.contains("$ref:") {
      let ref_target = normalize_reference_target(line)
      if ref_target != "" {
        push_simple_record(
          declarations, symbols, profile, server, "openapi", path, line_no, "reference",
          ref_target, line,
        )
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          ref_target,
          "ref",
          Json::string(ref_target),
        )
      }
    }

    if line.has_prefix("operationId:") {
      let name = @extract.trim_spaces(line[12:].to_string())
      push_simple_record(
        declarations,
        symbols,
        profile,
        server,
        "openapi",
        path,
        line_no,
        "operation",
        name,
        "operation \{name}",
      )
      set_metadata(
        declarations,
        profile,
        path,
        declaration_start,
        name,
        "operationId",
        Json::string(name),
      )
      if active_callback_expression != "" {
        set_metadata(
          declarations,
          profile,
          path,
          declaration_start,
          name,
          "callbackExpression",
          Json::string(active_callback_expression),
        )
      }
      current_operation = name
    }
  }
}
