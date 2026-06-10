import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  apiGetJson,
  apiParseEnvelope,
  apiPostJson,
  buildTenantHeaders,
  resolveApiTransportMode,
} from './httpClient'

afterEach(() => {
  delete (globalThis as { __PIX2PI_API_TRANSPORT_MODE__?: string })
    .__PIX2PI_API_TRANSPORT_MODE__
})

describe('httpClient', () => {
  it('tenant header bos ise bos object doner', () => {
    expect(buildTenantHeaders('')).toEqual({})
  })

  it('tenant header dolu ise normalize edilmis header doner', () => {
    expect(buildTenantHeaders('tr01')).toEqual({
      'X-Tenant-ID': 'TR01',
    })
  })

  it('explicit transport mode onceliklidir', () => {
    expect(resolveApiTransportMode('live')).toBe('live')
    expect(resolveApiTransportMode('mock')).toBe('mock')
  })

  it('runtime transport override okunur', () => {
    ;(globalThis as { __PIX2PI_API_TRANSPORT_MODE__?: string })
      .__PIX2PI_API_TRANSPORT_MODE__ = 'live'

    expect(resolveApiTransportMode()).toBe('live')
  })

  it('success envelope parse eder', () => {
    const parsed = apiParseEnvelope<{ value: number }>(
      {
        success: true,
        data: { value: 42 },
        meta: {
          request_id: 'req-1',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'test.source',
        },
      },
      'fallback.source',
    )

    expect(parsed.success).toBe(true)

    if (parsed.success) {
      expect(parsed.data.value).toBe(42)
      expect(parsed.meta.requestId).toBe('req-1')
      expect(parsed.meta.source).toBe('test.source')
    }
  })

  it('error envelope parse eder', () => {
    const parsed = apiParseEnvelope(
      {
        success: false,
        error: {
          code: 'BAD_REQUEST',
          message: 'Hatali istek',
        },
        meta: {
          request_id: 'req-2',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'test.source',
        },
      },
      'fallback.source',
    )

    expect(parsed.success).toBe(false)

    if (!parsed.success) {
      expect(parsed.error.code).toBe('BAD_REQUEST')
      expect(parsed.error.message).toBe('Hatali istek')
      expect(parsed.meta.requestId).toBe('req-2')
    }
  })

  it('GET helper json response parse eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () => JSON.stringify({ ok: true }),
    })

    const result = await apiGetJson<{ ok: boolean }>('/api/test', {
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(result.ok).toBe(true)
  })

  it('POST helper body gonderir ve response parse eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () => JSON.stringify({ saved: true }),
    })

    const result = await apiPostJson<{ saved: boolean }, { name: string }>(
      '/api/test',
      { name: 'pix2pi' },
      { fetcher },
    )

    expect(fetcher).toHaveBeenCalled()
    const callArgs = fetcher.mock.calls[0]?.[1]
    expect(callArgs.method).toBe('POST')
    expect(callArgs.body).toBe(JSON.stringify({ name: 'pix2pi' }))
    expect(result.saved).toBe(true)
  })
})
