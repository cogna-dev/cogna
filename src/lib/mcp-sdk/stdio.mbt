///|
fn is_jsonrpc_notification_request(request : Json) -> Bool {
  guard request is Object(request_object) else { return false }
  if request_object.get("method") is Some(String(_)) {
    !request_object.contains("id")
  } else {
    false
  }
}

///|
fn list_changed_notification() -> Json {
  {
    "jsonrpc": "2.0",
    "method": "notifications/tools/list_changed",
    "params": { "changed": true },
  }
}

///|
fn should_emit_list_changed_notification(response : Json) -> Bool {
  guard response is Object(response_object) else { return false }
  guard response_object.get("result") is Some(Object(result_object)) else {
    return false
  }
  match result_object.get("listChanged") {
    Some(True) => true
    _ => false
  }
}

///|
pub fn stdio_output_lines(
  line : String,
  request_handler : (Json) -> Json,
) -> Array[String] {
  let outputs : Array[String] = []
  let parsed = try? @json.parse(line)
  guard parsed is Ok(request) else {
    outputs.push(
      error_response(Json::null(), -32700, "parse error").stringify(indent=0),
    )
    return outputs
  }
  let response = request_handler(request)
  if is_jsonrpc_notification_request(request) {
    return outputs
  }
  if should_emit_list_changed_notification(response) {
    outputs.push(list_changed_notification().stringify(indent=0))
  }
  outputs.push(response.stringify(indent=0))
  outputs
}

///|
pub fn serve_stdio_once(
  line : String,
  request_handler : (Json) -> Json,
) -> String {
  let outputs = stdio_output_lines(line, request_handler)
  if outputs.is_empty() {
    ""
  } else {
    outputs[outputs.length() - 1]
  }
}

///|
fn process_stdio_line(line : String, request_handler : (Json) -> Json) -> Unit {
  let trimmed = line.trim().to_string()
  if trimmed == "" {
    return
  }
  let outputs = stdio_output_lines(trimmed, request_handler)
  for i in 0..<outputs.length() {
    println(outputs[i])
  }
}

///|
pub fn run_stdio_repl(
  request_handler : (Json) -> Json,
  stdin_path? : String = "/dev/stdin",
) -> Unit {
  ignore(stdin_path)
  for i = 0; ; i = i + 1 {
    match read_stdin_line() {
      Some(line) => {
        process_stdio_line(line, request_handler)
        ignore(i)
      }
      None => return
    }
  }
}
