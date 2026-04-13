///|
pub(all) enum TokenKind {
  Identifier(String)
  Keyword(String)
  Symbol(String)
  StringLiteral(String)
  NumberLiteral(String)
  DocComment(String)
  Comment(String)
  Attribute(String)
  Raw(String)
}

///|
pub struct Token {
  kind : TokenKind
  start : Int
  end : Int
  line : Int
  column : Int
}

///|
fn is_space(c : UInt16) -> Bool {
  c == ' ' || c == '\t' || c == '\r'
}

///|
fn is_alpha(c : UInt16) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
fn is_digit(c : UInt16) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn is_ident_char(c : UInt16) -> Bool {
  is_alpha(c) || is_digit(c)
}

///|
fn keyword_kind(text : String) -> TokenKind {
  match text {
    "package" | "import" | "type" | "func" | "const" | "var" | "struct" |
    "interface" | "pub" | "mod" | "trait" | "impl" | "enum" | "union" |
    "static" | "unsafe" | "extern" | "where" | "use" | "macro_rules" |
    "macro" => Keyword(text)
    _ => Identifier(text)
  }
}

///|
pub fn token_text(token : Token) -> String {
  match token.kind {
    Identifier(text) | Keyword(text) | Symbol(text) | StringLiteral(text) |
    NumberLiteral(text) | DocComment(text) | Comment(text) | Attribute(text) |
    Raw(text) => text
  }
}

///|
pub fn trim_spaces(value : String) -> String {
  let mut start = 0
  let mut end = value.length()
  while start < end && is_space(value.code_unit_at(start)) {
    start += 1
  }
  while end > start && is_space(value.code_unit_at(end - 1)) {
    end -= 1
  }
  value[start:end].to_string()
}

///|
pub fn line_before_comment(value : String) -> String {
  match value.find("//") {
    Some(idx) => value[0:idx].to_string()
    None => value
  }
}

///|
pub fn trim_quotes(value : String) -> String {
  let trimmed = trim_spaces(value)
  if trimmed.length() >= 2 &&
    ((trimmed.code_unit_at(0) == '"' &&
        trimmed.code_unit_at(trimmed.length() - 1) == '"') ||
      (trimmed.code_unit_at(0) == '\'' &&
        trimmed.code_unit_at(trimmed.length() - 1) == '\'')) {
    trimmed[1:trimmed.length() - 1].to_string()
  } else {
    trimmed
  }
}

///|
pub fn first_token(text : String) -> String {
  let trimmed = trim_spaces(text)
  if trimmed == "" {
    return ""
  }
  let mut end = 0
  while end < trimmed.length() {
    let c = trimmed.code_unit_at(end)
    if is_space(c) || c == '(' || c == '{' || c == '[' || c == ':' || c == ',' ||
      c == ';' {
      break
    }
    end += 1
  }
  trimmed[0:end].to_string()
}

///|
pub fn token_before(value : String, marker : String) -> String {
  match value.find(marker) {
    Some(idx) => first_token(value[0:idx].to_string())
    None => first_token(value)
  }
}

///|
pub fn quoted_parts(line : String) -> Array[String] {
  let parts : Array[String] = []
  let mut start = -1
  for i in 0..<line.length() {
    if line.code_unit_at(i) == '"' {
      if start < 0 {
        start = i + 1
      } else {
        parts.push(line[start:i].to_string())
        start = -1
      }
    }
  }
  parts
}

///|
pub fn leading_spaces(line : String) -> Int {
  let mut count = 0
  while count < line.length() && line.code_unit_at(count) == ' ' {
    count += 1
  }
  count
}

///|
pub fn starts_with_any(value : String, prefixes : Array[String]) -> Bool {
  for i in 0..<prefixes.length() {
    if value.has_prefix(prefixes[i]) {
      return true
    }
  }
  false
}

///|
pub fn strip_braces(value : String) -> String {
  let mut out = trim_spaces(value)
  if out.has_suffix("{") {
    out = trim_spaces(out.strip_suffix("{").unwrap_or(out).to_string())
  }
  if out.has_suffix("}") {
    out = trim_spaces(out.strip_suffix("}").unwrap_or(out).to_string())
  }
  if out.has_suffix(";") {
    out = trim_spaces(out.strip_suffix(";").unwrap_or(out).to_string())
  }
  out
}

///|
pub fn matching_delimiter_index(
  value : String,
  start : Int,
  open_char : UInt16,
  close_char : UInt16,
) -> Int? {
  let mut depth = 0
  for i in start..<value.length() {
    let c = value.code_unit_at(i)
    if c == open_char {
      depth += 1
    } else if c == close_char {
      depth -= 1
      if depth == 0 {
        return Some(i)
      }
    }
  }
  None
}

///|
pub fn split_top_level(value : String, delimiter : UInt16) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  let mut paren = 0
  let mut bracket = 0
  let mut brace = 0
  let mut angle = 0
  for i in 0..<value.length() {
    let c = value.code_unit_at(i)
    if c == '(' {
      paren += 1
    } else if c == ')' {
      if paren > 0 {
        paren -= 1
      }
    } else if c == '[' {
      bracket += 1
    } else if c == ']' {
      if bracket > 0 {
        bracket -= 1
      }
    } else if c == '{' {
      brace += 1
    } else if c == '}' {
      if brace > 0 {
        brace -= 1
      }
    } else if c == '<' {
      angle += 1
    } else if c == '>' {
      if angle > 0 {
        angle -= 1
      }
    } else if c == delimiter && paren == 0 && bracket == 0 && brace == 0 &&
      angle == 0 {
      parts.push(value[start:i].to_string())
      start = i + 1
    }
  }
  parts.push(value[start:].to_string())
  parts
}

///|
pub fn unique_trimmed_strings(values : Array[String]) -> Array[String] {
  let unique : Array[String] = []
  let seen : Map[String, Bool] = {}
  for i in 0..<values.length() {
    let value = trim_spaces(values[i])
    if value == "" || seen.contains(value) {
      continue
    }
    seen[value] = true
    unique.push(value)
  }
  unique
}

///|
pub fn tokenize_line(line : String, line_no : Int) -> Array[Token] {
  let tokens : Array[Token] = []
  let trimmed = trim_spaces(line)
  if trimmed == "" {
    return tokens
  }
  if trimmed.has_prefix("///") {
    tokens.push({
      kind: DocComment(trim_spaces(trimmed[3:].to_string())),
      start: 0,
      end: line.length(),
      line: line_no,
      column: 0,
    })
    return tokens
  }
  if trimmed.has_prefix("//") {
    tokens.push({
      kind: Comment(trim_spaces(trimmed[2:].to_string())),
      start: 0,
      end: line.length(),
      line: line_no,
      column: 0,
    })
    return tokens
  }
  if trimmed.has_prefix("#") {
    tokens.push({
      kind: Attribute(trimmed),
      start: 0,
      end: line.length(),
      line: line_no,
      column: 0,
    })
    return tokens
  }
  let mut i = 0
  while i < line.length() {
    let c = line.code_unit_at(i)
    if is_space(c) {
      i += 1
      continue
    }
    if c == '"' || c == '\'' {
      let quote = c
      let mut end = i + 1
      while end < line.length() && line.code_unit_at(end) != quote {
        end += 1
      }
      let final_end = if end < line.length() { end + 1 } else { line.length() }
      tokens.push({
        kind: StringLiteral(line[i:final_end].to_string()),
        start: i,
        end: final_end,
        line: line_no,
        column: i,
      })
      i = final_end
      continue
    }
    if is_alpha(c) {
      let mut end = i + 1
      while end < line.length() && is_ident_char(line.code_unit_at(end)) {
        end += 1
      }
      let text = line[i:end].to_string()
      tokens.push({
        kind: keyword_kind(text),
        start: i,
        end,
        line: line_no,
        column: i,
      })
      i = end
      continue
    }
    if is_digit(c) {
      let mut end = i + 1
      while end < line.length() && (is_digit(line.code_unit_at(end)) ||
          line.code_unit_at(end) == '.' || line.code_unit_at(end) == '_') {
        end += 1
      }
      tokens.push({
        kind: NumberLiteral(line[i:end].to_string()),
        start: i,
        end,
        line: line_no,
        column: i,
      })
      i = end
      continue
    }
    tokens.push({
      kind: Symbol(line[i:i + 1].to_string()),
      start: i,
      end: i + 1,
      line: line_no,
      column: i,
    })
    i += 1
  }
  tokens
}
