export type WebhookRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type WebhookSummaryItem = {
  status: string;
  count: number;
  endpointCount: number;
  attemptCount: number;
  generatedAt: string;
};

export type WebhookEndpointRow = {
  endpointKey: string;
  displayName: string;
  visibilityScope: string;
  targetUrl: string;
  httpMethod: string;
  authType: string;
  signatureHeader: string;
  timeoutSeconds: number;
  retryLimit: number;
  retryBackoffSeconds: number;
  isEnabled: boolean;
  deliveryCount: number;
  failedCount: number;
  deadLetterCount: number;
  updatedAt: string;
};

export type WebhookDeliveryRow = {
  deliveryId: string;
  endpointKey: string;
  deliveryKey: string;
  eventType: string;
  priority: string;
  status: string;
  responseCode: number;
  retryCount: number;
  maxAttempts: number;
  nextRetryAt: string;
  deliveredAt: string;
  deadLetteredAt: string;
  sourceRefType: string;
  sourceRefId: string;
  lastError: string;
  createdAt: string;
  updatedAt: string;
};

export type WebhookMonitorOverview = {
  health: WebhookRuntimeHealth;
  summary: WebhookSummaryItem[];
  endpoints: WebhookEndpointRow[];
  deliveries: WebhookDeliveryRow[];
  dlq: WebhookDeliveryRow[];
};
