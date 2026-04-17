import {
  build,
  diff,
  fetch_packages,
  query_outlines,
  query,
} from '../../../../_build/js/debug/build/sdk/sdk.js'

import { parseBuildResponse } from './generated/build.js'
import { parseDiffResponse, serializeDiffRequest } from './generated/diff.js'
import {
  parseFetchPackagesResponse,
  parseQueryOutlinesResponse,
  parseQueryResponse,
  serializeQueryOutlinesRequest,
  serializeQueryRequest,
} from './generated/query.js'

import type { BuildResponse } from './generated/build.js'
import type { DiffRequest, DiffResponse } from './generated/diff.js'
import type {
  QueryOutlinesRequest,
  QueryOutlinesResponse,
  QueryRequest,
  QueryResponse,
  FetchPackagesResponse,
} from './generated/query.js'

type RawSdk = {
  build(req: undefined): unknown
  diff(req: unknown): unknown
  fetch_packages(req: undefined): unknown
  query_outlines(req: unknown): unknown
  query(req: unknown): unknown
}

const rawSdk: RawSdk = {
  build: build as (req: undefined) => unknown,
  diff: diff as (req: unknown) => unknown,
  fetch_packages: fetch_packages as (req: undefined) => unknown,
  query_outlines: query_outlines as (req: unknown) => unknown,
  query: query as (req: unknown) => unknown,
}

export function buildSdk(): BuildResponse | undefined {
  return parseBuildResponse(rawSdk.build(undefined))
}

export function diffSdk(req: DiffRequest): DiffResponse | undefined {
  return parseDiffResponse(rawSdk.diff(serializeDiffRequest(req)))
}

export function fetchPackages(): FetchPackagesResponse | undefined {
  return parseFetchPackagesResponse(rawSdk.fetch_packages(undefined))
}

export function queryOutlines(req: QueryOutlinesRequest): QueryOutlinesResponse | undefined {
  return parseQueryOutlinesResponse(rawSdk.query_outlines(serializeQueryOutlinesRequest(req)))
}

export function querySdk(req: QueryRequest): QueryResponse | undefined {
  return parseQueryResponse(rawSdk.query(serializeQueryRequest(req)))
}

export {
  buildSdk as build,
  diffSdk as diff,
  querySdk as query,
}
