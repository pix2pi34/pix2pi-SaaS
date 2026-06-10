import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { RealtimeMonitorPage } from './RealtimeMonitorPage';
import {
  normalizeRealtimeRows,
  normalizeRealtimeSummary,
  normalizeRealtimeTables,
} from './realtime-api';

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
      <RealtimeMonitorPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/realtime-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'realtime-runtime',
          db: 'ok',
          port: '5970',
        }),
      } as Response;
    }

    if (url.includes('/realtime-runtime/api/realtime/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              status: 'ok',
              channel_count: 1,
              connection_count: 1,
              active_connection_count: 1,
              websocket_count: 1,
              sse_count: 0,
              presence_count: 1,
              online_presence_count: 1,
              channel_permission_count: 1,
              generated_at: '2026-04-25T01:00:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/realtime-runtime/api/realtime/tables')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              table_name: 'runtime.notification_channels',
              exists: true,
              count: 1,
              generated_at: '2026-04-25T01:00:00Z',
            },
            {
              table_name: 'runtime.realtime_connections',
              exists: true,
              count: 1,
              generated_at: '2026-04-25T01:00:00Z',
            },
            {
              table_name: 'runtime.realtime_presence',
              exists: true,
              count: 1,
              generated_at: '2026-04-25T01:00:00Z',
            },
            {
              table_name: 'runtime.realtime_channel_permissions',
              exists: true,
              count: 1,
              generated_at: '2026-04-25T01:00:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/realtime-runtime/api/realtime/channels')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              table_name: 'runtime.notification_channels',
              record_json: '{"channel_key":"tenant.events","display_name":"Tenant Events","channel_type":"sse","is_enabled":true}',
              observed_at: '2026-04-25T01:00:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/realtime-runtime/api/realtime/connections')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              table_name: 'runtime.realtime_connections',
              record_json: '{"connection_id":"conn-ws-001","protocol":"websocket","channel_name":"tenant.events","connection_status":"connected"}',
              observed_at: '2026-04-25T01:00:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/realtime-runtime/api/realtime/presence')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              table_name: 'runtime.realtime_presence',
              record_json: '{"connection_id":"conn-ws-001","presence_status":"online","server_node":"node-a"}',
              observed_at: '2026-04-25T01:00:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    return {
      ok: true,
      json: async () => ({
        items: [
          {
            table_name: 'runtime.realtime_channel_permissions',
            record_json: '{"channel_name":"tenant.events","operation":"subscribe","decision":"granted"}',
            observed_at: '2026-04-25T01:00:00Z',
          },
        ],
        limit: 50,
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

describe('realtime-monitor-page', () => {
  it('normalizes realtime runtime payloads', () => {
    expect(normalizeRealtimeSummary({ items: [{ status: 'ok', connection_count: 3 }] })[0].connectionCount).toBe(3);
    expect(normalizeRealtimeTables({ items: [{ table_name: 'runtime.realtime_connections', exists: true }] })[0].exists).toBe(true);
    expect(normalizeRealtimeRows({ items: [{ table_name: 'runtime.realtime_presence', record_json: '{"presence_status":"online"}' }] })[0].recordJSON).toContain('online');
  });

  it('renders realtime monitor and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Realtime / Channel Monitor yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Realtime / Channel Monitor')).toBeInTheDocument();
    });

    expect(screen.getByText('Status OK')).toBeInTheDocument();
    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('Channels 1')).toBeInTheDocument();
    expect(screen.getByText('Connections 1')).toBeInTheDocument();
    expect(screen.getByText('Active 1')).toBeInTheDocument();
    expect(screen.getByText('WS 1')).toBeInTheDocument();
    expect(screen.getByText('SSE 0')).toBeInTheDocument();
    expect(screen.getByText('Presence 1')).toBeInTheDocument();
    expect(screen.getByText('Permissions 1')).toBeInTheDocument();

    expect(screen.getAllByText('runtime.notification_channels').length).toBeGreaterThan(0);
    expect(screen.getAllByText('runtime.realtime_connections').length).toBeGreaterThan(0);
    expect(screen.getAllByText('runtime.realtime_presence').length).toBeGreaterThan(0);
    expect(screen.getAllByText('runtime.realtime_channel_permissions').length).toBeGreaterThan(0);

    expect(screen.getAllByText(/tenant\.events/).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/conn-ws-001/).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/presence_status/).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/decision/).length).toBeGreaterThan(0);

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters realtime monitor rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getAllByText('runtime.notification_channels').length).toBeGreaterThan(0);
    });

    await user.type(screen.getByLabelText('Realtime monitor ara'), 'presence');

    expect(screen.queryByText('runtime.notification_channels')).not.toBeInTheDocument();
    expect(screen.getAllByText('runtime.realtime_presence').length).toBeGreaterThan(0);
    expect(screen.getAllByText(/presence_status/).length).toBeGreaterThan(0);
  });

  it('renders error state when realtime runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Realtime / Channel Monitor okunamadi')).toBeInTheDocument();
    });
  });
});
