///| Extractor benchmark harness — A003-5 parity-first
///|
///| Runs `backend=native` and `backend=lsp` on the same examples corpus,
///| measures repeated-build wall time for the MoonBit-native and lsp-assisted
///| build modes, compares the final emitted artifacts, and emits a JSON report
///| per fixture. The parity gate (`snapshotDiffCount == 0`) is mandatory.
///|
///| Run on the native target only:
///|
///|   moon test --target native src/scripts/benchmark
///|
///| Results are written to examples/<fixture>/full/bench/summary.json and
///| a combined report to /tmp/extractor_bench_report.json.

///|
fn bench_error(msg : String) -> @cli.CliError {
  @cli.command_error("extractor_bench: \{msg}")
}

///|
struct BenchFixture {
  name : String
  label : String
  profile : String
  summary_root : String
  repo_root : String
  source_file : String
  include_globs : Array[String]
  lsif_path : String
  copy_source : Bool
}

///|
struct BenchRunArtifacts {
  backend : String
  mode : String
  wall_ms : Int
  manifest : String
  metadata : String
  checksums : String
  declarations : String
  symbols : String
  components : String
  sbom : String
}

///|
fn path_basename(path : String) -> String {
  let trimmed = path.trim().to_string()
  if trimmed == "" {
    return "fixture"
  }
  let normalized = if trimmed.has_suffix("/") {
    trimmed[:trimmed.length() - 1].to_string()
  } else {
    trimmed
  }
  let parts = normalized.split("/").to_array()
  if parts.is_empty() {
    normalized
  } else {
    parts[parts.length() - 1].to_string()
  }
}

///|
fn default_bench_fixture(profile : String) -> BenchFixture {
  match profile {
    "go-module" => {
      name: "go-module",
      label: "examples/go-module/full",
      profile,
      summary_root: "examples/go-module/full",
      repo_root: "examples/go-module/full/repo",
      source_file: "main.go",
      include_globs: ["**/*.go"],
      lsif_path: "examples/go-module/full/bench/lsif/dump.lsif",
      copy_source: true,
    }
    "rust-crate" => {
      name: "rust-crate",
      label: "examples/rust-crate/full",
      profile,
      summary_root: "examples/rust-crate/full",
      repo_root: "examples/rust-crate/full/repo",
      source_file: "lib.rs",
      include_globs: ["**/*.rs"],
      lsif_path: "examples/rust-crate/full/bench/lsif/dump.lsif",
      copy_source: true,
    }
    _ => {
      name: profile,
      label: profile,
      profile,
      summary_root: profile,
      repo_root: profile,
      source_file: "",
      include_globs: [],
      lsif_path: "",
      copy_source: false,
    }
  }
}

///|
fn default_include_globs(profile : String) -> Array[String] {
  if profile == "go-module" {
    ["**/*.go"]
  } else if profile == "rust-crate" {
    ["**/*.rs"]
  } else {
    []
  }
}

///|
fn parse_include_globs(raw : String, fallback : Array[String]) -> Array[String] {
  let normalized = raw.trim().to_string().replace_all(old="\n", new=";")
  if normalized == "" {
    return fallback
  }
  let patterns : Array[String] = []
  for part in normalized.split(";") {
    let pattern = part.to_string().trim().to_string()
    if pattern != "" {
      patterns.push(pattern)
    }
  }
  if patterns.is_empty() {
    fallback
  } else {
    patterns
  }
}

///|
fn external_bench_fixture(
  profile : String,
  repo_root : String,
  summary_root : String,
  lsif_path : String,
  include_globs : Array[String],
) -> BenchFixture {
  let source_file = if profile == "go-module" { "main.go" } else { "lib.rs" }
  {
    name: path_basename(summary_root),
    label: repo_root,
    profile,
    summary_root,
    repo_root,
    source_file,
    include_globs,
    lsif_path,
    copy_source: false,
  }
}

///|
fn active_bench_fixtures() -> Array[BenchFixture] {
  let fixtures : Array[BenchFixture] = []
  match @sys.get_env_var("CODEIQ_BENCH_GO_ROOT") {
    Some(root) if root.trim().to_string() != "" =>
      fixtures.push(
        external_bench_fixture(
          "go-module",
          root.trim().to_string(),
          @sys.get_env_var("CODEIQ_BENCH_GO_SUMMARY_ROOT")
          .unwrap_or("spec/bench/aws-sdk-go-v2")
          .trim()
          .to_string(),
          @sys.get_env_var("CODEIQ_BENCH_GO_LSIF_PATH")
          .unwrap_or("\{root.trim().to_string()}/bench/lsif/dump.lsif")
          .trim()
          .to_string(),
          parse_include_globs(
            @sys.get_env_var("CODEIQ_BENCH_GO_INCLUDE").unwrap_or(""),
            default_include_globs("go-module"),
          ),
        ),
      )
    _ => fixtures.push(default_bench_fixture("go-module"))
  }
  match @sys.get_env_var("CODEIQ_BENCH_RUST_ROOT") {
    Some(root) if root.trim().to_string() != "" =>
      fixtures.push(
        external_bench_fixture(
          "rust-crate",
          root.trim().to_string(),
          @sys.get_env_var("CODEIQ_BENCH_RUST_SUMMARY_ROOT")
          .unwrap_or("spec/bench/aws-sdk-rust")
          .trim()
          .to_string(),
          @sys.get_env_var("CODEIQ_BENCH_RUST_LSIF_PATH")
          .unwrap_or("\{root.trim().to_string()}/bench/lsif/dump.lsif")
          .trim()
          .to_string(),
          parse_include_globs(
            @sys.get_env_var("CODEIQ_BENCH_RUST_INCLUDE").unwrap_or(""),
            default_include_globs("rust-crate"),
          ),
        ),
      )
    _ => fixtures.push(default_bench_fixture("rust-crate"))
  }
  fixtures
}

///|
fn cleanup_bench_repo(path : String, _source_file : String) -> Unit {
  @bench_shell.run_command_capture("rm -rf '" + path + "'") |> ignore
}

///|
fn cleanup_bench_pair(fixture : BenchFixture) -> Unit {
  cleanup_bench_repo("/tmp/extractor_bench_\{fixture.name}_native", fixture.source_file)
  cleanup_bench_repo("/tmp/extractor_bench_\{fixture.name}_lsp", fixture.source_file)
}

///|
fn cleanup_direct_repo(repo : String) -> Unit {
  @bench_shell.run_command_capture("rm -rf '\{repo}/dist'") |> ignore
  @fs.remove_file("\{repo}/codeiq.yaml") catch {
    _ => ()
  }
}

///|
fn cleanup_fixture_workspace(fixture : BenchFixture) -> Unit {
  if fixture.copy_source {
    cleanup_bench_pair(fixture)
  } else {
    cleanup_direct_repo(fixture.repo_root)
  }
}

///|
fn ensure_bench_repo(path : String) -> Result[Unit, @cli.CliError] {
  @fs.create_dir(path) catch {
    _ => ()
  }
  Ok(())
}

///|
fn write_bench_source_file(
  repo : String,
  fixture : BenchFixture,
) -> Result[Unit, @cli.CliError] {
  let src_path = "\{fixture.repo_root}/\{fixture.source_file}"
  let content = @fs.read_file_to_string(src_path) catch {
    err =>
      return Err(
        bench_error("cannot read fixture \{src_path}: \{err.to_string()}"),
      )
  }
  let parts = fixture.source_file.split("/").to_array()
  if parts.length() > 1 {
    let mut subdir = repo
    for i in 0..<(parts.length() - 1) {
      subdir = "\{subdir}/\{parts[i]}"
      @fs.create_dir(subdir) catch { _ => () }
    }
  }
  @fs.write_string_to_file("\{repo}/\{fixture.source_file}", content) catch {
    err => return Err(bench_error("cannot write source: \{err.to_string()}"))
  }
  Ok(())
}

///|
fn write_bench_config(
  repo : String,
  fixture : BenchFixture,
  validation : String,
) -> Result[Unit, @cli.CliError] {
  let purl = "pkg:\{fixture.profile}/bench@0.0.0"
  let include_entries = fixture.include_globs.map(fn(pattern) { "    - \{pattern}" })
  if include_entries.is_empty() {
    return Err(bench_error("benchmark include patterns are empty for \{fixture.label}"))
  }
  let config_content = (
    #|schemaVersion: ciq-config/v1
    #|profile: PROFILE_PLACEHOLDER
    #|validation: VALIDATION_PLACEHOLDER
    #|purl: PURL_PLACEHOLDER
    #|source:
    #|  repo: https://github.com/example/bench
    #|  ref: main
    #|inputs:
    #|  include:
    #|INCLUDE_PLACEHOLDER
    #|checks:
    #|  format: sarif
    #|  policy: default-compat
    #|
  )
    .replace(old="PROFILE_PLACEHOLDER", new=fixture.profile)
    .replace(old="VALIDATION_PLACEHOLDER", new=validation)
    .replace(old="PURL_PLACEHOLDER", new=purl)
    .replace(old="INCLUDE_PLACEHOLDER", new=include_entries.join("\n"))
  @fs.write_string_to_file("\{repo}/codeiq.yaml", config_content) catch {
    err => return Err(bench_error("cannot write config: \{err.to_string()}"))
  }
  Ok(())
}

///|
fn init_bench_git_repo(repo : String) -> Unit {
  @bench_shell.run_command_capture(
    "git -C '\{repo}' init -q && git -C '\{repo}' add . && git -C '\{repo}' commit -q -m init --allow-empty",
  )
  |> ignore
}

///|
let bench_warmup_runs = 1

///|
let bench_measure_runs = 9

///|
fn env_positive_int(name : String, fallback : Int) -> Int {
  match @sys.get_env_var(name) {
    Some(value) => {
      let parsed_out = try? @string.parse_int(value.trim())
      match parsed_out {
        Ok(parsed) if parsed > 0 => parsed
        _ => fallback
      }
    }
    None => fallback
  }
}

///|
fn env_non_negative_int(name : String, fallback : Int) -> Int {
  match @sys.get_env_var(name) {
    Some(value) => {
      let parsed_out = try? @string.parse_int(value.trim())
      match parsed_out {
        Ok(parsed) if parsed >= 0 => parsed
        _ => fallback
      }
    }
    None => fallback
  }
}

///|
fn configured_bench_warmup_runs() -> Int {
  env_non_negative_int("CODEIQ_BENCH_WARMUP_RUNS", bench_warmup_runs)
}

///|
fn configured_bench_measure_runs() -> Int {
  env_positive_int("CODEIQ_BENCH_MEASURE_RUNS", bench_measure_runs)
}

///|
let bench_timer_modulus_us = 1000000000

///|
fn current_time_us() -> Int {
  let out = @bench_shell.run_command_capture(
    "python3 -c 'import time; print((time.perf_counter_ns() // 1000) % 1000000000)'",
  )
  match out {
    (0, s, _) => @string.parse_int(s.trim()) catch { _ => 0 }
    _ => 0
  }
}

///|
fn elapsed_us(start : Int, end : Int) -> Int {
  if end >= start {
    end - start
  } else {
    bench_timer_modulus_us - start + end
  }
}

///|
fn remove_bench_dist(repo : String) -> Unit {
  @bench_shell.run_command_capture("rm -rf '\{repo}/dist'") |> ignore
}

///|
fn median_sample_us(samples : Array[Int]) -> Int {
  if samples.is_empty() {
    return 0
  }
  let sorted = samples.copy()
  sorted.sort()
  let mid = sorted.length() / 2
  if sorted.length() % 2 == 1 {
    sorted[mid]
  } else {
    (sorted[mid - 1] + sorted[mid]) / 2
  }
}

///|
fn rounded_ms_from_us(value_us : Int) -> Int {
  if value_us <= 0 {
    0
  } else {
    (value_us + 999) / 1000
  }
}

///|
fn run_build_once(repo : String, backend : String) -> Result[Int, @cli.CliError] {
  @sys.set_env_var("CODEIQ_EXTRACTOR_BACKEND", backend)
  let t0 = current_time_us()
  let build_result = @build.run({ repo, })
  let t1 = current_time_us()
  @sys.unset_env_var("CODEIQ_EXTRACTOR_BACKEND")
  guard build_result is Ok(_) else { return Err(build_result.unwrap_err()) }
  Ok(elapsed_us(t0, t1))
}

///|
fn read_bench_text(path : String) -> Result[String, @cli.CliError] {
  let content = @fs.read_file_to_string(path) catch {
    err =>
      return Err(
        bench_error("cannot read bench artifact \{path}: \{err.to_string()}"),
      )
  }
  Ok(content)
}

///|
fn run_extractor_for_bench(
  fixture : BenchFixture,
  backend : String,
) -> Result[BenchRunArtifacts, @cli.CliError] {
  let repo = if fixture.copy_source {
    "/tmp/extractor_bench_\{fixture.name}_\{backend}"
  } else {
    fixture.repo_root
  }
  if fixture.copy_source {
    cleanup_bench_repo(repo, fixture.source_file)
    let ensure_out = ensure_bench_repo(repo)
    guard ensure_out is Ok(_) else { return Err(ensure_out.unwrap_err()) }
    let source_out = write_bench_source_file(repo, fixture)
    guard source_out is Ok(_) else { return Err(source_out.unwrap_err()) }
    init_bench_git_repo(repo)
  } else if !@fs.path_exists(repo) {
    return Err(bench_error("benchmark repo not found: \{repo}"))
  }
  let config_out = write_bench_config(repo, fixture, "none")
  guard config_out is Ok(_) else { return Err(config_out.unwrap_err()) }
  let warmup_runs = configured_bench_warmup_runs()
  let measure_runs = configured_bench_measure_runs()
  for _ in 0..<warmup_runs {
    remove_bench_dist(repo)
    let warmup_out = run_build_once(repo, backend)
    guard warmup_out is Ok(_) else {
      cleanup_fixture_workspace(fixture)
      return Err(
        bench_error(
          "build failed for \{fixture.name}/backend=\{backend}: \{warmup_out.unwrap_err().to_string()}",
        ),
      )
    }
  }
  let wall_samples_us : Array[Int] = []
  for _ in 0..<measure_runs {
    remove_bench_dist(repo)
    let build_out = run_build_once(repo, backend)
    guard build_out is Ok(sample_us) else {
      cleanup_fixture_workspace(fixture)
      return Err(
        bench_error(
          "build failed for \{fixture.name}/backend=\{backend}: \{build_out.unwrap_err().to_string()}",
        ),
      )
    }
    wall_samples_us.push(sample_us)
  }
  let wall_ms = rounded_ms_from_us(median_sample_us(wall_samples_us))
  if wall_samples_us.is_empty() {
    cleanup_fixture_workspace(fixture)
    return Err(
      bench_error(
        "benchmark produced no samples for \{fixture.name}/backend=\{backend}",
      ),
    )
  }
  let manifest_out = read_bench_text("\{repo}/dist/manifest.json")
  guard manifest_out is Ok(manifest) else { return Err(manifest_out.unwrap_err()) }
  let metadata_out = read_bench_text("\{repo}/dist/metadata.json")
  guard metadata_out is Ok(metadata) else { return Err(metadata_out.unwrap_err()) }
  let checksums_out = read_bench_text("\{repo}/dist/checksums.txt")
  guard checksums_out is Ok(checksums) else { return Err(checksums_out.unwrap_err()) }
  let declarations_out = read_bench_text("\{repo}/dist/declarations.ndjson")
  guard declarations_out is Ok(declarations) else {
    return Err(declarations_out.unwrap_err())
  }
  let symbols_out = read_bench_text("\{repo}/dist/symbols.ndjson")
  guard symbols_out is Ok(symbols) else { return Err(symbols_out.unwrap_err()) }
  let components_out = read_bench_text("\{repo}/dist/software-components.ndjson")
  guard components_out is Ok(components) else { return Err(components_out.unwrap_err()) }
  let sbom_out = read_bench_text("\{repo}/dist/sbom.spdx.json")
  guard sbom_out is Ok(sbom) else { return Err(sbom_out.unwrap_err()) }
  let metadata_json = try? @json.parse(metadata)
  let mode = match metadata_json {
    Ok(Object(root)) =>
      match root.get("extractor") {
        Some(Object(extractor)) =>
          match extractor.get("mode") {
            Some(String(value)) => value
            _ => "unknown"
          }
        _ => "unknown"
      }
    _ => "unknown"
  }
  Ok({
    backend,
    mode,
    wall_ms,
    manifest,
    metadata,
    checksums,
    declarations,
    symbols,
    components,
    sbom,
  })
}

///|
fn lsif_probe(
  fixture : BenchFixture,
  lang : String,
) -> @build.LsifReport {
  let lsif_path = fixture.lsif_path
  if !@fs.path_exists(lsif_path) {
    let tool = if lang == "go" { "lsif-go" } else { "rust-analyzer" }
    return @build.make_lsif_report(
      false,
      "LSIF dump not found at \{lsif_path}; run \{tool} to generate",
      0,
      0,
    )
  }
  let content = @fs.read_file_to_string(lsif_path) catch {
    _ => return @build.make_lsif_report(false, "cannot read LSIF dump", 0, 0)
  }
  let raw = @utf8.encode(content).length()
  let gz = @build.gzip_size_of(content)
  @build.make_lsif_report(true, "", raw, gz)
}

///|
fn artifact_diff_count(
  baseline : BenchRunArtifacts,
  validated : BenchRunArtifacts,
) -> Int {
  let mut diff_count = 0
  if @build.normalize_bench_snapshot_text(baseline.manifest) !=
    @build.normalize_bench_snapshot_text(validated.manifest) {
    diff_count = diff_count + 1
  }
  if @build.normalize_bench_snapshot_text(baseline.metadata) !=
    @build.normalize_bench_snapshot_text(validated.metadata) {
    diff_count = diff_count + 1
  }
  if @build.normalize_bench_checksums_text(baseline.checksums) !=
    @build.normalize_bench_checksums_text(validated.checksums) {
    diff_count = diff_count + 1
  }
  diff_count = diff_count + @build.compare_ndjson_lines(
    baseline.declarations,
    validated.declarations,
  )
  diff_count = diff_count + @build.compare_ndjson_lines(
    baseline.symbols,
    validated.symbols,
  )
  if baseline.components != validated.components {
    diff_count = diff_count + 1
  }
  if baseline.sbom != validated.sbom {
    diff_count = diff_count + 1
  }
  // bundle_sha256 is not compared: bundles embed manifest.json which contains
  // a non-deterministic git commit hash, making byte-level bundle equality
  // impossible across two independent build invocations. All semantic content
  // is already verified by the individual artifact comparisons above.
  diff_count
}

///|
fn bundle_sizes(run : BenchRunArtifacts) -> (Int, Int) {
  let combined = run.manifest + run.declarations + run.symbols
  let raw = @utf8.encode(combined).length()
  let gz = @build.gzip_size_of(combined)
  (raw, gz)
}

///|
fn make_fixture_report(
  fixture : BenchFixture,
  run : BenchRunArtifacts,
  lsif : @build.LsifReport,
  diff_count : Int,
) -> @build.BenchReport {
  let (raw, gz) = bundle_sizes(run)
  let decl_count = @build.count_ndjson_lines(run.declarations)
  let sym_count = @build.count_ndjson_lines(run.symbols)
  let bpd = if decl_count > 0 { raw / decl_count } else { 0 }
  @build.make_bench_report(
    fixture.label,
    run.backend,
    run.mode,
    diff_count == 0,
    @build.make_bench_metrics(
      run.wall_ms,
      0,
      raw,
      gz,
      decl_count,
      sym_count,
      bpd,
      diff_count,
    ),
    lsif,
  )
}

///|
fn run_bench_fixture(
  fixture : BenchFixture,
) -> Result[Array[@build.BenchReport], @cli.CliError] {
  let lang = if fixture.profile == "go-module" { "go" } else { "rust" }
  let lsif = lsif_probe(fixture, lang)
  let native_out = run_extractor_for_bench(fixture, "native")
  guard native_out is Ok(native_run) else {
    cleanup_fixture_workspace(fixture)
    return Err(native_out.unwrap_err())
  }
  let lsp_out = run_extractor_for_bench(fixture, "lsp")
  guard lsp_out is Ok(lsp_run) else {
    cleanup_fixture_workspace(fixture)
    return Err(lsp_out.unwrap_err())
  }
  let diff_count = artifact_diff_count(native_run, lsp_run)
  let native_report = make_fixture_report(fixture, native_run, lsif, diff_count)
  let lsp_report = make_fixture_report(fixture, lsp_run, lsif, diff_count)
  cleanup_fixture_workspace(fixture)
  if diff_count != 0 {
    return Err(
      bench_error(
        "parity failed for \{fixture.name}: backend=native vs backend=lsp snapshotDiffCount=\{diff_count}",
      ),
    )
  }
  Ok([native_report, lsp_report])
}

///|
fn write_bench_summary(
  fixture : BenchFixture,
  reports : Array[@build.BenchReport],
) -> Unit {
  let bench_dir = "\{fixture.summary_root}/bench"
  if !@fs.path_exists(bench_dir) {
    @fs.create_dir(bench_dir) catch { _ => () }
  }
  let entries = reports.map(fn(r) { @build.bench_report_json(r) })
  let parity = if reports.length() > 0 { reports[0].parity } else { false }
  let summary : Json = {
    "schemaVersion": "ciq-bench/v1",
    "fixture": fixture.label,
    "parityPassed": parity,
    "sampling": {
      "warmupRuns": configured_bench_warmup_runs(),
      "measureRuns": configured_bench_measure_runs(),
    },
    "runs": Json::array(entries),
  }
  @fs.write_string_to_file(
    "\{bench_dir}/summary.json",
    summary.stringify(indent=2),
  ) catch {
    _ => ()
  }
}

///|
fn format_report_table(
  native_report : @build.BenchReport,
  lsp_report : @build.BenchReport,
) -> String {
  let n = native_report.metrics
  let l = lsp_report.metrics
  let speedup = if n.wall_ms > 0 {
    let ratio = l.wall_ms * 100 / n.wall_ms
    "\{ratio / 100}.\{ratio % 100}x"
  } else {
    "n/a"
  }
  [
    "  fixture:          \{native_report.fixture}",
    "  backend           native          lsp",
    "  mode              \{native_report.mode}   \{lsp_report.mode}",
    "  wall_ms           \{n.wall_ms}              \{l.wall_ms}     lsp/native: \{speedup}",
    "  bundle_raw        \{n.bundle_bytes_raw}          \{l.bundle_bytes_raw}",
    "  bundle_gz         \{n.bundle_bytes_gzip}           \{l.bundle_bytes_gzip}",
    "  declarations      \{n.declarations}             \{l.declarations}",
    "  snapshot_diffs    \{n.snapshot_diff_count}             \{l.snapshot_diff_count}",
    "  parity            \{native_report.parity}",
    "  lsif_supported    \{native_report.lsif.supported}",
  ].join("\\n")
}

///|
test "extractor benchmark: native and lsp builds stay in parity" {
  let all_reports : Array[@build.BenchReport] = []
  let lines : Array[String] = ["=== extractor benchmark report ===", ""]
  let failures : Array[String] = []
  for fixture in active_bench_fixtures() {
    lines.push("--- \{fixture.name} ---")
    let reports_out = run_bench_fixture(fixture)
    match reports_out {
      Ok(reports) => {
        write_bench_summary(fixture, reports)
        for report in reports {
          all_reports.push(report)
        }
        lines.push(format_report_table(reports[0], reports[1]))
      }
      Err(e) => {
        let message = e.to_string()
        failures.push(message)
        lines.push("  ERROR: \{message}")
      }
    }
    lines.push("")
  }
  let combined : Json = {
    "schemaVersion": "ciq-bench/v1",
    "runs": Json::array(all_reports.map(fn(r) { @build.bench_report_json(r) })),
  }
  @fs.write_string_to_file(
    "/tmp/extractor_bench_report.json",
    combined.stringify(indent=2),
  ) catch {
    _ => ()
  }
  println(lines.join("\\n"))
  if !failures.is_empty() {
    fail(failures.join("; "))
  }
}
