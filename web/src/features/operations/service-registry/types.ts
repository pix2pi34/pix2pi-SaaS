export type ServiceRegistryStatus = 'UP' | 'DOWN' | 'DEGRADED' | 'UNKNOWN';

export type ServiceRegistryInstance = {
  serviceName: string;
  instanceId: string;
  status: ServiceRegistryStatus;
  endpoint: string;
  node: string;
  version: string;
  lastHeartbeatAt: string;
  tenantVisibility: string;
};
