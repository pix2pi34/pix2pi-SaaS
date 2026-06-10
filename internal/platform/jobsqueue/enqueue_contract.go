package jobsqueue

import (
	"regexp"
	"strings"
	"time"
)

var (
	jobQueueKeyPattern = regexp.MustCompile(`^[a-z0-9][a-z0-9._-]*$`)
	jobKeyPattern      = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var allowedJobPriorities = map[string]struct{}{
	"low":      {},
	"normal":   {},
	"high":     {},
	"critical": {},
}

var allowedJobStatuses = map[string]struct{}{
	"queued":     {},
	"scheduled":  {},
	"processing": {},
	"succeeded":  {},
	"failed":     {},
	"cancelled":  {},
	"dead_letter": {},
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

type ValidationErrors []ValidationError

func (v ValidationErrors) Error() string {
	if len(v) == 0 {
		return "validation failed"
	}

	parts := make([]string, 0, len(v))
	for _, item := range v {
		parts = append(parts, item.Field+": "+item.Message)
	}

	return strings.Join(parts, ", ")
}

func containsValue(values map[string]struct{}, value string) bool {
	_, ok := values[value]
	return ok
}

type EnqueueJobRequest struct {
	TenantID       string         `json:"tenant_id,omitempty"`
	QueueKey       string         `json:"queue_key"`
	JobKey         string         `json:"job_key"`
	JobType        string         `json:"job_type"`
	Priority       string         `json:"priority"`
	DedupKey       string         `json:"dedup_key,omitempty"`
	Payload        map[string]any `json:"payload,omitempty"`
	ScheduledAt    *time.Time     `json:"scheduled_at,omitempty"`
	RequestedBy    string         `json:"requested_by"`
	MaxAttempts    int            `json:"max_attempts"`
}

type EnqueueJobResponse struct {
	JobID        string     `json:"job_id"`
	QueueKey     string     `json:"queue_key"`
	JobKey       string     `json:"job_key"`
	JobType      string     `json:"job_type"`
	Priority     string     `json:"priority"`
	Status       string     `json:"status"`
	DedupMatched bool       `json:"dedup_matched"`
	ScheduledAt  *time.Time `json:"scheduled_at,omitempty"`
	EnqueuedAt   time.Time  `json:"enqueued_at"`
}

func (r EnqueueJobRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !jobQueueKeyPattern.MatchString(strings.TrimSpace(r.QueueKey)) {
		errs = append(errs, ValidationError{
			Field:   "queue_key",
			Message: "gecersiz format",
		})
	}

	if !jobKeyPattern.MatchString(strings.TrimSpace(r.JobKey)) {
		errs = append(errs, ValidationError{
			Field:   "job_key",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.JobType) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_type",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedJobPriorities, strings.TrimSpace(r.Priority)) {
		errs = append(errs, ValidationError{
			Field:   "priority",
			Message: "desteklenmeyen deger",
		})
	}

	if strings.TrimSpace(r.RequestedBy) == "" {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "zorunlu alan",
		})
	}

	if r.MaxAttempts < 1 || r.MaxAttempts > 100 {
		errs = append(errs, ValidationError{
			Field:   "max_attempts",
			Message: "1-100 araliginda olmali",
		})
	}

	if r.ScheduledAt != nil && r.ScheduledAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "scheduled_at",
			Message: "gecersiz zaman",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r EnqueueJobResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !jobQueueKeyPattern.MatchString(strings.TrimSpace(r.QueueKey)) {
		errs = append(errs, ValidationError{
			Field:   "queue_key",
			Message: "gecersiz format",
		})
	}

	if !jobKeyPattern.MatchString(strings.TrimSpace(r.JobKey)) {
		errs = append(errs, ValidationError{
			Field:   "job_key",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.JobType) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_type",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedJobPriorities, strings.TrimSpace(r.Priority)) {
		errs = append(errs, ValidationError{
			Field:   "priority",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedJobStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.EnqueuedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "enqueued_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
