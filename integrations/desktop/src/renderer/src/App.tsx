/* eslint-disable */

import { useMemo, useState, useEffect } from 'react'
import type { Outline, PackageNode, QueryMatch, QueryMode } from '@cogna/ui'
import { buildCommand, diffCommand, mockData, queryModes, runMockQuery, PackageTree, DiffView } from '@cogna/ui'
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
  Minus,
  Square,
  X
} from 'lucide-react'

type DetailItem = Outline | QueryMatch
type ExplorerTab = 'outlines' | 'query'

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

type AppView = 'explorer' | 'diff'

function App(): React.JSX.Element {
  const packageList = useMemo(() => flattenPackages(mockData.packages.root), [])
  const [selectedPackageName, setSelectedPackageName] = useState(
    packageList[0]?.name ?? 'workspace-app'
  )
  const [tab, setTab] = useState<ExplorerTab>('outlines')
  const [queryMode, setQueryMode] = useState<QueryMode>('fuzzy-text')
  const [queryText, setQueryText] = useState('effect cleanup')
  const [selectedDetailId, setSelectedDetailId] = useState<string | null>(null)
  const [appView, setAppView] = useState<AppView>('explorer')

  const [commandOpen, setCommandOpen] = useState(false)

  const selectedPackage = useMemo(
    () => packageList.find((item) => item.name === selectedPackageName) ?? packageList[0],
    [packageList, selectedPackageName]
  )

  const outlines = useMemo(
    () => mockData.outlines[selectedPackage.name] ?? [],
    [selectedPackage.name]
  )
  const queryResponse = useMemo(
    () => runMockQuery(selectedPackage.name, queryMode, queryText),
    [queryMode, queryText, selectedPackage.name]
  )

  const activeDetail = useMemo<DetailItem | null>(() => {
    if (tab === 'outlines') {
      return outlines.find((item) => item.id === selectedDetailId) ?? outlines[0] ?? null
    }

    return (
      queryResponse.matches.find((item) => item.id === selectedDetailId) ??
      queryResponse.matches[0] ??
      null
    )
  }, [outlines, queryResponse.matches, selectedDetailId, tab])

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

  const isMac = useMemo(() => window.navigator.platform.toUpperCase().indexOf('MAC') >= 0, [])

  return (
    <TooltipProvider>
      <div className="h-screen flex flex-col bg-background text-foreground overflow-hidden font-sans">
        {/* Menubar */}
        <header
          className={`h-[38px] grid items-center border-b border-border flex-shrink-0 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 ${isMac ? 'pl-[72px]' : 'pl-4'}`}
          style={{ WebkitAppRegion: 'drag', gridTemplateColumns: '1fr auto 1fr' } as React.CSSProperties}
        >
          <div />

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
                appView === 'diff' ? 'bg-background text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'
              }`}
              onClick={() => setAppView('diff')}
              type="button"
            >
              Diff
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
                >
                  <Minus className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={() => window.api.window.maximize()}
                  className="h-full px-3 hover:bg-accent text-muted-foreground transition-colors"
                >
                  <Square className="w-3 h-3" />
                </button>
                <button
                  onClick={() => window.api.window.close()}
                  className="h-full px-3 hover:bg-destructive hover:text-destructive-foreground text-muted-foreground transition-colors"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>
        </header>

        {/* Main area below menubar */}
        {appView === 'explorer' ? (
        <div className="flex flex-1 overflow-hidden">
          {/* Sidebar */}
          <aside className="w-[240px] flex-shrink-0 border-r border-border flex flex-col bg-muted/20">
            <div className="h-10 flex items-center px-4 border-b border-border/50 bg-background/50">
              <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">
                Packages
              </h2>
            </div>
            <ScrollArea className="flex-1">
              <div className="p-3">
                <PackageTree
                  node={mockData.packages.root}
                  selected={selectedPackage.name}
                  onSelect={(name) => {
                    setSelectedPackageName(name)
                    setSelectedDetailId(null)
                  }}
                />
              </div>
            </ScrollArea>
          </aside>

          {/* Explorer panel */}
          <section className="flex-1 flex flex-col border-r border-border overflow-hidden bg-background">
            <div className="h-10 flex items-center justify-between px-4 border-b border-border flex-shrink-0">
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-semibold">{selectedPackage.name}</h2>
                <Badge variant="outline" className="h-5 px-1.5 text-[10px] text-muted-foreground">
                  {tab === 'outlines' ? 'Outlines' : 'Query'}
                </Badge>
              </div>

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

            {tab === 'outlines' ? (
              <ScrollArea className="flex-1">
                <div className="p-4 flex flex-col gap-2">
                  {outlines.length === 0 ? (
                    <div className="text-center py-8 text-sm text-muted-foreground">
                      No outlines found.
                    </div>
                  ) : (
                    outlines.map((item) => (
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
                          <span className="font-mono text-sm font-semibold text-primary">
                            {item.symbol}
                          </span>
                          <Badge variant="secondary" className="text-[10px] h-5">
                            {item.kind}
                          </Badge>
                        </div>
                        <p className="text-xs text-muted-foreground line-clamp-1 mb-2">
                          {item.summary}
                        </p>
                        <div className="flex items-center gap-2 text-[10px] text-muted-foreground/70">
                          {'deprecated' in item && item.deprecated && (
                            <Badge variant="destructive" className="h-4 px-1">
                              Deprecated
                            </Badge>
                          )}
                          <span className="font-mono">{item.location.uri}</span>
                        </div>
                      </button>
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
                      queryResponse.matches.map((item) => (
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
                            <span className="font-mono text-sm font-semibold text-primary">
                              {item.symbol}
                            </span>
                            <Badge variant="secondary" className="text-[10px] h-5">
                              {item.kind}
                            </Badge>
                          </div>
                          <p className="text-xs text-muted-foreground line-clamp-1 mb-2">
                            {item.summary}
                          </p>
                          <div className="flex items-center gap-2 text-[10px] text-muted-foreground/70 font-mono">
                            {item.score !== undefined ? (
                              <span className="bg-muted px-1 rounded">
                                Score: {item.score.toFixed(2)}
                              </span>
                            ) : (
                              <span className="bg-muted px-1 rounded">Exact match</span>
                            )}
                            <span className="truncate">{item.location.uri}</span>
                          </div>
                        </button>
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

          {/* Detail panel */}
          <aside className="w-[340px] flex-shrink-0 flex flex-col overflow-hidden bg-card/50">
            <div className="h-10 flex items-center px-4 border-b border-border bg-background/50">
              <h2 className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">
                Details
              </h2>
            </div>

            <ScrollArea className="flex-1">
              {activeDetail ? (
                <div className="p-5 flex flex-col gap-6">
                  <div>
                    <h3 className="font-mono text-lg font-bold text-foreground mb-2 break-all">
                      {activeDetail.symbol}
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
                      <span className="text-muted-foreground">ID</span>
                      <code className="font-mono text-xs bg-muted px-1.5 py-0.5 rounded break-all">
                        {activeDetail.id}
                      </code>

                      <span className="text-muted-foreground">Location</span>
                      <span className="font-mono text-xs break-all">
                        {activeDetail.location.uri}:{activeDetail.location.startLine}-
                        {activeDetail.location.endLine}
                      </span>
                    </div>
                  </div>

                  <Separator />

                  {isQueryMatch(activeDetail) && activeDetail.signature && (
                    <div className="space-y-2">
                      <span className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">
                        Signature
                      </span>
                      <pre className="p-3 rounded-md bg-muted/50 border border-border/50 text-xs font-mono overflow-x-auto whitespace-pre-wrap">
                        {activeDetail.signature}
                      </pre>
                    </div>
                  )}

                  <div className="space-y-2">
                    <span className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">
                      Summary
                    </span>
                    <p className="text-sm leading-relaxed text-foreground/90">
                      {activeDetail.summary}
                    </p>
                  </div>

                  {isQueryMatch(activeDetail) && activeDetail.docs && (
                    <div className="space-y-2">
                      <span className="text-xs font-semibold tracking-wider text-muted-foreground uppercase">
                        Documentation
                      </span>
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
                    <p className="text-sm">
                      Select an outline or query result to inspect its details.
                    </p>
                  </div>
                </div>
              )}
            </ScrollArea>
          </aside>
        </div>
        ) : (
          <DiffView />
        )}

        {/* Command palette dialog */}
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
                  console.log('Copying build command:', buildCommand)
                  setCommandOpen(false)
                }}
              >
                <TerminalSquare className="mr-2 h-4 w-4 text-muted-foreground" />
                <span>Build Project</span>
              </CommandItem>
              <CommandItem
                value="diff command"
                onSelect={() => {
                  console.log('Copying diff command:', diffCommand)
                  setCommandOpen(false)
                }}
              >
                <TerminalSquare className="mr-2 h-4 w-4 text-muted-foreground" />
                <span>Diff Project</span>
              </CommandItem>
            </CommandGroup>
          </CommandList>
        </CommandDialog>
      </div>
    </TooltipProvider>
  )
}

export default App
