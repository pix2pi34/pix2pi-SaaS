export type IncidentAuditRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type IncidentAuditSummaryItem = {
  alertLevel: string;
  incidentCount: number;
  openIncidentCount: number;
  criticalIncidentCount: number;
  auditEventCount: number;
  auditLogCount: number;
  recentAuditLogCount: number;
  generatedAt: string;
};

export type IncidentRow = {
  incidentId: string;
  tenantId: string;
  businessCode: string;
  incidentKey: string;
  title: string;
  summary: string;
  severity: string;
  status: string;
  source: string;
  ownerTeam: string;
  openedBy: string;
  acknowledgedBy: string;
  resolvedBy: string;
  detectedAt: string;
  acknowledgedAt: string;
  resolvedAt: string;
  closedAt: string;
  createdAt: string;
  updatedAt: string;
};

export type AuditEventRow = {
  eventId: string;
  tenantId: string;
  actorUserId: string;
  eventCode: string;
  entitySchema: string;
  entityTable: string;
  entityId: string;
  payload: string;
  createdAt: string;
};

export type AuditLogRow = {
  logId: number;
  tenantId: string;
  actorType: string;
  actorId: string;
  action: string;
  entityType: string;
  entityId: string;
  status: string;
  details: string;
  createdAt: string;
};

export type TimelineRow = {
  source: string;
  refId: string;
  title: string;
  status: string;
  severity: string;
  actor: string;
  entity: string;
  createdAt: string;
};

export type IncidentAuditOverview = {
  health: IncidentAuditRuntimeHealth;
  summary: IncidentAuditSummaryItem[];
  incidents: IncidentRow[];
  auditEvents: AuditEventRow[];
  auditLogs: AuditLogRow[];
  timeline: TimelineRow[];
};
