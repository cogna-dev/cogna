///|
pub fn parse_tool_call(
  params : Json,
) -> Result[(String, Map[String, Json]), (Int, String)] {
  guard params is Object(params_object) else {
    return Err((-32602, "tools/call params must be an object"))
  }
  guard params_object.get("name") is Some(String(name)) else {
    return Err((-32602, "tools/call missing tool name"))
  }

  let args : Map[String, Json] = match params_object.get("arguments") {
    Some(Object(arguments)) => arguments
    Some(Null) => {}
    None => {}
    _ => return Err((-32602, "tools/call arguments must be an object"))
  }
  Ok((name, args))
}
