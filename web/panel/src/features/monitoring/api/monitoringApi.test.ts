import { describe, expect, it, vi } from 'vitest'
import { fetchMonitoringContract } from './monitoringApi'

describe('monitoringApi', () => {
  it('mock modda mock envelope doner', async () => {
    const response = await fetchMonitoringContract('TR01', {
      transportMode: 'mock',
    })

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('monitoring.contract.mock')
      expect(response.data.cards.length).toBeGreaterThan(0)
    }
  })

  it('hybrid modda real fetch fail olursa mocka duser', async () => {
    const fetcher = vi.fn().mockRejectedValue(new Error('network down'))

    const response = await fetchMonitoringContract('TR01', {
      transportMode: 'hybrid',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalled()
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('monitoring.contract.mock')
    }
  })

  it('live modda real health ve warnings endpointlerini adapter ile map eder', async () => {
    const healthPayload = {
      data: {
        services_up: '6/6',
        avg_latency_display: '111 ms',
        last_check_display: '12 sn',
        services: [
          {
            id: 'svc-auth',
            service: 'identity-api',
            status: 'UP',
            latency: '41 ms',
            last_check: 'az once',
          },
          {
            id: 'svc-gw',
            service: 'api-gateway',
            status: 'DEGRADED',
            latency: '199 ms',
            last_check: 'az once',
          },
        ],
        timeline: [
          {
            id: 't1',
            title: 'Health snapshot alindi',
            detail: 'Canli health summary endpoint cevabi alindi.',
            time: 'az once',
          },
        ],
      },
      meta: {
        request_id: 'req-monitoring-1',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.health.summary',
      },
    }

    const warningsPayload = {
      data: {
        warning_count: 3,
        warnings: [
          {
            id: 'w1',
            title: 'Gateway latency yuksek',
            detail: 'Latency beklenen esigi asti.',
            level: 'high',
          },
          {
            id: 'w2',
            title: 'Read model gecikmeli',
            detail: 'Read model senkronu geriden geliyor.',
            level: 'medium',
          },
        ],
      },
      meta: {
        request_id: 'req-monitoring-2',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.monitoring.warnings',
      },
    }

    const fetcher = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(healthPayload),
      })
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(warningsPayload),
      })

    const response = await fetchMonitoringContract('TR01', {
      transportMode: 'live',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalledTimes(2)
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.health.summary')
      expect(response.meta.requestId).toBe('req-monitoring-1')
      expect(response.data.cards[0].value).toBe('6/6')
      expect(response.data.cards[1].value).toBe('3')
      expect(response.data.cards[2].value).toBe('111 ms')
      expect(response.data.services[0].service).toBe('identity-api')
      expect(response.data.services[1].status).toBe('DEGRADED')
      expect(response.data.warnings[0].title).toBe('Gateway latency yuksek')
      expect(response.data.timeline[0].title).toBe('Health snapshot alindi')
    }
  })

  it('live modda alternatif backend alan adlarini map eder', async () => {
    const healthPayload = {
      summary: {
        healthy_services: '5/5',
        latency_display: '145 ms',
        refresh_window: '20 sn',
        service_status: [
          {
            code: 'mission-control',
            health: 'UP',
            response_time: '88 ms',
            checked_at: '1 dk once',
          },
        ],
        events: [
          {
            name: 'Health timeline event',
            description: 'Health event gercekte geldi.',
            at: 'az once',
          },
        ],
      },
      meta: {
        requestId: 'req-monitoring-3',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.health.alt',
      },
    }

    const warningsPayload = {
      summary: {
        alert_count: 4,
        items: [
          {
            name: 'Alternate warning',
            reason: 'Alternative warnings payload geldi.',
            severity: 'critical',
          },
        ],
      },
      meta: {
        requestId: 'req-monitoring-4',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.warnings.alt',
      },
    }

    const fetcher = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(healthPayload),
      })
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(warningsPayload),
      })

    const response = await fetchMonitoringContract('TR01-FIN', {
      transportMode: 'live',
      fetcher,
    })

    expect(fetcher).toHaveBeenCalledTimes(2)
    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.meta.source).toBe('backend.health.alt')
      expect(response.meta.requestId).toBe('req-monitoring-3')
      expect(response.data.cards[0].value).toBe('5/5')
      expect(response.data.cards[1].value).toBe('4')
      expect(response.data.cards[2].value).toBe('145 ms')
      expect(response.data.services[0].service).toBe('mission-control')
      expect(response.data.warnings[0].level).toBe('high')
      expect(response.data.timeline[0].title).toBe('Health timeline event')
    }
  })

  it('live modda explicit empty warnings listesini korur', async () => {
    const healthPayload = {
      data: {
        services_up: '4/4',
        avg_latency_display: '99 ms',
        last_check_display: '8 sn',
      },
      meta: {
        request_id: 'req-monitoring-5',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.health.summary',
      },
    }

    const warningsPayload = {
      data: {
        warning_count: 0,
        warnings: [],
      },
      meta: {
        request_id: 'req-monitoring-6',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.monitoring.warnings',
      },
    }

    const fetcher = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(healthPayload),
      })
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(warningsPayload),
      })

    const response = await fetchMonitoringContract('TR01', {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.data.cards[1].value).toBe('0')
      expect(response.data.warnings).toEqual([])
    }
  })

  it('live modda explicit empty payload gelirse bos monitoring state doner', async () => {
    const healthPayload = {
      data: {
        empty: true,
        services: [],
        timeline: [],
      },
      meta: {
        request_id: 'req-monitoring-7',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.health.empty',
      },
    }

    const warningsPayload = {
      data: {
        empty: true,
        warnings: [],
      },
      meta: {
        request_id: 'req-monitoring-8',
        timestamp: '2026-04-21T00:00:00.000Z',
        source: 'backend.warnings.empty',
      },
    }

    const fetcher = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(healthPayload),
      })
      .mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(warningsPayload),
      })

    const response = await fetchMonitoringContract('TR01', {
      transportMode: 'live',
      fetcher,
    })

    expect(response.success).toBe(true)

    if (response.success) {
      expect(response.data.cards).toEqual([])
      expect(response.data.warnings).toEqual([])
      expect(response.data.services).toEqual([])
      expect(response.data.timeline).toEqual([])
    }
  })
})
