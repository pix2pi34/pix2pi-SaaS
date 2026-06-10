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
import type { DashboardContractData } from '../contracts/dashboard.contract'

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

function findMetricCards(
  source: Record<string, unknown>,
): Record<string, unknown>[] {
  for (const key of ['cards', 'kpis', 'metrics']) {
    const cards = toRecordArray(source[key])
    if (cards.length > 0) {
      return cards
    }
  }

  return []
}

function findCardMetricValue(
  cards: Record<string, unknown>[],
  candidates: string[],
  fallback: string,
) {
  const normalizedCandidates = candidates.map((item) => item.toLowerCase())

  for (const card of cards) {
    const id = asString(
      card.id ?? card.key ?? card.code ?? card.slug,
      '',
    ).toLowerCase()
    const label = asString(
      card.label ?? card.title ?? card.name,
      '',
    ).toLowerCase()

    const matched = normalizedCandidates.some(
      (candidate) => id.includes(candidate) || label.includes(candidate),
    )

    if (!matched) {
      continue
    }

    return asNumberString(
      card.value ?? card.display_value ?? card.amount ?? card.total,
      fallback,
    )
  }

  return fallback
}

function buildMockDashboardData(tenantCode: string): DashboardContractData {
  const code = normalizeTenantCode(tenantCode)

  return {
    metrics: [
      {
        id: 'ciro',
        label: 'Gunluk ciro',
        value: code === 'TR01-FIN' ? '₺212.940' : '₺148.420',
        delta: code === 'TR01-FIN' ? '+%12.1' : '+%8.4',
        tone: 'good',
      },
      {
        id: 'siparis',
        label: 'Acilan siparis',
        value: code === 'TR01-OPS' ? '341' : '286',
        delta: code === 'TR01-OPS' ? '+49' : '+34',
        tone: 'good',
      },
      {
        id: 'tenant',
        label: 'Aktif tenant oturumu',
        value: '3',
        delta: `baglam: ${code}`,
        tone: 'neutral',
      },
      {
        id: 'uyari',
        label: 'Izleme uyari alani',
        value: code === 'TR01-FIN' ? '1' : '2',
        delta: 'dashboard real summary hazir',
        tone: 'warn',
      },
    ],
    activities: [
      {
        id: 'a1',
        title: 'Dashboard summary contract alindi',
        detail: `${code} icin dashboard summary contract cevabi yuklendi.`,
        time: 'az once',
        state: 'ok',
      },
      {
        id: 'a2',
        title: 'Tenant baglamina gore veri secildi',
        detail: `Aktif tenant kodu ${code} dashboard summary entegrasyonuna tasindi.`,
        time: 'az once',
        state: 'ok',
      },
      {
        id: 'a3',
        title: 'Real summary entegrasyonu aktif',
        detail: 'Hybrid modda endpoint varsa gercek veri okunur, yoksa mocka donulur.',
        time: 'az once',
        state: 'pending',
      },
      {
        id: 'a4',
        title: 'Monitoring baglantisi ayrik ilerliyor',
        detail: 'Monitoring route kendi endpointleri ile baglanmaya devam edecek.',
        time: 'siradaki adim',
        state: 'attention',
      },
    ],
    actions: [
      {
        id: 'tenant-view',
        title: 'Tenant gorunumu ac',
        detail: `Secili tenant ${code} baglaminda dashboard aktif.`,
        state: 'ready',
      },
      {
        id: 'summary-refresh',
        title: 'Summary yenile',
        detail: 'Dashboard summary endpoint tekrar cagrilabilir.',
        state: 'next',
      },
      {
        id: 'monitoring-open',
        title: 'Monitoring alani',
        detail: 'Monitoring route farkli endpointler ile beslenecek.',
        state: 'next',
      },
    ],
    summaryCards: [
      {
        id: 'user',
        label: 'Kullanici baglami',
        value: 'Demo Panel Kullanicisi',
        detail: 'frontend contract snapshot',
      },
      {
        id: 'tenant',
        label: 'Aktif tenant',
        value: code,
        detail: 'tenant-aware data feed',
      },
      {
        id: 'source',
        label: 'Contract kaynagi',
        value: API_ENDPOINTS.dashboardSummary,
        detail: 'real summary endpoint',
      },
    ],
  }
}

function adaptDashboardData(
  input: unknown,
  tenantCode: string,
): DashboardContractData {
  const fallback = buildMockDashboardData(tenantCode)
  const root = asRecord(input)

  if (!root) {
    return fallback
  }

  const data =
    asRecord(root.data) ??
    asRecord(root.summary) ??
    asRecord(root.dashboard) ??
    root

  const cards = findMetricCards(data)

  const salesValue = asString(
    data.daily_sales_display ??
      data.total_sales_display ??
      data.daily_revenue_display ??
      data.revenue_display,
    findCardMetricValue(cards, ['sales', 'revenue', 'ciro'], fallback.metrics[0].value),
  )

  const orderValue = asNumberString(
    data.order_count ?? data.total_orders ?? data.daily_order_count,
    findCardMetricValue(cards, ['order', 'siparis'], fallback.metrics[1].value),
  )

  const tenantValue = asNumberString(
    data.active_tenant_count ?? data.active_tenants,
    findCardMetricValue(cards, ['tenant'], fallback.metrics[2].value),
  )

  const warningValue = asNumberString(
    data.warning_count ?? data.alert_count,
    findCardMetricValue(cards, ['warning', 'uyari', 'alert'], fallback.metrics[3].value),
  )

  const code = normalizeTenantCode(tenantCode)

  return {
    metrics: [
      {
        ...fallback.metrics[0],
        value: salesValue,
      },
      {
        ...fallback.metrics[1],
        value: orderValue,
      },
      {
        ...fallback.metrics[2],
        value: tenantValue,
        delta: `baglam: ${code}`,
      },
      {
        ...fallback.metrics[3],
        value: warningValue,
        delta: 'real veya hybrid summary',
      },
    ],
    activities: [
      {
        ...fallback.activities[0],
        detail: `${code} icin dashboard real summary response alindi.`,
      },
      {
        ...fallback.activities[1],
      },
      {
        ...fallback.activities[2],
        detail: 'Transport omurgasi gercek summary endpointini kullanabilecek halde.',
      },
      {
        ...fallback.activities[3],
      },
    ],
    actions: fallback.actions,
    summaryCards: [
      {
        ...fallback.summaryCards[0],
      },
      {
        ...fallback.summaryCards[1],
        value: code,
      },
      {
        ...fallback.summaryCards[2],
        value: API_ENDPOINTS.dashboardSummary,
        detail: 'real veya hybrid summary endpoint',
      },
    ],
  }
}

async function createMockDashboardEnvelope(tenantCode: string) {
  const data = buildMockDashboardData(tenantCode)

  return createMockSuccessEnvelope({
    data,
    source: 'dashboard.contract.mock',
    requestPrefix: 'dashboard-summary',
  })
}

export async function fetchDashboardContract(
  tenantCode: string,
  options: ApiRequestOptions = {},
): Promise<ApiEnvelope<DashboardContractData>> {
  const mode = resolveApiTransportMode(options.transportMode)

  if (mode === 'mock') {
    return createMockDashboardEnvelope(tenantCode)
  }

  try {
    const raw = await executeRequestWithRetry(
      () =>
        apiGetJson<unknown>(API_ENDPOINT_URLS.dashboardSummary, {
          ...options,
          headers: {
            ...buildTenantHeaders(tenantCode),
            ...(options.headers ?? {}),
          },
        }),
      {
        method: 'GET',
        maxRetries: options.maxRetries,
        retryDelayMs: options.retryDelayMs,
      },
    )

    const root = asRecord(raw)
    const meta = asRecord(root?.meta)
    const data = adaptDashboardData(raw, tenantCode)

    return {
      success: true,
      data,
      meta: {
        requestId: asString(
          meta?.request_id ?? meta?.requestId,
          `dashboard-real-${Math.random().toString(36).slice(2, 10)}`,
        ),
        timestamp: asString(
          meta?.timestamp,
          new Date().toISOString(),
        ),
        source: asString(meta?.source, 'dashboard.contract.real'),
      },
    }
  } catch (error) {
    if (shouldUseMockFallback(mode, error)) {
      return createMockDashboardEnvelope(tenantCode)
    }

    return buildApiErrorEnvelope(
      `dashboard.contract.${mode}`,
      error,
      'dashboard-fetch-error',
      'DASHBOARD',
    )
  }
}
