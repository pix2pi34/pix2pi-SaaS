export type EarlyWarningRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type EarlyWarningSummaryItem = {
  alertLevel: string;
  serviceCount: number;
  serviceOKCount: number;
  serviceFailCount: number;
  resourceCount: number;
  signalCount: number;
  warningCount: number;
  criticalCount: number;
  incidentCount: number;
  generatedAt: string;
};

export type EarlyWarningServiceItem = {
  serviceKey: string;
  display: string;
  status: string;
  httpStatus: number;
  latencyMs: number;
  message: string;
  checkedAt: string;
};

export type EarlyWarningResourceItem = {
  resourceKey: string;
  display: string;
  value: number;
  unit: string;
  usedPercent: number;
  level: string;
  message: string;
  checkedAt: string;
};

export type EarlyWarningSignalItem = {
  signalKey: string;
  category: string;
  level: string;
  status: string;
  message: string;
  generatedAt: string;
};

export type EarlyWarningIncidentItem = {
  tableName: string;
  count: number;
  generatedAt: string;
};

export type EarlyWarningOverview = {
  health: EarlyWarningRuntimeHealth;
  summary: EarlyWarningSummaryItem[];
  services: EarlyWarningServiceItem[];
  resources: EarlyWarningResourceItem[];
  signals: EarlyWarningSignalItem[];
  incidents: EarlyWarningIncidentItem[];
};
