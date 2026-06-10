import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { PublicAPIMonitorPage } from './PublicAPIMonitorPage';
import {
  normalizeAPIKeys,
  normalizePublicAPISummary,
  normalizeQuotaPolicies,
  normalizeUsage,
} from './publicapi-monitor-api';

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
      <PublicAPIMonitorPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/publicapi-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'publicapi-runtime',
          db: 'ok',
          port: '5920',
        }),
      } as Response;
    }

    if (url.includes('/publicapi-runtime/api/publicapi/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              status: 'active',
              count: 1,
              key_count: 1,
              policy_count: 1,
              usage_count: 1,
              request_count: 120,
              rejected_count: 3,
              generated_at: '2026-04-24T12:20:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/publicapi-runtime/api/publicapi/api-keys')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              key_ref: 'dev-app-key-1',
              display_name: 'Developer App Key',
              visibility_scope: 'tenant',
              key_prefix: 'pxp_live',
              status: 'active',
              last_used_at: '2026-04-24T12:15:00Z',
              expires_at: '2026-12-31T23:59:59Z',
              revoked_at: '',
              created_at: '2026-04-24T12:00:00Z',
              updated_at: '2026-04-24T12:15:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/publicapi-runtime/api/publicapi/quota-policies')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              policy_key: 'hourly-quota',
              key_ref: 'dev-app-key-1',
              endpoint_scope: '/api/v1/orders',
              quota_period: 'hour',
              request_limit: 1000,
              burst_limit: 100,
              is_enabled: true,
              created_at: '2026-04-24T12:00:00Z',
              updated_at: '2026-04-24T12:15:00Z',
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
            usage_id: 'usage-1',
            key_ref: 'dev-app-key-1',
            policy_key: 'hourly-quota',
            usage_window_start: '2026-04-24T12:00:00Z',
            usage_window_end: '2026-04-24T13:00:00Z',
            request_count: 120,
            rejected_count: 3,
            last_request_at: '2026-04-24T12:15:00Z',
            created_at: '2026-04-24T12:00:00Z',
            updated_at: '2026-04-24T12:15:00Z',
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

describe('publicapi-monitor-page', () => {
  it('normalizes public api runtime payloads', () => {
    expect(normalizePublicAPISummary({ items: [{ status: 'empty', count: 0 }] })[0].status).toBe('empty');
    expect(normalizeAPIKeys({ items: [{ key_ref: 'dev-app-key-1', status: 'active' }] })[0].keyRef).toBe('dev-app-key-1');
    expect(normalizeQuotaPolicies({ items: [{ policy_key: 'hourly-quota', is_enabled: true }] })[0].policyKey).toBe('hourly-quota');
    expect(normalizeUsage({ items: [{ usage_id: 'usage-1', request_count: 120 }] })[0].requestCount).toBe(120);
  });

  it('renders public api monitor overview and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Public API Monitor yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Public API Monitor')).toBeInTheDocument();
    });

    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('API Key 1')).toBeInTheDocument();
    expect(screen.getByText('Policy 1')).toBeInTheDocument();
    expect(screen.getByText('Usage 1')).toBeInTheDocument();
    expect(screen.getByText('Request 120')).toBeInTheDocument();
    expect(screen.getByText('Rejected 3')).toBeInTheDocument();

    expect(screen.getAllByText('dev-app-key-1').length).toBeGreaterThan(0);
    expect(screen.getByText('Developer App Key')).toBeInTheDocument();
    expect(screen.getAllByText('hourly-quota').length).toBeGreaterThan(0);
    expect(screen.getByText('/api/v1/orders')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters public api rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Developer App Key')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Public API ara'), 'hourly');

    expect(screen.queryByText('Developer App Key')).not.toBeInTheDocument();
    expect(screen.getAllByText('hourly-quota').length).toBeGreaterThan(0);
  });

  it('renders error state when public api runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Public API Monitor okunamadi')).toBeInTheDocument();
    });
  });
});
