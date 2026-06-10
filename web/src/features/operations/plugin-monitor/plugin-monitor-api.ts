import type {
  PluginCatalogRow,
  PluginMonitorOverview,
  PluginRuntimeHealth,
  PluginStateRow,
  PluginSummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type PluginMonitorFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: PluginMonitorFetchOptions): Record<string, string> {
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

function normalizeSummaryItem(raw: Record<string, unknown>): PluginSummaryItem {
  return {
    status: asText(raw.status, 'unknown'),
    count: asNumber(raw.count),
    pluginCount: asNumber(raw.plugin_count ?? raw.pluginCount),
    stateCount: asNumber(raw.state_count ?? raw.stateCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeCatalogRow(raw: Record<string, unknown>): PluginCatalogRow {
  return {
    pluginKey: asText(raw.plugin_key ?? raw.pluginKey, '-'),
    displayName: asText(raw.display_name ?? raw.displayName, '-'),
    versionNo: asText(raw.version_no ?? raw.versionNo, '-'),
    visibilityScope: asText(raw.visibility_scope ?? raw.visibilityScope, '-'),
    sourceType: asText(raw.source_type ?? raw.sourceType, '-'),
    lifecycleStatus: asText(raw.lifecycle_status ?? raw.lifecycleStatus, '-'),
    entrypointRef: asText(raw.entrypoint_ref ?? raw.entrypointRef, ''),
    checksum: asText(raw.checksum, ''),
    requiredPlatformVersion: asText(raw.required_platform_version ?? raw.requiredPlatformVersion, ''),
    isEnabled: asBool(raw.is_enabled ?? raw.isEnabled),
    publishedAt: asText(raw.published_at ?? raw.publishedAt, ''),
    deprecatedAt: asText(raw.deprecated_at ?? raw.deprecatedAt, ''),
    archivedAt: asText(raw.archived_at ?? raw.archivedAt, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeStateRow(raw: Record<string, unknown>): PluginStateRow {
  return {
    stateId: asText(raw.state_id ?? raw.stateId, '-'),
    pluginKey: asText(raw.plugin_key ?? raw.pluginKey, '-'),
    stateKey: asText(raw.state_key ?? raw.stateKey, '-'),
    desiredState: asText(raw.desired_state ?? raw.desiredState, '-'),
    currentState: asText(raw.current_state ?? raw.currentState, '-'),
    installRef: asText(raw.install_ref ?? raw.installRef, ''),
    installedAt: asText(raw.installed_at ?? raw.installedAt, ''),
    activatedAt: asText(raw.activated_at ?? raw.activatedAt, ''),
    deactivatedAt: asText(raw.deactivated_at ?? raw.deactivatedAt, ''),
    lastHealthAt: asText(raw.last_health_at ?? raw.lastHealthAt, ''),
    lastError: asText(raw.last_error ?? raw.lastError, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

export function normalizePluginSummary(payload: unknown): PluginSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizePluginCatalog(payload: unknown): PluginCatalogRow[] {
  return listFromPayload(payload).map(normalizeCatalogRow);
}

export function normalizePluginStates(payload: unknown): PluginStateRow[] {
  return listFromPayload(payload).map(normalizeStateRow);
}

export async function fetchPluginMonitorOverview(
  options: PluginMonitorFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<PluginMonitorOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, catalogResponse, statesResponse, runtimeResponse] =
    await Promise.all([
      fetcher('/plugin-runtime/health', { headers }),
      fetcher('/plugin-runtime/api/plugins/summary', { headers }),
      fetcher('/plugin-runtime/api/plugins/catalog?limit=50', { headers }),
      fetcher('/plugin-runtime/api/plugins/states?limit=50', { headers }),
      fetcher('/plugin-runtime/api/plugins/runtime?limit=50', { headers }),
    ]);

  if (!healthResponse.ok) {
    throw new Error(`plugin runtime health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`plugin summary okunamadi: ${summaryResponse.status}`);
  }

  if (!catalogResponse.ok) {
    throw new Error(`plugin catalog okunamadi: ${catalogResponse.status}`);
  }

  if (!statesResponse.ok) {
    throw new Error(`plugin states okunamadi: ${statesResponse.status}`);
  }

  if (!runtimeResponse.ok) {
    throw new Error(`plugin runtime okunamadi: ${runtimeResponse.status}`);
  }

  const health = await healthResponse.json() as PluginRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const catalogPayload = await catalogResponse.json();
  const statesPayload = await statesResponse.json();
  const runtimePayload = await runtimeResponse.json();

  return {
    health,
    summary: normalizePluginSummary(summaryPayload),
    catalog: normalizePluginCatalog(catalogPayload),
    states: normalizePluginStates(statesPayload),
    runtime: normalizePluginStates(runtimePayload),
  };
}
