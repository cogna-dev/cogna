import * as fs from "node:fs/promises"

export interface SarifArtifactLocation {
  uri?: string
}

export interface SarifRegion {
  startLine?: number
  endLine?: number
}

export interface SarifPhysicalLocation {
  artifactLocation?: SarifArtifactLocation
  region?: SarifRegion
}

export interface SarifLocation {
  physicalLocation?: SarifPhysicalLocation
}

export interface SarifMessage {
  text?: string
}

export interface SarifRule {
  id: string
  helpUri?: string
}

export interface SarifResult {
  ruleId?: string
  level?: string
  message?: SarifMessage
  locations?: SarifLocation[]
}

export interface SarifRun {
  tool?: {
    driver?: {
      rules?: SarifRule[]
    }
  }
  results?: SarifResult[]
}

export interface SarifLog {
  version: string
  runs: SarifRun[]
}

export function parseSarif(text: string): SarifLog {
  const parsed = JSON.parse(text) as Partial<SarifLog>
  if (!Array.isArray(parsed.runs)) {
    throw new Error("SARIF log must contain runs[]")
  }
  return {
    version: parsed.version ?? "",
    runs: parsed.runs,
  }
}

export async function readSarif(filePath: string): Promise<SarifLog> {
  const text = await fs.readFile(filePath, "utf8")
  return parseSarif(text)
}

export function rulesById(log: SarifLog): Map<string, SarifRule> {
  const out = new Map<string, SarifRule>()
  for (const run of log.runs) {
    for (const rule of run.tool?.driver?.rules ?? []) {
      if (rule.id) {
        out.set(rule.id, rule)
      }
    }
  }
  return out
}

export function helpUriForRule(log: SarifLog, ruleId: string | undefined): string | undefined {
  if (!ruleId) {
    return undefined
  }
  return rulesById(log).get(ruleId)?.helpUri
}
