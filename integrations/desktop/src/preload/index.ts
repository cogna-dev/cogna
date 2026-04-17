import { contextBridge, ipcRenderer } from 'electron'
import { electronAPI } from '@electron-toolkit/preload'

type WorkspaceState = {
  folderPath: string
  displayName: string
  contextSummary: string
  source: 'default' | 'deep-link' | 'renderer'
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
