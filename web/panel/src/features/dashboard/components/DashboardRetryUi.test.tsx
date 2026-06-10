import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { DashboardPage } from '../pages/DashboardPage'

const dashboardMock = vi.hoisted(() => {
  const state = {
    phase: 'error' as 'error' | 'loading' | 'success',
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

vi.mock('../hooks/useDashboardSummary', () => ({
  useDashboardSummary: () => {
    if (dashboardMock.phase === 'loading') {
      return {
        status: 'loading',
        data: null,
        errorMessage: '',
        requestId: '',
        source: '',
        refresh: dashboardMock.refreshSpy,
      }
    }

    if (dashboardMock.phase === 'success') {
      return {
        status: 'success',
        data: {
          metrics: [
            {
              id: 'm1',
              label: 'Gunluk ciro',
              value: '₺148.420',
              delta: '+%8',
              tone: 'good',
            },
          ],
          activities: [
            {
              id: 'a1',
              title: 'Aktivite',
              detail: 'detay',
              time: 'az once',
              state: 'ok',
            },
          ],
          actions: [
            {
              id: 'x1',
              title: 'Summary yenile',
              detail: 'detay',
              state: 'ready',
            },
          ],
          summaryCards: [
            {
              id: 's1',
              label: 'Aktif tenant',
              value: 'TR01',
              detail: 'detay',
            },
          ],
        },
        errorMessage: '',
        requestId: 'req-dashboard-success',
        source: 'dashboard.contract.live',
        refresh: dashboardMock.refreshSpy,
      }
    }

    return {
      status: 'error',
      data: null,
      errorMessage: 'Dashboard retry gerekiyor.',
      requestId: 'req-dashboard-error',
      source: 'dashboard.contract.live',
      refresh: dashboardMock.refreshSpy,
    }
  },
}))

describe('Dashboard Retry UI', () => {
  beforeEach(() => {
    dashboardMock.phase = 'error'
    dashboardMock.refreshSpy.mockClear()
    authMock.signOut.mockClear()
    authMock.refreshSession.mockClear()
    authMock.retryAuthMe.mockClear()
    tenantMock.switchTenant.mockClear()
    tenantMock.setActiveTenantCode.mockClear()
    tenantMock.refreshTenantContext.mockClear()
  })

  it('loading -> retry -> success gecisini gosterir', () => {
    const { rerender } = render(
      <AppRuntimeProvider>
        <DashboardPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('Dashboard contract hatasi')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Summary tekrar dene' }))
    expect(dashboardMock.refreshSpy).toHaveBeenCalledTimes(1)

    rerender(
      <AppRuntimeProvider>
        <DashboardPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('Dashboard verisi yukleniyor')).toBeInTheDocument()

    dashboardMock.phase = 'success'

    rerender(
      <AppRuntimeProvider>
        <DashboardPage />
      </AppRuntimeProvider>,
    )

    expect(
      screen.getByText('Dashboard contract basariyla yuklendi'),
    ).toBeInTheDocument()
  })
})
