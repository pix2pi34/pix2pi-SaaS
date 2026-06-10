import { getRuntimeConfig } from '../../../core/config/runtime-config';
import type { ServiceRegistryInstance, ServiceRegistryStatus } from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type FetchServiceRegistryOptions = {
  accessToken?: string;
  tenantId?: string;
};

type RawServiceObject = {
  serviceName?: unknown;
  service_name?: unknown;
  name?: unknown;
  service?: unknown;
  instanceId?: unknown;
  instance_id?: unknown;
  status?: unknown;
  endpoint?: unknown;
  url?: unknown;
  node?: unknown;
  version?: unknown;
  lastHeartbeatAt?: unknown;
  last_heartbeat_at?: unknown;
  tenantVisibility?: unknown;
  tenant_visibility?: unknown;
};

function asText(value: unknown, fallback: string): string {
  if (typeof value === 'string' && value.trim() !== '') {
    return value.trim();
  }

  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }

  return fallback;
}

function normalizeStatus(value: unknown): ServiceRegistryStatus {
  const status = asText(value, 'UNKNOWN').toUpperCase();

  if (status === 'UP' || status === 'ONLINE' || status === 'ACTIVE' || status === 'OK') {
    return 'UP';
  }

  if (status === 'DOWN' || status === 'OFFLINE' || status === 'FAILED') {
    return 'DOWN';
  }

  if (status === 'DEGRADED' || status === 'WARNING' || status === 'WARN') {
    return 'DEGRADED';
  }

  return 'UNKNOWN';
}

function normalizeServiceObject(raw: RawServiceObject, index: number): ServiceRegistryInstance {
  const serviceName = asText(
    raw.serviceName ?? raw.service_name ?? raw.name ?? raw.service,
    `service-${index + 1}`,
  );

  return {
    serviceName,
    instanceId: asText(raw.instanceId ?? raw.instance_id, `${serviceName}-instance-1`),
    status: normalizeStatus(raw.status),
    endpoint: asText(raw.endpoint ?? raw.url, '-'),
    node: asText(raw.node, 'local-node'),
    version: asText(raw.version, 'unknown'),
    lastHeartbeatAt: asText(raw.lastHeartbeatAt ?? raw.last_heartbeat_at, '-'),
    tenantVisibility: asText(raw.tenantVisibility ?? raw.tenant_visibility, 'platform'),
  };
}

function normalizeRecordPayload(payload: Record<string, unknown>): ServiceRegistryInstance[] {
  return Object.entries(payload)
    .map(([serviceName, status]) => ({
      serviceName,
      instanceId: `${serviceName}-instance-1`,
      status: normalizeStatus(status),
      endpoint: '-',
      node: 'local-node',
      version: 'unknown',
      lastHeartbeatAt: '-',
      tenantVisibility: 'platform',
    }))
    .sort((a, b) => a.serviceName.localeCompare(b.serviceName));
}

export function normalizeServiceRegistryPayload(payload: unknown): ServiceRegistryInstance[] {
  if (Array.isArray(payload)) {
    return payload
      .map((item, index) => normalizeServiceObject((item ?? {}) as RawServiceObject, index))
      .sort((a, b) => a.serviceName.localeCompare(b.serviceName));
  }

  if (payload && typeof payload === 'object') {
    const obj = payload as Record<string, unknown>;

    if (Array.isArray(obj.services)) {
      return obj.services
        .map((item, index) => normalizeServiceObject((item ?? {}) as RawServiceObject, index))
        .sort((a, b) => a.serviceName.localeCompare(b.serviceName));
    }

    if (obj.services && typeof obj.services === 'object') {
      return normalizeRecordPayload(obj.services as Record<string, unknown>);
    }

    return normalizeRecordPayload(obj);
  }

  return [];
}

function buildServiceRegistryURL(): string {
  const config = getRuntimeConfig();
  const apiBaseUrl = config.apiBaseUrl.trim().replace(/\/$/, '');

  if (apiBaseUrl === '') {
    return '/api/services';
  }

  return `${apiBaseUrl}/api/services`;
}

export async function fetchServiceRegistry(
  options: FetchServiceRegistryOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<ServiceRegistryInstance[]> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers: Record<string, string> = {
    Accept: 'application/json',
  };

  if (options.accessToken) {
    headers.Authorization = `Bearer ${options.accessToken}`;
  }

  if (options.tenantId) {
    headers['X-Tenant-ID'] = options.tenantId;
  }

  const response = await fetcher(buildServiceRegistryURL(), {
    headers,
  });

  if (!response.ok) {
    throw new Error(`service registry okunamadi: ${response.status}`);
  }

  const payload = await response.json();
  return normalizeServiceRegistryPayload(payload);
}
