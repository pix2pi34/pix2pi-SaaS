import { describe, expect, it, vi } from 'vitest'
import { fetchTenantContext } from './tenantApi'
import type { AuthSession } from '../../auth/types/auth.types'

function createSession(tenantCode: string): AuthSession {
  return {
    accessToken: 'token-1',
    refreshToken: 'token-2',
    tenantCode,
    remember: true,
    source: 'real',
  }
}

describe('tenantApi', () => {
  it('mock modda tenant context doner', async () => {
    const response = await fetchTenantContext(createSession('TR01'), {
      transportMode: 'mock',
    })

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('tenant.context.mock')
      expect(response.data.currentTenantCode).toBe('TR01')
      expect(response.data.tenants.length).toBeGreaterThan(0)
    }
  })

  it('hybrid modda fetch fail olursa mocka duser', async () => {
    const fetcher = vi.fn().mockRejectedValue(new Error('network down'))

    const response = await fetchTenantContext(createSession('TR01-FIN'), {
      transportMode: 'hybrid',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('tenant.context.mock')
      expect(response.data.currentTenantCode).toBe('TR01-FIN')
    }
  })

  it('live modda standart payloadi map eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        JSON.stringify({
          success: true,
          data: {
            current_tenant: {
              code: 'TR01-FIN',
              name: 'TR01 Finans',
            },
            tenants: [
              { id: 'tr01-fin', code: 'TR01-FIN', name: 'TR01 Finans' },
            ],
          },
          meta: {
            request_id: 'req-tenant-1',
            timestamp: '2026-04-21T00:00:00.000Z',
            source: 'backend.tenant.context',
          },
        }),
    })

    const response = await fetchTenantContext(createSession('TR01-FIN'), {
      transportMode: 'live',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    const fetchOptions = fetcher.mock.calls[0]?.[1]
    expect(fetchOptions.headers['X-Tenant-ID']).toBe('TR01-FIN')
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.tenant.context')
      expect(response.meta.requestId).toBe('req-tenant-1')
      expect(response.data.currentTenantCode).toBe('TR01-FIN')
      expect(response.data.tenants[0].code).toBe('TR01-FIN')
    }
  })

  it('live modda alternatif payloadi map eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        JSON.stringify({
          success: true,
          data: {
            tenant: {
              tenant_code: 'TR01-OPS',
            },
            items: [
              {
                id: 'ops',
                tenant_code: 'TR01-OPS',
                display_name: 'TR01 Operasyon',
              },
            ],
          },
          meta: {
            requestId: 'req-tenant-2',
            timestamp: '2026-04-21T00:00:00.000Z',
            source: 'backend.tenant.alt',
          },
        }),
    })

    const response = await fetchTenantContext(createSession('TR01-OPS'), {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.tenant.alt')
      expect(response.data.currentTenantCode).toBe('TR01-OPS')
      expect(response.data.tenants[0].name).toBe('TR01 Operasyon')
    }
  })

  it('live modda explicit empty context durumunu korur', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        JSON.stringify({
          success: true,
          data: {
            empty: true,
          },
          meta: {
            requestId: 'req-tenant-3',
            timestamp: '2026-04-21T00:00:00.000Z',
            source: 'backend.tenant.empty',
          },
        }),
    })

    const response = await fetchTenantContext(createSession('TR01'), {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.data.currentTenantCode).toBe('')
      expect(response.data.tenants).toEqual([])
    }
  })

  it('live modda 403 durumunu forbidden olarak map eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: false,
      status: 403,
      text: async () => '',
    })

    const response = await fetchTenantContext(createSession('TR01'), {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(false)

    if (!response.success) {
      expect(response.error.code).toBe('TENANT_CONTEXT_FORBIDDEN')
      expect(response.error.message).toBe('Bu tenant baglamina erisiminiz yok.')
    }
  })

  it('live modda invalid tenant kodunu reddeder', async () => {
    const fetcher = vi.fn()

    const response = await fetchTenantContext(createSession('INVALID'), {
      transportMode: 'live',
      fetcher,
    })

    expect(fetcher).not.toHaveBeenCalled()
    expect(response.success).toBe(false)

    if (!response.success) {
      expect(response.error.code).toBe('TENANT_CONTEXT_INVALID_TENANT')
      expect(response.error.message).toBe('Gecersiz tenant kodu.')
    }
  })

  it('live modda backend tenant mismatch durumunu reddeder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        JSON.stringify({
          success: true,
          data: {
            current_tenant: {
              code: 'TR01-OPS',
            },
            tenants: [
              { id: 'ops', code: 'TR01-OPS', name: 'TR01 Operasyon' },
            ],
          },
          meta: {
            requestId: 'req-tenant-4',
            timestamp: '2026-04-21T00:00:00.000Z',
            source: 'backend.tenant.mismatch',
          },
        }),
    })

    const response = await fetchTenantContext(createSession('TR01-FIN'), {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(false)

    if (!response.success) {
      expect(response.error.code).toBe('TENANT_CONTEXT_MISMATCH')
      expect(response.error.message).toBe(
        'Backend tenant baglami istenen tenant ile eslesmiyor.',
      )
    }
  })

  it('live modda cross-tenant veri sizintisini reddeder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        JSON.stringify({
          success: true,
          data: {
            current_tenant: {
              code: 'TR01-FIN',
            },
            tenants: [
              { id: 'fin', code: 'TR01-FIN', name: 'TR01 Finans' },
              { id: 'ops', code: 'TR01-OPS', name: 'TR01 Operasyon' },
            ],
          },
          meta: {
            requestId: 'req-tenant-5',
            timestamp: '2026-04-21T00:00:00.000Z',
            source: 'backend.tenant.leak',
          },
        }),
    })

    const response = await fetchTenantContext(createSession('TR01-FIN'), {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(false)

    if (!response.success) {
      expect(response.error.code).toBe('TENANT_CONTEXT_CROSS_TENANT_LEAK')
      expect(response.error.message).toBe(
        'Cevap icinde istenmeyen tenant verisi bulundu.',
      )
    }
  })
})
