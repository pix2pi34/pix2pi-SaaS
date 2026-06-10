import type {
  EarlyWarningIncidentItem,
  EarlyWarningOverview,
  EarlyWarningResourceItem,
  EarlyWarningRuntimeHealth,
  EarlyWarningServiceItem,
  EarlyWarningSignalItem,
  EarlyWarningSummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type EarlyWarningFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: EarlyWarningFetchOptions): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: 'application/json',
  };

  if (options.accessToken) {
    headers.Authorization = `Bearer ${options.accessToken}`;
  }

  if (options.tenantId) {
    headers['X-Tenant-ID'] = options.tenantId;
  }

  return headers;
}

function asText(value: unknown, fallback = ''): string {
  if (typeof value === 'string') {
    return value;
  }

  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }

  return fallback;
}

function asNumber(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

function listFromPayload(payload: unknown): Record<string, unknown>[] {
  if (!payload || typeof payload !== 'object') {
    return [];
  }

  const obj = payload as Record<string, unknown>;
  const items = obj.items;

  if (!Array.isArray(items)) {
    return [];
  }

  return items.filter(
    (item): item is Record<string, unknown> =>
      Boolean(item) && typeof item === 'object' && !Array.isArray(item),
  );
}

function normalizeSummaryItem(raw: Record<string, unknown>): EarlyWarningSummaryItem {
  return {
    alertLevel: asText(raw.alert_level ?? raw.alertLevel, 'unknown'),
    serviceCount: asNumber(raw.service_count ?? raw.serviceCount),
    serviceOKCount: asNumber(raw.service_ok_count ?? raw.serviceOKCount),
    serviceFailCount: asNumber(raw.service_fail_count ?? raw.serviceFailCount),
    resourceCount: asNumber(raw.resource_count ?? raw.resourceCount),
    signalCount: asNumber(raw.signal_count ?? raw.signalCount),
    warningCount: asNumber(raw.warning_count ?? raw.warningCount),
    criticalCount: asNumber(raw.critical_count ?? raw.criticalCount),
    incidentCount: asNumber(raw.incident_count ?? raw.incidentCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeServiceItem(raw: Record<string, unknown>): EarlyWarningServiceItem {
  return {
    serviceKey: asText(raw.service_key ?? raw.serviceKey, '-'),
    display: asText(raw.display, '-'),
    status: asText(raw.status, '-'),
    httpStatus: asNumber(raw.http_status ?? raw.httpStatus),
    latencyMs: asNumber(raw.latency_ms ?? raw.latencyMs),
    message: asText(raw.message, '-'),
    checkedAt: asText(raw.checked_at ?? raw.checkedAt, '-'),
  };
}

function normalizeResourceItem(raw: Record<string, unknown>): EarlyWarningResourceItem {
  return {
    resourceKey: asText(raw.resource_key ?? raw.resourceKey, '-'),
    display: asText(raw.display, '-'),
    value: asNumber(raw.value),
    unit: asText(raw.unit, '-'),
    usedPercent: asNumber(raw.used_percent ?? raw.usedPercent),
    level: asText(raw.level, '-'),
    message: asText(raw.message, '-'),
    checkedAt: asText(raw.checked_at ?? raw.checkedAt, '-'),
  };
}

function normalizeSignalItem(raw: Record<string, unknown>): EarlyWarningSignalItem {
  return {
    signalKey: asText(raw.signal_key ?? raw.signalKey, '-'),
    category: asText(raw.category, '-'),
    level: asText(raw.level, '-'),
    status: asText(raw.status, '-'),
    message: asText(raw.message, '-'),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeIncidentItem(raw: Record<string, unknown>): EarlyWarningIncidentItem {
  return {
    tableName: asText(raw.table_name ?? raw.tableName, '-'),
    count: asNumber(raw.count),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

export function normalizeEarlyWarningSummary(payload: unknown): EarlyWarningSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeEarlyWarningServices(payload: unknown): EarlyWarningServiceItem[] {
  return listFromPayload(payload).map(normalizeServiceItem);
}

export function normalizeEarlyWarningResources(payload: unknown): EarlyWarningResourceItem[] {
  return listFromPayload(payload).map(normalizeResourceItem);
}

export function normalizeEarlyWarningSignals(payload: unknown): EarlyWarningSignalItem[] {
  return listFromPayload(payload).map(normalizeSignalItem);
}

export function normalizeEarlyWarningIncidents(payload: unknown): EarlyWarningIncidentItem[] {
  return listFromPayload(payload).map(normalizeIncidentItem);
}

export async function fetchEarlyWarningOverview(
  options: EarlyWarningFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<EarlyWarningOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, servicesResponse, resourcesResponse, signalsResponse, incidentsResponse] =
    await Promise.all([
      fetcher('/early-warning-runtime/health', { headers }),
      fetcher('/early-warning-runtime/api/early-warning/summary', { headers }),
      fetcher('/early-warning-runtime/api/early-warning/services', { headers }),
      fetcher('/early-warning-runtime/api/early-warning/resources', { headers }),
      fetcher('/early-warning-runtime/api/early-warning/signals?limit=100', { headers }),
      fetcher('/early-warning-runtime/api/early-warning/incidents', { headers }),
    ]);

  if (!healthResponse.ok) {
    throw new Error(`early warning health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`early warning summary okunamadi: ${summaryResponse.status}`);
  }

  if (!servicesResponse.ok) {
    throw new Error(`early warning services okunamadi: ${servicesResponse.status}`);
  }

  if (!resourcesResponse.ok) {
    throw new Error(`early warning resources okunamadi: ${resourcesResponse.status}`);
  }

  if (!signalsResponse.ok) {
    throw new Error(`early warning signals okunamadi: ${signalsResponse.status}`);
  }

  if (!incidentsResponse.ok) {
    throw new Error(`early warning incidents okunamadi: ${incidentsResponse.status}`);
  }

  const health = await healthResponse.json() as EarlyWarningRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const servicesPayload = await servicesResponse.json();
  const resourcesPayload = await resourcesResponse.json();
  const signalsPayload = await signalsResponse.json();
  const incidentsPayload = await incidentsResponse.json();

  return {
    health,
    summary: normalizeEarlyWarningSummary(summaryPayload),
    services: normalizeEarlyWarningServices(servicesPayload),
    resources: normalizeEarlyWarningResources(resourcesPayload),
    signals: normalizeEarlyWarningSignals(signalsPayload),
    incidents: normalizeEarlyWarningIncidents(incidentsPayload),
  };
}
