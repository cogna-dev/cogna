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

function workspaceRoot(): string {
  return resolve(__dirname, '../../../../..')
}

function cliRunnerPath(): string {
  return resolve(workspaceRoot(), 'integrations/cli/run.sh')
}

function workspaceArg(workspacePath?: string): string {
  return workspacePath && workspacePath.trim().length > 0 ? workspacePath : '.'
}

async function runCli(args: string[], cwd: string): Promise<CliInvocationResult> {
  const scriptPath = cliRunnerPath()
  if (!existsSync(scriptPath)) {
    throw new Error(`Cogna CLI runner not found at ${scriptPath}`)
  }
  const result = await execFileAsync(scriptPath, ['--', ...args], {
    cwd,
    env: process.env,
  })
  return {
    stdout: result.stdout ?? '',
    stderr: result.stderr ?? '',
  }
}

function readJsonFile<T>(path: string): T {
  return JSON.parse(readFileSync(path, 'utf-8')) as T
}

export async function sdkBuild(workspacePath?: string): Promise<IpcResult<{ success: boolean }>> {
  try {
    const cwd = workspaceArg(workspacePath)
    await runCli(['build', '--repo', cwd], cwd)
    return ok({ success: true })
  } catch (error) {
    return err(error)
  }
}

export async function sdkFetchPackages(): Promise<IpcResult<{ root: DesktopPackageNode }>> {
  try {
    const result = fetchPackages()
    if (!result?.root) {
      return err('fetchPackages returned empty root')
    }
    return ok({ root: mapPackageNode(result.root) })
  } catch (error) {
    return err(error)
  }
}

export async function sdkQueryOutlines(pkg: string): Promise<IpcResult<{ package: string; outlines: DesktopOutline[] }>> {
  try {
    const result = queryOutlines({ package: pkg })
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
}): Promise<IpcResult<{ package: string; mode: string; matches: DesktopQueryMatch[] }>> {
  try {
    const req = {
      package: params.package,
      exactId: params.mode === 'exact-id' ? params.input : undefined,
      exactSymbol: params.mode === 'exact-symbol' ? params.input : undefined,
      text: params.mode === 'fuzzy-text' ? params.input : undefined,
      limit: params.mode === 'fuzzy-text' ? params.limit : undefined,
    }
    const result = query(req)
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
    const args = ['diff', '--repo', cwd, '--since', params.base, '--include-test-changes', params.includeTestChanges ? 'true' : 'false']
    await runCli(args, cwd)
    const diffPath = resolve(cwd, 'dist', 'diff.json')
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
