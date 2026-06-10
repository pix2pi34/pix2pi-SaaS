package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	JobAuditEventQueued     = "JOB_QUEUED"
	JobAuditEventDispatched = "JOB_DISPATCHED"
	JobAuditEventFailed     = "JOB_FAILED"
	JobAuditEventRetried    = "JOB_RETRIED"
	JobAuditEventCanceled   = "JOB_CANCELED"

	JobAuditSeverityInfo    = "INFO"
	JobAuditSeverityWarning = "WARNING"
	JobAuditSeverityError   = "ERROR"

	JobAuditDecisionAllow = "ALLOW"
	JobAuditDecisionDeny  = "DENY"

	JobAuditReasonAllowed          = "JOB_AUDIT_ALLOWED"
	JobAuditReasonMissingTenant    = "JOB_AUDIT_MISSING_TENANT"
	JobAuditReasonMissingJobID     = "JOB_AUDIT_MISSING_JOB_ID"
	JobAuditReasonMissingJobType   = "JOB_AUDIT_MISSING_JOB_TYPE"
	JobAuditReasonMissingEventType = "JOB_AUDIT_MISSING_EVENT_TYPE"
	JobAuditReasonInvalidEventType = "JOB_AUDIT_INVALID_EVENT_TYPE"
	JobAuditReasonInvalidSeverity  = "JOB_AUDIT_INVALID_SEVERITY"
	JobAuditReasonMissingMessage   = "JOB_AUDIT_MISSING_MESSAGE"
	JobAuditReasonCrossTenant      = "JOB_AUDIT_CROSS_TENANT_DENIED"
	JobAuditReasonAuditLogNotFound = "JOB_AUDIT_LOG_NOT_FOUND"
)

var (
	ErrJobAuditMissingTenant    = errors.New("missing job audit tenant id")
	ErrJobAuditMissingJobID     = errors.New("missing job audit job id")
	ErrJobAuditMissingJobType   = errors.New("missing job audit job type")
	ErrJobAuditMissingEventType = errors.New("missing job audit event type")
	ErrJobAuditInvalidEventType = errors.New("invalid job audit event type")
	ErrJobAuditInvalidSeverity  = errors.New("invalid job audit severity")
	ErrJobAuditMissingMessage   = errors.New("missing job audit message")
	ErrJobAuditCrossTenant      = errors.New("cross-tenant job audit access denied")
	ErrJobAuditLogNotFound      = errors.New("job audit log not found")
)

type JobAuditLogPersistenceRuntimeConfig struct {
	RequireTenant     bool     `json:"require_tenant"`
	AllowedEventTypes []string `json:"allowed_event_types"`
	AllowedSeverities []string `json:"allowed_severities"`
	DefaultSeverity   string   `json:"default_severity"`
	RequireMessage    bool     `json:"require_message"`
}

func DefaultJobAuditLogPersistenceRuntimeConfig() JobAuditLogPersistenceRuntimeConfig {
	return JobAuditLogPersistenceRuntimeConfig{
		RequireTenant: true,
		AllowedEventTypes: []string{
			JobAuditEventQueued,
			JobAuditEventDispatched,
			JobAuditEventFailed,
			JobAuditEventRetried,
			JobAuditEventCanceled,
		},
		AllowedSeverities: []string{
			JobAuditSeverityInfo,
			JobAuditSeverityWarning,
			JobAuditSeverityError,
		},
		DefaultSeverity: JobAuditSeverityInfo,
		RequireMessage:  true,
	}
}

type JobAuditLogRequest struct {
	TenantID      string            `json:"tenant_id"`
	JobID         string            `json:"job_id"`
	JobType       string            `json:"job_type"`
	Queue         string            `json:"queue,omitempty"`
	EventType     string            `json:"event_type"`
	Severity      string            `json:"severity,omitempty"`
	State         string            `json:"state,omitempty"`
	Message       string            `json:"message"`
	ActorID       string            `json:"actor_id,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Attributes    map[string]string `json:"attributes,omitempty"`
}

type JobAuditLogRecord struct {
	TenantID      string            `json:"tenant_id"`
	AuditID       string            `json:"audit_id"`
	JobID         string            `json:"job_id"`
	JobType       string            `json:"job_type"`
	Queue         string            `json:"queue,omitempty"`
	EventType     string            `json:"event_type"`
	Severity      string            `json:"severity"`
	State         string            `json:"state,omitempty"`
	Message       string            `json:"message"`
	ActorID       string            `json:"actor_id,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Attributes    map[string]string `json:"attributes,omitempty"`
	CreatedAt     string            `json:"created_at"`
}

type JobAuditLogDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	AuditID       string `json:"audit_id,omitempty"`
	JobID         string `json:"job_id,omitempty"`
	JobType       string `json:"job_type,omitempty"`
	EventType     string `json:"event_type,omitempty"`
	Severity      string `json:"severity,omitempty"`
	State         string `json:"state,omitempty"`
	ActorID       string `json:"actor_id,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type JobAuditLogPersistenceRuntime struct {
	config JobAuditLogPersistenceRuntimeConfig
	mu     sync.RWMutex
	logs   map[string]JobAuditLogRecord
}

func NewJobAuditLogPersistenceRuntime(config JobAuditLogPersistenceRuntimeConfig) *JobAuditLogPersistenceRuntime {
	defaults := DefaultJobAuditLogPersistenceRuntimeConfig()

	if len(config.AllowedEventTypes) == 0 {
		config.AllowedEventTypes = defaults.AllowedEventTypes
	}
	if len(config.AllowedSeverities) == 0 {
		config.AllowedSeverities = defaults.AllowedSeverities
	}
	if strings.TrimSpace(config.DefaultSeverity) == "" {
		config.DefaultSeverity = defaults.DefaultSeverity
	}

	return &JobAuditLogPersistenceRuntime{
		config: config,
		logs:   make(map[string]JobAuditLogRecord),
	}
}

func (r *JobAuditLogPersistenceRuntime) RecordJobAuditLog(req JobAuditLogRequest) (JobAuditLogRecord, JobAuditLogDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	jobID := strings.TrimSpace(req.JobID)
	jobType := normalizeJobDispatchValue(req.JobType)
	eventType := normalizeJobAuditValue(req.EventType)
	severity := normalizeJobAuditValue(req.Severity)
	state := normalizeJobDispatchValue(req.State)

	if severity == "" {
		severity = normalizeJobAuditValue(r.config.DefaultSeverity)
	}

	decision := JobAuditLogDecision{
		Decision:      JobAuditDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		JobID:         jobID,
		JobType:       jobType,
		EventType:     eventType,
		Severity:      severity,
		State:         state,
		ActorID:       strings.TrimSpace(req.ActorID),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        JobAuditReasonAllowed,
		CheckedAt:     now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = JobAuditReasonMissingTenant
		return JobAuditLogRecord{}, decision, ErrJobAuditMissingTenant
	}

	if jobID == "" {
		decision.Reason = JobAuditReasonMissingJobID
		return JobAuditLogRecord{}, decision, ErrJobAuditMissingJobID
	}

	if jobType == "" {
		decision.Reason = JobAuditReasonMissingJobType
		return JobAuditLogRecord{}, decision, ErrJobAuditMissingJobType
	}

	if eventType == "" {
		decision.Reason = JobAuditReasonMissingEventType
		return JobAuditLogRecord{}, decision, ErrJobAuditMissingEventType
	}

	if !r.eventTypeAllowed(eventType) {
		decision.Reason = JobAuditReasonInvalidEventType
		return JobAuditLogRecord{}, decision, ErrJobAuditInvalidEventType
	}

	if !r.severityAllowed(severity) {
		decision.Reason = JobAuditReasonInvalidSeverity
		return JobAuditLogRecord{}, decision, ErrJobAuditInvalidSeverity
	}

	if r.config.RequireMessage && strings.TrimSpace(req.Message) == "" {
		decision.Reason = JobAuditReasonMissingMessage
		return JobAuditLogRecord{}, decision, ErrJobAuditMissingMessage
	}

	record := JobAuditLogRecord{
		TenantID:      tenantID,
		AuditID:       NewJobAuditLogID(),
		JobID:         jobID,
		JobType:       jobType,
		Queue:         strings.TrimSpace(req.Queue),
		EventType:     eventType,
		Severity:      severity,
		State:         state,
		Message:       strings.TrimSpace(req.Message),
		ActorID:       strings.TrimSpace(req.ActorID),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Attributes:    cloneJobDispatchPayload(req.Attributes),
		CreatedAt:     now,
	}

	r.mu.Lock()
	r.logs[record.AuditID] = record
	r.mu.Unlock()

	decision.Decision = JobAuditDecisionAllow
	decision.Allowed = true
	decision.AuditID = record.AuditID
	decision.Reason = JobAuditReasonAllowed

	return record, decision, nil
}

func (r *JobAuditLogPersistenceRuntime) RecordFromJob(job TenantAwareJobRecord, eventType string, message string) (JobAuditLogRecord, JobAuditLogDecision, error) {
	return r.RecordJobAuditLog(JobAuditLogRequest{
		TenantID:      job.TenantID,
		JobID:         job.JobID,
		JobType:       job.JobType,
		Queue:         job.Queue,
		EventType:     eventType,
		Severity:      JobAuditSeverityInfo,
		State:         job.State,
		Message:       message,
		ActorID:       job.RequestedBy,
		CorrelationID: job.CorrelationID,
		Attributes: map[string]string{
			"priority":   job.Priority,
			"dedupe_key": job.DedupeKey,
		},
	})
}

func (r *JobAuditLogPersistenceRuntime) GetAuditLog(tenantID string, auditID string) (JobAuditLogRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	auditID = strings.TrimSpace(auditID)

	if tenantID == "" {
		return JobAuditLogRecord{}, ErrJobAuditMissingTenant
	}
	if auditID == "" {
		return JobAuditLogRecord{}, ErrJobAuditLogNotFound
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.logs[auditID]
	if !ok {
		return JobAuditLogRecord{}, ErrJobAuditLogNotFound
	}

	if record.TenantID != tenantID {
		return JobAuditLogRecord{}, ErrJobAuditCrossTenant
	}

	return record, nil
}

func (r *JobAuditLogPersistenceRuntime) ListTenantAuditLogs(tenantID string) ([]JobAuditLogRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrJobAuditMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]JobAuditLogRecord, 0)
	for _, record := range r.logs {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *JobAuditLogPersistenceRuntime) ListJobAuditLogs(tenantID string, jobID string) ([]JobAuditLogRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	jobID = strings.TrimSpace(jobID)

	if tenantID == "" {
		return nil, ErrJobAuditMissingTenant
	}
	if jobID == "" {
		return nil, ErrJobAuditMissingJobID
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]JobAuditLogRecord, 0)
	for _, record := range r.logs {
		if record.TenantID == tenantID && record.JobID == jobID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *JobAuditLogPersistenceRuntime) eventTypeAllowed(eventType string) bool {
	eventType = normalizeJobAuditValue(eventType)
	for _, allowed := range r.config.AllowedEventTypes {
		if normalizeJobAuditValue(allowed) == eventType {
			return true
		}
	}
	return false
}

func (r *JobAuditLogPersistenceRuntime) severityAllowed(severity string) bool {
	severity = normalizeJobAuditValue(severity)
	for _, allowed := range r.config.AllowedSeverities {
		if normalizeJobAuditValue(allowed) == severity {
			return true
		}
	}
	return false
}

func normalizeJobAuditValue(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func NewJobAuditLogID() string {
	return randomOpsRuntimeID("job_audit_log_")
}
