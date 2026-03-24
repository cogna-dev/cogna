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
fn quoted_labels(line : String) -> Array[String] {
  let result : Array[String] = []
  let mut in_quote = false
  let mut start = -1
  for i in 0..<line.length() {
    let ch = line.code_unit_at(i)
    if ch == '"' {
      if in_quote {
        if start >= 0 {
          result.push(line[start:i].to_string())
        }
        in_quote = false
        start = -1
      } else {
        in_quote = true
        start = i + 1
      }
    }
  }
  result
}

///|
fn block_kind_name(line : String) -> (String, String) {
  if line.has_prefix("resource ") {
    let parts = quoted_labels(line)
    if parts.length() >= 2 {
      return ("resource", "\{parts[0]}.\{parts[1]}")
    }
  }
  if line.has_prefix("data ") {
    let parts = quoted_labels(line)
    if parts.length() >= 2 {
      return ("data", "\{parts[0]}.\{parts[1]}")
    }
  }
  if line.has_prefix("variable ") {
    let parts = quoted_labels(line)
    if parts.length() >= 1 {
      return ("variable", parts[0])
    }
  }
  if line.has_prefix("output ") {
    let parts = quoted_labels(line)
    if parts.length() >= 1 {
      return ("output", parts[0])
    }
  }
  if line.has_prefix("module ") {
    let parts = quoted_labels(line)
    if parts.length() >= 1 {
      return ("module", parts[0])
    }
  }
  if line.has_prefix("provider ") {
    let parts = quoted_labels(line)
    if parts.length() >= 1 {
      return ("provider", parts[0])
    }
  }
  if line.has_prefix("locals") && line.has_suffix("{") {
    return ("locals", "locals")
  }
  if line.has_prefix("dynamic ") {
    let parts = quoted_labels(line)
    if parts.length() >= 1 {
      return ("dynamic", parts[0])
    }
  }
  if line.has_prefix("check ") {
    let parts = quoted_labels(line)
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
fn find_eq(line : String) -> Int {
  let mut pos = -1
  for i in 0..<line.length() {
    if line.code_unit_at(i) == '=' {
      pos = i
      break
    }
  }
  pos
}

///|
fn attr_name_value(line : String) -> (String, String) {
  let eq_pos = find_eq(line)
  if eq_pos < 0 {
    return ("", "")
  }
  let key = trim_line(line[0:eq_pos].to_string())
  // Skip keys that contain spaces (they look like block declarations, not attrs)
  if key.contains(" ") || key == "" {
    return ("", "")
  }
  let val = trim_line(line[eq_pos + 1:line.length()].to_string())
  (key, val)
}

///|
/// Parse an HCL/Terraform file represented as an array of source lines.
/// Returns an `HclFile` containing all recognised top-level and nested blocks
/// together with their immediate attributes.
pub fn parse_hcl_file(lines : Array[String]) -> HclFile {
  let blocks : Array[HclBlock] = []
  // Stack tracks (kind, name, signature, line_no, attrs) for open blocks
  let kind_stack : Array[String] = []
  let name_stack : Array[String] = []
  let sig_stack : Array[String] = []
  let lineno_stack : Array[Int] = []
  let attrs_stack : Array[Array[HclAttr]] = []

  for i in 0..<lines.length() {
    let line_no = i + 1
    let line = trim_line(lines[i].to_string())

    if line.contains("{") && line.contains("}") {
      let (kind, name) = block_kind_name(line)
      if kind != "" {
        blocks.push({ kind, name, signature: line, line_no, attrs: [] })
        continue
      }
    }

    if line.has_suffix("{") {
      let (kind, name) = block_kind_name(line)
      kind_stack.push(kind)
      name_stack.push(name)
      sig_stack.push(line)
      lineno_stack.push(line_no)
      attrs_stack.push([])
    } else if line == "}" {
      if !kind_stack.is_empty() {
        let kind = kind_stack.pop().unwrap()
        let name = name_stack.pop().unwrap()
        let sig = sig_stack.pop().unwrap()
        let lno = lineno_stack.pop().unwrap()
        let attrs = attrs_stack.pop().unwrap()
        if kind != "" {
          blocks.push({ kind, name, signature: sig, line_no: lno, attrs })
        }
      }
      // Attribute scanning — only inside a named block
    } else if !attrs_stack.is_empty() && !kind_stack.is_empty() {
      let top_kind = kind_stack[kind_stack.length() - 1]
      if top_kind != "" {
        let (k, v) = attr_name_value(line)
        if k != "" {
          let top_attrs = attrs_stack[attrs_stack.length() - 1]
          top_attrs.push({ name: k, value: v, line_no })
        }
      }
    }
  }

  { blocks, }
}
