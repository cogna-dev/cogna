import test from "node:test"
import assert from "node:assert/strict"

import { helpUriForRule, parseSarif, rulesById } from "../../sarif"

const sampleSarif = JSON.stringify({
  version: "2.1.0",
  runs: [
    {
      tool: {
        driver: {
          rules: [
            {
              id: "compat.core.removed-declaration",
              helpUri: "https://codeiq.xaclabs.dev/docs/policies/generated/core/removed-declaration",
            },
          ],
        },
      },
      results: [],
    },
  ],
})

test("parseSarif keeps runs and indexes rules", () => {
  const report = parseSarif(sampleSarif)
  const rules = rulesById(report)
  assert.equal(rules.size, 1)
  assert.equal(
    helpUriForRule(report, "compat.core.removed-declaration"),
    "https://codeiq.xaclabs.dev/docs/policies/generated/core/removed-declaration",
  )
})
