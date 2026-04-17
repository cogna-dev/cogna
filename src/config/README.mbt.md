# config package

Project configuration schema, defaults, loading, and validation for Cogna.

This package intentionally contains:

- config data types and defaults
- `ciq-config/v1` and `ciq-config/v2` schema definitions
- config discovery and path resolution
- validation of loaded project config

Other packages should depend on resolved config data rather than reimplementing config parsing.

## Example

```mbt check
///|
test "config defaults target the local registry cache" {
  inspect(default_config().registry.store_dir, content=".cogna/cache/registry")
}
```
