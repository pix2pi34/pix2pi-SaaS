import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchPublicAPIMonitorOverview } from './publicapi-monitor-api';
import type { APIKeyRow, APIQuotaPolicyRow, APIUsageRow } from './types';

function statusClassName(status: string): string {
  const normalized = status.toLowerCase();

  if (['active', 'enabled', 'allowed', 'ok', 'empty'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['revoked', 'expired', 'blocked', 'limited', 'rejected', 'disabled'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['pending', 'warning', 'sandbox'].includes(normalized)) {
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

function filterKeys(rows: APIKeyRow[], query: string): APIKeyRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.keyRef,
        row.displayName,
        row.visibilityScope,
        row.keyPrefix,
        row.status,
      ],
      query,
    ),
  );
}

function filterPolicies(rows: APIQuotaPolicyRow[], query: string): APIQuotaPolicyRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.policyKey,
        row.keyRef,
        row.endpointScope,
        row.quotaPeriod,
      ],
      query,
    ),
  );
}

function filterUsage(rows: APIUsageRow[], query: string): APIUsageRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.usageId,
        row.keyRef,
        row.policyKey,
        row.lastRequestAt,
      ],
      query,
    ),
  );
}

export function PublicAPIMonitorPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const publicAPIQuery = useQuery({
    queryKey: ['operations', 'publicapi-monitor', tenantId],
    queryFn: () => fetchPublicAPIMonitorOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = publicAPIQuery.data?.summary ?? [];
  const apiKeys = publicAPIQuery.data?.apiKeys ?? [];
  const quotaPolicies = publicAPIQuery.data?.quotaPolicies ?? [];
  const usage = publicAPIQuery.data?.usage ?? [];

  const filteredKeys = useMemo(() => filterKeys(apiKeys, query), [apiKeys, query]);
  const filteredPolicies = useMemo(() => filterPolicies(quotaPolicies, query), [quotaPolicies, query]);
  const filteredUsage = useMemo(() => filterUsage(usage, query), [usage, query]);

  const keyCount = summary[0]?.keyCount ?? apiKeys.length;
  const policyCount = summary[0]?.policyCount ?? quotaPolicies.length;
  const usageCount = summary[0]?.usageCount ?? usage.length;
  const requestCount = summary.reduce((acc, item) => acc + item.requestCount, 0);
  const rejectedCount = summary.reduce((acc, item) => acc + item.rejectedCount, 0);

  if (publicAPIQuery.isLoading || publicAPIQuery.isPending) {
    return <LoadingState message="Public API Monitor yukleniyor..." />;
  }

  if (publicAPIQuery.isError) {
    return (
      <ErrorState
        title="Public API Monitor okunamadi"
        description="Public API Runtime servisi, 5920 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void publicAPIQuery.refetch()}
      />
    );
  }

  if (!publicAPIQuery.data) {
    return (
      <EmptyState
        title="Public API Monitor verisi bulunamadi"
        description="Public API Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Public API Monitor</strong>
            <p className="small">
              API key, quota policy, rate/usage ve developer portal runtime durumlarini read-only izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void publicAPIQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className="badge">Runtime {publicAPIQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {publicAPIQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">API Key {keyCount}</span>
          <span className="badge">Policy {policyCount}</span>
          <span className="badge">Usage {usageCount}</span>
          <span className="badge">Request {requestCount}</span>
          <span className="badge">Rejected {rejectedCount}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran monitor/read-only modda calisir. API key uretimi, quota enforce ve docs publish runtime ayri akislarda kalir.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Durum Ozeti</strong>
            <div className="small">Kaynak: /publicapi-runtime/api/publicapi/summary</div>
          </div>
          <input
            aria-label="Public API ara"
            placeholder="API key, policy veya usage ara"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Adet</th>
              <th>Key</th>
              <th>Policy</th>
              <th>Usage</th>
              <th>Request</th>
              <th>Rejected</th>
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
                <td>{item.keyCount}</td>
                <td>{item.policyCount}</td>
                <td>{item.usageCount}</td>
                <td>{item.requestCount}</td>
                <td>{item.rejectedCount}</td>
                <td>{item.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>API Keys</strong>
            <div className="small">Kaynak: /publicapi-runtime/api/publicapi/api-keys</div>
          </div>
          <span className="badge">Gosterilen {filteredKeys.length} / {apiKeys.length}</span>
        </div>

        {apiKeys.length === 0 ? (
          <EmptyState
            title="API key kaydi yok"
            description="Henüz runtime.api_keys tablosunda API key bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Key Ref</th>
                <th>Display</th>
                <th>Prefix</th>
                <th>Status</th>
                <th>Scope</th>
                <th>Last Used</th>
                <th>Expires</th>
              </tr>
            </thead>
            <tbody>
              {filteredKeys.map((key) => (
                <tr key={key.keyRef}>
                  <td>{key.keyRef}</td>
                  <td>{key.displayName}</td>
                  <td>{key.keyPrefix || '-'}</td>
                  <td>
                    <span className={statusClassName(key.status)}>{key.status}</span>
                  </td>
                  <td>{key.visibilityScope}</td>
                  <td>{key.lastUsedAt || '-'}</td>
                  <td>{key.expiresAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Quota Policies</strong>
            <div className="small">Kaynak: /publicapi-runtime/api/publicapi/quota-policies</div>
          </div>
          <span className="badge">Gosterilen {filteredPolicies.length} / {quotaPolicies.length}</span>
        </div>

        {quotaPolicies.length === 0 ? (
          <EmptyState
            title="Quota policy kaydi yok"
            description="Henüz runtime.api_quota_policies tablosunda quota policy bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Policy</th>
                <th>Key Ref</th>
                <th>Endpoint</th>
                <th>Period</th>
                <th>Limit</th>
                <th>Burst</th>
                <th>Aktif</th>
              </tr>
            </thead>
            <tbody>
              {filteredPolicies.map((policy) => (
                <tr key={policy.policyKey}>
                  <td>{policy.policyKey}</td>
                  <td>{policy.keyRef || '-'}</td>
                  <td>{policy.endpointScope}</td>
                  <td>{policy.quotaPeriod}</td>
                  <td>{policy.requestLimit}</td>
                  <td>{policy.burstLimit}</td>
                  <td>{policy.isEnabled ? 'Evet' : 'Hayir'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>API Usage</strong>
            <div className="small">Kaynak: /publicapi-runtime/api/publicapi/usage</div>
          </div>
          <span className="badge">Gosterilen {filteredUsage.length} / {usage.length}</span>
        </div>

        {usage.length === 0 ? (
          <EmptyState
            title="API usage kaydi yok"
            description="Henüz runtime.api_key_usage tablosunda usage bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Key Ref</th>
                <th>Policy</th>
                <th>Window</th>
                <th>Request</th>
                <th>Rejected</th>
                <th>Last Request</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsage.map((item) => (
                <tr key={item.usageId}>
                  <td>{item.keyRef || '-'}</td>
                  <td>{item.policyKey || '-'}</td>
                  <td>{item.usageWindowStart || '-'} → {item.usageWindowEnd || '-'}</td>
                  <td>{item.requestCount}</td>
                  <td>{item.rejectedCount}</td>
                  <td>{item.lastRequestAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
