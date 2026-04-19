import {
  fetchPackages,
  queryOutlines,
  query,
  type PackageNode,
  type Outline,
  type QueryMatch,
} from '@cogna-dev/sdk'
import { execFile } from 'node:child_process'
import { promisify } from 'node:util'
import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'

export type DesktopRelation = 'root' | 'workspace' | 'direct' | 'transitive'

export type DesktopSourceLocation = {
  uri: string
  startLine: number
  endLine: number
}

export type DesktopPackageNode = {
  name: string
  version?: string
  ecosystem?: string
  relation: DesktopRelation
  summary?: string
  children: DesktopPackageNode[]
}

export type DesktopOutline = {
  id: string
  symbol: string
  kind: string
  summary?: string
  deprecated: boolean
  location: DesktopSourceLocation
}

export type DesktopQueryMatch = {
  id: string
  symbol: string
  kind: string
  signature?: string
  summary?: string
  docs?: string
  score?: number
  location: DesktopSourceLocation
}

export type DesktopDiffChange = {
  kind: 'added' | 'removed' | 'changed' | 'deprecated'
  id: string
  symbol: string
  level: string
  message: string
}

export type DesktopDiffResult = {
  summary: {
    added: number
    removed: number
    changed: number
    deprecated: number
  }
  changes: DesktopDiffChange[]
  testChanges: DesktopDiffChange[]
}

export type DesktopSarifRule = {
  id: string
  helpUri?: string
}

export type DesktopSarifResult = {
  ruleId?: string
  level: 'error' | 'warning' | 'note'
  message: string
  uri: string
  startLine: number
  endLine: number
  helpUri?: string
}

export type DesktopCheckResult = {
  sarifPath: string
  summary: {
    error: number
    warning: number
    note: number
    total: number
  }
  results: DesktopSarifResult[]
}

function emptySummary(): DesktopDiffResult['summary'] {
  return {
    added: 0,
    removed: 0,
    changed: 0,
    deprecated: 0,
  }
}

export type IpcSuccess<T> = {
  success: true
  data: T
}

export type IpcFailure = {
  success: false
  error: string
}

export type IpcResult<T> = IpcSuccess<T> | IpcFailure

function ok<T>(data: T): IpcSuccess<T> {
  return { success: true, data }
}

function err(message: unknown): IpcFailure {
  return {
    success: false,
    error: message instanceof Error ? message.message : String(message),
  }
}

function mapRelation(relation: string): DesktopRelation {
  if (relation === 'root' || relation === 'workspace' || relation === 'direct' || relation === 'transitive') {
    return relation
  }
  return 'transitive'
}

function mapPackageNode(node: PackageNode): DesktopPackageNode {
  return {
    name: node.name,
    version: node.version,
    ecosystem: node.ecosystem,
    relation: mapRelation(node.relation),
    summary: node.summary,
    children: node.children.map(mapPackageNode),
  }
}

function mapLocation(location?: { uri: string; startLine: number; endLine: number }): DesktopSourceLocation {
  if (!location) {
    return { uri: 'unknown', startLine: 1, endLine: 1 }
  }
  return {
    uri: location.uri,
    startLine: location.startLine,
    endLine: location.endLine,
  }
}

function mapOutline(item: Outline): DesktopOutline {
  return {
    id: item.id,
    symbol: item.symbol,
    kind: item.kind,
    summary: item.summary,
    deprecated: item.deprecated,
    location: mapLocation(item.location),
  }
}

function mapQueryMatch(item: QueryMatch): DesktopQueryMatch {
  return {
    id: item.id,
    symbol: item.symbol,
    kind: item.kind,
    signature: item.signature,
    summary: item.summary,
    docs: item.docs,
    score: item.score,
    location: mapLocation(item.location),
  }
}

const execFileAsync = promisify(execFile)

type DiffFileResult = {
  summary?: DesktopDiffResult['summary']
  changes: DesktopDiffChange[]
  testChanges?: DesktopDiffChange[]
  test_changes?: DesktopDiffChange[]
}

type CliInvocationResult = {
  stdout: string
  stderr: string
}

type SarifRule = {
  id: string
  helpUri?: string
}

type SarifResultEntry = {
  ruleId?: string
  level?: string
  message?: {
    text?: string
  }
  locations?: Array<{
    physicalLocation?: {
      artifactLocation?: {
        uri?: string
      }
      region?: {
        startLine?: number
        endLine?: number
      }
    }
  }>
}

type SarifRun = {
  tool?: {
    driver?: {
      rules?: SarifRule[]
    }
  }
  results?: SarifResultEntry[]
}

type SarifLog = {
  version?: string
  runs?: SarifRun[]
}

function workspaceArg(workspacePath?: string): string {
  return workspacePath && workspacePath.trim().length > 0 ? workspacePath : '.'
}

function withWorkspaceCwd<T>(workspacePath: string | undefined, action: () => T): T {
  const cwd = workspaceArg(workspacePath)
  const previous = process.cwd()
  try {
    process.chdir(cwd)
    return action()
  } finally {
    process.chdir(previous)
  }
}

async function runCli(args: string[], cwd: string): Promise<CliInvocationResult> {
  try {
    const result = await execFileAsync('cogna', args, {
      cwd,
      env: process.env,
    })
    return {
      stdout: result.stdout ?? '',
      stderr: result.stderr ?? '',
    }
  } catch (error) {
    if (error instanceof Error && 'code' in error && (error as { code?: string }).code === 'ENOENT') {
      throw new Error('Cogna CLI not found in PATH. Please install cogna and ensure it is available in your shell environment.')
    }
    throw error
  }
}

function readJsonFile<T>(path: string): T {
  return JSON.parse(readFileSync(path, 'utf-8')) as T
}

function mapSarifLevel(level?: string): 'error' | 'warning' | 'note' {
  if (level === 'error' || level === 'warning') {
    return level
  }
  return 'note'
}

function mapSarifResult(item: SarifResultEntry, rulesById: Map<string, DesktopSarifRule>): DesktopSarifResult {
  const location = item.locations?.[0]?.physicalLocation
  const uri = location?.artifactLocation?.uri ?? 'unknown'
  const startLine = location?.region?.startLine ?? 1
  const endLine = location?.region?.endLine ?? startLine
  const level = mapSarifLevel(item.level)
  const rule = item.ruleId ? rulesById.get(item.ruleId) : undefined
  return {
    ruleId: item.ruleId,
    level,
    message: item.message?.text ?? 'Policy finding',
    uri,
    startLine,
    endLine,
    helpUri: rule?.helpUri,
  }
}

export async function sdkBuild(workspacePath?: string): Promise<IpcResult<{ success: boolean }>> {
  try {
    const cwd = workspaceArg(workspacePath)
    await runCli(['build'], cwd)
    return ok({ success: true })
  } catch (error) {
    return err(error)
  }
}

export async function sdkInit(workspacePath?: string): Promise<IpcResult<{ success: boolean }>> {
  try {
    const cwd = workspaceArg(workspacePath)
    await runCli(['init', '--output', './cogna.yaml'], cwd)
    return ok({ success: true })
  } catch (error) {
    return err(error)
  }
}

export async function sdkFetchPackages(workspacePath?: string): Promise<IpcResult<{ root: DesktopPackageNode }>> {
  try {
    const result = withWorkspaceCwd(workspacePath, () => fetchPackages())
    if (!result?.root) {
      return err('fetchPackages returned empty root')
    }
    return ok({ root: mapPackageNode(result.root) })
  } catch (error) {
    return err(error)
  }
}

export async function sdkQueryOutlines(pkg: string, workspacePath?: string): Promise<IpcResult<{ package: string; outlines: DesktopOutline[] }>> {
  try {
    const result = withWorkspaceCwd(workspacePath, () => queryOutlines({ package: pkg }))
    if (!result) {
      return err('queryOutlines returned empty result')
    }
    return ok({
      package: result.package,
      outlines: result.outlines.map(mapOutline),
    })
  } catch (error) {
    return err(error)
  }
}

export async function sdkQuery(params: {
  package: string
  mode: 'exact-id' | 'exact-symbol' | 'fuzzy-text'
  input: string
  limit?: number
  workspacePath?: string
}): Promise<IpcResult<{ package: string; mode: string; matches: DesktopQueryMatch[] }>> {
  try {
    const req = {
      package: params.package,
      exactId: params.mode === 'exact-id' ? params.input : undefined,
      exactSymbol: params.mode === 'exact-symbol' ? params.input : undefined,
      text: params.mode === 'fuzzy-text' ? params.input : undefined,
      limit: params.mode === 'fuzzy-text' ? params.limit : undefined,
    }
    const result = withWorkspaceCwd(params.workspacePath, () => query(req))
    if (!result) {
      return err('query returned empty result')
    }
    return ok({
      package: result.package,
      mode: result.mode,
      matches: result.matches.map(mapQueryMatch),
    })
  } catch (error) {
    return err(error)
  }
}

export async function sdkDiff(params: {
  workspacePath?: string
  base: string
  target: string
  includeTestChanges: boolean
}): Promise<IpcResult<DesktopDiffResult>> {
  try {
    const cwd = workspaceArg(params.workspacePath)
    const args = ['diff', '--since', params.base, '--include-test-changes', params.includeTestChanges ? 'true' : 'false']
    const invocation = await runCli(args, cwd)
    const defaultDiffPath = resolve(cwd, 'dist', 'diff.json')
    let diffPath = defaultDiffPath
    if (!existsSync(diffPath)) {
      const match = invocation.stdout.match(/Generated CIQ declaration diff at (.+)$/m)
      const candidate = match?.[1]?.trim()
      if (candidate && existsSync(candidate)) {
        diffPath = candidate
      }
    }
    if (!existsSync(diffPath)) {
      throw new Error(`Diff output missing after command completion: ${defaultDiffPath}`)
    }
    const result = readJsonFile<DiffFileResult>(diffPath)
    const summary = result.summary
      ? {
          added: result.summary.added,
          removed: result.summary.removed,
          changed: result.summary.changed,
          deprecated: result.summary.deprecated,
        }
      : emptySummary()
    const testChanges = result.testChanges ?? result.test_changes ?? []
    return ok({
      summary,
      changes: result.changes.map((change) => ({
        kind: change.kind,
        id: change.id,
        symbol: change.symbol,
        level: change.level,
        message: change.message,
      })),
      testChanges: testChanges.map((change) => ({
        kind: change.kind,
        id: change.id,
        symbol: change.symbol,
        level: change.level,
        message: change.message,
      })),
    })
  } catch (error) {
    return err(error)
  }
}

export async function sdkCheck(workspacePath?: string): Promise<IpcResult<DesktopCheckResult>> {
  try {
    const cwd = workspaceArg(workspacePath)
    await runCli(['check'], cwd)
    const sarifPath = resolve(cwd, 'dist', 'check.sarif.json')
    const sarif = readJsonFile<SarifLog>(sarifPath)
    const runs = sarif.runs ?? []
    const rulesById = new Map<string, DesktopSarifRule>()
    for (const run of runs) {
      for (const rule of run.tool?.driver?.rules ?? []) {
        if (rule.id && !rulesById.has(rule.id)) {
          rulesById.set(rule.id, { id: rule.id, helpUri: rule.helpUri })
        }
      }
    }

    const results: DesktopSarifResult[] = []
    for (const run of runs) {
      for (const item of run.results ?? []) {
        results.push(mapSarifResult(item, rulesById))
      }
    }

    let errorCount = 0
    let warningCount = 0
    let noteCount = 0
    for (const item of results) {
      if (item.level === 'error') {
        errorCount += 1
      } else if (item.level === 'warning') {
        warningCount += 1
      } else {
        noteCount += 1
      }
    }

    return ok({
      sarifPath,
      summary: {
        error: errorCount,
        warning: warningCount,
        note: noteCount,
        total: results.length,
      },
      results,
    })
  } catch (error) {
    return err(error)
  }
}
