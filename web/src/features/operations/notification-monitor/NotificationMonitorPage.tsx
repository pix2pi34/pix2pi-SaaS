import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState, ErrorState, LoadingState } from '../../../components/States';
import { useAuthStore } from '../../../core/auth/auth-store';
import { fetchNotificationMonitorOverview } from './notification-monitor-api';
import type {
  NotificationChannelRow,
  NotificationItemRow,
  NotificationRecipientRow,
} from './types';

function statusClassName(status: string): string {
  const normalized = status.toLowerCase();

  if (['sent', 'delivered', 'completed', 'enabled', 'active', 'queued', 'empty'].includes(normalized)) {
    return 'status-pill status-pill--up';
  }

  if (['failed', 'dead_letter', 'cancelled', 'disabled'].includes(normalized)) {
    return 'status-pill status-pill--down';
  }

  if (['pending', 'scheduled', 'processing', 'retry', 'claimed'].includes(normalized)) {
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

function filterChannels(rows: NotificationChannelRow[], query: string): NotificationChannelRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.channelKey,
        row.displayName,
        row.channelType,
        row.visibilityScope,
        row.providerKey,
      ],
      query,
    ),
  );
}

function filterItems(rows: NotificationItemRow[], query: string): NotificationItemRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.notificationId,
        row.channelKey,
        row.notificationKey,
        row.notificationType,
        row.priority,
        row.status,
        row.title,
        row.sourceRefType,
        row.sourceRefId,
      ],
      query,
    ),
  );
}

function filterRecipients(rows: NotificationRecipientRow[], query: string): NotificationRecipientRow[] {
  return rows.filter((row) =>
    includesAny(
      [
        row.recipientId,
        row.notificationKey,
        row.recipientType,
        row.recipientKey,
        row.destination,
        row.deliveryStatus,
        row.errorMessage,
      ],
      query,
    ),
  );
}

export function NotificationMonitorPage() {
  const [query, setQuery] = useState('');
  const session = useAuthStore((state) => state.session);

  const accessToken = session?.accessToken ?? '';
  const tenantId = session?.activeTenant.id ?? '';

  const notificationQuery = useQuery({
    queryKey: ['operations', 'notification-monitor', tenantId],
    queryFn: () => fetchNotificationMonitorOverview({ accessToken, tenantId }),
    enabled: accessToken !== '',
    retry: 1,
    retryDelay: 10,
  });

  const summary = notificationQuery.data?.summary ?? [];
  const channels = notificationQuery.data?.channels ?? [];
  const items = notificationQuery.data?.items ?? [];
  const recipients = notificationQuery.data?.recipients ?? [];
  const dlq = notificationQuery.data?.dlq ?? [];

  const filteredChannels = useMemo(() => filterChannels(channels, query), [channels, query]);
  const filteredItems = useMemo(() => filterItems(items, query), [items, query]);
  const filteredRecipients = useMemo(() => filterRecipients(recipients, query), [recipients, query]);
  const filteredDlq = useMemo(() => filterRecipients(dlq, query), [dlq, query]);

  const channelCount = summary[0]?.channelCount ?? channels.length;
  const notificationCount = summary[0]?.notificationCount ?? items.length;
  const recipientCount = summary[0]?.recipientCount ?? recipients.length;
  const deliveredCount = summary.reduce((acc, item) => acc + item.deliveredCount, 0);
  const failedCount = summary.reduce((acc, item) => acc + item.failedCount, 0);

  if (notificationQuery.isLoading || notificationQuery.isPending) {
    return <LoadingState message="Notification Monitor yukleniyor..." />;
  }

  if (notificationQuery.isError) {
    return (
      <ErrorState
        title="Notification Monitor okunamadi"
        description="Notification Runtime servisi, 5930 portu veya panel proxy kontrol edilmeli."
        retryAction={() => void notificationQuery.refetch()}
      />
    );
  }

  if (!notificationQuery.data) {
    return (
      <EmptyState
        title="Notification Monitor verisi bulunamadi"
        description="Notification Runtime endpoint bos dondu."
      />
    );
  }

  return (
    <div className="page-grid">
      <section className="card span-8">
        <div className="toolbar">
          <div>
            <strong>Notification Monitor</strong>
            <p className="small">
              Notification channel, queue item, recipient delivery ve DLQ durumlarini read-only izler.
            </p>
          </div>
          <button
            type="button"
            className="btn btn-secondary"
            onClick={() => void notificationQuery.refetch()}
          >
            Yenile
          </button>
        </div>

        <div className="button-row">
          <span className="badge">Runtime {notificationQuery.data.health.status.toUpperCase()}</span>
          <span className="badge">DB {notificationQuery.data.health.db.toUpperCase()}</span>
          <span className="badge">Channel {channelCount}</span>
          <span className="badge">Notification {notificationCount}</span>
          <span className="badge">Recipient {recipientCount}</span>
          <span className="badge">Delivered {deliveredCount}</span>
          <span className="badge">Failed {failedCount}</span>
          <span className="badge">DLQ {dlq.length}</span>
        </div>
      </section>

      <section className="card span-4">
        <strong>Profesyonel Not</strong>
        <p className="small">
          Bu ekran monitor/read-only modda calisir. Gercek notification sender/worker ayri akista kalir.
        </p>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Durum Ozeti</strong>
            <div className="small">Kaynak: /notification-runtime/api/notifications/summary</div>
          </div>
          <input
            aria-label="Notification ara"
            placeholder="Channel, notification, recipient veya hata ara"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>

        <table className="data-table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Adet</th>
              <th>Channel</th>
              <th>Notification</th>
              <th>Recipient</th>
              <th>Delivered</th>
              <th>Failed</th>
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
                <td>{item.channelCount}</td>
                <td>{item.notificationCount}</td>
                <td>{item.recipientCount}</td>
                <td>{item.deliveredCount}</td>
                <td>{item.failedCount}</td>
                <td>{item.generatedAt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Notification Channels</strong>
            <div className="small">Kaynak: /notification-runtime/api/notifications/channels</div>
          </div>
          <span className="badge">Gosterilen {filteredChannels.length} / {channels.length}</span>
        </div>

        {channels.length === 0 ? (
          <EmptyState
            title="Notification channel kaydi yok"
            description="Henüz runtime.notification_channels tablosunda channel bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Channel</th>
                <th>Display</th>
                <th>Type</th>
                <th>Scope</th>
                <th>Provider</th>
                <th>Aktif</th>
              </tr>
            </thead>
            <tbody>
              {filteredChannels.map((channel) => (
                <tr key={channel.channelKey}>
                  <td>{channel.channelKey}</td>
                  <td>{channel.displayName}</td>
                  <td>{channel.channelType}</td>
                  <td>{channel.visibilityScope}</td>
                  <td>{channel.providerKey || '-'}</td>
                  <td>{channel.isEnabled ? 'Evet' : 'Hayir'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Notification Items</strong>
            <div className="small">Kaynak: /notification-runtime/api/notifications/items</div>
          </div>
          <span className="badge">Gosterilen {filteredItems.length} / {items.length}</span>
        </div>

        {items.length === 0 ? (
          <EmptyState
            title="Notification kaydi yok"
            description="Henüz runtime.notifications tablosunda notification bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Notification</th>
                <th>Channel</th>
                <th>Type</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Title</th>
                <th>Scheduled</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => (
                <tr key={item.notificationId}>
                  <td>{item.notificationKey}</td>
                  <td>{item.channelKey || '-'}</td>
                  <td>{item.notificationType}</td>
                  <td>{item.priority}</td>
                  <td>
                    <span className={statusClassName(item.status)}>{item.status}</span>
                  </td>
                  <td>{item.title || '-'}</td>
                  <td>{item.scheduledAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Recipient Deliveries</strong>
            <div className="small">Kaynak: /notification-runtime/api/notifications/recipients</div>
          </div>
          <span className="badge">Gosterilen {filteredRecipients.length} / {recipients.length}</span>
        </div>

        {recipients.length === 0 ? (
          <EmptyState
            title="Recipient delivery kaydi yok"
            description="Henüz runtime.notification_recipients tablosunda recipient bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Notification</th>
                <th>Recipient</th>
                <th>Type</th>
                <th>Destination</th>
                <th>Status</th>
                <th>Delivered</th>
                <th>Hata</th>
              </tr>
            </thead>
            <tbody>
              {filteredRecipients.map((recipient) => (
                <tr key={recipient.recipientId}>
                  <td>{recipient.notificationKey || '-'}</td>
                  <td>{recipient.recipientKey}</td>
                  <td>{recipient.recipientType}</td>
                  <td>{recipient.destination}</td>
                  <td>
                    <span className={statusClassName(recipient.deliveryStatus)}>
                      {recipient.deliveryStatus}
                    </span>
                  </td>
                  <td>{recipient.deliveredAt || '-'}</td>
                  <td>{recipient.errorMessage || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card span-12">
        <div className="toolbar">
          <div>
            <strong>Notification DLQ</strong>
            <div className="small">Kaynak: /notification-runtime/api/notifications/dlq</div>
          </div>
          <span className="badge">Gosterilen {filteredDlq.length} / {dlq.length}</span>
        </div>

        {dlq.length === 0 ? (
          <EmptyState
            title="Notification DLQ kaydi yok"
            description="Dead-letter veya failed notification recipient bulunmuyor."
          />
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Notification</th>
                <th>Recipient</th>
                <th>Destination</th>
                <th>Status</th>
                <th>Hata</th>
                <th>Updated</th>
              </tr>
            </thead>
            <tbody>
              {filteredDlq.map((recipient) => (
                <tr key={recipient.recipientId}>
                  <td>{recipient.notificationKey || '-'}</td>
                  <td>{recipient.recipientKey}</td>
                  <td>{recipient.destination}</td>
                  <td>
                    <span className={statusClassName(recipient.deliveryStatus)}>
                      {recipient.deliveryStatus}
                    </span>
                  </td>
                  <td>{recipient.errorMessage || '-'}</td>
                  <td>{recipient.updatedAt || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
