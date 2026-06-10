import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { WorkflowMonitorPage } from './WorkflowMonitorPage';
import {
  normalizeWorkflowApprovals,
  normalizeWorkflowDefinitions,
  normalizeWorkflowInstances,
  normalizeWorkflowSteps,
  normalizeWorkflowSummary,
} from './workflow-monitor-api';

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
      <WorkflowMonitorPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/workflow-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'workflow-runtime',
          db: 'ok',
          port: '5900',
        }),
      } as Response;
    }

    if (url.includes('/workflow-runtime/api/workflows/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              status: 'running',
              count: 1,
              definition_count: 1,
              step_count: 1,
              approval_count: 1,
              generated_at: '2026-04-24T11:30:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/workflow-runtime/api/workflows/definitions')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              workflow_key: 'order-approval',
              display_name: 'Order Approval',
              version_no: 1,
              visibility_scope: 'tenant',
              definition_status: 'published',
              trigger_event: 'order.created',
              is_enabled: true,
              created_at: '2026-04-24T11:00:00Z',
              updated_at: '2026-04-24T11:05:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/workflow-runtime/api/workflows/instances')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              instance_id: 'instance-1',
              workflow_key: 'order-approval',
              instance_key: 'order-approval-001',
              workflow_status: 'running',
              subject_ref_type: 'order',
              subject_ref_id: 'order-1',
              current_step_key: 'manual-approval',
              started_at: '2026-04-24T11:10:00Z',
              finished_at: '',
              created_at: '2026-04-24T11:10:00Z',
              updated_at: '2026-04-24T11:12:00Z',
            },
          ],
          limit: 25,
        }),
      } as Response;
    }

    if (url.includes('/workflow-runtime/api/workflows/steps')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              step_id: 'step-1',
              instance_key: 'order-approval-001',
              step_key: 'manual-approval',
              step_order: 1,
              step_type: 'manual',
              step_status: 'waiting',
              assigned_to: 'manager-1',
              started_at: '2026-04-24T11:11:00Z',
              finished_at: '',
              created_at: '2026-04-24T11:10:00Z',
              updated_at: '2026-04-24T11:12:00Z',
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
            approval_id: 'approval-1',
            instance_key: 'order-approval-001',
            step_id: 'step-1',
            approval_key: 'approval-manager-1',
            approver_ref: 'manager-1',
            approval_status: 'pending',
            requested_at: '2026-04-24T11:12:00Z',
            responded_at: '',
            response_note: '',
            created_at: '2026-04-24T11:12:00Z',
            updated_at: '2026-04-24T11:12:00Z',
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

describe('workflow-monitor-page', () => {
  it('normalizes workflow runtime payloads', () => {
    expect(normalizeWorkflowSummary({ items: [{ status: 'empty', count: 0 }] })[0].status).toBe('empty');
    expect(normalizeWorkflowDefinitions({ items: [{ workflow_key: 'order-approval', is_enabled: true }] })[0].workflowKey).toBe('order-approval');
    expect(normalizeWorkflowInstances({ items: [{ instance_id: 'instance-1', instance_key: 'demo' }] })[0].instanceKey).toBe('demo');
    expect(normalizeWorkflowSteps({ items: [{ step_id: 'step-1', step_key: 'manual' }] })[0].stepKey).toBe('manual');
    expect(normalizeWorkflowApprovals({ items: [{ approval_id: 'approval-1', approval_key: 'approve' }] })[0].approvalKey).toBe('approve');
  });

  it('renders workflow monitor overview and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Workflow Monitor yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Workflow Monitor')).toBeInTheDocument();
    });

    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('Definition 1')).toBeInTheDocument();
    expect(screen.getByText('Instance 1')).toBeInTheDocument();
    expect(screen.getByText('Step 1')).toBeInTheDocument();
    expect(screen.getByText('Approval 1')).toBeInTheDocument();

    expect(screen.getAllByText('order-approval').length).toBeGreaterThan(0);
    expect(screen.getAllByText('order-approval-001').length).toBeGreaterThan(0);
    expect(screen.getAllByText('manual-approval').length).toBeGreaterThan(0);
    expect(screen.getAllByText('approval-manager-1').length).toBeGreaterThan(0);

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters workflow rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getAllByText('approval-manager-1').length).toBeGreaterThan(0);
    });

    await user.type(screen.getByLabelText('Workflow ara'), 'manager');

    expect(screen.queryByText('order.created')).not.toBeInTheDocument();
    expect(screen.getAllByText('approval-manager-1').length).toBeGreaterThan(0);
  });

  it('renders error state when workflow runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Workflow Monitor okunamadi')).toBeInTheDocument();
    });
  });
});
