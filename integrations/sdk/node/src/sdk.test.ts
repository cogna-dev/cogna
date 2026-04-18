import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, it, expect, beforeAll, afterAll } from 'vitest'

import {
  parseFetchPackagesRequest,
  parseFetchPackagesResponse,
  parseQueryOutlinesRequest,
  parseQueryOutlinesResponse,
  parseQueryRequest,
  parseQueryResponse,
  serializeQueryRequest,
} from './generated/query.js'
import { fetchPackages, queryOutlines, query } from './moonbit.js'

const __dirname = dirname(fileURLToPath(import.meta.url))
const repoRoot = join(__dirname, '../../../..')
const fixturesDir = join(repoRoot, 'e2e/sdk-fixtures')
const runtimeProjectDir = '/tmp/cogna-sdk-node-runtime'

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

function loadFixture(name: string) {
  return JSON.parse(readFileSync(join(fixturesDir, name), 'utf-8'))
}

function must<T>(value: T | undefined | null, message: string): NonNullable<T> {
  if (value == null) {
    throw new Error(message)
  }
  return value
}

function writeRuntimeProjectFiles(): void {
  mkdirSync(join(runtimeProjectDir, 'dist'), { recursive: true })
  mkdirSync(join(runtimeProjectDir, '.cogna', 'cache'), { recursive: true })

  writeFileSync(
    join(runtimeProjectDir, 'cogna.yaml'),
    [
      'schemaVersion: ciq-config/v1',
      'profile: go-module',
      'purl: pkg:golang/example/sdkacceptance@0.1.0',
      'source:',
      '  repo: https://github.com/example/cogna-sdkacceptance',
      '  ref: main',
      'inputs:',
      '  include:',
      '    - "**/*.go"',
      'checks:',
      '  format: sarif',
      '  policy: default-compat',
      '',
    ].join('\n'),
    'utf-8',
  )

  const declarationsText = readFileSync(join(fixturesDir, 'declarations.ndjson'), 'utf-8')
  writeFileSync(join(runtimeProjectDir, 'dist', 'declarations.ndjson'), declarationsText, 'utf-8')

  writeFileSync(
    join(runtimeProjectDir, '.cogna', 'sbom.spdx.json'),
    JSON.stringify(
      {
        spdxVersion: 'SPDX-2.3',
        SPDXID: 'SPDXRef-DOCUMENT',
        name: 'sdkacceptance',
        packages: [
          {
            SPDXID: 'SPDXRef-Root',
            name: 'sdkacceptance',
            versionInfo: '0.1.0',
          },
          {
            SPDXID: 'SPDXRef-Package-UUID',
            name: 'github.com/google/uuid',
            versionInfo: '1.6.0',
            externalRefs: [
              {
                referenceCategory: 'PACKAGE-MANAGER',
                referenceType: 'purl',
                referenceLocator: 'pkg:golang/github.com/google/uuid@1.6.0',
              },
            ],
          },
          {
            SPDXID: 'SPDXRef-Package-LO',
            name: 'github.com/samber/lo',
            versionInfo: '1.49.1',
            externalRefs: [
              {
                referenceCategory: 'PACKAGE-MANAGER',
                referenceType: 'purl',
                referenceLocator: 'pkg:golang/github.com/samber/lo@1.49.1',
              },
            ],
          },
        ],
        relationships: [
          {
            spdxElementId: 'SPDXRef-Root',
            relationshipType: 'DEPENDS_ON',
            relatedSpdxElement: 'SPDXRef-Package-UUID',
          },
          {
            spdxElementId: 'SPDXRef-Root',
            relationshipType: 'DEPENDS_ON',
            relatedSpdxElement: 'SPDXRef-Package-LO',
          },
        ],
      },
      null,
      2,
    ),
    'utf-8',
  )

  writeFileSync(
    join(runtimeProjectDir, 'dist', 'manifest.ndjson'),
    `${JSON.stringify({ purl: 'pkg:golang/example/sdkacceptance@0.1.0' })}\n`,
    'utf-8',
  )
}

describe('FetchPackages', () => {
  const fixture = loadFixture('fetch-packages.json')

  it('parses FetchPackagesRequest from fixture input', () => {
    const req = parseFetchPackagesRequest(fixture.input)
    expect(req).toEqual({})
  })

  it('parses FetchPackagesResponse with nested children', () => {
    const res = must(parseFetchPackagesResponse(fixture.output), 'expected fetch packages response')
    expect(res.root.name).toBe('example/sdkacceptance')
    expect(res.root.relation).toBe('root')
    expect(res.root.children).toHaveLength(2)
    const lo = res.root.children[1]
    expect(lo.name).toBe('github.com/samber/lo')
    expect(lo.children).toHaveLength(1)
    expect(lo.children[0]?.relation).toBe('transitive')
  })

  it('returns undefined for invalid FetchPackagesResponse input', () => {
    expect(parseFetchPackagesResponse(null)).toBeUndefined()
    expect(parseFetchPackagesResponse({ root: null })).toBeUndefined()
  })
})

describe('QueryOutlines', () => {
  const fixture = loadFixture('query-outlines.json')

  it('parses QueryOutlinesRequest from fixture input', () => {
    const req = must(parseQueryOutlinesRequest(fixture.input), 'expected query outlines request')
    expect(req.package).toBe('example/sdkacceptance')
  })

  it('parses QueryOutlinesResponse with locations', () => {
    const res = must(parseQueryOutlinesResponse(fixture.output), 'expected query outlines response')
    expect(res.outlines).toHaveLength(4)
    const first = res.outlines[0]
    expect(first?.id).toBe('decl:go:example/sdkacceptance.Greeter')
    expect(first?.kind).toBe('type')
    const location = must(first?.location, 'expected first outline location')
    expect(location.startLine).toBe(12)
    expect(location.endLine).toBe(14)
  })
})

describe('Query request/response parsing', () => {
  const exactIdFixture = loadFixture('query-exact-id.json')
  const exactSymbolFixture = loadFixture('query-exact-symbol.json')
  const fuzzyFixture = loadFixture('query-fuzzy-text.json')

  it('parses and serializes exact-id requests', () => {
    const req = must(parseQueryRequest(exactIdFixture.input), 'expected exact-id request')
    expect(req.exactId).toBe('decl:go:example/sdkacceptance.Greeter')
    expect(req.exactSymbol).toBeUndefined()
    expect(serializeQueryRequest(req)).toHaveProperty('exact_id', 'decl:go:example/sdkacceptance.Greeter')
  })

  it('parses exact-symbol responses', () => {
    const res = must(parseQueryResponse(exactSymbolFixture.output), 'expected exact-symbol response')
    expect(res.mode).toBe('exact-symbol')
    expect(res.matches[0]?.kind).toBe('method')
  })

  it('parses fuzzy-text response scores and locations', () => {
    const res = must(parseQueryResponse(fuzzyFixture.output), 'expected fuzzy-text response')
    expect(res.mode).toBe('fuzzy-text')
    expect(res.matches).toHaveLength(2)
    expect(res.matches[0]?.score).toBeCloseTo(0.94)
    const firstLocation = must(res.matches[0]?.location, 'expected first fuzzy match location')
    expect(firstLocation.startLine).toBeGreaterThan(0)
    expect(firstLocation.endLine).toBeGreaterThanOrEqual(firstLocation.startLine)
  })
})

describe('Real ndjson data', () => {
  const ndjsonPath = join(fixturesDir, 'declarations.ndjson')
  let records: NdjsonRecord[] = []

  beforeAll(() => {
    records = readFileSync(ndjsonPath, 'utf-8')
      .split('\n')
      .filter((line) => line.trim() !== '')
      .map((line) => JSON.parse(line) as NdjsonRecord)
  })

  it('loads 4 declaration records from ndjson', () => {
    expect(records).toHaveLength(4)
  })

  it('parses outlines from ndjson-derived objects', () => {
    const outlines = records.map((record) => ({
      id: record.id,
      symbol: record.canonical_name,
      kind: record.kind,
      summary: record.docs,
      deprecated: false,
      location: record.location,
    }))
    const res = must(
      parseQueryOutlinesResponse({ package: 'example/sdkacceptance', outlines }),
      'expected outlines response from ndjson',
    )
    expect(res.outlines).toHaveLength(4)
    const first = res.outlines[0]
    expect(first?.symbol).toBe('Greeter')
    expect(first?.location?.startLine).toBe(12)
  })

  it('parses exact-id and fuzzy-text matches from ndjson-derived objects', () => {
    const greeter = must(records.find((record) => record.id === 'decl:go:example/sdkacceptance.Greeter'), 'expected Greeter record')
    const buildLabels = must(records.find((record) => record.name === 'BuildLabels'), 'expected BuildLabels record')

    const exactId = must(
      parseQueryResponse({
        package: 'example/sdkacceptance',
        mode: 'exact-id',
        matches: [{ id: greeter.id, symbol: greeter.canonical_name, kind: greeter.kind, summary: greeter.docs, location: greeter.location, score: 1.0 }],
      }),
      'expected exact-id response',
    )
    expect(exactId.matches[0]?.symbol).toBe('Greeter')

    const fuzzy = must(
      parseQueryResponse({
        package: 'example/sdkacceptance',
        mode: 'fuzzy-text',
        matches: [{ id: buildLabels.id, symbol: buildLabels.canonical_name, kind: buildLabels.kind, summary: buildLabels.docs, location: buildLabels.location, score: 0.87 }],
      }),
      'expected fuzzy-text response',
    )
    expect(fuzzy.matches[0]?.symbol).toBe('BuildLabels')
    expect(fuzzy.matches[0]?.score).toBeCloseTo(0.87)
  })
})

describe('Direct MoonBit readonly facade', () => {
  const previousCwd = process.cwd()
  const queryOutlinesFixture = loadFixture('query-outlines.json')
  const queryExactIdFixture = loadFixture('query-exact-id.json')
  const queryExactSymbolFixture = loadFixture('query-exact-symbol.json')
  const queryFuzzyTextFixture = loadFixture('query-fuzzy-text.json')

  beforeAll(() => {
    rmSync(runtimeProjectDir, { recursive: true, force: true })
    writeRuntimeProjectFiles()
    process.chdir(runtimeProjectDir)
  })

  afterAll(() => {
    process.chdir(previousCwd)
    rmSync(runtimeProjectDir, { recursive: true, force: true })
  })

  it('fetchPackages returns package data from current project dist artifacts', () => {
    const res = must(fetchPackages(), 'expected fetchPackages result')
    expect(res.root.name).toBe('sdkacceptance')
    expect(res.root.relation).toBe('root')
    expect(res.root.children.length).toBeGreaterThan(0)
  })

  it('queryOutlines returns typed outlines from the compiled MoonBit runtime', () => {
    writeRuntimeProjectFiles()
    const req = must(parseQueryOutlinesRequest(queryOutlinesFixture.input), 'expected queryOutlines request')
    const res = must(queryOutlines(req), 'expected queryOutlines result')
    expect(res.package).toBe('example/sdkacceptance')
    expect(res.outlines).toHaveLength(4)
    expect(res.outlines[0]?.id).toBe(queryOutlinesFixture.output.outlines[0].id)
    expect(res.outlines[0]?.symbol).toBe(queryOutlinesFixture.output.outlines[0].symbol)
    expect(res.outlines[0]?.location?.startLine).toBe(queryOutlinesFixture.output.outlines[0].location.start_line)
  })

  it('query supports exact-id through the direct facade', () => {
    writeRuntimeProjectFiles()
    const req = must(parseQueryRequest(queryExactIdFixture.input), 'expected exact-id request')
    const res = must(query(req), 'expected exact-id result')
    expect(res.mode).toBe('exact-id')
    expect(res.matches.length).toBeGreaterThan(0)
    expect(res.matches.some((match) => match.id === queryExactIdFixture.output.matches[0].id)).toBe(true)
  })

  it('query supports exact-symbol through the direct facade', () => {
    writeRuntimeProjectFiles()
    const req = must(parseQueryRequest(queryExactSymbolFixture.input), 'expected exact-symbol request')
    const res = must(query(req), 'expected exact-symbol result')
    expect(res.mode).toBe('exact-symbol')
    expect(res.matches[0]?.symbol).toBe(queryExactSymbolFixture.output.matches[0].symbol)
  })

  it('query supports fuzzy-text through the direct facade', () => {
    writeRuntimeProjectFiles()
    const req = must(
      parseQueryRequest({
        ...queryFuzzyTextFixture.input,
        text: 'BuildLabel',
      }),
      'expected fuzzy-text request',
    )
    const res = must(query(req), 'expected fuzzy-text result')
    expect(res.mode).toBe('fuzzy-text')
    expect(res.matches.length).toBeGreaterThan(0)
  })
})
