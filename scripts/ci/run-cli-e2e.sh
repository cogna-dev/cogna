#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
REPOS_ROOT="$ROOT_DIR/e2e/repos"
KEEP_ARTIFACTS="${COGNA_E2E_KEEP_ARTIFACTS:-false}"
CLI_TIMEOUT_SECONDS="${COGNA_E2E_TIMEOUT_SECONDS:-10}"

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

run_cli_from_root() {
  (
    cd "$ROOT_DIR"
    COGNA_CLI_TIMEOUT_SECONDS="$CLI_TIMEOUT_SECONDS" bash integrations/cli/run.sh -- "$@"
  )
}

run_cli_in_repo() {
  local repo_dir="$1"
  shift
  (
    cd "$repo_dir"
    perl -e 'alarm shift; exec @ARGV' "$CLI_TIMEOUT_SECONDS" \
      moon run --target native --manifest-path "$ROOT_DIR/moon.mod.json" src/cmd/main -- "$@"
  )
}

assert_file_exists() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "assert failed: expected file $path" >&2
    exit 1
  fi
}

expected_profile() {
  local repo_name="$1"
  case "$repo_name" in
    go-module|openapi-spec|rust-crate|terraform-module) echo "$repo_name" ;;
    *) echo "" ;;
  esac
}

assert_profile() {
  local repo_dir="$1"
  local profile="$2"
  [[ -z "$profile" ]] && return
  if ! grep -Eq "^profile: ${profile}$" "$repo_dir/cogna.yaml"; then
    echo "assert failed: expected profile ${profile} in $repo_dir/cogna.yaml" >&2
    sed -n '1,40p' "$repo_dir/cogna.yaml" >&2 || true
    exit 1
  fi
}

prepare_repo_dependencies() {
  local repo_dir="$1"
  if [[ -f "$repo_dir/go.mod" ]]; then
    (cd "$repo_dir" && go mod download)
  fi
  if [[ -f "$repo_dir/Cargo.toml" ]]; then
    (cd "$repo_dir" && cargo fetch)
  fi
}

prepare_diff_inputs() {
  local repo_dir="$1"
  mkdir -p "$repo_dir/dist/base" "$repo_dir/dist/target"
  cp "$repo_dir/dist/manifest.json" "$repo_dir/dist/base/manifest.json"
  cp "$repo_dir/dist/declarations.ndjson" "$repo_dir/dist/base/declarations.ndjson"
  if [[ -f "$repo_dir/dist/sbom.spdx.json" ]]; then
    cp "$repo_dir/dist/sbom.spdx.json" "$repo_dir/dist/base/sbom.spdx.json"
  fi

  cp "$repo_dir/dist/manifest.json" "$repo_dir/dist/target/manifest.json"
  cp "$repo_dir/dist/declarations.ndjson" "$repo_dir/dist/target/declarations.ndjson"
  if [[ -f "$repo_dir/dist/sbom.spdx.json" ]]; then
    cp "$repo_dir/dist/sbom.spdx.json" "$repo_dir/dist/target/sbom.spdx.json"
  fi
}

cleanup_repo() {
  local repo_dir="$1"
  rm -rf "$repo_dir/.cogna" "$repo_dir/dist" "$repo_dir/cogna.yaml"
}

run_repo_e2e() {
  local repo_dir="$1"
  local repo_name="$2"
  local repo_rel="${repo_dir#$ROOT_DIR/}"
  local profile
  profile="$(expected_profile "$repo_name")"

  log "[$repo_name] reset workspace"
  cleanup_repo "$repo_dir"

  log "[$repo_name] prepare dependencies"
  prepare_repo_dependencies "$repo_dir"

  log "[$repo_name] step 1/5 init"
  run_cli_from_root init --output "./$repo_rel/cogna.yaml"
  assert_file_exists "$repo_dir/cogna.yaml"
  assert_file_exists "$repo_dir/.cogna/policies/compat.rego"
  assert_profile "$repo_dir" "$profile"

  log "[$repo_name] step 2/5 build"
  set +e
  run_cli_from_root build --repo "./$repo_rel"
  local exit_code=$?
  set -e
  if [[ "$exit_code" -ne 0 ]]; then
    if [[ "$exit_code" -eq 142 ]]; then
      echo "[$repo_name] build timed out after ${CLI_TIMEOUT_SECONDS}s; inspect debug logs above" >&2
    else
      echo "[$repo_name] build failed with exit code $exit_code" >&2
    fi
    exit "$exit_code"
  fi
  assert_file_exists "$repo_dir/dist/manifest.json"
  assert_file_exists "$repo_dir/dist/declarations.ndjson"
  assert_file_exists "$repo_dir/dist/bundle.ciq.tgz"

  log "[$repo_name] prepare diff fixtures"
  prepare_diff_inputs "$repo_dir"

  log "[$repo_name] step 3/5 diff"
  run_cli_from_root diff --repo "./$repo_rel" --since v0.0.0 --include-test-changes true
  assert_file_exists "$repo_dir/dist/diff.json"

  log "[$repo_name] step 4/5 check"
  run_cli_in_repo "$repo_dir" check
  assert_file_exists "$repo_dir/dist/check.sarif.json"

  if [[ "$KEEP_ARTIFACTS" == "true" ]]; then
    log "[$repo_name] keeping artifacts because COGNA_E2E_KEEP_ARTIFACTS=true"
  else
    log "[$repo_name] step 5/5 cleanup"
    cleanup_repo "$repo_dir"
  fi

  log "[$repo_name] e2e done"
}

main() {
  local targets=()
  if [[ "$#" -gt 0 ]]; then
    for name in "$@"; do
      targets+=("$REPOS_ROOT/$name")
    done
  else
    while IFS= read -r dir; do
      targets+=("$dir")
    done < <(find "$REPOS_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)
  fi

  if [[ "${#targets[@]}" -eq 0 ]]; then
    echo "no repos found under $REPOS_ROOT" >&2
    exit 1
  fi

  for repo_dir in "${targets[@]}"; do
    if [[ ! -d "$repo_dir" ]]; then
      echo "repo directory does not exist: $repo_dir" >&2
      exit 1
    fi
    run_repo_e2e "$repo_dir" "$(basename "$repo_dir")"
  done

  log "all e2e repos completed successfully"
}

main "$@"
