import { API_ENDPOINTS, API_ENDPOINT_URLS } from '../../../shared/api/config/endpoints'
import { createMockSuccessEnvelope } from '../../../shared/api/client/mockClient'
import {
  apiGetJson,
  buildTenantHeaders,
  resolveApiTransportMode,
  type ApiRequestOptions,
} from '../../../shared/api/client/httpClient'
import {
  buildApiErrorEnvelope,
  executeRequestWithRetry,
  shouldUseMockFallback,
} from '../../../shared/api/client/requestPolicy'
import type { ApiEnvelope } from '../../../shared/api/contracts/api.types'
import type { MonitoringContractData } from '../contracts/monitoring.contract'
import type {
  HealthCard,
  ServiceStatus,
  TimelineItem,
  WarningItem,
} from '../types/monitoring.types'

function normalizeTenantCode(tenantCode: string) {
  const normalized = tenantCode.trim().toUpperCase()
  return normalized || 'TR01'
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : null
}

function asString(value: unknown, fallback: string) {
  return typeof value === 'string' && value.trim() ? value : fallback
}

function asNumberString(value: unknown, fallback: string) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return String(value)
  }

  if (typeof value === 'string' && value.trim()) {
    return value
  }

  return fallback
}

function toRecordArray(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.filter(
    (item): item is Record<string, unknown> =>
      typeof item === 'object' && item !== null,
  )
}

function pickArray(
  source: Record<string, unknown>,
  keys: string[],
): { items: Record<string, unknown>[]; explicit: boolean } {
  for (const key of keys) {
    if (key in source) {
      return {
        items: toRecordArray(source[key]),
        explicit: true,
      }
    }
  }

  return {
    items: [],
    explicit: false,
  }
}

function normalizeHealthTone(input: string): HealthCard['tone'] {
  const value = input.toLowerCase()

  if (value.includes('warn')) {
    return 'warning'
  }

  if (value.includes('degrad') || value.includes('slow') || value.includes('risk')) {
    return 'degraded'
  }

  return 'healthy'
}

function normalizeServiceStatus(input: string): ServiceStatus['status'] {
  const value = input.toUpperCase()

  if (value.includes('DEGRADED')) {
    return 'DEGRADED'
  }

  if (value.includes('PENDING') || value.includes('UNKNOWN')) {
    return 'PENDING'
  }

  return 'UP'
}

function normalizeWarningLevel(input: string): WarningItem['level'] {
  const value = input.toLowerCase()

  if (value.includes('high') || value.includes('critical')) {
    return 'high'
  }

  return 'medium'
}

function isExplicitEmpty(data: Record<string, unknown>) {
  return data.empty === true || data.no_data === true
}

function buildMockMonitoringData(tenantCode: string): MonitoringContractData {
  const code = normalizeTenantCode(tenantCode)

  return {
    cards: [
      {
        id: 'services',
        label: 'Servis sagligi',
        value: code === 'TR01-OPS' ? '5/5' : '4/5',
        detail: `kontrat tenant: ${code}`,
        tone: 'healthy',
      },
      {
        id: 'warnings',
        label: 'Aktif uyari',
        value: code === 'TR01-FIN' ? '1' : '2',
        detail: 'warning contract baglandi',
        tone: 'warning',
      },
      {
        id: 'latency',
        label: 'Ortalama gecikme',
        value: code === 'TR01-OPS' ? '154 ms' : '182 ms',
        detail: 'real health hybrid adapter cevabi',
        tone: 'degraded',
      },
      {
        id: 'checks',
        label: 'Son health taramasi',
        value: '18 sn',
        detail: API_ENDPOINTS.healthSummary,
        tone: 'healthy',
      },
    ],
    warnings: [
      {
        id: 'w1',
        title: 'Gateway summary endpoint baglantisi bekliyor',
        detail: `${code} icin monitoring warnings contract cevabi uretildi.`,
        level: 'medium',
      },
      {
        id: 'w2',
        title: 'Bir servis degrade senaryosunda',
        detail: 'Monitoring skeleton tarafinda gorunurluk icin placeholder uyaridir.',
        level: 'high',
      },
    ],
    services: [
      {
        id: 'svc-identity',
        service: 'identity-api',
        status: 'UP',
        latency: '64 ms',
        lastCheck: 'az once',
      },
      {
        id: 'svc-gateway',
        service: 'api-gateway',
        status: 'DEGRADED',
        latency: code === 'TR01-FIN' ? '221 ms' : '241 ms',
        lastCheck: 'az once',
      },
      {
        id: 'svc-mission',
        service: 'mission-control',
        status: 'UP',
        latency: '88 ms',
        lastCheck: '1 dk once',
      },
      {
        id: 'svc-reporting',
        service: 'reporting-read-model',
        status: 'PENDING',
        latency: '--',
        lastCheck: '9.3 sonrasi',
      },
    ],
    timeline: [
      {
        id: 'm1',
        title: 'Monitoring contract response alindi',
        detail: `${code} icin health overview contract cevabi yuklendi.`,
        time: 'az once',
      },
      {
        id: 'm2',
        title: 'Warning panel contract ile beslendi',
        detail: 'Warning listesi adapter katmani ustunden guncellendi.',
        time: 'az once',
      },
      {
        id: 'm3',
        title: 'Service table contract ile eslendi',
        detail: 'Service status verisi hybrid envelope icinde normalize edildi.',
        time: 'az once',
      },
    ],
  }
}

function adaptCards(
  healthData: Record<string, unknown>,
  warningsData: Record<string, unknown>,
  tenantCode: string,
): HealthCard[] {
  const fallback = buildMockMonitoringData(tenantCode).cards
  const code = normalizeTenantCode(tenantCode)

  return [
    {
      ...fallback[0],
      value: asNumberString(
        healthData.services_up ??
          healthData.up_count ??
          healthData.healthy_services ??
          healthData.service_health,
        fallback[0].value,
      ),
      detail: `kontrat tenant: ${code}`,
      tone: normalizeHealthTone(
        asString(
          healthData.service_health_tone ?? healthData.health_tone,
          fallback[0].tone,
        ),
      ),
    },
    {
      ...fallback[1],
      value: asNumberString(
        warningsData.warning_count ??
          warningsData.alert_count ??
          healthData.warning_count,
        fallback[1].value,
      ),
      detail: 'real warnings endpoint baglandi',
      tone: 'warning',
    },
    {
      ...fallback[2],
      value: asString(
        healthData.avg_latency_display ??
          healthData.avg_latency ??
          healthData.latency_display,
        fallback[2].value,
      ),
      detail: 'real health endpoint adaptoru',
      tone: normalizeHealthTone(
        asString(
          healthData.latency_tone ?? healthData.performance_tone,
          fallback[2].tone,
        ),
      ),
    },
    {
      ...fallback[3],
      value: asString(
        healthData.last_check_display ??
          healthData.last_scan ??
          healthData.refresh_window,
        fallback[3].value,
      ),
      detail: API_ENDPOINTS.healthSummary,
      tone: 'healthy',
    },
  ]
}

function adaptWarnings(
  warningsData: Record<string, unknown>,
  tenantCode: string,
): WarningItem[] {
  const fallback = buildMockMonitoringData(tenantCode).warnings
  const picked = pickArray(warningsData, ['warnings', 'items'])

  if (picked.explicit && picked.items.length === 0) {
    return []
  }

  if (!picked.explicit && picked.items.length === 0) {
    return fallback
  }

  return picked.items.slice(0, 5).map((item, index) => ({
    id: asString(item.id, `warn-${index + 1}`),
    title: asString(
      item.title ?? item.message ?? item.name,
      fallback[index]?.title ?? `Warning ${index + 1}`,
    ),
    detail: asString(
      item.detail ?? item.description ?? item.reason,
      fallback[index]?.detail ?? 'Warning detayi bekleniyor.',
    ),
    level: normalizeWarningLevel(
      asString(item.level ?? item.severity, fallback[index]?.level ?? 'medium'),
    ),
  }))
}

function adaptServices(
  healthData: Record<string, unknown>,
  tenantCode: string,
): ServiceStatus[] {
  const fallback = buildMockMonitoringData(tenantCode).services
  const picked = pickArray(healthData, ['services', 'service_status', 'items'])

  if (picked.explicit && picked.items.length === 0) {
    return []
  }

  if (!picked.explicit && picked.items.length === 0) {
    return fallback
  }

  return picked.items.slice(0, 8).map((item, index) => ({
    id: asString(item.id, `svc-${index + 1}`),
    service: asString(
      item.service ?? item.name ?? item.code,
      fallback[index]?.service ?? `service-${index + 1}`,
    ),
    status: normalizeServiceStatus(
      asString(item.status ?? item.health, fallback[index]?.status ?? 'UP'),
    ),
    latency: asString(
      item.latency ?? item.latency_display ?? item.response_time,
      fallback[index]?.latency ?? '--',
    ),
    lastCheck: asString(
      item.last_check ?? item.checked_at ?? item.updated_at,
      fallback[index]?.lastCheck ?? 'bekleniyor',
    ),
  }))
}

function adaptTimeline(
  healthData: Record<string, unknown>,
  warningsData: Record<string, unknown>,
  tenantCode: string,
): TimelineItem[] {
  const fallback = buildMockMonitoringData(tenantCode).timeline
  const code = normalizeTenantCode(tenantCode)
  const pickedHealth = pickArray(healthData, ['timeline', 'events'])
  const pickedWarnings = pickArray(warningsData, ['timeline'])
  const items =
    pickedHealth.items.length > 0
      ? pickedHealth.items
      : pickedWarnings.items

  if ((pickedHealth.explicit || pickedWarnings.explicit) && items.length === 0) {
    return []
  }

  if (!pickedHealth.explicit && !pickedWarnings.explicit && items.length === 0) {
    return [
      {
        ...fallback[0],
        detail: `${code} icin health summary ve warnings response alindi.`,
      },
      fallback[1],
      fallback[2],
    ]
  }

  return items.slice(0, 5).map((item, index) => ({
    id: asString(item.id, `timeline-${index + 1}`),
    title: asString(
      item.title ?? item.message ?? item.name,
      fallback[index]?.title ?? `Timeline ${index + 1}`,
    ),
    detail: asString(
      item.detail ?? item.description ?? item.reason,
      fallback[index]?.detail ?? 'Timeline detayi bekleniyor.',
    ),
    time: asString(
      item.time ?? item.at ?? item.created_at,
      fallback[index]?.time ?? 'az once',
    ),
  }))
}

function isExplicitMonitoringEmpty(
  healthData: Record<string, unknown>,
  warningsData: Record<string, unknown>,
) {
  const servicePick = pickArray(healthData, ['services', 'service_status', 'items'])
  const warningPick = pickArray(warningsData, ['warnings', 'items'])
  const timelinePick = pickArray(healthData, ['timeline', 'events'])

  if (isExplicitEmpty(healthData) || isExplicitEmpty(warningsData)) {
    return true
  }

  return (
    servicePick.explicit &&
    warningPick.explicit &&
    timelinePick.explicit &&
    servicePick.items.length === 0 &&
    warningPick.items.length === 0 &&
    timelinePick.items.length === 0
  )
}

function adaptMonitoringData(
  healthInput: unknown,
  warningsInput: unknown,
  tenantCode: string,
): MonitoringContractData {
  const healthRoot = asRecord(healthInput)
  const warningsRoot = asRecord(warningsInput)

  const healthData =
    asRecord(healthRoot?.data) ??
    asRecord(healthRoot?.summary) ??
    asRecord(healthRoot?.health) ??
    healthRoot ??
    {}

  const warningsData =
    asRecord(warningsRoot?.data) ??
    asRecord(warningsRoot?.summary) ??
    asRecord(warningsRoot?.warnings) ??
    warningsRoot ??
    {}

  if (isExplicitMonitoringEmpty(healthData, warningsData)) {
    return {
      cards: [],
      warnings: [],
      services: [],
      timeline: [],
    }
  }

  return {
    cards: adaptCards(healthData, warningsData, tenantCode),
    warnings: adaptWarnings(warningsData, tenantCode),
    services: adaptServices(healthData, tenantCode),
    timeline: adaptTimeline(healthData, warningsData, tenantCode),
  }
}

async function createMockMonitoringEnvelope(tenantCode: string) {
  const data = buildMockMonitoringData(tenantCode)

  return createMockSuccessEnvelope({
    data,
    source: 'monitoring.contract.mock',
    requestPrefix: 'monitoring-summary',
  })
}

export async function fetchMonitoringContract(
  tenantCode: string,
  options: ApiRequestOptions = {},
): Promise<ApiEnvelope<MonitoringContractData>> {
  const mode = resolveApiTransportMode(options.transportMode)

  if (mode === 'mock') {
    return createMockMonitoringEnvelope(tenantCode)
  }

  try {
    const headers = {
      ...buildTenantHeaders(tenantCode),
      ...(options.headers ?? {}),
    }

    const [healthRaw, warningsRaw] = await Promise.all([
      executeRequestWithRetry(
        () =>
          apiGetJson<unknown>(API_ENDPOINT_URLS.healthSummary, {
            ...options,
            headers,
          }),
        {
          method: 'GET',
          maxRetries: options.maxRetries,
          retryDelayMs: options.retryDelayMs,
        },
      ),
      executeRequestWithRetry(
        () =>
          apiGetJson<unknown>(API_ENDPOINT_URLS.monitoringWarnings, {
            ...options,
            headers,
          }),
        {
          method: 'GET',
          maxRetries: options.maxRetries,
          retryDelayMs: options.retryDelayMs,
        },
      ),
    ])

    const healthRoot = asRecord(healthRaw)
    const warningsRoot = asRecord(warningsRaw)
    const healthMeta = asRecord(healthRoot?.meta)
    const warningsMeta = asRecord(warningsRoot?.meta)
    const data = adaptMonitoringData(healthRaw, warningsRaw, tenantCode)

    return {
      success: true,
      data,
      meta: {
        requestId: asString(
          healthMeta?.request_id ??
            healthMeta?.requestId ??
            warningsMeta?.request_id ??
            warningsMeta?.requestId,
          `monitoring-real-${Math.random().toString(36).slice(2, 10)}`,
        ),
        timestamp: asString(
          healthMeta?.timestamp ?? warningsMeta?.timestamp,
          new Date().toISOString(),
        ),
        source: asString(
          healthMeta?.source ?? warningsMeta?.source,
          'monitoring.contract.real',
        ),
      },
    }
  } catch (error) {
    if (shouldUseMockFallback(mode, error)) {
      return createMockMonitoringEnvelope(tenantCode)
    }

    return buildApiErrorEnvelope(
      `monitoring.contract.${mode}`,
      error,
      'monitoring-fetch-error',
      'MONITORING',
    )
  }
}
