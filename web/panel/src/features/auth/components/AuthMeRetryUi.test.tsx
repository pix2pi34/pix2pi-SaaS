import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { LoginCard } from './LoginCard'

const retryAuthMeSpy = vi.fn()

vi.mock('../context/AuthContext', () => ({
  useAuth: () => ({
    signIn: vi.fn(),
    errorMessage: 'Oturum gecersiz veya suresi dolmus.',
    errorRequestId: 'req-auth-retry',
    errorSource: 'auth.me.live',
    status: 'signed_out',
    canRetryAuthMe: true,
    retryAuthMe: retryAuthMeSpy,
  }),
}))

describe('AuthMe Retry UI', () => {
  it('session retry butonu auth me retry davranisini tetikler', () => {
    render(
      <AppRuntimeProvider>
        <LoginCard />
      </AppRuntimeProvider>,
    )

    fireEvent.click(
      screen.getByRole('button', { name: 'Session tekrar dene' }),
    )

    expect(retryAuthMeSpy).toHaveBeenCalledTimes(1)
  })
})
