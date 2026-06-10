package jobsqueue

import (
	"regexp"
	"strings"
	"time"
)

var workerKeyPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)

type ClaimJobRequest struct {
	TenantID     string `json:"tenant_id,omitempty"`
	QueueKey     string `json:"queue_key"`
	WorkerID     string `json:"worker_id"`
	LeaseSeconds int    `json:"lease_seconds"`
}

type ClaimJobResponse struct {
	Claimed        bool           `json:"claimed"`
	JobID          string         `json:"job_id,omitempty"`
	QueueKey       string         `json:"queue_key,omitempty"`
	JobKey         string         `json:"job_key,omitempty"`
	JobType        string         `json:"job_type,omitempty"`
	Priority       string         `json:"priority,omitempty"`
	Status         string         `json:"status,omitempty"`
	AttemptNo      int            `json:"attempt_no,omitempty"`
	Payload        map[string]any `json:"payload,omitempty"`
	WorkerID       string         `json:"worker_id,omitempty"`
	LeaseExpiresAt *time.Time     `json:"lease_expires_at,omitempty"`
	ClaimedAt      time.Time      `json:"claimed_at"`
}

func (r ClaimJobRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !jobQueueKeyPattern.MatchString(strings.TrimSpace(r.QueueKey)) {
		errs = append(errs, ValidationError{
			Field:   "queue_key",
			Message: "gecersiz format",
		})
	}

	if !workerKeyPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if r.LeaseSeconds < 5 || r.LeaseSeconds > 3600 {
		errs = append(errs, ValidationError{
			Field:   "lease_seconds",
			Message: "5-3600 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ClaimJobResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.ClaimedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "claimed_at",
			Message: "zorunlu alan",
		})
	}

	if r.Claimed {
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

		if strings.TrimSpace(r.Status) != "processing" {
			errs = append(errs, ValidationError{
				Field:   "status",
				Message: "processing olmali",
			})
		}

		if r.AttemptNo < 1 {
			errs = append(errs, ValidationError{
				Field:   "attempt_no",
				Message: "1 veya daha buyuk olmali",
			})
		}

		if !workerKeyPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
			errs = append(errs, ValidationError{
				Field:   "worker_id",
				Message: "gecersiz format",
			})
		}

		if r.LeaseExpiresAt == nil || r.LeaseExpiresAt.IsZero() {
			errs = append(errs, ValidationError{
				Field:   "lease_expires_at",
				Message: "zorunlu alan",
			})
		}
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
