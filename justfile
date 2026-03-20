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
  moon install yufeiminds/codeiq/cmd/main

run:
  moon run src/cmd/main

e2e:
  moon test src/e2e

ci: lint format-check test build
