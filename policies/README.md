# Cogna Policy Rules

This directory contains the built-in OPA Rego policies for `cogna check`.

## Structure

```text
policies/
  compat.rego   # all built-in compatibility rules (package cogna.compat)
```

## OPA Entrypoint

`data.cogna.compat.deny`

## Rule metadata contract

Every `deny` output object must include:

- `rule_id`: canonical rule id (for example `compat.go.signature-changed`)
- `level`: `error` | `warning` | `note`
- `message`: human-readable summary
- `path`: source path in diff payload
- `docs`: canonical policy documentation URL

Canonical docs URL pattern:

`https://cogna.xaclabs.dev/docs/policies#rule-<rule_id_with_dots_replaced_by_dashes>`

Example for `compat.go.signature-changed`:

`https://cogna.xaclabs.dev/docs/policies#rule-compat-go-signature-changed`

## Built-in rule index

### core

- <a id="rule-compat-core-removed-declaration"></a>`compat.core.removed-declaration` — Public declaration was removed and callers will break.
- <a id="rule-compat-core-new-declaration"></a>`compat.core.new-declaration` — Public declaration was added.
- <a id="rule-compat-core-deprecated-declaration"></a>`compat.core.deprecated-declaration` — Public declaration became deprecated.

### go

- <a id="rule-compat-go-pointer-receiver-changed"></a>`compat.go.pointer-receiver-changed` — Go pointer receiver compatibility changed.
- <a id="rule-compat-go-receiver-changed"></a>`compat.go.receiver-changed` — Go receiver type changed.
- <a id="rule-compat-go-method-set-shrunk"></a>`compat.go.method-set-shrunk` — Go method set shrank.
- <a id="rule-compat-go-method-set-expanded"></a>`compat.go.method-set-expanded` — Go method set expanded and needs review.
- <a id="rule-compat-go-signature-changed"></a>`compat.go.signature-changed` — Go public signature changed.

### rust

- <a id="rule-compat-rust-became-unsafe"></a>`compat.rust.became-unsafe` — Rust public item became unsafe.
- <a id="rule-compat-rust-extern-abi-added"></a>`compat.rust.extern-abi-added` — Rust extern ABI was added.
- <a id="rule-compat-rust-extern-abi-changed"></a>`compat.rust.extern-abi-changed` — Rust extern ABI changed.
- <a id="rule-compat-rust-where-clause-changed"></a>`compat.rust.where-clause-changed` — Rust where-clause changed.
- <a id="rule-compat-rust-signature-changed"></a>`compat.rust.signature-changed` — Rust public signature changed.

### terraform

- <a id="rule-compat-terraform-provider-ref-changed"></a>`compat.terraform.provider-ref-changed` — Terraform provider reference changed.
- <a id="rule-compat-terraform-prevent-destroy-added"></a>`compat.terraform.prevent-destroy-added` — Terraform prevent_destroy was added.
- <a id="rule-compat-terraform-create-before-destroy-added"></a>`compat.terraform.create-before-destroy-added` — Terraform create_before_destroy was added.
- <a id="rule-compat-terraform-ignore-changes-expanded"></a>`compat.terraform.ignore-changes-expanded` — Terraform ignore_changes expanded.
- <a id="rule-compat-terraform-lifecycle-changed"></a>`compat.terraform.lifecycle-changed` — Terraform lifecycle metadata changed.
- <a id="rule-compat-terraform-input-became-required"></a>`compat.terraform.input-became-required` — Terraform input became required and callers must update configuration.
- <a id="rule-compat-terraform-output-removed"></a>`compat.terraform.output-removed` — Terraform output was removed and downstream references can break.

### openapi

- <a id="rule-compat-openapi-http-method-changed"></a>`compat.openapi.http-method-changed` — OpenAPI HTTP method changed.
- <a id="rule-compat-openapi-became-required"></a>`compat.openapi.became-required` — OpenAPI field or parameter became required.
- <a id="rule-compat-openapi-status-codes-added"></a>`compat.openapi.status-codes-added` — OpenAPI status codes were added.
- <a id="rule-compat-openapi-media-types-added"></a>`compat.openapi.media-types-added` — OpenAPI media types were added.
- <a id="rule-compat-openapi-operation-changed"></a>`compat.openapi.operation-changed` — OpenAPI operation changed.
- <a id="rule-compat-openapi-response-status-removed"></a>`compat.openapi.response-status-removed` — OpenAPI response status code was removed.
- <a id="rule-compat-openapi-response-schema-narrowed"></a>`compat.openapi.response-schema-narrowed` — OpenAPI response schema narrowed and clients may fail to parse it.

### component

- <a id="rule-compat-component-version-upgrade"></a>`compat.component.version-upgrade` — Software component version changed.
- <a id="rule-compat-component-metadata-changed"></a>`compat.component.metadata-changed` — Software component metadata changed.

## Adding custom rules

Add new `.rego` files to this directory and keep package `cogna.compat`.
For custom rules, follow the same metadata contract and set `docs` to a stable URL.

## Helper functions in `compat.rego`

| Function | Description |
|---|---|
| `has_finding(change, code)` | Matches a semantic diff finding by code |
| `component_upgrade(change, kind)` | Matches a component diff by upgrade kind |
