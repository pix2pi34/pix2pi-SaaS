import { describe, expect, it, vi } from 'vitest'
import { authLogin, authMe } from './authApi'
import type { AuthSession } from '../types/auth.types'

describe('authApi', () => {
  it('mock modda login envelope doner', async () => {
    const response = await authLogin(
      {
        email: 'demo@pix2pi.local',
        password: 'Demo123',
        tenantCode: 'TR01',
        remember: true,
      },
      { transportMode: 'mock' },
    )

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('auth.contract.mock')
      expect(response.data.session.source).toBe('mock')
      expect(response.data.session.tenantCode).toBe('TR01')
    }
  })

  it('live modda login cevabini map eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        JSON.stringify({
          success: true,
          data: {
            user: {
              id: 'user-9',
              email: 'real@pix2pi.local',
              display_name: 'Real User',
              role: 'admin',
            },
            session: {
              access_token: 'real-access',
              refresh_token: 'real-refresh',
              tenant_code: 'TR01-FIN',
            },
          },
          meta: {
            request_id: 'req-auth-1',
            timestamp: '2026-04-21T00:00:00.000Z',
            source: 'backend.auth.login',
          },
        }),
    })

    const response = await authLogin(
      {
        email: 'real@pix2pi.local',
        password: 'Secret123',
        tenantCode: 'TR01-FIN',
        remember: false,
      },
      { transportMode: 'live', fetcher },
    )

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.auth.login')
      expect(response.data.user.displayName).toBe('Real User')
      expect(response.data.session.accessToken).toBe('real-access')
      expect(response.data.session.tenantCode).toBe('TR01-FIN')
      expect(response.data.session.source).toBe('real')
    }
  })

  it('hybrid modda auth me fail olursa mocka duser', async () => {
    const fetcher = vi.fn().mockRejectedValue(new Error('network down'))
    const session: AuthSession = {
      accessToken: 'token-1',
      refreshToken: 'token-2',
      tenantCode: 'TR01',
      remember: true,
      source: 'real',
    }

    const response = await authMe(session, {
      transportMode: 'hybrid',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('auth.me.mock')
      expect(response.data.session.source).toBe('mock')
    }
  })

  it('live modda auth me cevabini map eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        JSON.stringify({
          success: true,
          data: {
            me: {
              id: 'user-10',
              email: 'me@pix2pi.local',
              name: 'Session User',
              role: 'manager',
            },
          },
          meta: {
            requestId: 'req-auth-me-1',
            timestamp: '2026-04-21T00:00:00.000Z',
            source: 'backend.auth.me',
          },
        }),
    })

    const session: AuthSession = {
      accessToken: 'token-1',
      refreshToken: 'token-2',
      tenantCode: 'TR01',
      remember: true,
      source: 'real',
    }

    const response = await authMe(session, {
      transportMode: 'live',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.auth.me')
      expect(response.meta.requestId).toBe('req-auth-me-1')
      expect(response.data.user.displayName).toBe('Session User')
      expect(response.data.session.tenantCode).toBe('TR01')
    }
  })

  it('live modda auth me 401 durumunu unauthorized olarak map eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
      text: async () => '',
    })

    const session: AuthSession = {
      accessToken: 'expired-token',
      refreshToken: 'token-2',
      tenantCode: 'TR01',
      remember: true,
      source: 'real',
    }

    const response = await authMe(session, {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(false)

    if (!response.success) {
      expect(response.error.code).toBe('AUTH_UNAUTHORIZED')
      expect(response.error.message).toBe('Oturum gecersiz veya suresi dolmus.')
    }
  })

  it('live modda auth me 403 durumunu forbidden olarak map eder', async () => {
    const fetcher = vi.fn().mockResolvedValue({
      ok: false,
      status: 403,
      text: async () => '',
    })

    const session: AuthSession = {
      accessToken: 'forbidden-token',
      refreshToken: 'token-2',
      tenantCode: 'TR01',
      remember: true,
      source: 'real',
    }

    const response = await authMe(session, {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(false)

    if (!response.success) {
      expect(response.error.code).toBe('AUTH_FORBIDDEN')
      expect(response.error.message).toBe('Bu islem icin yetkiniz yok.')
    }
  })
})
