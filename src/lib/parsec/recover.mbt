///|
pub fn skip_balanced(
  text : String,
  start : Int,
  open_char : UInt16,
  close_char : UInt16,
) -> Int? {
  matching_delimiter_index(text, start, open_char, close_char)
}

///|
pub fn skip_balanced_tokens(
  tokens : Array[Token],
  start : Int,
  open_text : String,
  close_text : String,
) -> Int? {
  let mut depth = 0
  for i in start..<tokens.length() {
    let text = token_text(tokens[i])
    if text == open_text {
      depth += 1
    } else if text == close_text {
      depth -= 1
      if depth == 0 {
        return Some(i)
      }
    }
  }
  None
}

///|
pub fn recover_until_prefix(
  lines : Array[String],
  start_index : Int,
  prefixes : Array[String],
) -> Int {
  for i in start_index..<lines.length() {
    let clean = trim_spaces(lines[i])
    if starts_with_any(clean, prefixes) {
      return i
    }
  }
  lines.length()
}
