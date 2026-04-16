import {
  ciq_bundle_v1_schema_json,
  ciq_query_v1_schema_json,
  ciq_result_v1_schema_json,
  validate_ciq_bundle_v1_json,
  validate_ciq_query_v1_json,
  validate_ciq_result_v1_json,
} from './moonbit/contracts.js'
import { parseJsonText, parseValidationReport, toJsonText } from './shared.js'

function parseRequiredJson(text, label) {
  const out = parseJsonText(text, label)
  if (!out.ok) {
    throw new Error(out.error.message)
  }
  return out.value
}

function validateWith(validator, value, label) {
  const valueOut = toJsonText(value, label)
  if (!valueOut.ok) {
    return { ok: false, message: valueOut.error.message }
  }
  return parseValidationReport(validator(valueOut.value), `${label} validation report`)
}

export function ciqBundleV1Schema() {
  return parseRequiredJson(ciq_bundle_v1_schema_json(), 'ciq-bundle/v1 schema')
}

export function ciqQueryV1Schema() {
  return parseRequiredJson(ciq_query_v1_schema_json(), 'ciq-query/v1 schema')
}

export function ciqResultV1Schema() {
  return parseRequiredJson(ciq_result_v1_schema_json(), 'ciq-result/v1 schema')
}

export function validateCiqBundleV1(value) {
  return validateWith(validate_ciq_bundle_v1_json, value, 'ciq-bundle/v1 value')
}

export function validateCiqQueryV1(value) {
  return validateWith(validate_ciq_query_v1_json, value, 'ciq-query/v1 value')
}

export function validateCiqResultV1(value) {
  return validateWith(validate_ciq_result_v1_json, value, 'ciq-result/v1 value')
}
