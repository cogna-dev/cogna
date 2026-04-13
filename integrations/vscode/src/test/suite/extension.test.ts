import * as assert from "node:assert/strict"
import * as path from "node:path"

import * as vscode from "vscode"

import {
  OPEN_RULE_DOCUMENTATION_COMMAND,
  REFRESH_DIAGNOSTICS_COMMAND,
  RUN_ANALYSIS_COMMAND,
} from "../../extension"

const extensionId = "yufeiminds.codeiq"

suite("CodeIQ extension", () => {
  suiteSetup(async () => {
    const extension = vscode.extensions.getExtension(extensionId)
    assert.ok(extension, `Missing extension ${extensionId}`)
    await extension.activate()

    const workspaceDir = process.env.CODEIQ_TEST_WORKSPACE
    const cliPath = process.env.CODEIQ_TEST_CLI
    assert.ok(workspaceDir, "CODEIQ_TEST_WORKSPACE must be set")
    assert.ok(cliPath, "CODEIQ_TEST_CLI must be set")

    const config = vscode.workspace.getConfiguration("codeiq")
    await config.update("workingDirectory", workspaceDir, vscode.ConfigurationTarget.Workspace)
    await config.update("cliPath", cliPath, vscode.ConfigurationTarget.Workspace)
    await config.update("runOnSave", false, vscode.ConfigurationTarget.Workspace)
    await config.update("autoOpenPolicyDocs", false, vscode.ConfigurationTarget.Workspace)

    const document = await vscode.workspace.openTextDocument(path.join(workspaceDir, "openapi", "payment.yaml"))
    await vscode.window.showTextDocument(document)
  })

  test("registers CodeIQ commands", async () => {
    const commands = await vscode.commands.getCommands(true)
    assert.ok(commands.includes(RUN_ANALYSIS_COMMAND))
    assert.ok(commands.includes(REFRESH_DIAGNOSTICS_COMMAND))
    assert.ok(commands.includes(OPEN_RULE_DOCUMENTATION_COMMAND))
  })

  test("refresh diagnostics reads existing sarif", async () => {
    const result = await vscode.commands.executeCommand<{ diagnosticCount: number; sarifPath: string }>(
      REFRESH_DIAGNOSTICS_COMMAND,
    )
    assert.ok(result)
    assert.equal(result.diagnosticCount, 1)
    assert.match(result.sarifPath, /check\.sarif\.json$/)

    const editor = vscode.window.activeTextEditor
    assert.ok(editor)
    const diagnostics = vscode.languages.getDiagnostics(editor.document.uri)
    assert.equal(diagnostics.length, 1)
    assert.equal(diagnostics[0]?.source, "codeiq")
  })

  test("open rule documentation returns help uri from diagnostics", async () => {
    await vscode.commands.executeCommand(REFRESH_DIAGNOSTICS_COMMAND)
    const opened = await vscode.commands.executeCommand<string>(OPEN_RULE_DOCUMENTATION_COMMAND)
    assert.equal(
      opened,
      "https://codeiq.xaclabs.dev/docs/policies/generated/core/removed-declaration",
    )
  })

  test("run analysis produces refreshed diagnostics", async () => {
    const result = await vscode.commands.executeCommand<{ diagnosticCount: number; sarifPath: string }>(
      RUN_ANALYSIS_COMMAND,
    )
    assert.ok(result)
    assert.ok(result.diagnosticCount >= 1)

    const editor = vscode.window.activeTextEditor
    assert.ok(editor)
    const diagnostics = vscode.languages.getDiagnostics(editor.document.uri)
    assert.ok(diagnostics.length >= 1)
    const code = diagnostics[0]?.code
    assert.equal(code, "compat.core.removed-declaration")
  })
})
