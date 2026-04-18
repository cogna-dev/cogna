import { contextBridge, ipcRenderer } from 'electron'
import { electronAPI } from '@electron-toolkit/preload'

type WorkspaceState = {
  folderPath: string
  displayName: string
  contextSummary: string
  source: 'default' | 'deep-link' | 'renderer'
}

type IpcSuccess<T> = {
  success: true
  data: T
}

type IpcFailure = {
  success: false
  error: string
}

type IpcResult<T> = IpcSuccess<T> | IpcFailure

type Relation = 'root' | 'workspace' | 'direct' | 'transitive'
type QueryMode = 'exact-id' | 'exact-symbol' | 'fuzzy-text'

type SourceLocation = {
  uri: string
  startLine: number
  endLine: number
}

type PackageNode = {
  name: string
  version?: string
  ecosystem?: string
  relation: Relation
  summary?: string
  children: PackageNode[]
}

type Outline = {
  id: string
  symbol: string
  kind: string
  summary?: string
  deprecated: boolean
  location: SourceLocation
}

type QueryMatch = {
  id: string
  symbol: string
  kind: string
  signature?: string
  summary?: string
  docs?: string
  score?: number
  location: SourceLocation
}

type DiffChange = {
  kind: 'added' | 'removed' | 'changed' | 'deprecated'
  id: string
  symbol: string
  level: string
  message: string
}

type DiffResult = {
  summary: {
    added: number
    removed: number
    changed: number
    deprecated: number
  }
  changes: DiffChange[]
  testChanges: DiffChange[]
}

const api = {
  window: {
    minimize: () => ipcRenderer.send('window:minimize'),
    maximize: () => ipcRenderer.send('window:maximize'),
    close: () => ipcRenderer.send('window:close')
  },
  workspace: {
    getState: (): Promise<WorkspaceState> => ipcRenderer.invoke('workspace:get-state'),
    openFolder: (folderPath: string): void => ipcRenderer.send('workspace:open-folder', folderPath),
    onDidChange: (callback: (state: WorkspaceState) => void): (() => void) => {
      const listener = (_event: Electron.IpcRendererEvent, state: WorkspaceState): void => {
        callback(state)
      }
      ipcRenderer.on('workspace:changed', listener)
      return (): void => {
        ipcRenderer.off('workspace:changed', listener)
      }
    }
  },
  sdk: {
    build: (): Promise<IpcResult<{ success: boolean }>> => ipcRenderer.invoke('sdk:build'),
    diff: (params: {
      base: string
      target: string
      includeTestChanges: boolean
    }): Promise<IpcResult<DiffResult>> => ipcRenderer.invoke('sdk:diff', params),
    fetchPackages: (): Promise<IpcResult<{ root: PackageNode }>> => ipcRenderer.invoke('sdk:fetch-packages'),
    queryOutlines: (pkg: string): Promise<IpcResult<{ package: string; outlines: Outline[] }>> =>
      ipcRenderer.invoke('sdk:query-outlines', pkg),
    query: (params: {
      package: string
      mode: QueryMode
      input: string
      limit?: number
    }): Promise<IpcResult<{ package: string; mode: string; matches: QueryMatch[] }>> =>
      ipcRenderer.invoke('sdk:query', params),
  }
}

if (process.contextIsolated) {
  try {
    contextBridge.exposeInMainWorld('electron', electronAPI)
    contextBridge.exposeInMainWorld('api', api)
  } catch (error) {
    console.error(error)
  }
} else {
  const globalWindow = window as Window & typeof globalThis & {
    electron: typeof electronAPI
    api: typeof api
  }
  globalWindow.electron = electronAPI
  globalWindow.api = api
}
