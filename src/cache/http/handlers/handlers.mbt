// User-owned file. Safe from regeneration.

///|
pub fn health_check(
  _ctx : @lib.RequestContext,
  _input : @generated.HealthCheckInput,
) -> Result[@generated.HealthCheckResponse, @lib.AppError] {
  Ok(@generated.HealthCheckResponse::Ok(()))
}
