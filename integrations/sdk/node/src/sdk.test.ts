import { readFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, it, expect, beforeAll, afterAll } from 'vitest'

import { parseBuildRequest, parseBuildResponse, serializeBuildRequest } from './generated/build.js'
import {
  parseDiffRequest,
  parseDiffResponse,
  serializeDiffRequest,
} from './generated/diff.js'
import {
  parseFetchPackagesRequest,
  parseFetchPackagesResponse,
  parseQueryOutlinesRequest,
  parseQueryOutlinesResponse,
  parseQueryRequest,
  parseQueryResponse,
  serializeQueryRequest,
} from './generated/query.js'
import { build, diff, fetchPackages, queryOutlines, query } from './moonbit.js'

const __dirname = dirname(fileURLToPath(import.meta.url))
const repoRoot = join(__dirname, '../../../..')
const fixturesDir = join(repoRoot, 'e2e/sdk-fixtures')

function loadFixture(name: string) {
  return JSON.parse(readFileSync(join(fixturesDir, name), 'utf-8'))
}

// ---------------------------------------------------------------------------
// Build
// ---------------------------------------------------------------------------

describe('Build', () => {
  const fixture = loadFixture('build.json')

  it('parses BuildRequest from fixture input', () => {
    const req = parseBuildRequest(fixture.input)
    expect(req).toEqual({})
  })

  it('parses BuildResponse from fixture output', () => {
    const res = parseBuildResponse(fixture.output)
    expect(res).toBeDefined()
    expect(res!.success).toBe(true)
  })

  it('round-trips BuildRequest through serialize', () => {
    const req = parseBuildRequest(fixture.input)
    expect(serializeBuildRequest(req)).toEqual({})
  })
})

// ---------------------------------------------------------------------------
// Diff
// ---------------------------------------------------------------------------

describe('Diff', () => {
  const fixture = loadFixture('diff.json')

  it('parses DiffRequest from fixture input (snake_case)', () => {
    const req = parseDiffRequest(fixture.input)
    expect(req.base).toBe('v0.0.1')
    expect(req.target).toBe('working-tree')
    expect(req.includeTestChanges).toBe(false)
  })

  it('serializes DiffRequest to snake_case JSON keys', () => {
    const req = parseDiffRequest(fixture.input)
    const obj = serializeDiffRequest(req)
    expect(obj).toHaveProperty('include_test_changes', false)
    expect(obj).not.toHaveProperty('includeTestChanges')
  })

  it('parses DiffResponse from fixture output', () => {
    const res = parseDiffResponse(fixture.output)
    expect(res).toBeDefined()
    expect(res!.changes).toHaveLength(4)
    expect(res!.changes[0].kind).toBe('added')
    expect(res!.changes[0].level).toBe('non-breaking')
    // test_changes is null in fixture → treated as empty array
    expect(res!.testChanges).toEqual([])
  })
})

// ---------------------------------------------------------------------------
// FetchPackages
// ---------------------------------------------------------------------------

describe('FetchPackages', () => {
  const fixture = loadFixture('fetch-packages.json')

  it('parses FetchPackagesRequest from fixture input', () => {
    const req = parseFetchPackagesRequest(fixture.input)
    expect(req).toEqual({})
  })

  it('parses FetchPackagesResponse with nested children', () => {
    const res = parseFetchPackagesResponse(fixture.output)
    expect(res).toBeDefined()
    expect(res!.root.name).toBe('example/sdkacceptance')
    expect(res!.root.relation).toBe('root')
    expect(res!.root.children).toHaveLength(2)
    const lo = res!.root.children[1]
    expect(lo.name).toBe('github.com/samber/lo')
    expect(lo.children).toHaveLength(1)
    expect(lo.children[0].relation).toBe('transitive')
  })

  it('returns undefined for invalid FetchPackagesResponse input', () => {
    expect(parseFetchPackagesResponse(null)).toBeUndefined()
    expect(parseFetchPackagesResponse({ root: null })).toBeUndefined()
  })
})

// ---------------------------------------------------------------------------
// QueryOutlines
// ---------------------------------------------------------------------------

describe('QueryOutlines', () => {
  const fixture = loadFixture('query-outlines.json')

  it('parses QueryOutlinesRequest from fixture input', () => {
    const req = parseQueryOutlinesRequest(fixture.input)
    expect(req).toBeDefined()
    expect(req!.package).toBe('example/sdkacceptance')
  })

  it('parses QueryOutlinesResponse with locations (snake_case)', () => {
    const res = parseQueryOutlinesResponse(fixture.output)
    expect(res).toBeDefined()
    expect(res!.outlines).toHaveLength(4)
    const first = res!.outlines[0]
    expect(first.id).toBe('decl:go:example/sdkacceptance.Greeter')
    expect(first.kind).toBe('type')
    expect(first.location).toBeDefined()
    expect(first.location!.startLine).toBe(12)
    expect(first.location!.endLine).toBe(14)
  })

  it('includes all outline kinds', () => {
    const res = parseQueryOutlinesResponse(fixture.output)!
    const kinds = res.outlines.map(o => o.kind)
    expect(kinds).toContain('type')
    expect(kinds).toContain('method')
    expect(kinds).toContain('function')
  })
})

// ---------------------------------------------------------------------------
// Query – exact-id
// ---------------------------------------------------------------------------

describe('Query (exact-id)', () => {
  const fixture = loadFixture('query-exact-id.json')

  it('parses QueryRequest with exact_id (snake_case)', () => {
    const req = parseQueryRequest(fixture.input)
    expect(req).toBeDefined()
    expect(req!.exactId).toBe('decl:go:example/sdkacceptance.Greeter')
    expect(req!.exactSymbol).toBeUndefined()
  })

  it('serializes QueryRequest with exact_id to snake_case key', () => {
    const req = parseQueryRequest(fixture.input)!
    const obj = serializeQueryRequest(req)
    expect(obj).toHaveProperty('exact_id', 'decl:go:example/sdkacceptance.Greeter')
    expect(obj).not.toHaveProperty('exactId')
  })

  it('parses QueryResponse with location fields', () => {
    const res = parseQueryResponse(fixture.output)
    expect(res).toBeDefined()
    expect(res!.mode).toBe('exact-id')
    expect(res!.matches).toHaveLength(1)
    const m = res!.matches[0]
    expect(m.symbol).toBe('Greeter')
    expect(m.location!.startLine).toBe(12)
    expect(m.location!.endLine).toBe(14)
  })
})

// ---------------------------------------------------------------------------
// Query – exact-symbol
// ---------------------------------------------------------------------------

describe('Query (exact-symbol)', () => {
  const fixture = loadFixture('query-exact-symbol.json')

  it('parses QueryRequest with exact_symbol (snake_case)', () => {
    const req = parseQueryRequest(fixture.input)
    expect(req).toBeDefined()
    expect(req!.exactSymbol).toBe('Greeter.Greet')
    expect(req!.exactId).toBeUndefined()
  })

  it('serializes QueryRequest with exact_symbol to snake_case key', () => {
    const req = parseQueryRequest(fixture.input)!
    const obj = serializeQueryRequest(req)
    expect(obj).toHaveProperty('exact_symbol', 'Greeter.Greet')
    expect(obj).not.toHaveProperty('exactSymbol')
  })

  it('parses QueryResponse mode exact-symbol', () => {
    const res = parseQueryResponse(fixture.output)
    expect(res!.mode).toBe('exact-symbol')
    expect(res!.matches[0].kind).toBe('method')
  })
})

// ---------------------------------------------------------------------------
// Query – fuzzy-text
// ---------------------------------------------------------------------------

describe('Query (fuzzy-text)', () => {
  const fixture = loadFixture('query-fuzzy-text.json')

  it('parses QueryRequest with text + limit', () => {
    const req = parseQueryRequest(fixture.input)
    expect(req).toBeDefined()
    expect(req!.text).toBe('label')
    expect(req!.limit).toBe(5)
  })

  it('parses QueryResponse with scores', () => {
    const res = parseQueryResponse(fixture.output)
    expect(res!.mode).toBe('fuzzy-text')
    expect(res!.matches).toHaveLength(2)
    expect(res!.matches[0].score).toBeCloseTo(0.94)
    expect(res!.matches[1].score).toBeCloseTo(0.41)
  })

  it('matches have location with snake_case fields parsed correctly', () => {
    const res = parseQueryResponse(fixture.output)!
    for (const m of res.matches) {
      expect(m.location).toBeDefined()
      expect(m.location!.startLine).toBeGreaterThan(0)
      expect(m.location!.endLine).toBeGreaterThanOrEqual(m.location!.startLine)
    }
  })
})

// ---------------------------------------------------------------------------
// Real ndjson data – end-to-end parse validation
// ---------------------------------------------------------------------------

type NdjsonRecord = {
  id: string
  kind: string
  name: string
  canonical_name: string
  path: string
  signature: string
  visibility: string
  docs: string
  language: string
  location: { uri: string; startLine: number; endLine: number }
}

describe('Real ndjson data', () => {
  const ndjsonPath = join(__dirname, '../../../../example/sdkacceptance/dist/declarations.ndjson')
  let records: NdjsonRecord[]

  beforeAll(() => {
    records = readFileSync(ndjsonPath, 'utf-8')
      .split('\n')
      .filter(l => l.trim() !== '')
      .map(l => JSON.parse(l) as NdjsonRecord)
  })

  it('loads 4 declaration records from ndjson', () => {
    expect(records).toHaveLength(4)
  })

  it('QueryOutlinesResponse – parses all 4 outlines from ndjson', () => {
    const outlines = records.map(r => ({
      id: r.id,
      symbol: r.canonical_name,
      kind: r.kind,
      summary: r.docs,
      deprecated: false,
      location: r.location,
    }))
    const res = parseQueryOutlinesResponse({ package: 'example/sdkacceptance', outlines })
    expect(res).toBeDefined()
    expect(res!.outlines).toHaveLength(4)

    const greeter = res!.outlines[0]
    expect(greeter.id).toBe('decl:go:example/sdkacceptance.Greeter')
    expect(greeter.symbol).toBe('Greeter')
    expect(greeter.kind).toBe('type')
    expect(greeter.location!.startLine).toBe(12)
    expect(greeter.location!.endLine).toBe(14)
  })

  it('QueryOutlinesResponse – contains all expected kinds', () => {
    const outlines = records.map(r => ({
      id: r.id,
      symbol: r.canonical_name,
      kind: r.kind,
      summary: r.docs,
      deprecated: false,
      location: r.location,
    }))
    const res = parseQueryOutlinesResponse({ package: 'example/sdkacceptance', outlines })!
    const kinds = res.outlines.map(o => o.kind)
    expect(kinds).toContain('type')
    expect(kinds).toContain('function')
    expect(kinds).toContain('method')
  })

  it('QueryResponse (exact-id) – parses Greeter record from ndjson', () => {
    const r = records.find(x => x.id === 'decl:go:example/sdkacceptance.Greeter')!
    const match = { id: r.id, symbol: r.canonical_name, kind: r.kind, summary: r.docs, location: r.location, score: 1.0 }
    const res = parseQueryResponse({
      package: 'example/sdkacceptance',
      mode: 'exact-id',
      matches: [match],
    })
    expect(res).toBeDefined()
    expect(res!.mode).toBe('exact-id')
    expect(res!.matches).toHaveLength(1)
    expect(res!.matches[0].symbol).toBe('Greeter')
    expect(res!.matches[0].kind).toBe('type')
    expect(res!.matches[0].location!.startLine).toBe(12)
  })

  it('QueryResponse (exact-symbol) – parses Greeter.Greet record from ndjson', () => {
    const r = records.find(x => x.canonical_name === 'Greeter.Greet')!
    const match = { id: r.id, symbol: r.canonical_name, kind: r.kind, summary: r.docs, location: r.location, score: 1.0 }
    const res = parseQueryResponse({
      package: 'example/sdkacceptance',
      mode: 'exact-symbol',
      matches: [match],
    })
    expect(res!.mode).toBe('exact-symbol')
    expect(res!.matches[0].symbol).toBe('Greeter.Greet')
    expect(res!.matches[0].kind).toBe('method')
    expect(res!.matches[0].location!.startLine).toBe(27)
  })

  it('QueryResponse (fuzzy-text) – parses BuildLabels record from ndjson', () => {
    const r = records.find(x => x.name === 'BuildLabels')!
    const match = { id: r.id, symbol: r.canonical_name, kind: r.kind, summary: r.docs, location: r.location, score: 0.87 }
    const res = parseQueryResponse({
      package: 'example/sdkacceptance',
      mode: 'fuzzy-text',
      matches: [match],
    })
    expect(res!.mode).toBe('fuzzy-text')
    expect(res!.matches[0].symbol).toBe('BuildLabels')
    expect(res!.matches[0].score).toBeCloseTo(0.87)
    expect(res!.matches[0].location!.startLine).toBe(20)
  })

  it('QueryResponse – location fields parsed from camelCase ndjson keys', () => {
    const newRequestId = records.find(x => x.name === 'NewRequestID')!
    const match = { id: newRequestId.id, symbol: newRequestId.canonical_name, kind: newRequestId.kind, summary: newRequestId.docs, location: newRequestId.location, score: 1.0 }
    const res = parseQueryResponse({ package: 'example/sdkacceptance', mode: 'exact-id', matches: [match] })!
    expect(res.matches[0].location!.startLine).toBe(16)
    expect(res.matches[0].location!.endLine).toBe(18)
  })
})


// ---------------------------------------------------------------------------
// Direct MoonBit SDK facade
// ---------------------------------------------------------------------------

describe('Direct MoonBit facade', () => {
  const previousCwd = process.cwd()

  beforeAll(() => {
    process.chdir(repoRoot)
  })

  afterAll(() => {
    process.chdir(previousCwd)
  })
  const queryOutlinesFixture = loadFixture('query-outlines.json')
  const queryExactIdFixture = loadFixture('query-exact-id.json')
  const queryExactSymbolFixture = loadFixture('query-exact-symbol.json')
  const queryFuzzyTextFixture = loadFixture('query-fuzzy-text.json')

  it('build returns the real MoonBit BuildResponse without JSON serialization', () => {
    const res = build()
    expect(res).toEqual({ success: true })
  })

  it('diff returns the real MoonBit DiffResponse without JSON serialization', () => {
    const res = diff({ base: 'v0.0.1', target: 'working-tree', includeTestChanges: false })
    expect(res).toBeDefined()
    expect(res!.changes).toEqual([])
    expect(res!.testChanges).toEqual([])
  })

  it('fetchPackages keeps the current stub behavior through the direct facade', () => {
    const res = fetchPackages()
    expect(res).toBeDefined()
    expect(res!.root.name).toBe('.')
    expect(res!.root.relation).toBe('root')
  })

  it('queryOutlines returns typed outlines from the compiled MoonBit runtime', () => {
    const req = parseQueryOutlinesRequest(queryOutlinesFixture.input)!
    const res = queryOutlines(req)
    expect(res).toBeDefined()
    expect(res!.package).toBe('example/sdkacceptance')
    expect(res!.outlines).toHaveLength(4)
    expect(res!.outlines[0].id).toBe(queryOutlinesFixture.output.outlines[0].id)
    expect(res!.outlines[0].symbol).toBe(queryOutlinesFixture.output.outlines[0].symbol)
    expect(res!.outlines[0].location!.startLine).toBe(queryOutlinesFixture.output.outlines[0].location.start_line)
  })

  it('query supports exact-id through the direct facade', () => {
    const req = parseQueryRequest(queryExactIdFixture.input)!
    const res = query(req)
    expect(res).toBeDefined()
    expect(res!.mode).toBe('exact-id')
    expect(res!.matches.length).toBeGreaterThan(0)
    expect(res!.matches.some(match => match.id === queryExactIdFixture.output.matches[0].id)).toBe(true)
  })

  it('query supports exact-symbol through the direct facade', () => {
    const req = parseQueryRequest(queryExactSymbolFixture.input)!
    const res = query(req)
    expect(res).toBeDefined()
    expect(res!.mode).toBe('exact-symbol')
    expect(res!.matches[0].symbol).toBe(queryExactSymbolFixture.output.matches[0].symbol)
  })

  it('query keeps the current fuzzy-text stub behavior through the direct facade', () => {
    const req = parseQueryRequest(queryFuzzyTextFixture.input)!
    const res = query(req)
    expect(res).toBeDefined()
    expect(res!.mode).toBe('fuzzy-text')
    expect(res!.matches).toEqual([])
  })
})
