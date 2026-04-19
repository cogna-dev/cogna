/* eslint-disable */

import { useMemo, useState, useEffect, useCallback } from 'react'
import type { Outline, PackageNode, QueryMatch, QueryMode, DiffResult } from './cogna-ui'
import { queryModes, PackageTree, DiffView } from './cogna-ui'
import {
  CommandDialog,
  CommandInput,
  CommandList,
  CommandGroup,
  CommandItem
} from '@renderer/components/ui/command'
import { Button } from '@renderer/components/ui/button'
import { Badge } from '@renderer/components/ui/badge'
import { Separator } from '@renderer/components/ui/separator'
import { ScrollArea } from '@renderer/components/ui/scroll-area'
import { TooltipProvider } from '@renderer/components/ui/tooltip'
import {
  ChevronRight,
  Folder,
  Search,
  TerminalSquare,
  Loader2,
  CheckCircle2,
  AlertCircle,
  Minus,
  Square,
  X
} from 'lucide-react'

type WorkspaceState = {
  folderPath: string
  displayName: string
  contextSummary: string
  source: 'default' | 'deep-link' | 'renderer'
}

type WorkspaceHealth = {
  hasConfig: boolean
  hasCache: boolean
}

type ToastKind = 'success' | 'error' | 'info'

type ToastMessage = {
  id: number
  kind: ToastKind
  title: string
  description?: string
}

type DetailItem = Outline | QueryMatch
type ExplorerTab = 'outlines' | 'query'
type AppView = 'explorer' | 'changes' | 'policy'

type Relation = 'root' | 'workspace' | 'direct' | 'transitive'

type SourceLocation = {
  uri: string
  startLine: number
  endLine: number
}

type SdkPackageNode = {
  name: string
  version?: string
  ecosystem?: string
  relation: Relation
  summary?: string
  children: SdkPackageNode[]
}

type SdkOutline = {
  id: string
  symbol: string
  kind: string
  summary?: string
  deprecated: boolean
  location: SourceLocation
}

type SdkQueryMatch = {
  id: string
  symbol: string
  kind: string
  signature?: string
  summary?: string
  docs?: string
  score?: number
  location: SourceLocation
}

type SdkDiffChange = {
  kind: 'added' | 'removed' | 'changed' | 'deprecated'
  id: string
  symbol: string
  level: string
  message: string
}

type SdkDiffResult = {
  summary: {
    added: number
    removed: number
    changed: number
    deprecated: number
  }
  changes: SdkDiffChange[]
  testChanges: SdkDiffChange[]
}

type SdkSarifResult = {
  ruleId?: string
  level: 'error' | 'warning' | 'note'
  message: string
  uri: string
  startLine: number
  endLine: number
  helpUri?: string
}

type SdkCheckResult = {
  sarifPath: string
  summary: {
    error: number
    warning: number
    note: number
    total: number
  }
  results: SdkSarifResult[]
}

type SdkResult<T> =
  | { success: true; data: T }
  | { success: false; error: string }

function flattenPackages(root: PackageNode): PackageNode[] {
  const items: PackageNode[] = []
  const visit = (node: PackageNode): void => {
    items.push(node)
    node.children.forEach(visit)
  }
  visit(root)
  return items
}

function isQueryMatch(item: DetailItem): item is QueryMatch {
  return 'signature' in item
}

function defaultWorkspace(folderPath: string): WorkspaceState {
  return {
    folderPath,
    displayName: folderPath.length > 0 ? folderPath.split('/').filter(Boolean).at(-1) ?? 'workspace-app' : 'workspace-app',
    contextSummary:
      folderPath.length > 0
        ? `Current project context loaded from ${folderPath}.`
        : 'Current project context resolved from cogna.yml and .cogna/sbom.spdx.json.',
    source: folderPath.length > 0 ? 'deep-link' : 'default',
  }
}

function mapPackageNode(node: SdkPackageNode): PackageNode {
  return {
    name: node.name,
    version: node.version,
    ecosystem: node.ecosystem,
    relation: node.relation,
    summary: node.summary,
    children: node.children.map(mapPackageNode),
  }
}

function mapLocation(location: SourceLocation): { uri: string; startLine: number; endLine: number } {
  return {
    uri: location.uri,
    startLine: location.startLine,
    endLine: location.endLine,
  }
}

function mapOutline(item: SdkOutline): Outline {
  return {
    id: item.id,
    symbol: item.symbol,
    kind: item.kind,
    summary: item.summary ?? '',
    deprecated: item.deprecated,
    location: mapLocation(item.location),
  }
}

function mapQueryMatch(item: SdkQueryMatch): QueryMatch {
  return {
    id: item.id,
    symbol: item.symbol,
    kind: item.kind,
    signature: item.signature,
    summary: item.summary ?? '',
    docs: item.docs,
    score: item.score,
    location: mapLocation(item.location),
  }
}

function mapDiffResult(result: SdkDiffResult): DiffResult {
  return {
    base: 'base',
    target: 'target',
    summary: result.summary,
    changes: result.changes.map((change) => ({
      ...change,
      location: { uri: change.symbol, startLine: 1, endLine: 1 },
    })),
    testChanges: result.testChanges.map((change) => ({
      ...change,
      location: { uri: change.symbol, startLine: 1, endLine: 1 },
    })),
  }
}

type OutlineGroupNode = {
  key: string
  label: string
  count: number
  children: OutlineGroupNode[]
}

function normalizeKind(kind: string): string {
  const value = kind.trim()
  return value.length > 0 ? value : 'unknown'
}

function kindPrefix(kind: string): string {
  const lower = kind.toLowerCase()
  if (lower.includes('func') || lower.includes('method') || lower.includes('operation')) return 'func'
  if (lower.includes('type') || lower.includes('struct') || lower.includes('class')) return 'type'
  if (lower.includes('interface')) return 'interface'
  if (lower.includes('const')) return 'const'
  if (lower.includes('var') || lower.includes('field') || lower.includes('property')) return 'var'
  return 'symbol'
}

function humanizedTail(raw: string): string {
  const value = raw.trim()
  if (!value) return 'Unknown'
  const stripped = value.replace(/^decl:[^:]*:/, '').replace(/^pkg:[^/]+\//, '')
  const parts = stripped.split(/[#:\s/]+/).filter(Boolean)
  if (parts.length === 0) return stripped
  const tail = parts[parts.length - 1]
  return tail || stripped
}

function readableSymbol(kind: string, symbol: string, id: string): string {
  const source = symbol.trim().length > 0 ? symbol : id
  return `${kindPrefix(kind)} ${humanizedTail(source)}`
}

function isOpenApiPackageNode(pkg: PackageNode): boolean {
  const eco = (pkg.ecosystem ?? '').toLowerCase()
  const name = pkg.name.toLowerCase()
  return eco.includes('openapi') || name.includes('openapi')
}

function extractOpenApiPath(item: Outline): string | null {
  const candidates = [item.location.uri, item.symbol, item.id]
  const matcher = /(\/[-a-zA-Z0-9._~%!$&'()*+,;=:@{}]+(?:\/[-a-zA-Z0-9._~%!$&'()*+,;=:@{}]+)*)/
  for (const text of candidates) {
    if (!text) continue
    const m = text.match(matcher)
    if (m && m[1].startsWith('/')) {
      return m[1]
    }
  }
  return null
}

function buildOpenApiGroupTree(items: Outline[]): OutlineGroupNode[] {
  const roots: OutlineGroupNode[] = []
  const map = new Map<string, OutlineGroupNode>()

  const getOrCreate = (key: string, label: string): OutlineGroupNode => {
    const found = map.get(key)
    if (found) {
      return found
    }
    const node: OutlineGroupNode = { key, label, count: 0, children: [] }
    map.set(key, node)
    return node
  }

  for (const item of items) {
    const path = extractOpenApiPath(item)
    if (!path) {
      const other = getOrCreate('other', 'Other')
      other.count += 1
      if (!roots.includes(other)) {
        roots.push(other)
      }
      continue
    }

    const segments = path.split('/').filter(Boolean)
    if (segments.length === 0) continue

    let parent: OutlineGroupNode | null = null
    let currentPath = ''
    for (const seg of segments) {
      currentPath += `/${seg}`
      const key = `path:${currentPath}`
      const node = getOrCreate(key, seg)
      node.count += 1
      if (parent === null) {
        if (!roots.includes(node)) {
          roots.push(node)
        }
      } else if (!parent.children.includes(node)) {
        parent.children.push(node)
      }
      parent = node
    }
  }

  const sortNode = (node: OutlineGroupNode): void => {
    node.children.sort((a, b) => a.label.localeCompare(b.label))
    node.children.forEach(sortNode)
  }

  roots.sort((a, b) => a.label.localeCompare(b.label))
  roots.forEach(sortNode)
  return roots
}

function renderOutlineGroupNode(
  node: OutlineGroupNode,
  selectedKey: string | null,
  onSelect: (key: string) => void,
  depth = 0,
): React.JSX.Element {
  const isSelected = selectedKey === node.key
  const isPath = node.key.startsWith('path:')

  return (
    <div key={node.key} className="space-y-1">
      <button
        type="button"
        onClick={() => onSelect(node.key)}
        className={`w-full flex items-center justify-between rounded-md px-2 py-1.5 text-xs transition-colors ${
          isSelected
            ? 'bg-accent text-accent-foreground font-medium'
            : 'text-muted-foreground hover:bg-muted hover:text-foreground'
        }`}
      >
        <span className="truncate" style={{ paddingLeft: `${depth * 12}px` }}>
          {isPath ? `/${node.label}` : node.label}
        </span>
        <span className="font-mono">{node.count}</span>
      </button>

      {node.children.map((child) => renderOutlineGroupNode(child, selectedKey, onSelect, depth + 1))}
    </div>
  )
}

function App(): React.JSX.Element {
  const [workspaceState, setWorkspaceState] = useState<WorkspaceState>(() => defaultWorkspace(''))
  const [packagesRoot, setPackagesRoot] = useState<PackageNode>({
    name: 'workspace-app',
    relation: 'root',
    children: [],
  })
  const packageList = useMemo(() => flattenPackages(packagesRoot), [packagesRoot])
  const [selectedPackageName, setSelectedPackageName] = useState('workspace-app')
  const [tab, setTab] = useState<ExplorerTab>('outlines')
  const [queryMode, setQueryMode] = useState<QueryMode>('fuzzy-text')
  const [queryText, setQueryText] = useState('effect cleanup')
  const [selectedDetailId, setSelectedDetailId] = useState<string | null>(null)
  const [selectedOutlineGroupKey, setSelectedOutlineGroupKey] = useState<string | null>(null)
  const [appView, setAppView] = useState<AppView>('explorer')
  const [policyTab, setPolicyTab] = useState<'loaded-policy'>('loaded-policy')
  const [commandOpen, setCommandOpen] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [workspaceHealth, setWorkspaceHealth] = useState<WorkspaceHealth>({ hasConfig: false, hasCache: false })
  const [isBootstrapping, setIsBootstrapping] = useState(true)
  const [isBuilding, setIsBuilding] = useState(false)
  const [isInitializing, setIsInitializing] = useState(false)
  const [outlinesByPackage, setOutlinesByPackage] = useState<Record<string, Outline[]>>({})
  const [queryMatchesByPackage, setQueryMatchesByPackage] = useState<Record<string, QueryMatch[]>>({})
  const [diffResult, setDiffResult] = useState<DiffResult | null>(null)
  const [checkResult, setCheckResult] = useState<SdkCheckResult | null>(null)
  const [isChecking, setIsChecking] = useState(false)
  const [toasts, setToasts] = useState<ToastMessage[]>([])

  const pushToast = useCallback((kind: ToastKind, title: string, description?: string): number => {
    const id = Date.now() + Math.floor(Math.random() * 1000)
    setToasts((current) => [...current, { id, kind, title, description }])
    window.setTimeout(() => {
      setToasts((current) => current.filter((item) => item.id !== id))
    }, 3600)
    return id
  }, [])

  const removeToast = useCallback((id: number) => {
    setToasts((current) => current.filter((item) => item.id !== id))
  }, [])

  const refreshWorkspaceData = useCallback(async () => {
    setIsBootstrapping(true)
    try {
      const ws = await window.api.workspace.getState()
      setWorkspaceState(ws)

      const health = await window.api.workspace.getHealth()
      setWorkspaceHealth(health)

      if (!health.hasCache) {
        setPackagesRoot({
          name: ws.displayName || 'workspace-app',
          relation: 'root',
          children: [],
        })
        setOutlinesByPackage({})
        setQueryMatchesByPackage({})
        setDiffResult(null)
        setCheckResult(null)
        setErrorMessage('')
        return
      }

      const packagesOut: SdkResult<{ root: SdkPackageNode }> = await window.api.sdk.fetchPackages()
      if (packagesOut.success) {
        setPackagesRoot(mapPackageNode(packagesOut.data.root))
        setErrorMessage('')
      } else {
        setErrorMessage(packagesOut.error)
      }
    } finally {
      setIsBootstrapping(false)
    }
  }, [])

  const selectedPackage = useMemo(
    () => packageList.find((item) => item.name === selectedPackageName) ?? packageList[0] ?? packagesRoot,
    [packageList, selectedPackageName, packagesRoot]
  )

  const outlines = useMemo(
    () => outlinesByPackage[selectedPackage.name] ?? [],
    [outlinesByPackage, selectedPackage.name]
  )

  const isOpenApiSelected = useMemo(() => isOpenApiPackageNode(selectedPackage), [selectedPackage])

  const outlineGroups = useMemo(() => {
    if (isOpenApiSelected) {
      return buildOpenApiGroupTree(outlines)
    }
    const byKind = new Map<string, number>()
    for (const item of outlines) {
      const kind = normalizeKind(item.kind)
      byKind.set(kind, (byKind.get(kind) ?? 0) + 1)
    }
    return Array.from(byKind.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([kind, count]) => ({ key: `kind:${kind}`, label: kind, count, children: [] as OutlineGroupNode[] }))
  }, [isOpenApiSelected, outlines])

  const filteredOutlines = useMemo(() => {
    if (!selectedOutlineGroupKey) return outlines

    if (selectedOutlineGroupKey.startsWith('kind:')) {
      const kind = selectedOutlineGroupKey.slice(5)
      return outlines.filter((item) => normalizeKind(item.kind) === kind)
    }

    if (selectedOutlineGroupKey === 'other') {
      return outlines.filter((item) => extractOpenApiPath(item) === null)
    }

    if (selectedOutlineGroupKey.startsWith('path:')) {
      const prefix = selectedOutlineGroupKey.slice(5)
      return outlines.filter((item) => {
        const path = extractOpenApiPath(item)
        return path ? path.startsWith(prefix) : false
      })
    }

    return outlines
  }, [outlines, selectedOutlineGroupKey])

  const groupedOutlines = useMemo(() => {
    const groups = new Map<string, Outline[]>()
    for (const item of filteredOutlines) {
      const key = normalizeKind(item.kind)
      groups.set(key, [...(groups.get(key) ?? []), item])
    }
    return Array.from(groups.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([kind, items]) => ({ kind, items }))
  }, [filteredOutlines])

  const queryResponse = useMemo(
    () => ({
      package: selectedPackage.name,
      mode: queryMode,
      matches: queryMatchesByPackage[selectedPackage.name] ?? [],
    }),
    [queryMatchesByPackage, selectedPackage.name, queryMode]
  )

  const groupedQueryMatches = useMemo(() => {
    const groups = new Map<string, QueryMatch[]>()
    for (const item of queryResponse.matches) {
      const key = normalizeKind(item.kind)
      groups.set(key, [...(groups.get(key) ?? []), item])
    }
    return Array.from(groups.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([kind, items]) => ({ kind, items }))
  }, [queryResponse.matches])

  const activeDetail = useMemo<DetailItem | null>(() => {
    if (tab === 'outlines') {
      return filteredOutlines.find((item) => item.id === selectedDetailId) ?? filteredOutlines[0] ?? null
    }
    return (
      queryResponse.matches.find((item) => item.id === selectedDetailId) ??
      queryResponse.matches[0] ??
      null
    )
  }, [filteredOutlines, queryResponse.matches, selectedDetailId, tab])

  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === 'k' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        setCommandOpen((open) => !open)
      }
    }
    document.addEventListener('keydown', down)
    return () => document.removeEventListener('keydown', down)
  }, [])

  useEffect(() => {
    let active = true
    void refreshWorkspaceData()
    const dispose = window.api.workspace.onDidChange(() => {
      if (!active) return
      void refreshWorkspaceData()
    })
    return () => {
      active = false
      dispose()
    }
  }, [refreshWorkspaceData])

  useEffect(() => {
    if (!workspaceHealth.hasCache) {
      return
    }
    if (!selectedPackage.name) {
      return
    }
    void window.api.sdk.queryOutlines(selectedPackage.name).then((result) => {
      if (result.success) {
        setOutlinesByPackage((current) => ({
          ...current,
          [selectedPackage.name]: result.data.outlines.map(mapOutline),
        }))
        setErrorMessage('')
      } else {
        setErrorMessage(result.error)
      }
    })
  }, [selectedPackage.name, workspaceHealth.hasCache])

  useEffect(() => {
    if (!workspaceHealth.hasCache) {
      return
    }
    if (queryText.trim().length === 0) {
      setQueryMatchesByPackage((current) => ({
        ...current,
        [selectedPackage.name]: [],
      }))
      return
    }
    void window.api.sdk
      .query({
        package: selectedPackage.name,
        mode: queryMode,
        input: queryText,
        limit: 5,
      })
      .then((result) => {
        if (result.success) {
          setQueryMatchesByPackage((current) => ({
            ...current,
            [selectedPackage.name]: result.data.matches.map(mapQueryMatch),
          }))
          setErrorMessage('')
        } else {
          setErrorMessage(result.error)
        }
      })
  }, [selectedPackage.name, queryMode, queryText, workspaceHealth.hasCache])

  useEffect(() => {
    setSelectedPackageName(packageList[0]?.name ?? 'workspace-app')
    setSelectedDetailId(null)
    setSelectedOutlineGroupKey(null)
  }, [packageList])

  useEffect(() => {
    setSelectedOutlineGroupKey(null)
  }, [selectedPackage.name])

  const isMac = useMemo(() => window.navigator.platform.toUpperCase().indexOf('MAC') >= 0, [])

  const resolveCliApi = useCallback(() => {
    const api = window.api as typeof window.api & {
      cli?: {
        build?: () => Promise<SdkResult<{ success: boolean }>>
        init?: () => Promise<SdkResult<{ success: boolean }>>
        check?: () => Promise<SdkResult<SdkCheckResult>>
        diff?: (params: {
          base: string
          target: string
          includeTestChanges: boolean
        }) => Promise<SdkResult<SdkDiffResult>>
      }
      sdk?: {
        build?: () => Promise<SdkResult<{ success: boolean }>>
        init?: () => Promise<SdkResult<{ success: boolean }>>
        check?: () => Promise<SdkResult<SdkCheckResult>>
        diff?: (params: {
          base: string
          target: string
          includeTestChanges: boolean
        }) => Promise<SdkResult<SdkDiffResult>>
      }
    }

    const build = api.cli?.build ?? api.sdk?.build
    const init = api.cli?.init ?? api.sdk?.init
    const check = api.cli?.check ?? api.sdk?.check
    const diff = api.cli?.diff ?? api.sdk?.diff

    return { build, init, check, diff }
  }, [])

  const handleBuild = async (): Promise<void> => {
    if (isBuilding) {
      return
    }
    setIsBuilding(true)
    const loadingToastId = pushToast('info', 'Build started', 'Running cogna build in current workspace.')
    try {
      const { build } = resolveCliApi()
      if (!build) {
        const message = 'Desktop command API is not available. Please restart `pnpm dev` to refresh preload/main process.'
        setErrorMessage(message)
        pushToast('error', 'Build failed', message)
        return
      }
      const out = await build()
      if (out.success) {
        pushToast('success', 'Build finished', 'Workspace cache artifacts are ready.')
        setErrorMessage('')
        await refreshWorkspaceData()
        return
      }
      setErrorMessage(out.error)
      pushToast('error', 'Build failed', out.error)
    } finally {
      removeToast(loadingToastId)
      setIsBuilding(false)
    }
  }

  const handleInit = async (): Promise<void> => {
    if (isInitializing) {
      return
    }
    setIsInitializing(true)
    const loadingToastId = pushToast('info', 'Init started', 'Creating cogna.yaml in current workspace.')
    try {
      const { init } = resolveCliApi()
      if (!init) {
        const message = 'Desktop command API is not available. Please restart `pnpm dev` to refresh preload/main process.'
        setErrorMessage(message)
        pushToast('error', 'Init failed', message)
        return
      }
      const out = await init()
      if (!out.success) {
        setErrorMessage(out.error)
        pushToast('error', 'Init failed', out.error)
        return
      }
      setErrorMessage('')
      pushToast('success', 'Init finished', 'Configuration file created successfully.')
      await refreshWorkspaceData()
    } finally {
      removeToast(loadingToastId)
      setIsInitializing(false)
    }
  }

  const handleCheck = async (): Promise<void> => {
    if (isChecking) {
      return
    }
    setIsChecking(true)
    const loadingToastId = pushToast('info', 'Check started', 'Running cogna check and reading SARIF report.')
    try {
      const { check } = resolveCliApi()
      if (!check) {
        const message = 'Desktop command API is not available. Please restart `pnpm dev` to refresh preload/main process.'
        setErrorMessage(message)
        pushToast('error', 'Check failed', message)
        return
      }
      const out = await check()
      if (!out.success) {
        setErrorMessage(out.error)
        pushToast('error', 'Check failed', out.error)
        return
      }
      setCheckResult(out.data)
      setErrorMessage('')
      pushToast('success', 'Check finished', `${out.data.summary.total} findings loaded from SARIF.`)
    } finally {
      removeToast(loadingToastId)
      setIsChecking(false)
    }
  }

  const handleDiffRun = async (params: {
    base: string
    target: string
    includeTestChanges: boolean
  }): Promise<DiffResult | null> => {
    const loadingToastId = pushToast('info', 'Changes started', 'Running cogna diff for selected base/target.')
    try {
      const { diff } = resolveCliApi()
      if (!diff) {
        const message = 'Desktop command API is not available. Please restart `pnpm dev` to refresh preload/main process.'
        setErrorMessage(message)
        pushToast('error', 'Changes failed', message)
        return null
      }
      const out = await diff(params)
      if (!out.success) {
        setErrorMessage(out.error)
        pushToast('error', 'Changes failed', out.error)
        return null
      }
      const mapped = {
        ...mapDiffResult(out.data),
        base: params.base,
        target: params.target,
      }
      setDiffResult(mapped)
      setErrorMessage('')
      pushToast('success', 'Changes finished', `${mapped.summary.changed + mapped.summary.added + mapped.summary.removed} changes computed.`)
      return mapped
    } finally {
      removeToast(loadingToastId)
    }
  }

  return (
    <TooltipProvider>
      <div className="h-screen flex flex-col bg-background text-foreground overflow-hidden font-sans">
        <header
          className={`h-[38px] grid items-center border-b border-border flex-shrink-0 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 ${isMac ? 'pl-[72px]' : 'pl-4'}`}
          style={{ WebkitAppRegion: 'drag', gridTemplateColumns: '1fr auto 1fr' } as React.CSSProperties}
        >
          <div className="min-w-0 px-4 flex flex-col justify-center">
            <span className="text-xs font-semibold text-foreground truncate">
              {workspaceState.displayName}
            </span>
            <span className="text-[10px] text-muted-foreground truncate">
              {workspaceState.folderPath || workspaceState.contextSummary}
            </span>
          </div>

          <div className="flex bg-muted p-0.5 rounded-lg" style={{ WebkitAppRegion: 'no-drag' } as React.CSSProperties}>
            <button
              className={`px-3 py-1 text-xs font-medium rounded-md transition-all ${
                appView === 'explorer' ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'
              }`}
              onClick={() => setAppView('explorer')}
              type="button"
            >
              Explorer
            </button>
            <button
              className={`px-3 py-1 text-xs font-medium rounded-md transition-all ${
                appView === 'changes' ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'
              }`}
              onClick={() => setAppView('changes')}
              type="button"
            >
              Reviewer
            </button>
            <button
              className={`px-3 py-1 text-xs font-medium rounded-md transition-all ${
                appView === 'policy' ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'
              }`}
              onClick={() => setAppView('policy')}
              type="button"
            >
              Gate
            </button>
          </div>

          <div
            className="flex items-center justify-end gap-2 pr-2 h-full"
            style={{ WebkitAppRegion: 'no-drag' } as React.CSSProperties}
          >
            <Button
              variant="outline"
              size="sm"
              className="h-6 px-2 py-0 text-xs justify-between text-muted-foreground shadow-sm border-border/40"
              onClick={() => setCommandOpen(true)}
            >
              <span className="flex items-center gap-1.5">
                <Search className="w-3 h-3" />
                <kbd className="pointer-events-none inline-flex h-4 select-none items-center gap-0.5 rounded border bg-muted px-1 font-mono text-[9px] font-medium text-muted-foreground opacity-100">
                  <span>⌘</span>K
                </kbd>
              </span>
            </Button>

            {!isMac && (
              <div className="flex items-center h-full ml-2">
                <button
                  onClick={() => window.api.window.minimize()}
                  className="h-full px-3 hover:bg-accent text-muted-foreground transition-colors"
                  type="button"
                >
                  <Minus className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={() => window.api.window.maximize()}
                  className="h-full px-3 hover:bg-accent text-muted-foreground transition-colors"
                  type="button"
                >
                  <Square className="w-3 h-3" />
                </button>
                <button
                  onClick={() => window.api.window.close()}
                  className="h-full px-3 hover:bg-destructive hover:text-destructive-foreground text-muted-foreground transition-colors"
                  type="button"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>
        </header>

        {errorMessage.length > 0 && (
          <div className="px-4 py-2 text-xs text-red-500 border-b border-border bg-red-500/5">{errorMessage}</div>
        )}

        {(!workspaceHealth.hasConfig || !workspaceHealth.hasCache || isBootstrapping) ? (
          <div className="flex flex-1 items-center justify-center px-6">
            <div className="w-full max-w-xl rounded-2xl border bg-card p-8 text-center shadow-sm flex flex-col items-center gap-4">
              {isBootstrapping ? (
                <>
                  <Loader2 className="size-10 animate-spin text-primary" />
                  <h2 className="text-xl font-semibold">Loading workspace</h2>
                  <p className="text-sm text-muted-foreground">Resolving configuration and cache status…</p>
                </>
              ) : !workspaceHealth.hasConfig ? (
                <>
                  <h2 className="text-xl font-semibold">Initialize this workspace first</h2>
                  <p className="text-sm text-muted-foreground">
                    No cogna.yaml found in the current workspace. Create it before using Explorer, Reviewer, and Gate.
                  </p>
                  <Button size="lg" className="min-w-40" onClick={() => void handleInit()} disabled={isInitializing}>
                    {isInitializing && <Loader2 className="mr-2 h-4 w-4 animate-spin" data-icon="inline-start" />}
                    Init
                  </Button>
                </>
              ) : (
                <>
                  <h2 className="text-xl font-semibold">Build cache artifacts</h2>
                  <p className="text-sm text-muted-foreground">
                    Workspace has config, but no local cache artifacts were found. Run Build to prepare package/index data.
                  </p>
                  <Button size="lg" className="min-w-40" onClick={() => void handleBuild()} disabled={isBuilding}>
                    {isBuilding && <Loader2 className="mr-2 h-4 w-4 animate-spin" data-icon="inline-start" />}
                    Build
                  </Button>
                </>
              )}
            </div>
          </div>
        ) : appView === 'explorer' ? (
          <div className="flex flex-1 overflow-hidden">
            <aside className="w-[240px] flex-shrink-0 border-r border-border flex flex-col bg-muted/20">
              <div className="h-10 flex items-center px-4 border-b border-border/50 bg-background/50">
                <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Packages</h2>
              </div>
              <ScrollArea className="flex-1">
                <div className="p-3">
                  <PackageTree
                    node={packagesRoot}
                    selected={selectedPackage.name}
                    onSelect={(name) => {
                      setSelectedPackageName(name)
                      setSelectedDetailId(null)
                    }}
                  />

                  <Separator className="my-3" />

                  <div className="space-y-1">
                    <div className="flex items-center justify-between px-2">
                      <span className="text-[10px] uppercase tracking-wider text-muted-foreground">Groups</span>
                      <Badge variant="outline" className="h-4 px-1 text-[10px]">
                        {outlineGroups.length}
                      </Badge>
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        setSelectedOutlineGroupKey(null)
                        setSelectedDetailId(null)
                      }}
                      className={`w-full flex items-center justify-between rounded-md px-2 py-1.5 text-xs transition-colors ${
                        selectedOutlineGroupKey === null
                          ? 'bg-accent text-accent-foreground font-medium'
                          : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                      }`}
                    >
                      <span>All symbols</span>
                      <span className="font-mono">{outlines.length}</span>
                    </button>

                    {outlineGroups.map((group) =>
                      renderOutlineGroupNode(
                        group,
                        selectedOutlineGroupKey,
                        (key) => {
                          setSelectedOutlineGroupKey(key)
                          setSelectedDetailId(null)
                        },
                      )
                    )}
                  </div>
                </div>
              </ScrollArea>
            </aside>

            <section className="flex-1 flex flex-col border-r border-border overflow-hidden bg-background">
              <div className="h-10 flex items-center justify-between px-4 border-b border-border flex-shrink-0">
                <div className="flex items-center gap-2">
                  <h2 className="text-sm font-semibold">{selectedPackage.name}</h2>
                  {selectedPackage.ecosystem && (
                    <Badge variant="outline" className="h-5 px-1.5 text-[10px] text-muted-foreground">
                      {selectedPackage.ecosystem}
                    </Badge>
                  )}
                  <Badge variant="outline" className="h-5 px-1.5 text-[10px] text-muted-foreground">
                    {tab === 'outlines' ? 'Outlines' : 'Query'}
                  </Badge>
                </div>

                <div className="flex items-center gap-2">
                  <Button size="sm" className="h-7 px-2" onClick={() => void handleBuild()} disabled={isBuilding}>
                    {isBuilding && <Loader2 className="mr-2 h-3.5 w-3.5 animate-spin" data-icon="inline-start" />}
                    Build
                  </Button>
                  <div className="flex bg-muted p-0.5 rounded-lg">
                    <button
                      className={`px-3 py-1 text-xs font-medium rounded-md transition-all ${tab === 'outlines' ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'}`}
                      onClick={() => {
                        setTab('outlines')
                        setSelectedDetailId(null)
                      }}
                      type="button"
                    >
                      Outlines
                    </button>
                    <button
                      className={`px-3 py-1 text-xs font-medium rounded-md transition-all ${tab === 'query' ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'}`}
                      onClick={() => {
                        setTab('query')
                        setSelectedDetailId(null)
                      }}
                      type="button"
                    >
                      Query
                    </button>
                  </div>
                </div>
              </div>

              {tab === 'outlines' ? (
                <ScrollArea className="flex-1">
                  <div className="p-4 flex flex-col gap-2">
                    {filteredOutlines.length === 0 ? (
                      <div className="text-center py-8 text-sm text-muted-foreground">No outlines found.</div>
                    ) : (
                      groupedOutlines.map((group) => (
                        <div key={group.kind} className="space-y-2">
                          <div className="flex items-center justify-between px-1">
                            <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">{group.kind}</span>
                            <Badge variant="outline" className="h-4 px-1 text-[10px]">
                              {group.items.length}
                            </Badge>
                          </div>

                          {group.items.map((item) => (
                            <button
                              key={item.id}
                              className={`flex flex-col p-3 rounded-lg border text-left transition-all ${
                                selectedDetailId === item.id
                                  ? 'bg-accent/50 border-accent-foreground/20 ring-1 ring-ring'
                                  : 'bg-card border-border hover:border-accent-foreground/20'
                              }`}
                              onClick={() => setSelectedDetailId(item.id)}
                              type="button"
                            >
                              <div className="flex items-center justify-between w-full mb-1">
                                <span className="text-sm font-semibold text-primary truncate">
                                  {readableSymbol(item.kind, item.symbol, item.id)}
                                </span>
                                <Badge variant="secondary" className="text-[10px] h-5">
                                  {item.kind}
                                </Badge>
                              </div>
                              <p className="text-xs text-muted-foreground line-clamp-1 mb-2">{item.summary}</p>
                              <div className="flex items-center gap-2 text-[10px] text-muted-foreground/70">
                                {item.deprecated && (
                                  <Badge variant="destructive" className="h-4 px-1">
                                    Deprecated
                                  </Badge>
                                )}
                                <span className="font-mono truncate">{item.location.uri}</span>
                              </div>
                            </button>
                          ))}
                        </div>
                      ))
                    )}
                  </div>
                </ScrollArea>
              ) : (
                <div className="flex flex-col h-full">
                  <div className="p-4 border-b border-border/50 bg-muted/10 space-y-3 shrink-0">
                    <div className="flex gap-2">
                      {queryModes.map((mode) => (
                        <button
                          key={mode.value}
                          className={`px-3 py-1.5 text-xs font-medium rounded-md border transition-colors ${
                            queryMode === mode.value
                              ? 'bg-primary text-primary-foreground border-primary'
                              : 'bg-background text-muted-foreground border-border hover:bg-accent hover:text-foreground'
                          }`}
                          onClick={() => {
                            setQueryMode(mode.value)
                            setSelectedDetailId(null)
                          }}
                          type="button"
                        >
                          {mode.label}
                        </button>
                      ))}
                    </div>
                    <div className="relative">
                      <Search className="absolute left-2.5 top-2 h-4 w-4 text-muted-foreground" />
                      <input
                        className="w-full h-8 pl-9 pr-3 rounded-md border border-input bg-background text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                        value={queryText}
                        onChange={(event) => setQueryText(event.target.value)}
                        placeholder={queryModes.find((mode) => mode.value === queryMode)?.placeholder}
                      />
                    </div>
                    <div className="flex items-center justify-between text-xs text-muted-foreground">
                      <span>{queryResponse.matches.length} matches found</span>
                      <span className="font-mono">{queryResponse.mode} mode</span>
                    </div>
                  </div>

                  <ScrollArea className="flex-1">
                    <div className="p-4 flex flex-col gap-2">
                      {queryResponse.matches.length > 0 ? (
                        groupedQueryMatches.map((group) => (
                          <div key={group.kind} className="space-y-2">
                            <div className="flex items-center justify-between px-1">
                              <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">{group.kind}</span>
                              <Badge variant="outline" className="h-4 px-1 text-[10px]">
                                {group.items.length}
                              </Badge>
                            </div>

                            {group.items.map((item) => (
                              <button
                                key={item.id}
                                className={`flex flex-col p-3 rounded-lg border text-left transition-all ${
                                  selectedDetailId === item.id
                                    ? 'bg-accent/50 border-accent-foreground/20 ring-1 ring-ring'
                                    : 'bg-card border-border hover:border-accent-foreground/20'
                                }`}
                                onClick={() => setSelectedDetailId(item.id)}
                                type="button"
                              >
                                <div className="flex items-center justify-between w-full mb-1">
                                  <span className="text-sm font-semibold text-primary truncate">
                                    {readableSymbol(item.kind, item.symbol, item.id)}
                                  </span>
                                  <Badge variant="secondary" className="text-[10px] h-5">
                                    {item.kind}
                                  </Badge>
                                </div>
                                <p className="text-xs text-muted-foreground line-clamp-1 mb-2">{item.summary}</p>
                                <div className="flex items-center gap-2 text-[10px] text-muted-foreground/70 font-mono">
                                  {item.score !== undefined ? (
                                    <span className="bg-muted px-1 rounded">Score: {item.score.toFixed(2)}</span>
                                  ) : (
                                    <span className="bg-muted px-1 rounded">Exact match</span>
                                  )}
                                  <span className="truncate">{item.location.uri}</span>
                                </div>
                              </button>
                            ))}
                          </div>
                        ))
                      ) : (
                        <div className="text-center py-12 flex flex-col items-center">
                          <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center mb-3">
                            <Search className="w-5 h-5 text-muted-foreground/50" />
                          </div>
                          <h3 className="text-sm font-medium mb-1">No matches</h3>
                          <p className="text-xs text-muted-foreground max-w-[250px]">
                            Try a different query mode or switch packages.
                          </p>
                        </div>
                      )}
                    </div>
                  </ScrollArea>
                </div>
              )}
            </section>

            <aside className="w-[340px] flex-shrink-0 flex flex-col overflow-hidden bg-card/50">
              <div className="h-10 flex items-center px-4 border-b border-border bg-background/50">
                <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Details</h2>
              </div>

              <ScrollArea className="flex-1">
                {activeDetail ? (
                  <div className="p-5 flex flex-col gap-6">
                    <div>
                      <h3 className="text-lg font-bold text-foreground mb-2 break-all">
                        {readableSymbol(activeDetail.kind, activeDetail.symbol, activeDetail.id)}
                      </h3>
                      <div className="flex flex-wrap gap-2">
                        <Badge variant="outline">{activeDetail.kind}</Badge>
                        {isQueryMatch(activeDetail) && activeDetail.score !== undefined && (
                          <Badge variant="secondary">Score: {activeDetail.score.toFixed(2)}</Badge>
                        )}
                        {'deprecated' in activeDetail && activeDetail.deprecated && (
                          <Badge variant="destructive">Deprecated</Badge>
                        )}
                      </div>
                    </div>

                    <Separator />

                    <div className="space-y-4">
                      <div className="grid grid-cols-[80px_1fr] gap-x-2 gap-y-3 text-sm">
                        <span className="text-muted-foreground">Symbol</span>
                        <code className="font-mono text-xs bg-muted px-1.5 py-0.5 rounded break-all">
                          {activeDetail.symbol}
                        </code>

                        <span className="text-muted-foreground">ID</span>
                        <code className="font-mono text-xs bg-muted px-1.5 py-0.5 rounded break-all">
                          {activeDetail.id}
                        </code>

                        <span className="text-muted-foreground">Location</span>
                        <span className="font-mono text-xs break-all">
                          {activeDetail.location.uri}:{activeDetail.location.startLine}-{activeDetail.location.endLine}
                        </span>
                      </div>
                    </div>

                    <Separator />

                    {isQueryMatch(activeDetail) && activeDetail.signature && (
                      <div className="space-y-2">
                        <span className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Signature</span>
                        <pre className="p-3 rounded-md bg-muted/50 border border-border/50 text-xs font-mono overflow-x-auto whitespace-pre-wrap">
                          {activeDetail.signature}
                        </pre>
                      </div>
                    )}

                    <div className="space-y-2">
                      <span className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Summary</span>
                      <p className="text-sm leading-relaxed text-foreground/90">{activeDetail.summary}</p>
                    </div>

                    {isQueryMatch(activeDetail) && activeDetail.docs && (
                      <div className="space-y-2">
                        <span className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">Documentation</span>
                        <div className="p-3 rounded-md bg-accent/20 border border-accent/20 text-sm leading-relaxed prose prose-sm dark:prose-invert">
                          {activeDetail.docs}
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="h-full flex items-center justify-center p-8 text-center text-muted-foreground">
                    <div className="flex flex-col items-center gap-2">
                      <ChevronRight className="w-8 h-8 opacity-20" />
                      <p className="text-sm">Select an outline or query result to inspect its details.</p>
                    </div>
                  </div>
                )}
              </ScrollArea>
            </aside>
          </div>
        ) : appView === 'changes' ? (
          <DiffView initialResult={diffResult} onRunDiff={handleDiffRun} />
        ) : (
          <div className="flex flex-col flex-1 overflow-hidden bg-background">
            <div className="h-10 flex items-center justify-between px-4 border-b border-border flex-shrink-0">
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-semibold">Policy</h2>
                <Badge variant="outline" className="h-5 px-1.5 text-[10px] text-muted-foreground">
                  {policyTab === 'loaded-policy' ? 'Loaded Policy' : 'Policy'}
                </Badge>
              </div>
              <Button size="sm" className="h-7 px-2" onClick={() => void handleCheck()} disabled={isChecking}>
                {isChecking && <Loader2 className="mr-2 h-3.5 w-3.5 animate-spin" data-icon="inline-start" />}
                {isChecking ? 'Checking…' : 'Check'}
              </Button>
            </div>
            <div className="h-10 px-4 border-b border-border/50 flex items-center gap-2">
              <button
                type="button"
                className="px-3 py-1 text-xs font-medium rounded-md bg-background border border-border"
                onClick={() => setPolicyTab('loaded-policy')}
              >
                Loaded Policy
              </button>
              <span className="text-xs text-muted-foreground truncate">
                {workspaceState.folderPath ? `${workspaceState.folderPath}/.cogna/policies` : '.cogna/policies'}
              </span>
            </div>
            {checkResult ? (
              <div className="flex flex-col flex-1 overflow-hidden">
                <div className="flex items-center gap-4 px-4 py-2 border-b border-border/50 bg-muted/5 shrink-0 text-xs">
                  <span className="text-red-400 font-semibold">{checkResult.summary.error} error</span>
                  <span className="text-yellow-400 font-semibold">{checkResult.summary.warning} warning</span>
                  <span className="text-blue-400 font-semibold">{checkResult.summary.note} note</span>
                  <span className="ml-auto text-muted-foreground">{checkResult.summary.total} total</span>
                </div>
                <div className="px-4 py-2 text-[11px] text-muted-foreground border-b border-border/30 font-mono truncate">
                  SARIF: {checkResult.sarifPath}
                </div>
                <ScrollArea className="flex-1">
                  <div className="p-3 flex flex-col gap-2">
                    {checkResult.results.length === 0 ? (
                      <div className="text-center py-10 text-sm text-muted-foreground">No SARIF findings.</div>
                    ) : (
                      checkResult.results.map((item, idx) => (
                        <div key={`${item.ruleId ?? 'rule'}-${idx}`} className="p-3 rounded-lg border bg-card">
                          <div className="flex items-center gap-2 mb-1">
                            <Badge
                              variant={
                                item.level === 'error'
                                  ? 'destructive'
                                  : item.level === 'warning'
                                    ? 'secondary'
                                    : 'outline'
                              }
                              className="text-[10px]"
                            >
                              {item.level}
                            </Badge>
                            <span className="font-mono text-xs text-primary break-all">{item.ruleId ?? 'policy.finding'}</span>
                          </div>
                          <p className="text-sm leading-relaxed">{item.message}</p>
                          <div className="text-[11px] text-muted-foreground font-mono mt-2 break-all">
                            {item.uri}:{item.startLine}-{item.endLine}
                          </div>
                          {item.helpUri && (
                            <a
                              href={item.helpUri}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-block mt-2 text-xs text-primary hover:underline"
                            >
                              Rule help
                            </a>
                          )}
                        </div>
                      ))
                    )}
                  </div>
                </ScrollArea>
              </div>
            ) : (
              <div className="flex flex-1 items-center justify-center text-sm text-muted-foreground">
                Click Check to run cogna check and load SARIF findings.
              </div>
            )}
          </div>
        )}

        <div className="pointer-events-none fixed right-4 top-14 z-50 flex w-[360px] flex-col gap-2">
          {toasts.map((item) => (
            <div
              key={item.id}
              className="pointer-events-auto rounded-lg border bg-card p-3 shadow-md"
              role="status"
              aria-live="polite"
            >
              <div className="flex items-start gap-2">
                {item.kind === 'success' ? (
                  <CheckCircle2 className="mt-0.5 size-4 text-green-500" />
                ) : item.kind === 'error' ? (
                  <AlertCircle className="mt-0.5 size-4 text-red-500" />
                ) : (
                  <Loader2 className="mt-0.5 size-4 animate-spin text-primary" />
                )}
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium truncate">{item.title}</p>
                  {item.description && <p className="mt-0.5 text-xs text-muted-foreground">{item.description}</p>}
                </div>
                <Button variant="ghost" size="sm" className="h-6 px-2" onClick={() => removeToast(item.id)}>
                  ×
                </Button>
              </div>
            </div>
          ))}
        </div>

        <CommandDialog open={commandOpen} onOpenChange={setCommandOpen}>
          <CommandInput placeholder="Search packages, symbols, commands..." />
          <CommandList>
            <CommandGroup heading="Packages">
              {packageList.map((pkg) => (
                <CommandItem
                  key={pkg.name}
                  value={`package ${pkg.name}`}
                  onSelect={() => {
                    setSelectedPackageName(pkg.name)
                    setCommandOpen(false)
                  }}
                >
                  <Folder className="mr-2 h-4 w-4 text-muted-foreground" />
                  <span>{pkg.name}</span>
                  <Badge variant="outline" className="ml-auto text-[10px]">
                    {pkg.relation}
                  </Badge>
                </CommandItem>
              ))}
            </CommandGroup>
            <Separator className="my-1" />
            <CommandGroup heading="Commands">
              <CommandItem
                value="build command"
                onSelect={() => {
                  void handleBuild()
                  setCommandOpen(false)
                }}
              >
                <TerminalSquare className="mr-2 h-4 w-4 text-muted-foreground" />
                <span>Build Project</span>
              </CommandItem>
              <CommandItem
                value="diff command"
                onSelect={() => {
                  setAppView('changes')
                  setCommandOpen(false)
                }}
              >
                <TerminalSquare className="mr-2 h-4 w-4 text-muted-foreground" />
                <span>Open Reviewer</span>
              </CommandItem>
              <CommandItem
                value="policy command"
                onSelect={() => {
                  setAppView('policy')
                  setCommandOpen(false)
                }}
              >
                <TerminalSquare className="mr-2 h-4 w-4 text-muted-foreground" />
                <span>Open Gate</span>
              </CommandItem>
            </CommandGroup>
          </CommandList>
        </CommandDialog>
      </div>
    </TooltipProvider>
  )
}

export default App
