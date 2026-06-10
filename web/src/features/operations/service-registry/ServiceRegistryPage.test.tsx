import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { ServiceRegistryPage } from './ServiceRegistryPage';
import { normalizeServiceRegistryPayload } from './service-registry-api';

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
      <ServiceRegistryPage />
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  setAuthenticatedSession();
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  useAuthStore.setState({ status: 'idle', session: null, error: null });
});

describe('service-registry-page', () => {
  it('normalizes simple service status payload', () => {
    const rows = normalizeServiceRegistryPayload({
      'mission-control': 'UP',
      'service-registry': 'DOWN',
    });

    expect(rows).toHaveLength(2);
    expect(rows[0].serviceName).toBe('mission-control');
    expect(rows[0].status).toBe('UP');
    expect(rows[1].status).toBe('DOWN');
  });

  it('renders service registry rows from API and sends auth headers', async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => ({
      ok: true,
      json: async () => ({
        services: [
          {
            serviceName: 'service-registry',
            status: 'UP',
            instanceId: 'registry-1',
            endpoint: 'http://localhost:9011',
            node: 'node-01',
            version: 'v1',
            lastHeartbeatAt: '2026-04-24T08:00:00Z',
            tenantVisibility: 'platform',
          },
        ],
      }),
    } as Response));

    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Service registry yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('service-registry')).toBeInTheDocument();
    });

    expect(screen.getByText('Calisiyor')).toBeInTheDocument();
    expect(screen.getByText('http://localhost:9011')).toBeInTheDocument();

    expect(fetchMock).toHaveBeenCalled();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters service rows by query', async () => {
    const user = userEvent.setup();

    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: true,
      json: async () => ({
        'mission-control': 'UP',
        'service-registry': 'UP',
      }),
    })));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('mission-control')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Servis ara'), 'registry');

    expect(screen.queryByText('mission-control')).not.toBeInTheDocument();
    expect(screen.getByText('service-registry')).toBeInTheDocument();
  });

  it('renders error state when API fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    })));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Service registry okunamadi')).toBeInTheDocument();
    });
  });
});
