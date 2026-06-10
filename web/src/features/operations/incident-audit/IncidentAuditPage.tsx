import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchIncidentAuditOverview } from './incident-audit-api';
import type {
  AuditEventRow,
  AuditLogRow,
  IncidentRow,
  TimelineRow,
} from './types';

function levelClassName(level: string): string {
  const normalized = level.toLowerCase();

  if (['ok', 'success', 'resolved', 'closed', 'recorded'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['critical', 'failed', 'fail', 'open', 'p0', 'p1', 'sev1'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['warning', 'acknowledged', 'investigating', 'pending'].includes(normalized)) {
    return 'status-pill status-pill--degraded';
  }

  return 'status-pill status-pill--unknown';
}

function includesAny(values: string[], query: string): boolean {
  const trimmed = query.trim().toLowerCase();

  if (!trimmed) {
    return true;
  }

  return values.some((value) => value.toLowerCase().includes(trimmed));
}

function filterIncidents(rows: IncidentRow[], query: string): IncidentRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.incidentId,
        row.tenantId,
        row.businessCode,
        row.incidentKey,
        row.title,
        row.summary,
        row.severity,
        row.status,
        row.source,
        row.ownerTeam,
      ],
      query,
    ),
  );
}

function filterAuditEvents(rows: AuditEventRow[], query: string): AuditEventRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.eventId,
        row.tenantId,
        row.actorUserId,
        row.eventCode,
        row.entitySchema,
        row.entityTable,
        row.entityId,
        row.payload,
      ],
      query,
    ),
  );
}

function filterAuditLogs(rows: AuditLogRow[], query: string): AuditLogRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        String(row.logId),
        row.tenantId,
        row.actorType,
        row.actorId,
        row.action,
        row.entityType,
        row.entityId,
        row.status,
        row.details,
      ],
      query,
    ),
  );
}

function filterTimeline(rows: TimelineRow[], query: string): TimelineRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.source,
        row.refId,
        row.title,
        row.status,
        row.severity,
        row.actor,
        row.entity,
      ],
      query,
    ),
  );
}

function shortJson(value: string): string {
  if (value.length <= 120) {
    return value;
  }

  return `${value.slice(0, 120)}...`;
}

export function IncidentAuditPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const incidentAuditQuery = useQuery({
    queryKey: ['operations', 'incident-audit', tenantId],
    queryFn: () => fetchIncidentAuditOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = incidentAuditQuery.data?.summary ?? [];
  const incidents = incidentAuditQuery.data?.incidents ?? [];
  const auditEvents = incidentAuditQuery.data?.auditEvents ?? [];
  const auditLogs = incidentAuditQuery.data?.auditLogs ?? [];
  const timeline = incidentAuditQuery.data?.timeline ?? [];

  const mainSummary = summary[0];

  const filteredIncidents = useMemo(() => filterIncidents(incidents, query), [incidents, query]);
  const filteredAuditEvents = useMemo(() => filterAuditEvents(auditEvents, query), [auditEvents, query]);
  const filteredAuditLogs = useMemo(() => filterAuditLogs(auditLogs, query), [auditLogs, query]);
  const filteredTimeline = useMemo(() => filterTimeline(timeline, query), [timeline, query]);

  if (incidentAuditQuery.isLoading || incidentAuditQuery.isPending) {
    return <LoadingState message="Incident / Audit Center yukleniyor..." />;
  }

  if (incidentAuditQuery.isError) {
    return (
      <ErrorState
        title="Incident / Audit Center okunamadi"
        description="Incident Audit Runtime servisi, 5950 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void incidentAuditQuery.refetch()}
      />
    );
  }

  if (!incidentAuditQuery.data || !mainSummary) {
    return (
      <EmptyState
        title="Incident / Audit verisi bulunamadi"
        description="Incident Audit Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Incident / Audit Center</strong>
            <p className="small">
              Incident kayitlari, audit events, audit logs ve birleşik timeline akisini read-only izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void incidentAuditQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className={levelClassName(mainSummary.alertLevel)}>
            Alert {mainSummary.alertLevel.toUpperCase()}
          </span>
          <span className="badge">Runtime {incidentAuditQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {incidentAuditQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Incident {mainSummary.incidentCount}</span>
          <span className="badge">Open {mainSummary.openIncidentCount}</span>
          <span className="badge">Critical {mainSummary.criticalIncidentCount}</span>
          <span className="badge">Audit Event {mainSummary.auditEventCount}</span>
          <span className="badge">Audit Log {mainSummary.auditLogCount}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran merkez izleme ekranidir. Sonraki adimda aksiyon butonlari, onay akisi ve otomatik response ayri guvenlik katmani ile eklenir.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Arama / Filtre</strong>
            <div className="small">Incident, audit action, actor, entity veya status ara.</div>
          </div>
          <input
            aria-label="Incident audit ara"
            placeholder="incident, ledger.build, accounting-service, success..."
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Unified Timeline</strong>
            <div className="small">Kaynak: /incident-audit-runtime/api/incident-audit/timeline</div>
          </div>
          <span className="badge">Gosterilen {filteredTimeline.length} / {timeline.length}</span>
        </div>

        {timeline.length === 0 ? (
          <EmptyState
            title="Timeline kaydi yok"
            description="Incident, audit event veya audit log kaydi bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Source</th>
                <th>Title</th>
                <th>Status</th>
                <th>Severity</th>
                <th>Actor</th>
                <th>Entity</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {filteredTimeline.map((item) => (
                <tr key={`${item.source}-${item.refId}`}>
                  <td>{item.source}</td>
                  <td>{item.title}</td>
                  <td>
                    <span className={levelClassName(item.status)}>{item.status}</span>
                  </td>
                  <td>{item.severity || '-'}</td>
                  <td>{item.actor || '-'}</td>
                  <td>{item.entity || '-'}</td>
                  <td>{item.createdAt}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Incidents</strong>
            <div className="small">Kaynak: /incident-audit-runtime/api/incident-audit/incidents</div>
          </div>
          <span className="badge">Gosterilen {filteredIncidents.length} / {incidents.length}</span>
        </div>

        {incidents.length === 0 ? (
          <EmptyState
            title="Incident kaydi yok"
            description="runtime.mission_control_incidents tablosunda aktif kayit bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Incident</th>
                <th>Title</th>
                <th>Severity</th>
                <th>Status</th>
                <th>Owner</th>
                <th>Source</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {filteredIncidents.map((incident) => (
                <tr key={incident.incidentId}>
                  <td>{incident.incidentKey}</td>
                  <td>{incident.title}</td>
                  <td>
                    <span className={levelClassName(incident.severity)}>{incident.severity}</span>
                  </td>
                  <td>
                    <span className={levelClassName(incident.status)}>{incident.status}</span>
                  </td>
                  <td>{incident.ownerTeam || '-'}</td>
                  <td>{incident.source || '-'}</td>
                  <td>{incident.createdAt}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Audit Events</strong>
            <div className="small">Kaynak: /incident-audit-runtime/api/incident-audit/audit-events</div>
          </div>
          <span className="badge">Gosterilen {filteredAuditEvents.length} / {auditEvents.length}</span>
        </div>

        {auditEvents.length === 0 ? (
          <EmptyState
            title="Audit event kaydi yok"
            description="audit.audit_events tablosunda kayit bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Event</th>
                <th>Tenant</th>
                <th>Actor</th>
                <th>Entity</th>
                <th>Payload</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {filteredAuditEvents.map((event) => (
                <tr key={event.eventId}>
                  <td>{event.eventCode}</td>
                  <td>{event.tenantId}</td>
                  <td>{event.actorUserId || '-'}</td>
                  <td>{event.entitySchema}.{event.entityTable}:{event.entityId}</td>
                  <td>{shortJson(event.payload)}</td>
                  <td>{event.createdAt}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Audit Logs</strong>
            <div className="small">Kaynak: /incident-audit-runtime/api/incident-audit/audit-logs</div>
          </div>
          <span className="badge">Gosterilen {filteredAuditLogs.length} / {auditLogs.length}</span>
        </div>

        {auditLogs.length === 0 ? (
          <EmptyState
            title="Audit log kaydi yok"
            description="public.audit_logs tablosunda kayit bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Tenant</th>
                <th>Actor</th>
                <th>Action</th>
                <th>Entity</th>
                <th>Status</th>
                <th>Details</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {filteredAuditLogs.map((log) => (
                <tr key={log.logId}>
                  <td>{log.logId}</td>
                  <td>{log.tenantId}</td>
                  <td>{log.actorType}:{log.actorId}</td>
                  <td>{log.action}</td>
                  <td>{log.entityType}:{log.entityId}</td>
                  <td>
                    <span className={levelClassName(log.status)}>{log.status}</span>
                  </td>
                  <td>{shortJson(log.details)}</td>
                  <td>{log.createdAt}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
