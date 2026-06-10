import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { EarlyWarningPage } from './EarlyWarningPage';
import {
  normalizeEarlyWarningIncidents,
  normalizeEarlyWarningResources,
  normalizeEarlyWarningServices,
  normalizeEarlyWarningSignals,
  normalizeEarlyWarningSummary,
} from './early-warning-api';

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
      <EarlyWarningPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/early-warning-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'early-warning-runtime',
          db: 'ok',
          port: '5940',
        }),
      } as Response;
    }

    if (url.includes('/early-warning-runtime/api/early-warning/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              alert_level: 'ok',
              service_count: 10,
              service_ok_count: 10,
              service_fail_count: 0,
              resource_count: 3,
              signal_count: 15,
              warning_count: 0,
              critical_count: 0,
              incident_count: 0,
              generated_at: '2026-04-24T20:30:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/early-warning-runtime/api/early-warning/services')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              service_key: 'panel',
              display: 'Control Panel',
              status: 'ok',
              http_status: 200,
              latency_ms: 5,
              message: 'service healthy',
              checked_at: '2026-04-24T20:30:00Z',
            },
            {
              service_key: 'api_gateway',
              display: 'API Gateway',
              status: 'ok',
              http_status: 200,
              latency_ms: 1,
              message: 'service healthy',
              checked_at: '2026-04-24T20:30:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/early-warning-runtime/api/early-warning/resources')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              resource_key: 'disk_root',
              display: 'Root Disk',
              value: 90.88,
              unit: 'GiB used',
              used_percent: 46.9,
              level: 'ok',
              message: 'disk kullanimi 46.9%',
              checked_at: '2026-04-24T20:30:00Z',
            },
            {
              resource_key: 'memory',
              display: 'Memory',
              value: 2.29,
              unit: 'GiB used',
              used_percent: 14.7,
              level: 'ok',
              message: 'memory kullanimi 14.7%',
              checked_at: '2026-04-24T20:30:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/early-warning-runtime/api/early-warning/signals')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              signal_key: 'service_panel',
              category: 'service',
              level: 'ok',
              status: 'ok',
              message: 'Control Panel => service healthy',
              generated_at: '2026-04-24T20:30:00Z',
            },
            {
              signal_key: 'resource_disk_root',
              category: 'resource',
              level: 'ok',
              status: 'ok',
              message: 'disk kullanimi 46.9%',
              generated_at: '2026-04-24T20:30:00Z',
            },
            {
              signal_key: 'database',
              category: 'database',
              level: 'ok',
              status: 'ok',
              message: 'database healthy',
              generated_at: '2026-04-24T20:30:00Z',
            },
          ],
          limit: 100,
        }),
      } as Response;
    }

    return {
      ok: true,
      json: async () => ({
        items: [
          {
            table_name: 'runtime.mission_control_incidents',
            count: 0,
            generated_at: '2026-04-24T20:30:00Z',
          },
          {
            table_name: 'public.audit_logs',
            count: 23,
            generated_at: '2026-04-24T20:30:00Z',
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

describe('early-warning-page', () => {
  it('normalizes early warning runtime payloads', () => {
    expect(normalizeEarlyWarningSummary({ items: [{ alert_level: 'ok', service_ok_count: 10 }] })[0].alertLevel).toBe('ok');
    expect(normalizeEarlyWarningServices({ items: [{ service_key: 'panel', http_status: 200 }] })[0].serviceKey).toBe('panel');
    expect(normalizeEarlyWarningResources({ items: [{ resource_key: 'disk_root', used_percent: 46.9 }] })[0].usedPercent).toBe(46.9);
    expect(normalizeEarlyWarningSignals({ items: [{ signal_key: 'database', level: 'ok' }] })[0].signalKey).toBe('database');
    expect(normalizeEarlyWarningIncidents({ items: [{ table_name: 'public.audit_logs', count: 23 }] })[0].count).toBe(23);
  });

  it('renders early warning dashboard and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Early Warning Dashboard yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Early Warning / Alert Dashboard')).toBeInTheDocument();
    });

    expect(screen.getByText('Alert OK')).toBeInTheDocument();
    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('Service OK 10')).toBeInTheDocument();
    expect(screen.getByText('Service FAIL 0')).toBeInTheDocument();
    expect(screen.getByText('Warning 0')).toBeInTheDocument();
    expect(screen.getByText('Critical 0')).toBeInTheDocument();
    expect(screen.getByText('Incident 0')).toBeInTheDocument();

    expect(screen.getAllByText('Control Panel').length).toBeGreaterThan(0);
    expect(screen.getByText('API Gateway')).toBeInTheDocument();
    expect(screen.getByText('Root Disk')).toBeInTheDocument();
    expect(screen.getByText('Memory')).toBeInTheDocument();
    expect(screen.getAllByText('database').length).toBeGreaterThan(0);
    expect(screen.getByText('runtime.mission_control_incidents')).toBeInTheDocument();
    expect(screen.getByText('public.audit_logs')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters early warning rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Root Disk')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Early warning ara'), 'disk');

    expect(screen.queryByText('API Gateway')).not.toBeInTheDocument();
    expect(screen.getByText('Root Disk')).toBeInTheDocument();
    expect(screen.getByText('resource_disk_root')).toBeInTheDocument();
  });

  it('renders error state when early warning runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Early Warning Dashboard okunamadi')).toBeInTheDocument();
    });
  });
});
