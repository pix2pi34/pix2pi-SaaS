import type {
  MissionControlHealth,
  MissionControlOverview,
  MissionControlServiceCard,
  MissionControlStatus,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type MissionControlFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function normalizeStatus(value: unknown): MissionControlStatus {
  if (typeof value !== 'string') {
    return 'UNKNOWN';
  }

  const status = value.trim().toUpperCase();

  if (status === 'UP' || status === 'OK' || status === 'ACTIVE' || status === 'ONLINE') {
    return 'UP';
  }

  if (status === 'DOWN' || status === 'FAIL' || status === 'FAILED' || status === 'OFFLINE') {
    return 'DOWN';
  }

  if (status === 'DEGRADED' || status === 'WARN' || status === 'WARNING') {
    return 'DEGRADED';
  }

  return 'UNKNOWN';
}

function buildHeaders(options: MissionControlFetchOptions): Record<string, string> {
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

export function normalizeMissionControlServices(payload: unknown): MissionControlServiceCard[] {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return [];
  }

  return Object.entries(payload as Record<string, unknown>)
    .map(([serviceName, status]) => ({
      serviceName,
      status: normalizeStatus(status),
      category: serviceName.includes('registry') ? 'registry' : 'runtime',
      lastCheckedAt: '-',
    }))
    .sort((a, b) => a.serviceName.localeCompare(b.serviceName));
}

export async function fetchMissionControlOverview(
  options: MissionControlFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<MissionControlOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, servicesResponse] = await Promise.all([
    fetcher('/mission-control/health', { headers }),
    fetcher('/mission-control/api/services', { headers }),
  ]);

  if (!healthResponse.ok) {
    throw new Error(`mission control health okunamadi: ${healthResponse.status}`);
  }

  if (!servicesResponse.ok) {
    throw new Error(`mission control services okunamadi: ${servicesResponse.status}`);
  }

  const healthPayload = await healthResponse.json() as MissionControlHealth;
  const servicesPayload = await servicesResponse.json();

  return {
    health: {
      ok: Boolean(healthPayload.ok),
      service: typeof healthPayload.service === 'string' ? healthPayload.service : 'mission-control',
    },
    services: normalizeMissionControlServices(servicesPayload),
    generatedAt: new Date().toISOString(),
  };
}
