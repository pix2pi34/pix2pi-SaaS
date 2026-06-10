import type {
  AuditEventRow,
  AuditLogRow,
  IncidentAuditOverview,
  IncidentAuditRuntimeHealth,
  IncidentAuditSummaryItem,
  IncidentRow,
  TimelineRow,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type IncidentAuditFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: IncidentAuditFetchOptions): Record<string, string> {
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

function normalizeSummaryItem(raw: Record<string, unknown>): IncidentAuditSummaryItem {
  return {
    alertLevel: asText(raw.alert_level ?? raw.alertLevel, 'unknown'),
    incidentCount: asNumber(raw.incident_count ?? raw.incidentCount),
    openIncidentCount: asNumber(raw.open_incident_count ?? raw.openIncidentCount),
    criticalIncidentCount: asNumber(raw.critical_incident_count ?? raw.criticalIncidentCount),
    auditEventCount: asNumber(raw.audit_event_count ?? raw.auditEventCount),
    auditLogCount: asNumber(raw.audit_log_count ?? raw.auditLogCount),
    recentAuditLogCount: asNumber(raw.recent_audit_log_count ?? raw.recentAuditLogCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeIncidentRow(raw: Record<string, unknown>): IncidentRow {
  return {
    incidentId: asText(raw.incident_id ?? raw.incidentId, '-'),
    tenantId: asText(raw.tenant_id ?? raw.tenantId, '-'),
    businessCode: asText(raw.business_code ?? raw.businessCode, '-'),
    incidentKey: asText(raw.incident_key ?? raw.incidentKey, '-'),
    title: asText(raw.title, '-'),
    summary: asText(raw.summary, ''),
    severity: asText(raw.severity, '-'),
    status: asText(raw.status, '-'),
    source: asText(raw.source, ''),
    ownerTeam: asText(raw.owner_team ?? raw.ownerTeam, ''),
    openedBy: asText(raw.opened_by ?? raw.openedBy, ''),
    acknowledgedBy: asText(raw.acknowledged_by ?? raw.acknowledgedBy, ''),
    resolvedBy: asText(raw.resolved_by ?? raw.resolvedBy, ''),
    detectedAt: asText(raw.detected_at ?? raw.detectedAt, ''),
    acknowledgedAt: asText(raw.acknowledged_at ?? raw.acknowledgedAt, ''),
    resolvedAt: asText(raw.resolved_at ?? raw.resolvedAt, ''),
    closedAt: asText(raw.closed_at ?? raw.closedAt, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeAuditEventRow(raw: Record<string, unknown>): AuditEventRow {
  return {
    eventId: asText(raw.event_id ?? raw.eventId, '-'),
    tenantId: asText(raw.tenant_id ?? raw.tenantId, '-'),
    actorUserId: asText(raw.actor_user_id ?? raw.actorUserId, ''),
    eventCode: asText(raw.event_code ?? raw.eventCode, '-'),
    entitySchema: asText(raw.entity_schema ?? raw.entitySchema, ''),
    entityTable: asText(raw.entity_table ?? raw.entityTable, ''),
    entityId: asText(raw.entity_id ?? raw.entityId, ''),
    payload: asText(raw.payload, '{}'),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
  };
}

function normalizeAuditLogRow(raw: Record<string, unknown>): AuditLogRow {
  return {
    logId: asNumber(raw.log_id ?? raw.logId),
    tenantId: asText(raw.tenant_id ?? raw.tenantId, '-'),
    actorType: asText(raw.actor_type ?? raw.actorType, '-'),
    actorId: asText(raw.actor_id ?? raw.actorId, '-'),
    action: asText(raw.action, '-'),
    entityType: asText(raw.entity_type ?? raw.entityType, '-'),
    entityId: asText(raw.entity_id ?? raw.entityId, '-'),
    status: asText(raw.status, '-'),
    details: asText(raw.details, '{}'),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
  };
}

function normalizeTimelineRow(raw: Record<string, unknown>): TimelineRow {
  return {
    source: asText(raw.source, '-'),
    refId: asText(raw.ref_id ?? raw.refId, '-'),
    title: asText(raw.title, '-'),
    status: asText(raw.status, '-'),
    severity: asText(raw.severity, ''),
    actor: asText(raw.actor, ''),
    entity: asText(raw.entity, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
  };
}

export function normalizeIncidentAuditSummary(payload: unknown): IncidentAuditSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeIncidents(payload: unknown): IncidentRow[] {
  return listFromPayload(payload).map(normalizeIncidentRow);
}

export function normalizeAuditEvents(payload: unknown): AuditEventRow[] {
  return listFromPayload(payload).map(normalizeAuditEventRow);
}

export function normalizeAuditLogs(payload: unknown): AuditLogRow[] {
  return listFromPayload(payload).map(normalizeAuditLogRow);
}

export function normalizeTimeline(payload: unknown): TimelineRow[] {
  return listFromPayload(payload).map(normalizeTimelineRow);
}

export async function fetchIncidentAuditOverview(
  options: IncidentAuditFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<IncidentAuditOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, incidentsResponse, auditEventsResponse, auditLogsResponse, timelineResponse] =
    await Promise.all([
      fetcher('/incident-audit-runtime/health', { headers }),
      fetcher('/incident-audit-runtime/api/incident-audit/summary', { headers }),
      fetcher('/incident-audit-runtime/api/incident-audit/incidents?limit=50', { headers }),
      fetcher('/incident-audit-runtime/api/incident-audit/audit-events?limit=50', { headers }),
      fetcher('/incident-audit-runtime/api/incident-audit/audit-logs?limit=50', { headers }),
      fetcher('/incident-audit-runtime/api/incident-audit/timeline?limit=50', { headers }),
    ]);

  if (!healthResponse.ok) {
    throw new Error(`incident audit health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`incident audit summary okunamadi: ${summaryResponse.status}`);
  }

  if (!incidentsResponse.ok) {
    throw new Error(`incidents okunamadi: ${incidentsResponse.status}`);
  }

  if (!auditEventsResponse.ok) {
    throw new Error(`audit events okunamadi: ${auditEventsResponse.status}`);
  }

  if (!auditLogsResponse.ok) {
    throw new Error(`audit logs okunamadi: ${auditLogsResponse.status}`);
  }

  if (!timelineResponse.ok) {
    throw new Error(`timeline okunamadi: ${timelineResponse.status}`);
  }

  const health = await healthResponse.json() as IncidentAuditRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const incidentsPayload = await incidentsResponse.json();
  const auditEventsPayload = await auditEventsResponse.json();
  const auditLogsPayload = await auditLogsResponse.json();
  const timelinePayload = await timelineResponse.json();

  return {
    health,
    summary: normalizeIncidentAuditSummary(summaryPayload),
    incidents: normalizeIncidents(incidentsPayload),
    auditEvents: normalizeAuditEvents(auditEventsPayload),
    auditLogs: normalizeAuditLogs(auditLogsPayload),
    timeline: normalizeTimeline(timelinePayload),
  };
}
