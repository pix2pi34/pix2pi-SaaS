import type { ApiEnvelope, ApiErrorEnvelope, ApiSuccessEnvelope } from '../contracts/api.types'

export type ApiTransportMode = 'mock' | 'hybrid' | 'live'

export type ApiRequestOptions = {
  transportMode?: ApiTransportMode
  fetcher?: typeof fetch
  headers?: Record<string, string>
  timeoutMs?: number
  maxRetries?: number
  retryDelayMs?: number
}

function normalizeMode(value: string | undefined): ApiTransportMode {
  if (value === 'mock' || value === 'hybrid' || value === 'live') {
    return value
  }

  return 'hybrid'
}

function readRuntimeTransportOverride(): ApiTransportMode | undefined {
  const runtimeValue = (globalThis as { __PIX2PI_API_TRANSPORT_MODE__?: unknown })
    .__PIX2PI_API_TRANSPORT_MODE__

  return typeof runtimeValue === 'string'
    ? normalizeMode(runtimeValue)
    : undefined
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : null
}

function asString(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value : fallback
}

function buildMeta(
  input: Record<string, unknown> | null,
  fallbackSource: string,
) {
  return {
    requestId: asString(
      input?.request_id ?? input?.requestId,
      `req-${Math.random().toString(36).slice(2, 10)}`,
    ),
    timestamp: asString(
      input?.timestamp,
      new Date().toISOString(),
    ),
    source: asString(
      input?.source,
      fallbackSource,
    ),
  }
}

function createTimeoutController(timeoutMs: number) {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => {
    controller.abort()
  }, timeoutMs)

  return {
    signal: controller.signal,
    cleanup: () => clearTimeout(timeoutId),
  }
}

async function parseJsonResponse<T>(response: Response): Promise<T> {
  const text = await response.text()

  if (!text.trim()) {
    return {} as T
  }

  try {
    return JSON.parse(text) as T
  } catch {
    throw new Error('INVALID_JSON_RESPONSE')
  }
}

async function apiRequestJson<T>(
  method: 'GET' | 'POST',
  url: string,
  options: ApiRequestOptions & { body?: unknown } = {},
): Promise<T> {
  const fetcher = options.fetcher ?? globalThis.fetch

  if (!fetcher) {
    throw new Error('FETCH_API_UNAVAILABLE')
  }

  const timeoutMs = options.timeoutMs ?? 8000
  const timeoutController = createTimeoutController(timeoutMs)

  try {
    const response = await fetcher(url, {
      method,
      signal: timeoutController.signal,
      headers: {
        Accept: 'application/json',
        ...(method === 'POST' ? { 'Content-Type': 'application/json' } : {}),
        ...(options.headers ?? {}),
      },
      ...(method === 'POST' ? { body: JSON.stringify(options.body ?? {}) } : {}),
    })

    if (!response.ok) {
      throw new Error(`HTTP_${response.status}`)
    }

    return await parseJsonResponse<T>(response)
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error('REQUEST_TIMEOUT')
    }

    throw error
  } finally {
    timeoutController.cleanup()
  }
}

export function resolveApiTransportMode(
  explicitMode?: ApiTransportMode,
): ApiTransportMode {
  if (explicitMode) {
    return explicitMode
  }

  const runtimeOverride = readRuntimeTransportOverride()
  if (runtimeOverride) {
    return runtimeOverride
  }

  return normalizeMode(import.meta.env.VITE_API_TRANSPORT_MODE)
}

export function buildTenantHeaders(tenantCode: string): Record<string, string> {
  const normalized = tenantCode.trim().toUpperCase()
  const headers: Record<string, string> = {}

  if (normalized) {
    headers['X-Tenant-ID'] = normalized
  }

  return headers
}

export function apiParseEnvelope<T>(
  input: unknown,
  fallbackSource: string,
): ApiEnvelope<T> {
  const root = asRecord(input)
  const meta = buildMeta(asRecord(root?.meta), fallbackSource)

  if (root?.success === false) {
    const errorRoot = asRecord(root.error)

    const errorEnvelope: ApiErrorEnvelope = {
      success: false,
      error: {
        code: asString(errorRoot?.code, 'API_ERROR'),
        message: asString(errorRoot?.message, 'Bilinmeyen API hatasi.'),
      },
      meta,
    }

    return errorEnvelope
  }

  if (root?.success === true && 'data' in root) {
    const successEnvelope: ApiSuccessEnvelope<T> = {
      success: true,
      data: root.data as T,
      meta,
    }

    return successEnvelope
  }

  const successEnvelope: ApiSuccessEnvelope<T> = {
    success: true,
    data: ((root?.data ?? root) as T),
    meta,
  }

  return successEnvelope
}

export async function apiGetJson<T>(
  url: string,
  options: ApiRequestOptions = {},
): Promise<T> {
  return apiRequestJson<T>('GET', url, options)
}

export async function apiPostJson<TResponse, TBody = Record<string, unknown>>(
  url: string,
  body: TBody,
  options: ApiRequestOptions = {},
): Promise<TResponse> {
  return apiRequestJson<TResponse>('POST', url, {
    ...options,
    body,
  })
}
