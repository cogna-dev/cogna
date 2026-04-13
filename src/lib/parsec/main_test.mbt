///|
test "parsec split_top_level respects nested delimiters" {
  inspect(
    split_top_level("A, func(T, U), map[string]struct{ X int }", ','),
    content="[\"A\", \" func(T, U)\", \" map[string]struct{ X int }\"]",
  )
}

///|
test "parsec tokenizes docs and keywords" {
  let doc_tokens = tokenize_line("/// hello", 1)
  inspect(doc_tokens.length(), content="1")
  inspect(token_text(doc_tokens[0]), content="hello")

  let tokens = tokenize_line("pub fn hello(name: String)", 2)
  inspect(tokens.length() > 0, content="true")
  inspect(token_text(tokens[0]), content="pub")
  inspect(token_text(tokens[1]), content="fn")
  inspect(token_text(tokens[2]), content="hello")
}

///|
test "parsec tag and delimited parse token stream" {
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
  match result {
    Matched(value~, next~) => {
      inspect(token_text(value), content="hello")
      inspect(next.is_done(), content="true")
    }
    _ => fail("expected parse to succeed")
  }
}
