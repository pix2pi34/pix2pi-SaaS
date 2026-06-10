import { cleanup, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../providers/AppRuntimeContext'
import { AppRouter } from './AppRouter'

const authState = vi.hoisted(() => ({
  status: 'signed_out' as 'signed_out' | 'signed_in' | 'loading',
}))

const tenantState = vi.hoisted(() => ({
  activeTenantCode: 'TR01',
}))

vi.mock('../../features/auth/context/AuthContext', () => ({
  useAuth: () => ({
    status: authState.status,
    user:
      authState.status === 'signed_in'
        ? {
            id: 'user-1',
            email: 'demo@pix2pi.local',
            displayName: 'Demo Kullanici',
            role: 'panel_admin',
          }
        : null,
    session:
      authState.status === 'signed_in'
        ? {
            accessToken: 'token-1',
            refreshToken: 'token-2',
            tenantCode: tenantState.activeTenantCode,
            remember: true,
            source: 'mock',
          }
        : null,
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

vi.mock('../../features/tenant/context/TenantContext', () => ({
  useTenant: () => ({
    status: 'ready',
    tenants: [
      {
        id: 'tr01',
        code: 'TR01',
        name: 'TR01 Merkez',
        status: tenantState.activeTenantCode === 'TR01' ? 'active' : 'available',
      },
      {
        id: 'tr01-fin',
        code: 'TR01-FIN',
        name: 'TR01 Finans',
        status: tenantState.activeTenantCode === 'TR01-FIN' ? 'active' : 'available',
      },
      {
        id: 'tr01-ops',
        code: 'TR01-OPS',
        name: 'TR01 Operasyon',
        status: tenantState.activeTenantCode === 'TR01-OPS' ? 'active' : 'available',
      },
    ],
    activeTenant: {
      id: tenantState.activeTenantCode.toLowerCase(),
      code: tenantState.activeTenantCode,
      name:
        tenantState.activeTenantCode === 'TR01-FIN'
          ? 'TR01 Finans'
          : tenantState.activeTenantCode === 'TR01-OPS'
            ? 'TR01 Operasyon'
            : 'TR01 Merkez',
      status: 'active',
    },
    errorCode: '',
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    setActiveTenantCode: vi.fn(),
    switchTenant: vi.fn(),
    refreshTenantContext: vi.fn(),
  }),
}))

vi.mock('../../features/dashboard/hooks/useDashboardSummary', () => ({
  useDashboardSummary: () => ({
    status: 'success',
    data: {
      metrics: [
        { id: 'm1', label: 'Gunluk ciro', value: '₺148.420', delta: '+%8', tone: 'good' },
      ],
      activities: [
        { id: 'a1', title: 'Aktivite', detail: 'detay', time: 'az once', state: 'ok' },
      ],
      actions: [
        { id: 'x1', title: 'Summary yenile', detail: 'detay', state: 'ready' },
      ],
      summaryCards: [
        { id: 's1', label: 'Aktif tenant', value: tenantState.activeTenantCode, detail: 'detay' },
      ],
    },
    errorMessage: '',
    requestId: 'req-dashboard',
    source: 'dashboard.contract.mock',
    refresh: vi.fn(),
  }),
}))

vi.mock('../../features/monitoring/hooks/useMonitoringSummary', () => ({
  useMonitoringSummary: () => ({
    status: 'success',
    data: {
      cards: [
        { id: 'c1', label: 'Servis sagligi', value: '4/5', detail: 'detay', tone: 'healthy' },
      ],
      warnings: [
        { id: 'w1', title: 'Gateway warning', detail: 'detail', level: 'medium' },
      ],
      services: [
        { id: 'svc1', service: 'identity-api', status: 'UP', latency: '64 ms', lastCheck: 'az once' },
      ],
      timeline: [
        { id: 't1', title: 'Monitoring timeline event', detail: 'detail', time: 'az once' },
      ],
    },
    errorMessage: '',
    requestId: 'req-monitoring',
    source: 'monitoring.contract.mock',
    refresh: vi.fn(),
  }),
}))

function renderRoute(pathname: string) {
  return render(
    <MemoryRouter initialEntries={[pathname]}>
      <AppRuntimeProvider>
        <AppRouter />
      </AppRuntimeProvider>
    </MemoryRouter>,
  )
}

describe('Route Structure', () => {
  beforeEach(() => {
    authState.status = 'signed_out'
    tenantState.activeTenantCode = 'TR01'
    cleanup()
  })

  it('signed_out kullaniciyi protected route yerine login sayfasina yonlendirir', () => {
    renderRoute('/dashboard')

    expect(screen.getByText('Authentication UI yuzeyi hazir')).toBeInTheDocument()
  })

  it('signed_in kullanici protected dashboard routeunu render eder', () => {
    authState.status = 'signed_in'

    renderRoute('/dashboard')

    expect(
      screen.getByRole('heading', { name: 'Dashboard route aktif' }),
    ).toBeInTheDocument()
  })
})
