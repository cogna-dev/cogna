export const POLICY_INDEX_URL = "https://codeiq.xaclabs.dev/docs/policies"

export function resolveDocumentationUrl(helpUri?: string): string {
  const trimmed = helpUri?.trim()
  if (!trimmed) {
    return POLICY_INDEX_URL
  }
  return trimmed
}

export async function openDocumentation(
  opener: (target: string) => Promise<unknown> | unknown,
  helpUri?: string,
): Promise<string> {
  const target = resolveDocumentationUrl(helpUri)
  await opener(target)
  return target
}
