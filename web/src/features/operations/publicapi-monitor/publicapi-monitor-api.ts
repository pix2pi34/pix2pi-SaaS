import type {
  APIKeyRow,
  APIQuotaPolicyRow,
  APIUsageRow,
  PublicAPIMonitorOverview,
  PublicAPIRuntimeHealth,
  PublicAPISummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type PublicAPIMonitorFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: PublicAPIMonitorFetchOptions): Record<string, string> {
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

function asBool(value: unknown): boolean {
  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'string') {
    return value.toLowerCase() === 'true';
  }

  return false;
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

function normalizeSummaryItem(raw: Record<string, unknown>): PublicAPISummaryItem {
  return {
    status: asText(raw.status, 'unknown'),
    count: asNumber(raw.count),
    keyCount: asNumber(raw.key_count ?? raw.keyCount),
    policyCount: asNumber(raw.policy_count ?? raw.policyCount),
    usageCount: asNumber(raw.usage_count ?? raw.usageCount),
    requestCount: asNumber(raw.request_count ?? raw.requestCount),
    rejectedCount: asNumber(raw.rejected_count ?? raw.rejectedCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeAPIKeyRow(raw: Record<string, unknown>): APIKeyRow {
  return {
    keyRef: asText(raw.key_ref ?? raw.keyRef, '-'),
    displayName: asText(raw.display_name ?? raw.displayName, '-'),
    visibilityScope: asText(raw.visibility_scope ?? raw.visibilityScope, '-'),
    keyPrefix: asText(raw.key_prefix ?? raw.keyPrefix, ''),
    status: asText(raw.status, '-'),
    lastUsedAt: asText(raw.last_used_at ?? raw.lastUsedAt, ''),
    expiresAt: asText(raw.expires_at ?? raw.expiresAt, ''),
    revokedAt: asText(raw.revoked_at ?? raw.revokedAt, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeQuotaPolicyRow(raw: Record<string, unknown>): APIQuotaPolicyRow {
  return {
    policyKey: asText(raw.policy_key ?? raw.policyKey, '-'),
    keyRef: asText(raw.key_ref ?? raw.keyRef, '-'),
    endpointScope: asText(raw.endpoint_scope ?? raw.endpointScope, '-'),
    quotaPeriod: asText(raw.quota_period ?? raw.quotaPeriod, '-'),
    requestLimit: asNumber(raw.request_limit ?? raw.requestLimit),
    burstLimit: asNumber(raw.burst_limit ?? raw.burstLimit),
    isEnabled: asBool(raw.is_enabled ?? raw.isEnabled),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeUsageRow(raw: Record<string, unknown>): APIUsageRow {
  return {
    usageId: asText(raw.usage_id ?? raw.usageId, '-'),
    keyRef: asText(raw.key_ref ?? raw.keyRef, '-'),
    policyKey: asText(raw.policy_key ?? raw.policyKey, '-'),
    usageWindowStart: asText(raw.usage_window_start ?? raw.usageWindowStart, ''),
    usageWindowEnd: asText(raw.usage_window_end ?? raw.usageWindowEnd, ''),
    requestCount: asNumber(raw.request_count ?? raw.requestCount),
    rejectedCount: asNumber(raw.rejected_count ?? raw.rejectedCount),
    lastRequestAt: asText(raw.last_request_at ?? raw.lastRequestAt, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

export function normalizePublicAPISummary(payload: unknown): PublicAPISummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeAPIKeys(payload: unknown): APIKeyRow[] {
  return listFromPayload(payload).map(normalizeAPIKeyRow);
}

export function normalizeQuotaPolicies(payload: unknown): APIQuotaPolicyRow[] {
  return listFromPayload(payload).map(normalizeQuotaPolicyRow);
}

export function normalizeUsage(payload: unknown): APIUsageRow[] {
  return listFromPayload(payload).map(normalizeUsageRow);
}

export async function fetchPublicAPIMonitorOverview(
  options: PublicAPIMonitorFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<PublicAPIMonitorOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, keysResponse, policiesResponse, usageResponse] =
    await Promise.all([
      fetcher('/publicapi-runtime/health', { headers }),
      fetcher('/publicapi-runtime/api/publicapi/summary', { headers }),
      fetcher('/publicapi-runtime/api/publicapi/api-keys?limit=50', { headers }),
      fetcher('/publicapi-runtime/api/publicapi/quota-policies?limit=50', { headers }),
      fetcher('/publicapi-runtime/api/publicapi/usage?limit=50', { headers }),
    ]);

  if (!healthResponse.ok) {
    throw new Error(`public api runtime health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`public api summary okunamadi: ${summaryResponse.status}`);
  }

  if (!keysResponse.ok) {
    throw new Error(`api keys okunamadi: ${keysResponse.status}`);
  }

  if (!policiesResponse.ok) {
    throw new Error(`quota policies okunamadi: ${policiesResponse.status}`);
  }

  if (!usageResponse.ok) {
    throw new Error(`api usage okunamadi: ${usageResponse.status}`);
  }

  const health = await healthResponse.json() as PublicAPIRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const keysPayload = await keysResponse.json();
  const policiesPayload = await policiesResponse.json();
  const usagePayload = await usageResponse.json();

  return {
    health,
    summary: normalizePublicAPISummary(summaryPayload),
    apiKeys: normalizeAPIKeys(keysPayload),
    quotaPolicies: normalizeQuotaPolicies(policiesPayload),
    usage: normalizeUsage(usagePayload),
  };
}
