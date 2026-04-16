export type { JsonPrimitive, JsonObject, JsonValue, JsonSchema } from './types'
export type * from './generated/index.js'
export type {
  RecordLocation,
  SourceRef,
  Relation,
  ShapeInfo,
  LanguageSpecific,
  DeclarationRecord,
  SymbolRecord,
  SoftwareComponentRecord,
  CiqQuerySelector,
  CiqQueryV1,
  QueryMatch,
  CiqResultV1,
} from './types'

export type { ValidationIssue, ValidationResult } from './contracts'
export {
  ciqBundleV1Schema,
  ciqQueryV1Schema,
  ciqResultV1Schema,
  validateCiqBundleV1,
  validateCiqQueryV1,
  validateCiqResultV1,
} from './contracts'

export type {
  Result,
  SdkError,
  LocalIndexBuildInput,
  LocalIndexManifest,
  LocalIndexHandle,
  LocalIndexFiles,
} from './index-api'
export { buildLocalIndex, writeLocalIndex, loadLocalIndex } from './index-api'

export type { QueryError } from './query'
export { runQuery } from './query'
