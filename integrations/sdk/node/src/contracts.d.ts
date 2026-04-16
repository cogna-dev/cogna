import type { JsonSchema } from './types'

export interface ValidationIssue {
  path: string
  message: string
}

export type ValidationResult =
  | { ok: true }
  | { ok: false; message: string; issues?: ValidationIssue[] }

export function ciqBundleV1Schema(): JsonSchema
export function ciqQueryV1Schema(): JsonSchema
export function ciqResultV1Schema(): JsonSchema

export function validateCiqBundleV1(value: unknown): ValidationResult
export function validateCiqQueryV1(value: unknown): ValidationResult
export function validateCiqResultV1(value: unknown): ValidationResult
