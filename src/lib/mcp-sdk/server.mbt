///|
let cancelled_requests : Map[String, Bool] = {}

///|
let active_requests : Map[String, RequestContext] = {}

///|
fn parse_cancel_request_id(params : Json) -> Json {
  match params {
    Object(object) =>
      match object.get("requestId") {
        Some(value) => value
        None => object.get("id").unwrap_or(Json::null())
      }
    _ => Json::null()
  }
}

///|
fn mark_request_cancelled(id : Json) -> Bool {
  match request_id_key(id) {
    Some(key) => {
      cancelled_requests[key] = true
      true
    }
    None => false
  }
}

///|
fn is_request_cancelled_key(key : String) -> Bool {
  match cancelled_requests.get(key) {
    Some(true) => true
    _ => false
  }
}

///|
fn consume_request_cancelled_by_key(key : String) -> Bool {
  if is_request_cancelled_key(key) {
    cancelled_requests[key] = false
    true
  } else {
    false
  }
}

///|
fn remove_active_request(id : Json) -> Unit {
  match request_id_key(id) {
    Some(key) => {
      active_requests.remove(key)
      cancelled_requests.remove(key)
    }
    None => ()
  }
}

///|
fn start_request_context(request : Json) -> RequestContext? {
  let now_ms = @env.now()
  let context_out = extract_request_context(request, now_ms)
  guard context_out is Some(context) else { return None }
  active_requests[context.request_key] = context
  Some(context)
}

///|
fn is_runtime_cancelled(context : RequestContext) -> Bool {
  if is_request_cancelled_key(context.request_key) {
    true
  } else {
    request_runtime_cancelled(context, @env.now())
  }
}

///|
pub fn clear_runtime_state() -> Unit {
  active_requests.clear()
  cancelled_requests.clear()
}

///|
pub fn runtime_context_snapshot() -> Json {
  let entries : Array[Json] = []
  let now_ms = @env.now()
  for key, context in active_requests {
    let cancelled = is_request_cancelled_key(key)
    let deadline_exceeded = is_deadline_exceeded(context, now_ms)
    entries.push({
      "requestId": context.request_id,
      "requestKey": key,
      "startedAtMs": context.started_at_ms.to_int(),
      "deadlineMs": match context.deadline_ms {
        Some(value) =>
          Json::number(value.to_int().to_double(), repr="\{value.to_int()}")
        None => Json::null()
      },
      "cancelled": cancelled,
      "deadlineExceeded": deadline_exceeded,
    })
  }
  { "activeRequests": entries }
}

///|
fn with_request_context(
  request : Json,
  action : (RequestContext?) -> Json,
) -> Json {
  let context_out = start_request_context(request)
  let response = action(context_out)
  match context_out {
    Some(context) => {
      remove_active_request(context.request_id)
      response
    }
    None => response
  }
}

///|
fn deadline_exceeded_error(id : Json) -> Json {
  error_response(id, -32603, "request deadline exceeded")
}

///|
fn request_cancelled_error(id : Json) -> Json {
  error_response(id, -32603, "request cancelled")
}

///|
fn cancelled_or_deadline_error(context : RequestContext) -> Json? {
  if is_request_cancelled_key(context.request_key) {
    Some(request_cancelled_error(context.request_id))
  } else if is_deadline_exceeded(context, @env.now()) {
    Some(deadline_exceeded_error(context.request_id))
  } else {
    None
  }
}

///|
fn handle_tool_call_with_context(
  context : RequestContext?,
  params : Json,
  tool_call_handler : (Json, RequestContext, () -> Bool) -> Result[
    Json,
    (Int, String),
  ],
) -> Json {
  guard context is Some(request_context) else {
    return error_response(Json::null(), -32600, "missing request context")
  }
  let key = request_context.request_key
  if consume_request_cancelled_by_key(key) {
    return request_cancelled_error(request_context.request_id)
  }
  if is_deadline_exceeded(request_context, @env.now()) {
    return deadline_exceeded_error(request_context.request_id)
  }
  let cancelled = () => is_runtime_cancelled(request_context)
  match tool_call_handler(params, request_context, cancelled) {
    Ok(result) =>
      if cancelled() {
        match cancelled_or_deadline_error(request_context) {
          Some(error) => error
          None => success_response(request_context.request_id, result)
        }
      } else {
        success_response(request_context.request_id, result)
      }
    Err((code, message)) =>
      error_response(request_context.request_id, code, message)
  }
}

///|
fn cancel_runtime_snapshot_result(id : Json) -> Json {
  success_response(id, runtime_context_snapshot())
}

///|
pub fn handle_standard_request(
  request : Json,
  initialize_result : Json,
  ping_payload : Json,
  tools : Array[Json],
  sync_tools_state : () -> Result[Bool, String],
  tool_call_handler : (Json, RequestContext, () -> Bool) -> Result[
    Json,
    (Int, String),
  ],
) -> Json {
  route_request(request, ctx => {
    match ctx.method_name {
      "initialize" => {
        let sync_out = sync_tools_state()
        guard sync_out is Ok(_) else {
          return internal_error(ctx.id, sync_out.unwrap_err())
        }
        success_response(ctx.id, initialize_result)
      }
      "ping" => success_response(ctx.id, ping_payload)
      "tools/list" => {
        let sync_out = sync_tools_state()
        guard sync_out is Ok(changed) else {
          return internal_error(ctx.id, sync_out.unwrap_err())
        }
        success_response(ctx.id, { "tools": tools, "listChanged": changed })
      }
      "tools/list_changed" => {
        let sync_out = sync_tools_state()
        guard sync_out is Ok(changed) else {
          return internal_error(ctx.id, sync_out.unwrap_err())
        }
        success_response(ctx.id, {
          "changed": changed,
          "notification": "notifications/tools/list_changed",
        })
      }
      "tools/call" =>
        with_request_context(request, context => {
          handle_tool_call_with_context(context, ctx.params, tool_call_handler)
        })
      "$/cancelRequest" => {
        let target_id = parse_cancel_request_id(ctx.params)
        if target_id == ctx.id {
          error_response(ctx.id, -32600, "cannot cancel initialize request")
        } else {
          let cancelled = mark_request_cancelled(target_id)
          success_response(ctx.id, {
            "cancelled": cancelled,
            "requestId": target_id,
          })
        }
      }
      "runtime/context" => cancel_runtime_snapshot_result(ctx.id)
      "notifications/initialized" => success_response(ctx.id, { "ok": true })
      "notifications/cancelled" => {
        let target_id = parse_cancel_request_id(ctx.params)
        let cancelled = mark_request_cancelled(target_id)
        success_response(ctx.id, {
          "ok": true,
          "cancelled": cancelled,
          "requestId": target_id,
        })
      }
      _ =>
        error_response(ctx.id, -32601, "method not found: \{ctx.method_name}")
    }
  })
}
