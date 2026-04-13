///|
pub(all) enum ParseResult[T] {
  Matched(value~ : T, next~ : TokenStream)
  Error(String)
  Failure(String)
  Incomplete
}

///|
pub fn tag(stream : TokenStream, expected : String) -> ParseResult[Token] {
  match stream.current() {
    Some(token) if token_text(token) == expected =>
      Matched(value=token, next=stream.advance())
    Some(token) =>
      Error("expected '\{expected}' but found '\{token_text(token)}'")
    None => Incomplete
  }
}

///|
pub fn pred(
  stream : TokenStream,
  label : String,
  f : (Token) -> Bool,
) -> ParseResult[Token] {
  match stream.current() {
    Some(token) if f(token) => Matched(value=token, next=stream.advance())
    Some(_) => Error("expected '\{label}'")
    None => Incomplete
  }
}

///|
pub fn[T, U] map_result(
  stream : TokenStream,
  parser : (TokenStream) -> ParseResult[T],
  f : (T) -> U,
) -> ParseResult[U] {
  match parser(stream) {
    Matched(value~, next~) => Matched(value=f(value), next=next)
    Error(err) => Error(err)
    Failure(err) => Failure(err)
    Incomplete => Incomplete
  }
}

///|
pub fn[T] opt(
  stream : TokenStream,
  parser : (TokenStream) -> ParseResult[T],
) -> ParseResult[T?] {
  match parser(stream) {
    Matched(value~, next~) => Matched(value=Some(value), next=next)
    Error(_) => Matched(value=None, next=stream)
    Failure(err) => Failure(err)
    Incomplete => Incomplete
  }
}

///|
pub fn[T] many0(
  stream : TokenStream,
  parser : (TokenStream) -> ParseResult[T],
) -> ParseResult[Array[T]] {
  let values : Array[T] = []
  let mut current : TokenStream = stream
  while true {
    match parser(current) {
      Matched(value~, next~) => {
        values.push(value)
        current = next
      }
      Error(_) => return Matched(value=values, next=current)
      Failure(err) => return Failure(err)
      Incomplete => return Incomplete
    }
  }
  Matched(value=values, next=current)
}

///|
pub fn[T] many1(
  stream : TokenStream,
  parser : (TokenStream) -> ParseResult[T],
) -> ParseResult[Array[T]] {
  match many0(stream, parser) {
    Matched(value~, next~) if !value.is_empty() =>
      Matched(value=value, next=next)
    Matched(..) => Error("expected at least one match")
    Error(err) => Error(err)
    Failure(err) => Failure(err)
    Incomplete => Incomplete
  }
}

///|
pub fn[T, U] seq2(
  stream : TokenStream,
  left : (TokenStream) -> ParseResult[T],
  right : (TokenStream) -> ParseResult[U],
) -> ParseResult[(T, U)] {
  match left(stream) {
    Matched(value=left_value, next=next1) =>
      match right(next1) {
        Matched(value=right_value, next=next2) =>
          Matched(value=(left_value, right_value), next=next2)
        Error(err) => Error(err)
        Failure(err) => Failure(err)
        Incomplete => Incomplete
      }
    Error(err) => Error(err)
    Failure(err) => Failure(err)
    Incomplete => Incomplete
  }
}

///|
pub fn[T] alt2(
  stream : TokenStream,
  left : (TokenStream) -> ParseResult[T],
  right : (TokenStream) -> ParseResult[T],
) -> ParseResult[T] {
  match left(stream) {
    Matched(value~, next~) => Matched(value=value, next=next)
    Error(_) => right(stream)
    Failure(err) => Failure(err)
    Incomplete => right(stream)
  }
}

///|
pub fn[T] cut(result : ParseResult[T]) -> ParseResult[T] {
  match result {
    Error(err) => Failure(err)
    _ => result
  }
}

///|
pub fn[T, U, V] delimited(
  stream : TokenStream,
  open : (TokenStream) -> ParseResult[T],
  body : (TokenStream) -> ParseResult[U],
  close : (TokenStream) -> ParseResult[V],
) -> ParseResult[U] {
  match open(stream) {
    Matched(next=open_next, ..) =>
      match body(open_next) {
        Matched(value=body_value, next=body_next) =>
          match close(body_next) {
            Matched(next=close_next, ..) =>
              Matched(value=body_value, next=close_next)
            Error(err) => Error(err)
            Failure(err) => Failure(err)
            Incomplete => Incomplete
          }
        Error(err) => Error(err)
        Failure(err) => Failure(err)
        Incomplete => Incomplete
      }
    Error(err) => Error(err)
    Failure(err) => Failure(err)
    Incomplete => Incomplete
  }
}
