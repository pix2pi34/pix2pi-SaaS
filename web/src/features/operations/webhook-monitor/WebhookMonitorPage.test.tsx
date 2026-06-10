import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { WebhookMonitorPage } from './WebhookMonitorPage';
import {
  normalizeWebhookDeliveries,
  normalizeWebhookEndpoints,
  normalizeWebhookSummary,
} from './webhook-monitor-api';

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
      <WebhookMonitorPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/webhook-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'webhook-runtime',
          db: 'ok',
          port: '5890',
        }),
      } as Response;
    }

    if (url.includes('/webhook-runtime/api/webhooks/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              status: 'queued',
              count: 2,
              endpoint_count: 1,
              attempt_count: 3,
              generated_at: '2026-04-24T11:00:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/webhook-runtime/api/webhooks/endpoints')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              endpoint_key: 'customer-sync',
              display_name: 'Customer Sync',
              visibility_scope: 'tenant',
              target_url: 'https://example.com/webhook',
              http_method: 'POST',
              auth_type: 'hmac',
              signature_header: 'X-Pix2pi-Signature',
              timeout_seconds: 10,
              retry_limit: 3,
              retry_backoff_seconds: 30,
              is_enabled: true,
              delivery_count: 2,
              failed_count: 1,
              dead_letter_count: 1,
              updated_at: '2026-04-24T11:00:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/webhook-runtime/api/webhooks/dlq')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              delivery_id: 'delivery-dlq-1',
              endpoint_key: 'customer-sync',
              delivery_key: 'customer-sync-dlq-1',
              event_type: 'customer.failed',
              priority: 'high',
              status: 'dead_letter',
              response_code: 500,
              retry_count: 3,
              max_attempts: 3,
              next_retry_at: '',
              delivered_at: '',
              dead_lettered_at: '2026-04-24T11:05:00Z',
              source_ref_type: 'event',
              source_ref_id: 'evt-dlq-1',
              last_error: 'remote server failed',
              created_at: '2026-04-24T11:00:00Z',
              updated_at: '2026-04-24T11:05:00Z',
            },
          ],
          limit: 25,
        }),
      } as Response;
    }

    return {
      ok: true,
      json: async () => ({
        items: [
          {
            delivery_id: 'delivery-1',
            endpoint_key: 'customer-sync',
            delivery_key: 'customer-sync-delivery-1',
            event_type: 'customer.created',
            priority: 'normal',
            status: 'queued',
            response_code: 0,
            retry_count: 0,
            max_attempts: 3,
            next_retry_at: '',
            delivered_at: '',
            dead_lettered_at: '',
            source_ref_type: 'event',
            source_ref_id: 'evt-1',
            last_error: '',
            created_at: '2026-04-24T11:00:00Z',
            updated_at: '2026-04-24T11:00:00Z',
          },
        ],
        limit: 25,
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

describe('webhook-monitor-page', () => {
  it('normalizes webhook runtime payloads', () => {
    expect(normalizeWebhookSummary({ items: [{ status: 'empty', count: 0 }] })[0].status).toBe('empty');
    expect(normalizeWebhookEndpoints({ items: [{ endpoint_key: 'customer-sync', is_enabled: true }] })[0].endpointKey).toBe('customer-sync');
    expect(normalizeWebhookDeliveries({ items: [{ delivery_id: 'delivery-1', delivery_key: 'demo' }] })[0].deliveryKey).toBe('demo');
  });

  it('renders webhook monitor overview and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Webhook Monitor yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Webhook Monitor')).toBeInTheDocument();
    });

    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getAllByText('customer-sync').length).toBeGreaterThan(0);
    expect(screen.getByText('customer-sync-delivery-1')).toBeInTheDocument();
    expect(screen.getByText('customer-sync-dlq-1')).toBeInTheDocument();
    expect(screen.getByText('DLQ 1')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters webhook endpoints and deliveries by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('customer-sync-delivery-1')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Webhook ara'), 'dlq');

    expect(screen.queryByText('customer-sync-delivery-1')).not.toBeInTheDocument();
    expect(screen.getByText('customer-sync-dlq-1')).toBeInTheDocument();
  });

  it('renders error state when webhook runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Webhook Monitor okunamadi')).toBeInTheDocument();
    });
  });
});
