import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchRealtimeOverview } from './realtime-api';
import type {
  RealtimeGenericRow,
  RealtimeTableStatusItem,
} from './types';

function levelClassName(level: string): string {
  const normalized = level.toLowerCase();

  if (['ok', 'active', 'online', 'connected', 'streaming', 'true'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['fail', 'failed', 'down', 'false', 'missing'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['empty', 'unknown', 'offline', 'expired'].includes(normalized)) {
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

function filterTables(rows: RealtimeTableStatusItem[], query: string): RealtimeTableStatusItem[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.tableName,
        String(row.exists),
        String(row.count),
      ],
      query,
    ),
  );
}

function filterRows(rows: RealtimeGenericRow[], query: string): RealtimeGenericRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.tableName,
        row.recordJSON,
        row.observedAt,
      ],
      query,
    ),
  );
}

function shortJson(value: string): string {
  if (value.length <= 160) {
    return value;
  }

  return `${value.slice(0, 160)}...`;
}

function RealtimeRowsTable(props: {
  title: string;
  source: string;
  rows: RealtimeGenericRow[];
  query: string;
  emptyTitle: string;
  emptyDescription: string;
}) {
  const filteredRows = useMemo(() => filterRows(props.rows, props.query), [props.rows, props.query]);

  return (
    <section className="card span-12">
      <div className="toolbar">
        <div>
          <strong>{props.title}</strong>
          <div className="small">Kaynak: {props.source}</div>
        </div>
        <span className="badge">Gosterilen {filteredRows.length} / {props.rows.length}</span>
      </div>

      {props.rows.length === 0 ? (
        <EmptyState
          title={props.emptyTitle}
          description={props.emptyDescription}
        />
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th>Table</th>
              <th>Record JSON</th>
              <th>Observed</th>
            </tr>
          </thead>
          <tbody>
            {filteredRows.map((row, index) => (
              <tr key={`${row.tableName}-${row.observedAt}-${index}`}>
                <td>{row.tableName}</td>
                <td>{shortJson(row.recordJSON)}</td>
                <td>{row.observedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}

export function RealtimeMonitorPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const realtimeQuery = useQuery({
    queryKey: ['operations', 'realtime-monitor', tenantId],
    queryFn: () => fetchRealtimeOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = realtimeQuery.data?.summary ?? [];
  const tables = realtimeQuery.data?.tables ?? [];
  const channels = realtimeQuery.data?.channels ?? [];
  const connections = realtimeQuery.data?.connections ?? [];
  const presence = realtimeQuery.data?.presence ?? [];
  const permissions = realtimeQuery.data?.permissions ?? [];

  const mainSummary = summary[0];

  const filteredTables = useMemo(() => filterTables(tables, query), [tables, query]);

  if (realtimeQuery.isLoading || realtimeQuery.isPending) {
    return <LoadingState message="Realtime / Channel Monitor yukleniyor..." />;
  }

  if (realtimeQuery.isError) {
    return (
      <ErrorState
        title="Realtime / Channel Monitor okunamadi"
        description="Realtime Runtime servisi, 5970 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void realtimeQuery.refetch()}
      />
    );
  }

  if (!realtimeQuery.data || !mainSummary) {
    return (
      <EmptyState
        title="Realtime verisi bulunamadi"
        description="Realtime Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Realtime / Channel Monitor</strong>
            <p className="small">
              WebSocket, SSE, presence ve channel permission katmanlarini read-only izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void realtimeQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className={levelClassName(mainSummary.status)}>
            Status {mainSummary.status.toUpperCase()}
          </span>
          <span className="badge">Runtime {realtimeQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {realtimeQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Channels {mainSummary.channelCount}</span>
          <span className="badge">Connections {mainSummary.connectionCount}</span>
          <span className="badge">Active {mainSummary.activeConnectionCount}</span>
          <span className="badge">WS {mainSummary.webSocketCount}</span>
          <span className="badge">SSE {mainSummary.sseCount}</span>
          <span className="badge">Presence {mainSummary.presenceCount}</span>
          <span className="badge">Permissions {mainSummary.channelPermissionCount}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Realtime tablolarinin bir kismi henuz DB tarafinda yok. Bu ekran eksik tablolari hata uretmeden gorunur kilar.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Arama / Filtre</strong>
            <div className="small">Table, channel, connection, presence veya permission ara.</div>
          </div>
          <input
            aria-label="Realtime monitor ara"
            placeholder="realtime, channel, connection, presence, websocket, sse..."
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Realtime Table Status</strong>
            <div className="small">Kaynak: /realtime-runtime/api/realtime/tables</div>
          </div>
          <span className="badge">Gosterilen {filteredTables.length} / {tables.length}</span>
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Table</th>
              <th>Exists</th>
              <th>Count</th>
              <th>Generated</th>
            </tr>
          </thead>
          <tbody>
            {filteredTables.map((table) => (
              <tr key={table.tableName}>
                <td>{table.tableName}</td>
                <td>
                  <span className={levelClassName(String(table.exists))}>
                    {String(table.exists)}
                  </span>
                </td>
                <td>{table.count}</td>
                <td>{table.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <RealtimeRowsTable
        title="Channels"
        source="/realtime-runtime/api/realtime/channels"
        rows={channels}
        query={query}
        emptyTitle="Channel kaydi yok"
        emptyDescription="runtime.notification_channels tablosunda kayit bulunmuyor."
      />

      <RealtimeRowsTable
        title="Connections"
        source="/realtime-runtime/api/realtime/connections"
        rows={connections}
        query={query}
        emptyTitle="Connection kaydi yok"
        emptyDescription="runtime.realtime_connections tablosu yok veya bos."
      />

      <RealtimeRowsTable
        title="Presence"
        source="/realtime-runtime/api/realtime/presence"
        rows={presence}
        query={query}
        emptyTitle="Presence kaydi yok"
        emptyDescription="runtime.realtime_presence tablosu yok veya bos."
      />

      <RealtimeRowsTable
        title="Channel Permissions"
        source="/realtime-runtime/api/realtime/permissions"
        rows={permissions}
        query={query}
        emptyTitle="Permission kaydi yok"
        emptyDescription="runtime.realtime_channel_permissions tablosu yok veya bos."
      />
    </div>
  );
}
