import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { MonitoringPage } from '../pages/MonitoringPage'

const monitoringRefreshSpy = vi.fn()
const authMock = vi.hoisted(() => ({
  signIn: vi.fn(),
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
    signIn: authMock.signIn,
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
      { id: 'tr01-ops', code: 'TR01-OPS', name: 'TR01 Operasyon', status: 'available' },
    ],
    activeTenant: {
      id: 'tr01',
      code: 'TR01',
      name: 'TR01 Merkez',
      status: 'active',
    },
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    setActiveTenantCode: tenantMock.setActiveTenantCode,
    switchTenant: tenantMock.switchTenant,
    refreshTenantContext: tenantMock.refreshTenantContext,
  }),
}))

vi.mock('../hooks/useMonitoringSummary', () => ({
  useMonitoringSummary: () => ({
    status: 'success',
    data: {
      cards: [
        {
          id: 'health',
          label: 'Servis sagligi',
          value: '4/5',
          detail: 'health summary contract',
          tone: 'healthy',
        },
        {
          id: 'warning',
          label: 'Aktif uyari',
          value: '2',
          detail: 'warnings contract',
          tone: 'warning',
        },
      ],
      warnings: [
        {
          id: 'w1',
          title: 'Gateway warning',
          detail: 'warning detail',
          level: 'medium',
        },
      ],
      services: [
        {
          id: 'svc-1',
          service: 'identity-api',
          status: 'UP',
          latency: '64 ms',
          lastCheck: 'az once',
        },
      ],
      timeline: [
        {
          id: 't1',
          title: 'Monitoring timeline event',
          detail: 'timeline detail',
          time: 'az once',
        },
      ],
    },
    errorMessage: '',
    requestId: 'req-monitoring-success',
    source: 'monitoring.contract.mock',
    refresh: monitoringRefreshSpy,
  }),
}))

describe('Monitoring UI Skeleton', () => {
  it('signed_in durumda monitoring shared state bloklarini gosterir', () => {
    render(
      <AppRuntimeProvider>
        <MonitoringPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('Monitoring route aktif')).toBeInTheDocument()
    expect(screen.getByText('Monitoring contract basariyla yuklendi')).toBeInTheDocument()
    expect(screen.getByText('Monitoring health overview')).toBeInTheDocument()
    expect(screen.getByText('Monitoring warnings panel')).toBeInTheDocument()
    expect(screen.getByText('Service status table')).toBeInTheDocument()
    expect(screen.getAllByText('Monitoring timeline').length).toBeGreaterThan(0)
    expect(screen.getByText('Servis sagligi')).toBeInTheDocument()
    expect(screen.getAllByText('Monitoring yenile').length).toBeGreaterThan(0)
    expect(screen.getByText('Runtime config paneli')).toBeInTheDocument()
    expect(screen.getByText('Health path: /api/v1/health/summary')).toBeInTheDocument()
    expect(screen.getByText('Warnings path: /api/v1/monitoring/warnings')).toBeInTheDocument()
  })
})
