export type PublicAPIRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type PublicAPISummaryItem = {
  status: string;
  count: number;
  keyCount: number;
  policyCount: number;
  usageCount: number;
  requestCount: number;
  rejectedCount: number;
  generatedAt: string;
};

export type APIKeyRow = {
  keyRef: string;
  displayName: string;
  visibilityScope: string;
  keyPrefix: string;
  status: string;
  lastUsedAt: string;
  expiresAt: string;
  revokedAt: string;
  createdAt: string;
  updatedAt: string;
};

export type APIQuotaPolicyRow = {
  policyKey: string;
  keyRef: string;
  endpointScope: string;
  quotaPeriod: string;
  requestLimit: number;
  burstLimit: number;
  isEnabled: boolean;
  createdAt: string;
  updatedAt: string;
};

export type APIUsageRow = {
  usageId: string;
  keyRef: string;
  policyKey: string;
  usageWindowStart: string;
  usageWindowEnd: string;
  requestCount: number;
  rejectedCount: number;
  lastRequestAt: string;
  createdAt: string;
  updatedAt: string;
};

export type PublicAPIMonitorOverview = {
  health: PublicAPIRuntimeHealth;
  summary: PublicAPISummaryItem[];
  apiKeys: APIKeyRow[];
  quotaPolicies: APIQuotaPolicyRow[];
  usage: APIUsageRow[];
};
