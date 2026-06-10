export type WorkflowRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type WorkflowSummaryItem = {
  status: string;
  count: number;
  definitionCount: number;
  stepCount: number;
  approvalCount: number;
  generatedAt: string;
};

export type WorkflowDefinitionRow = {
  workflowKey: string;
  displayName: string;
  versionNo: number;
  visibilityScope: string;
  definitionStatus: string;
  triggerEvent: string;
  isEnabled: boolean;
  createdAt: string;
  updatedAt: string;
};

export type WorkflowInstanceRow = {
  instanceId: string;
  workflowKey: string;
  instanceKey: string;
  workflowStatus: string;
  subjectRefType: string;
  subjectRefId: string;
  currentStepKey: string;
  startedAt: string;
  finishedAt: string;
  createdAt: string;
  updatedAt: string;
};

export type WorkflowStepRow = {
  stepId: string;
  instanceKey: string;
  stepKey: string;
  stepOrder: number;
  stepType: string;
  stepStatus: string;
  assignedTo: string;
  startedAt: string;
  finishedAt: string;
  createdAt: string;
  updatedAt: string;
};

export type WorkflowApprovalRow = {
  approvalId: string;
  instanceKey: string;
  stepId: string;
  approvalKey: string;
  approverRef: string;
  approvalStatus: string;
  requestedAt: string;
  respondedAt: string;
  responseNote: string;
  createdAt: string;
  updatedAt: string;
};

export type WorkflowMonitorOverview = {
  health: WorkflowRuntimeHealth;
  summary: WorkflowSummaryItem[];
  definitions: WorkflowDefinitionRow[];
  instances: WorkflowInstanceRow[];
  steps: WorkflowStepRow[];
  approvals: WorkflowApprovalRow[];
};
