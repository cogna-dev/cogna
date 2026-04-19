import { ElectronAPI } from '@electron-toolkit/preload'

interface WorkspaceState {
  folderPath: string
  displayName: string
  contextSummary: string
  source: 'default' | 'deep-link' | 'renderer'
}

interface WorkspaceHealth {
  hasConfig: boolean
  hasCache: boolean
}

interface IpcSuccess<T> {
  success: true
  data: T
}

interface IpcFailure {
  success: false
  error: string
}

type IpcResult<T> = IpcSuccess<T> | IpcFailure

type Relation = 'root' | 'workspace' | 'direct' | 'transitive'
type QueryMode = 'exact-id' | 'exact-symbol' | 'fuzzy-text'

interface SourceLocation {
  uri: string
  startLine: number
  endLine: number
}

interface PackageNode {
  name: string
  version?: string
  ecosystem?: string
  relation: Relation
  summary?: string
  children: PackageNode[]
}

interface Outline {
  id: string
  symbol: string
  kind: string
  summary?: string
  deprecated: boolean
  location: SourceLocation
}

interface QueryMatch {
  id: string
  symbol: string
  kind: string
  signature?: string
  summary?: string
  docs?: string
  score?: number
  location: SourceLocation
}

interface DiffChange {
  kind: 'added' | 'removed' | 'changed' | 'deprecated'
  id: string
  symbol: string
  level: string
  message: string
}

interface DiffResult {
  summary: {
    added: number
    removed: number
    changed: number
    deprecated: number
  }
  changes: DiffChange[]
  testChanges: DiffChange[]
}

interface SarifResult {
  ruleId?: string
  level: 'error' | 'warning' | 'note'
  message: string
  uri: string
  startLine: number
  endLine: number
  helpUri?: string
}

interface CheckResult {
  sarifPath: string
  summary: {
    error: number
    warning: number
    note: number
    total: number
  }
  results: SarifResult[]
}

declare global {
  interface Window {
    electron: ElectronAPI
    api: {
      window: {
        minimize: () => void
        maximize: () => void
        close: () => void
      }
      workspace: {
        getState: () => Promise<WorkspaceState>
        getHealth: () => Promise<WorkspaceHealth>
        openFolder: (folderPath: string) => void
        onDidChange: (callback: (state: WorkspaceState) => void) => () => void
      }
      cli: {
        build: () => Promise<IpcResult<{ success: boolean }>>
        init: () => Promise<IpcResult<{ success: boolean }>>
        check: () => Promise<IpcResult<CheckResult>>
        diff: (params: {
          base: string
          target: string
          includeTestChanges: boolean
        }) => Promise<IpcResult<DiffResult>>
      }
      sdk: {
        fetchPackages: () => Promise<IpcResult<{ root: PackageNode }>>
        queryOutlines: (pkg: string) => Promise<IpcResult<{ package: string; outlines: Outline[] }>>
        query: (params: {
          package: string
          mode: QueryMode
          input: string
          limit?: number
        }) => Promise<IpcResult<{ package: string; mode: string; matches: QueryMatch[] }>>
      }
    }
  }
}
