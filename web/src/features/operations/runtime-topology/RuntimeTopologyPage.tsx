import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchRuntimeTopologyOverview } from './runtime-topology-api';
import type {
  RuntimeTopologyEdge,
  RuntimeTopologyNode,
  RuntimeTopologyRegistryItem,
} from './types';

function levelClassName(level: string): string {
  const normalized = level.toLowerCase();

  if (['ok', 'healthy', 'active'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['fail', 'failed', 'down', 'critical', 'degraded'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['warning', 'unknown'].includes(normalized)) {
    return 'status-pill status-pill--degraded';
  }

  return 'status-pill status-pill--unknown';
}

function includesAny(values: string[], query: string): boolean {
  const trimmed = query.trim().toLowerCase();

  if (!trimmed) {
    return true;
  }

  return values.some((value) => value.toLowerCase().includes(trimmed));
}

function filterNodes(rows: RuntimeTopologyNode[], query: string): RuntimeTopologyNode[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.nodeKey,
        row.display,
        row.nodeType,
        row.layer,
        row.checkMode,
        row.port,
        row.status,
        row.message,
        row.url,
        row.address,
      ],
      query,
    ),
  );
}

function filterEdges(rows: RuntimeTopologyEdge[], query: string): RuntimeTopologyEdge[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.fromNode,
        row.toNode,
        row.relation,
        row.protocol,
      ],
      query,
    ),
  );
}

function filterRegistry(rows: RuntimeTopologyRegistryItem[], query: string): RuntimeTopologyRegistryItem[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.tableName,
        String(row.count),
      ],
      query,
    ),
  );
}

function groupNodesByLayer(nodes: RuntimeTopologyNode[]): Record<string, RuntimeTopologyNode[]> {
  return nodes.reduce<Record<string, RuntimeTopologyNode[]>>((acc, node) => {
    const layer = node.layer || 'unknown';
    acc[layer] = acc[layer] ?? [];
    acc[layer].push(node);
    return acc;
  }, {});
}

function endpointText(node: RuntimeTopologyNode): string {
  if (node.url) {
    return node.url;
  }

  if (node.address) {
    return node.address;
  }

  if (node.port) {
    return `:${node.port}`;
  }

  return '-';
}

export function RuntimeTopologyPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const runtimeTopologyQuery = useQuery({
    queryKey: ['operations', 'runtime-topology', tenantId],
    queryFn: () => fetchRuntimeTopologyOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = runtimeTopologyQuery.data?.summary ?? [];
  const nodes = runtimeTopologyQuery.data?.nodes ?? [];
  const edges = runtimeTopologyQuery.data?.edges ?? [];
  const registry = runtimeTopologyQuery.data?.registry ?? [];

  const mainSummary = summary[0];

  const filteredNodes = useMemo(() => filterNodes(nodes, query), [nodes, query]);
  const filteredEdges = useMemo(() => filterEdges(edges, query), [edges, query]);
  const filteredRegistry = useMemo(() => filterRegistry(registry, query), [registry, query]);

  const groupedNodes = useMemo(() => groupNodesByLayer(filteredNodes), [filteredNodes]);
  const layerNames = useMemo(() => Object.keys(groupedNodes).sort(), [groupedNodes]);

  if (runtimeTopologyQuery.isLoading || runtimeTopologyQuery.isPending) {
    return <LoadingState message="Runtime Health / Topology yukleniyor..." />;
  }

  if (runtimeTopologyQuery.isError) {
    return (
      <ErrorState
        title="Runtime Health / Topology okunamadi"
        description="Runtime Topology servisi, 5960 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void runtimeTopologyQuery.refetch()}
      />
    );
  }

  if (!runtimeTopologyQuery.data || !mainSummary) {
    return (
      <EmptyState
        title="Runtime topology verisi bulunamadi"
        description="Runtime Topology endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Runtime Health / Topology View</strong>
            <p className="small">
              Nginx, panel, runtime servisleri ve PostgreSQL baglantisini tek topology ekraninda izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void runtimeTopologyQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className={levelClassName(mainSummary.topologyStatus)}>
            Topology {mainSummary.topologyStatus.toUpperCase()}
          </span>
          <span className="badge">Runtime {runtimeTopologyQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {runtimeTopologyQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Node {mainSummary.nodeCount}</span>
          <span className="badge">OK {mainSummary.nodeOKCount}</span>
          <span className="badge">FAIL {mainSummary.nodeFailCount}</span>
          <span className="badge">Edge {mainSummary.edgeCount}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Service Registry tabloları bos olsa bile bu ekran canlı port, HTTP health ve DB ping uzerinden gerçek runtime haritasini cikarir.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Arama / Filtre</strong>
            <div className="small">Node, layer, port, relation, protocol veya registry tablosu ara.</div>
          </div>
          <input
            aria-label="Runtime topology ara"
            placeholder="nginx, panel, runtime, db, 5960, proxies..."
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Topology Map</strong>
            <div className="small">Layer bazli canlı node görünümü.</div>
          </div>
          <span className="badge">Gosterilen {filteredNodes.length} / {nodes.length}</span>
        </div>

        {filteredNodes.length === 0 ? (
          <EmptyState
            title="Node bulunamadi"
            description="Filtreye uyan runtime node yok."
          />
        ) : (
          <div className="page-grid">
            {layerNames.map((layer) => (
              <section className="card span-4" key={layer}>
                <div className="toolbar">
                  <strong>{layer}</strong>
                  <span className="badge">{groupedNodes[layer]?.length ?? 0} node</span>
                </div>

                <div className="button-row">
                  {groupedNodes[layer]?.map((node) => (
                    <span className={levelClassName(node.status)} key={node.nodeKey}>
                      {node.display}
                    </span>
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Runtime Nodes</strong>
            <div className="small">Kaynak: /runtime-topology/api/runtime-topology/nodes</div>
          </div>
          <span className="badge">Gosterilen {filteredNodes.length} / {nodes.length}</span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Node</th>
              <th>Layer</th>
              <th>Type</th>
              <th>Status</th>
              <th>Mode</th>
              <th>Port</th>
              <th>HTTP</th>
              <th>Latency</th>
              <th>Endpoint</th>
              <th>Checked</th>
            </tr>
          </thead>
          <tbody>
            {filteredNodes.map((node) => (
              <tr key={node.nodeKey}>
                <td>{node.display}</td>
                <td>{node.layer}</td>
                <td>{node.nodeType}</td>
                <td>
                  <span className={levelClassName(node.status)}>{node.status}</span>
                </td>
                <td>{node.checkMode}</td>
                <td>{node.port || '-'}</td>
                <td>{node.httpStatus || '-'}</td>
                <td>{node.latencyMs} ms</td>
                <td>{endpointText(node)}</td>
                <td>{node.checkedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Runtime Edges</strong>
            <div className="small">Kaynak: /runtime-topology/api/runtime-topology/edges</div>
          </div>
          <span className="badge">Gosterilen {filteredEdges.length} / {edges.length}</span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>From</th>
              <th>Relation</th>
              <th>To</th>
              <th>Protocol</th>
            </tr>
          </thead>
          <tbody>
            {filteredEdges.map((edge) => (
              <tr key={`${edge.fromNode}-${edge.relation}-${edge.toNode}`}>
                <td>{edge.fromNode}</td>
                <td>{edge.relation}</td>
                <td>{edge.toNode}</td>
                <td>{edge.protocol}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Service Registry Counts</strong>
            <div className="small">Kaynak: /runtime-topology/api/runtime-topology/registry</div>
          </div>
          <span className="badge">
            Services {mainSummary.registryServiceCount} · Instances {mainSummary.registryInstanceCount} · Heartbeats {mainSummary.registryHeartbeatCount}
          </span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Table</th>
              <th>Count</th>
              <th>Generated</th>
            </tr>
          </thead>
          <tbody>
            {filteredRegistry.map((item) => (
              <tr key={item.tableName}>
                <td>{item.tableName}</td>
                <td>{item.count}</td>
                <td>{item.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}
