import * as path from "node:path"

import type { SarifLog } from "./sarif"
import { helpUriForRule } from "./sarif"

export type DiagnosticLevel = "error" | "warning" | "information"

export interface DiagnosticItem {
  filePath: string
  startLine: number
  endLine: number
  severity: DiagnosticLevel
  message: string
  ruleId: string
  helpUri?: string
}

export function diagnosticSeverity(level: string | undefined): DiagnosticLevel {
  switch (level) {
    case "error":
      return "error"
    case "warning":
      return "warning"
    default:
      return "information"
  }
}

function resolveArtifactPath(workingDirectory: string, artifactUri: string | undefined): string | undefined {
  if (!artifactUri) {
    return undefined
  }
  if (artifactUri.startsWith("http://") || artifactUri.startsWith("https://")) {
    return undefined
  }
  if (path.isAbsolute(artifactUri)) {
    return artifactUri
  }
  return path.resolve(workingDirectory, artifactUri)
}

export function collectDiagnosticItems(log: SarifLog, workingDirectory: string): DiagnosticItem[] {
  const out: DiagnosticItem[] = []
  for (const run of log.runs) {
    for (const result of run.results ?? []) {
      const location = result.locations?.[0]?.physicalLocation
      const filePath = resolveArtifactPath(
        workingDirectory,
        location?.artifactLocation?.uri,
      )
      if (!filePath) {
        continue
      }
      const startLine = Math.max(location?.region?.startLine ?? 1, 1)
      const endLine = Math.max(location?.region?.endLine ?? startLine, startLine)
      const ruleId = result.ruleId ?? "codeiq.unknown"
      out.push({
        filePath,
        startLine,
        endLine,
        severity: diagnosticSeverity(result.level),
        message: result.message?.text ?? ruleId,
        ruleId,
        helpUri: helpUriForRule(log, result.ruleId),
      })
    }
  }
  return out
}
