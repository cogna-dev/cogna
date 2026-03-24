///|
pub fn get_required_string(
  args : Map[String, Json],
  key : String,
) -> Result[String, String] {
  match args.get(key) {
    Some(String(value)) => Ok(value)
    _ => Err("missing required string argument \{key}")
  }
}

///|
pub fn get_optional_string(args : Map[String, Json], key : String) -> String? {
  match args.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
pub fn get_optional_int(args : Map[String, Json], key : String) -> Int? {
  match args.get(key) {
    Some(Number(value, ..)) => Some(value.to_int())
    _ => None
  }
}
