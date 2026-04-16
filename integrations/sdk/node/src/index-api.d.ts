import type {
  DeclarationRecord,
  JsonObject,
  SoftwareComponentRecord,
  SymbolRecord,
} from './types'

export interface SdkError {
  message: string
}

export type Result<T, E = SdkError> =
  | { ok: true; value: T }
  | { ok: false; error: E }

export interface LocalIndexBuildInput {
  rootDir: string
  profile: string
  include: string[]
  outDir?: string
  purl?: string
}

export interface LocalIndexManifest {
  schemaVersion: 'codeiq-local-index/v1'
  profile: string
  mode: string
  fallback: boolean
  declarationCount: number
  symbolCount: number
  diagnosticFiles: number
  commit: string
  rootDir: string
  outDir: string
}

export interface LocalIndexHandle {
  profile: string
  declarations: DeclarationRecord[]
  symbols: SymbolRecord[]
  softwareComponents?: SoftwareComponentRecord[]
  manifest?: LocalIndexManifest | JsonObject
}

export interface LocalIndexFiles {
  rootDir: string
  manifestPath?: string
  declarationsPath: string
  symbolsPath: string
  softwareComponentsPath?: string
}

export function buildLocalIndex(input: LocalIndexBuildInput): Result<LocalIndexHandle>
export function writeLocalIndex(input: LocalIndexBuildInput): Result<LocalIndexFiles>
export function loadLocalIndex(path: string): Result<LocalIndexHandle>
