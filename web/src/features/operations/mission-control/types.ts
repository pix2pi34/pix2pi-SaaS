export type MissionControlStatus = 'UP' | 'DOWN' | 'DEGRADED' | 'UNKNOWN';

export type MissionControlServiceCard = {
  serviceName: string;
  status: MissionControlStatus;
  category: string;
  lastCheckedAt: string;
};

export type MissionControlHealth = {
  ok: boolean;
  service: string;
};

export type MissionControlOverview = {
  health: MissionControlHealth;
  services: MissionControlServiceCard[];
  generatedAt: string;
};
