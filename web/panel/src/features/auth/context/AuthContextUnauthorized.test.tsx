import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { AuthProvider, useAuth } from './AuthContext'

const LOCAL_STORAGE_KEY = 'pix2pi.auth.local.v1'

function Probe() {
  const { status, errorMessage } = useAuth()

  return (
    <div>
      <div data-testid="status">{status}</div>
      <div data-testid="error">{errorMessage || 'no-error'}</div>
    </div>
  )
}

describe('AuthContext unauthorized handling', () => {
  beforeEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
    vi.restoreAllMocks()
    delete (globalThis as { __PIX2PI_API_TRANSPORT_MODE__?: string })
      .__PIX2PI_API_TRANSPORT_MODE__
  })

  afterEach(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
    vi.restoreAllMocks()
    delete (globalThis as { __PIX2PI_API_TRANSPORT_MODE__?: string })
      .__PIX2PI_API_TRANSPORT_MODE__
  })

  it('401 durumunda stored session temizlenir ve signed_out olur', async () => {
    window.localStorage.setItem(
      LOCAL_STORAGE_KEY,
      JSON.stringify({
        user: {
          id: 'user-1',
          email: 'stored@pix2pi.local',
          displayName: 'Stored User',
          role: 'admin',
        },
        session: {
          accessToken: 'expired-token',
          refreshToken: 'refresh-token',
          tenantCode: 'TR01',
          remember: true,
          source: 'real',
        },
      }),
    )

    ;(globalThis as { __PIX2PI_API_TRANSPORT_MODE__?: string })
      .__PIX2PI_API_TRANSPORT_MODE__ = 'live'

    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 401,
        text: async () => '',
      }),
    )

    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    )

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('signed_out')
    })

    expect(screen.getByTestId('error')).toHaveTextContent(
      'Oturum gecersiz veya suresi dolmus.',
    )
    expect(window.localStorage.getItem(LOCAL_STORAGE_KEY)).toBeNull()
  })
})
