///|
pub(open) trait Display {
  display(self : Self) -> String
}

///|
pub type CliResult[T, E] = Result[T, E]

///|
pub fn[T : Display] display(value : T) -> String {
  value.display()
}
