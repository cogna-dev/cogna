///|
pub(all) struct RequestContext {
  request_id : Json
  request_key : String
  started_at_ms : UInt64
  deadline_ms : UInt64?
} derive(Show, Eq)

///|
pub fn request_id_key(id : Json) -> String? {
  if id == Json::null() {
    None
  } else {
    Some(id.stringify(indent=0))
  }
}

///|
fn positive_int_from_json(value : Json) -> Int? {
  match value {
    Number(number, ..) => {
      let int_value = number.to_int()
      if int_value <= 0 {
        None
      } else {
        Some(int_value)
      }
    }
    _ => None
  }
}

///|
fn positive_int_from_object(object : Map[String, Json], field : String) -> Int? {
  match object.get(field) {
    Some(value) => positive_int_from_json(value)
    None => None
  }
}

///|
pub fn parse_deadline_ms(params : Json, now_ms : UInt64) -> UInt64? {
  guard params is Object(params_object) else { return None }

  match positive_int_from_object(params_object, "deadlineMs") {
    Some(value) => return Some(value.to_uint64())
    None => ()
  }

  match positive_int_from_object(params_object, "timeoutMs") {
    Some(value) => return Some(now_ms + value.to_uint64())
    None => None
  }
}

///|
fn id_from_request_object(request_object : Map[String, Json]) -> Json {
  match request_object.get("id") {
    Some(id) => id
    None => Json::null()
  }
}

///|
pub fn extract_request_context(
  request : Json,
  now_ms : UInt64,
) -> RequestContext? {
  guard request is Object(request_object) else { return None }
  if !request_object.contains("id") {
    return None
  }
  let request_id = id_from_request_object(request_object)
  let request_key_out = request_id_key(request_id)
  guard request_key_out is Some(request_key) else { return None }

  let params = match request_object.get("params") {
    Some(value) => value
    None => Json::object({})
  }
  let deadline_ms = parse_deadline_ms(params, now_ms)
  Some({ request_id, request_key, started_at_ms: now_ms, deadline_ms })
}

///|
pub fn is_deadline_exceeded(ctx : RequestContext, now_ms : UInt64) -> Bool {
  match ctx.deadline_ms {
    Some(deadline) => now_ms >= deadline
    None => false
  }
}

///|
pub fn request_runtime_cancelled(ctx : RequestContext, now_ms : UInt64) -> Bool {
  is_deadline_exceeded(ctx, now_ms)
}
