import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { MonitoringPage } from '../pages/MonitoringPage'

const tenantState = vi.hoisted(() => ({
  activeTenantCode: 'TR01',
}))

const switchTenantMock = vi.hoisted(() =>
  vi.fn((code: string) => {
    tenantState.activeTenantCode = code
  }),
)

function buildTenants(activeCode: string) {
  return [
    {
      id: 'tr01',
      code: 'TR01',
      name: 'TR01 Merkez',
      status: activeCode === 'TR01' ? 'active' : 'available',
    },
    {
      id: 'tr01-fin',
      code: 'TR01-FIN',
      name: 'TR01 Finans',
      status: activeCode === 'TR01-FIN' ? 'active' : 'available',
    },
    {
      id: 'tr01-ops',
      code: 'TR01-OPS',
      name: 'TR01 Operasyon',
      status: activeCode === 'TR01-OPS' ? 'active' : 'available',
    },
  ]
}

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
      tenantCode: tenantState.activeTenantCode,
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
    tenants: buildTenants(tenantState.activeTenantCode),
    activeTenant:
      buildTenants(tenantState.activeTenantCode).find(
        (item) => item.code === tenantState.activeTenantCode,
      ) ?? null,
    errorCode: '',
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    setActiveTenantCode: switchTenantMock,
    switchTenant: switchTenantMock,
    refreshTenantContext: vi.fn(),
  }),
}))

vi.mock('../hooks/useMonitoringSummary', () => ({
  useMonitoringSummary: (tenantCode?: string) => {
    const code = tenantCode || tenantState.activeTenantCode

    return {
      status: 'success',
      data: {
        cards: [
          {
            id: 'health',
            label: 'Servis sagligi',
            value: code === 'TR01-OPS' ? '5/5' : '4/5',
            detail: 'health summary contract',
            tone: 'healthy',
          },
        ],
        warnings: [
          {
            id: 'w1',
            title: code === 'TR01-OPS' ? 'Ops warning' : 'Gateway warning',
            detail: 'warning detail',
            level: 'medium',
          },
        ],
        services: [
          {
            id: 'svc-1',
            service: 'identity-api',
            status: 'UP',
            latency: code === 'TR01-OPS' ? '54 ms' : '64 ms',
            lastCheck: 'az once',
          },
        ],
        timeline: [
          {
            id: 't1',
            title: 'Monitoring timeline event',
            detail: `tenant: ${code}`,
            time: 'az once',
          },
        ],
      },
      errorMessage: '',
      requestId: `req-${code}`,
      source: 'monitoring.contract.mock',
      refresh: vi.fn(),
    }
  },
}))

describe('Monitoring Tenant Refetch', () => {
  it('tenant degisince monitoring verisini yeniden yukler', () => {
    tenantState.activeTenantCode = 'TR01'
    switchTenantMock.mockClear()

    const { rerender } = render(
      <AppRuntimeProvider>
        <MonitoringPage />
      </AppRuntimeProvider>,
    )

    expect(
      screen.getByRole('heading', { name: 'Monitoring route aktif' }),
    ).toBeInTheDocument()
    expect(screen.getByText('4/5')).toBeInTheDocument()
    expect(screen.getAllByText(/Aktif kod:\s*TR01/i).length).toBeGreaterThan(0)

    fireEvent.change(screen.getByLabelText('Tenant secimi'), {
      target: { value: 'TR01-OPS' },
    })

    expect(switchTenantMock).toHaveBeenCalledWith('TR01-OPS')

    rerender(
      <AppRuntimeProvider>
        <MonitoringPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('5/5')).toBeInTheDocument()
    expect(screen.getAllByText(/Aktif kod:\s*TR01-OPS/i).length).toBeGreaterThan(0)
  })
})
