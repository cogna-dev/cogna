export type Relation = 'root' | 'workspace' | 'direct' | 'transitive'
export type QueryMode = 'exact-id' | 'exact-symbol' | 'fuzzy-text'

export interface SourceLocation {
  uri: string
  startLine: number
  endLine: number
}

export interface PackageNode {
  name: string
  version?: string
  ecosystem?: string
  relation: Relation
  summary?: string
  children: PackageNode[]
}

export interface Outline {
  id: string
  symbol: string
  kind: string
  summary: string
  deprecated: boolean
  location: SourceLocation
}

export interface QueryMatch {
  id: string
  symbol: string
  kind: string
  signature?: string
  summary: string
  docs?: string
  score?: number
  location: SourceLocation
}

export interface QueryResponse {
  package: string
  mode: QueryMode
  matches: QueryMatch[]
  cursor?: string
}

const workspaceRoot: PackageNode = {
  name: 'workspace-app',
  version: '0.4.0',
  ecosystem: 'workspace',
  relation: 'root',
  summary: 'Current project context resolved from cogna.yml and .cogna/sbom.spdx.json.',
  children: [
    {
      name: '@cogna/sdk',
      version: '0.1.0',
      ecosystem: 'npm',
      relation: 'workspace',
      summary: 'Node SDK facade and generated DTO surface.',
      children: []
    },
    {
      name: 'react',
      version: '19.2.0',
      ecosystem: 'npm',
      relation: 'direct',
      summary: 'UI runtime dependency.',
      children: [
        {
          name: 'scheduler',
          version: '0.27.0',
          ecosystem: 'npm',
          relation: 'transitive',
          summary: 'Transitive React runtime scheduling package.',
          children: []
        }
      ]
    },
    {
      name: 'tokio',
      version: '1.43.0',
      ecosystem: 'cargo',
      relation: 'transitive',
      summary: 'Async runtime surfaced from the current dependency graph.',
      children: []
    }
  ]
}

const outlines: Record<string, Outline[]> = {
  'workspace-app': [
    {
      id: 'decl:workspace:AppShell',
      symbol: 'AppShell',
      kind: 'component',
      summary: 'Top-level desktop workspace that coordinates package browsing and query flows.',
      deprecated: false,
      location: { uri: 'src/renderer/src/App.tsx', startLine: 1, endLine: 320 }
    },
    {
      id: 'decl:workspace:runMockQuery',
      symbol: 'runMockQuery',
      kind: 'function',
      summary: 'Mock data provider that emulates the Query API response shape.',
      deprecated: false,
      location: { uri: 'src/renderer/src/mock-data.ts', startLine: 136, endLine: 182 }
    }
  ],
  '@cogna/sdk': [
    {
      id: 'decl:ts:@cogna/sdk:build',
      symbol: 'build',
      kind: 'function',
      summary: 'Build the current project query context and return success only.',
      deprecated: false,
      location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 1, endLine: 32 }
    },
    {
      id: 'decl:ts:@cogna/sdk:query',
      symbol: 'query',
      kind: 'function',
      summary: 'Unified exact and fuzzy query entry point for a chosen package.',
      deprecated: false,
      location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 34, endLine: 76 }
    },
    {
      id: 'decl:ts:@cogna/sdk:queryOutlines',
      symbol: 'queryOutlines',
      kind: 'function',
      summary: 'Return public API outline items for the given package.',
      deprecated: false,
      location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 34, endLine: 76 }
    }
  ],
  react: [
    {
      id: 'decl:npm:react:useEffect',
      symbol: 'useEffect',
      kind: 'function',
      summary: 'Synchronize a component with an external system.',
      deprecated: false,
      location: { uri: 'packages/react/src/ReactHooks.js', startLine: 93, endLine: 128 }
    },
    {
      id: 'decl:npm:react:useState',
      symbol: 'useState',
      kind: 'function',
      summary: 'Add reactive local state to a function component.',
      deprecated: false,
      location: { uri: 'packages/react/src/ReactHooks.js', startLine: 72, endLine: 91 }
    }
  ],
  scheduler: [
    {
      id: 'decl:npm:scheduler:unstable_scheduleCallback',
      symbol: 'unstable_scheduleCallback',
      kind: 'function',
      summary: 'Schedule work with a selected priority level.',
      deprecated: false,
      location: { uri: 'packages/scheduler/src/forks/Scheduler.js', startLine: 327, endLine: 372 }
    }
  ],
  tokio: [
    {
      id: 'decl:rust:tokio::sync::Mutex::lock',
      symbol: 'tokio::sync::Mutex::lock',
      kind: 'function',
      summary: 'Acquire the mutex asynchronously.',
      deprecated: false,
      location: { uri: 'src/sync/mutex.rs', startLine: 120, endLine: 134 }
    },
    {
      id: 'decl:rust:tokio::spawn',
      symbol: 'tokio::spawn',
      kind: 'function',
      summary: 'Spawn a future onto the Tokio runtime.',
      deprecated: false,
      location: { uri: 'src/task/spawn.rs', startLine: 165, endLine: 210 }
    }
  ]
}

const queryMatches: Record<string, QueryMatch[]> = {
  'workspace-app': [
    {
      id: 'decl:workspace:runMockQuery',
      symbol: 'runMockQuery',
      kind: 'function',
      signature: 'runMockQuery(packageName, mode, input) -> QueryResponse',
      summary:
        'Mocked Query implementation that keeps the desktop demo aligned with the public API contract.',
      docs: 'This demo intentionally mirrors exact-id, exact-symbol, and fuzzy-text without depending on the unstable SDK runtime path.',
      score: 0.94,
      location: { uri: 'src/renderer/src/mock-data.ts', startLine: 136, endLine: 182 }
    }
  ],
  '@cogna/sdk': [
    {
      id: 'decl:ts:@cogna/sdk:query',
      symbol: 'query',
      kind: 'function',
      signature: 'query(request: QueryRequest) -> Promise<QueryResponse>',
      summary: 'Run exact-id, exact-symbol, or fuzzy-text queries for one package.',
      docs: 'The current facade is typed, but the runtime depends on a monorepo-only _build path and is therefore not used directly in this desktop demo.',
      score: 0.97,
      location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 34, endLine: 76 }
    },
    {
      id: 'decl:ts:@cogna/sdk:queryOutlines',
      symbol: 'queryOutlines',
      kind: 'function',
      signature: 'queryOutlines(request: QueryOutlinesRequest) -> Promise<QueryOutlinesResponse>',
      summary: 'Load public API outline items for a package.',
      docs: 'Ideal for package browsing panes and detail drawers in desktop or IDE surfaces.',
      score: 0.88,
      location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 34, endLine: 76 }
    }
  ],
  react: [
    {
      id: 'decl:npm:react:useEffect',
      symbol: 'useEffect',
      kind: 'function',
      signature: 'useEffect(setup, deps?)',
      summary: 'Synchronize a component with an external system.',
      docs: 'When the effect returns a function, React runs it as cleanup before the next effect or unmount.',
      score: 0.99,
      location: { uri: 'packages/react/src/ReactHooks.js', startLine: 93, endLine: 128 }
    },
    {
      id: 'decl:npm:react:useState',
      symbol: 'useState',
      kind: 'function',
      signature: 'useState(initialState)',
      summary: 'Create stateful values in a function component.',
      docs: 'React preserves this state between renders and re-renders on updates.',
      score: 0.72,
      location: { uri: 'packages/react/src/ReactHooks.js', startLine: 72, endLine: 91 }
    }
  ],
  scheduler: [
    {
      id: 'decl:npm:scheduler:unstable_scheduleCallback',
      symbol: 'unstable_scheduleCallback',
      kind: 'function',
      signature: 'unstable_scheduleCallback(priorityLevel, callback)',
      summary: 'Queue work with Scheduler priority semantics.',
      docs: 'Useful when you need finer-grained work scheduling under React internals.',
      score: 0.67,
      location: { uri: 'packages/scheduler/src/forks/Scheduler.js', startLine: 327, endLine: 372 }
    }
  ],
  tokio: [
    {
      id: 'decl:rust:tokio::sync::Mutex::lock',
      symbol: 'tokio::sync::Mutex::lock',
      kind: 'function',
      signature: "fn lock(&self) -> impl Future<Output = MutexGuard<'_, T>>",
      summary: 'Acquire the mutex asynchronously.',
      docs: 'Locks this mutex, causing the current task to yield until the lock has been acquired.',
      score: 0.96,
      location: { uri: 'src/sync/mutex.rs', startLine: 120, endLine: 134 }
    },
    {
      id: 'decl:rust:tokio::spawn',
      symbol: 'tokio::spawn',
      kind: 'function',
      signature: 'pub fn spawn<F>(future: F) -> JoinHandle<F::Output>',
      summary: 'Spawn a future onto the Tokio runtime.',
      docs: 'The provided future starts running in the background immediately after spawn is called.',
      score: 0.84,
      location: { uri: 'src/task/spawn.rs', startLine: 165, endLine: 210 }
    }
  ]
}

export const mockData = {
  packages: { root: workspaceRoot },
  outlines
}

export const queryModes = [
  {
    value: 'exact-id' as const,
    label: 'Exact ID',
    placeholder: 'decl:rust:tokio::sync::Mutex::lock'
  },
  {
    value: 'exact-symbol' as const,
    label: 'Exact Symbol',
    placeholder: 'tokio::sync::Mutex::lock'
  },
  {
    value: 'fuzzy-text' as const,
    label: 'Fuzzy Text',
    placeholder: 'effect cleanup'
  }
]

export const buildCommand = 'pnpm exec cogna build'
export const diffCommand =
  'pnpm exec cogna diff --base v1.1.0 --target working-tree --include-test-changes'

export function runMockQuery(packageName: string, mode: QueryMode, input: string): QueryResponse {
  const normalized = input.trim().toLowerCase()
  const source = queryMatches[packageName] ?? []

  if (normalized.length === 0) {
    return {
      package: packageName,
      mode,
      matches: mode === 'fuzzy-text' ? source : []
    }
  }

  const matches = source.filter((item) => {
    if (mode === 'exact-id') {
      return item.id.toLowerCase() === normalized
    }

    if (mode === 'exact-symbol') {
      return item.symbol.toLowerCase() === normalized
    }

    const haystack = [item.symbol, item.summary, item.docs ?? '', item.signature ?? '']
      .join(' ')
      .toLowerCase()
    return haystack.includes(normalized)
  })

  return {
    package: packageName,
    mode,
    matches
  }
}

export type DiffChangeKind = 'added' | 'removed' | 'changed' | 'deprecated'
export type DiffBreakingLevel = 'breaking' | 'compatible' | 'non-breaking'

export interface DiffChange {
  kind: DiffChangeKind
  id: string
  symbol: string
  level: DiffBreakingLevel
  message: string
  beforeSignature?: string
  afterSignature?: string
  location?: SourceLocation
}

export interface DiffSummary {
  added: number
  removed: number
  changed: number
  deprecated: number
}

export interface DiffResult {
  base: string
  target: string
  summary: DiffSummary
  changes: DiffChange[]
  testChanges: DiffChange[]
}

export function runMockDiff(base: string, target: string, includeTestChanges: boolean): DiffResult {
  // return a rich mock result regardless of inputs
  return {
    base: base || 'v1.1.0',
    target: target || 'working-tree',
    summary: { added: 3, removed: 1, changed: 2, deprecated: 1 },
    changes: [
      {
        kind: 'changed',
        id: 'decl:ts:@cogna/sdk:query',
        symbol: 'query',
        level: 'breaking',
        message: 'options parameter is now required',
        beforeSignature:
          'query(request: QueryRequest, options?: Options) -> Promise<QueryResponse>',
        afterSignature: 'query(request: QueryRequest, options: Options) -> Promise<QueryResponse>',
        location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 34, endLine: 76 }
      },
      {
        kind: 'added',
        id: 'decl:ts:@cogna/sdk:diff',
        symbol: 'diff',
        level: 'compatible',
        message: 'new public API added',
        afterSignature: 'diff(request: DiffRequest) -> Promise<DiffResult>',
        location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 80, endLine: 120 }
      },
      {
        kind: 'added',
        id: 'decl:ts:@cogna/sdk:fetchPackages',
        symbol: 'fetchPackages',
        level: 'compatible',
        message: 'new public API added',
        afterSignature: 'fetchPackages() -> Promise<FetchPackagesResponse>',
        location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 122, endLine: 145 }
      },
      {
        kind: 'added',
        id: 'decl:rust:tokio::task::JoinSet::join_next',
        symbol: 'tokio::task::JoinSet::join_next',
        level: 'compatible',
        message: 'new method added to JoinSet',
        afterSignature: 'pub async fn join_next(&mut self) -> Option<Result<T, JoinError>>',
        location: { uri: 'src/task/join_set.rs', startLine: 220, endLine: 255 }
      },
      {
        kind: 'removed',
        id: 'decl:ts:@cogna/sdk:buildLocalIndex',
        symbol: 'buildLocalIndex',
        level: 'breaking',
        message: 'internal API removed from public surface',
        beforeSignature: 'buildLocalIndex(path: string) -> Promise<void>',
        location: { uri: 'integrations/sdk/node/src/moonbit.ts', startLine: 1, endLine: 32 }
      },
      {
        kind: 'changed',
        id: 'decl:npm:react:useEffect',
        symbol: 'useEffect',
        level: 'compatible',
        message: 'optional deps parameter stricter typing in React 19',
        beforeSignature: 'useEffect(setup: EffectCallback, deps?: DependencyList)',
        afterSignature: 'useEffect(setup: EffectCallback, deps: DependencyList | undefined)',
        location: { uri: 'packages/react/src/ReactHooks.js', startLine: 93, endLine: 128 }
      },
      {
        kind: 'deprecated',
        id: 'decl:npm:react:useLayoutEffect',
        symbol: 'useLayoutEffect',
        level: 'non-breaking',
        message: 'prefer useEffect with layout timing instead',
        location: { uri: 'packages/react/src/ReactHooks.js', startLine: 130, endLine: 155 }
      }
    ],
    testChanges: includeTestChanges
      ? [
          {
            kind: 'added',
            id: 'test:sdk:query-round-trip',
            symbol: 'query round-trip test',
            level: 'non-breaking',
            message: 'new e2e test added for query API',
            location: { uri: 'src/e2e/native/sdk_test.mbt', startLine: 1, endLine: 40 }
          }
        ]
      : []
  }
}
