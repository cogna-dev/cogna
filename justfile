default: ci

build:
  moon build

clean:
  moon clean

test:
  moon test

lint:
  moon check

format:
  moon fmt

format-check:
  moon fmt --check

install: build
  mkdir -p "${CODEIQ_INSTALL_DIR:-${HOME}/.moon/bin}"
  bash integrations/cli/install.sh "${CODEIQ_INSTALL_DIR:-${HOME}/.moon/bin}" codeiq

run:
  bash integrations/cli/run.sh

e2e:
  moon test src/e2e

proto-gen:
  go build -o tools/protoc-gen-codeiq/protoc-gen-codeiq ./tools/protoc-gen-codeiq
  buf generate --template buf.gen.yaml

ci: lint format-check test build

action-e2e:
  act workflow_dispatch -W .github/workflows/actions-e2e.yml --container-architecture linux/amd64

install-vscode:
  code --uninstall-extension yufeiminds.codeiq || true
  cd integrations/vscode && npm ci && npm run compile && npx @vscode/vsce package --no-dependencies && code --install-extension "$(pwd)/$(node -p \"const pkg=require('./package.json'); pkg.name + '-' + pkg.version + '.vsix'\")"
