import { describe, expect, it, vi } from 'vitest'
import { fetchDashboardContract } from './dashboardApi'

describe('dashboardApi', () => {
  it('mock modda mock envelope doner', async () => {
    const response = await fetchDashboardContract('TR01', {
      transportMode: 'mock',
    })

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('dashboard.contract.mock')
      expect(response.data.metrics.length).toBeGreaterThan(0)
    }
  })

  it('hybrid modda real fetch fail olursa mocka duser', async () => {
    const fetcher = vi.fn().mockRejectedValue(new Error('network down'))

    const response = await fetchDashboardContract('TR01', {
      transportMode: 'hybrid',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('dashboard.contract.mock')
    }
  })

  it('live modda real dashboard summary endpoint cevabini adapter ile map eder', async () => {
    const payload = {
      data: {
        daily_sales_display: '₺999.000',
        order_count: 123,
        active_tenant_count: 7,
        warning_count: 1,
      },
      meta: {
        request_id: 'req-real-dashboard-1',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.dashboard.summary',
      },
    }

    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () => JSON.stringify(payload),
    })

    const response = await fetchDashboardContract('TR01', {
      transportMode: 'live',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.dashboard.summary')
      expect(response.meta.requestId).toBe('req-real-dashboard-1')
      expect(response.data.metrics[0].value).toBe('₺999.000')
      expect(response.data.metrics[1].value).toBe('123')
      expect(response.data.metrics[2].value).toBe('7')
      expect(response.data.metrics[3].value).toBe('1')
    }
  })

  it('live modda alternatif backend alan adlarini ve kart yapisini map eder', async () => {
    const payload = {
      dashboard: {
        cards: [
          {
            key: 'revenue',
            display_value: '₺321.000',
          },
          {
            key: 'order',
            value: 555,
          },
          {
            key: 'tenant',
            value: 9,
          },
          {
            key: 'alert',
            value: 4,
          },
        ],
      },
      meta: {
        requestId: 'req-real-dashboard-2',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.dashboard.cards',
      },
    }

    const fetcher = vi.fn().mockResolvedValue({
      ok: true,
      text: async () => JSON.stringify(payload),
    })

    const response = await fetchDashboardContract('TR01-FIN', {
      transportMode: 'live',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.dashboard.cards')
      expect(response.meta.requestId).toBe('req-real-dashboard-2')
      expect(response.data.metrics[0].value).toBe('₺321.000')
      expect(response.data.metrics[1].value).toBe('555')
      expect(response.data.metrics[2].value).toBe('9')
      expect(response.data.metrics[3].value).toBe('4')
      expect(response.data.summaryCards[1].value).toBe('TR01-FIN')
    }
  })
})
