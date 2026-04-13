# parsec library

Reusable tokenization, parser-combinator, and recovery helpers for MoonBit packages.

This package intentionally contains **generic** capabilities only:

- Line tokenization (`tokenize_line`, `Token`, `TokenKind`)
- Token stream traversal (`new_stream`, `TokenStream`)
- Small parser combinators (`tag`, `pred`, `many0`, `many1`, `seq2`, `alt2`, `delimited`)
- String and token recovery helpers (`split_top_level`, `skip_balanced`, `skip_balanced_tokens`)

Language- or product-specific parsing rules should stay in the owning package.

## Example

```mbt check
///|
test "parsec parses a delimited identifier" {
  let tokens = tokenize_line("(hello)", 1)
  let stream = new_stream(tokens)
  let parse_word = fn(stream : TokenStream) {
    pred(stream, "identifier", fn(token) {
      match token.kind {
        Identifier(_) | Keyword(_) => true
        _ => false
      }
    })
  }
  let result = delimited(
    stream,
    fn(s) { tag(s, "(") },
    parse_word,
    fn(s) { tag(s, ")") },
  )
  guard result is Matched(value~, next~) else { fail("parse should succeed") }
  inspect(token_text(value), content="hello")
  inspect(next.is_done(), content="true")
}
```
