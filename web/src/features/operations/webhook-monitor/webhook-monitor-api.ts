import type {
  WebhookDeliveryRow,
  WebhookEndpointRow,
  WebhookMonitorOverview,
  WebhookRuntimeHealth,
  WebhookSummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type WebhookMonitorFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: WebhookMonitorFetchOptions): Record<string, string> {
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

  return items
    .filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === 'object' && !Array.isArray(item));
}

function normalizeSummaryItem(raw: Record<string, unknown>): WebhookSummaryItem {
  return {
    status: asText(raw.status, 'unknown'),
    count: asNumber(raw.count),
    endpointCount: asNumber(raw.endpoint_count ?? raw.endpointCount),
    attemptCount: asNumber(raw.attempt_count ?? raw.attemptCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeEndpointRow(raw: Record<string, unknown>): WebhookEndpointRow {
  return {
    endpointKey: asText(raw.endpoint_key ?? raw.endpointKey, '-'),
    displayName: asText(raw.display_name ?? raw.displayName, '-'),
    visibilityScope: asText(raw.visibility_scope ?? raw.visibilityScope, '-'),
    targetUrl: asText(raw.target_url ?? raw.targetUrl, '-'),
    httpMethod: asText(raw.http_method ?? raw.httpMethod, '-'),
    authType: asText(raw.auth_type ?? raw.authType, '-'),
    signatureHeader: asText(raw.signature_header ?? raw.signatureHeader, '-'),
    timeoutSeconds: asNumber(raw.timeout_seconds ?? raw.timeoutSeconds),
    retryLimit: asNumber(raw.retry_limit ?? raw.retryLimit),
    retryBackoffSeconds: asNumber(raw.retry_backoff_seconds ?? raw.retryBackoffSeconds),
    isEnabled: asBool(raw.is_enabled ?? raw.isEnabled),
    deliveryCount: asNumber(raw.delivery_count ?? raw.deliveryCount),
    failedCount: asNumber(raw.failed_count ?? raw.failedCount),
    deadLetterCount: asNumber(raw.dead_letter_count ?? raw.deadLetterCount),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeDeliveryRow(raw: Record<string, unknown>): WebhookDeliveryRow {
  return {
    deliveryId: asText(raw.delivery_id ?? raw.deliveryId, '-'),
    endpointKey: asText(raw.endpoint_key ?? raw.endpointKey, '-'),
    deliveryKey: asText(raw.delivery_key ?? raw.deliveryKey, '-'),
    eventType: asText(raw.event_type ?? raw.eventType, '-'),
    priority: asText(raw.priority, '-'),
    status: asText(raw.status, '-'),
    responseCode: asNumber(raw.response_code ?? raw.responseCode),
    retryCount: asNumber(raw.retry_count ?? raw.retryCount),
    maxAttempts: asNumber(raw.max_attempts ?? raw.maxAttempts),
    nextRetryAt: asText(raw.next_retry_at ?? raw.nextRetryAt, '-'),
    deliveredAt: asText(raw.delivered_at ?? raw.deliveredAt, '-'),
    deadLetteredAt: asText(raw.dead_lettered_at ?? raw.deadLetteredAt, '-'),
    sourceRefType: asText(raw.source_ref_type ?? raw.sourceRefType, '-'),
    sourceRefId: asText(raw.source_ref_id ?? raw.sourceRefId, '-'),
    lastError: asText(raw.last_error ?? raw.lastError, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

export function normalizeWebhookSummary(payload: unknown): WebhookSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeWebhookEndpoints(payload: unknown): WebhookEndpointRow[] {
  return listFromPayload(payload).map(normalizeEndpointRow);
}

export function normalizeWebhookDeliveries(payload: unknown): WebhookDeliveryRow[] {
  return listFromPayload(payload).map(normalizeDeliveryRow);
}

export async function fetchWebhookMonitorOverview(
  options: WebhookMonitorFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<WebhookMonitorOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, endpointsResponse, deliveriesResponse, dlqResponse] = await Promise.all([
    fetcher('/webhook-runtime/health', { headers }),
    fetcher('/webhook-runtime/api/webhooks/summary', { headers }),
    fetcher('/webhook-runtime/api/webhooks/endpoints', { headers }),
    fetcher('/webhook-runtime/api/webhooks/deliveries?limit=25', { headers }),
    fetcher('/webhook-runtime/api/webhooks/dlq?limit=25', { headers }),
  ]);

  if (!healthResponse.ok) {
    throw new Error(`webhook runtime health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`webhook summary okunamadi: ${summaryResponse.status}`);
  }

  if (!endpointsResponse.ok) {
    throw new Error(`webhook endpoints okunamadi: ${endpointsResponse.status}`);
  }

  if (!deliveriesResponse.ok) {
    throw new Error(`webhook deliveries okunamadi: ${deliveriesResponse.status}`);
  }

  if (!dlqResponse.ok) {
    throw new Error(`webhook dlq okunamadi: ${dlqResponse.status}`);
  }

  const health = await healthResponse.json() as WebhookRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const endpointsPayload = await endpointsResponse.json();
  const deliveriesPayload = await deliveriesResponse.json();
  const dlqPayload = await dlqResponse.json();

  return {
    health,
    summary: normalizeWebhookSummary(summaryPayload),
    endpoints: normalizeWebhookEndpoints(endpointsPayload),
    deliveries: normalizeWebhookDeliveries(deliveriesPayload),
    dlq: normalizeWebhookDeliveries(dlqPayload),
  };
}
