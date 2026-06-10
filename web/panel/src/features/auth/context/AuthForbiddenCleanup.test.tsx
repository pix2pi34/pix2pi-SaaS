import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AuthProvider, useAuth } from './AuthContext'

const authApiMock = vi.hoisted(() => ({
  authLogin: vi.fn(),
  authMe: vi.fn(),
}))

vi.mock('../api/authApi', () => authApiMock)

const LOCAL_STORAGE_KEY = 'pix2pi.auth.local.v1'

function Probe() {
  const auth = useAuth()

  return (
    <div>
      <div data-testid="status">{auth.status}</div>
      <div data-testid="error-code">{auth.errorCode || 'no-code'}</div>
      <div data-testid="retry-flag">{auth.canRetryAuthMe ? 'yes' : 'no'}</div>
    </div>
  )
}

describe('Auth forbidden cleanup', () => {
  beforeEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
    authApiMock.authLogin.mockReset()
    authApiMock.authMe.mockReset()
  })

  it('forbidden durumunda storage temizlenir ve recoverable session tutulmaz', async () => {
    window.localStorage.setItem(
      LOCAL_STORAGE_KEY,
      JSON.stringify({
        user: {
          id: 'user-1',
          email: 'demo@pix2pi.local',
          displayName: 'Demo Kullanici',
          role: 'panel_admin',
        },
        session: {
          accessToken: 'token-1',
          refreshToken: 'token-2',
          tenantCode: 'TR01',
          remember: true,
          source: 'real',
        },
      }),
    )

    authApiMock.authMe.mockResolvedValueOnce({
      success: false,
      error: {
        code: 'AUTH_FORBIDDEN',
        message: 'Bu alana erisiminiz yok.',
      },
      meta: {
        requestId: 'req-auth-forbidden',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'auth.me.live',
      },
    })

    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    )

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('signed_out')
    })

    expect(screen.getByTestId('error-code')).toHaveTextContent('AUTH_FORBIDDEN')
    expect(screen.getByTestId('retry-flag')).toHaveTextContent('no')
    expect(window.localStorage.getItem(LOCAL_STORAGE_KEY)).toBeNull()
  })
})
