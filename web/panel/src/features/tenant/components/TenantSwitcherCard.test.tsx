import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { AppRuntimeProvider } from '../../../app/providers/AppRuntimeContext'
import { TenantSwitcherCard } from './TenantSwitcherCard'

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

vi.mock('../context/TenantContext', () => ({
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

describe('Tenant-Aware Layout', () => {
  it('session acildiktan sonra tenant secimini degistirir', () => {
    tenantState.activeTenantCode = 'TR01'
    switchTenantMock.mockClear()

    const { rerender } = render(
      <AppRuntimeProvider>
        <TenantSwitcherCard />
      </AppRuntimeProvider>,
    )

    expect(
      screen.getByRole('heading', { name: 'Tenant secimi' }),
    ).toBeInTheDocument()
    expect(screen.getAllByText(/Aktif kod:\s*TR01/i).length).toBeGreaterThan(0)

    fireEvent.change(screen.getByLabelText('Tenant secimi'), {
      target: { value: 'TR01-FIN' },
    })

    expect(switchTenantMock).toHaveBeenCalledWith('TR01-FIN')

    rerender(
      <AppRuntimeProvider>
        <TenantSwitcherCard />
      </AppRuntimeProvider>,
    )

    expect(screen.getAllByText(/Aktif kod:\s*TR01-FIN/i).length).toBeGreaterThan(0)
    expect(screen.getByText(/Tenant sayisi:\s*3/i)).toBeInTheDocument()
  })
})
