import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { describe, expect, it, vi, beforeEach } from 'vitest'
import { useMonitoringSummary } from '../hooks/useMonitoringSummary'

const monitoringApiMock = vi.hoisted(() => ({
  fetchMonitoringContract: vi.fn(),
}))

vi.mock('../api/monitoringApi', () => monitoringApiMock)

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

function MonitoringProbe({ tenantCode }: { tenantCode: string }) {
  const state = useMonitoringSummary(tenantCode)

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

describe('Monitoring State Hardening', () => {
  beforeEach(() => {
    monitoringApiMock.fetchMonitoringContract.mockReset()
  })

  it('tenant degisince eski response yeni state uzerine yazilmaz', async () => {
    const first = createDeferred<any>()
    const second = createDeferred<any>()

    monitoringApiMock.fetchMonitoringContract
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise)

    const { rerender } = render(<MonitoringProbe tenantCode="TR01" />)

    rerender(<MonitoringProbe tenantCode="TR01-OPS" />)

    await act(async () => {
      second.resolve({
        success: true,
        data: {
          cards: [{ id: 'c1', label: 'Servis sagligi', value: '5/5', detail: 'detay', tone: 'healthy' }],
          warnings: [],
          services: [],
          timeline: [],
        },
        meta: {
          requestId: 'req-monitoring-new',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'monitoring.contract.live',
        },
      })
    })

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('success')
    })

    expect(screen.getByTestId('request-id')).toHaveTextContent('req-monitoring-new')
    expect(screen.getByTestId('error')).toHaveTextContent('no-error')

    await act(async () => {
      first.resolve({
        success: false,
        error: {
          code: 'MONITORING_TIMEOUT',
          message: 'eski monitoring hata',
        },
        meta: {
          requestId: 'req-monitoring-old',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'monitoring.contract.live',
        },
      })
    })

    await waitFor(() => {
      expect(screen.getByTestId('request-id')).toHaveTextContent('req-monitoring-new')
    })

    expect(screen.getByTestId('error')).toHaveTextContent('no-error')
  })

  it('retry sirasinda eski hata temizlenir ve success sonrasi reset olur', async () => {
    monitoringApiMock.fetchMonitoringContract
      .mockResolvedValueOnce({
        success: false,
        error: {
          code: 'MONITORING_TIMEOUT',
          message: 'ilk monitoring hata',
        },
        meta: {
          requestId: 'req-monitoring-error',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'monitoring.contract.live',
        },
      })
      .mockResolvedValueOnce({
        success: true,
        data: {
          cards: [{ id: 'c1', label: 'Servis sagligi', value: '4/5', detail: 'detay', tone: 'healthy' }],
          warnings: [],
          services: [],
          timeline: [],
        },
        meta: {
          requestId: 'req-monitoring-success',
          timestamp: '2026-04-21T00:00:00.000Z',
          source: 'monitoring.contract.live',
        },
      })

    render(<MonitoringProbe tenantCode="TR01" />)

    await waitFor(() => {
      expect(screen.getByTestId('error')).toHaveTextContent('ilk monitoring hata')
    })

    fireEvent.click(screen.getByRole('button', { name: 'retry' }))

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('loading')
    })

    await waitFor(() => {
      expect(screen.getByTestId('status')).toHaveTextContent('success')
    })

    expect(screen.getByTestId('error')).toHaveTextContent('no-error')
    expect(screen.getByTestId('request-id')).toHaveTextContent('req-monitoring-success')
  })
})
