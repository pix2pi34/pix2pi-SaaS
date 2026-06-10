import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../providers/AppRuntimeContext'
import { TenantGuard } from './TenantGuard'

const tenantState = vi.hoisted(() => ({
  status: 'ready',
  activeTenant: null as null | { code: string },
  errorCode: 'TENANT_CONTEXT_MISMATCH',
  errorMessage: 'Backend tenant baglami istenen tenant ile eslesmiyor.',
  errorRequestId: 'req-tenant-guard',
  errorSource: 'tenant.context.live',
}))

vi.mock('../../../features/tenant/context/TenantContext', () => ({
  useTenant: () => ({
    status: tenantState.status,
    tenants: [],
    activeTenant: tenantState.activeTenant,
    errorCode: tenantState.errorCode,
    errorMessage: tenantState.errorMessage,
    errorRequestId: tenantState.errorRequestId,
    errorSource: tenantState.errorSource,
    setActiveTenantCode: vi.fn(),
    switchTenant: vi.fn(),
    refreshTenantContext: vi.fn(),
  }),
}))

describe('TenantGuard Security', () => {
  it('tenant mismatch durumunda outleti bloklar', () => {
    render(
      <AppRuntimeProvider>
        <MemoryRouter initialEntries={['/dashboard']}>
          <Routes>
            <Route element={<TenantGuard />}>
              <Route path="/dashboard" element={<div>dashboard-page</div>} />
            </Route>
          </Routes>
        </MemoryRouter>
      </AppRuntimeProvider>,
    )

    expect(screen.getByText('Tenant guard blocked')).toBeInTheDocument()
    expect(screen.queryByText('dashboard-page')).not.toBeInTheDocument()
  })
})
