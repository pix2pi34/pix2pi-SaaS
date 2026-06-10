import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchEarlyWarningOverview } from './early-warning-api';
import type {
  EarlyWarningIncidentItem,
  EarlyWarningResourceItem,
  EarlyWarningServiceItem,
  EarlyWarningSignalItem,
} from './types';

function levelClassName(level: string): string {
  const normalized = level.toLowerCase();

  if (['ok', 'healthy', 'active'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['critical', 'fail', 'failed', 'down'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['warning', 'degraded'].includes(normalized)) {
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

function filterServices(rows: EarlyWarningServiceItem[], query: string): EarlyWarningServiceItem[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.serviceKey,
        row.display,
        row.status,
        row.message,
        String(row.httpStatus),
      ],
      query,
    ),
  );
}

function filterResources(rows: EarlyWarningResourceItem[], query: string): EarlyWarningResourceItem[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.resourceKey,
        row.display,
        row.level,
        row.message,
      ],
      query,
    ),
  );
}

function filterSignals(rows: EarlyWarningSignalItem[], query: string): EarlyWarningSignalItem[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.signalKey,
        row.category,
        row.level,
        row.status,
        row.message,
      ],
      query,
    ),
  );
}

function filterIncidents(rows: EarlyWarningIncidentItem[], query: string): EarlyWarningIncidentItem[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.tableName,
        String(row.count),
      ],
      query,
    ),
  );
}

export function EarlyWarningPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const earlyWarningQuery = useQuery({
    queryKey: ['operations', 'early-warning', tenantId],
    queryFn: () => fetchEarlyWarningOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = earlyWarningQuery.data?.summary ?? [];
  const services = earlyWarningQuery.data?.services ?? [];
  const resources = earlyWarningQuery.data?.resources ?? [];
  const signals = earlyWarningQuery.data?.signals ?? [];
  const incidents = earlyWarningQuery.data?.incidents ?? [];

  const mainSummary = summary[0];

  const filteredServices = useMemo(() => filterServices(services, query), [services, query]);
  const filteredResources = useMemo(() => filterResources(resources, query), [resources, query]);
  const filteredSignals = useMemo(() => filterSignals(signals, query), [signals, query]);
  const filteredIncidents = useMemo(() => filterIncidents(incidents, query), [incidents, query]);

  if (earlyWarningQuery.isLoading || earlyWarningQuery.isPending) {
    return <LoadingState message="Early Warning Dashboard yukleniyor..." />;
  }

  if (earlyWarningQuery.isError) {
    return (
      <ErrorState
        title="Early Warning Dashboard okunamadi"
        description="Early Warning Runtime servisi, 5940 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void earlyWarningQuery.refetch()}
      />
    );
  }

  if (!earlyWarningQuery.data || !mainSummary) {
    return (
      <EmptyState
        title="Early Warning verisi bulunamadi"
        description="Early Warning Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Early Warning / Alert Dashboard</strong>
            <p className="small">
              Servis sagligi, sistem kaynaklari, DB health ve incident sinyallerini tek merkezden izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void earlyWarningQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className={levelClassName(mainSummary.alertLevel)}>
            Alert {mainSummary.alertLevel.toUpperCase()}
          </span>
          <span className="badge">Runtime {earlyWarningQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {earlyWarningQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Service OK {mainSummary.serviceOKCount}</span>
          <span className="badge">Service FAIL {mainSummary.serviceFailCount}</span>
          <span className="badge">Warning {mainSummary.warningCount}</span>
          <span className="badge">Critical {mainSummary.criticalCount}</span>
          <span className="badge">Incident {mainSummary.incidentCount}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran read-only alarm merkezidir. Otomatik aksiyon/restart/isolation bir sonraki incident center akisine baglanacak.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Arama / Filtre</strong>
            <div className="small">Servis, kaynak, sinyal veya incident tablosu ara.</div>
          </div>
          <input
            aria-label="Early warning ara"
            placeholder="service, db, disk, memory, warning, critical..."
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Service Health</strong>
            <div className="small">Kaynak: /early-warning-runtime/api/early-warning/services</div>
          </div>
          <span className="badge">Gosterilen {filteredServices.length} / {services.length}</span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Service</th>
              <th>Status</th>
              <th>HTTP</th>
              <th>Latency</th>
              <th>Mesaj</th>
              <th>Checked</th>
            </tr>
          </thead>
          <tbody>
            {filteredServices.map((service) => (
              <tr key={service.serviceKey}>
                <td>{service.display}</td>
                <td>
                  <span className={levelClassName(service.status)}>{service.status}</span>
                </td>
                <td>{service.httpStatus}</td>
                <td>{service.latencyMs} ms</td>
                <td>{service.message}</td>
                <td>{service.checkedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Resource Pressure</strong>
            <div className="small">Kaynak: /early-warning-runtime/api/early-warning/resources</div>
          </div>
          <span className="badge">Gosterilen {filteredResources.length} / {resources.length}</span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Kaynak</th>
              <th>Level</th>
              <th>Kullanim</th>
              <th>Deger</th>
              <th>Mesaj</th>
              <th>Checked</th>
            </tr>
          </thead>
          <tbody>
            {filteredResources.map((resource) => (
              <tr key={resource.resourceKey}>
                <td>{resource.display}</td>
                <td>
                  <span className={levelClassName(resource.level)}>{resource.level}</span>
                </td>
                <td>{resource.usedPercent.toFixed(1)}%</td>
                <td>{resource.value.toFixed(2)} {resource.unit}</td>
                <td>{resource.message}</td>
                <td>{resource.checkedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Warning Signals</strong>
            <div className="small">Kaynak: /early-warning-runtime/api/early-warning/signals</div>
          </div>
          <span className="badge">Gosterilen {filteredSignals.length} / {signals.length}</span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Signal</th>
              <th>Category</th>
              <th>Level</th>
              <th>Status</th>
              <th>Mesaj</th>
              <th>Generated</th>
            </tr>
          </thead>
          <tbody>
            {filteredSignals.map((signal) => (
              <tr key={signal.signalKey}>
                <td>{signal.signalKey}</td>
                <td>{signal.category}</td>
                <td>
                  <span className={levelClassName(signal.level)}>{signal.level}</span>
                </td>
                <td>{signal.status}</td>
                <td>{signal.message}</td>
                <td>{signal.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Incident / Audit Counters</strong>
            <div className="small">Kaynak: /early-warning-runtime/api/early-warning/incidents</div>
          </div>
          <span className="badge">Gosterilen {filteredIncidents.length} / {incidents.length}</span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Tablo</th>
              <th>Count</th>
              <th>Generated</th>
            </tr>
          </thead>
          <tbody>
            {filteredIncidents.map((incident) => (
              <tr key={incident.tableName}>
                <td>{incident.tableName}</td>
                <td>{incident.count}</td>
                <td>{incident.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}
