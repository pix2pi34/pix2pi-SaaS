package jobsqueue

import (
	"strings"
	"time"
)

var allowedJobRecoveryActionTypes = map[string]struct{}{
	"retry":       {},
	"requeue":     {},
	"dead_letter": {},
}

type RecoverJobRequest struct {
	TenantID        string `json:"tenant_id,omitempty"`
	JobID           string `json:"job_id"`
	ActionType      string `json:"action_type"`
	RequestedBy     string `json:"requested_by"`
	TargetQueueKey  string `json:"target_queue_key,omitempty"`
	Reason          string `json:"reason,omitempty"`
	ResetAttempts   bool   `json:"reset_attempts"`
}

type RecoverJobResponse struct {
	JobID          string    `json:"job_id"`
	ActionType     string    `json:"action_type"`
	Status         string    `json:"status"`
	QueueKey       string    `json:"queue_key,omitempty"`
	AttemptNo      int       `json:"attempt_no"`
	LeaseReleased  bool      `json:"lease_released"`
	RequestedBy    string    `json:"requested_by"`
	Reason         string    `json:"reason,omitempty"`
	RequestedAt    time.Time `json:"requested_at"`
}

func (r RecoverJobRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedJobRecoveryActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if !workerKeyPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if targetQueueKey := strings.TrimSpace(r.TargetQueueKey); targetQueueKey != "" && !jobQueueKeyPattern.MatchString(targetQueueKey) {
		errs = append(errs, ValidationError{
			Field:   "target_queue_key",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ActionType) == "requeue" && strings.TrimSpace(r.TargetQueueKey) == "" {
		errs = append(errs, ValidationError{
			Field:   "target_queue_key",
			Message: "requeue icin zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r RecoverJobResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedJobRecoveryActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedJobStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if queueKey := strings.TrimSpace(r.QueueKey); queueKey != "" && !jobQueueKeyPattern.MatchString(queueKey) {
		errs = append(errs, ValidationError{
			Field:   "queue_key",
			Message: "gecersiz format",
		})
	}

	if !workerKeyPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if r.AttemptNo < 0 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "0-100 araliginda olmali",
		})
	}

	if !r.LeaseReleased {
		errs = append(errs, ValidationError{
			Field:   "lease_released",
			Message: "true olmali",
		})
	}

	if r.RequestedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "requested_at",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.ActionType) == "dead_letter" && strings.TrimSpace(r.Status) != "dead_letter" {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "dead_letter action icin dead_letter olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
