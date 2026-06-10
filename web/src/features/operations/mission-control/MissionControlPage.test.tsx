import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { MissionControlPage } from './MissionControlPage';
import { normalizeMissionControlServices } from './mission-control-api';

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
      <MissionControlPage />
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

describe('mission-control-page', () => {
  it('normalizes mission services payload', () => {
    const rows = normalizeMissionControlServices({
      'mission-control': 'UP',
      'service-registry': 'DOWN',
    });

    expect(rows).toHaveLength(2);
    expect(rows[0].serviceName).toBe('mission-control');
    expect(rows[0].status).toBe('UP');
    expect(rows[1].status).toBe('DOWN');
  });

  it('renders mission control overview and sends auth headers', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
      const url = String(input);

      if (url.includes('/mission-control/health')) {
        return {
          ok: true,
          json: async () => ({ ok: true, service: 'mission-control' }),
        } as Response;
      }

      return {
        ok: true,
        json: async () => ({
          'mission-control': 'UP',
          'service-registry': 'UP',
        }),
      } as Response;
    });

    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Mission Control yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('mission-control')).toBeInTheDocument();
    });

    expect(screen.getAllByText('Calisiyor')).toHaveLength(2);
    expect(screen.getByText('Health OK')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters mission services by query', async () => {
    const user = userEvent.setup();

    vi.stubGlobal('fetch', vi.fn(async (input: RequestInfo | URL) => {
      const url = String(input);

      if (url.includes('/mission-control/health')) {
        return {
          ok: true,
          json: async () => ({ ok: true, service: 'mission-control' }),
        } as Response;
      }

      return {
        ok: true,
        json: async () => ({
          'mission-control': 'UP',
          'service-registry': 'UP',
        }),
      } as Response;
    }));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('mission-control')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Mission servis ara'), 'registry');

    expect(screen.queryByText('mission-control')).not.toBeInTheDocument();
    expect(screen.getByText('service-registry')).toBeInTheDocument();
  });

  it('renders error state when mission api fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Mission Control okunamadi')).toBeInTheDocument();
    });
  });
});
