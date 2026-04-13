///|
priv enum HclLine {
  BlockOpen(kind~ : String, name~ : String, signature~ : String, line_no~ : Int)
  UnknownOpen
  OneLine(kind~ : String, name~ : String, signature~ : String, line_no~ : Int)
  Close
  Attr(name~ : String, value~ : String, line_no~ : Int)
  Ignored
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
fn parse_identifier_text(
  stream : @parsec.TokenStream,
) -> @parsec.ParseResult[String] {
  @parsec.map_result(stream, fn(s) {
    @parsec.pred(s, "identifier", fn(token) {
      match token.kind {
        Identifier(_) | Keyword(_) => true
        _ => false
      }
    })
  }, @parsec.token_text)
}

///|
fn parse_string_text(stream : @parsec.TokenStream) -> @parsec.ParseResult[String] {
  @parsec.map_result(stream, fn(s) {
    @parsec.pred(s, "string", fn(token) {
      match token.kind {
        StringLiteral(_) => true
        _ => false
      }
    })
  }, fn(token) {
    let text = @parsec.token_text(token)
    if text.length() >= 2 && text.code_unit_at(0) == '"' &&
      text.code_unit_at(text.length() - 1) == '"' {
      text[1:text.length() - 1].to_string()
    } else {
      text
    }
  })
}

///|
fn parse_string_literals_before_open(tokens : Array[@parsec.Token]) -> Array[String] {
  let labels : Array[String] = []
  let mut stream = @parsec.new_stream(tokens)
  while !stream.is_done() {
    match @parsec.tag(stream, "{") {
      Matched(..) => break
      _ => ()
    }
    match parse_string_text(stream) {
      Matched(value~, next~) => {
        labels.push(value)
        stream = next
      }
      _ => stream = stream.advance()
    }
  }
  labels
}

///|
fn parse_block_kind_name(tokens : Array[@parsec.Token]) -> (String, String) {
  if tokens.is_empty() {
    return ("", "")
  }
  let stream = @parsec.new_stream(tokens)
  match parse_identifier_text(stream) {
    Matched(value=kind, next=after_kind) => {
      match @parsec.cut(@parsec.tag(after_kind, "{")) {
        Matched(..) => {
          match kind {
            "locals" | "terraform" => return (kind, kind)
            _ => ()
          }
        }
        _ => ()
      }
      let labels = parse_string_literals_before_open(tokens)
      match kind {
        "resource" | "data" if labels.length() >= 2 =>
          (kind, "\{labels[0]}.\{labels[1]}")
        "variable" | "output" | "module" | "provider" | "dynamic" |
        "check" if labels.length() >= 1 =>
          (kind, labels[0])
        "locals" if tokens.length() >= 1 => ("locals", "locals")
        "terraform" if tokens.length() >= 1 => ("terraform", "terraform")
        _ => ("", "")
      }
    }
    _ => ("", "")
  }
}

///|
fn classify_line(line : String, line_no : Int) -> HclLine {
  let trimmed = trim_line(line)
  if trimmed == "" {
    return Ignored
  }
  let tokens = @parsec.tokenize_line(trimmed, line_no)
  if trimmed.contains("{") && trimmed.contains("}") {
    let (kind, name) = parse_block_kind_name(tokens)
    if kind != "" {
      return OneLine(kind~, name~, signature=trimmed, line_no~)
    }
    return Ignored
  }
  if trimmed.has_suffix("{") {
    let (kind, name) = parse_block_kind_name(tokens)
    if kind != "" {
      return BlockOpen(kind~, name~, signature=trimmed, line_no~)
    }
    return UnknownOpen
  }
  if trimmed == "}" {
    return Close
  }
  let eq_pos = find_eq(trimmed)
  if eq_pos >= 0 {
    let key = trim_line(trimmed[0:eq_pos].to_string())
    if key != "" && !key.contains(" ") {
      let value = trim_line(trimmed[eq_pos + 1:trimmed.length()].to_string())
      return Attr(name=key, value~, line_no~)
    }
  }
  Ignored
}

///|
fn assemble_hcl_file(lines : Array[HclLine]) -> HclFile {
  let blocks : Array[HclBlock] = []
  let kind_stack : Array[String] = []
  let name_stack : Array[String] = []
  let sig_stack : Array[String] = []
  let lineno_stack : Array[Int] = []
  let attrs_stack : Array[Array[HclAttr]] = []

  for line in lines {
    match line {
      OneLine(kind~, name~, signature~, line_no~) => {
        blocks.push({ kind, name, signature, line_no, attrs: [] })
      }
      BlockOpen(kind~, name~, signature~, line_no~) => {
        kind_stack.push(kind)
        name_stack.push(name)
        sig_stack.push(signature)
        lineno_stack.push(line_no)
        attrs_stack.push([])
      }
      UnknownOpen => {
        kind_stack.push("")
        name_stack.push("")
        sig_stack.push("")
        lineno_stack.push(0)
        attrs_stack.push([])
      }
      Close => {
        if !kind_stack.is_empty() {
          let kind = kind_stack.pop().unwrap()
          let name = name_stack.pop().unwrap()
          let signature = sig_stack.pop().unwrap()
          let line_no = lineno_stack.pop().unwrap()
          let attrs = attrs_stack.pop().unwrap()
          if kind != "" {
            blocks.push({ kind, name, signature, line_no, attrs })
          }
        }
      }
      Attr(name~, value~, line_no~) => {
        if !kind_stack.is_empty() && !attrs_stack.is_empty() {
          let top_kind = kind_stack[kind_stack.length() - 1]
          if top_kind != "" {
            attrs_stack[attrs_stack.length() - 1].push({ name, value, line_no })
          }
        }
      }
      Ignored => ()
    }
  }

  { blocks, }
}

///|
/// Parse an HCL/Terraform file represented as an array of source lines.
/// Returns an `HclFile` containing all recognised top-level and nested blocks
/// together with their immediate attributes.
pub fn parse_hcl_file(lines : Array[String]) -> HclFile {
  let classified : Array[HclLine] = []
  for i in 0..<lines.length() {
    classified.push(classify_line(lines[i].to_string(), i + 1))
  }
  assemble_hcl_file(classified)
}
