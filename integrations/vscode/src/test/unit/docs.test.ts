import test from "node:test"
import assert from "node:assert/strict"

import { POLICY_INDEX_URL, openDocumentation, resolveDocumentationUrl } from "../../docs"

test("resolveDocumentationUrl falls back to policy index", () => {
  assert.equal(resolveDocumentationUrl(undefined), POLICY_INDEX_URL)
  assert.equal(resolveDocumentationUrl("https://example.com/rule"), "https://example.com/rule")
})

test("openDocumentation returns opened target", async () => {
  let opened = ""
  const target = await openDocumentation(async (value) => {
    opened = value
  }, "https://example.com/rule")
  assert.equal(target, "https://example.com/rule")
  assert.equal(opened, "https://example.com/rule")
})
