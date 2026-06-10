import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { PluginMonitorPage } from './PluginMonitorPage';
import {
  normalizePluginCatalog,
  normalizePluginStates,
  normalizePluginSummary,
} from './plugin-monitor-api';

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
      <PluginMonitorPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/plugin-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'plugin-runtime',
          db: 'ok',
          port: '5910',
        }),
      } as Response;
    }

    if (url.includes('/plugin-runtime/api/plugins/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              status: 'published',
              count: 1,
              plugin_count: 1,
              state_count: 1,
              generated_at: '2026-04-24T12:00:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/plugin-runtime/api/plugins/catalog')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              plugin_key: 'erp-export-logo',
              display_name: 'Logo ERP Export',
              version_no: '1.0.0',
              visibility_scope: 'tenant',
              source_type: 'internal',
              lifecycle_status: 'published',
              entrypoint_ref: 'plugin-erp',
              checksum: 'sha256-demo',
              required_platform_version: '8.6.0',
              is_enabled: true,
              published_at: '2026-04-24T12:00:00Z',
              deprecated_at: '',
              archived_at: '',
              created_at: '2026-04-24T11:50:00Z',
              updated_at: '2026-04-24T12:00:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/plugin-runtime/api/plugins/runtime')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              state_id: 'state-runtime-1',
              plugin_key: 'erp-export-logo',
              state_key: 'runtime-logo-export',
              desired_state: 'activated',
              current_state: 'active',
              install_ref: 'install-1',
              installed_at: '2026-04-24T12:01:00Z',
              activated_at: '2026-04-24T12:02:00Z',
              deactivated_at: '',
              last_health_at: '2026-04-24T12:03:00Z',
              last_error: '',
              created_at: '2026-04-24T12:01:00Z',
              updated_at: '2026-04-24T12:03:00Z',
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
            state_id: 'state-1',
            plugin_key: 'erp-export-logo',
            state_key: 'tenant-logo-export',
            desired_state: 'activated',
            current_state: 'active',
            install_ref: 'install-1',
            installed_at: '2026-04-24T12:01:00Z',
            activated_at: '2026-04-24T12:02:00Z',
            deactivated_at: '',
            last_health_at: '2026-04-24T12:03:00Z',
            last_error: '',
            created_at: '2026-04-24T12:01:00Z',
            updated_at: '2026-04-24T12:03:00Z',
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

describe('plugin-monitor-page', () => {
  it('normalizes plugin runtime payloads', () => {
    expect(normalizePluginSummary({ items: [{ status: 'empty', count: 0 }] })[0].status).toBe('empty');
    expect(normalizePluginCatalog({ items: [{ plugin_key: 'erp-export-logo', is_enabled: true }] })[0].pluginKey).toBe('erp-export-logo');
    expect(normalizePluginStates({ items: [{ state_id: 'state-1', state_key: 'tenant-logo-export' }] })[0].stateKey).toBe('tenant-logo-export');
  });

  it('renders plugin monitor overview and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Plugin Monitor yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Plugin Monitor')).toBeInTheDocument();
    });

    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('Plugin 1')).toBeInTheDocument();
    expect(screen.getByText('State 1')).toBeInTheDocument();
    expect(screen.getByText('Status Toplam 1')).toBeInTheDocument();

    expect(screen.getAllByText('erp-export-logo').length).toBeGreaterThan(0);
    expect(screen.getByText('tenant-logo-export')).toBeInTheDocument();
    expect(screen.getByText('runtime-logo-export')).toBeInTheDocument();
    expect(screen.getByText('8.6.0')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters plugin rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('tenant-logo-export')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Plugin ara'), 'runtime');

    expect(screen.queryByText('tenant-logo-export')).not.toBeInTheDocument();
    expect(screen.getByText('runtime-logo-export')).toBeInTheDocument();
  });

  it('renders error state when plugin runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Plugin Monitor okunamadi')).toBeInTheDocument();
    });
  });
});
