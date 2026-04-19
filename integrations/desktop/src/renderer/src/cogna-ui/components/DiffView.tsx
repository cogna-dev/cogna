import { useState, useEffect } from 'react'
import type { DiffResult, DiffChange } from '../types'
import { cn } from '../lib/utils'
import { GitBranch, GitCompare, ArrowRight, ChevronDown, ChevronRight } from 'lucide-react'

type DiffChangeKind = DiffChange['kind']

const KIND_COLORS: Record<DiffChangeKind, string> = {
  added:      'text-green-500',
  removed:    'text-red-500',
  changed:    'text-blue-500',
  deprecated: 'text-yellow-500',
}
const KIND_DOT: Record<DiffChangeKind, string> = {
  added:      'bg-green-500',
  removed:    'bg-red-500',
  changed:    'bg-blue-500',
  deprecated: 'bg-yellow-500',
}
const LEVEL_COLORS = {
  breaking:      'bg-red-500/10 text-red-400 border-red-500/20',
  compatible:    'bg-green-500/10 text-green-400 border-green-500/20',
  'non-breaking': 'bg-muted text-muted-foreground border-border',
}

function ChangeRow({ change }: { change: DiffChange }) {
  const [expanded, setExpanded] = useState(false)
  const hasSig = !!(change.beforeSignature || change.afterSignature)
  const rowKey = `${change.id}-${change.kind}-${change.level}`
  return (
    <button
      type="button"
      className={cn(
        'w-full text-left border-b border-border/20 hover:bg-muted/30 transition-colors',
        hasSig ? 'cursor-pointer' : 'cursor-default'
      )}
      onClick={() => hasSig && setExpanded((v: boolean) => !v)}
      onKeyDown={(event) => {
        if (!hasSig) {
          return
        }
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault()
          setExpanded((v: boolean) => !v)
        }
      }}
      disabled={!hasSig}
      aria-expanded={expanded}
      data-row-key={rowKey}
    >
      <div className="flex items-center gap-2 px-3 py-1.5">
        {hasSig ? (
          expanded
            ? <ChevronDown className="w-3 h-3 text-muted-foreground shrink-0" />
            : <ChevronRight className="w-3 h-3 text-muted-foreground shrink-0" />
        ) : (
          <span className="w-3 h-3 shrink-0" />
        )}
        <span className={cn('w-1.5 h-1.5 rounded-full shrink-0', KIND_DOT[change.kind])} />
        <span className={cn('text-[10px] font-semibold w-[68px] shrink-0 uppercase tracking-wide', KIND_COLORS[change.kind])}>
          {change.kind}
        </span>
        <code className="font-mono text-xs flex-1 truncate text-foreground">{change.symbol}</code>
        <span className={cn('text-[10px] px-1.5 py-0.5 rounded border shrink-0', LEVEL_COLORS[change.level])}>
          {change.level}
        </span>
        <span className="text-[11px] text-muted-foreground truncate max-w-[200px] hidden sm:block">
          {change.message}
        </span>
      </div>
      {expanded && (
        <div className="flex flex-col gap-1 px-3 pb-2 ml-10">
          {change.beforeSignature && (
            <div className="flex gap-2 p-2 rounded bg-red-500/5 border border-red-500/10 text-xs font-mono overflow-x-auto">
              <span className="text-red-500 select-none shrink-0">-</span>
              <pre className="text-foreground/80 whitespace-pre-wrap">{change.beforeSignature}</pre>
            </div>
          )}
          {change.afterSignature && (
            <div className="flex gap-2 p-2 rounded bg-green-500/5 border border-green-500/10 text-xs font-mono overflow-x-auto">
              <span className="text-green-500 select-none shrink-0">+</span>
              <pre className="text-foreground/80 whitespace-pre-wrap">{change.afterSignature}</pre>
            </div>
          )}
          {change.location && (
            <span className="text-[10px] text-muted-foreground font-mono mt-1">
              {change.location.uri}:{change.location.startLine}-{change.location.endLine}
            </span>
          )}
          <p className="text-xs text-muted-foreground sm:hidden">{change.message}</p>
        </div>
      )}
    </button>
  )
}

interface DiffViewProps {
  readonly?: boolean
  initialResult?: DiffResult | null
  onRunDiff?: (params: {
    base: string
    target: string
    includeTestChanges: boolean
  }) => Promise<DiffResult | null>
}

export function DiffView({
  readonly = false,
  initialResult = null,
  onRunDiff,
}: DiffViewProps): React.JSX.Element {
  const [base, setBase] = useState('v1.1.0')
  const [target, setTarget] = useState('working-tree')
  const [includeTestChanges, setIncludeTestChanges] = useState(true)
  const [result, setResult] = useState<DiffResult | null>(initialResult)
  const [filterKind, setFilterKind] = useState<DiffChangeKind | 'all'>('all')
  const [showTestChanges, setShowTestChanges] = useState(true)
  const [isRunning, setIsRunning] = useState(false)

  useEffect(() => {
    setResult(initialResult)
  }, [initialResult])

  const handleRunDiff = async () => {
    if (!onRunDiff || isRunning || readonly) {
      return
    }
    setIsRunning(true)
    try {
      const next = await onRunDiff({ base, target, includeTestChanges })
      if (next) {
        setResult(next)
      }
    } finally {
      setIsRunning(false)
    }
  }

  const allChanges = result ? [...result.changes, ...(showTestChanges ? result.testChanges : [])] : []
  const filteredChanges = allChanges.filter((c) => filterKind === 'all' || c.kind === filterKind)

  return (
    <div className="flex flex-col flex-1 h-full overflow-hidden bg-background">
      <div className="flex flex-wrap items-center gap-3 px-4 py-2 border-b border-border bg-muted/10 shrink-0">
        <div className="flex items-center gap-2">
          <GitBranch className="w-3.5 h-3.5 text-muted-foreground" />
          <input
            className="h-7 px-2 text-xs rounded border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring w-28"
            value={base}
            onChange={(e) => setBase(e.target.value)}
            placeholder="Base (e.g. v1.1.0)"
            disabled={readonly}
          />
        </div>
        <ArrowRight className="w-3.5 h-3.5 text-muted-foreground" />
        <div className="flex items-center gap-2">
          <GitCompare className="w-3.5 h-3.5 text-muted-foreground" />
          <input
            className="h-7 px-2 text-xs rounded border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring w-28"
            value={target}
            onChange={(e) => setTarget(e.target.value)}
            placeholder="Target"
            disabled={readonly}
          />
        </div>
        <label className="flex items-center gap-1.5 text-xs text-muted-foreground cursor-pointer ml-2">
          <input
            type="checkbox"
            checked={includeTestChanges}
            onChange={(e) => setIncludeTestChanges(e.target.checked)}
            disabled={readonly}
          />
          Include test changes
        </label>
        {!readonly && (
          <button
            type="button"
            onClick={handleRunDiff}
            disabled={isRunning}
            className="ml-auto h-7 px-3 text-xs rounded bg-primary text-primary-foreground hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isRunning ? 'Running…' : 'Run Diff'}
          </button>
        )}
      </div>

      {!result ? (
        <div className="flex flex-col items-center justify-center flex-1 text-muted-foreground">
          <GitCompare className="w-10 h-10 mb-3 opacity-20" />
          <p className="text-sm">Enter base and target versions to run a diff.</p>
        </div>
      ) : (
        <div className="flex flex-col flex-1 overflow-hidden">
          <div className="flex items-center gap-4 px-4 py-2 border-b border-border/50 bg-muted/5 shrink-0 text-xs">
            <span className="text-green-400 font-semibold">+{result.summary.added} added</span>
            <span className="text-red-400 font-semibold">-{result.summary.removed} removed</span>
            <span className="text-blue-400 font-semibold">~{result.summary.changed} changed</span>
            <span className="text-yellow-400 font-semibold">?{result.summary.deprecated} deprecated</span>
            <span className="ml-auto text-muted-foreground">
              {allChanges.length} total
              {filteredChanges.length !== allChanges.length && ` · ${filteredChanges.length} shown`}
            </span>
          </div>

          <div className="flex items-center justify-between px-4 py-1.5 border-b border-border/30 shrink-0">
            <div className="flex gap-1.5">
              {(['all', 'added', 'removed', 'changed', 'deprecated'] as const).map((kind) => (
                <button
                  type="button"
                  key={kind}
                  onClick={() => setFilterKind(kind as DiffChangeKind | 'all')}
                  className={cn(
                    'px-2 py-0.5 text-[10px] font-medium rounded border transition-colors',
                    filterKind === kind
                      ? 'bg-primary text-primary-foreground border-primary'
                      : 'bg-background text-muted-foreground border-border hover:bg-muted'
                  )}
                >
                  {kind.charAt(0).toUpperCase() + kind.slice(1)}
                </button>
              ))}
            </div>
            <label className="flex items-center gap-1.5 text-xs text-muted-foreground cursor-pointer">
              <input
                type="checkbox"
                checked={showTestChanges}
                onChange={(e) => setShowTestChanges(e.target.checked)}
              />
              Tests
            </label>
          </div>

          <div className="flex-1 overflow-y-auto">
            {filteredChanges.length === 0 ? (
              <div className="text-center py-12 text-sm text-muted-foreground">
                No changes match the current filters.
              </div>
            ) : (
              filteredChanges.map((change) => (
                <ChangeRow key={`${change.id}-${change.kind}-${change.level}`} change={change} />
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}
