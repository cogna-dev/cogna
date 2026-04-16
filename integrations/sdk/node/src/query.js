import { run_query_json } from './moonbit/query.js'
import { errorResult, ok, parseJsonText, toJsonText, unwrapMoonBitResult } from './shared.js'

function normalizeIndex(index) {
  if (!index || typeof index !== 'object') {
    return errorResult('index must be an object')
  }
  if (!Array.isArray(index.declarations)) {
    return errorResult('index declarations must be an array')
  }
  if (!Array.isArray(index.symbols)) {
    return errorResult('index symbols must be an array')
  }
  return ok({
    profile: typeof index.profile === 'string' && index.profile !== '' ? index.profile : 'unknown',
    declarations: index.declarations,
    symbols: index.symbols,
    softwareComponents: Array.isArray(index.softwareComponents) ? index.softwareComponents : [],
    manifest: index.manifest,
  })
}

export function runQuery(index, query) {
  const indexOut = normalizeIndex(index)
  if (!indexOut.ok) {
    return indexOut
  }
  const indexTextOut = toJsonText(indexOut.value, 'local index handle')
  if (!indexTextOut.ok) {
    return indexTextOut
  }
  const queryTextOut = toJsonText(query, 'query')
  if (!queryTextOut.ok) {
    return queryTextOut
  }
  const resultOut = unwrapMoonBitResult(run_query_json(indexTextOut.value, queryTextOut.value))
  if (!resultOut.ok) {
    return resultOut
  }
  const parsedOut = parseJsonText(resultOut.value, 'ciq-result/v1 output')
  if (!parsedOut.ok) {
    return parsedOut
  }
  return ok(parsedOut.value)
}
