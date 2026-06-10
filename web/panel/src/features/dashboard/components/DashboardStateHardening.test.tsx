import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { describe, expect, it, vi, beforeEach } from 'vitest'
import { useDashboardSummary } from '../hooks/useDashboardSummary'

const dashboardApiMock = vi.hoisted(() => ({
  fetchDashboardContract: vi.fn(),
}))

vi.mock('../api/dashboardApi', () => dashboardApiMock)

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

function DashboardProbe({ tenantCode }: { tenantCode: string }) {
  const state = useDashboardSummary(tenantCode)

  return (
    <div>
      <div data-testid="status">{state.status}</div>
      <div data-testid="error">{state.errorMessage || 'no-error'}</div>
      <div data-testid="request-id">{state.requestId || 'no-request'}</div>
      <div data-testid="source">{state.source || 'no-source'}</div>
      <button type="button" onClick={state.refresh}>
        retry
      </button>
    </div>
  )
}

describe('Dashboard State Hardening', () => {
  beforeEach(() => {
    dashboardApiMock.fetchDashboardContract.mockReset()
  })

  it('tenant degisince eski response yeni state uzerine yazilmaz', async () => {
    const first = createDeferred<any>()
    const second = createDeferred<any>()

    dashboardApiMock.fetchDashboardContract
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise)

    const { rerender } = render(<DashboardProbe tenantCode="TR01" />)

    rerender(<DashboardProbe tenantCode="TR01-FIN" />)

    await act(async () => {
      second.resolve({
        success: true,
        data: {
          metrics: [{ id: 'm1', label: 'Gunluk ciro', value: '₺212.940', delta: '+%1', tone: 'good' }],
          activities: [],
          actions: [],
          summaryCards: [],
        },
        meta: {
          requestId: 'req-new',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'dashboard.contract.live',
        },
      })
    })

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('success')
    })

    expect(screen.getByTestId('request-id')).toHaveTextContent('req-new')
    expect(screen.getByTestId('error')).toHaveTextContent('no-error')

    await act(async () => {
      first.resolve({
        success: false,
        error: {
          code: 'DASHBOARD_FORBIDDEN',
          message: 'eski hata',
        },
        meta: {
          requestId: 'req-old',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'dashboard.contract.live',
        },
      })
    })

    await waitFor(() => {
      expect(screen.getByTestId('request-id')).toHaveTextContent('req-new')
    })

    expect(screen.getByTestId('error')).toHaveTextContent('no-error')
  })

  it('retry sirasinda eski hata temizlenir ve success sonrasi reset olur', async () => {
    dashboardApiMock.fetchDashboardContract
      .mockResolvedValueOnce({
        success: false,
        error: {
          code: 'DASHBOARD_TIMEOUT',
          message: 'ilk hata',
        },
        meta: {
          requestId: 'req-error',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'dashboard.contract.live',
        },
      })
      .mockResolvedValueOnce({
        success: true,
        data: {
          metrics: [{ id: 'm1', label: 'Gunluk ciro', value: '₺148.420', delta: '+%1', tone: 'good' }],
          activities: [],
          actions: [],
          summaryCards: [],
        },
        meta: {
          requestId: 'req-success',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'dashboard.contract.live',
        },
      })

    render(<DashboardProbe tenantCode="TR01" />)

    await waitFor(() => {
      expect(screen.getByTestId('error')).toHaveTextContent('ilk hata')
    })

    fireEvent.click(screen.getByRole('button', { name: 'retry' }))

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('loading')
    })

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('success')
    })

    expect(screen.getByTestId('error')).toHaveTextContent('no-error')
    expect(screen.getByTestId('request-id')).toHaveTextContent('req-success')
  })
})
