import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { MonitoringPage } from '../pages/MonitoringPage'

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
    errorCode: '',
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    canRetryAuthMe: false,
    signIn: vi.fn(),
    signOut: vi.fn(),
    refreshSession: vi.fn(),
    retryAuthMe: vi.fn(),
  }),
}))

vi.mock('../../tenant/context/TenantContext', () => ({
  useTenant: () => ({
    status: 'ready',
    tenants: [],
    activeTenant: null,
    errorCode: '',
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    setActiveTenantCode: vi.fn(),
    switchTenant: vi.fn(),
    refreshTenantContext: vi.fn(),
  }),
}))

vi.mock('../hooks/useMonitoringSummary', () => ({
  useMonitoringSummary: () => ({
    status: 'success',
    data: {
      cards: [{ id: 'c1', label: 'Servis sagligi', value: '4/5', detail: 'detay', tone: 'healthy' }],
      warnings: [{ id: 'w1', title: 'Gateway warning', detail: 'detail', level: 'medium' }],
      services: [{ id: 'svc1', service: 'identity-api', status: 'UP', latency: '64 ms', lastCheck: 'az once' }],
      timeline: [{ id: 't1', title: 'Monitoring timeline event', detail: 'detail', time: 'az once' }],
    },
    errorMessage: '',
    requestId: 'req-monitoring',
    source: 'monitoring.contract.mock',
    refresh: vi.fn(),
  }),
}))

describe('Monitoring manual retry guard', () => {
  it('tenant yoksa manuel retry disabled olur', () => {
    render(
      <AppRuntimeProvider>
        <MonitoringPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByRole('button', { name: 'Monitoring yenile' })).toBeDisabled()
    expect(
      screen.getByText('Guvenlik korumasi nedeniyle manuel retry su an kisitli.'),
    ).toBeInTheDocument()
  })
})
