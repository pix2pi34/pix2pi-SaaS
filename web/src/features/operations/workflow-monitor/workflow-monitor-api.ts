import type {
  WorkflowApprovalRow,
  WorkflowDefinitionRow,
  WorkflowInstanceRow,
  WorkflowMonitorOverview,
  WorkflowRuntimeHealth,
  WorkflowStepRow,
  WorkflowSummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type WorkflowMonitorFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: WorkflowMonitorFetchOptions): Record<string, string> {
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

function normalizeSummaryItem(raw: Record<string, unknown>): WorkflowSummaryItem {
  return {
    status: asText(raw.status, 'unknown'),
    count: asNumber(raw.count),
    definitionCount: asNumber(raw.definition_count ?? raw.definitionCount),
    stepCount: asNumber(raw.step_count ?? raw.stepCount),
    approvalCount: asNumber(raw.approval_count ?? raw.approvalCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeDefinitionRow(raw: Record<string, unknown>): WorkflowDefinitionRow {
  return {
    workflowKey: asText(raw.workflow_key ?? raw.workflowKey, '-'),
    displayName: asText(raw.display_name ?? raw.displayName, '-'),
    versionNo: asNumber(raw.version_no ?? raw.versionNo),
    visibilityScope: asText(raw.visibility_scope ?? raw.visibilityScope, '-'),
    definitionStatus: asText(raw.definition_status ?? raw.definitionStatus, '-'),
    triggerEvent: asText(raw.trigger_event ?? raw.triggerEvent, '-'),
    isEnabled: asBool(raw.is_enabled ?? raw.isEnabled),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeInstanceRow(raw: Record<string, unknown>): WorkflowInstanceRow {
  return {
    instanceId: asText(raw.instance_id ?? raw.instanceId, '-'),
    workflowKey: asText(raw.workflow_key ?? raw.workflowKey, '-'),
    instanceKey: asText(raw.instance_key ?? raw.instanceKey, '-'),
    workflowStatus: asText(raw.workflow_status ?? raw.workflowStatus, '-'),
    subjectRefType: asText(raw.subject_ref_type ?? raw.subjectRefType, '-'),
    subjectRefId: asText(raw.subject_ref_id ?? raw.subjectRefId, '-'),
    currentStepKey: asText(raw.current_step_key ?? raw.currentStepKey, '-'),
    startedAt: asText(raw.started_at ?? raw.startedAt, '-'),
    finishedAt: asText(raw.finished_at ?? raw.finishedAt, '-'),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeStepRow(raw: Record<string, unknown>): WorkflowStepRow {
  return {
    stepId: asText(raw.step_id ?? raw.stepId, '-'),
    instanceKey: asText(raw.instance_key ?? raw.instanceKey, '-'),
    stepKey: asText(raw.step_key ?? raw.stepKey, '-'),
    stepOrder: asNumber(raw.step_order ?? raw.stepOrder),
    stepType: asText(raw.step_type ?? raw.stepType, '-'),
    stepStatus: asText(raw.step_status ?? raw.stepStatus, '-'),
    assignedTo: asText(raw.assigned_to ?? raw.assignedTo, ''),
    startedAt: asText(raw.started_at ?? raw.startedAt, '-'),
    finishedAt: asText(raw.finished_at ?? raw.finishedAt, '-'),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeApprovalRow(raw: Record<string, unknown>): WorkflowApprovalRow {
  return {
    approvalId: asText(raw.approval_id ?? raw.approvalId, '-'),
    instanceKey: asText(raw.instance_key ?? raw.instanceKey, '-'),
    stepId: asText(raw.step_id ?? raw.stepId, '-'),
    approvalKey: asText(raw.approval_key ?? raw.approvalKey, '-'),
    approverRef: asText(raw.approver_ref ?? raw.approverRef, '-'),
    approvalStatus: asText(raw.approval_status ?? raw.approvalStatus, '-'),
    requestedAt: asText(raw.requested_at ?? raw.requestedAt, '-'),
    respondedAt: asText(raw.responded_at ?? raw.respondedAt, '-'),
    responseNote: asText(raw.response_note ?? raw.responseNote, ''),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

export function normalizeWorkflowSummary(payload: unknown): WorkflowSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeWorkflowDefinitions(payload: unknown): WorkflowDefinitionRow[] {
  return listFromPayload(payload).map(normalizeDefinitionRow);
}

export function normalizeWorkflowInstances(payload: unknown): WorkflowInstanceRow[] {
  return listFromPayload(payload).map(normalizeInstanceRow);
}

export function normalizeWorkflowSteps(payload: unknown): WorkflowStepRow[] {
  return listFromPayload(payload).map(normalizeStepRow);
}

export function normalizeWorkflowApprovals(payload: unknown): WorkflowApprovalRow[] {
  return listFromPayload(payload).map(normalizeApprovalRow);
}

export async function fetchWorkflowMonitorOverview(
  options: WorkflowMonitorFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<WorkflowMonitorOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, definitionsResponse, instancesResponse, stepsResponse, approvalsResponse] =
    await Promise.all([
      fetcher('/workflow-runtime/health', { headers }),
      fetcher('/workflow-runtime/api/workflows/summary', { headers }),
      fetcher('/workflow-runtime/api/workflows/definitions', { headers }),
      fetcher('/workflow-runtime/api/workflows/instances?limit=25', { headers }),
      fetcher('/workflow-runtime/api/workflows/steps?limit=25', { headers }),
      fetcher('/workflow-runtime/api/workflows/approvals?limit=25', { headers }),
    ]);

  if (!healthResponse.ok) {
    throw new Error(`workflow runtime health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`workflow summary okunamadi: ${summaryResponse.status}`);
  }

  if (!definitionsResponse.ok) {
    throw new Error(`workflow definitions okunamadi: ${definitionsResponse.status}`);
  }

  if (!instancesResponse.ok) {
    throw new Error(`workflow instances okunamadi: ${instancesResponse.status}`);
  }

  if (!stepsResponse.ok) {
    throw new Error(`workflow steps okunamadi: ${stepsResponse.status}`);
  }

  if (!approvalsResponse.ok) {
    throw new Error(`workflow approvals okunamadi: ${approvalsResponse.status}`);
  }

  const health = await healthResponse.json() as WorkflowRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const definitionsPayload = await definitionsResponse.json();
  const instancesPayload = await instancesResponse.json();
  const stepsPayload = await stepsResponse.json();
  const approvalsPayload = await approvalsResponse.json();

  return {
    health,
    summary: normalizeWorkflowSummary(summaryPayload),
    definitions: normalizeWorkflowDefinitions(definitionsPayload),
    instances: normalizeWorkflowInstances(instancesPayload),
    steps: normalizeWorkflowSteps(stepsPayload),
    approvals: normalizeWorkflowApprovals(approvalsPayload),
  };
}
