import type {
  NotificationChannelRow,
  NotificationItemRow,
  NotificationMonitorOverview,
  NotificationRecipientRow,
  NotificationRuntimeHealth,
  NotificationSummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type NotificationMonitorFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: NotificationMonitorFetchOptions): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: 'application/json',
  };

  if (options.accessToken) {
    headers.Authorization = `Bearer ${options.accessToken}`;
  }

  if (options.tenantId) {
    headers['X-Tenant-ID'] = options.tenantId;
  }

  return headers;
}

function asText(value: unknown, fallback = ''): string {
  if (typeof value === 'string') {
    return value;
  }

  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }

  return fallback;
}

function asNumber(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

function asBool(value: unknown): boolean {
  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'string') {
    return value.toLowerCase() === 'true';
  }

  return false;
}

function listFromPayload(payload: unknown): Record<string, unknown>[] {
  if (!payload || typeof payload !== 'object') {
    return [];
  }

  const obj = payload as Record<string, unknown>;
  const items = obj.items;

  if (!Array.isArray(items)) {
    return [];
  }

  return items.filter(
    (item): item is Record<string, unknown> =>
      Boolean(item) && typeof item === 'object' && !Array.isArray(item),
  );
}

function normalizeSummaryItem(raw: Record<string, unknown>): NotificationSummaryItem {
  return {
    status: asText(raw.status, 'unknown'),
    count: asNumber(raw.count),
    channelCount: asNumber(raw.channel_count ?? raw.channelCount),
    notificationCount: asNumber(raw.notification_count ?? raw.notificationCount),
    recipientCount: asNumber(raw.recipient_count ?? raw.recipientCount),
    deliveredCount: asNumber(raw.delivered_count ?? raw.deliveredCount),
    failedCount: asNumber(raw.failed_count ?? raw.failedCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeChannelRow(raw: Record<string, unknown>): NotificationChannelRow {
  return {
    channelKey: asText(raw.channel_key ?? raw.channelKey, '-'),
    displayName: asText(raw.display_name ?? raw.displayName, '-'),
    channelType: asText(raw.channel_type ?? raw.channelType, '-'),
    visibilityScope: asText(raw.visibility_scope ?? raw.visibilityScope, '-'),
    providerKey: asText(raw.provider_key ?? raw.providerKey, ''),
    isEnabled: asBool(raw.is_enabled ?? raw.isEnabled),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeItemRow(raw: Record<string, unknown>): NotificationItemRow {
  return {
    notificationId: asText(raw.notification_id ?? raw.notificationId, '-'),
    channelKey: asText(raw.channel_key ?? raw.channelKey, '-'),
    notificationKey: asText(raw.notification_key ?? raw.notificationKey, '-'),
    notificationType: asText(raw.notification_type ?? raw.notificationType, '-'),
    priority: asText(raw.priority, '-'),
    status: asText(raw.status, '-'),
    title: asText(raw.title, '-'),
    sourceRefType: asText(raw.source_ref_type ?? raw.sourceRefType, ''),
    sourceRefId: asText(raw.source_ref_id ?? raw.sourceRefId, ''),
    scheduledAt: asText(raw.scheduled_at ?? raw.scheduledAt, ''),
    sentAt: asText(raw.sent_at ?? raw.sentAt, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeRecipientRow(raw: Record<string, unknown>): NotificationRecipientRow {
  return {
    recipientId: asText(raw.recipient_id ?? raw.recipientId, '-'),
    notificationKey: asText(raw.notification_key ?? raw.notificationKey, '-'),
    recipientType: asText(raw.recipient_type ?? raw.recipientType, '-'),
    recipientKey: asText(raw.recipient_key ?? raw.recipientKey, '-'),
    destination: asText(raw.destination, '-'),
    deliveryStatus: asText(raw.delivery_status ?? raw.deliveryStatus, '-'),
    errorMessage: asText(raw.error_message ?? raw.errorMessage, ''),
    deliveredAt: asText(raw.delivered_at ?? raw.deliveredAt, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

export function normalizeNotificationSummary(payload: unknown): NotificationSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeNotificationChannels(payload: unknown): NotificationChannelRow[] {
  return listFromPayload(payload).map(normalizeChannelRow);
}

export function normalizeNotificationItems(payload: unknown): NotificationItemRow[] {
  return listFromPayload(payload).map(normalizeItemRow);
}

export function normalizeNotificationRecipients(payload: unknown): NotificationRecipientRow[] {
  return listFromPayload(payload).map(normalizeRecipientRow);
}

export async function fetchNotificationMonitorOverview(
  options: NotificationMonitorFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<NotificationMonitorOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, channelsResponse, itemsResponse, recipientsResponse, dlqResponse] =
    await Promise.all([
      fetcher('/notification-runtime/health', { headers }),
      fetcher('/notification-runtime/api/notifications/summary', { headers }),
      fetcher('/notification-runtime/api/notifications/channels?limit=50', { headers }),
      fetcher('/notification-runtime/api/notifications/items?limit=50', { headers }),
      fetcher('/notification-runtime/api/notifications/recipients?limit=50', { headers }),
      fetcher('/notification-runtime/api/notifications/dlq?limit=50', { headers }),
    ]);

  if (!healthResponse.ok) {
    throw new Error(`notification runtime health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`notification summary okunamadi: ${summaryResponse.status}`);
  }

  if (!channelsResponse.ok) {
    throw new Error(`notification channels okunamadi: ${channelsResponse.status}`);
  }

  if (!itemsResponse.ok) {
    throw new Error(`notification items okunamadi: ${itemsResponse.status}`);
  }

  if (!recipientsResponse.ok) {
    throw new Error(`notification recipients okunamadi: ${recipientsResponse.status}`);
  }

  if (!dlqResponse.ok) {
    throw new Error(`notification dlq okunamadi: ${dlqResponse.status}`);
  }

  const health = await healthResponse.json() as NotificationRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const channelsPayload = await channelsResponse.json();
  const itemsPayload = await itemsResponse.json();
  const recipientsPayload = await recipientsResponse.json();
  const dlqPayload = await dlqResponse.json();

  return {
    health,
    summary: normalizeNotificationSummary(summaryPayload),
    channels: normalizeNotificationChannels(channelsPayload),
    items: normalizeNotificationItems(itemsPayload),
    recipients: normalizeNotificationRecipients(recipientsPayload),
    dlq: normalizeNotificationRecipients(dlqPayload),
  };
}
