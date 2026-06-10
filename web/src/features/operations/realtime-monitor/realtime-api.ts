import type {
  RealtimeGenericRow,
  RealtimeOverview,
  RealtimeRuntimeHealth,
  RealtimeSummaryItem,
  RealtimeTableStatusItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type RealtimeFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: RealtimeFetchOptions): Record<string, string> {
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

function asBoolean(value: unknown): boolean {
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

function normalizeSummaryItem(raw: Record<string, unknown>): RealtimeSummaryItem {
  return {
    status: asText(raw.status, 'unknown'),
    channelCount: asNumber(raw.channel_count ?? raw.channelCount),
    connectionCount: asNumber(raw.connection_count ?? raw.connectionCount),
    activeConnectionCount: asNumber(raw.active_connection_count ?? raw.activeConnectionCount),
    webSocketCount: asNumber(raw.websocket_count ?? raw.webSocketCount),
    sseCount: asNumber(raw.sse_count ?? raw.sseCount),
    presenceCount: asNumber(raw.presence_count ?? raw.presenceCount),
    onlinePresenceCount: asNumber(raw.online_presence_count ?? raw.onlinePresenceCount),
    channelPermissionCount: asNumber(raw.channel_permission_count ?? raw.channelPermissionCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeTableStatusItem(raw: Record<string, unknown>): RealtimeTableStatusItem {
  return {
    tableName: asText(raw.table_name ?? raw.tableName, '-'),
    exists: asBoolean(raw.exists),
    count: asNumber(raw.count),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeGenericRow(raw: Record<string, unknown>): RealtimeGenericRow {
  return {
    tableName: asText(raw.table_name ?? raw.tableName, '-'),
    recordJSON: asText(raw.record_json ?? raw.recordJSON, '{}'),
    observedAt: asText(raw.observed_at ?? raw.observedAt, '-'),
  };
}

export function normalizeRealtimeSummary(payload: unknown): RealtimeSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeRealtimeTables(payload: unknown): RealtimeTableStatusItem[] {
  return listFromPayload(payload).map(normalizeTableStatusItem);
}

export function normalizeRealtimeRows(payload: unknown): RealtimeGenericRow[] {
  return listFromPayload(payload).map(normalizeGenericRow);
}

export async function fetchRealtimeOverview(
  options: RealtimeFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<RealtimeOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [
    healthResponse,
    summaryResponse,
    tablesResponse,
    channelsResponse,
    connectionsResponse,
    presenceResponse,
    permissionsResponse,
  ] = await Promise.all([
    fetcher('/realtime-runtime/health', { headers }),
    fetcher('/realtime-runtime/api/realtime/summary', { headers }),
    fetcher('/realtime-runtime/api/realtime/tables', { headers }),
    fetcher('/realtime-runtime/api/realtime/channels?limit=50', { headers }),
    fetcher('/realtime-runtime/api/realtime/connections?limit=50', { headers }),
    fetcher('/realtime-runtime/api/realtime/presence?limit=50', { headers }),
    fetcher('/realtime-runtime/api/realtime/permissions?limit=50', { headers }),
  ]);

  if (!healthResponse.ok) {
    throw new Error(`realtime health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`realtime summary okunamadi: ${summaryResponse.status}`);
  }

  if (!tablesResponse.ok) {
    throw new Error(`realtime tables okunamadi: ${tablesResponse.status}`);
  }

  if (!channelsResponse.ok) {
    throw new Error(`realtime channels okunamadi: ${channelsResponse.status}`);
  }

  if (!connectionsResponse.ok) {
    throw new Error(`realtime connections okunamadi: ${connectionsResponse.status}`);
  }

  if (!presenceResponse.ok) {
    throw new Error(`realtime presence okunamadi: ${presenceResponse.status}`);
  }

  if (!permissionsResponse.ok) {
    throw new Error(`realtime permissions okunamadi: ${permissionsResponse.status}`);
  }

  const health = await healthResponse.json() as RealtimeRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const tablesPayload = await tablesResponse.json();
  const channelsPayload = await channelsResponse.json();
  const connectionsPayload = await connectionsResponse.json();
  const presencePayload = await presenceResponse.json();
  const permissionsPayload = await permissionsResponse.json();

  return {
    health,
    summary: normalizeRealtimeSummary(summaryPayload),
    tables: normalizeRealtimeTables(tablesPayload),
    channels: normalizeRealtimeRows(channelsPayload),
    connections: normalizeRealtimeRows(connectionsPayload),
    presence: normalizeRealtimeRows(presencePayload),
    permissions: normalizeRealtimeRows(permissionsPayload),
  };
}
