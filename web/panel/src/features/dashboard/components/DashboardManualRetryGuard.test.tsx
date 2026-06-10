import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { DashboardPage } from '../pages/DashboardPage'

vi.mock('../../auth/context/AuthContext', () => ({
  useAuth: () => ({
    status: 'signed_out',
    user: null,
    session: null,
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
    tenants: [{ id: 'tr01', code: 'TR01', name: 'TR01 Merkez', status: 'active' }],
    activeTenant: { id: 'tr01', code: 'TR01', name: 'TR01 Merkez', status: 'active' },
    errorCode: '',
    errorMessage: '',
    errorRequestId: '',
    errorSource: '',
    setActiveTenantCode: vi.fn(),
    switchTenant: vi.fn(),
    refreshTenantContext: vi.fn(),
  }),
}))

vi.mock('../hooks/useDashboardSummary', () => ({
  useDashboardSummary: () => ({
    status: 'success',
    data: {
      metrics: [{ id: 'm1', label: 'Gunluk ciro', value: '₺148.420', delta: '+%8', tone: 'good' }],
      activities: [{ id: 'a1', title: 'Aktivite', detail: 'detay', time: 'az once', state: 'ok' }],
      actions: [{ id: 'x1', title: 'Summary yenile', detail: 'detay', state: 'ready' }],
      summaryCards: [{ id: 's1', label: 'Aktif tenant', value: 'TR01', detail: 'detay' }],
    },
    errorMessage: '',
    requestId: 'req-dashboard',
    source: 'dashboard.contract.mock',
    refresh: vi.fn(),
  }),
}))

describe('Dashboard manual retry guard', () => {
  it('signed_out durumda manuel retry disabled olur', () => {
    render(
      <AppRuntimeProvider>
        <DashboardPage />
      </AppRuntimeProvider>,
    )

    expect(screen.getByRole('button', { name: 'Summary yenile' })).toBeDisabled()
    expect(
      screen.getByText('Guvenlik korumasi nedeniyle manuel retry su an kisitli.'),
    ).toBeInTheDocument()
  })
})
