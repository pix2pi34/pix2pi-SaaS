import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { RuntimeTopologyPage } from './RuntimeTopologyPage';
import {
  normalizeRuntimeTopologyEdges,
  normalizeRuntimeTopologyNodes,
  normalizeRuntimeTopologyRegistry,
  normalizeRuntimeTopologySummary,
} from './runtime-topology-api';

function setAuthenticatedSession() {
  useAuthStore.setState({
    status: 'authenticated',
    error: null,
    session: {
      accessToken: 'test-access-token',
      expiresAt: new Date(Date.now() + 1000 * 60 * 60).toISOString(),
      user: {
        id: 'u1',
        fullName: 'Demo Kullanici',
        email: 'demo@pix2pi.local',
        isSuperAdmin: false,
      },
      activeTenant: { id: 'tenant-1', name: 'Merkez Tenant', slug: 'merkez-tenant' },
      tenants: [
        { id: 'tenant-1', name: 'Merkez Tenant', slug: 'merkez-tenant' },
      ],
      roles: [
        { code: 'TENANT_ADMIN', label: 'Tenant Admin' },
      ],
    },
  });
}

function renderWithQueryClient() {
  const client = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  return render(
    <QueryClientProvider client={client}>
      <RuntimeTopologyPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/runtime-topology/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'runtime-topology',
          db: 'ok',
          port: '5960',
        }),
      } as Response;
    }

    if (url.includes('/runtime-topology/api/runtime-topology/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              topology_status: 'ok',
              node_count: 15,
              node_ok_count: 15,
              node_fail_count: 0,
              edge_count: 18,
              registry_service_count: 0,
              registry_instance_count: 0,
              registry_heartbeat_count: 0,
              generated_at: '2026-04-25T00:20:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/runtime-topology/api/runtime-topology/nodes')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              node_key: 'nginx_https',
              display: 'Nginx HTTPS',
              node_type: 'edge',
              layer: 'edge',
              check_mode: 'tcp',
              port: '443',
              url: '',
              address: '127.0.0.1:443',
              status: 'ok',
              http_status: 0,
              latency_ms: 0,
              message: 'tcp listen active',
              checked_at: '2026-04-25T00:20:00Z',
            },
            {
              node_key: 'control_panel',
              display: 'Control Panel',
              node_type: 'app',
              layer: 'console',
              check_mode: 'http',
              port: '7100',
              url: 'http://127.0.0.1:7100/health',
              address: '',
              status: 'ok',
              http_status: 200,
              latency_ms: 7,
              message: 'service healthy',
              checked_at: '2026-04-25T00:20:00Z',
            },
            {
              node_key: 'runtime_topology',
              display: 'Runtime Topology',
              node_type: 'runtime',
              layer: 'observability',
              check_mode: 'http',
              port: '5960',
              url: 'http://127.0.0.1:5960/health',
              address: '',
              status: 'ok',
              http_status: 200,
              latency_ms: 1,
              message: 'service healthy',
              checked_at: '2026-04-25T00:20:00Z',
            },
            {
              node_key: 'postgres_db',
              display: 'PostgreSQL DB',
              node_type: 'database',
              layer: 'data',
              check_mode: 'sql',
              port: '',
              url: '',
              address: '',
              status: 'ok',
              http_status: 0,
              latency_ms: 0,
              message: 'database healthy',
              checked_at: '2026-04-25T00:20:00Z',
            },
          ],
          limit: 100,
        }),
      } as Response;
    }

    if (url.includes('/runtime-topology/api/runtime-topology/edges')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              from_node: 'nginx_https',
              to_node: 'control_panel',
              relation: 'serves',
              protocol: 'https',
            },
            {
              from_node: 'control_panel',
              to_node: 'runtime_topology',
              relation: 'proxies',
              protocol: 'http',
            },
            {
              from_node: 'runtime_topology',
              to_node: 'postgres_db',
              relation: 'reads topology',
              protocol: 'sql',
            },
          ],
        }),
      } as Response;
    }

    return {
      ok: true,
      json: async () => ({
        items: [
          {
            table_name: 'runtime.service_registry_services',
            count: 0,
            generated_at: '2026-04-25T00:20:00Z',
          },
          {
            table_name: 'runtime.service_registry_instances',
            count: 0,
            generated_at: '2026-04-25T00:20:00Z',
          },
          {
            table_name: 'runtime.service_registry_heartbeats',
            count: 0,
            generated_at: '2026-04-25T00:20:00Z',
          },
        ],
      }),
    } as Response;
  });
}

beforeEach(() => {
  setAuthenticatedSession();
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  useAuthStore.setState({ status: 'idle', session: null, error: null });
});

describe('runtime-topology-page', () => {
  it('normalizes runtime topology payloads', () => {
    expect(normalizeRuntimeTopologySummary({ items: [{ topology_status: 'ok', node_ok_count: 15 }] })[0].nodeOKCount).toBe(15);
    expect(normalizeRuntimeTopologyNodes({ items: [{ node_key: 'control_panel', http_status: 200 }] })[0].nodeKey).toBe('control_panel');
    expect(normalizeRuntimeTopologyEdges({ items: [{ from_node: 'a', to_node: 'b', relation: 'proxies' }] })[0].relation).toBe('proxies');
    expect(normalizeRuntimeTopologyRegistry({ items: [{ table_name: 'runtime.service_registry_services', count: 0 }] })[0].tableName).toBe('runtime.service_registry_services');
  });

  it('renders runtime topology dashboard and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Runtime Health / Topology yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Runtime Health / Topology View')).toBeInTheDocument();
    });

    expect(screen.getByText('Topology OK')).toBeInTheDocument();
    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('Node 15')).toBeInTheDocument();
    expect(screen.getByText('OK 15')).toBeInTheDocument();
    expect(screen.getByText('FAIL 0')).toBeInTheDocument();
    expect(screen.getByText('Edge 18')).toBeInTheDocument();

    expect(screen.getAllByText('Nginx HTTPS').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Control Panel').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Runtime Topology').length).toBeGreaterThan(0);
    expect(screen.getAllByText('PostgreSQL DB').length).toBeGreaterThan(0);
    expect(screen.getByText('runtime.service_registry_services')).toBeInTheDocument();
    expect(screen.getByText('runtime.service_registry_instances')).toBeInTheDocument();
    expect(screen.getByText('runtime.service_registry_heartbeats')).toBeInTheDocument();
    expect(screen.getByText('reads topology')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters runtime topology rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getAllByText('Control Panel').length).toBeGreaterThan(0);
    });

    await user.type(screen.getByLabelText('Runtime topology ara'), 'postgres');

    expect(screen.queryByText('Control Panel')).not.toBeInTheDocument();
    expect(screen.getAllByText('PostgreSQL DB').length).toBeGreaterThan(0);
    expect(screen.getAllByText('postgres_db').length).toBeGreaterThan(0);
  });

  it('renders error state when runtime topology fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Runtime Health / Topology okunamadi')).toBeInTheDocument();
    });
  });
});
