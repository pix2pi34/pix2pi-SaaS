import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { NotificationMonitorPage } from './NotificationMonitorPage';
import {
  normalizeNotificationChannels,
  normalizeNotificationItems,
  normalizeNotificationRecipients,
  normalizeNotificationSummary,
} from './notification-monitor-api';

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
      <NotificationMonitorPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/notification-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'notification-runtime',
          db: 'ok',
          port: '5930',
        }),
      } as Response;
    }

    if (url.includes('/notification-runtime/api/notifications/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              status: 'queued',
              count: 1,
              channel_count: 1,
              notification_count: 1,
              recipient_count: 1,
              delivered_count: 1,
              failed_count: 1,
              generated_at: '2026-04-24T13:50:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/notification-runtime/api/notifications/channels')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              channel_key: 'email-main',
              display_name: 'Main Email Channel',
              channel_type: 'email',
              visibility_scope: 'tenant',
              provider_key: 'smtp-primary',
              is_enabled: true,
              created_at: '2026-04-24T13:30:00Z',
              updated_at: '2026-04-24T13:40:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/notification-runtime/api/notifications/items')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              notification_id: 'notification-1',
              channel_key: 'email-main',
              notification_key: 'invoice-created-1',
              notification_type: 'invoice.created',
              priority: 'normal',
              status: 'queued',
              title: 'Invoice Created',
              source_ref_type: 'invoice',
              source_ref_id: 'invoice-1',
              scheduled_at: '2026-04-24T13:45:00Z',
              sent_at: '',
              created_at: '2026-04-24T13:40:00Z',
              updated_at: '2026-04-24T13:45:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/notification-runtime/api/notifications/dlq')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              recipient_id: 'recipient-dlq-1',
              notification_key: 'invoice-created-1',
              recipient_type: 'email',
              recipient_key: 'customer-2',
              destination: 'failed@example.com',
              delivery_status: 'failed',
              error_message: 'smtp failed',
              delivered_at: '',
              created_at: '2026-04-24T13:45:00Z',
              updated_at: '2026-04-24T13:50:00Z',
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
            recipient_id: 'recipient-1',
            notification_key: 'invoice-created-1',
            recipient_type: 'email',
            recipient_key: 'customer-1',
            destination: 'customer@example.com',
            delivery_status: 'delivered',
            error_message: '',
            delivered_at: '2026-04-24T13:46:00Z',
            created_at: '2026-04-24T13:45:00Z',
            updated_at: '2026-04-24T13:46:00Z',
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

describe('notification-monitor-page', () => {
  it('normalizes notification runtime payloads', () => {
    expect(normalizeNotificationSummary({ items: [{ status: 'empty', count: 0 }] })[0].status).toBe('empty');
    expect(normalizeNotificationChannels({ items: [{ channel_key: 'email-main', is_enabled: true }] })[0].channelKey).toBe('email-main');
    expect(normalizeNotificationItems({ items: [{ notification_id: 'n1', notification_key: 'invoice-created-1' }] })[0].notificationKey).toBe('invoice-created-1');
    expect(normalizeNotificationRecipients({ items: [{ recipient_id: 'r1', recipient_key: 'customer-1' }] })[0].recipientKey).toBe('customer-1');
  });

  it('renders notification monitor overview and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Notification Monitor yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Notification Monitor')).toBeInTheDocument();
    });

    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('Channel 1')).toBeInTheDocument();
    expect(screen.getByText('Notification 1')).toBeInTheDocument();
    expect(screen.getByText('Recipient 1')).toBeInTheDocument();
    expect(screen.getByText('Delivered 1')).toBeInTheDocument();
    expect(screen.getByText('Failed 1')).toBeInTheDocument();
    expect(screen.getByText('DLQ 1')).toBeInTheDocument();

    expect(screen.getAllByText('email-main').length).toBeGreaterThan(0);
    expect(screen.getByText('Main Email Channel')).toBeInTheDocument();
    expect(screen.getAllByText('invoice-created-1').length).toBeGreaterThan(0);
    expect(screen.getByText('customer@example.com')).toBeInTheDocument();
    expect(screen.getByText('failed@example.com')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters notification rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Main Email Channel')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Notification ara'), 'failed');

    expect(screen.queryByText('Main Email Channel')).not.toBeInTheDocument();
    expect(screen.getByText('failed@example.com')).toBeInTheDocument();
    expect(screen.getByText('smtp failed')).toBeInTheDocument();
  });

  it('renders error state when notification runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Notification Monitor okunamadi')).toBeInTheDocument();
    });
  });
});
