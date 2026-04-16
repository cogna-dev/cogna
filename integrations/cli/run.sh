#!/usr/bin/env bash

set -euo pipefail

source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
manifest_path="$source_root/moon.mod.json"

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

cd "$source_root"
if [[ ${#cli_args[@]} -eq 0 ]]; then
  moon run "${moon_args[@]}" --manifest-path "$manifest_path" src/cmd/main
else
  moon run "${moon_args[@]}" --manifest-path "$manifest_path" src/cmd/main -- "${cli_args[@]}"
fi
