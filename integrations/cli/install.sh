#!/usr/bin/env bash

set -euo pipefail

install_dir="${1:-${CODEIQ_INSTALL_DIR:-${HOME}/.moon/bin}}"
binary_name="${2:-codeiq}"

mkdir -p "$install_dir"
moon install --bin "$install_dir" --path src/cmd/main

main_path="$install_dir/main"
if [[ ! -x "$main_path" ]]; then
  echo "Expected MoonBit install to create $main_path" >&2
  exit 1
fi

if [[ "$binary_name" != "main" ]]; then
  ln -sf "$main_path" "$install_dir/$binary_name"
fi
