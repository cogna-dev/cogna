///|
test "configured bench warmup runs accepts zero" {
  @sys.set_env_var("CODEIQ_BENCH_WARMUP_RUNS", "0")
  inspect(configured_bench_warmup_runs(), content="0")
  @sys.unset_env_var("CODEIQ_BENCH_WARMUP_RUNS")
}

///|
test "configured bench measure runs stays positive only" {
  @sys.set_env_var("CODEIQ_BENCH_MEASURE_RUNS", "0")
  inspect(configured_bench_measure_runs(), content="9")
  @sys.unset_env_var("CODEIQ_BENCH_MEASURE_RUNS")
}
