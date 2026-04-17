import { ElectronAPI } from '@electron-toolkit/preload'

interface WorkspaceState {
  folderPath: string
  displayName: string
  contextSummary: string
  source: 'default' | 'deep-link' | 'renderer'
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
        openFolder: (folderPath: string) => void
        onDidChange: (callback: (state: WorkspaceState) => void) => () => void
      }
    }
  }
}
