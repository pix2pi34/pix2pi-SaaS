import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { MonitoringPage } from '../pages/MonitoringPage'

const monitoringMock = vi.hoisted(() => {
  const state = {
    phase: 'errorA' as 'errorA' | 'loading' | 'errorB',
    refreshSpy: vi.fn(),
  }

  state.refreshSpy.mockImplementation(() => {
    state.phase = 'loading'
  })

  return state
})

const authMock = vi.hoisted(() => ({
  signOut: vi.fn(),
  refreshSession: vi.fn(),
  retryAuthMe: vi.fn(),
}))

const tenantMock = vi.hoisted(() => ({
  switchTenant: vi.fn(),
  setActiveTenantCode: vi.fn(),
  refreshTenantContext: vi.fn(),
}))

vi.mock('../../auth/context/AuthContext', () => ({
  useAuth: () => ({
    status: 'signed_in',
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
      source: 'mock',
    },
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    canRetryAuthMe: false,
    signIn: vi.fn(),
    signOut: authMock.signOut,
    refreshSession: authMock.refreshSession,
    retryAuthMe: authMock.retryAuthMe,
  }),
}))

vi.mock('../../tenant/context/TenantContext', () => ({
  useTenant: () => ({
    status: 'ready',
    tenants: [
      { id: 'tr01', code: 'TR01', name: 'TR01 Merkez', status: 'active' },
      { id: 'tr01-fin', code: 'TR01-FIN', name: 'TR01 Finans', status: 'available' },
    ],
    activeTenant: { id: 'tr01', code: 'TR01', name: 'TR01 Merkez', status: 'active' },
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    setActiveTenantCode: tenantMock.setActiveTenantCode,
    switchTenant: tenantMock.switchTenant,
    refreshTenantContext: tenantMock.refreshTenantContext,
  }),
}))

vi.mock('../hooks/useMonitoringSummary', () => ({
  useMonitoringSummary: () => {
    if (monitoringMock.phase === 'loading') {
      return {
        status: 'loading',
        data: null,
        errorMessage: '',
        requestId: '',
        source: '',
        refresh: monitoringMock.refreshSpy,
      }
    }

    if (monitoringMock.phase === 'errorB') {
      return {
        status: 'error',
        data: null,
        errorMessage: 'Monitoring retry sonrasi hata devam ediyor.',
        requestId: 'req-monitoring-error-2',
        source: 'monitoring.contract.live',
        refresh: monitoringMock.refreshSpy,
      }
    }

    return {
      status: 'error',
      data: null,
      errorMessage: 'Monitoring ilk hata durumu.',
      requestId: 'req-monitoring-error-1',
      source: 'monitoring.contract.live',
      refresh: monitoringMock.refreshSpy,
    }
  },
}))

describe('Monitoring Retry UI', () => {
  beforeEach(() => {
    monitoringMock.phase = 'errorA'
    monitoringMock.refreshSpy.mockClear()
    authMock.signOut.mockClear()
    authMock.refreshSession.mockClear()
    authMock.retryAuthMe.mockClear()
    tenantMock.switchTenant.mockClear()
    tenantMock.setActiveTenantCode.mockClear()
    tenantMock.refreshTenantContext.mockClear()
  })

  it('loading -> retry -> error gecisini gosterir', () => {
    const { rerender } = render(
      <AppRuntimeProvider>
        <MonitoringPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('Monitoring contract hatasi')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Monitoring tekrar dene' }))
    expect(monitoringMock.refreshSpy).toHaveBeenCalledTimes(1)

    rerender(
      <AppRuntimeProvider>
        <MonitoringPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('Monitoring contract verisi yukleniyor')).toBeInTheDocument()

    monitoringMock.phase = 'errorB'

    rerender(
      <AppRuntimeProvider>
        <MonitoringPage />
      </AppRuntimeProvider>,
    )

    expect(
      screen.getByText('Monitoring retry sonrasi hata devam ediyor.'),
    ).toBeInTheDocument()
  })
})
