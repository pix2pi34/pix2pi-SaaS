import type { ApiSuccessEnvelope } from '../contracts/api.types'

function buildRequestId(prefix: string) {
  return `${prefix}-${Math.random().toString(36).slice(2, 10)}`
}

export async function createMockSuccessEnvelope<T>({
  data,
  source,
  requestPrefix,
  delayMs = 30,
}: {
  data: T
  source: string
  requestPrefix: string
  delayMs?: number
}): Promise<ApiSuccessEnvelope<T>> {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        success: true,
        data,
        meta: {
          requestId: buildRequestId(requestPrefix),
          timestamp: new Date().toISOString(),
          source,
        },
      })
    }, delayMs)
  })
}
