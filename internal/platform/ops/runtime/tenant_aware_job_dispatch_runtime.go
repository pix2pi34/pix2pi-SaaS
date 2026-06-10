package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	JobDispatchTypeWebhookDelivery = "WEBHOOK_DELIVERY"
	JobDispatchTypeEmailDelivery   = "EMAIL_DELIVERY"
	JobDispatchTypeReportBuild     = "REPORT_BUILD"
	JobDispatchTypeCleanup         = "CLEANUP"

	JobDispatchPriorityLow      = "LOW"
	JobDispatchPriorityNormal   = "NORMAL"
	JobDispatchPriorityHigh     = "HIGH"
	JobDispatchPriorityCritical = "CRITICAL"

	JobDispatchStateQueued     = "QUEUED"
	JobDispatchStateDispatched = "DISPATCHED"
	JobDispatchStateRejected   = "REJECTED"

	JobDispatchDecisionAllow = "ALLOW"
	JobDispatchDecisionDeny  = "DENY"

	JobDispatchReasonAllowed         = "JOB_DISPATCH_ALLOWED"
	JobDispatchReasonMissingTenant   = "JOB_DISPATCH_MISSING_TENANT"
	JobDispatchReasonMissingJobType  = "JOB_DISPATCH_MISSING_JOB_TYPE"
	JobDispatchReasonInvalidJobType  = "JOB_DISPATCH_INVALID_JOB_TYPE"
	JobDispatchReasonInvalidPriority = "JOB_DISPATCH_INVALID_PRIORITY"
	JobDispatchReasonMissingPayload  = "JOB_DISPATCH_MISSING_PAYLOAD"
	JobDispatchReasonCrossTenant     = "JOB_DISPATCH_CROSS_TENANT_DENIED"
	JobDispatchReasonDuplicateDedupe = "JOB_DISPATCH_DUPLICATE_DEDUPE_KEY"
	JobDispatchReasonJobNotFound     = "JOB_DISPATCH_JOB_NOT_FOUND"
)

var (
	ErrJobDispatchMissingTenant   = errors.New("missing job dispatch tenant id")
	ErrJobDispatchMissingJobType  = errors.New("missing job dispatch job type")
	ErrJobDispatchInvalidJobType  = errors.New("invalid job dispatch job type")
	ErrJobDispatchInvalidPriority = errors.New("invalid job dispatch priority")
	ErrJobDispatchMissingPayload  = errors.New("missing job dispatch payload")
	ErrJobDispatchCrossTenant     = errors.New("cross-tenant job dispatch denied")
	ErrJobDispatchDuplicateDedupe = errors.New("duplicate job dispatch dedupe key")
	ErrJobDispatchJobNotFound     = errors.New("job dispatch record not found")
)

type TenantAwareJobDispatchRuntimeConfig struct {
	RequireTenant     bool     `json:"require_tenant"`
	AllowedJobTypes   []string `json:"allowed_job_types"`
	AllowedPriorities []string `json:"allowed_priorities"`
	DefaultQueue      string   `json:"default_queue"`
	DefaultPriority   string   `json:"default_priority"`
	RequirePayload    bool     `json:"require_payload"`
	EnableDedupeGuard bool     `json:"enable_dedupe_guard"`
}

func DefaultTenantAwareJobDispatchRuntimeConfig() TenantAwareJobDispatchRuntimeConfig {
	return TenantAwareJobDispatchRuntimeConfig{
		RequireTenant: true,
		AllowedJobTypes: []string{
			JobDispatchTypeWebhookDelivery,
			JobDispatchTypeEmailDelivery,
			JobDispatchTypeReportBuild,
			JobDispatchTypeCleanup,
		},
		AllowedPriorities: []string{
			JobDispatchPriorityLow,
			JobDispatchPriorityNormal,
			JobDispatchPriorityHigh,
			JobDispatchPriorityCritical,
		},
		DefaultQueue:      "default",
		DefaultPriority:   JobDispatchPriorityNormal,
		RequirePayload:    true,
		EnableDedupeGuard: true,
	}
}

type TenantAwareJobDispatchRequest struct {
	TenantID      string            `json:"tenant_id"`
	JobType       string            `json:"job_type"`
	Queue         string            `json:"queue,omitempty"`
	Priority      string            `json:"priority,omitempty"`
	Payload       map[string]string `json:"payload,omitempty"`
	DedupeKey     string            `json:"dedupe_key,omitempty"`
	RequestedBy   string            `json:"requested_by,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
}

type TenantAwareJobRecord struct {
	TenantID      string            `json:"tenant_id"`
	JobID         string            `json:"job_id"`
	JobType       string            `json:"job_type"`
	Queue         string            `json:"queue"`
	Priority      string            `json:"priority"`
	State         string            `json:"state"`
	Payload       map[string]string `json:"payload"`
	DedupeKey     string            `json:"dedupe_key,omitempty"`
	RequestedBy   string            `json:"requested_by,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	CreatedAt     string            `json:"created_at"`
	UpdatedAt     string            `json:"updated_at"`
}

type TenantAwareJobDispatchDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	JobID         string `json:"job_id,omitempty"`
	JobType       string `json:"job_type,omitempty"`
	Queue         string `json:"queue,omitempty"`
	Priority      string `json:"priority,omitempty"`
	State         string `json:"state,omitempty"`
	DedupeKey     string `json:"dedupe_key,omitempty"`
	RequestedBy   string `json:"requested_by,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type TenantAwareJobDispatchRuntime struct {
	config TenantAwareJobDispatchRuntimeConfig
	mu     sync.RWMutex
	jobs   map[string]TenantAwareJobRecord
	dedupe map[string]string
}

func NewTenantAwareJobDispatchRuntime(config TenantAwareJobDispatchRuntimeConfig) *TenantAwareJobDispatchRuntime {
	defaults := DefaultTenantAwareJobDispatchRuntimeConfig()

	if len(config.AllowedJobTypes) == 0 {
		config.AllowedJobTypes = defaults.AllowedJobTypes
	}
	if len(config.AllowedPriorities) == 0 {
		config.AllowedPriorities = defaults.AllowedPriorities
	}
	if strings.TrimSpace(config.DefaultQueue) == "" {
		config.DefaultQueue = defaults.DefaultQueue
	}
	if strings.TrimSpace(config.DefaultPriority) == "" {
		config.DefaultPriority = defaults.DefaultPriority
	}

	return &TenantAwareJobDispatchRuntime{
		config: config,
		jobs:   make(map[string]TenantAwareJobRecord),
		dedupe: make(map[string]string),
	}
}

func (r *TenantAwareJobDispatchRuntime) DispatchJob(req TenantAwareJobDispatchRequest) (TenantAwareJobRecord, TenantAwareJobDispatchDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	jobType := normalizeJobDispatchValue(req.JobType)
	queue := strings.TrimSpace(req.Queue)
	priority := normalizeJobDispatchValue(req.Priority)
	dedupeKey := strings.TrimSpace(req.DedupeKey)

	if queue == "" {
		queue = r.config.DefaultQueue
	}
	if priority == "" {
		priority = normalizeJobDispatchValue(r.config.DefaultPriority)
	}

	decision := TenantAwareJobDispatchDecision{
		Decision:      JobDispatchDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		JobType:       jobType,
		Queue:         queue,
		Priority:      priority,
		DedupeKey:     dedupeKey,
		RequestedBy:   strings.TrimSpace(req.RequestedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        JobDispatchReasonAllowed,
		CheckedAt:     now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = JobDispatchReasonMissingTenant
		decision.State = JobDispatchStateRejected
		return TenantAwareJobRecord{}, decision, ErrJobDispatchMissingTenant
	}

	if jobType == "" {
		decision.Reason = JobDispatchReasonMissingJobType
		decision.State = JobDispatchStateRejected
		return TenantAwareJobRecord{}, decision, ErrJobDispatchMissingJobType
	}

	if !r.jobTypeAllowed(jobType) {
		decision.Reason = JobDispatchReasonInvalidJobType
		decision.State = JobDispatchStateRejected
		return TenantAwareJobRecord{}, decision, ErrJobDispatchInvalidJobType
	}

	if !r.priorityAllowed(priority) {
		decision.Reason = JobDispatchReasonInvalidPriority
		decision.State = JobDispatchStateRejected
		return TenantAwareJobRecord{}, decision, ErrJobDispatchInvalidPriority
	}

	if r.config.RequirePayload && len(req.Payload) == 0 {
		decision.Reason = JobDispatchReasonMissingPayload
		decision.State = JobDispatchStateRejected
		return TenantAwareJobRecord{}, decision, ErrJobDispatchMissingPayload
	}

	if r.config.EnableDedupeGuard && dedupeKey != "" {
		if existingJobID, ok := r.dedupe[tenantDedupeKey(tenantID, dedupeKey)]; ok {
			decision.Reason = JobDispatchReasonDuplicateDedupe
			decision.JobID = existingJobID
			decision.State = JobDispatchStateRejected
			return TenantAwareJobRecord{}, decision, ErrJobDispatchDuplicateDedupe
		}
	}

	record := TenantAwareJobRecord{
		TenantID:      tenantID,
		JobID:         NewTenantAwareJobID(),
		JobType:       jobType,
		Queue:         queue,
		Priority:      priority,
		State:         JobDispatchStateQueued,
		Payload:       cloneJobDispatchPayload(req.Payload),
		DedupeKey:     dedupeKey,
		RequestedBy:   strings.TrimSpace(req.RequestedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	r.mu.Lock()
	r.jobs[record.JobID] = record
	if r.config.EnableDedupeGuard && dedupeKey != "" {
		r.dedupe[tenantDedupeKey(tenantID, dedupeKey)] = record.JobID
	}
	r.mu.Unlock()

	decision.Decision = JobDispatchDecisionAllow
	decision.Allowed = true
	decision.JobID = record.JobID
	decision.State = record.State
	decision.Reason = JobDispatchReasonAllowed

	return record, decision, nil
}

func (r *TenantAwareJobDispatchRuntime) MarkDispatched(tenantID string, jobID string) (TenantAwareJobRecord, TenantAwareJobDispatchDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	jobID = strings.TrimSpace(jobID)

	decision := TenantAwareJobDispatchDecision{
		Decision:  JobDispatchDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		JobID:     jobID,
		Reason:    JobDispatchReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = JobDispatchReasonMissingTenant
		return TenantAwareJobRecord{}, decision, ErrJobDispatchMissingTenant
	}

	if jobID == "" {
		decision.Reason = JobDispatchReasonJobNotFound
		return TenantAwareJobRecord{}, decision, ErrJobDispatchJobNotFound
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	record, ok := r.jobs[jobID]
	if !ok {
		decision.Reason = JobDispatchReasonJobNotFound
		return TenantAwareJobRecord{}, decision, ErrJobDispatchJobNotFound
	}

	if record.TenantID != tenantID {
		decision.Reason = JobDispatchReasonCrossTenant
		return TenantAwareJobRecord{}, decision, ErrJobDispatchCrossTenant
	}

	record.State = JobDispatchStateDispatched
	record.UpdatedAt = now
	r.jobs[jobID] = record

	decision.Decision = JobDispatchDecisionAllow
	decision.Allowed = true
	decision.JobType = record.JobType
	decision.Queue = record.Queue
	decision.Priority = record.Priority
	decision.State = record.State
	decision.DedupeKey = record.DedupeKey
	decision.RequestedBy = record.RequestedBy
	decision.CorrelationID = record.CorrelationID
	decision.Reason = JobDispatchReasonAllowed

	return record, decision, nil
}

func (r *TenantAwareJobDispatchRuntime) GetJob(tenantID string, jobID string) (TenantAwareJobRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	jobID = strings.TrimSpace(jobID)

	if tenantID == "" {
		return TenantAwareJobRecord{}, ErrJobDispatchMissingTenant
	}
	if jobID == "" {
		return TenantAwareJobRecord{}, ErrJobDispatchJobNotFound
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.jobs[jobID]
	if !ok {
		return TenantAwareJobRecord{}, ErrJobDispatchJobNotFound
	}
	if record.TenantID != tenantID {
		return TenantAwareJobRecord{}, ErrJobDispatchCrossTenant
	}

	return record, nil
}

func (r *TenantAwareJobDispatchRuntime) ListTenantJobs(tenantID string) ([]TenantAwareJobRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrJobDispatchMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]TenantAwareJobRecord, 0)
	for _, record := range r.jobs {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *TenantAwareJobDispatchRuntime) ListTenantQueueJobs(tenantID string, queue string) ([]TenantAwareJobRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	queue = strings.TrimSpace(queue)

	if tenantID == "" {
		return nil, ErrJobDispatchMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]TenantAwareJobRecord, 0)
	for _, record := range r.jobs {
		if record.TenantID == tenantID && record.Queue == queue {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *TenantAwareJobDispatchRuntime) jobTypeAllowed(jobType string) bool {
	jobType = normalizeJobDispatchValue(jobType)
	for _, allowed := range r.config.AllowedJobTypes {
		if normalizeJobDispatchValue(allowed) == jobType {
			return true
		}
	}
	return false
}

func (r *TenantAwareJobDispatchRuntime) priorityAllowed(priority string) bool {
	priority = normalizeJobDispatchValue(priority)
	for _, allowed := range r.config.AllowedPriorities {
		if normalizeJobDispatchValue(allowed) == priority {
			return true
		}
	}
	return false
}

func normalizeJobDispatchValue(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func tenantDedupeKey(tenantID string, dedupeKey string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(dedupeKey)
}

func cloneJobDispatchPayload(input map[string]string) map[string]string {
	out := make(map[string]string)
	for key, value := range input {
		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		if key != "" && value != "" {
			out[key] = value
		}
	}
	return out
}

func NewTenantAwareJobID() string {
	return randomOpsRuntimeID("tenant_job_")
}
