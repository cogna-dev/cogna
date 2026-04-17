import test from "node:test"
import assert from "node:assert/strict"

import { resolveCliPath, resolveSarifPath, resolveWorkingDirectory } from "../../cli"

test("resolve working directory prefers config and resolves relative paths", () => {
  const folders = [{ uri: { fsPath: "/workspace/demo" } }]
  assert.equal(resolveWorkingDirectory(folders, undefined), "/workspace/demo")
  assert.equal(resolveWorkingDirectory(folders, "subdir"), "/workspace/demo/subdir")
  assert.equal(resolveWorkingDirectory(folders, "/tmp/demo"), "/tmp/demo")
})

test("resolve cli path keeps PATH lookups and resolves relative binaries", () => {
  assert.equal(resolveCliPath(undefined, "/workspace/demo"), "cogna")
  assert.equal(resolveCliPath("cogna", "/workspace/demo"), "cogna")
  assert.equal(resolveCliPath(".moon/bin/cogna", "/workspace/demo"), "/workspace/demo/.moon/bin/cogna")
})

test("resolve sarif path is relative to working directory by default", () => {
  assert.equal(resolveSarifPath("/workspace/demo"), "/workspace/demo/dist/check.sarif.json")
  assert.equal(resolveSarifPath("/workspace/demo", "/tmp/check.sarif.json"), "/tmp/check.sarif.json")
})
