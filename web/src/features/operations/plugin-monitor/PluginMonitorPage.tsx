import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchPluginMonitorOverview } from './plugin-monitor-api';
import type { PluginCatalogRow, PluginStateRow } from './types';

function statusClassName(status: string): string {
  const normalized = status.toLowerCase();

  if (['active', 'activated', 'enabled', 'installed', 'running', 'published', 'empty'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['failed', 'blocked', 'disabled', 'archived', 'deprecated', 'denied'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['pending', 'installing', 'deactivating', 'warning', 'draft'].includes(normalized)) {
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

function filterCatalog(rows: PluginCatalogRow[], query: string): PluginCatalogRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.pluginKey,
        row.displayName,
        row.versionNo,
        row.visibilityScope,
        row.sourceType,
        row.lifecycleStatus,
        row.entrypointRef,
        row.requiredPlatformVersion,
      ],
      query,
    ),
  );
}

function filterStates(rows: PluginStateRow[], query: string): PluginStateRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.stateId,
        row.pluginKey,
        row.stateKey,
        row.desiredState,
        row.currentState,
        row.installRef,
        row.lastError,
      ],
      query,
    ),
  );
}

export function PluginMonitorPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const pluginQuery = useQuery({
    queryKey: ['operations', 'plugin-monitor', tenantId],
    queryFn: () => fetchPluginMonitorOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = pluginQuery.data?.summary ?? [];
  const catalog = pluginQuery.data?.catalog ?? [];
  const states = pluginQuery.data?.states ?? [];
  const runtime = pluginQuery.data?.runtime ?? [];

  const filteredCatalog = useMemo(() => filterCatalog(catalog, query), [catalog, query]);
  const filteredStates = useMemo(() => filterStates(states, query), [states, query]);
  const filteredRuntime = useMemo(() => filterStates(runtime, query), [runtime, query]);

  const totalByStatus = summary.reduce((acc, item) => acc + item.count, 0);
  const pluginCount = summary[0]?.pluginCount ?? catalog.length;
  const stateCount = summary[0]?.stateCount ?? states.length;

  if (pluginQuery.isLoading || pluginQuery.isPending) {
    return <LoadingState message="Plugin Monitor yukleniyor..." />;
  }

  if (pluginQuery.isError) {
    return (
      <ErrorState
        title="Plugin Monitor okunamadi"
        description="Plugin Runtime servisi, 5910 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void pluginQuery.refetch()}
      />
    );
  }

  if (!pluginQuery.data) {
    return (
      <EmptyState
        title="Plugin Monitor verisi bulunamadi"
        description="Plugin Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Plugin Monitor</strong>
            <p className="small">
              Plugin katalog, lifecycle, tenant state, permission/sandbox uyumluluk izlerini read-only takip eder.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void pluginQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className="badge">Runtime {pluginQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {pluginQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Plugin {pluginCount}</span>
          <span className="badge">State {stateCount}</span>
          <span className="badge">Status Toplam {totalByStatus}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran monitor/read-only modda calisir. Gercek plugin executor/sandbox runner ayri asamada kontrollu acilacak.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Durum Ozeti</strong>
            <div className="small">Kaynak: /plugin-runtime/api/plugins/summary</div>
          </div>
          <input
            aria-label="Plugin ara"
            placeholder="Plugin, state veya runtime ara"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Adet</th>
              <th>Plugin Sayisi</th>
              <th>State Sayisi</th>
              <th>Uretim Zamani</th>
            </tr>
          </thead>
          <tbody>
            {summary.map((item) => (
              <tr key={item.status}>
                <td>
                  <span className={statusClassName(item.status)}>{item.status}</span>
                </td>
                <td>{item.count}</td>
                <td>{item.pluginCount}</td>
                <td>{item.stateCount}</td>
                <td>{item.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Plugin Catalog</strong>
            <div className="small">Kaynak: /plugin-runtime/api/plugins/catalog</div>
          </div>
          <span className="badge">Gosterilen {filteredCatalog.length} / {catalog.length}</span>
        </div>

        {catalog.length === 0 ? (
          <EmptyState
            title="Plugin kaydi yok"
            description="Henüz runtime.plugins tablosunda plugin bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Plugin</th>
                <th>Versiyon</th>
                <th>Lifecycle</th>
                <th>Kaynak</th>
                <th>Gorunurluk</th>
                <th>Platform</th>
                <th>Aktif</th>
              </tr>
            </thead>
            <tbody>
              {filteredCatalog.map((plugin) => (
                <tr key={`${plugin.pluginKey}-${plugin.versionNo}`}>
                  <td>{plugin.pluginKey}</td>
                  <td>{plugin.versionNo}</td>
                  <td>
                    <span className={statusClassName(plugin.lifecycleStatus)}>
                      {plugin.lifecycleStatus}
                    </span>
                  </td>
                  <td>{plugin.sourceType}</td>
                  <td>{plugin.visibilityScope}</td>
                  <td>{plugin.requiredPlatformVersion || '-'}</td>
                  <td>{plugin.isEnabled ? 'Evet' : 'Hayir'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Plugin States</strong>
            <div className="small">Kaynak: /plugin-runtime/api/plugins/states</div>
          </div>
          <span className="badge">Gosterilen {filteredStates.length} / {states.length}</span>
        </div>

        {states.length === 0 ? (
          <EmptyState
            title="Plugin state kaydi yok"
            description="Henüz runtime.plugin_states tablosunda state bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>State</th>
                <th>Plugin</th>
                <th>Desired</th>
                <th>Current</th>
                <th>Install Ref</th>
                <th>Son Health</th>
                <th>Hata</th>
              </tr>
            </thead>
            <tbody>
              {filteredStates.map((state) => (
                <tr key={state.stateId}>
                  <td>{state.stateKey}</td>
                  <td>{state.pluginKey || '-'}</td>
                  <td>{state.desiredState}</td>
                  <td>
                    <span className={statusClassName(state.currentState)}>
                      {state.currentState}
                    </span>
                  </td>
                  <td>{state.installRef || '-'}</td>
                  <td>{state.lastHealthAt || '-'}</td>
                  <td>{state.lastError || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Runtime Health States</strong>
            <div className="small">Kaynak: /plugin-runtime/api/plugins/runtime</div>
          </div>
          <span className="badge">Gosterilen {filteredRuntime.length} / {runtime.length}</span>
        </div>

        {runtime.length === 0 ? (
          <EmptyState
            title="Runtime state kaydi yok"
            description="Plugin runtime health state kaydi bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Plugin</th>
                <th>State</th>
                <th>Current</th>
                <th>Activated</th>
                <th>Deactivated</th>
                <th>Son Health</th>
              </tr>
            </thead>
            <tbody>
              {filteredRuntime.map((state) => (
                <tr key={`${state.stateId}-runtime`}>
                  <td>{state.pluginKey || '-'}</td>
                  <td>{state.stateKey}</td>
                  <td>
                    <span className={statusClassName(state.currentState)}>
                      {state.currentState}
                    </span>
                  </td>
                  <td>{state.activatedAt || '-'}</td>
                  <td>{state.deactivatedAt || '-'}</td>
                  <td>{state.lastHealthAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
