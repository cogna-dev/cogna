#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

export COGNA_ENABLE_REMOTE_E2E="${COGNA_ENABLE_REMOTE_E2E:-true}"
export COGNA_ENABLE_GIT_REMOTE_E2E="${COGNA_ENABLE_GIT_REMOTE_E2E:-true}"
export COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E="${COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E:-true}"
export COGNA_REMOTE_WORKSPACE_ROOT="${COGNA_REMOTE_WORKSPACE_ROOT:-${REPO_ROOT}}"

cd "${REPO_ROOT}"

echo "[remote-e2e] COGNA_ENABLE_REMOTE_E2E=${COGNA_ENABLE_REMOTE_E2E}"
echo "[remote-e2e] COGNA_ENABLE_GIT_REMOTE_E2E=${COGNA_ENABLE_GIT_REMOTE_E2E}"
echo "[remote-e2e] COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E=${COGNA_ENABLE_RUST_PACKAGE_REMOTE_E2E}"
echo "[remote-e2e] COGNA_REMOTE_WORKSPACE_ROOT=${COGNA_REMOTE_WORKSPACE_ROOT}"

for attempt in 1 2 3; do
  if moon test --target native src/e2e/extractors/main_test.mbt &&
    moon test --target native src/e2e/extractors/remote_test.mbt; then
    exit 0
  fi
  if [[ "$attempt" -lt 3 ]]; then
    echo "[remote-e2e] moon test failed, retrying (${attempt}/3) after lock contention backoff"
    sleep 3
  fi
done

echo "[remote-e2e] moon test failed after retries" >&2
exit 1
