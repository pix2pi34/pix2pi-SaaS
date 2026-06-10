export type NotificationRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type NotificationSummaryItem = {
  status: string;
  count: number;
  channelCount: number;
  notificationCount: number;
  recipientCount: number;
  deliveredCount: number;
  failedCount: number;
  generatedAt: string;
};

export type NotificationChannelRow = {
  channelKey: string;
  displayName: string;
  channelType: string;
  visibilityScope: string;
  providerKey: string;
  isEnabled: boolean;
  createdAt: string;
  updatedAt: string;
};

export type NotificationItemRow = {
  notificationId: string;
  channelKey: string;
  notificationKey: string;
  notificationType: string;
  priority: string;
  status: string;
  title: string;
  sourceRefType: string;
  sourceRefId: string;
  scheduledAt: string;
  sentAt: string;
  createdAt: string;
  updatedAt: string;
};

export type NotificationRecipientRow = {
  recipientId: string;
  notificationKey: string;
  recipientType: string;
  recipientKey: string;
  destination: string;
  deliveryStatus: string;
  errorMessage: string;
  deliveredAt: string;
  createdAt: string;
  updatedAt: string;
};

export type NotificationMonitorOverview = {
  health: NotificationRuntimeHealth;
  summary: NotificationSummaryItem[];
  channels: NotificationChannelRow[];
  items: NotificationItemRow[];
  recipients: NotificationRecipientRow[];
  dlq: NotificationRecipientRow[];
};
