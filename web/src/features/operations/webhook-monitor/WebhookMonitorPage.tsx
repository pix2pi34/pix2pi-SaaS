import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchWebhookMonitorOverview } from './webhook-monitor-api';
import type { WebhookDeliveryRow, WebhookEndpointRow } from './types';

function statusClassName(status: string): string {
  const normalized = status.toLowerCase();

  if (['succeeded', 'delivered', 'queued', 'empty'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['failed', 'dead_letter', 'cancelled'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['processing', 'scheduled', 'retry'].includes(normalized)) {
    return 'status-pill status-pill--degraded';
  }

  return 'status-pill status-pill--unknown';
}

function filterEndpoints(rows: WebhookEndpointRow[], query: string): WebhookEndpointRow[] {
  const trimmed = query.trim().toLowerCase();

  if (!trimmed) {
    return rows;
  }

  return rows.filter((row) =>
    [
      row.endpointKey,
      row.displayName,
      row.visibilityScope,
      row.targetUrl,
      row.httpMethod,
      row.authType,
      row.signatureHeader,
      row.updatedAt,
    ].some((value) => value.toLowerCase().includes(trimmed)),
  );
}

function filterDeliveries(rows: WebhookDeliveryRow[], query: string): WebhookDeliveryRow[] {
  const trimmed = query.trim().toLowerCase();

  if (!trimmed) {
    return rows;
  }

  return rows.filter((row) =>
    [
      row.deliveryId,
      row.endpointKey,
      row.deliveryKey,
      row.eventType,
      row.priority,
      row.status,
      row.sourceRefType,
      row.sourceRefId,
      row.lastError,
    ].some((value) => value.toLowerCase().includes(trimmed)),
  );
}

export function WebhookMonitorPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const webhookQuery = useQuery({
    queryKey: ['operations', 'webhook-monitor', tenantId],
    queryFn: () => fetchWebhookMonitorOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = webhookQuery.data?.summary ?? [];
  const endpoints = webhookQuery.data?.endpoints ?? [];
  const deliveries = webhookQuery.data?.deliveries ?? [];
  const dlq = webhookQuery.data?.dlq ?? [];

  const filteredEndpoints = useMemo(() => filterEndpoints(endpoints, query), [endpoints, query]);
  const filteredDeliveries = useMemo(() => filterDeliveries(deliveries, query), [deliveries, query]);
  const filteredDlq = useMemo(() => filterDeliveries(dlq, query), [dlq, query]);

  const totalDeliveries = summary.reduce((acc, item) => acc + item.count, 0);
  const endpointCount = summary[0]?.endpointCount ?? endpoints.length;
  const attemptCount = summary[0]?.attemptCount ?? 0;

  if (webhookQuery.isLoading || webhookQuery.isPending) {
    return <LoadingState message="Webhook Monitor yukleniyor..." />;
  }

  if (webhookQuery.isError) {
    return (
      <ErrorState
        title="Webhook Monitor okunamadi"
        description="Webhook Runtime servisi, 5890 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void webhookQuery.refetch()}
      />
    );
  }

  if (!webhookQuery.data) {
    return (
      <EmptyState
        title="Webhook Monitor verisi bulunamadi"
        description="Webhook Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Webhook Monitor</strong>
            <p className="small">
              Webhook endpointlerini, delivery durumlarini, retry/DLQ akislarini ve imza tabanli gonderim izlerini takip eder.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void webhookQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className="badge">Runtime {webhookQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {webhookQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Endpoint {endpointCount}</span>
          <span className="badge">Delivery {totalDeliveries}</span>
          <span className="badge">Attempt {attemptCount}</span>
          <span className="badge">DLQ {dlq.length}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran monitor/read-only modda calisir. Gercek webhook sender/worker ayri asamada kontrollu acilacak.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Durum Ozeti</strong>
            <div className="small">Kaynak: /webhook-runtime/api/webhooks/summary</div>
          </div>
          <input
            aria-label="Webhook ara"
            placeholder="Endpoint veya delivery ara"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Adet</th>
              <th>Endpoint Sayisi</th>
              <th>Attempt Sayisi</th>
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
                <td>{item.endpointCount}</td>
                <td>{item.attemptCount}</td>
                <td>{item.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Webhook Endpointleri</strong>
            <div className="small">Kaynak: /webhook-runtime/api/webhooks/endpoints</div>
          </div>
          <span className="badge">Gosterilen {filteredEndpoints.length} / {endpoints.length}</span>
        </div>

        {endpoints.length === 0 ? (
          <EmptyState
            title="Webhook endpoint kaydi yok"
            description="Henüz runtime.webhook_endpoints tablosunda endpoint bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Endpoint</th>
                <th>Method</th>
                <th>Auth</th>
                <th>Signature Header</th>
                <th>Aktif</th>
                <th>Delivery</th>
                <th>Failed</th>
                <th>DLQ</th>
              </tr>
            </thead>
            <tbody>
              {filteredEndpoints.map((endpoint) => (
                <tr key={endpoint.endpointKey}>
                  <td>{endpoint.endpointKey}</td>
                  <td>{endpoint.httpMethod}</td>
                  <td>{endpoint.authType}</td>
                  <td>{endpoint.signatureHeader || '-'}</td>
                  <td>{endpoint.isEnabled ? 'Evet' : 'Hayir'}</td>
                  <td>{endpoint.deliveryCount}</td>
                  <td>{endpoint.failedCount}</td>
                  <td>{endpoint.deadLetterCount}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Son Webhook Delivery Kayitlari</strong>
            <div className="small">Kaynak: /webhook-runtime/api/webhooks/deliveries</div>
          </div>
          <span className="badge">Gosterilen {filteredDeliveries.length} / {deliveries.length}</span>
        </div>

        {deliveries.length === 0 ? (
          <EmptyState
            title="Webhook delivery kaydi yok"
            description="Henüz runtime.webhook_deliveries tablosunda delivery bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Delivery</th>
                <th>Endpoint</th>
                <th>Event</th>
                <th>Priority</th>
                <th>Status</th>
                <th>HTTP</th>
                <th>Retry</th>
                <th>Olusturma</th>
              </tr>
            </thead>
            <tbody>
              {filteredDeliveries.map((delivery) => (
                <tr key={delivery.deliveryId}>
                  <td>{delivery.deliveryKey}</td>
                  <td>{delivery.endpointKey || '-'}</td>
                  <td>{delivery.eventType}</td>
                  <td>{delivery.priority}</td>
                  <td>
                    <span className={statusClassName(delivery.status)}>{delivery.status}</span>
                  </td>
                  <td>{delivery.responseCode || '-'}</td>
                  <td>{delivery.retryCount} / {delivery.maxAttempts}</td>
                  <td>{delivery.createdAt}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Webhook DLQ</strong>
            <div className="small">Kaynak: /webhook-runtime/api/webhooks/dlq</div>
          </div>
          <span className="badge">Gosterilen {filteredDlq.length} / {dlq.length}</span>
        </div>

        {dlq.length === 0 ? (
          <EmptyState
            title="DLQ kaydi yok"
            description="Dead-letter durumuna dusen webhook delivery kaydi bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Delivery</th>
                <th>Endpoint</th>
                <th>Event</th>
                <th>Hata</th>
                <th>Dead Letter Zamani</th>
              </tr>
            </thead>
            <tbody>
              {filteredDlq.map((delivery) => (
                <tr key={delivery.deliveryId}>
                  <td>{delivery.deliveryKey}</td>
                  <td>{delivery.endpointKey || '-'}</td>
                  <td>{delivery.eventType}</td>
                  <td>{delivery.lastError || '-'}</td>
                  <td>{delivery.deadLetteredAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
