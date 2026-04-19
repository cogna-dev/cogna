export type Relation = 'root' | 'workspace' | 'direct' | 'transitive'
export type QueryMode = 'exact-id' | 'exact-symbol' | 'fuzzy-text'

export const queryModes: Array<{
  value: QueryMode
  label: string
  placeholder: string
}> = [
  {
    value: 'exact-id',
    label: 'Exact ID',
    placeholder: 'decl:go:example/sdkacceptance.Greeter',
  },
  {
    value: 'exact-symbol',
    label: 'Exact Symbol',
    placeholder: 'Greeter.Greet',
  },
  {
    value: 'fuzzy-text',
    label: 'Fuzzy Text',
    placeholder: 'label',
  },
]

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
  summary?: string
  deprecated: boolean
  location: SourceLocation
}

export interface QueryMatch {
  id: string
  symbol: string
  kind: string
  signature?: string
  summary?: string
  docs?: string
  score?: number
  location: SourceLocation
}

export interface DiffChange {
  kind: 'added' | 'removed' | 'changed' | 'deprecated'
  id: string
  symbol: string
  level: string
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
