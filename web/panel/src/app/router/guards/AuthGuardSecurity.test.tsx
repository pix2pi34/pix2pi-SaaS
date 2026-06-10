import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../providers/AppRuntimeContext'
import { AuthGuard } from './AuthGuard'

const authState = vi.hoisted(() => ({
  status: 'signed_out',
  errorCode: '',
  errorMessage: '',
  errorRequestId: '',
  errorSource: '',
}))

vi.mock('../../../features/auth/context/AuthContext', () => ({
  useAuth: () => ({
    status: authState.status,
    user: null,
    session: null,
    errorCode: authState.errorCode,
    errorMessage: authState.errorMessage,
    errorRequestId: authState.errorRequestId,
    errorSource: authState.errorSource,
    canRetryAuthMe: false,
    signIn: vi.fn(),
    signOut: vi.fn(),
    refreshSession: vi.fn(),
    retryAuthMe: vi.fn(),
  }),
}))

describe('AuthGuard Security', () => {
  beforeEach(() => {
    authState.status = 'signed_out'
    authState.errorCode = ''
    authState.errorMessage = ''
    authState.errorRequestId = ''
    authState.errorSource = ''
  })

  it('401 / signed_out durumda login sayfasina yonlendirir', () => {
    render(
      <AppRuntimeProvider>
        <MemoryRouter initialEntries={['/dashboard']}>
          <Routes>
            <Route path="/login" element={<div>login-page</div>} />
            <Route element={<AuthGuard />}>
              <Route path="/dashboard" element={<div>dashboard-page</div>} />
            </Route>
          </Routes>
        </MemoryRouter>
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('login-page')).toBeInTheDocument()
  })

  it('403 forbidden durumda ekranda kalir ve hata yuzeyi gosterir', () => {
    authState.errorCode = 'AUTH_FORBIDDEN'
    authState.errorMessage = 'Bu alana erisiminiz yok.'
    authState.errorRequestId = 'req-auth-forbidden'
    authState.errorSource = 'auth.me.live'

    render(
      <AppRuntimeProvider>
        <MemoryRouter initialEntries={['/dashboard']}>
          <Routes>
            <Route path="/login" element={<div>login-page</div>} />
            <Route element={<AuthGuard />}>
              <Route path="/dashboard" element={<div>dashboard-page</div>} />
            </Route>
          </Routes>
        </MemoryRouter>
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('Authentication access blocked')).toBeInTheDocument()
    expect(screen.queryByText('login-page')).not.toBeInTheDocument()
    expect(screen.queryByText('dashboard-page')).not.toBeInTheDocument()
  })
})
