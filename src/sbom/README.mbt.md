# sbom package

SBOM and dependency-evidence generation for CodeIQ bundles.

This package intentionally contains the SBOM vertical:

- software component records and SPDX emission
- dependency collection across npm, Cargo, and Go inputs
- dependency snapshot hashing for bundle provenance
- exported SBOM artifacts used by `build`

`snapshot` here means dependency evidence snapshotting, not declaration snapshot baselines.

## Example

```mbt check
///|
test "sbom component signatures include version when present" {
  let component : SoftwareComponent = {
    id: "pkg:npm/react@19.0.0",
    name: "react",
    version: Some("19.0.0"),
    purl: Some("pkg:npm/react@19.0.0"),
    component_type: "library",
    scope: "dependency",
    evidence_path: "package.json",
    hashes: [],
  }
  inspect(component_signature(component), content="library react@19.0.0")
}
```
