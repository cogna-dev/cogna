#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
CASES_DIR="$ROOT_DIR/e2e/changes"
WORK_DIR="$ROOT_DIR/.tmp/changes-e2e"
UPDATE_MODE="false"

CASES=(go rust terraform openapi)
SELECTED_CASES=()

usage() {
  cat <<'USAGE'
Usage: scripts/ci/run-changes-e2e.sh [--update] [--case <name>]...

Options:
  --update       Regenerate expected snapshots under e2e/changes/*/expected
  --case <name>  Run only one case (go|rust|terraform|openapi). Repeatable.
USAGE
}

require_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "missing required command: $name" >&2
    exit 1
  fi
}

contains_case() {
  local value="$1"
  shift
  for item in "$@"; do
    if [[ "$item" == "$value" ]]; then
      return 0
    fi
  done
  return 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --update)
        UPDATE_MODE="true"
        shift
        ;;
      --case)
        if [[ $# -lt 2 ]]; then
          echo "--case requires a value" >&2
          exit 1
        fi
        SELECTED_CASES+=("$2")
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

write_case_config() {
  local run_root="$1"
  cat >"$run_root/cogna.yaml" <<'EOF'
schemaVersion: ciq-config/v2
profile: openapi-spec
purl: pkg:openapi/e2e/changes@0.0.0
source:
  repo: https://github.com/example/changes-e2e
  ref: main
inputs:
  include:
    - "**/*"
checks:
  format: sarif
  policy: ./.cogna/policies
diff:
  includeTestChanges: false
EOF
}

normalize_diff() {
  local src="$1"
  local out="$2"
  jq -S . "$src" > "$out"
}

normalize_sarif() {
  local src="$1"
  local out="$2"
  jq -S '
    .runs |= map(
      .tool.driver.rules |= (if type == "array" then sort_by(.id // "") else . end)
      | .results |= (if type == "array" then sort_by(.ruleId // "", (.locations[0].physicalLocation.artifactLocation.uri // ""), .message.text // "") else . end)
    )
  ' "$src" > "$out"
}

run_cli() {
  local workdir="$1"
  shift
  (
    cd "$workdir"
    moon run --target native --manifest-path "$ROOT_DIR/moon.mod.json" src/cmd/main -- "$@"
  )
}

build_mock_opa_eval() {
  local diff_file="$1"
  local out_file="$2"
  jq '{
    result: [
      {
        expressions: [
          {
            value: (
              [
                (.changes[]? as $change
                  | $change.semanticDiff.findings[]?.code? as $code
                  | (if $code == "removed-declaration" then {"rule_id":"compat.core.removed-declaration","level":"error","message":"Public declaration was removed and callers will break.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-core-removed-declaration"}
                    elif $code == "new-declaration" then {"rule_id":"compat.core.new-declaration","level":"note","message":"Public declaration was added.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-core-new-declaration"}
                    elif $code == "deprecated-declaration" then {"rule_id":"compat.core.deprecated-declaration","level":"note","message":"Public declaration became deprecated.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-core-deprecated-declaration"}
                    elif $code == "go-pointer-receiver-changed" then {"rule_id":"compat.go.pointer-receiver-changed","level":"error","message":"Go pointer receiver compatibility changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-go-pointer-receiver-changed"}
                    elif $code == "go-receiver-changed" then {"rule_id":"compat.go.receiver-changed","level":"error","message":"Go receiver type changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-go-receiver-changed"}
                    elif $code == "go-method-set-shrunk" then {"rule_id":"compat.go.method-set-shrunk","level":"error","message":"Go method set shrank.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-go-method-set-shrunk"}
                    elif $code == "go-method-set-expanded" then {"rule_id":"compat.go.method-set-expanded","level":"warning","message":"Go method set expanded and needs review.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-go-method-set-expanded"}
                    elif $code == "go-signature-changed" then {"rule_id":"compat.go.signature-changed","level":"warning","message":"Go public signature changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-go-signature-changed"}
                    elif $code == "rust-became-unsafe" then {"rule_id":"compat.rust.became-unsafe","level":"error","message":"Rust public item became unsafe.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-became-unsafe"}
                    elif $code == "rust-extern-abi-added" then {"rule_id":"compat.rust.extern-abi-added","level":"error","message":"Rust extern ABI was added.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-extern-abi-added"}
                    elif $code == "rust-extern-abi-changed" then {"rule_id":"compat.rust.extern-abi-changed","level":"error","message":"Rust extern ABI changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-extern-abi-changed"}
                    elif $code == "rust-where-clause-changed" then {"rule_id":"compat.rust.where-clause-changed","level":"warning","message":"Rust where-clause changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-where-clause-changed"}
                    elif $code == "rust-signature-changed" then {"rule_id":"compat.rust.signature-changed","level":"warning","message":"Rust public signature changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-rust-signature-changed"}
                    elif $code == "terraform-provider-ref-changed" then {"rule_id":"compat.terraform.provider-ref-changed","level":"error","message":"Terraform provider reference changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-provider-ref-changed"}
                    elif $code == "terraform-prevent-destroy-added" then {"rule_id":"compat.terraform.prevent-destroy-added","level":"warning","message":"Terraform prevent_destroy was added.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-prevent-destroy-added"}
                    elif $code == "terraform-create-before-destroy-added" then {"rule_id":"compat.terraform.create-before-destroy-added","level":"warning","message":"Terraform create_before_destroy was added.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-create-before-destroy-added"}
                    elif $code == "terraform-ignore-changes-expanded" then {"rule_id":"compat.terraform.ignore-changes-expanded","level":"note","message":"Terraform ignore_changes expanded.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-ignore-changes-expanded"}
                    elif $code == "terraform-lifecycle-changed" then {"rule_id":"compat.terraform.lifecycle-changed","level":"warning","message":"Terraform lifecycle metadata changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-lifecycle-changed"}
                    elif $code == "terraform-input-became-required" then {"rule_id":"compat.terraform.input-became-required","level":"error","message":"Terraform input became required and callers must update configuration.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-input-became-required"}
                    elif $code == "terraform-output-removed" then {"rule_id":"compat.terraform.output-removed","level":"error","message":"Terraform output was removed and downstream references can break.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-terraform-output-removed"}
                    elif $code == "openapi-http-method-changed" then {"rule_id":"compat.openapi.http-method-changed","level":"error","message":"OpenAPI HTTP method changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-http-method-changed"}
                    elif $code == "openapi-became-required" then {"rule_id":"compat.openapi.became-required","level":"error","message":"OpenAPI field or parameter became required.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-became-required"}
                    elif $code == "openapi-status-codes-added" then {"rule_id":"compat.openapi.status-codes-added","level":"warning","message":"OpenAPI status codes were added.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-status-codes-added"}
                    elif $code == "openapi-media-types-added" then {"rule_id":"compat.openapi.media-types-added","level":"note","message":"OpenAPI media types were added.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-media-types-added"}
                    elif $code == "openapi-operation-changed" then {"rule_id":"compat.openapi.operation-changed","level":"warning","message":"OpenAPI operation changed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-operation-changed"}
                    elif $code == "openapi-response-status-removed" then {"rule_id":"compat.openapi.response-status-removed","level":"error","message":"OpenAPI response status code was removed.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-response-status-removed"}
                    elif $code == "openapi-response-schema-narrowed" then {"rule_id":"compat.openapi.response-schema-narrowed","level":"error","message":"OpenAPI response schema narrowed and clients may fail to parse it.","docs":"https://cogna.xaclabs.dev/docs/policies#rule-compat-openapi-response-schema-narrowed"}
                    else empty
                    end)
                  | . + {path: ($change.path // "unknown")}),
                (.changes[]?
                  | select(.componentDiff.upgradeKind == "version-upgrade")
                  | {
                      "rule_id": "compat.component.version-upgrade",
                      "level": "warning",
                      "message": "Software component version changed.",
                      "path": (.path // "unknown"),
                      "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-component-version-upgrade"
                    }),
                (.changes[]?
                  | select(.componentDiff.upgradeKind == "metadata-change")
                  | {
                      "rule_id": "compat.component.metadata-changed",
                      "level": "warning",
                      "message": "Software component metadata changed.",
                      "path": (.path // "unknown"),
                      "docs": "https://cogna.xaclabs.dev/docs/policies#rule-compat-component-metadata-changed"
                    })
              ]
            )
          }
        ]
      }
    ]
  }' "$diff_file" > "$out_file"
}

prepare_case() {
  local case_name="$1"
  local case_root="$CASES_DIR/$case_name"
  local run_root="$WORK_DIR/$case_name"

  rm -rf "$run_root"
  mkdir -p "$run_root/dist/base" "$run_root/dist/target" "$run_root/.cogna/policies"

  cp "$ROOT_DIR/policies/compat.rego" "$run_root/.cogna/policies/compat.rego"
  cp "$case_root/old/manifest.json" "$run_root/dist/base/manifest.json"
  cp "$case_root/old/declarations.ndjson" "$run_root/dist/base/declarations.ndjson"
  cp "$case_root/new/manifest.json" "$run_root/dist/target/manifest.json"
  cp "$case_root/new/declarations.ndjson" "$run_root/dist/target/declarations.ndjson"

  write_case_config "$run_root"
}

compare_or_update() {
  local expected="$1"
  local actual="$2"
  if [[ "$UPDATE_MODE" == "true" ]]; then
    cp "$actual" "$expected"
    return 0
  fi

  if [[ ! -f "$expected" ]]; then
    echo "missing expected snapshot: $expected" >&2
    echo "run with --update to create snapshots" >&2
    exit 1
  fi

  if ! diff -u "$expected" "$actual"; then
    echo "snapshot mismatch: $expected" >&2
    exit 1
  fi
}

run_case() {
  local case_name="$1"
  local case_root="$CASES_DIR/$case_name"
  local run_root="$WORK_DIR/$case_name"

  echo "[changes-e2e] case=$case_name"

  prepare_case "$case_name"

  run_cli "$ROOT_DIR" diff --repo "$run_root" --include-test-changes false
  local opa_eval_override="$run_root/dist/opa-eval.json"
  build_mock_opa_eval "$run_root/dist/diff.json" "$opa_eval_override"
  (
    cd "$run_root"
    COGNA_OPA_EVAL_JSON="$(cat "$opa_eval_override")" \
      moon run --target native --manifest-path "$ROOT_DIR/moon.mod.json" src/cmd/main -- check
  )

  local norm_diff="$run_root/dist/diff.normalized.json"
  local norm_sarif="$run_root/dist/check.sarif.normalized.json"
  normalize_diff "$run_root/dist/diff.json" "$norm_diff"
  normalize_sarif "$run_root/dist/check.sarif.json" "$norm_sarif"

  mkdir -p "$case_root/expected/diff" "$case_root/expected/sarif"
  compare_or_update "$case_root/expected/diff/diff.json" "$norm_diff"
  compare_or_update "$case_root/expected/sarif/check.sarif.json" "$norm_sarif"
}

main() {
  require_cmd moon
  require_cmd jq

  parse_args "$@"

  if [[ ${#SELECTED_CASES[@]} -eq 0 ]]; then
    SELECTED_CASES=("${CASES[@]}")
  fi

  for case_name in "${SELECTED_CASES[@]}"; do
    if ! contains_case "$case_name" "${CASES[@]}"; then
      echo "unsupported case: $case_name" >&2
      exit 1
    fi
    run_case "$case_name"
  done

  echo "[changes-e2e] success"
}

main "$@"
