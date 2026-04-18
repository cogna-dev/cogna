# ==============================================================================
# Cogna — Development Task Runner
# ==============================================================================
#
# Usage:   just <recipe>
# Requires: just ≥ 1.14, moon, bash
#
# Capability matrix (local parity with CI):
#
#  Verb      | Recipe              | What it does
#  ----------+---------------------+-------------------------------------------
#  build     | build-cli           | Compile native CLI binary (moon build)
#  build     | build-sdk           | Compile JS/Wasm SDK (moon build --target js)
#  build     | build-all           | build-cli + build-sdk
#  test      | test-unit           | Unit tests (moon test)
#  test      | test-e2e            | End-to-end tests (moon test src/e2e)
#  test      | test-all            | test-unit + test-e2e
#  check     | check-lint          | Type-check and static analysis (moon check)
#  check     | check-format        | Verify formatting without changes (moon fmt --check)
#  check     | check-version       | Verify git tag matches moon.mod.json version
#  check     | check-publish       | Dry-run SDK publish (moon publish --dry-run)
#  check     | check-all           | All pre-release gates (lint + format + version)
#  check     | check-sdk           | Typecheck + lint JS SDK (@cogna-dev/sdk)
#  fmt       | fmt                 | Format source files in-place (moon fmt)
#  fmt       | fmt-sdk             | Format JS SDK source files (biome)
#  install   | install-cli         | Install cogna binary to local bin
#  install   | install-vscode      | Build and install the VSCode extension
#  run       | run [ARGS...]       | Run cogna via moon run (no install required)
#  gen       | gen-proto           | Regenerate protobuf bindings
#  gen       | gen-openapi         | Regenerate API stubs from openapi.json (mapi)
#  test      | test-sdk            | Run JS SDK tests (vitest)
#  release   | release-dry         | Dry-run SDK publish to validate package
#  clean     | clean               | Remove all build artifacts (moon clean)
#  ci        | ci                  | Full CI gate (check-lint + check-format + test-unit + build-cli + check-sdk)
#  act       | act-e2e             | Run Actions E2E locally via act
#
# Dependency graph:
#
#   ci ──────────────────────────────────────────────────────────────────────┐
#     └── check-all ─── check-lint                                           │
#                   └── check-format                                         │
#     └── test-unit                                                          │
#     └── build-cli                                                          │
#                                                                            │
#   build-all ─── build-cli                                                  │
#             └── build-sdk                                                  │
#                                                                            │
#   test-all ─── test-unit                                                   │
#            └── test-e2e ─── build-cli (implicit: CLI must be installed)    │
#                                                                            │
#   install-cli ─── build-cli                                                │
#                                                                            │
# ==============================================================================

# Default: run full CI gate
default: ci

# ------------------------------------------------------------------------------
# build — Compile artifacts
# ------------------------------------------------------------------------------

# Compile native CLI binary
build-cli:
    moon build

# Compile JS/Wasm SDK (produces target/js output)
build-sdk:
    moon build --target js

# Compile all artifacts (CLI + SDK)
build-all: build-cli build-sdk

# ------------------------------------------------------------------------------
# test — Run test suites
# ------------------------------------------------------------------------------

# Run unit tests
test-unit:
    moon test

# Run JS SDK tests (vitest)
test-sdk:
    pnpm --filter @cogna-dev/sdk run test

# Run end-to-end integration tests
test-e2e:
    moon test src/e2e

# Run all tests (unit + e2e)
test-all: test-unit test-e2e

# ------------------------------------------------------------------------------
# check — Validate without side effects (pre-release gates)
# ------------------------------------------------------------------------------

# Run type checker and static analysis
check-lint:
    moon check

# Verify all source files are formatted (fails if any changes needed)
check-format:
    moon fmt --check

# Verify git tag matches moon.mod.json version (requires TAG env var or current tag)
check-version:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="${TAG:-$(git describe --exact-match --tags HEAD 2>/dev/null || echo '')}"
    if [ -z "$tag" ]; then
      echo "No exact git tag found on HEAD. Set TAG=vX.Y.Z to override." >&2
      exit 1
    fi
    version=$(python3 -c 'import json; print(json.load(open("moon.mod.json"))["version"])')
    expected="v${version}"
    if [ "$tag" != "$expected" ]; then
      echo "Tag mismatch: git tag='$tag' but moon.mod.json version='$version' (expected tag '$expected')" >&2
      exit 1
    fi
    echo "Version OK: $tag == v$version"

# Dry-run SDK publish to validate the package without uploading
check-publish:
    moon publish --dry-run

# Run all pre-release checks (used as release gate)
check-all: check-lint check-format

# Typecheck and lint the JS SDK (integrations/sdk/node)
check-sdk:
    pnpm --filter @cogna-dev/sdk run typecheck
    pnpm --filter @cogna-dev/sdk run lint

# ------------------------------------------------------------------------------
# fmt — Format source files in-place
# ------------------------------------------------------------------------------

# Format all MoonBit source files
fmt:
    moon fmt

# Format JS SDK source files (integrations/sdk/node) using biome
fmt-sdk:
    pnpm --filter @cogna-dev/sdk run format

# ------------------------------------------------------------------------------
# install — Local installation
# ------------------------------------------------------------------------------

# Install cogna CLI to local bin directory (default: ~/.moon/bin)
install-cli: build-cli
    mkdir -p "${COGNA_INSTALL_DIR:-${HOME}/.moon/bin}"
    bash integrations/cli/install.sh "${COGNA_INSTALL_DIR:-${HOME}/.moon/bin}" cogna

# Build and install the VSCode extension from source
install-vscode:
    code --uninstall-extension yufeiminds.cogna || true
    cd integrations/vscode && npm ci && npm run compile && npx @vscode/vsce package --no-dependencies && code --install-extension "$(pwd)/$(node -p "const pkg=require('./package.json'); pkg.name + '-' + pkg.version + '.vsix'")"

# ------------------------------------------------------------------------------
# run — Execute without installing
# ------------------------------------------------------------------------------

# Run cogna in-repo via moon run (passes remaining args to cogna)
run *ARGS:
    bash integrations/cli/run.sh {{ARGS}}

# ------------------------------------------------------------------------------
# gen — Code generation
# ------------------------------------------------------------------------------

# Regenerate protobuf bindings (requires go + buf)
gen-proto:
    go build -o proto/protoc-gen-cogna/protoc-gen-cogna ./proto/protoc-gen-cogna
    buf generate --template buf.gen.yaml

# Regenerate API stubs from openapi.json into the existing project (mapi ≥ 0.1.1)
gen-openapi:
    mapi generate --spec openapi.json --project .

# Export MoonBit SDK JS runtime to dist/runtime for consumers
export-sdk-runtime:
    node ./scripts/export-sdk-runtime.mjs

# ------------------------------------------------------------------------------
# release — Release preparation
# ------------------------------------------------------------------------------

# Dry-run SDK publish to mooncakes.io (validates package, does not upload)
release-dry:
    moon publish --dry-run

# ------------------------------------------------------------------------------
# clean — Remove build artifacts
# ------------------------------------------------------------------------------

# Remove all build outputs
clean:
    moon clean

# ------------------------------------------------------------------------------
# ci — Full CI gate (mirrors GitHub CI)
# ------------------------------------------------------------------------------

# Full CI pipeline: lint + format check + unit tests + CLI build + JS SDK check
ci: check-lint check-format test-unit build-cli check-sdk

# ------------------------------------------------------------------------------
# act — Local GitHub Actions simulation
# ------------------------------------------------------------------------------

# Run Actions E2E workflow locally via act (requires act + Docker)
act-e2e:
    act workflow_dispatch -W .github/workflows/actions-e2e.yml --container-architecture linux/amd64
