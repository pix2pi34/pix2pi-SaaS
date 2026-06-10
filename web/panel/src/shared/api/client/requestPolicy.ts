import type { ApiErrorEnvelope } from '../contracts/api.types'
import type { ApiTransportMode } from './httpClient'

export type ApiErrorKind =
  | 'network'
  | 'timeout'
  | 'unauthorized'
  | 'forbidden'
  | 'invalid_response'
  | 'tenant_invalid'
  | 'tenant_mismatch'
  | 'tenant_security'
  | 'unknown'

export type ApiErrorClassification = {
  kind: ApiErrorKind
  codeSuffix: string
  message: string
  retryable: boolean
  fallbackEligible: boolean
  staleEligible: boolean
}

type RetryOptions = {
  method?: 'GET' | 'POST'
  maxRetries?: number
  retryDelayMs?: number
}

function readErrorMessage(error: unknown) {
  if (error instanceof Error) {
    return error.message
  }

  if (typeof error === 'string') {
    return error
  }

  return 'UNKNOWN_ERROR'
}

export function classifyApiError(error: unknown): ApiErrorClassification {
  const rawMessage = readErrorMessage(error)
  const normalized = rawMessage.trim().toUpperCase()
  const lowered = rawMessage.trim().toLowerCase()

  if (normalized === 'HTTP_401') {
    return {
      kind: 'unauthorized',
      codeSuffix: 'UNAUTHORIZED',
      message: 'Oturum gecersiz veya suresi dolmus.',
      retryable: false,
      fallbackEligible: false,
      staleEligible: false,
    }
  }

  if (normalized === 'HTTP_403') {
    return {
      kind: 'forbidden',
      codeSuffix: 'FORBIDDEN',
      message: 'Bu islem icin yetkiniz yok.',
      retryable: false,
      fallbackEligible: false,
      staleEligible: false,
    }
  }

  if (normalized === 'REQUEST_TIMEOUT') {
    return {
      kind: 'timeout',
      codeSuffix: 'TIMEOUT',
      message: 'Istek zaman asimina ugradi.',
      retryable: true,
      fallbackEligible: true,
      staleEligible: true,
    }
  }

  if (normalized === 'INVALID_JSON_RESPONSE') {
    return {
      kind: 'invalid_response',
      codeSuffix: 'INVALID_RESPONSE',
      message: 'Servis gecersiz cevap dondu.',
      retryable: false,
      fallbackEligible: true,
      staleEligible: true,
    }
  }

  if (normalized.includes('INVALID_TENANT')) {
    return {
      kind: 'tenant_invalid',
      codeSuffix: 'INVALID_TENANT',
      message: 'Gecersiz tenant kodu.',
      retryable: false,
      fallbackEligible: false,
      staleEligible: false,
    }
  }

  if (normalized.includes('MISMATCH')) {
    return {
      kind: 'tenant_mismatch',
      codeSuffix: 'MISMATCH',
      message: 'Backend tenant baglami istenen tenant ile eslesmiyor.',
      retryable: false,
      fallbackEligible: false,
      staleEligible: false,
    }
  }

  if (
    normalized.includes('CROSS_TENANT_LEAK') ||
    normalized.includes('TENANT_SECURITY')
  ) {
    return {
      kind: 'tenant_security',
      codeSuffix: 'CROSS_TENANT_LEAK',
      message: 'Cevap icinde istenmeyen tenant verisi bulundu.',
      retryable: false,
      fallbackEligible: false,
      staleEligible: false,
    }
  }

  if (
    lowered.includes('network down') ||
    lowered.includes('failed to fetch') ||
    lowered.includes('networkerror') ||
    lowered.includes('fetch failed') ||
    lowered.includes('connection reset')
  ) {
    return {
      kind: 'network',
      codeSuffix: 'NETWORK',
      message: 'Ag baglantisi kurulamadigi icin istek tamamlanamadi.',
      retryable: true,
      fallbackEligible: true,
      staleEligible: true,
    }
  }

  return {
    kind: 'unknown',
    codeSuffix: 'REQUEST_FAILED',
    message: rawMessage || 'Istek basarisiz.',
    retryable: false,
    fallbackEligible: true,
    staleEligible: true,
  }
}

export function shouldRetryRequest(
  error: unknown,
  options: RetryOptions = {},
  attempt = 0,
) {
  const classification = classifyApiError(error)
  const method = options.method ?? 'GET'
  const maxRetries = options.maxRetries ?? 2

  return method === 'GET' && classification.retryable && attempt < maxRetries
}

function wait(ms: number) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms)
  })
}

export async function executeRequestWithRetry<T>(
  executor: () => Promise<T>,
  options: RetryOptions = {},
): Promise<T> {
  const retryDelayMs = options.retryDelayMs ?? 25
  let attempt = 0

  while (true) {
    try {
      return await executor()
    } catch (error) {
      if (!shouldRetryRequest(error, options, attempt)) {
        throw error
      }

      attempt += 1
      await wait(retryDelayMs * attempt)
    }
  }
}

export function shouldUseMockFallback(
  transportMode: ApiTransportMode,
  error: unknown,
) {
  if (transportMode !== 'hybrid') {
    return false
  }

  return classifyApiError(error).fallbackEligible
}

export function shouldKeepStaleData(error: unknown) {
  return classifyApiError(error).staleEligible
}

export function buildApiErrorEnvelope(
  source: string,
  error: unknown,
  requestPrefix: string,
  codePrefix = 'API',
): ApiErrorEnvelope {
  const classification = classifyApiError(error)

  return {
    success: false,
    error: {
      code: `${codePrefix}_${classification.codeSuffix}`,
      message: classification.message,
    },
    meta: {
      requestId: `${requestPrefix}-${Math.random().toString(36).slice(2, 10)}`,
      timestamp: new Date().toISOString(),
      source,
    },
  }
}
