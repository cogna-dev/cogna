import test from "node:test"
import assert from "node:assert/strict"

import { collectDiagnosticItems, diagnosticSeverity } from "../../diagnostics"
import { parseSarif } from "../../sarif"

const report = parseSarif(
  JSON.stringify({
    version: "2.1.0",
    runs: [
      {
        tool: {
          driver: {
            rules: [
              {
                id: "compat.go.signature-changed",
                helpUri: "https://codeiq.xaclabs.dev/docs/policies/generated/go/signature-changed",
              },
            ],
          },
        },
        results: [
          {
            ruleId: "compat.go.signature-changed",
            level: "warning",
            message: { text: "signature changed" },
            locations: [
              {
                physicalLocation: {
                  artifactLocation: { uri: "client/client.go" },
                  region: { startLine: 12, endLine: 13 },
                },
              },
            ],
          },
        ],
      },
    ],
  }),
)

test("diagnosticSeverity maps sarif levels", () => {
  assert.equal(diagnosticSeverity("error"), "error")
  assert.equal(diagnosticSeverity("warning"), "warning")
  assert.equal(diagnosticSeverity("note"), "information")
})

test("collectDiagnosticItems maps sarif results to workspace files", () => {
  const items = collectDiagnosticItems(report, "/workspace/demo")
  assert.equal(items.length, 1)
  assert.equal(items[0]?.filePath, "/workspace/demo/client/client.go")
  assert.equal(items[0]?.startLine, 12)
  assert.equal(items[0]?.endLine, 13)
  assert.equal(items[0]?.helpUri, "https://codeiq.xaclabs.dev/docs/policies/generated/go/signature-changed")
})
