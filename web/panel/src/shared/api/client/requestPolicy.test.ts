import { describe, expect, it, vi } from 'vitest'
import {
  buildApiErrorEnvelope,
  classifyApiError,
  executeRequestWithRetry,
  shouldKeepStaleData,
  shouldRetryRequest,
  shouldUseMockFallback,
} from './requestPolicy'

describe('requestPolicy', () => {
  it('timeout error retryable ve fallback eligible olur', () => {
    const classified = classifyApiError(new Error('REQUEST_TIMEOUT'))

    expect(classified.kind).toBe('timeout')
    expect(classified.retryable).toBe(true)
    expect(classified.fallbackEligible).toBe(true)
  })

  it('401 unauthorized no-retry ve no-fallback olur', () => {
    const classified = classifyApiError(new Error('HTTP_401'))

    expect(classified.kind).toBe('unauthorized')
    expect(classified.retryable).toBe(false)
    expect(shouldUseMockFallback('hybrid', new Error('HTTP_401'))).toBe(false)
  })

  it('invalid response hybrid fallback acabilir', () => {
    expect(shouldUseMockFallback('hybrid', new Error('INVALID_JSON_RESPONSE'))).toBe(true)
  })

  it('tenant mismatch fallback acmaz ve stale data tutulmaz', () => {
    expect(shouldUseMockFallback('hybrid', new Error('TENANT_CONTEXT_MISMATCH'))).toBe(false)
    expect(shouldKeepStaleData(new Error('TENANT_CONTEXT_MISMATCH'))).toBe(false)
  })

  it('GET timeout retry edilir ama POST timeout retry edilmez', () => {
    expect(
      shouldRetryRequest(new Error('REQUEST_TIMEOUT'), { method: 'GET', maxRetries: 2 }, 0),
    ).toBe(true)

    expect(
      shouldRetryRequest(new Error('REQUEST_TIMEOUT'), { method: 'POST', maxRetries: 2 }, 0),
    ).toBe(false)
  })

  it('executeRequestWithRetry GET network hatasinda yeniden dener', async () => {
    const executor = vi
      .fn()
      .mockRejectedValueOnce(new Error('network down'))
      .mockResolvedValueOnce('ok')

    const result = await executeRequestWithRetry(executor, {
      method: 'GET',
      maxRetries: 2,
      retryDelayMs: 1,
    })

    expect(result).toBe('ok')
    expect(executor).toHaveBeenCalledTimes(2)
  })

  it('error envelope standard formatta doner', () => {
    const envelope = buildApiErrorEnvelope(
      'dashboard.contract.live',
      new Error('HTTP_403'),
      'dashboard-live-error',
      'DASHBOARD',
    )

    expect(envelope.success).toBe(false)
    expect(envelope.error.code).toBe('DASHBOARD_FORBIDDEN')
    expect(envelope.error.message).toBe('Bu islem icin yetkiniz yok.')
    expect(envelope.meta.source).toBe('dashboard.contract.live')
  })

  it('live modda network hatasi mock fallback acmaz', () => {
    expect(shouldUseMockFallback('live', new Error('network down'))).toBe(false)
  })

  it('retryable network hatasi stale data tutmaya uygun olur', () => {
    expect(shouldKeepStaleData(new Error('network down'))).toBe(true)
  })

  it('403 forbidden stale data tutulmaz', () => {
    expect(shouldKeepStaleData(new Error('HTTP_403'))).toBe(false)
  })
})
