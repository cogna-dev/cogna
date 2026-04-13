///|
fn normalize_reference_target(value : String) -> String {
  match value.find("$ref:") {
    Some(idx) =>
      @parsec.trim_quotes(
        @parsec.trim_spaces(value[idx + 5:].to_string()),
      )
    None => @parsec.trim_quotes(@parsec.trim_spaces(value))
  }
}

///|
pub fn field_string(record : Json, key : String) -> String {
  guard record is Object(object) else { return "" }
  match object.get(key) {
    Some(String(value)) => value
    _ => ""
  }
}

///|
pub fn canonical_name(profile : String, path : String, name : String) -> String {
  let scoped = path.replace(old="/", new="::")
  "\{profile}::\{scoped}::\{name}"
}

///|
pub fn declaration_id(profile : String, path : String, name : String) -> String {
  let canonical = canonical_name(profile, path, name)
  "decl:\{profile}:\{canonical}"
}

///|
pub fn declaration_shape(kind : String, signature : String) -> Json {
  let form = if signature.contains("(") && signature.contains(")") {
    "callable"
  } else {
    "symbol"
  }
  { "kind": kind, "subkind": kind, "form": form, "signature": signature }
}

///|
pub fn signature_type_params(signature : String) -> Array[String] {
  match signature.find("[") {
    Some(open_idx) => {
      let equals_idx = signature.find("=").unwrap_or(signature.length())
      let paren_idx = signature.find("(").unwrap_or(signature.length())
      if open_idx > equals_idx || open_idx > paren_idx {
        return []
      }
      match @parsec.matching_delimiter_index(signature, open_idx, '[', ']') {
        Some(close_idx) if close_idx > open_idx + 1 =>
          @parsec.split_top_level(
            signature[open_idx + 1:close_idx].to_string(),
            ',',
          )
          .map(part => @parsec.first_token(part))
          |> @parsec.unique_trimmed_strings
        _ => []
      }
    }
    None =>
      match signature.find("<") {
        Some(open_idx) => {
          let equals_idx = signature.find("=").unwrap_or(signature.length())
          let paren_idx = signature.find("(").unwrap_or(signature.length())
          if open_idx > equals_idx || open_idx > paren_idx {
            return []
          }
          match @parsec.matching_delimiter_index(signature, open_idx, '<', '>') {
            Some(close_idx) if close_idx > open_idx + 1 =>
              @parsec.split_top_level(
                signature[open_idx + 1:close_idx].to_string(),
                ',',
              )
              .map(part => @parsec.first_token(part))
              |> @parsec.unique_trimmed_strings
            _ => []
          }
        }
        None => []
      }
  }
}

///|
pub fn signature_param_types(signature : String) -> Array[String] {
  match signature.find("(") {
    Some(open_idx) =>
      match @parsec.matching_delimiter_index(signature, open_idx, '(', ')') {
        Some(close_idx) if close_idx > open_idx + 1 => {
          let body = signature[open_idx + 1:close_idx].to_string()
          if @parsec.trim_spaces(body) == "" {
            []
          } else {
            @parsec.split_top_level(body, ',').map(part => {
              let candidate = @parsec.trim_spaces(part)
              if candidate == "" {
                ""
              } else {
                match candidate.find(":") {
                  Some(idx) =>
                    @parsec.trim_spaces(candidate[idx + 1:].to_string())
                  None =>
                    match candidate.find(" ") {
                      Some(idx) =>
                        @parsec.trim_spaces(candidate[idx + 1:].to_string())
                      None => candidate
                    }
                }
              }
            })
            |> @parsec.unique_trimmed_strings
          }
        }
        _ => []
      }
    None => []
  }
}

///|
pub fn parse_return_type(signature : String) -> String {
  match signature.find(")") {
    Some(close_idx) => {
      let tail = signature[close_idx + 1:].to_string() |> @parsec.trim_spaces
      if tail.has_prefix("{") || tail == "" {
        return ""
      }
      if tail.has_prefix("->") {
        return tail[2:].to_string() |> @parsec.trim_spaces |> @parsec.strip_braces
      }
      if tail.has_prefix("(") ||
        tail.has_prefix("[") ||
        tail.has_prefix("*") ||
        tail.has_prefix("&") ||
        tail.has_prefix("string") ||
        tail.has_prefix("int") ||
        tail.has_prefix("bool") ||
        tail.has_prefix("float") ||
        tail.has_prefix("byte") ||
        tail.has_prefix("char") {
        return @parsec.strip_braces(tail)
      }
      ""
    }
    _ => ""
  }
}

///|
pub fn signature_return_types(signature : String) -> Array[String] {
  let ret = parse_return_type(signature)
  if ret == "" {
    []
  } else {
    @parsec.unique_trimmed_strings([ret])
  }
}

///|
pub fn enrich_shape_metadata(record : Json) -> Unit {
  let kind = field_string(record, "kind")
  let name = field_string(record, "name")
  let signature = field_string(record, "signature")
  if signature == "" {
    return
  }
  if kind == "method" ||
    kind == "field" ||
    kind == "embedded_field" ||
    kind == "associated_type" ||
    kind == "associated_const" ||
    kind == "associated_fn" {
    match name.find(".") {
      Some(idx) if idx > 0 =>
        set_shape_string(
          record,
          "owner",
          name[0:idx].to_string() |> @parsec.trim_spaces,
        )
      _ =>
        match name.find("::") {
          Some(idx) if idx > 0 =>
            set_shape_string(
              record,
              "owner",
              name[0:idx].to_string() |> @parsec.trim_spaces,
            )
          _ => ()
        }
    }
  }
  if kind == "function" ||
    kind == "method" ||
    kind == "associated_fn" ||
    kind == "struct" ||
    kind == "interface" ||
    kind == "trait" ||
    kind == "impl" {
    set_shape_string_array(record, "type_params", signature_type_params(signature))
  }
  if kind == "function" || kind == "method" || kind == "associated_fn" {
    set_shape_string_array(record, "parameters", signature_param_types(signature))
    set_shape_string_array(record, "returns", signature_return_types(signature))
  }
}

///|
pub fn parse_first_param(signature : String) -> String {
  match signature.find("(") {
    Some(open_idx) =>
      match signature.find(")") {
        Some(close_idx) if close_idx > open_idx + 1 => {
          let body = signature[open_idx + 1:close_idx].to_string()
            |> @parsec.trim_spaces
          if body == "" {
            ""
          } else {
            let first = body.split(",").to_array()[0].to_string() |> @parsec.trim_spaces
            match first.find(" ") {
              Some(space_idx) if space_idx > 0 =>
                first[space_idx + 1:].to_string() |> @parsec.trim_spaces
              _ => first
            }
          }
        }
        _ => ""
      }
    _ => ""
  }
}

///|
pub fn push_unique_relation(
  relations : Array[Json],
  kind : String,
  target : String,
) -> Unit {
  if kind == "" || target == "" {
    return
  }
  let candidate = "\{kind}::\{target}"
  for i in 0..<relations.length() {
    guard relations[i] is Object(object) else { continue }
    let existing_kind = match object.get("kind") {
      Some(String(value)) => value
      _ => ""
    }
    let existing_target = match object.get("target") {
      Some(String(value)) => value
      _ => ""
    }
    if "\{existing_kind}::\{existing_target}" == candidate {
      return
    }
  }
  relations.push({ "kind": kind, "target": target })
}

///|
pub fn declaration_relations_v2(
  profile : String,
  path : String,
  kind : String,
  name : String,
  signature : String,
) -> Array[Json] {
  let relations : Array[Json] = []
  push_unique_relation(relations, "declared_in", "file:\{path}")

  if kind == "struct" ||
    kind == "enum" ||
    kind == "interface" ||
    kind == "trait" ||
    kind == "module" ||
    kind == "resource" ||
    kind == "schema" {
    push_unique_relation(relations, "contains", "decl:\{profile}::\{name}")
    push_unique_relation(relations, "has_member", "decl:\{profile}::\{name}")
  }

  if kind == "function" ||
    kind == "method" ||
    kind == "associated_fn" ||
    kind == "operation" {
    let first_param = parse_first_param(signature)
    if first_param != "" {
      push_unique_relation(
        relations,
        "has_parameter",
        "type:\{profile}::\{first_param}",
      )
      push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{first_param}",
      )
    }
    let ret = parse_return_type(signature)
    if ret != "" {
      push_unique_relation(relations, "returns", "type:\{profile}::\{ret}")
      push_unique_relation(
        relations,
        "references_type",
        "type:\{profile}::\{ret}",
      )
    }
  }

  if kind == "impl" {
    if signature.contains(" for ") {
      let parts = signature.split(" for ").to_array()
      if parts.length() >= 2 {
        let trait_name = parts[0]
          .to_string()
          .strip_prefix("impl")
          .unwrap_or(parts[0].to_string())
          .to_string()
          |> @parsec.trim_spaces
        let target_type = parts[1].to_string() |> @parsec.strip_braces |> @parsec.trim_spaces
        if trait_name != "" && target_type != "" {
          push_unique_relation(
            relations,
            "implements",
            "type:\{profile}::\{trait_name}",
          )
          push_unique_relation(
            relations,
            "references_type",
            "type:\{profile}::\{target_type}",
          )
        }
      }
    } else {
      let target = signature
        .strip_prefix("impl")
        .unwrap_or(signature)
        .to_string()
        |> @parsec.strip_braces
        |> @parsec.trim_spaces
      if target != "" {
        push_unique_relation(
          relations,
          "references_type",
          "type:\{profile}::\{target}",
        )
      }
    }
  }

  if kind == "reference" {
    let reference_target = normalize_reference_target(signature)
    if reference_target != "" {
      push_unique_relation(relations, "references_type", reference_target)
    }
  }

  if kind == "meta_for_each" || kind == "meta_depends_on" {
    let parts = signature.split("=").to_array()
    let target = if parts.length() >= 2 {
      parts[1].to_string() |> @parsec.trim_spaces
    } else {
      ""
    }
    if target != "" {
      push_unique_relation(relations, "references_type", target)
    }
  }

  relations
}

///|
pub fn make_declaration(
  profile : String,
  server : String,
  language : String,
  path : String,
  line_no : Int,
  kind : String,
  name : String,
  signature : String,
  docs : String,
) -> Json {
  let canonical = canonical_name(profile, path, name)
  {
    "id": "decl:\{profile}:\{canonical}",
    "kind": kind,
    "name": name,
    "canonical_name": canonical,
    "path": path,
    "signature": signature,
    "shape": declaration_shape(kind, signature),
    "visibility": "public",
    "docs": docs,
    "baselineRole": "baseline",
    "language": language,
    "source_refs": [{ "uri": path, "startLine": line_no, "endLine": line_no }],
    "relations": declaration_relations_v2(profile, path, kind, name, signature),
    "location": { "uri": path, "startLine": line_no, "endLine": line_no },
    "language_specific": { "profile": profile, "server": server },
  }
}

///|
pub fn make_symbol(
  profile : String,
  path : String,
  line_no : Int,
  kind : String,
  name : String,
  signature : String,
) -> Json {
  let canonical = canonical_name(profile, path, name)
  {
    "id": "sym:\{profile}:\{canonical}",
    "path": "\{path}:\{line_no}",
    "kind": kind,
    "name": name,
    "summary": signature,
    "owner": path,
    "location": { "uri": path, "startLine": line_no, "endLine": line_no },
  }
}
