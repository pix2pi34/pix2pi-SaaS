import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { TenantLayoutInfoCard } from './TenantLayoutInfoCard'

const refreshTenantContextSpy = vi.fn()

vi.mock('../../auth/context/AuthContext', () => ({
  useAuth: () => ({
    session: {
      tenantCode: 'TR01',
    },
  }),
}))

vi.mock('../context/TenantContext', () => ({
  useTenant: () => ({
    activeTenant: null,
    tenants: [],
    status: 'error',
    errorMessage: 'Tenant context yeniden denenmeli.',
    errorRequestId: 'req-tenant-retry',
    errorSource: 'tenant.context.live',
    refreshTenantContext: refreshTenantContextSpy,
  }),
}))

describe('Tenant Retry UI', () => {
  it('tenant context retry butonu refresh fonksiyonunu cagirir', () => {
    render(
      <AppRuntimeProvider>
        <TenantLayoutInfoCard />
      </AppRuntimeProvider>,
    )

    fireEvent.click(
      screen.getByRole('button', { name: 'Tenant context tekrar dene' }),
    )

    expect(refreshTenantContextSpy).toHaveBeenCalledTimes(1)
  })
})
