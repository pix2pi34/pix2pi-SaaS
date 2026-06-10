import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AuthProvider, useAuth } from './AuthContext'
import { LOCAL_STORAGE_KEY } from '../utils/authStorage'

const authApiMock = vi.hoisted(() => ({
  authLogin: vi.fn(),
  authMe: vi.fn(),
}))

vi.mock('../api/authApi', () => authApiMock)

function Probe() {
  const auth = useAuth()

  return (
    <div>
      <div data-testid="status">{auth.status}</div>
      <div data-testid="user">{auth.user?.email ?? 'no-user'}</div>
      <div data-testid="tenant">{auth.session?.tenantCode ?? 'no-tenant'}</div>
      <button type="button" onClick={auth.signOut}>
        sign-out
      </button>
    </div>
  )
}

describe('Auth logout cleanup', () => {
  beforeEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
    authApiMock.authLogin.mockReset()
    authApiMock.authMe.mockReset()
  })

  it('signOut sonrasi storage ve hassas state temizlenir', async () => {
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
      success: true,
      data: {
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
      },
      meta: {
        requestId: 'req-auth-success',
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
      expect(screen.getByTestId('status')).toHaveTextContent('signed_in')
    })

    fireEvent.click(screen.getByRole('button', { name: 'sign-out' }))

    expect(screen.getByTestId('status')).toHaveTextContent('signed_out')
    expect(screen.getByTestId('user')).toHaveTextContent('no-user')
    expect(screen.getByTestId('tenant')).toHaveTextContent('no-tenant')
    expect(window.localStorage.getItem(LOCAL_STORAGE_KEY)).toBeNull()
  })
})
