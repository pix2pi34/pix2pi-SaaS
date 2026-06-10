import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { JobsQueuePage } from './JobsQueuePage';
import { normalizeJobsQueues, normalizeJobsSummary, normalizeRecentJobs } from './jobs-queue-api';

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
      <JobsQueuePage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/jobs-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'jobs-runtime',
          db: 'ok',
          port: '5880',
        }),
      } as Response;
    }

    if (url.includes('/jobs-runtime/api/jobs/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              status: 'queued',
              count: 2,
              queue_count: 1,
              attempt_count: 3,
              generated_at: '2026-04-24T10:00:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/jobs-runtime/api/jobs/queues')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              queue_key: 'default',
              display_name: 'Default',
              visibility_scope: 'global',
              is_enabled: true,
              max_concurrency: 5,
              retry_limit: 3,
              retry_backoff_seconds: 30,
              dead_letter_queue_key: 'default.dlq',
              queued_count: 2,
              processing_count: 1,
              failed_count: 0,
              dead_letter_count: 0,
              updated_at: '2026-04-24T10:00:00Z',
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
            job_id: 'job-1',
            queue_key: 'default',
            job_key: 'invoice-sync-1',
            job_type: 'invoice.sync',
            priority: 'normal',
            status: 'queued',
            retry_count: 0,
            max_attempts: 3,
            last_error: '',
            locked_by: '',
            available_at: '',
            created_at: '2026-04-24T10:00:00Z',
            updated_at: '2026-04-24T10:00:00Z',
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

describe('jobs-queue-page', () => {
  it('normalizes jobs runtime payloads', () => {
    expect(normalizeJobsSummary({ items: [{ status: 'empty', count: 0 }] })[0].status).toBe('empty');
    expect(normalizeJobsQueues({ items: [{ queue_key: 'default', is_enabled: true }] })[0].queueKey).toBe('default');
    expect(normalizeRecentJobs({ items: [{ job_id: 'job-1', job_key: 'demo' }] })[0].jobKey).toBe('demo');
  });

  it('renders jobs queue overview and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Jobs Queue yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Jobs Queue')).toBeInTheDocument();
    });

    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getAllByText('default').length).toBeGreaterThan(0);
    expect(screen.getByText('invoice-sync-1')).toBeInTheDocument();

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters queues and recent jobs by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('invoice-sync-1')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Jobs ara'), 'invoice');

    expect(screen.queryByText('default.dlq')).not.toBeInTheDocument();
    expect(screen.getByText('invoice-sync-1')).toBeInTheDocument();
  });

  it('renders error state when jobs runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Jobs Queue okunamadi')).toBeInTheDocument();
    });
  });
});
