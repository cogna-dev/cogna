///|
test "extractor bench run rejects unsupported backend" {
  let out = run({ profile: "go-module", fixture: "full", backend: "canonical" })
  guard out is Err(err) else {
    fail("expected unsupported backend to fail")
  }
  assert_true(err.message.contains("backend must be one of"))
}
