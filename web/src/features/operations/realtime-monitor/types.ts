export type RealtimeRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type RealtimeSummaryItem = {
  status: string;
  channelCount: number;
  connectionCount: number;
  activeConnectionCount: number;
  webSocketCount: number;
  sseCount: number;
  presenceCount: number;
  onlinePresenceCount: number;
  channelPermissionCount: number;
  generatedAt: string;
};

export type RealtimeTableStatusItem = {
  tableName: string;
  exists: boolean;
  count: number;
  generatedAt: string;
};

export type RealtimeGenericRow = {
  tableName: string;
  recordJSON: string;
  observedAt: string;
};

export type RealtimeOverview = {
  health: RealtimeRuntimeHealth;
  summary: RealtimeSummaryItem[];
  tables: RealtimeTableStatusItem[];
  channels: RealtimeGenericRow[];
  connections: RealtimeGenericRow[];
  presence: RealtimeGenericRow[];
  permissions: RealtimeGenericRow[];
};
