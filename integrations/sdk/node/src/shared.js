export function ok(value) {
  return { ok: true, value }
}

export function errorResult(message) {
  return { ok: false, error: { message } }
}

export function unwrapMoonBitResult(result) {
  if (result && result.$tag === 1) {
    return ok(result._0)
  }
  if (result && result.$tag === 0) {
    return errorResult(normalizeMessage(result._0))
  }
  return errorResult('unexpected MoonBit result')
}

export function normalizeMessage(value) {
  if (typeof value === 'string' && value !== '') {
    return value
  }
  if (value && typeof value.message === 'string' && value.message !== '') {
    return value.message
  }
  if (value instanceof Error && value.message) {
    return value.message
  }
  return String(value ?? 'unknown error')
}

export function parseJsonText(text, label) {
  try {
    return ok(JSON.parse(text))
  } catch (error) {
    return errorResult(`${label} is not valid JSON: ${normalizeMessage(error)}`)
  }
}

export function toJsonText(value, label) {
  try {
    const text = JSON.stringify(value)
    if (typeof text !== 'string') {
      return errorResult(`${label} must be JSON-serializable`)
    }
    return ok(text)
  } catch (error) {
    return errorResult(`${label} must be JSON-serializable: ${normalizeMessage(error)}`)
  }
}

export function parseNdjsonText(text, label) {
  const values = []
  const lines = text.split(/\r?\n/u)
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index].trim()
    if (line === '') {
      continue
    }
    try {
      values.push(JSON.parse(line))
    } catch (error) {
      return errorResult(
        `${label} contains invalid NDJSON at line ${index + 1}: ${normalizeMessage(error)}`,
      )
    }
  }
  return ok(values)
}

export function parseValidationReport(text, label) {
  const reportOut = parseJsonText(text, label)
  if (!reportOut.ok) {
    return { ok: false, message: reportOut.error.message }
  }
  const report = reportOut.value
  if (report && report.ok === true) {
    return { ok: true }
  }
  const issues = Array.isArray(report?.issues)
    ? report.issues
        .filter(
          issue => issue && typeof issue.path === 'string' && typeof issue.message === 'string',
        )
        .map(issue => ({ path: issue.path, message: issue.message }))
    : undefined
  return {
    ok: false,
    message:
      report && typeof report.message === 'string' && report.message !== ''
        ? report.message
        : `${label} failed validation`,
    issues,
  }
}
