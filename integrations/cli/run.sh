#!/usr/bin/env bash

set -euo pipefail

source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
manifest_path="$source_root/moon.mod.json"
timeout_seconds="${COGNA_CLI_TIMEOUT_SECONDS:-}"

run_moon() {
  if [[ -n "$timeout_seconds" ]]; then
    perl -e 'alarm shift; exec @ARGV' "$timeout_seconds" "$@"
  else
    "$@"
  fi
}

moon_args=()
cli_args=()
split_args=0

for arg in "$@"; do
  if [[ "$arg" == "--" && $split_args -eq 0 ]]; then
    split_args=1
    continue
  fi
  if [[ $split_args -eq 0 ]]; then
    moon_args+=("$arg")
  else
    cli_args+=("$arg")
  fi
done

has_target=0
if [[ ${#moon_args[@]} -gt 0 ]]; then
  for arg in "${moon_args[@]}"; do
    if [[ "$arg" == "--target" || "$arg" == --target=* ]]; then
      has_target=1
      break
    fi
  done
fi
if [[ $has_target -eq 0 ]]; then
  if [[ ${#moon_args[@]} -gt 0 ]]; then
    moon_args=(--target native "${moon_args[@]}")
  else
    moon_args=(--target native)
  fi
fi

cd "$source_root"
if [[ ${#moon_args[@]} -eq 0 ]]; then
  if [[ ${#cli_args[@]} -eq 0 ]]; then
    run_moon moon run --manifest-path "$manifest_path" src/cmd/main
  else
    run_moon moon run --manifest-path "$manifest_path" src/cmd/main -- "${cli_args[@]}"
  fi
else
  if [[ ${#cli_args[@]} -eq 0 ]]; then
    run_moon moon run "${moon_args[@]}" --manifest-path "$manifest_path" src/cmd/main
  else
    run_moon moon run "${moon_args[@]}" --manifest-path "$manifest_path" src/cmd/main -- "${cli_args[@]}"
  fi
fi
