import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchServiceRegistry } from './service-registry-api';
import type { ServiceRegistryInstance, ServiceRegistryStatus } from './types';

function statusLabel(status: ServiceRegistryStatus): string {
  switch (status) {
    case 'UP':
      return 'Calisiyor';
    case 'DOWN':
      return 'Kapali';
    case 'DEGRADED':
      return 'Riskli';
    default:
      return 'Bilinmiyor';
  }
}

function statusClassName(status: ServiceRegistryStatus): string {
  return `status-pill status-pill--${status.toLowerCase()}`;
}

function countByStatus(rows: ServiceRegistryInstance[], status: ServiceRegistryStatus): number {
  return rows.filter((row) => row.status === status).length;
}

export function ServiceRegistryPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const serviceQuery = useQuery({
    queryKey: ['operations', 'service-registry', tenantId],
    queryFn: () => fetchServiceRegistry({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const rows = serviceQuery.data ?? [];

  const filteredRows = useMemo(() => {
    const trimmed = query.trim().toLowerCase();

    if (!trimmed) {
      return rows;
    }

    return rows.filter((row) =>
      [
        row.serviceName,
        row.instanceId,
        row.status,
        row.endpoint,
        row.node,
        row.version,
        row.tenantVisibility,
      ].some((value) => value.toLowerCase().includes(trimmed)),
    );
  }, [query, rows]);

  if (serviceQuery.isLoading || serviceQuery.isPending) {
    return <LoadingState message="Service registry yukleniyor..." />;
  }

  if (serviceQuery.isError) {
    return (
      <ErrorState
        title="Service registry okunamadi"
        description="Runtime servis listesi alinamadi. API gateway veya service-registry endpoint kontrol edilmeli."
        retryAction={() => void serviceQuery.refetch()}
      />
    );
  }

  if (rows.length === 0) {
    return (
      <EmptyState
        title="Servis kaydi bulunamadi"
        description="Service registry endpoint bos dondu. Servisler heartbeat gondermeye baslayinca burada gorunecek."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Service Registry</strong>
            <p className="small">
              Platform servislerinin runtime durumunu, instance bilgisini ve son heartbeat gorunumunu izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void serviceQuery.refetch()}
          >
            Yenile
          </button>
        </div>
        <div className="button-row">
          <span className="badge">Toplam {rows.length} servis</span>
          <span className="badge">UP {countByStatus(rows, 'UP')}</span>
          <span className="badge">DOWN {countByStatus(rows, 'DOWN')}</span>
          <span className="badge">DEGRADED {countByStatus(rows, 'DEGRADED')}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Operasyon Notu</strong>
        <p className="small">
          Bu ekran WEB-L3 operasyon konsolunun ilk parcasidir. Sonraki ekranlar Mission Control, Jobs, Webhook ve Workflow monitor ile ayni yapida buyuyecek.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Servis Instance Listesi</strong>
            <div className="small">Tenant-safe runtime gorunurluk ve heartbeat kontrol tablosu</div>
          </div>
          <input
            aria-label="Servis ara"
            placeholder="Servis ara"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Servis</th>
              <th>Durum</th>
              <th>Instance</th>
              <th>Endpoint</th>
              <th>Node</th>
              <th>Version</th>
              <th>Tenant Gorunurluk</th>
              <th>Son Heartbeat</th>
            </tr>
          </thead>
          <tbody>
            {filteredRows.map((row) => (
              <tr key={`${row.serviceName}-${row.instanceId}`}>
                <td>{row.serviceName}</td>
                <td>
                  <span className={statusClassName(row.status)}>{statusLabel(row.status)}</span>
                </td>
                <td>{row.instanceId}</td>
                <td>{row.endpoint}</td>
                <td>{row.node}</td>
                <td>{row.version}</td>
                <td>{row.tenantVisibility}</td>
                <td>{row.lastHeartbeatAt}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="toolbar" style={{ marginTop: 16 }}>
          <span className="small">Gosterilen {filteredRows.length} / {rows.length} servis</span>
          <span className="small">Kaynak: /api/services</span>
        </div>
      </section>
    </div>
  );
}
