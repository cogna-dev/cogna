///|
pub fn type_name(signature : String) -> String {
  let body = signature.strip_prefix("type ").unwrap_or(signature).to_string()
    |> @extract.trim_spaces
  let plain = match body.find("=") {
    Some(idx) => body[0:idx].to_string() |> @extract.trim_spaces
    None => body
  }
  let base = match plain.find("[") {
    Some(idx) => plain[0:idx].to_string()
    None => @extract.first_token(plain)
  }
  @extract.trim_spaces(base)
}

///|
fn method_param_types(signature : String) -> Array[String] {
  let rest = signature.strip_prefix("func ").unwrap_or(signature).to_string()
  if !rest.has_prefix("(") {
    return @extract.signature_param_types(signature)
  }
  match @extract.matching_delimiter_index(rest, 0, '(', ')') {
    Some(close_idx) if close_idx + 1 < rest.length() =>
      @extract.signature_param_types(
        rest[close_idx + 1:].to_string() |> @extract.trim_spaces,
      )
    _ => @extract.signature_param_types(signature)
  }
}

///|
fn return_types_after_params(value : String) -> Array[String] {
  let tail = @extract.strip_braces(@extract.trim_spaces(value))
  if tail == "" {
    return []
  }
  if tail.has_prefix("(") {
    return match @extract.matching_delimiter_index(tail, 0, '(', ')') {
      Some(close_idx) if close_idx > 1 =>
        @extract.split_top_level(tail[1:close_idx].to_string(), ',')
        |> @extract.unique_trimmed_strings
      _ => []
    }
  }
  @extract.unique_trimmed_strings([tail])
}

///|
fn function_return_types(signature : String) -> Array[String] {
  match signature.find("(") {
    Some(open_idx) =>
      match @extract.matching_delimiter_index(signature, open_idx, '(', ')') {
        Some(close_idx) if close_idx + 1 < signature.length() =>
          return_types_after_params(signature[close_idx + 1:].to_string())
        _ => []
      }
    None => []
  }
}

///|
fn method_return_types(signature : String) -> Array[String] {
  let rest = signature.strip_prefix("func ").unwrap_or(signature).to_string()
  if !rest.has_prefix("(") {
    return function_return_types(signature)
  }
  match @extract.matching_delimiter_index(rest, 0, '(', ')') {
    Some(close_idx) if close_idx + 1 < rest.length() =>
      function_return_types(
        rest[close_idx + 1:].to_string() |> @extract.trim_spaces,
      )
    _ => function_return_types(signature)
  }
}

///|
fn receiver_parts(signature : String) -> (String, Bool) {
  let rest = signature.strip_prefix("func ").unwrap_or(signature).to_string()
  if !rest.has_prefix("(") {
    return ("", false)
  }
  match @extract.matching_delimiter_index(rest, 0, '(', ')') {
    Some(close_idx) if close_idx > 1 => {
      let receiver = @extract.trim_spaces(rest[1:close_idx].to_string())
      let pointer = receiver.contains("*")
      let base = match receiver.find("*") {
        Some(idx) => receiver[idx + 1:].to_string()
        None => receiver
      }
      let name = match base.find(" ") {
        Some(idx) => base[idx + 1:].to_string()
        None => base
      }
      let trimmed = match name.find("[") {
        Some(idx) => name[0:idx].to_string()
        None => name
      }
      (@extract.trim_spaces(trimmed), pointer)
    }
    _ => ("", false)
  }
}

///|
pub fn normalize_type_reference(value : String) -> String {
  let trimmed = @extract.strip_braces(@extract.trim_spaces(value))
  if trimmed == "" {
    return ""
  }
  if trimmed.has_prefix("*") {
    return normalize_type_reference(trimmed[1:].to_string())
  }
  trimmed
}

///|
pub fn enrich_record(record : Json) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let name = @extract.field_string(record, "name")
  let signature = @extract.field_string(record, "signature")
  let type_params = @extract.signature_type_params(signature)
  @extract.set_language_specific_string_array(
    record, "go", "typeParams", type_params,
  )
  if kind == "struct" || kind == "interface" {
    let owner = type_name(signature)
    @extract.set_shape_string(record, "owner", owner)
    @extract.set_language_specific_string(record, "go", "owner", owner)
  }
  if kind == "field" || kind == "embedded_field" {
    match name.find(".") {
      Some(idx) if idx > 0 => {
        let owner = name[0:idx].to_string()
        @extract.set_shape_string(record, "owner", owner)
        @extract.set_language_specific_string(record, "go", "owner", owner)
      }
      _ => ()
    }
    let field_type = if kind == "embedded_field" {
      signature
    } else {
      match signature.find(" ") {
        Some(idx) => signature[idx + 1:].to_string() |> @extract.trim_spaces
        None => ""
      }
    }
    @extract.set_language_specific_string(record, "go", "fieldType", field_type)
    if kind == "embedded_field" {
      @extract.set_language_specific_bool(record, "go", "embedded", true)
    }
  }
  if kind == "import" {
    let quoted = @extract.quoted_parts(signature)
    if !quoted.is_empty() {
      @extract.set_language_specific_string(
        record,
        "go",
        "importPath",
        quoted[0],
      )
    }
    match name.find(" ") {
      Some(idx) if idx > 0 =>
        @extract.set_language_specific_string(
          record,
          "go",
          "importAlias",
          name[0:idx].to_string() |> @extract.trim_spaces,
        )
      _ => ()
    }
  }
  if kind == "method" {
    let (receiver, pointer) = receiver_parts(signature)
    @extract.set_language_specific_string(record, "go", "receiver", receiver)
    @extract.set_language_specific_bool(
      record, "go", "pointerReceiver", pointer,
    )
    @extract.set_shape_string(record, "owner", receiver)
    @extract.set_language_specific_string(record, "go", "owner", receiver)
    @extract.put_shape_string_array(
      record,
      "parameters",
      method_param_types(signature),
    )
    @extract.put_shape_string_array(
      record,
      "returns",
      method_return_types(signature),
    )
  }
}

///|
fn collect_embedding_index(
  declarations : Array[Json],
) -> Map[String, Array[(String, Bool)]] {
  let embeddings : Map[String, Array[(String, Bool)]] = {}
  for i in 0..<declarations.length() {
    if @extract.field_string(declarations[i], "language") != "go" ||
      @extract.field_string(declarations[i], "kind") != "embedded_field" {
      continue
    }
    let owner = @extract.shape_string(declarations[i], "owner")
    let field_type = @extract.language_specific_profile_string(
      declarations[i],
      "go",
      "fieldType",
    )
    let target = normalize_type_reference(field_type)
    let is_pointer = field_type.has_prefix("*")
    if owner == "" || target == "" {
      continue
    }
    match embeddings.get(owner) {
      Some(entries) => entries.push((target, is_pointer))
      None => embeddings[owner] = [(target, is_pointer)]
    }
  }
  embeddings
}

///|
fn method_set_types(
  owner : String,
  pointer_receiver : Bool,
  embeddings : Map[String, Array[(String, Bool)]],
) -> Array[String] {
  let method_sets : Array[String] = []
  if owner == "" {
    return method_sets
  }
  if pointer_receiver {
    @extract.append_unique_string(method_sets, "*\{owner}")
  } else {
    @extract.append_unique_string(method_sets, owner)
    @extract.append_unique_string(method_sets, "*\{owner}")
  }
  let mut changed = true
  while changed {
    changed = false
    for embedder, embedded_types in embeddings {
      let before = method_sets.length()
      for i in 0..<embedded_types.length() {
        let (embedded_type, embedded_pointer) = embedded_types[i]
        let has_value = @extract.contains_string(method_sets, embedded_type)
        let has_pointer = @extract.contains_string(
          method_sets,
          "*\{embedded_type}",
        )
        if embedded_pointer {
          if has_value || has_pointer {
            @extract.append_unique_string(method_sets, embedder)
            @extract.append_unique_string(method_sets, "*\{embedder}")
          }
        } else {
          if has_value {
            @extract.append_unique_string(method_sets, embedder)
          }
          if has_value || has_pointer {
            @extract.append_unique_string(method_sets, "*\{embedder}")
          }
        }
      }
      if method_sets.length() != before {
        changed = true
      }
    }
  }
  method_sets
}

///|
fn rewrite_relations(record : Json, profile : String) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let signature = @extract.field_string(record, "signature")
  if kind == "function" || kind == "method" {
    let relations = @extract.filter_record_relations(record, [
      "has_parameter", "returns", "references_type",
    ])
    let param_types = if kind == "method" {
      method_param_types(signature)
    } else {
      @extract.signature_param_types(signature)
    }
    for i in 0..<param_types.length() {
      let ty = normalize_type_reference(param_types[i])
      if ty == "" {
        continue
      }
      @extract.push_unique_relation(
        relations,
        "has_parameter",
        "type:\{profile}::\{ty}",
      )
      @extract.push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{ty}",
      )
    }
    let return_types = if kind == "method" {
      method_return_types(signature)
    } else {
      function_return_types(signature)
    }
    for i in 0..<return_types.length() {
      let ty = normalize_type_reference(return_types[i])
      if ty == "" {
        continue
      }
      @extract.push_unique_relation(
        relations,
        "returns",
        "type:\{profile}::\{ty}",
      )
      @extract.push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{ty}",
      )
    }
    @extract.set_record_relations(record, relations)
    return
  }
  if kind == "field" || kind == "embedded_field" {
    let relations = @extract.filter_record_relations(record, ["references_type"])
    let field_type = @extract.language_specific_profile_string(
      record, "go", "fieldType",
    )
    let ty = normalize_type_reference(field_type)
    if ty != "" {
      @extract.push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{ty}",
      )
    }
    @extract.set_record_relations(record, relations)
  }
}

///|
pub fn postprocess_declarations(
  declarations : Array[Json],
  profile : String,
) -> Unit {
  let type_ids : Map[String, String] = {}
  for i in 0..<declarations.length() {
    if @extract.field_string(declarations[i], "language") != "go" {
      continue
    }
    let kind = @extract.field_string(declarations[i], "kind")
    if kind == "struct" || kind == "interface" || kind == "type" {
      let name = @extract.field_string(declarations[i], "name")
      let id = @extract.field_string(declarations[i], "id")
      if name != "" && id != "" {
        type_ids[name] = id
      }
    }
  }

  let embeddings = collect_embedding_index(declarations)
  for i in 0..<declarations.length() {
    if @extract.field_string(declarations[i], "language") != "go" {
      continue
    }
    rewrite_relations(declarations[i], profile)
  }

  for i in 0..<declarations.length() {
    if @extract.field_string(declarations[i], "language") != "go" {
      continue
    }
    let kind = @extract.field_string(declarations[i], "kind")
    let id = @extract.field_string(declarations[i], "id")
    if kind == "field" || kind == "embedded_field" || kind == "method" {
      let owner = @extract.shape_string(declarations[i], "owner")
      match type_ids.get(owner) {
        Some(owner_id) =>
          @extract.append_relation_to_record_by_id(
            declarations, owner_id, "has_member", id,
          )
        None => ()
      }
    }
    if kind == "method" {
      let owner = @extract.shape_string(declarations[i], "owner")
      let pointer_receiver = @extract.language_specific_profile_bool(
        declarations[i],
        "go",
        "pointerReceiver",
      ).unwrap_or(false)
      let owner_sets = method_set_types(owner, pointer_receiver, embeddings)
      @extract.set_language_specific_string_array(
        declarations[i],
        "go",
        "methodSetTypes",
        owner_sets,
      )
      for j in 0..<owner_sets.length() {
        let owner_type = normalize_type_reference(owner_sets[j])
        match type_ids.get(owner_type) {
          Some(owner_id) =>
            @extract.append_relation_to_record_by_id(
              declarations, owner_id, "has_member", id,
            )
          None => ()
        }
      }
    }
  }
}

///|
fn names(segment : String) -> Array[String] {
  let lhs = match segment.find("=") {
    Some(idx) => segment[0:idx].to_string()
    None => segment
  }
  let normalized = @extract.strip_braces(lhs)
  let values : Array[String] = []
  let pieces = normalized.split(",").to_array()
  for i in 0..<pieces.length() {
    let name = @extract.first_token(pieces[i].to_string())
    if name != "" && name != "_" {
      values.push(name)
    }
  }
  values
}

///|
fn push_records(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  kind : String,
  names : Array[String],
  signature : String,
  docs : String,
) -> Unit {
  for i in 0..<names.length() {
    declarations.push(
      @extract.make_declaration(
        profile,
        server,
        "go",
        path,
        line_no,
        kind,
        names[i],
        signature,
        docs,
      ),
    )
    guard @extract.last_record(declarations) is Some(record) else {
      symbols.push(
        @extract.make_symbol(profile, path, line_no, kind, names[i], signature),
      )
      continue
    }
    @extract.enrich_shape_metadata(record)
    enrich_record(record)
    symbols.push(
      @extract.make_symbol(profile, path, line_no, kind, names[i], signature),
    )
  }
}

///|
fn import_name(clean_line : String) -> String {
  let parts = @extract.quoted_parts(clean_line)
  if parts.length() == 0 {
    return ""
  }
  let import_path = parts[0]
  let tail = @extract.trim_spaces(clean_line[7:].to_string())
  let import_alias = @extract.first_token(tail)
  if import_alias == "" || import_alias.has_prefix("\"") {
    import_path
  } else {
    "\{import_alias} \{import_path}"
  }
}

///|
fn strip_tag(line : String) -> String {
  match line.find("`") {
    Some(idx) => line[0:idx].to_string() |> @extract.trim_spaces
    None => line
  }
}

///|
fn struct_name(line : String, grouped~ : Bool) -> String {
  let source = if grouped {
    line
  } else {
    line.strip_prefix("type ").unwrap_or(line).to_string()
  }
  @extract.first_token(source)
}

///|
fn extract_struct_field(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  owner : String,
  line : String,
  docs : String,
) -> Unit {
  let clean = @extract.line_before_comment(line)
    |> @extract.trim_spaces
    |> strip_tag
  if clean == "" || clean == "{" || clean == "}" {
    return
  }

  let is_embedded = !clean.contains(" ") && !clean.contains("\t")
  let raw_name = if is_embedded { clean } else { @extract.first_token(clean) }
  let name = raw_name.strip_prefix("*").unwrap_or(raw_name).to_string()
  if name == "" {
    return
  }

  let kind = if is_embedded { "embedded_field" } else { "field" }
  let full_name = "\{owner}.\{name}"
  declarations.push(
    @extract.make_declaration(
      profile, server, "go", path, line_no, kind, full_name, clean, docs,
    ),
  )
  guard @extract.last_record(declarations) is Some(record) else {
    symbols.push(
      @extract.make_symbol(profile, path, line_no, kind, full_name, clean),
    )
    return
  }
  @extract.enrich_shape_metadata(record)
  enrich_record(record)
  symbols.push(
    @extract.make_symbol(profile, path, line_no, kind, full_name, clean),
  )
}

///|
fn extract_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  line_no : Int,
  line : String,
  docs : String,
) -> Unit {
  let clean_line = @extract.line_before_comment(line) |> @extract.trim_spaces
  if clean_line == "" {
    return
  }

  if clean_line.has_prefix("type ") {
    let rest = clean_line[5:].to_string()
    let name = @extract.first_token(rest)
    let kind = if rest.contains("=") {
      "type_alias"
    } else if rest.contains("struct") {
      "struct"
    } else if rest.contains("interface") {
      "interface"
    } else {
      "type"
    }
    declarations.push(
      @extract.make_declaration(
        profile, server, "go", path, line_no, kind, name, clean_line, docs,
      ),
    )
    guard @extract.last_record(declarations) is Some(record) else {
      symbols.push(
        @extract.make_symbol(profile, path, line_no, kind, name, clean_line),
      )
      return
    }
    @extract.enrich_shape_metadata(record)
    enrich_record(record)
    symbols.push(
      @extract.make_symbol(profile, path, line_no, kind, name, clean_line),
    )
    return
  }

  if clean_line.has_prefix("package ") {
    let name = @extract.first_token(clean_line[8:].to_string())
    declarations.push(
      @extract.make_declaration(
        profile, server, "go", path, line_no, "package", name, clean_line, docs,
      ),
    )
    symbols.push(
      @extract.make_symbol(profile, path, line_no, "package", name, clean_line),
    )
    return
  }

  if clean_line.has_prefix("import ") {
    let name = import_name(clean_line)
    declarations.push(
      @extract.make_declaration(
        profile, server, "go", path, line_no, "import", name, clean_line, docs,
      ),
    )
    guard @extract.last_record(declarations) is Some(record) else {
      symbols.push(
        @extract.make_symbol(profile, path, line_no, "import", name, clean_line),
      )
      return
    }
    @extract.enrich_shape_metadata(record)
    enrich_record(record)
    symbols.push(
      @extract.make_symbol(profile, path, line_no, "import", name, clean_line),
    )
    return
  }

  if clean_line.has_prefix("func ") {
    let mut rest = clean_line[5:].to_string()
    let kind = if rest.has_prefix("(") {
      match rest.find(") ") {
        Some(idx) => {
          rest = rest[idx + 2:].to_string()
          "method"
        }
        None => "method"
      }
    } else {
      "function"
    }
    let name = @extract.token_before(rest, "(")
    declarations.push(
      @extract.make_declaration(
        profile, server, "go", path, line_no, kind, name, clean_line, docs,
      ),
    )
    guard @extract.last_record(declarations) is Some(record) else {
      symbols.push(
        @extract.make_symbol(profile, path, line_no, kind, name, clean_line),
      )
      return
    }
    @extract.enrich_shape_metadata(record)
    enrich_record(record)
    symbols.push(
      @extract.make_symbol(profile, path, line_no, kind, name, clean_line),
    )
    return
  }

  if clean_line.has_prefix("const ") {
    push_records(
      declarations,
      symbols,
      profile,
      server,
      path,
      line_no,
      "const",
      names(clean_line[6:].to_string()),
      clean_line,
      docs,
    )
    return
  }

  if clean_line.has_prefix("var ") {
    push_records(
      declarations,
      symbols,
      profile,
      server,
      path,
      line_no,
      "var",
      names(clean_line[4:].to_string()),
      clean_line,
      docs,
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
  let mut pending_doc = ""
  let mut pending_doc_line = 0
  let mut group_kind = ""
  let mut group_scope_depth = 0
  let mut active_struct = ""
  let mut active_struct_depth = 0

  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = @extract.trim_spaces(lines[i].to_string())

    if line.has_prefix("//") {
      let piece = line.strip_prefix("//").unwrap_or(line).to_string()
        |> @extract.trim_spaces
      pending_doc = if pending_doc == "" {
        piece
      } else {
        "\{pending_doc}\n\{piece}"
      }
      pending_doc_line = line_no
      continue
    }
    if line == "" {
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    if line == ")" {
      group_kind = ""
      group_scope_depth = 0
      active_struct = ""
      active_struct_depth = 0
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    if line.has_prefix("const (") || line == "const(" {
      group_kind = "const"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }
    if line.has_prefix("var (") || line == "var(" {
      group_kind = "var"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }
    if line.has_prefix("type (") || line == "type(" {
      group_kind = "type"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }
    if line.has_prefix("import (") || line == "import(" {
      group_kind = "import"
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    if group_kind != "" {
      let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
        pending_doc
      } else {
        ""
      }
      if active_struct != "" && active_struct_depth > 0 {
        extract_struct_field(
          declarations, symbols, profile, server, path, line_no, active_struct, line,
          docs,
        )
      }
      let group_line = @extract.strip_braces(line)
      if group_scope_depth == 0 && group_line != "" {
        let synthetic = "\{group_kind} \{group_line}"
        extract_record(
          declarations, symbols, profile, server, path, line_no, synthetic, docs,
        )
        if group_kind == "type" &&
          line.contains("struct") &&
          line.has_suffix("{") {
          active_struct = struct_name(group_line, grouped=true)
          active_struct_depth = 0
        }
      }
      for c in line {
        if c == '{' {
          group_scope_depth += 1
          if active_struct != "" {
            active_struct_depth += 1
          }
        } else if c == '}' && group_scope_depth > 0 {
          group_scope_depth -= 1
          if active_struct != "" {
            active_struct_depth -= 1
            if active_struct_depth <= 0 {
              active_struct = ""
              active_struct_depth = 0
            }
          }
        }
      }
      pending_doc = ""
      pending_doc_line = 0
      continue
    }

    let declaration_prefixes = [
      "package ", "import ", "type ", "func ", "const ", "var ",
    ]
    let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
      pending_doc
    } else {
      ""
    }
    if active_struct != "" && active_struct_depth > 0 {
      extract_struct_field(
        declarations, symbols, profile, server, path, line_no, active_struct, line,
        docs,
      )
    }
    if @extract.starts_with_any(line, declaration_prefixes) {
      extract_record(
        declarations, symbols, profile, server, path, line_no, line, docs,
      )
      if line.has_prefix("type ") &&
        line.contains("struct") &&
        line.has_suffix("{") {
        active_struct = struct_name(line, grouped=false)
        active_struct_depth = 0
      }
      pending_doc = ""
      pending_doc_line = 0
    }
    for c in line {
      if c == '{' {
        if active_struct != "" {
          active_struct_depth += 1
        }
      } else if c == '}' {
        if active_struct != "" {
          active_struct_depth -= 1
          if active_struct_depth <= 0 {
            active_struct = ""
            active_struct_depth = 0
          }
        }
      }
    }
  }
}
