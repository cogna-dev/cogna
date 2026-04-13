///| BenchMetrics holds all measured metrics for one extractor run.
pub(all) struct BenchMetrics {
  wall_ms : Int
  peak_rss_mb : Int
  bundle_bytes_raw : Int
  bundle_bytes_gzip : Int
  declarations : Int
  symbols : Int
  bytes_per_declaration : Int
  snapshot_diff_count : Int
} derive(Eq)

///|
pub impl Show for BenchMetrics with output(self, logger) {
  logger.write_string("{wall_ms: ")
  logger.write_object(self.wall_ms)
  logger.write_string(", peak_rss_mb: ")
  logger.write_object(self.peak_rss_mb)
  logger.write_string(", bundle_bytes_raw: ")
  logger.write_object(self.bundle_bytes_raw)
  logger.write_string(", bundle_bytes_gzip: ")
  logger.write_object(self.bundle_bytes_gzip)
  logger.write_string(", declarations: ")
  logger.write_object(self.declarations)
  logger.write_string(", symbols: ")
  logger.write_object(self.symbols)
  logger.write_string(", bytes_per_declaration: ")
  logger.write_object(self.bytes_per_declaration)
  logger.write_string(", snapshot_diff_count: ")
  logger.write_object(self.snapshot_diff_count)
  logger.write_char('}')
}

///| BenchReport is the top-level JSON report for one backend run.
pub(all) struct BenchReport {
  fixture : String
  backend : String
  mode : String
  parity : Bool
  metrics : BenchMetrics
  lsif : LsifReport
} derive(Eq)

///|
pub impl Show for BenchReport with output(self, logger) {
  logger.write_string("{fixture: ")
  logger.write_object(self.fixture)
  logger.write_string(", backend: ")
  logger.write_object(self.backend)
  logger.write_string(", mode: ")
  logger.write_object(self.mode)
  logger.write_string(", parity: ")
  logger.write_object(self.parity)
  logger.write_string(", metrics: ")
  logger.write_object(self.metrics)
  logger.write_string(", lsif: ")
  logger.write_object(self.lsif)
  logger.write_char('}')
}

///| LsifReport records LSIF dump size info for comparison, or marks it unsupported.
pub(all) struct LsifReport {
  supported : Bool
  reason : String
  bytes_raw : Int
  bytes_gzip : Int
} derive(Eq)

///|
pub impl Show for LsifReport with output(self, logger) {
  logger.write_string("{supported: ")
  logger.write_object(self.supported)
  logger.write_string(", reason: ")
  logger.write_object(self.reason)
  logger.write_string(", bytes_raw: ")
  logger.write_object(self.bytes_raw)
  logger.write_string(", bytes_gzip: ")
  logger.write_object(self.bytes_gzip)
  logger.write_char('}')
}

///| make_bench_metrics constructs a BenchMetrics value.
pub fn make_bench_metrics(
  wall_ms : Int,
  peak_rss_mb : Int,
  bundle_bytes_raw : Int,
  bundle_bytes_gzip : Int,
  declarations : Int,
  symbols : Int,
  bytes_per_declaration : Int,
  snapshot_diff_count : Int,
) -> BenchMetrics {
  {
    wall_ms,
    peak_rss_mb,
    bundle_bytes_raw,
    bundle_bytes_gzip,
    declarations,
    symbols,
    bytes_per_declaration,
    snapshot_diff_count,
  }
}

///| make_lsif_report constructs an LsifReport value.
pub fn make_lsif_report(
  supported : Bool,
  reason : String,
  bytes_raw : Int,
  bytes_gzip : Int,
) -> LsifReport {
  { supported, reason, bytes_raw, bytes_gzip }
}

///| make_bench_report constructs a BenchReport value.
pub fn make_bench_report(
  fixture : String,
  backend : String,
  mode : String,
  parity : Bool,
  metrics : BenchMetrics,
  lsif : LsifReport,
) -> BenchReport {
  { fixture, backend, mode, parity, metrics, lsif }
}

///| bench_metrics_json serialises BenchMetrics to a Json object.
pub fn bench_metrics_json(m : BenchMetrics) -> Json {
  {
    "wallMs": m.wall_ms,
    "cpuMs": m.wall_ms,
    "peakRssMb": m.peak_rss_mb,
    "bundleBytesRaw": m.bundle_bytes_raw,
    "bundleBytesGzip": m.bundle_bytes_gzip,
    "declarations": m.declarations,
    "symbols": m.symbols,
    "bytesPerDeclaration": m.bytes_per_declaration,
    "snapshotDiffCount": m.snapshot_diff_count,
  }
}

///| lsif_report_json serialises LsifReport to a Json object.
pub fn lsif_report_json(r : LsifReport) -> Json {
  let base : Map[String, Json] = {
    "supported": r.supported,
    "reason": r.reason,
    "bytesRaw": r.bytes_raw,
    "bytesGzip": r.bytes_gzip,
  }
  Json::object(base)
}

///| bench_report_json serialises BenchReport to a Json object.
pub fn bench_report_json(r : BenchReport) -> Json {
  {
    "fixture": r.fixture,
    "backend": r.backend,
    "mode": r.mode,
    "parity": r.parity,
    "metrics": bench_metrics_json(r.metrics),
    "lsif": lsif_report_json(r.lsif),
  }
}

///| normalize_bench_snapshot_text normalizes manifest/metadata snapshots so
/// benchmark parity compares semantic output rather than runtime noise.
pub fn normalize_bench_snapshot_text(content : String) -> String {
  let parsed = try? @json.parse(content)
  guard parsed is Ok(Object(root)) else { return content }

  if root.get("schemaVersion") is Some(String("ciq-metadata/v1")) {
    let extractor_obj : Map[String, Json] = match root.get("extractor") {
      Some(Object(e)) => e
      _ => {}
    }
    return ({
      "schemaVersion": root.get("schemaVersion").unwrap_or("ciq-metadata/v1"),
      "profile": root.get("profile").unwrap_or("unknown"),
      "inputPatterns": root.get("inputPatterns").unwrap_or([]),
      "build": root.get("build").unwrap_or({}),
      "extractor": {
        "role": extractor_obj.get("role").unwrap_or("canonical"),
        "mode": "<normalized>",
        "backend": extractor_obj.get("backend").unwrap_or("canonical"),
        "server": extractor_obj.get("server").unwrap_or("canonical"),
        "version": extractor_obj.get("version").unwrap_or("canonical-v1"),
        "fallback": extractor_obj.get("fallback").unwrap_or(false),
        "timingMs": extractor_obj.get("timingMs").unwrap_or({}),
        "stats": extractor_obj.get("stats").unwrap_or({}),
      },
    } : Json).stringify(indent=2)
  }

  if root.get("schemaVersion") is Some(String("ciq-bundle/v1")) {
    let normalized_source = match root.get("source") {
      Some(Object(source)) => {
        let object : Map[String, Json] = {
          "repo": source.get("repo").unwrap_or(""),
          "ref": source.get("ref").unwrap_or(""),
          "commit": "<normalized>",
        }
        Json::object(object)
      }
      _ => Json::object({})
    }
    return ({
      "schemaVersion": root.get("schemaVersion").unwrap_or("ciq-bundle/v1"),
      "purl": root.get("purl").unwrap_or(""),
      "profile": root.get("profile").unwrap_or(""),
      "declarationSchema": root.get("declarationSchema").unwrap_or({}),
      "source": normalized_source,
      "artifacts": root.get("artifacts").unwrap_or([]),
    } : Json).stringify(indent=2)
  }

  content
}

///| normalize_bench_checksums_text masks checksum churn caused by
/// runtime timestamps and commit-hash noise while preserving semantic artifact parity.
pub fn normalize_bench_checksums_text(content : String) -> String {
  let lines = content.split("\n").to_array()
  let normalized : Array[String] = []
  for i in 0..<lines.length() {
    let line = lines[i]
    if line.has_prefix("metadata.json  ") {
      normalized.push("metadata.json  <normalized>")
    } else if line.has_prefix("manifest.json  ") {
      normalized.push("manifest.json  <normalized>")
    } else {
      normalized.push(line.to_string())
    }
  }
  normalized.join("\n")
}

///| bundle_file_sha256 returns a stable hash for a bundle file, or an empty
/// marker when the artifact is missing.
pub fn bundle_file_sha256(path : String) -> String {
  let bytes = @fs.read_file_to_bytes(path) catch {
    _ => return "<missing>"
  }
  @sha256.sha256_hexdigest(bytes)
}

///| count_ndjson_lines counts non-empty lines in an NDJSON string.
pub fn count_ndjson_lines(text : String) -> Int {
  let mut count = 0
  for line in text.split("\n") {
    let t = trim_spaces(line.to_string())
    if t != "" {
      count = count + 1
    }
  }
  count
}

///| measure_file_size returns the byte length of a file, or 0 if missing.
pub fn measure_file_size(path : String) -> Int {
  let content = @fs.read_file_to_string(path) catch {
    _ => return 0
  }
  @utf8.encode(content).length()
}

///| gzip_size_of returns the gzip-compressed byte size of a string.
pub fn gzip_size_of(text : String) -> Int {
  let raw = @utf8.encode(text)
  let buf = @gio.Buffer::new()
  let writer = @gzip.Writer::new(buf)
  let (_, write_out) = writer.write(@gio.Slice::new(raw.to_array()))
  if write_out is Some(_) {
    return raw.length()
  }
  let close_out = writer.close()
  if close_out is Some(_) {
    return raw.length()
  }
  buf.to_bytes().length()
}

///| compare_ndjson_lines returns the number of lines that differ between two
/// NDJSON texts (a line-by-line diff count, ignoring blank lines).
pub fn compare_ndjson_lines(a : String, b : String) -> Int {
  let lines_a = a
    .split("\n")
    .map(fn(l) { trim_spaces(l.to_string()) })
    .filter(fn(l) { l != "" })
    .to_array()
  let lines_b = b
    .split("\n")
    .map(fn(l) { trim_spaces(l.to_string()) })
    .filter(fn(l) { l != "" })
    .to_array()
  let len = if lines_a.length() > lines_b.length() {
    lines_a.length()
  } else {
    lines_b.length()
  }
  let mut diffs = 0
  for i in 0..<len {
    let la = if i < lines_a.length() { lines_a[i] } else { "" }
    let lb = if i < lines_b.length() { lines_b[i] } else { "" }
    if la != lb {
      diffs = diffs + 1
    }
  }
  diffs
}
