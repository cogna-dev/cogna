///|
pub fn dispatch_tool_call(
  params : Json,
  context : RequestContext,
  on_outlines : (Map[String, Json], RequestContext) -> Result[Json, String],
  on_symbol : (Map[String, Json], RequestContext) -> Result[Json, String],
) -> Result[Json, (Int, String)] {
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

  match name {
    "codeiq.query.outlines" =>
      match on_outlines(args, context) {
        Ok(result) => Ok(result)
        Err(message) => Err((-32602, message))
      }
    "codeiq.query.symbol" =>
      match on_symbol(args, context) {
        Ok(result) => Ok(result)
        Err(message) => Err((-32602, message))
      }
    _ => Err((-32601, "unknown tool: \{name}"))
  }
}
