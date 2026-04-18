import {
  fetch_packages,
  query_outlines,
  query,
} from './runtime/sdk.runtime.js'

import {
  parseFetchPackagesResponse,
  parseQueryOutlinesResponse,
  parseQueryResponse,
  serializeQueryOutlinesRequest,
  serializeQueryRequest,
} from './generated/query.js'
import type {
  QueryOutlinesRequest,
  QueryOutlinesResponse,
  QueryRequest,
  QueryResponse,
  FetchPackagesResponse,
} from './generated/query.js'

type RawSdk = {
  fetch_packages(req: undefined): unknown
  query_outlines(req: unknown): unknown
  query(req: unknown): unknown
}

const rawSdk: RawSdk = {
  fetch_packages: fetch_packages as (req: undefined) => unknown,
  query_outlines: query_outlines as (req: unknown) => unknown,
  query: query as (req: unknown) => unknown,
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
  querySdk as query,
}
