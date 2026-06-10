import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchMissionControlOverview } from './mission-control-api';
import type { MissionControlServiceCard, MissionControlStatus } from './types';

function statusLabel(status: MissionControlStatus): string {
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

function statusClassName(status: MissionControlStatus): string {
  return `status-pill status-pill--${status.toLowerCase()}`;
}

function countByStatus(rows: MissionControlServiceCard[], status: MissionControlStatus): number {
  return rows.filter((row) => row.status === status).length;
}

export function MissionControlPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const missionQuery = useQuery({
    queryKey: ['operations', 'mission-control', tenantId],
    queryFn: () => fetchMissionControlOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const services = missionQuery.data?.services ?? [];

  const filteredServices = useMemo(() => {
    const trimmed = query.trim().toLowerCase();

    if (!trimmed) {
      return services;
    }

    return services.filter((service) =>
      [
        service.serviceName,
        service.status,
        service.category,
        service.lastCheckedAt,
      ].some((value) => value.toLowerCase().includes(trimmed)),
    );
  }, [query, services]);

  if (missionQuery.isLoading || missionQuery.isPending) {
    return <LoadingState message="Mission Control yukleniyor..." />;
  }

  if (missionQuery.isError) {
    return (
      <ErrorState
        title="Mission Control okunamadi"
        description="Mission Control proxy, 5860 servisi veya panel upstream kontrol edilmeli."
        retryAction={() => void missionQuery.refetch()}
      />
    );
  }

  if (!missionQuery.data || services.length === 0) {
    return (
      <EmptyState
        title="Mission Control kaydi bulunamadi"
        description="Mission Control servis listesi bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Mission Control</strong>
            <p className="small">
              Platform runtime merkezini, servis sagligini ve operasyon komuta durumunu izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void missionQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className="badge">Servis: {missionQuery.data.health.service}</span>
          <span className="badge">Health {missionQuery.data.health.ok ? 'OK' : 'FAIL'}</span>
          <span className="badge">UP {countByStatus(services, 'UP')}</span>
          <span className="badge">DOWN {countByStatus(services, 'DOWN')}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Operasyon Durumu</strong>
        <p className="small">
          Mission Control binary servis olarak calisiyor. Panel bu ekrana /mission-control proxy uzerinden baglanir.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Runtime Komuta Servisleri</strong>
            <div className="small">Kaynak: /mission-control/api/services</div>
          </div>
          <input
            aria-label="Mission servis ara"
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
              <th>Kategori</th>
              <th>Son Kontrol</th>
            </tr>
          </thead>
          <tbody>
            {filteredServices.map((service) => (
              <tr key={service.serviceName}>
                <td>{service.serviceName}</td>
                <td>
                  <span className={statusClassName(service.status)}>
                    {statusLabel(service.status)}
                  </span>
                </td>
                <td>{service.category}</td>
                <td>{service.lastCheckedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="toolbar" style={{ marginTop: 16 }}>
          <span className="small">Gosterilen {filteredServices.length} / {services.length} servis</span>
          <span className="small">Uretim zamani: {missionQuery.data.generatedAt}</span>
        </div>
      </section>
    </div>
  );
}
