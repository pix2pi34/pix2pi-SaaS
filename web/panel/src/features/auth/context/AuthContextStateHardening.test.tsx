import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AuthProvider, useAuth } from './AuthContext'

const authApiMock = vi.hoisted(() => ({
  authLogin: vi.fn(),
  authMe: vi.fn(),
}))

vi.mock('../api/authApi', () => authApiMock)

const LOCAL_STORAGE_KEY = 'pix2pi.auth.local.v1'

function AuthProbe() {
  const state = useAuth()

  return (
    <div>
      <div data-testid="status">{state.status}</div>
      <div data-testid="error">{state.errorMessage || 'no-error'}</div>
      <div data-testid="request-id">{state.errorRequestId || 'no-request'}</div>
      <button type="button" onClick={() => void state.retryAuthMe()}>
        retry-auth-me
      </button>
    </div>
  )
}

describe('AuthContext State Hardening', () => {
  beforeEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
    authApiMock.authLogin.mockReset()
    authApiMock.authMe.mockReset()
  })

  it('retryAuthMe eski hatayi temizler ve success sonrasi resetler', async () => {
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

    authApiMock.authMe
      .mockResolvedValueOnce({
        success: false,
        error: {
          code: 'AUTH_UNAUTHORIZED',
          message: 'Oturum gecersiz veya suresi dolmus.',
        },
        meta: {
          requestId: 'req-auth-error',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'auth.me.live',
        },
      })
      .mockResolvedValueOnce({
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
        <AuthProbe />
      </AuthProvider>,
    )

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('signed_out')
    })

    expect(screen.getByTestId('error')).toHaveTextContent(
      'Oturum gecersiz veya suresi dolmus.',
    )

    fireEvent.click(screen.getByRole('button', { name: 'retry-auth-me' }))

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('loading')
    })

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('signed_in')
    })

    expect(screen.getByTestId('error')).toHaveTextContent('no-error')
    expect(screen.getByTestId('request-id')).toHaveTextContent('no-request')
  })
})
