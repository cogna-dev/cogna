import * as vscode from "vscode"

import {
  CodeIQCommandError,
  fileExists,
  readTextFile,
  resolveCliPath,
  resolveSarifPath,
  resolveWorkingDirectory,
  runAnalysis,
} from "./cli"
import { collectDiagnosticItems, type DiagnosticItem } from "./diagnostics"
import { openDocumentation } from "./docs"
import { parseSarif } from "./sarif"

export const RUN_ANALYSIS_COMMAND = "codeiq.runAnalysis"
export const REFRESH_DIAGNOSTICS_COMMAND = "codeiq.refreshDiagnostics"
export const OPEN_RULE_DOCUMENTATION_COMMAND = "codeiq.openRuleDocumentation"

interface ExtensionDependencies {
  openExternal(target: vscode.Uri): Thenable<boolean>
}

const defaultDependencies: ExtensionDependencies = {
  openExternal(target: vscode.Uri) {
    if (process.env.CODEIQ_TEST_DISABLE_EXTERNAL_OPEN === "true") {
      return Promise.resolve(true)
    }
    return vscode.env.openExternal(target)
  },
}

function configuration() {
  const config = vscode.workspace.getConfiguration("codeiq")
  return {
    cliPath: config.get<string>("cliPath"),
    workingDirectory: config.get<string>("workingDirectory"),
    runOnSave: config.get<boolean>("runOnSave", false),
    autoOpenPolicyDocs: config.get<boolean>("autoOpenPolicyDocs", false),
  }
}

function toSeverity(level: DiagnosticItem["severity"]): vscode.DiagnosticSeverity {
  switch (level) {
    case "error":
      return vscode.DiagnosticSeverity.Error
    case "warning":
      return vscode.DiagnosticSeverity.Warning
    default:
      return vscode.DiagnosticSeverity.Information
  }
}

function diagnosticsAtCursor(editor: vscode.TextEditor | undefined): vscode.Diagnostic[] {
  if (!editor) {
    return []
  }
  const line = editor.selection.active.line
  return vscode.languages
    .getDiagnostics(editor.document.uri)
    .filter((diagnostic) => diagnostic.source === "codeiq")
    .filter((diagnostic) => diagnostic.range.start.line <= line && diagnostic.range.end.line >= line)
}

function helpUriFromDiagnostic(diagnostic: vscode.Diagnostic): string | undefined {
  const information = diagnostic.relatedInformation?.[0]
  if (!information) {
    return undefined
  }
  const scheme = information.location.uri.scheme
  if (scheme === "http" || scheme === "https") {
    return information.location.uri.toString()
  }
  return undefined
}

function uniqueHelpUris(diagnostics: readonly vscode.Diagnostic[]): string[] {
  return [...new Set(diagnostics.map(helpUriFromDiagnostic).filter((value): value is string => Boolean(value)))]
}

async function applyDiagnostics(
  collection: vscode.DiagnosticCollection,
  workingDirectory: string,
  output: vscode.OutputChannel,
): Promise<DiagnosticItem[]> {
  const sarifPath = resolveSarifPath(workingDirectory)
  if (!(await fileExists(sarifPath))) {
    throw new Error(`Missing SARIF file at ${sarifPath}`)
  }
  const sarifText = await readTextFile(sarifPath)
  const report = parseSarif(sarifText)
  const items = collectDiagnosticItems(report, workingDirectory)
  collection.clear()

  const grouped = new Map<string, vscode.Diagnostic[]>()
  for (const item of items) {
    const range = new vscode.Range(
      Math.max(item.startLine - 1, 0),
      0,
      Math.max(item.endLine - 1, 0),
      0,
    )
    const diagnostic = new vscode.Diagnostic(range, item.message, toSeverity(item.severity))
    diagnostic.source = "codeiq"
    diagnostic.code = item.ruleId
    if (item.helpUri) {
      diagnostic.relatedInformation = [
        new vscode.DiagnosticRelatedInformation(
          new vscode.Location(vscode.Uri.parse(item.helpUri), new vscode.Position(0, 0)),
          item.helpUri,
        ),
      ]
    }
    const fileDiagnostics = grouped.get(item.filePath) ?? []
    fileDiagnostics.push(diagnostic)
    grouped.set(item.filePath, fileDiagnostics)
  }

  for (const [filePath, fileDiagnostics] of grouped.entries()) {
    collection.set(vscode.Uri.file(filePath), fileDiagnostics)
  }
  output.appendLine(`Loaded ${items.length} CodeIQ diagnostics from ${sarifPath}`)
  return items
}

function registerCodeActions(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.languages.registerCodeActionsProvider(
      { scheme: "file" },
      {
        provideCodeActions: (_document, _range, codeActionContext, _token) => {
          const codeiqDiagnostics = codeActionContext.diagnostics.filter(
            (diagnostic) => diagnostic.source === "codeiq",
          )
          if (codeiqDiagnostics.length === 0) {
            return []
          }

          const actions: vscode.Command[] = []
          const [firstHelpUri] = uniqueHelpUris(codeiqDiagnostics)
          if (firstHelpUri) {
            actions.push({
              command: OPEN_RULE_DOCUMENTATION_COMMAND,
              title: "CodeIQ: Open Rule Documentation",
              arguments: [firstHelpUri],
            })
          }

          actions.push({
            command: REFRESH_DIAGNOSTICS_COMMAND,
            title: "CodeIQ: Refresh Diagnostics",
          })
          return actions
        },
      },
    ),
  )
}

export async function activateWithDependencies(
  context: vscode.ExtensionContext,
  dependencies: ExtensionDependencies,
) {
  const output = vscode.window.createOutputChannel("CodeIQ")
  const collection = vscode.languages.createDiagnosticCollection("codeiq")
  context.subscriptions.push(output, collection)

  let running = false

  const refreshDiagnostics = async (): Promise<{ diagnosticCount: number; sarifPath: string }> => {
    const config = configuration()
    const workingDirectory = resolveWorkingDirectory(vscode.workspace.workspaceFolders, config.workingDirectory)
    if (!workingDirectory) {
      throw new Error("No workspace folder or CodeIQ working directory configured")
    }
    const items = await applyDiagnostics(collection, workingDirectory, output)
    return {
      diagnosticCount: items.length,
      sarifPath: resolveSarifPath(workingDirectory),
    }
  }

  const runAnalysisCommand = async (): Promise<{ diagnosticCount: number; sarifPath: string }> => {
    if (running) {
      throw new Error("CodeIQ analysis is already running")
    }
    running = true
    output.show(true)
    try {
      const config = configuration()
      const workingDirectory = resolveWorkingDirectory(vscode.workspace.workspaceFolders, config.workingDirectory)
      if (!workingDirectory) {
        throw new Error("No workspace folder or CodeIQ working directory configured")
      }
      const cliPath = resolveCliPath(config.cliPath, workingDirectory)
      output.appendLine(`Running CodeIQ analysis in ${workingDirectory}`)
      const analysis = await runAnalysis(cliPath, workingDirectory)
      for (const step of analysis.steps) {
        output.appendLine(`$ ${[step.command, ...step.args].join(" ")}`)
        if (step.stdout.trim()) {
          output.appendLine(step.stdout.trim())
        }
        if (step.stderr.trim()) {
          output.appendLine(step.stderr.trim())
        }
      }
      const refreshed = await refreshDiagnostics()
      if (config.autoOpenPolicyDocs) {
        const activeDiagnostics = diagnosticsAtCursor(vscode.window.activeTextEditor)
        const [firstHelpUri] = uniqueHelpUris(activeDiagnostics)
        if (firstHelpUri) {
          await openDocumentation((target) => dependencies.openExternal(vscode.Uri.parse(target)), firstHelpUri)
        }
      }
      return refreshed
    } catch (error) {
      if (error instanceof CodeIQCommandError) {
        output.appendLine(error.message)
        if (error.result.stdout.trim()) {
          output.appendLine(error.result.stdout.trim())
        }
        if (error.result.stderr.trim()) {
          output.appendLine(error.result.stderr.trim())
        }
      }
      throw error
    } finally {
      running = false
    }
  }

  const openRuleDocumentation = async (target?: string): Promise<string> => {
    const activeDiagnostics = diagnosticsAtCursor(vscode.window.activeTextEditor)
    const helpUri = target ?? uniqueHelpUris(activeDiagnostics)[0]
    const opened = await openDocumentation(
      (documentationTarget) => dependencies.openExternal(vscode.Uri.parse(documentationTarget)),
      helpUri,
    )
    return opened
  }

  context.subscriptions.push(
    vscode.commands.registerCommand(RUN_ANALYSIS_COMMAND, async () => {
      const result = await runAnalysisCommand()
      return result
    }),
    vscode.commands.registerCommand(REFRESH_DIAGNOSTICS_COMMAND, async () => {
      const result = await refreshDiagnostics()
      return result
    }),
    vscode.commands.registerCommand(OPEN_RULE_DOCUMENTATION_COMMAND, async (target?: string) => {
      const result = await openRuleDocumentation(target)
      return result
    }),
  )

  registerCodeActions(context)

  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument(async (document) => {
      const config = configuration()
      if (!config.runOnSave || document.uri.scheme !== "file") {
        return
      }
      try {
        await runAnalysisCommand()
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error)
        output.appendLine(`Run-on-save failed: ${message}`)
      }
    }),
  )

  const initialWorkingDirectory = resolveWorkingDirectory(
    vscode.workspace.workspaceFolders,
    configuration().workingDirectory,
  )
  if (initialWorkingDirectory && (await fileExists(resolveSarifPath(initialWorkingDirectory)))) {
    void refreshDiagnostics().catch((error: unknown) => {
      const message = error instanceof Error ? error.message : String(error)
      output.appendLine(`Initial diagnostic refresh skipped: ${message}`)
    })
  }
}

export async function activate(context: vscode.ExtensionContext) {
  await activateWithDependencies(context, defaultDependencies)
}

export function deactivate() {
  return undefined
}
