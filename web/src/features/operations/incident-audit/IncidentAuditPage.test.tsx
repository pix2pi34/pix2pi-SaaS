import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAuthStore } from '../../../core/auth/auth-store';
import { IncidentAuditPage } from './IncidentAuditPage';
import {
  normalizeAuditEvents,
  normalizeAuditLogs,
  normalizeIncidentAuditSummary,
  normalizeIncidents,
  normalizeTimeline,
} from './incident-audit-api';

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
      <IncidentAuditPage />
    </QueryClientProvider>,
  );
}

function createFetchMock() {
  return vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input);

    if (url.includes('/incident-audit-runtime/health')) {
      return {
        ok: true,
        json: async () => ({
          status: 'ok',
          service: 'incident-audit-runtime',
          db: 'ok',
          port: '5950',
        }),
      } as Response;
    }

    if (url.includes('/incident-audit-runtime/api/incident-audit/summary')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              alert_level: 'ok',
              incident_count: 1,
              open_incident_count: 0,
              critical_incident_count: 0,
              audit_event_count: 1,
              audit_log_count: 23,
              recent_audit_log_count: 0,
              generated_at: '2026-04-24T21:00:00Z',
            },
          ],
        }),
      } as Response;
    }

    if (url.includes('/incident-audit-runtime/api/incident-audit/incidents')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              incident_id: 'incident-1',
              tenant_id: 'tenant-1',
              business_code: 'ops',
              incident_key: 'inc-api-1',
              title: 'API latency warning',
              summary: 'Gateway latency rose temporarily',
              severity: 'warning',
              status: 'resolved',
              source: 'early-warning',
              owner_team: 'platform',
              opened_by: 'system',
              acknowledged_by: 'ops-1',
              resolved_by: 'ops-1',
              detected_at: '2026-04-24T20:50:00Z',
              acknowledged_at: '2026-04-24T20:52:00Z',
              resolved_at: '2026-04-24T20:55:00Z',
              closed_at: '',
              created_at: '2026-04-24T20:50:00Z',
              updated_at: '2026-04-24T20:55:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/incident-audit-runtime/api/incident-audit/audit-events')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              event_id: 'audit-event-1',
              tenant_id: 'tenant-1',
              actor_user_id: 'user-1',
              event_code: 'tenant.updated',
              entity_schema: 'public',
              entity_table: 'tenants',
              entity_id: 'tenant-1',
              payload: '{"change":"name"}',
              created_at: '2026-04-24T20:45:00Z',
            },
          ],
          limit: 50,
        }),
      } as Response;
    }

    if (url.includes('/incident-audit-runtime/api/incident-audit/audit-logs')) {
      return {
        ok: true,
        json: async () => ({
          items: [
            {
              log_id: 23,
              tenant_id: 'tenant-001',
              actor_type: 'system',
              actor_id: 'accounting-service',
              action: 'ledger.build',
              entity_type: 'ledger_posting',
              entity_id: 'S-57A-1776310805',
              status: 'success',
              details: '{"event":"sale.created","gross_amount":1200}',
              created_at: '2026-04-16T03:40:06Z',
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
            source: 'incident',
            ref_id: 'incident-1',
            title: 'API latency warning',
            status: 'resolved',
            severity: 'warning',
            actor: 'system',
            entity: 'api-gateway',
            created_at: '2026-04-24T20:50:00Z',
          },
          {
            source: 'audit_log',
            ref_id: '23',
            title: 'ledger.build',
            status: 'success',
            severity: '',
            actor: 'system:accounting-service',
            entity: 'ledger_posting:S-57A-1776310805',
            created_at: '2026-04-16T03:40:06Z',
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

describe('incident-audit-page', () => {
  it('normalizes incident audit runtime payloads', () => {
    expect(normalizeIncidentAuditSummary({ items: [{ alert_level: 'ok', audit_log_count: 23 }] })[0].auditLogCount).toBe(23);
    expect(normalizeIncidents({ items: [{ incident_id: 'incident-1', incident_key: 'inc-api-1' }] })[0].incidentKey).toBe('inc-api-1');
    expect(normalizeAuditEvents({ items: [{ event_id: 'event-1', event_code: 'tenant.updated' }] })[0].eventCode).toBe('tenant.updated');
    expect(normalizeAuditLogs({ items: [{ log_id: 23, action: 'ledger.build' }] })[0].action).toBe('ledger.build');
    expect(normalizeTimeline({ items: [{ source: 'audit_log', ref_id: '23' }] })[0].refId).toBe('23');
  });

  it('renders incident audit center and sends auth headers', async () => {
    const fetchMock = createFetchMock();
    vi.stubGlobal('fetch', fetchMock);

    renderWithQueryClient();

    expect(screen.getByText('Incident / Audit Center yukleniyor...')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('Incident / Audit Center')).toBeInTheDocument();
    });

    expect(screen.getByText('Alert OK')).toBeInTheDocument();
    expect(screen.getByText('Runtime OK')).toBeInTheDocument();
    expect(screen.getByText('DB OK')).toBeInTheDocument();
    expect(screen.getByText('Incident 1')).toBeInTheDocument();
    expect(screen.getByText('Open 0')).toBeInTheDocument();
    expect(screen.getByText('Critical 0')).toBeInTheDocument();
    expect(screen.getByText('Audit Event 1')).toBeInTheDocument();
    expect(screen.getByText('Audit Log 23')).toBeInTheDocument();

    expect(screen.getAllByText('API latency warning').length).toBeGreaterThan(0);
    expect(screen.getByText('inc-api-1')).toBeInTheDocument();
    expect(screen.getByText('tenant.updated')).toBeInTheDocument();
    expect(screen.getAllByText('ledger.build').length).toBeGreaterThan(0);
    expect(screen.getAllByText('system:accounting-service').length).toBeGreaterThan(0);

    const firstCall = fetchMock.mock.calls[0];
    expect(firstCall).toBeDefined();

    const init = firstCall?.[1] as RequestInit | undefined;
    expect(init?.headers).toMatchObject({
      Accept: 'application/json',
      Authorization: 'Bearer test-access-token',
      'X-Tenant-ID': 'tenant-1',
    });
  });

  it('filters incident audit rows by query', async () => {
    const user = userEvent.setup();
    vi.stubGlobal('fetch', createFetchMock());

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('inc-api-1')).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText('Incident audit ara'), 'ledger');

    expect(screen.queryByText('inc-api-1')).not.toBeInTheDocument();
    expect(screen.getAllByText('ledger.build').length).toBeGreaterThan(0);
    expect(screen.getAllByText('ledger_posting:S-57A-1776310805').length).toBeGreaterThan(0);
  });

  it('renders error state when incident audit runtime fails', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      ok: false,
      status: 500,
      json: async () => ({}),
    } as Response)));

    renderWithQueryClient();

    await waitFor(() => {
      expect(screen.getByText('Incident / Audit Center okunamadi')).toBeInTheDocument();
    });
  });
});
