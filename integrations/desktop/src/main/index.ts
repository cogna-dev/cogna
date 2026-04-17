import { app, shell, BrowserWindow, ipcMain } from 'electron'
import { existsSync, statSync } from 'fs'
import { basename, join, resolve } from 'path'
import { electronApp, optimizer, is } from '@electron-toolkit/utils'
import icon from '../../resources/icon.png?asset'

const APP_ID = 'dev.xaclabs.cogna'
const PROTOCOL_NAME = 'cogna'

type WorkspaceState = {
  folderPath: string
  displayName: string
  contextSummary: string
  source: 'default' | 'deep-link' | 'renderer'
}

let mainWindow: BrowserWindow | null = null
let workspaceState: WorkspaceState = {
  folderPath: '',
  displayName: 'workspace-app',
  contextSummary: 'Current project context resolved from cogna.yml and .cogna/sbom.spdx.json.',
  source: 'default'
}

function focusMainWindow(): void {
  if (!mainWindow) {
    return
  }
  if (mainWindow.isMinimized()) {
    mainWindow.restore()
  }
  mainWindow.focus()
}

function sendWorkspaceState(): void {
  if (!mainWindow || mainWindow.isDestroyed()) {
    return
  }
  const publish = (): void => {
    mainWindow?.webContents.send('workspace:changed', workspaceState)
  }
  if (mainWindow.webContents.isLoadingMainFrame()) {
    mainWindow.webContents.once('did-finish-load', publish)
  } else {
    publish()
  }
}

function workspaceName(folderPath: string): string {
  const trimmed = folderPath.trim()
  if (trimmed.length === 0) {
    return 'workspace-app'
  }
  const name = basename(trimmed)
  return name.length > 0 ? name : 'workspace-app'
}

function resolveWorkspaceState(
  folderPath: string | null | undefined,
  source: WorkspaceState['source']
): WorkspaceState | null {
  if (!folderPath || folderPath.trim().length === 0) {
    return {
      folderPath: '',
      displayName: 'workspace-app',
      contextSummary: 'Current project context resolved from cogna.yml and .cogna/sbom.spdx.json.',
      source: 'default'
    }
  }

  const normalized = resolve(folderPath)
  if (!existsSync(normalized)) {
    return null
  }
  const stat = statSync(normalized)
  if (!stat.isDirectory()) {
    return null
  }

  return {
    folderPath: normalized,
    displayName: workspaceName(normalized),
    contextSummary: `Current project context loaded from ${normalized}.`,
    source
  }
}

function updateWorkspaceFolder(
  folderPath: string | null | undefined,
  source: WorkspaceState['source']
): void {
  const next = resolveWorkspaceState(folderPath, source)
  if (!next) {
    return
  }
  workspaceState = next
  focusMainWindow()
  sendWorkspaceState()
}

function parseDeepLink(url: string): string | null {
  try {
    const parsed = new URL(url)
    if (parsed.protocol !== `${PROTOCOL_NAME}:`) {
      return null
    }
    if (parsed.hostname !== 'open' && parsed.pathname !== '/open') {
      return null
    }
    return parsed.searchParams.get('folder')
  } catch {
    return null
  }
}

function extractDeepLink(argv: string[]): string | null {
  return argv.find((value) => value.startsWith(`${PROTOCOL_NAME}://`)) ?? null
}

function registerProtocol(): void {
  if (process.defaultApp && process.argv.length >= 2) {
    app.setAsDefaultProtocolClient(PROTOCOL_NAME, process.execPath, [resolve(process.argv[1])])
  } else {
    app.setAsDefaultProtocolClient(PROTOCOL_NAME)
  }
}

function handleDeepLink(url: string): void {
  const folder = parseDeepLink(url)
  if (!folder) {
    return
  }
  updateWorkspaceFolder(folder, 'deep-link')
}

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    show: false,
    frame: false,
    titleBarStyle: 'hidden',
    trafficLightPosition: { x: 16, y: 11 },
    autoHideMenuBar: true,
    ...(process.platform === 'linux' ? { icon } : {}),
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  mainWindow.on('ready-to-show', () => {
    mainWindow?.show()
    sendWorkspaceState()
  })
  mainWindow.on('closed', () => {
    mainWindow = null
  })
  mainWindow.webContents.setWindowOpenHandler((details) => {
    shell.openExternal(details.url)
    return { action: 'deny' }
  })

  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    void mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
  } else {
    void mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

registerProtocol()

const gotTheLock = app.requestSingleInstanceLock()

if (!gotTheLock) {
  app.quit()
} else {
  app.on('second-instance', (_event, commandLine) => {
    focusMainWindow()
    const deepLink = extractDeepLink(commandLine)
    if (deepLink) {
      handleDeepLink(deepLink)
    }
  })

  app.on('open-url', (event, url) => {
    event.preventDefault()
    handleDeepLink(url)
  })

  ipcMain.on('window:minimize', () => mainWindow?.minimize())
  ipcMain.on('window:maximize', () => {
    if (!mainWindow) {
      return
    }
    if (mainWindow.isMaximized()) mainWindow.unmaximize()
    else mainWindow.maximize()
  })
  ipcMain.on('window:close', () => mainWindow?.close())
  ipcMain.on('workspace:open-folder', (_event, folderPath: string) => {
    updateWorkspaceFolder(folderPath, 'renderer')
  })
  ipcMain.handle('workspace:get-state', () => workspaceState)

  app.whenReady().then(() => {
    electronApp.setAppUserModelId(APP_ID)
    app.on('browser-window-created', (_, window) => {
      optimizer.watchWindowShortcuts(window)
    })
    createWindow()
    const deepLink = extractDeepLink(process.argv)
    if (deepLink) {
      handleDeepLink(deepLink)
    }
    app.on('activate', function () {
      if (BrowserWindow.getAllWindows().length === 0) createWindow()
      else focusMainWindow()
    })
  })
}

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
