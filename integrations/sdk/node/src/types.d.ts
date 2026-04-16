export type JsonPrimitive = string | number | boolean | null

export interface JsonObject {
  [key: string]: JsonValue | undefined
}

export type JsonValue = JsonPrimitive | JsonObject | JsonValue[]

export type JsonSchema = JsonObject

export interface RecordLocation extends JsonObject {
  uri: string
  startLine: number
  endLine: number
}

export interface SourceRef extends RecordLocation {}

export interface Relation extends JsonObject {
  kind: string
  target: string
}

export interface ShapeInfo extends JsonObject {
  kind: string
  subkind?: string
  form?: string
  signature?: string
  owner?: string
  parameters?: string[]
  returns?: string[]
}

export type LanguageSpecific = JsonObject

export interface DeclarationRecord extends JsonObject {
  id: string
  kind: string
  signature: string
  location: RecordLocation
  path?: string
  name?: string
  canonical_name?: string
  language?: string
  baselineRole?: string
  source_refs?: SourceRef[]
  relations?: Relation[]
  visibility?: string
  docs?: string
  shape?: ShapeInfo
  language_specific?: LanguageSpecific
}

export interface SymbolRecord extends JsonObject {
  id: string
  path: string
  kind: string
  name: string
  summary: string
  owner: string
  location: RecordLocation
}

export interface SoftwareComponentRecord extends JsonObject {
  kind?: string
  name?: string
  purl?: string
  version?: string
  location?: RecordLocation
}

export interface CiqQuerySelector extends JsonObject {
  path: string
  kind?: string
}

export interface CiqQueryV1 extends JsonObject {
  schemaVersion: 'ciq-query/v1'
  purl: string
  selector: CiqQuerySelector
  repo?: string
  intent?: string
}

export interface QueryMatch extends DeclarationRecord {}

export interface CiqResultV1 extends JsonObject {
  schemaVersion: 'ciq-result/v1'
  purl: string
  matches: QueryMatch[]
}
