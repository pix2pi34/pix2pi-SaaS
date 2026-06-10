import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { TenantProvider, useTenant } from '../context/TenantContext'

const tenantApiMock = vi.hoisted(() => ({
  fetchTenantContext: vi.fn(),
}))

const authState = vi.hoisted(() => ({
  status: 'signed_in' as const,
  session: {
    accessToken: 'token-1',
    refreshToken: 'token-2',
    tenantCode: 'TR01',
    remember: true,
    source: 'real',
  },
}))

vi.mock('../api/tenantApi', () => tenantApiMock)
vi.mock('../../auth/context/AuthContext', () => ({
  useAuth: () => authState,
}))

type Deferred<T> = {
  promise: Promise<T>
  resolve: (value: T) => void
}

function createDeferred<T>(): Deferred<T> {
  let resolve!: (value: T) => void

  const promise = new Promise<T>((res) => {
    resolve = res
  })

  return { promise, resolve }
}

function TenantProbe() {
  const state = useTenant()

  return (
    <div>
      <div data-testid="status">{state.status}</div>
      <div data-testid="active">{state.activeTenant?.code ?? 'none'}</div>
      <div data-testid="error">{state.errorMessage || 'no-error'}</div>
      <button type="button" onClick={() => state.switchTenant('TR01-FIN')}>
        switch-fin
      </button>
    </div>
  )
}

describe('Tenant State Hardening', () => {
  beforeEach(() => {
    tenantApiMock.fetchTenantContext.mockReset()
    authState.session.tenantCode = 'TR01'
  })

  it('tenant switch sirasinda eski hata statee geri yazilmaz', async () => {
    const deferred = createDeferred<any>()
    tenantApiMock.fetchTenantContext.mockReturnValueOnce(deferred.promise)

    render(
      <TenantProvider>
        <TenantProbe />
      </TenantProvider>,
    )

    await waitFor(() => {
      expect(screen.getByTestId('active')).toHaveTextContent('TR01')
    })

    fireEvent.click(screen.getByRole('button', { name: 'switch-fin' }))

    await waitFor(() => {
      expect(screen.getByTestId('active')).toHaveTextContent('TR01-FIN')
    })

    await act(async () => {
      deferred.resolve({
        success: false,
        error: {
          code: 'TENANT_CONTEXT_TIMEOUT',
          message: 'eski tenant hata',
        },
        meta: {
          requestId: 'req-tenant-old',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'tenant.context.live',
        },
      })
    })

    await waitFor(() => {
      expect(screen.getByTestId('active')).toHaveTextContent('TR01-FIN')
    })

    expect(screen.getByTestId('error')).toHaveTextContent('no-error')
  })
})
