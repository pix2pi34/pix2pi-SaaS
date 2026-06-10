import type {
  RuntimeTopologyEdge,
  RuntimeTopologyHealth,
  RuntimeTopologyNode,
  RuntimeTopologyOverview,
  RuntimeTopologyRegistryItem,
  RuntimeTopologySummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type RuntimeTopologyFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: RuntimeTopologyFetchOptions): Record<string, string> {
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

function normalizeSummaryItem(raw: Record<string, unknown>): RuntimeTopologySummaryItem {
  return {
    topologyStatus: asText(raw.topology_status ?? raw.topologyStatus, 'unknown'),
    nodeCount: asNumber(raw.node_count ?? raw.nodeCount),
    nodeOKCount: asNumber(raw.node_ok_count ?? raw.nodeOKCount),
    nodeFailCount: asNumber(raw.node_fail_count ?? raw.nodeFailCount),
    edgeCount: asNumber(raw.edge_count ?? raw.edgeCount),
    registryServiceCount: asNumber(raw.registry_service_count ?? raw.registryServiceCount),
    registryInstanceCount: asNumber(raw.registry_instance_count ?? raw.registryInstanceCount),
    registryHeartbeatCount: asNumber(raw.registry_heartbeat_count ?? raw.registryHeartbeatCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeNode(raw: Record<string, unknown>): RuntimeTopologyNode {
  return {
    nodeKey: asText(raw.node_key ?? raw.nodeKey, '-'),
    display: asText(raw.display, '-'),
    nodeType: asText(raw.node_type ?? raw.nodeType, '-'),
    layer: asText(raw.layer, '-'),
    checkMode: asText(raw.check_mode ?? raw.checkMode, '-'),
    port: asText(raw.port, ''),
    url: asText(raw.url, ''),
    address: asText(raw.address, ''),
    status: asText(raw.status, '-'),
    httpStatus: asNumber(raw.http_status ?? raw.httpStatus),
    latencyMs: asNumber(raw.latency_ms ?? raw.latencyMs),
    message: asText(raw.message, '-'),
    checkedAt: asText(raw.checked_at ?? raw.checkedAt, '-'),
  };
}

function normalizeEdge(raw: Record<string, unknown>): RuntimeTopologyEdge {
  return {
    fromNode: asText(raw.from_node ?? raw.fromNode, '-'),
    toNode: asText(raw.to_node ?? raw.toNode, '-'),
    relation: asText(raw.relation, '-'),
    protocol: asText(raw.protocol, '-'),
  };
}

function normalizeRegistryItem(raw: Record<string, unknown>): RuntimeTopologyRegistryItem {
  return {
    tableName: asText(raw.table_name ?? raw.tableName, '-'),
    count: asNumber(raw.count),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

export function normalizeRuntimeTopologySummary(payload: unknown): RuntimeTopologySummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeRuntimeTopologyNodes(payload: unknown): RuntimeTopologyNode[] {
  return listFromPayload(payload).map(normalizeNode);
}

export function normalizeRuntimeTopologyEdges(payload: unknown): RuntimeTopologyEdge[] {
  return listFromPayload(payload).map(normalizeEdge);
}

export function normalizeRuntimeTopologyRegistry(payload: unknown): RuntimeTopologyRegistryItem[] {
  return listFromPayload(payload).map(normalizeRegistryItem);
}

export async function fetchRuntimeTopologyOverview(
  options: RuntimeTopologyFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<RuntimeTopologyOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, nodesResponse, edgesResponse, registryResponse] =
    await Promise.all([
      fetcher('/runtime-topology/health', { headers }),
      fetcher('/runtime-topology/api/runtime-topology/summary', { headers }),
      fetcher('/runtime-topology/api/runtime-topology/nodes?limit=100', { headers }),
      fetcher('/runtime-topology/api/runtime-topology/edges', { headers }),
      fetcher('/runtime-topology/api/runtime-topology/registry', { headers }),
    ]);

  if (!healthResponse.ok) {
    throw new Error(`runtime topology health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`runtime topology summary okunamadi: ${summaryResponse.status}`);
  }

  if (!nodesResponse.ok) {
    throw new Error(`runtime topology nodes okunamadi: ${nodesResponse.status}`);
  }

  if (!edgesResponse.ok) {
    throw new Error(`runtime topology edges okunamadi: ${edgesResponse.status}`);
  }

  if (!registryResponse.ok) {
    throw new Error(`runtime topology registry okunamadi: ${registryResponse.status}`);
  }

  const health = await healthResponse.json() as RuntimeTopologyHealth;
  const summaryPayload = await summaryResponse.json();
  const nodesPayload = await nodesResponse.json();
  const edgesPayload = await edgesResponse.json();
  const registryPayload = await registryResponse.json();

  return {
    health,
    summary: normalizeRuntimeTopologySummary(summaryPayload),
    nodes: normalizeRuntimeTopologyNodes(nodesPayload),
    edges: normalizeRuntimeTopologyEdges(edgesPayload),
    registry: normalizeRuntimeTopologyRegistry(registryPayload),
  };
}
