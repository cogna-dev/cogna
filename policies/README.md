# Cogna Policy Rules

This directory contains the built-in OPA Rego policies for `cogna check`.

## Structure

```
policies/
  compat.rego   # All built-in compatibility rules (package cogna.compat)
```

## Rule Metadata Format

Each `deny` rule embeds structured metadata as JSON fields in the `out` object:

```rego
deny contains out if {
  change := input.changes[_]           # or input.componentChanges[_]
  has_finding(change, "<finding_code>") # or component_upgrade(change, "<kind>")
  out := {
    "rule_id": "<family>.<rule>",      # e.g. "compat.go.signature-changed"
    "level":   "error|warning|note",
    "message": "<human-readable summary>",
    "path":    change.path,
    "docs":    "https://cogna.xaclabs.dev/docs/policies/generated/<family>/<slug>"
  }
}
```

Python tooling (e.g. `scripts/gendoc.py`) parses this file to extract rule metadata and generate MDX documentation pages.

## OPA Entrypoint

`data.cogna.compat.deny`

## Adding Custom Rules

Add new `.rego` files to this directory. Custom rules must use `package cogna.compat` and follow the same metadata format so `gendoc.py` can discover them.

## Helper Functions

| Function | Description |
|---|---|
| `has_finding(change, code)` | Matches a semantic diff finding by code |
| `component_upgrade(change, kind)` | Matches a component diff by upgrade kind |
