# registry library

Reusable registry path, routing, and remote-client helpers for Cogna packages.

This package intentionally contains **shared** capabilities only:

- Local store path helpers (`local_store_root`, `local_store_index_dir`, `local_store_bundles_dir`)
- HTTP path and route helpers (`upload_path`, `versions_path`, `bundle_detail_path`, `route`)
- URL and header helpers (`url_encode`, `url_decode`, `header_value`)
- Remote registry operations (`download_remote_by_purl`, `upload_remote`)

Command-specific polling, process control, and server wiring should stay in the owning command or vertical adapter package.

## Example

```mbt check
///|
test "registry round-trips purl path helpers" {
  inspect(upload_path(), content="/api/v1/bundles")
  let encoded = url_encode("pkg:generic/acme/demo@0.1.0")
  let decoded = url_decode(encoded)
  guard decoded is Ok(purl) else { fail("url decode should succeed") }
  inspect(purl, content="pkg:generic/acme/demo@0.1.0")
  let route_out = route("GET", resolve_path(purl))
  guard route_out is ResolveByPurl(value) else {
    fail("expected resolve route")
  }
  inspect(value, content="pkg:generic/acme/demo@0.1.0")
}
```
