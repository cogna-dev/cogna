import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { build_local_index_native_json } from './moonbit/index.js'
import { errorResult, normalizeMessage, ok, parseJsonText, parseNdjsonText, unwrapMoonBitResult } from './shared.js'

const DEFAULT_PURL = 'pkg:generic/codeiq-local@0.0.0'
const LOCAL_INDEX_SCHEMA_VERSION = 'codeiq-local-index/v1'

function normalizeBuildInput(input) {
  if (!input || typeof input !== 'object') {
    return errorResult('build input must be an object')
  }
  const rootDir = typeof input.rootDir === 'string' && input.rootDir !== '' ? resolve(input.rootDir) : null
  if (rootDir == null) {
    return errorResult('build input rootDir must be a non-empty string')
  }
  const profile = typeof input.profile === 'string' && input.profile !== '' ? input.profile : null
  if (profile == null) {
    return errorResult('build input profile must be a non-empty string')
  }
  if (!Array.isArray(input.include) || input.include.some(value => typeof value !== 'string' || value === '')) {
    return errorResult('build input include must be an array of non-empty strings')
  }
  const purl = typeof input.purl === 'string' && input.purl !== '' ? input.purl : DEFAULT_PURL
  const outDir =
    typeof input.outDir === 'string' && input.outDir !== ''
      ? resolve(rootDir, input.outDir)
      : resolve(rootDir, 'dist')
  return ok({
    rootDir,
    profile,
    include: [...input.include],
    outDir,
    purl,
  })
}

function parseBuildOutput(text) {
  const payloadOut = parseJsonText(text, 'local index build output')
  if (!payloadOut.ok) {
    return payloadOut
  }
  const payload = payloadOut.value
  if (typeof payload?.declarationsText !== 'string') {
    return errorResult('local index build output is missing declarationsText')
  }
  if (typeof payload?.symbolsText !== 'string') {
    return errorResult('local index build output is missing symbolsText')
  }
  return ok(payload)
}

function manifestFromPayload(input, payload) {
  return {
    schemaVersion: LOCAL_INDEX_SCHEMA_VERSION,
    profile: input.profile,
    mode: typeof payload.mode === 'string' ? payload.mode : 'native-assisted',
    fallback: payload.fallback === true,
    declarationCount: Number.isInteger(payload.declarationCount) ? payload.declarationCount : 0,
    symbolCount: Number.isInteger(payload.symbolCount) ? payload.symbolCount : 0,
    diagnosticFiles: Number.isInteger(payload.diagnosticFiles) ? payload.diagnosticFiles : 0,
    commit: typeof payload.commit === 'string' && payload.commit !== '' ? payload.commit : 'unknown',
    rootDir: input.rootDir,
    outDir: input.outDir,
  }
}

function handleFromArtifacts(input, payload) {
  const declarationsOut = parseNdjsonText(payload.declarationsText, 'declarations.ndjson')
  if (!declarationsOut.ok) {
    return declarationsOut
  }
  const symbolsOut = parseNdjsonText(payload.symbolsText, 'symbols.ndjson')
  if (!symbolsOut.ok) {
    return symbolsOut
  }
  const manifest = manifestFromPayload(input, payload)
  return ok({
    profile: input.profile,
    declarations: declarationsOut.value,
    symbols: symbolsOut.value,
    softwareComponents: [],
    manifest,
  })
}

function buildArtifacts(input) {
  const inputOut = normalizeBuildInput(input)
  if (!inputOut.ok) {
    return inputOut
  }
  const normalized = inputOut.value
  const moonbitOut = unwrapMoonBitResult(
    build_local_index_native_json(
      normalized.rootDir,
      normalized.profile,
      normalized.purl,
      normalized.include,
    ),
  )
  if (!moonbitOut.ok) {
    return moonbitOut
  }
  const payloadOut = parseBuildOutput(moonbitOut.value)
  if (!payloadOut.ok) {
    return payloadOut
  }
  const handleOut = handleFromArtifacts(normalized, payloadOut.value)
  if (!handleOut.ok) {
    return handleOut
  }
  return ok({
    input: normalized,
    payload: payloadOut.value,
    handle: handleOut.value,
  })
}

function resolveIndexDir(indexPath) {
  const base = resolve(indexPath)
  const directDeclarations = resolve(base, 'declarations.ndjson')
  const directSymbols = resolve(base, 'symbols.ndjson')
  if (existsSync(directDeclarations) || existsSync(directSymbols)) {
    return base
  }
  return resolve(base, 'dist')
}

function readOptionalJson(path) {
  if (!existsSync(path)) {
    return undefined
  }
  try {
    return JSON.parse(readFileSync(path, 'utf8'))
  } catch {
    return undefined
  }
}

export function buildLocalIndex(input) {
  const artifactsOut = buildArtifacts(input)
  if (!artifactsOut.ok) {
    return artifactsOut
  }
  return ok(artifactsOut.value.handle)
}

export function writeLocalIndex(input) {
  const artifactsOut = buildArtifacts(input)
  if (!artifactsOut.ok) {
    return artifactsOut
  }
  const { input: normalized, payload, handle } = artifactsOut.value
  const manifestPath = resolve(normalized.outDir, 'manifest.json')
  const declarationsPath = resolve(normalized.outDir, 'declarations.ndjson')
  const symbolsPath = resolve(normalized.outDir, 'symbols.ndjson')
  try {
    mkdirSync(normalized.outDir, { recursive: true })
    writeFileSync(declarationsPath, payload.declarationsText)
    writeFileSync(symbolsPath, payload.symbolsText)
    writeFileSync(manifestPath, JSON.stringify(handle.manifest, null, 2))
    return ok({
      rootDir: normalized.rootDir,
      manifestPath,
      declarationsPath,
      symbolsPath,
    })
  } catch (error) {
    return errorResult(`failed to write local index: ${normalizeMessage(error)}`)
  }
}

export function loadLocalIndex(indexPath) {
  if (typeof indexPath !== 'string' || indexPath === '') {
    return errorResult('index path must be a non-empty string')
  }
  const indexDir = resolveIndexDir(indexPath)
  const declarationsPath = resolve(indexDir, 'declarations.ndjson')
  const symbolsPath = resolve(indexDir, 'symbols.ndjson')
  if (!existsSync(declarationsPath) || !existsSync(symbolsPath)) {
    return errorResult('local index files not found')
  }
  try {
    const declarationsOut = parseNdjsonText(readFileSync(declarationsPath, 'utf8'), declarationsPath)
    if (!declarationsOut.ok) {
      return declarationsOut
    }
    const symbolsOut = parseNdjsonText(readFileSync(symbolsPath, 'utf8'), symbolsPath)
    if (!symbolsOut.ok) {
      return symbolsOut
    }
    const componentsPath = resolve(indexDir, 'software-components.ndjson')
    const softwareComponentsOut = existsSync(componentsPath)
      ? parseNdjsonText(readFileSync(componentsPath, 'utf8'), componentsPath)
      : ok([])
    if (!softwareComponentsOut.ok) {
      return softwareComponentsOut
    }
    const manifestPath = resolve(indexDir, 'manifest.json')
    const manifest = readOptionalJson(manifestPath)
    return ok({
      profile: typeof manifest?.profile === 'string' ? manifest.profile : 'unknown',
      declarations: declarationsOut.value,
      symbols: symbolsOut.value,
      softwareComponents: softwareComponentsOut.value,
      manifest,
    })
  } catch (error) {
    return errorResult(`failed to load local index: ${normalizeMessage(error)}`)
  }
}
