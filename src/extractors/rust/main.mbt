///|
fn type_name(signature : String, prefix : String) -> String {
  let body = signature.strip_prefix(prefix).unwrap_or(signature).to_string()
    |> @extract.trim_spaces
  let base = match body.find("<") {
    Some(idx) => body[0:idx].to_string()
    None => @extract.token_before(body, " ")
  }
  @extract.trim_spaces(base)
}

///|
fn where_clause(signature : String) -> String {
  match signature.find(" where ") {
    Some(idx) =>
      signature[idx + 7:].to_string()
      |> @extract.trim_spaces
      |> @extract.strip_braces
    None => ""
  }
}

///|
fn strip_leading_generics(value : String) -> String {
  let trimmed = @extract.trim_spaces(value)
  if !trimmed.has_prefix("<") {
    return trimmed
  }
  match @extract.matching_delimiter_index(trimmed, 0, '<', '>') {
    Some(close_idx) if close_idx + 1 < trimmed.length() =>
      @extract.trim_spaces(trimmed[close_idx + 1:].to_string())
    Some(_) => ""
    None => trimmed
  }
}

///|
pub fn decl_name(text : String) -> String {
  let trimmed = @extract.trim_spaces(text)
  if trimmed == "" {
    return ""
  }
  let mut end = 0
  while end < trimmed.length() {
    let c = trimmed.code_unit_at(end)
    if c == '<' {
      match @extract.matching_delimiter_index(trimmed, end, '<', '>') {
        Some(close_idx) => {
          end = close_idx + 1
          continue
        }
        None => break
      }
    }
    if c == ' ' ||
      c == '\t' ||
      c == '{' ||
      c == '(' ||
      c == '=' ||
      c == ':' ||
      c == ';' {
      break
    }
    end += 1
  }
  @extract.trim_spaces(trimmed[0:end].to_string())
}

///|
pub fn strip_decl_modifiers(value : String) -> String {
  let mut out = @extract.trim_spaces(value)
  let mut changed = true
  while changed {
    changed = false
    if out.has_prefix("unsafe ") {
      out = @extract.trim_spaces(out[7:].to_string())
      changed = true
      continue
    }
    if out.has_prefix("async ") {
      out = @extract.trim_spaces(out[6:].to_string())
      changed = true
      continue
    }
    if out.has_prefix("extern ") {
      let rest = @extract.trim_spaces(out[7:].to_string())
      if rest.has_prefix("\"") {
        match rest[1:].find("\"") {
          Some(close_idx) => {
            out = @extract.trim_spaces(rest[close_idx + 2:].to_string())
            changed = true
            continue
          }
          None => {
            out = rest
            changed = true
            continue
          }
        }
      }
      out = rest
      changed = true
      continue
    }
  }
  out
}

///|
fn signature_type_params(signature : String) -> Array[String] {
  match signature.find("<") {
    Some(open_idx) => {
      let equals_idx = signature.find("=").unwrap_or(signature.length())
      let paren_idx = signature.find("(").unwrap_or(signature.length())
      if open_idx > equals_idx || open_idx > paren_idx {
        return []
      }
      match @extract.matching_delimiter_index(signature, open_idx, '<', '>') {
        Some(close_idx) if close_idx > open_idx + 1 =>
          @extract.split_top_level(
            signature[open_idx + 1:close_idx].to_string(),
            ',',
          )
          |> @extract.unique_trimmed_strings
        _ => []
      }
    }
    None => []
  }
}

///|
fn multiline_clause(lines : Array[String], start_idx : Int) -> String {
  let parts : Array[String] = []
  let mut saw_where = false
  for i in (start_idx + 1)..<lines.length() {
    let clean = @extract.trim_spaces(
      @extract.line_before_comment(lines[i].to_string()),
    )
    if clean == "" {
      continue
    }
    if clean.has_prefix("where") {
      saw_where = true
      let clause = clean.strip_prefix("where").unwrap_or(clean).to_string()
        |> @extract.trim_spaces
        |> @extract.strip_braces
      if clause != "" {
        parts.push(clause)
      }
      if clean.has_suffix("{") || clean.has_suffix(";") {
        break
      }
      continue
    }
    if !saw_where {
      break
    }
    let clause = @extract.strip_braces(clean)
    if clause != "" {
      parts.push(clause)
    }
    if clean.has_suffix("{") || clean.has_suffix(";") {
      break
    }
  }
  if parts.is_empty() {
    ""
  } else {
    parts.join(", ")
  }
}

///|
pub fn impl_targets(signature : String) -> (String, String) {
  let trimmed = signature.strip_prefix("impl").unwrap_or(signature).to_string()
    |> @extract.trim_spaces
  let normalized = @extract.strip_braces(trimmed)
  match normalized.find(" for ") {
    Some(idx) => {
      let trait_target = normalized[0:idx].to_string() |> @extract.trim_spaces
      let impl_target = normalized[idx + 5:].to_string() |> @extract.trim_spaces
      (trait_target, impl_target)
    }
    None => ("", normalized)
  }
}

///|
fn is_unsafe(signature : String) -> Bool {
  let clean = @extract.trim_spaces(@extract.line_before_comment(signature))
  clean.has_prefix("unsafe ") || clean.contains(" unsafe ")
}

///|
fn extern_abi(signature : String) -> String {
  let clean = @extract.trim_spaces(@extract.line_before_comment(signature))
  if !clean.contains("extern") {
    return ""
  }
  let quoted = @extract.quoted_parts(clean)
  if !quoted.is_empty() {
    return quoted[0]
  }
  if clean.contains("extern fn") || clean.contains("extern unsafe fn") {
    return "C"
  }
  ""
}

///|
pub fn normalize_owner_key(value : String) -> String {
  let trimmed = @extract.line_before_comment(value)
    |> @extract.trim_spaces
    |> @extract.strip_braces
  if trimmed == "" {
    return ""
  }
  let without_where = match trimmed.find(" where ") {
    Some(idx) => trimmed[0:idx].to_string() |> @extract.trim_spaces
    None => trimmed
  }
  strip_leading_generics(without_where) |> @extract.trim_spaces
}

///|
fn record_type_params(record : Json) -> Array[String] {
  let kind = @extract.field_string(record, "kind")
  let name = @extract.field_string(record, "name")
  let signature = @extract.field_string(record, "signature")
  if kind == "impl" ||
    kind == "struct" ||
    kind == "trait" ||
    kind == "enum" ||
    kind == "union" ||
    kind == "type_alias" ||
    kind == "function" {
    return signature_type_params(signature)
  }
  if kind == "associated_type" ||
    kind == "associated_const" ||
    kind == "associated_fn" {
    match name.find("<") {
      Some(_) => {
        let owner = match name.find("::") {
          Some(idx) if idx > 0 => name[0:idx].to_string()
          _ => name
        }
        return match owner.find("<") {
          Some(open_idx) =>
            match @extract.matching_delimiter_index(owner, open_idx, '<', '>') {
              Some(close_idx) if close_idx > open_idx + 1 =>
                @extract.split_top_level(
                  owner[open_idx + 1:close_idx].to_string(),
                  ',',
                ).map(part => @extract.first_token(part))
                |> @extract.unique_trimmed_strings
              _ => []
            }
          None => []
        }
      }
      None => return []
    }
  }
  match name.find("<") {
    Some(open_idx) =>
      match @extract.matching_delimiter_index(name, open_idx, '<', '>') {
        Some(close_idx) if close_idx > open_idx + 1 =>
          @extract.split_top_level(
            name[open_idx + 1:close_idx].to_string(),
            ',',
          ).map(part => @extract.first_token(part))
          |> @extract.unique_trimmed_strings
        _ => []
      }
    None => []
  }
}

///|
pub fn enrich_record(record : Json) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let name = @extract.field_string(record, "name")
  let signature = @extract.field_string(record, "signature")
  let type_params = record_type_params(record)
  @extract.set_shape_string_array(record, "type_params", type_params)
  @extract.set_language_specific_string_array(
    record, "rust", "typeParams", type_params,
  )
  @extract.set_language_specific_string(
    record,
    "rust",
    "whereClause",
    where_clause(signature),
  )
  if is_unsafe(signature) {
    @extract.set_language_specific_bool(record, "rust", "unsafe", true)
  }
  @extract.set_language_specific_string(
    record,
    "rust",
    "externAbi",
    extern_abi(signature),
  )
  if kind == "struct" {
    let owner = type_name(signature, "pub struct ")
    @extract.set_shape_string(record, "owner", owner)
    @extract.set_language_specific_string(record, "rust", "owner", owner)
  } else if kind == "trait" {
    let owner = type_name(signature, "pub trait ")
    @extract.set_shape_string(record, "owner", owner)
    @extract.set_language_specific_string(record, "rust", "owner", owner)
  } else if kind == "impl" {
    let (trait_target, impl_target) = impl_targets(signature)
    @extract.set_language_specific_string(
      record, "rust", "traitTarget", trait_target,
    )
    @extract.set_language_specific_string(
      record, "rust", "implTarget", impl_target,
    )
    @extract.set_shape_string(record, "owner", impl_target)
  } else if kind == "associated_type" ||
    kind == "associated_const" ||
    kind == "associated_fn" {
    let owner = match name.find("::") {
      Some(idx) if idx > 0 => name[0:idx].to_string()
      _ => ""
    }
    @extract.set_shape_string(record, "owner", owner)
    @extract.set_language_specific_string(record, "rust", "owner", owner)
    @extract.set_language_specific_bool(record, "rust", "associated", true)
    if owner != "" {
      @extract.set_language_specific_string(
        record, "rust", "traitTarget", owner,
      )
    }
  }
}

///|
pub fn set_multiline_clause(
  record : Json,
  lines : Array[String],
  line_no : Int,
) -> Unit {
  if where_clause(@extract.field_string(record, "signature")) != "" {
    return
  }
  @extract.set_language_specific_string(
    record,
    "rust",
    "whereClause",
    multiline_clause(lines, line_no - 1),
  )
}

///|
fn append_type_relation(
  relations : Array[Json],
  profile : String,
  value : String,
) -> Unit {
  let normalized = normalize_owner_key(value)
  if normalized == "" {
    return
  }
  @extract.push_unique_relation(
    relations,
    "references_type",
    "type:\{profile}::\{normalized}",
  )
}

///|
fn rewrite_relations(record : Json, profile : String) -> Unit {
  let kind = @extract.field_string(record, "kind")
  let signature = @extract.field_string(record, "signature")
  if kind == "function" || kind == "associated_fn" {
    let relations = @extract.filter_record_relations(record, [
      "has_parameter", "returns", "references_type",
    ])
    let param_types = @extract.signature_param_types(signature)
    for i in 0..<param_types.length() {
      let ty = @extract.trim_spaces(param_types[i])
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
    let return_types = @extract.signature_return_types(signature)
    for i in 0..<return_types.length() {
      let ty = @extract.trim_spaces(return_types[i])
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
    append_type_relation(
      relations,
      profile,
      @extract.language_specific_profile_string(record, "rust", "owner"),
    )
    append_type_relation(
      relations,
      profile,
      @extract.language_specific_profile_string(record, "rust", "traitTarget"),
    )
    append_type_relation(
      relations,
      profile,
      @extract.language_specific_profile_string(record, "rust", "implTarget"),
    )
    @extract.set_record_relations(record, relations)
    return
  }
  if kind == "impl" {
    let relations = @extract.filter_record_relations(record, [
      "implements", "references_type",
    ])
    let trait_target = normalize_owner_key(
      @extract.language_specific_profile_string(record, "rust", "traitTarget"),
    )
    let impl_target = normalize_owner_key(
      @extract.language_specific_profile_string(record, "rust", "implTarget"),
    )
    if trait_target != "" {
      @extract.push_unique_relation(
        relations,
        "implements",
        "type:\{profile}::\{trait_target}",
      )
      @extract.push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{trait_target}",
      )
    }
    if impl_target != "" {
      @extract.push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{impl_target}",
      )
    }
    @extract.set_record_relations(record, relations)
    return
  }
  if kind == "associated_type" ||
    kind == "associated_const" ||
    kind == "const" ||
    kind == "type_alias" {
    let relations = @extract.filter_record_relations(record, ["references_type"])
    append_type_relation(
      relations,
      profile,
      @extract.language_specific_profile_string(record, "rust", "owner"),
    )
    append_type_relation(
      relations,
      profile,
      @extract.language_specific_profile_string(record, "rust", "traitTarget"),
    )
    append_type_relation(
      relations,
      profile,
      @extract.language_specific_profile_string(record, "rust", "implTarget"),
    )
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
    if @extract.field_string(declarations[i], "language") != "rust" {
      continue
    }
    let kind = @extract.field_string(declarations[i], "kind")
    if kind == "struct" ||
      kind == "enum" ||
      kind == "union" ||
      kind == "trait" ||
      kind == "type_alias" {
      let name = normalize_owner_key(
        @extract.field_string(declarations[i], "name"),
      )
      let id = @extract.field_string(declarations[i], "id")
      if name != "" && id != "" {
        type_ids[name] = id
      }
    }
  }

  for i in 0..<declarations.length() {
    if @extract.field_string(declarations[i], "language") != "rust" {
      continue
    }
    rewrite_relations(declarations[i], profile)
  }

  for i in 0..<declarations.length() {
    if @extract.field_string(declarations[i], "language") != "rust" {
      continue
    }
    let kind = @extract.field_string(declarations[i], "kind")
    let id = @extract.field_string(declarations[i], "id")
    let owner = normalize_owner_key(
      @extract.language_specific_profile_string(
        declarations[i],
        "rust",
        "owner",
      ),
    )
    if (
        kind == "associated_type" ||
        kind == "associated_const" ||
        kind == "associated_fn" ||
        kind == "function" ||
        kind == "const" ||
        kind == "type_alias"
      ) &&
      owner != "" {
      match type_ids.get(owner) {
        Some(owner_id) =>
          @extract.append_relation_to_record_by_id(
            declarations, owner_id, "has_member", id,
          )
        None => ()
      }
    }
    if kind == "impl" {
      let trait_target = normalize_owner_key(
        @extract.language_specific_profile_string(
          declarations[i],
          "rust",
          "traitTarget",
        ),
      )
      let impl_target = normalize_owner_key(
        @extract.language_specific_profile_string(
          declarations[i],
          "rust",
          "implTarget",
        ),
      )
      if trait_target != "" && impl_target != "" {
        match type_ids.get(impl_target) {
          Some(type_id) =>
            @extract.append_relation_to_record_by_id(
              declarations,
              type_id,
              "implements",
              "type:\{profile}::\{trait_target}",
            )
          None => ()
        }
      }
    }
  }
}

///|
fn push_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
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
      profile, server, "rust", path, line_no, kind, name, signature, docs,
    ),
  )
  guard @extract.last_record(declarations) is Some(record) else {
    symbols.push(
      @extract.make_symbol(profile, path, line_no, kind, name, signature),
    )
    return
  }
  @extract.enrich_shape_metadata(record)
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
  path : String,
  line_no : Int,
  kind : String,
  name : String,
  signature : String,
) -> Unit {
  push_record(
    declarations, symbols, profile, server, path, line_no, kind, name, signature,
    "",
  )
}

///|
fn extract_record(
  declarations : Array[Json],
  symbols : Array[Json],
  profile : String,
  server : String,
  path : String,
  lines : Array[String],
  line_no : Int,
  line : String,
  docs : String,
  active_impl_target : String,
  active_impl_trait : String,
) -> Unit {
  let clean = @extract.line_before_comment(line) |> @extract.trim_spaces
  if clean == "" {
    return
  }

  let mut normalized = clean
  let mut vis = "public"
  if normalized.has_prefix("pub(crate) ") {
    vis = "pub(crate)"
    normalized = normalized[11:].to_string()
  } else if normalized.has_prefix("pub(super) ") {
    vis = "pub(super)"
    normalized = normalized[11:].to_string()
  } else if normalized.has_prefix("pub(in ") {
    vis = "pub(in)"
    match normalized.find(") ") {
      Some(idx) => normalized = normalized[idx + 2:].to_string()
      None => ()
    }
  } else if normalized.has_prefix("pub ") {
    normalized = normalized[4:].to_string()
  } else {
    return
  }

  let kind_source = strip_decl_modifiers(normalized)
  let (kind, name) = if kind_source.has_prefix("fn ") {
    ("function", @extract.token_before(kind_source[3:].to_string(), "("))
  } else if kind_source.has_prefix("struct ") {
    ("struct", decl_name(kind_source[7:].to_string()))
  } else if kind_source.has_prefix("enum ") {
    ("enum", decl_name(kind_source[5:].to_string()))
  } else if kind_source.has_prefix("union ") {
    ("union", decl_name(kind_source[6:].to_string()))
  } else if kind_source.has_prefix("trait ") {
    ("trait", decl_name(kind_source[6:].to_string()))
  } else if kind_source.has_prefix("type ") {
    ("type_alias", decl_name(kind_source[5:].to_string()))
  } else if kind_source.has_prefix("const ") {
    ("const", @extract.token_before(kind_source[6:].to_string(), ":"))
  } else if kind_source.has_prefix("static ") {
    ("static", @extract.token_before(kind_source[7:].to_string(), ":"))
  } else if kind_source.has_prefix("mod ") {
    ("module", @extract.token_before(kind_source[4:].to_string(), "{"))
  } else if kind_source.has_prefix("use ") {
    ("use", @extract.strip_braces(kind_source[4:].to_string()))
  } else if kind_source.has_prefix("macro ") {
    ("macro", @extract.token_before(kind_source[6:].to_string(), "{"))
  } else {
    ("", "")
  }

  if name == "" || kind == "" {
    return
  }

  let signature = if vis == "public" { clean } else { "\{clean} // \{vis}" }
  push_record(
    declarations, symbols, profile, server, path, line_no, kind, name, signature,
    docs,
  )
  guard @extract.last_record(declarations) is Some(record) else { return }
  set_multiline_clause(record, lines, line_no)
  if active_impl_target != "" &&
    (kind == "function" || kind == "const" || kind == "type_alias") {
    @extract.set_shape_string(record, "owner", active_impl_target)
    @extract.set_language_specific_string(
      record, "rust", "owner", active_impl_target,
    )
    @extract.set_language_specific_string(
      record, "rust", "implTarget", active_impl_target,
    )
    if active_impl_trait != "" {
      @extract.set_language_specific_string(
        record, "rust", "traitTarget", active_impl_trait,
      )
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
  let mut pending_doc = ""
  let mut pending_doc_line = 0
  let mut pending_deprecated = ""
  let mut pending_macro_export = false
  let mut active_trait = ""
  let mut active_trait_depth = 0
  let mut pending_trait = ""
  let mut active_impl_target = ""
  let mut active_impl_trait = ""
  let mut active_impl_depth = 0
  let mut pending_impl_target = ""
  let mut pending_impl_trait = ""

  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = @extract.trim_spaces(lines[i].to_string())

    if line.has_prefix("///") {
      let piece = line.strip_prefix("///").unwrap_or(line).to_string()
        |> @extract.trim_spaces
      pending_doc = if pending_doc == "" {
        piece
      } else {
        "\{pending_doc}\n\{piece}"
      }
      pending_doc_line = line_no
      continue
    }
    if line.has_prefix("#[deprecated") {
      pending_deprecated = "Deprecated"
      continue
    }
    if line.has_prefix("#[macro_export") {
      pending_macro_export = true
      continue
    }
    if line == "" {
      pending_doc = ""
      pending_doc_line = 0
      pending_deprecated = ""
      continue
    }

    let clean = @extract.line_before_comment(line) |> @extract.trim_spaces
    if pending_macro_export && clean.has_prefix("macro_rules!") {
      let macro_name = @extract.token_before(clean[12:].to_string(), "{")
      let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
        pending_doc
      } else {
        ""
      }
      let docs_with_attrs = if pending_deprecated == "" {
        docs
      } else if docs == "" {
        pending_deprecated
      } else {
        "\{docs}\n\{pending_deprecated}"
      }
      push_record(
        declarations, symbols, profile, server, path, line_no, "macro", macro_name,
        clean, docs_with_attrs,
      )
      pending_doc = ""
      pending_doc_line = 0
      pending_deprecated = ""
      pending_macro_export = false
      continue
    }

    if active_trait != "" &&
      !clean.has_prefix("#") &&
      clean != "{" &&
      clean != "}" {
      let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
        pending_doc
      } else {
        ""
      }
      let docs_with_attrs = if pending_deprecated == "" {
        docs
      } else if docs == "" {
        pending_deprecated
      } else {
        "\{docs}\n\{pending_deprecated}"
      }
      if clean.has_prefix("type ") {
        let name = @extract.token_before(clean[5:].to_string(), ":")
        push_record(
          declarations,
          symbols,
          profile,
          server,
          path,
          line_no,
          "associated_type",
          "\{active_trait}::\{name}",
          clean,
          docs_with_attrs,
        )
      } else if clean.has_prefix("const ") {
        let name = @extract.token_before(clean[6:].to_string(), ":")
        push_record(
          declarations,
          symbols,
          profile,
          server,
          path,
          line_no,
          "associated_const",
          "\{active_trait}::\{name}",
          clean,
          docs_with_attrs,
        )
      } else if clean.has_prefix("fn ") {
        let name = @extract.token_before(clean[3:].to_string(), "(")
        push_record(
          declarations,
          symbols,
          profile,
          server,
          path,
          line_no,
          "associated_fn",
          "\{active_trait}::\{name}",
          clean,
          docs_with_attrs,
        )
      }
      pending_doc = ""
      pending_doc_line = 0
      pending_deprecated = ""
    }

    let impl_source = strip_decl_modifiers(clean)
    if impl_source.has_prefix("impl ") || impl_source.has_prefix("impl<") {
      let name = clean.strip_prefix("impl").unwrap_or(clean).to_string()
        |> @extract.trim_spaces
        |> @extract.strip_braces
      push_simple_record(
        declarations, symbols, profile, server, path, line_no, "impl", name, clean,
      )
      let (impl_trait, impl_target) = impl_targets(impl_source)
      pending_impl_trait = normalize_owner_key(impl_trait)
      pending_impl_target = normalize_owner_key(impl_target)
      if clean.has_suffix("{") {
        active_impl_target = pending_impl_target
        active_impl_trait = pending_impl_trait
        pending_impl_target = ""
        pending_impl_trait = ""
        active_impl_depth = 0
      }
    }

    let mut vis_normalized = clean
    let mut trait_visible = false
    if vis_normalized.has_prefix("pub(crate) ") {
      vis_normalized = vis_normalized[11:].to_string()
      trait_visible = true
    } else if vis_normalized.has_prefix("pub(super) ") {
      vis_normalized = vis_normalized[11:].to_string()
      trait_visible = true
    } else if vis_normalized.has_prefix("pub(in ") {
      trait_visible = true
      match vis_normalized.find(") ") {
        Some(idx) => vis_normalized = vis_normalized[idx + 2:].to_string()
        None => ()
      }
    } else if vis_normalized.has_prefix("pub ") {
      trait_visible = true
      vis_normalized = vis_normalized[4:].to_string()
    }
    let trait_source = strip_decl_modifiers(vis_normalized)
    if trait_visible && trait_source.has_prefix("trait ") {
      pending_trait = decl_name(trait_source[6:].to_string())
      if clean.has_suffix("{") {
        active_trait = pending_trait
        pending_trait = ""
        active_trait_depth = 0
      }
    }
    if pending_impl_target != "" && clean.has_suffix("{") {
      active_impl_target = pending_impl_target
      active_impl_trait = pending_impl_trait
      pending_impl_target = ""
      pending_impl_trait = ""
      active_impl_depth = 0
    }
    if pending_trait != "" && clean.has_suffix("{") {
      active_trait = pending_trait
      pending_trait = ""
      active_trait_depth = 0
    }

    let docs = if pending_doc != "" && pending_doc_line + 1 >= line_no {
      pending_doc
    } else {
      ""
    }
    let docs_with_attrs = if pending_deprecated == "" {
      docs
    } else if docs == "" {
      pending_deprecated
    } else {
      "\{docs}\n\{pending_deprecated}"
    }
    extract_record(
      declarations, symbols, profile, server, path, lines, line_no, line, docs_with_attrs,
      active_impl_target, active_impl_trait,
    )

    for c in clean {
      if c == '{' {
        if active_trait != "" {
          active_trait_depth += 1
        }
        if active_impl_target != "" {
          active_impl_depth += 1
        }
      } else if c == '}' {
        if active_trait != "" {
          active_trait_depth -= 1
          if active_trait_depth <= 0 {
            active_trait = ""
            active_trait_depth = 0
          }
        }
        if active_impl_target != "" {
          active_impl_depth -= 1
          if active_impl_depth <= 0 {
            active_impl_target = ""
            active_impl_trait = ""
            active_impl_depth = 0
          }
        }
      }
    }

    pending_doc = ""
    pending_doc_line = 0
    pending_deprecated = ""
    pending_macro_export = false
  }
}
