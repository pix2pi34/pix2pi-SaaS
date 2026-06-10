package opsconsole

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"
)

const (
	JobMonitorStateQueued     = "QUEUED"
	JobMonitorStateDispatched = "DISPATCHED"
	JobMonitorStateFailed     = "FAILED"
	JobMonitorStateRetried    = "RETRIED"
	JobMonitorStateDLQ        = "DLQ"

	WorkerMonitorStatusActive = "ACTIVE"
	WorkerMonitorStatusIdle   = "IDLE"
	WorkerMonitorStatusStale  = "STALE"
	WorkerMonitorStatusDown   = "DOWN"

	JobMonitorDecisionAllow = "ALLOW"
	JobMonitorDecisionDeny  = "DENY"

	JobMonitorReasonAllowed             = "JOB_MONITOR_ALLOWED"
	JobMonitorReasonMissingTenant       = "JOB_MONITOR_MISSING_TENANT"
	JobMonitorReasonCrossTenant         = "JOB_MONITOR_CROSS_TENANT_DENIED"
	JobMonitorReasonMissingJobID        = "JOB_MONITOR_MISSING_JOB_ID"
	JobMonitorReasonMissingWorkerID     = "JOB_MONITOR_MISSING_WORKER_ID"
	JobMonitorReasonMissingQueue        = "JOB_MONITOR_MISSING_QUEUE"
	JobMonitorReasonInvalidJobState     = "JOB_MONITOR_INVALID_JOB_STATE"
	JobMonitorReasonInvalidWorkerStatus = "JOB_MONITOR_INVALID_WORKER_STATUS"
)

var (
	ErrJobMonitorMissingTenant       = errors.New("missing job monitor tenant id")
	ErrJobMonitorCrossTenant         = errors.New("cross-tenant job monitor access denied")
	ErrJobMonitorMissingJobID        = errors.New("missing job monitor job id")
	ErrJobMonitorMissingWorkerID     = errors.New("missing job monitor worker id")
	ErrJobMonitorMissingQueue        = errors.New("missing job monitor queue")
	ErrJobMonitorInvalidJobState     = errors.New("invalid job monitor job state")
	ErrJobMonitorInvalidWorkerStatus = errors.New("invalid job monitor worker status")
)

type JobQueueWorkerMonitorConsoleConfig struct {
	RequireTenant         bool     `json:"require_tenant"`
	AllowPlatformViewer   bool     `json:"allow_platform_viewer"`
	MaxVisibleJobs        int      `json:"max_visible_jobs"`
	MaxVisibleWorkers     int      `json:"max_visible_workers"`
	WorkerStaleSeconds    int      `json:"worker_stale_seconds"`
	AllowedJobStates      []string `json:"allowed_job_states"`
	AllowedWorkerStatuses []string `json:"allowed_worker_statuses"`
}

func DefaultJobQueueWorkerMonitorConsoleConfig() JobQueueWorkerMonitorConsoleConfig {
	return JobQueueWorkerMonitorConsoleConfig{
		RequireTenant:       true,
		AllowPlatformViewer: true,
		MaxVisibleJobs:      100,
		MaxVisibleWorkers:   50,
		WorkerStaleSeconds:  120,
		AllowedJobStates: []string{
			JobMonitorStateQueued,
			JobMonitorStateDispatched,
			JobMonitorStateFailed,
			JobMonitorStateRetried,
			JobMonitorStateDLQ,
		},
		AllowedWorkerStatuses: []string{
			WorkerMonitorStatusActive,
			WorkerMonitorStatusIdle,
			WorkerMonitorStatusStale,
			WorkerMonitorStatusDown,
		},
	}
}

type JobMonitorEntry struct {
	TenantID      string            `json:"tenant_id"`
	JobID         string            `json:"job_id"`
	JobType       string            `json:"job_type"`
	Queue         string            `json:"queue"`
	Priority      string            `json:"priority"`
	State         string            `json:"state"`
	Attempt       int               `json:"attempt"`
	WorkerID      string            `json:"worker_id,omitempty"`
	LastError     string            `json:"last_error,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	CreatedAt     string            `json:"created_at"`
	UpdatedAt     string            `json:"updated_at"`
}

type WorkerMonitorEntry struct {
	TenantID       string            `json:"tenant_id"`
	WorkerID       string            `json:"worker_id"`
	Queue          string            `json:"queue"`
	Status         string            `json:"status"`
	Concurrency    int               `json:"concurrency"`
	ProcessedCount int               `json:"processed_count"`
	FailedCount    int               `json:"failed_count"`
	HeartbeatAt    string            `json:"heartbeat_at"`
	Metadata       map[string]string `json:"metadata,omitempty"`
	UpdatedAt      string            `json:"updated_at"`
}

type JobQueueWorkerMonitorRequest struct {
	TenantID          string `json:"tenant_id"`
	ViewerTenantID    string `json:"viewer_tenant_id,omitempty"`
	QueueFilter       string `json:"queue_filter,omitempty"`
	IncludeWorkers    bool   `json:"include_workers"`
	IncludeFailedJobs bool   `json:"include_failed_jobs"`
	CorrelationID     string `json:"correlation_id,omitempty"`
}

type JobQueueWorkerMonitorDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	QueueFilter    string `json:"queue_filter,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type JobQueueWorkerMonitorSnapshot struct {
	OK                bool                 `json:"ok"`
	TenantID          string               `json:"tenant_id"`
	ViewerTenantID    string               `json:"viewer_tenant_id"`
	QueueFilter       string               `json:"queue_filter,omitempty"`
	JobCount          int                  `json:"job_count"`
	WorkerCount       int                  `json:"worker_count"`
	QueuedCount       int                  `json:"queued_count"`
	DispatchedCount   int                  `json:"dispatched_count"`
	FailedCount       int                  `json:"failed_count"`
	RetriedCount      int                  `json:"retried_count"`
	DLQCount          int                  `json:"dlq_count"`
	ActiveWorkerCount int                  `json:"active_worker_count"`
	IdleWorkerCount   int                  `json:"idle_worker_count"`
	StaleWorkerCount  int                  `json:"stale_worker_count"`
	DownWorkerCount   int                  `json:"down_worker_count"`
	Queues            []string             `json:"queues"`
	Jobs              []JobMonitorEntry    `json:"jobs"`
	Workers           []WorkerMonitorEntry `json:"workers"`
	CorrelationID     string               `json:"correlation_id,omitempty"`
	GeneratedAt       string               `json:"generated_at"`
}

type JobQueueWorkerMonitorConsoleRuntime struct {
	config  JobQueueWorkerMonitorConsoleConfig
	mu      sync.RWMutex
	jobs    map[string]JobMonitorEntry
	workers map[string]WorkerMonitorEntry
}

func NewJobQueueWorkerMonitorConsoleRuntime(config JobQueueWorkerMonitorConsoleConfig) *JobQueueWorkerMonitorConsoleRuntime {
	defaults := DefaultJobQueueWorkerMonitorConsoleConfig()

	if config.MaxVisibleJobs <= 0 {
		config.MaxVisibleJobs = defaults.MaxVisibleJobs
	}
	if config.MaxVisibleWorkers <= 0 {
		config.MaxVisibleWorkers = defaults.MaxVisibleWorkers
	}
	if config.WorkerStaleSeconds <= 0 {
		config.WorkerStaleSeconds = defaults.WorkerStaleSeconds
	}
	if len(config.AllowedJobStates) == 0 {
		config.AllowedJobStates = defaults.AllowedJobStates
	}
	if len(config.AllowedWorkerStatuses) == 0 {
		config.AllowedWorkerStatuses = defaults.AllowedWorkerStatuses
	}

	return &JobQueueWorkerMonitorConsoleRuntime{
		config:  config,
		jobs:    make(map[string]JobMonitorEntry),
		workers: make(map[string]WorkerMonitorEntry),
	}
}

func (r *JobQueueWorkerMonitorConsoleRuntime) UpsertJob(entry JobMonitorEntry) (JobMonitorEntry, JobQueueWorkerMonitorDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.JobID = strings.TrimSpace(entry.JobID)
	entry.JobType = strings.TrimSpace(entry.JobType)
	entry.Queue = normalizeOpsConsoleValue(entry.Queue)
	entry.Priority = normalizeOpsConsoleValue(entry.Priority)
	entry.State = normalizeOpsConsoleValue(entry.State)

	decision := JobQueueWorkerMonitorDecision{
		Decision:  JobMonitorDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    JobMonitorReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = JobMonitorReasonMissingTenant
		return JobMonitorEntry{}, decision, ErrJobMonitorMissingTenant
	}

	if entry.JobID == "" {
		decision.Reason = JobMonitorReasonMissingJobID
		return JobMonitorEntry{}, decision, ErrJobMonitorMissingJobID
	}

	if entry.Queue == "" {
		decision.Reason = JobMonitorReasonMissingQueue
		return JobMonitorEntry{}, decision, ErrJobMonitorMissingQueue
	}

	if entry.State == "" || !r.jobStateAllowed(entry.State) {
		decision.Reason = JobMonitorReasonInvalidJobState
		return JobMonitorEntry{}, decision, ErrJobMonitorInvalidJobState
	}

	if entry.Attempt <= 0 {
		entry.Attempt = 1
	}
	if entry.CreatedAt == "" {
		entry.CreatedAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.jobs[jobMonitorKey(entry.TenantID, entry.JobID)] = entry
	r.mu.Unlock()

	decision.Decision = JobMonitorDecisionAllow
	decision.Allowed = true
	decision.Reason = JobMonitorReasonAllowed

	return entry, decision, nil
}

func (r *JobQueueWorkerMonitorConsoleRuntime) UpsertWorker(entry WorkerMonitorEntry) (WorkerMonitorEntry, JobQueueWorkerMonitorDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.WorkerID = strings.TrimSpace(entry.WorkerID)
	entry.Queue = normalizeOpsConsoleValue(entry.Queue)
	entry.Status = normalizeOpsConsoleValue(entry.Status)

	decision := JobQueueWorkerMonitorDecision{
		Decision:  JobMonitorDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    JobMonitorReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = JobMonitorReasonMissingTenant
		return WorkerMonitorEntry{}, decision, ErrJobMonitorMissingTenant
	}

	if entry.WorkerID == "" {
		decision.Reason = JobMonitorReasonMissingWorkerID
		return WorkerMonitorEntry{}, decision, ErrJobMonitorMissingWorkerID
	}

	if entry.Queue == "" {
		decision.Reason = JobMonitorReasonMissingQueue
		return WorkerMonitorEntry{}, decision, ErrJobMonitorMissingQueue
	}

	if entry.Status == "" || !r.workerStatusAllowed(entry.Status) {
		decision.Reason = JobMonitorReasonInvalidWorkerStatus
		return WorkerMonitorEntry{}, decision, ErrJobMonitorInvalidWorkerStatus
	}

	if entry.Concurrency <= 0 {
		entry.Concurrency = 1
	}
	if entry.HeartbeatAt == "" {
		entry.HeartbeatAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.workers[workerMonitorKey(entry.TenantID, entry.WorkerID)] = entry
	r.mu.Unlock()

	decision.Decision = JobMonitorDecisionAllow
	decision.Allowed = true
	decision.Reason = JobMonitorReasonAllowed

	return entry, decision, nil
}

func (r *JobQueueWorkerMonitorConsoleRuntime) BuildSnapshot(req JobQueueWorkerMonitorRequest) (JobQueueWorkerMonitorSnapshot, JobQueueWorkerMonitorDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	queueFilter := normalizeOpsConsoleValue(req.QueueFilter)

	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := JobQueueWorkerMonitorDecision{
		Decision:       JobMonitorDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		QueueFilter:    queueFilter,
		Reason:         JobMonitorReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = JobMonitorReasonMissingTenant
		return JobQueueWorkerMonitorSnapshot{}, decision, ErrJobMonitorMissingTenant
	}

	if viewerTenantID != tenantID && !(r.config.AllowPlatformViewer && viewerTenantID == "platform") {
		decision.Reason = JobMonitorReasonCrossTenant
		return JobQueueWorkerMonitorSnapshot{}, decision, ErrJobMonitorCrossTenant
	}

	snapshot := JobQueueWorkerMonitorSnapshot{
		OK:             true,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		QueueFilter:    queueFilter,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		GeneratedAt:    now,
	}

	queueSeen := map[string]bool{}

	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, job := range r.jobs {
		if job.TenantID != tenantID {
			continue
		}
		if queueFilter != "" && job.Queue != queueFilter {
			continue
		}
		if !req.IncludeFailedJobs && (job.State == JobMonitorStateFailed || job.State == JobMonitorStateDLQ) {
			continue
		}
		if snapshot.JobCount >= r.config.MaxVisibleJobs {
			continue
		}

		snapshot.Jobs = append(snapshot.Jobs, job)
		snapshot.JobCount++

		if !queueSeen[job.Queue] {
			queueSeen[job.Queue] = true
			snapshot.Queues = append(snapshot.Queues, job.Queue)
		}

		switch job.State {
		case JobMonitorStateQueued:
			snapshot.QueuedCount++
		case JobMonitorStateDispatched:
			snapshot.DispatchedCount++
		case JobMonitorStateFailed:
			snapshot.FailedCount++
		case JobMonitorStateRetried:
			snapshot.RetriedCount++
		case JobMonitorStateDLQ:
			snapshot.DLQCount++
		}
	}

	if req.IncludeWorkers {
		for _, worker := range r.workers {
			if worker.TenantID != tenantID {
				continue
			}
			if queueFilter != "" && worker.Queue != queueFilter {
				continue
			}
			if snapshot.WorkerCount >= r.config.MaxVisibleWorkers {
				continue
			}

			workerForSnapshot := worker
			if isWorkerHeartbeatStale(worker.HeartbeatAt, r.config.WorkerStaleSeconds) {
				workerForSnapshot.Status = WorkerMonitorStatusStale
			}

			snapshot.Workers = append(snapshot.Workers, workerForSnapshot)
			snapshot.WorkerCount++

			if !queueSeen[workerForSnapshot.Queue] {
				queueSeen[workerForSnapshot.Queue] = true
				snapshot.Queues = append(snapshot.Queues, workerForSnapshot.Queue)
			}

			switch workerForSnapshot.Status {
			case WorkerMonitorStatusActive:
				snapshot.ActiveWorkerCount++
			case WorkerMonitorStatusIdle:
				snapshot.IdleWorkerCount++
			case WorkerMonitorStatusStale:
				snapshot.StaleWorkerCount++
			case WorkerMonitorStatusDown:
				snapshot.DownWorkerCount++
			}
		}
	}

	decision.Decision = JobMonitorDecisionAllow
	decision.Allowed = true
	decision.Reason = JobMonitorReasonAllowed

	return snapshot, decision, nil
}

func (r *JobQueueWorkerMonitorConsoleRuntime) jobStateAllowed(state string) bool {
	state = normalizeOpsConsoleValue(state)
	for _, allowed := range r.config.AllowedJobStates {
		if normalizeOpsConsoleValue(allowed) == state {
			return true
		}
	}
	return false
}

func (r *JobQueueWorkerMonitorConsoleRuntime) workerStatusAllowed(status string) bool {
	status = normalizeOpsConsoleValue(status)
	for _, allowed := range r.config.AllowedWorkerStatuses {
		if normalizeOpsConsoleValue(allowed) == status {
			return true
		}
	}
	return false
}

func normalizeOpsConsoleValue(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func cloneOpsConsoleMap(input map[string]string) map[string]string {
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

func jobMonitorKey(tenantID string, jobID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(jobID)
}

func workerMonitorKey(tenantID string, workerID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(workerID)
}

func isWorkerHeartbeatStale(heartbeatAt string, staleSeconds int) bool {
	if strings.TrimSpace(heartbeatAt) == "" {
		return true
	}
	parsed, err := time.Parse(time.RFC3339Nano, strings.TrimSpace(heartbeatAt))
	if err != nil {
		return true
	}
	if staleSeconds <= 0 {
		staleSeconds = 120
	}
	return time.Since(parsed.UTC()) > time.Duration(staleSeconds)*time.Second
}

func NewOpsConsoleRuntimeID(prefix string) string {
	return fmt.Sprintf("%s%d", strings.TrimSpace(prefix), time.Now().UTC().UnixNano())
}
