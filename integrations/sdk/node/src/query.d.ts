import type { LocalIndexHandle, Result, SdkError } from './index-api'
import type { CiqQueryV1, CiqResultV1 } from './types'

export interface QueryError extends SdkError {}

export function runQuery(
  index: LocalIndexHandle,
  query: CiqQueryV1,
): Result<CiqResultV1, QueryError>
