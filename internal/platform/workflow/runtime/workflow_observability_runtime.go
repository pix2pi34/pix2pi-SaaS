package workflowruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	WorkflowObservabilityMetricTransition     = "transition"
	WorkflowObservabilityMetricApproval       = "approval"
	WorkflowObservabilityMetricRetry          = "retry"
	WorkflowObservabilityMetricCompensation   = "compensation"
	WorkflowObservabilityMetricFailedWorkflow = "failed_workflow"

	WorkflowObservabilityReasonAllowed       = "WORKFLOW_OBSERVABILITY_ALLOWED"
	WorkflowObservabilityReasonMissingTenant = "WORKFLOW_OBSERVABILITY_MISSING_TENANT"
	WorkflowObservabilityReasonCrossTenant   = "WORKFLOW_OBSERVABILITY_CROSS_TENANT_DENIED"
)

var (
	ErrWorkflowObservabilityMissingTenant = errors.New("missing workflow observability tenant id")
	ErrWorkflowObservabilityCrossTenant   = errors.New("cross-tenant workflow observability access denied")
)

type WorkflowObservabilityRuntimeConfig struct {
	RequireTenant bool `json:"require_tenant"`
}

func DefaultWorkflowObservabilityRuntimeConfig() WorkflowObservabilityRuntimeConfig {
	return WorkflowObservabilityRuntimeConfig{
		RequireTenant: true,
	}
}

type WorkflowMetricSnapshot struct {
	TenantID                string         `json:"tenant_id"`
	StateTransitionCounters map[string]int `json:"state_transition_counters"`
	ApprovalCounters        map[string]int `json:"approval_counters"`
	RetryCounters           map[string]int `json:"retry_counters"`
	CompensationCounters    map[string]int `json:"compensation_counters"`
	FailedWorkflowCounters  map[string]int `json:"failed_workflow_counters"`
	TotalTransitions        int            `json:"total_transitions"`
	TotalApprovals          int            `json:"total_approvals"`
	TotalRetryDecisions     int            `json:"total_retry_decisions"`
	TotalCompensations      int            `json:"total_compensations"`
	LastUpdatedAt           string         `json:"last_updated_at"`
}

type WorkflowObservabilityDecision struct {
	Decision  string `json:"decision"`
	Allowed   bool   `json:"allowed"`
	TenantID  string `json:"tenant_id"`
	Metric    string `json:"metric"`
	Reason    string `json:"reason"`
	CheckedAt string `json:"checked_at"`
}

type workflowTenantMetrics struct {
	snapshot WorkflowMetricSnapshot
}

type WorkflowObservabilityRuntime struct {
	config  WorkflowObservabilityRuntimeConfig
	mu      sync.RWMutex
	tenants map[string]*workflowTenantMetrics
}

func NewWorkflowObservabilityRuntime(config WorkflowObservabilityRuntimeConfig) *WorkflowObservabilityRuntime {
	return &WorkflowObservabilityRuntime{
		config:  config,
		tenants: make(map[string]*workflowTenantMetrics),
	}
}

func (r *WorkflowObservabilityRuntime) RecordTransition(event WorkflowTransitionEvent) (WorkflowMetricSnapshot, WorkflowObservabilityDecision, error) {
	tenantID := strings.TrimSpace(event.TenantID)
	decision := r.baseDecision(tenantID, WorkflowObservabilityMetricTransition)

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowObservabilityReasonMissingTenant
		return WorkflowMetricSnapshot{}, decision, ErrWorkflowObservabilityMissingTenant
	}

	key := transitionMetricKey(event.FromState, event.ToState)

	r.mu.Lock()
	defer r.mu.Unlock()

	metrics := r.metricsForTenant(tenantID)
	metrics.snapshot.StateTransitionCounters[key]++
	metrics.snapshot.TotalTransitions++

	if strings.TrimSpace(event.ToState) == WorkflowStateFailed {
		metrics.snapshot.FailedWorkflowCounters[WorkflowStateFailed]++
	}

	metrics.snapshot.LastUpdatedAt = time.Now().UTC().Format(time.RFC3339Nano)

	decision.Decision = WorkflowDecisionAllow
	decision.Allowed = true
	decision.Reason = WorkflowObservabilityReasonAllowed

	return cloneSnapshot(metrics.snapshot), decision, nil
}

func (r *WorkflowObservabilityRuntime) RecordApproval(approval ManualApprovalRequest) (WorkflowMetricSnapshot, WorkflowObservabilityDecision, error) {
	tenantID := strings.TrimSpace(approval.TenantID)
	decision := r.baseDecision(tenantID, WorkflowObservabilityMetricApproval)

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowObservabilityReasonMissingTenant
		return WorkflowMetricSnapshot{}, decision, ErrWorkflowObservabilityMissingTenant
	}

	status := strings.TrimSpace(approval.Status)
	if status == "" {
		status = ApprovalRequestStatusPending
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	metrics := r.metricsForTenant(tenantID)
	metrics.snapshot.ApprovalCounters[status]++
	metrics.snapshot.TotalApprovals++
	metrics.snapshot.LastUpdatedAt = time.Now().UTC().Format(time.RFC3339Nano)

	decision.Decision = WorkflowDecisionAllow
	decision.Allowed = true
	decision.Reason = WorkflowObservabilityReasonAllowed

	return cloneSnapshot(metrics.snapshot), decision, nil
}

func (r *WorkflowObservabilityRuntime) RecordRetryDecision(retryDecision WorkflowRetryDecision) (WorkflowMetricSnapshot, WorkflowObservabilityDecision, error) {
	tenantID := strings.TrimSpace(retryDecision.TenantID)
	decision := r.baseDecision(tenantID, WorkflowObservabilityMetricRetry)

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowObservabilityReasonMissingTenant
		return WorkflowMetricSnapshot{}, decision, ErrWorkflowObservabilityMissingTenant
	}

	action := strings.TrimSpace(retryDecision.Action)
	if action == "" {
		action = WorkflowRetryActionFail
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	metrics := r.metricsForTenant(tenantID)
	metrics.snapshot.RetryCounters[action]++
	metrics.snapshot.TotalRetryDecisions++
	metrics.snapshot.LastUpdatedAt = time.Now().UTC().Format(time.RFC3339Nano)

	decision.Decision = WorkflowDecisionAllow
	decision.Allowed = true
	decision.Reason = WorkflowObservabilityReasonAllowed

	return cloneSnapshot(metrics.snapshot), decision, nil
}

func (r *WorkflowObservabilityRuntime) RecordCompensation(record WorkflowCompensationRecord) (WorkflowMetricSnapshot, WorkflowObservabilityDecision, error) {
	tenantID := strings.TrimSpace(record.TenantID)
	decision := r.baseDecision(tenantID, WorkflowObservabilityMetricCompensation)

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WorkflowObservabilityReasonMissingTenant
		return WorkflowMetricSnapshot{}, decision, ErrWorkflowObservabilityMissingTenant
	}

	status := strings.TrimSpace(record.Status)
	if status == "" {
		status = WorkflowCompensationStatusRequested
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	metrics := r.metricsForTenant(tenantID)
	metrics.snapshot.CompensationCounters[status]++
	metrics.snapshot.TotalCompensations++
	metrics.snapshot.LastUpdatedAt = time.Now().UTC().Format(time.RFC3339Nano)

	decision.Decision = WorkflowDecisionAllow
	decision.Allowed = true
	decision.Reason = WorkflowObservabilityReasonAllowed

	return cloneSnapshot(metrics.snapshot), decision, nil
}

func (r *WorkflowObservabilityRuntime) Snapshot(tenantID string) (WorkflowMetricSnapshot, error) {
	tenantID = strings.TrimSpace(tenantID)
	if r.config.RequireTenant && tenantID == "" {
		return WorkflowMetricSnapshot{}, ErrWorkflowObservabilityMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	metrics, ok := r.tenants[tenantID]
	if !ok {
		return emptySnapshot(tenantID), nil
	}

	return cloneSnapshot(metrics.snapshot), nil
}

func (r *WorkflowObservabilityRuntime) TenantCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()

	return len(r.tenants)
}

func (r *WorkflowObservabilityRuntime) metricsForTenant(tenantID string) *workflowTenantMetrics {
	metrics, ok := r.tenants[tenantID]
	if ok {
		return metrics
	}

	snapshot := emptySnapshot(tenantID)
	snapshot.LastUpdatedAt = time.Now().UTC().Format(time.RFC3339Nano)

	metrics = &workflowTenantMetrics{snapshot: snapshot}
	r.tenants[tenantID] = metrics

	return metrics
}

func (r *WorkflowObservabilityRuntime) baseDecision(tenantID string, metric string) WorkflowObservabilityDecision {
	return WorkflowObservabilityDecision{
		Decision:  WorkflowDecisionDeny,
		Allowed:   false,
		TenantID:  strings.TrimSpace(tenantID),
		Metric:    strings.TrimSpace(metric),
		Reason:    WorkflowObservabilityReasonAllowed,
		CheckedAt: time.Now().UTC().Format(time.RFC3339Nano),
	}
}

func emptySnapshot(tenantID string) WorkflowMetricSnapshot {
	return WorkflowMetricSnapshot{
		TenantID:                strings.TrimSpace(tenantID),
		StateTransitionCounters: map[string]int{},
		ApprovalCounters:        map[string]int{},
		RetryCounters:           map[string]int{},
		CompensationCounters:    map[string]int{},
		FailedWorkflowCounters:  map[string]int{},
	}
}

func cloneSnapshot(snapshot WorkflowMetricSnapshot) WorkflowMetricSnapshot {
	return WorkflowMetricSnapshot{
		TenantID:                snapshot.TenantID,
		StateTransitionCounters: cloneCounterMap(snapshot.StateTransitionCounters),
		ApprovalCounters:        cloneCounterMap(snapshot.ApprovalCounters),
		RetryCounters:           cloneCounterMap(snapshot.RetryCounters),
		CompensationCounters:    cloneCounterMap(snapshot.CompensationCounters),
		FailedWorkflowCounters:  cloneCounterMap(snapshot.FailedWorkflowCounters),
		TotalTransitions:        snapshot.TotalTransitions,
		TotalApprovals:          snapshot.TotalApprovals,
		TotalRetryDecisions:     snapshot.TotalRetryDecisions,
		TotalCompensations:      snapshot.TotalCompensations,
		LastUpdatedAt:           snapshot.LastUpdatedAt,
	}
}

func cloneCounterMap(input map[string]int) map[string]int {
	out := make(map[string]int, len(input))
	for key, value := range input {
		out[key] = value
	}
	return out
}

func transitionMetricKey(fromState string, toState string) string {
	return strings.TrimSpace(fromState) + "->" + strings.TrimSpace(toState)
}
