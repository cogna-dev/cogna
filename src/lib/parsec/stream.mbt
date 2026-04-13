///|
pub struct TokenStream {
  tokens : Array[Token]
  index : Int
}

///|
pub fn new_stream(tokens : Array[Token]) -> TokenStream {
  { tokens, index: 0 }
}

///|
pub fn TokenStream::is_done(self : TokenStream) -> Bool {
  self.index >= self.tokens.length()
}

///|
pub fn TokenStream::current(self : TokenStream) -> Token? {
  if self.is_done() {
    None
  } else {
    Some(self.tokens[self.index])
  }
}

///|
pub fn TokenStream::advance(self : TokenStream, count? : Int = 1) -> TokenStream {
  let next = self.index + count
  if next >= self.tokens.length() {
    { tokens: self.tokens, index: self.tokens.length() }
  } else {
    { tokens: self.tokens, index: next }
  }
}

///|
pub fn TokenStream::remaining(self : TokenStream) -> Int {
  if self.index >= self.tokens.length() {
    0
  } else {
    self.tokens.length() - self.index
  }
}

///|
pub fn TokenStream::slice(self : TokenStream, start : Int, end_ : Int) -> Array[Token] {
  let begin = if start < 0 { 0 } else { start }
  let end_index = if end_ > self.tokens.length() {
    self.tokens.length()
  } else {
    end_
  }
  let out : Array[Token] = []
  for i in begin..<end_index {
    out.push(self.tokens[i])
  }
  out
}
