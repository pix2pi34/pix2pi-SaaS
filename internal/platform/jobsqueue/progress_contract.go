package jobsqueue

import (
	"strings"
	"time"
)

var allowedJobProgressStatuses = map[string]struct{}{
	"processing": {},
	"succeeded":  {},
	"failed":     {},
	"cancelled":  {},
}

type UpdateJobProgressRequest struct {
	TenantID           string `json:"tenant_id,omitempty"`
	JobID              string `json:"job_id"`
	WorkerID           string `json:"worker_id"`
	Status             string `json:"status"`
	ProgressPercent    int    `json:"progress_percent"`
	Message            string `json:"message,omitempty"`
	AttemptNo          int    `json:"attempt_no"`
	LeaseExtendSeconds int    `json:"lease_extend_seconds,omitempty"`
}

type UpdateJobProgressResponse struct {
	JobID           string     `json:"job_id"`
	WorkerID        string     `json:"worker_id"`
	Status          string     `json:"status"`
	ProgressPercent int        `json:"progress_percent"`
	AttemptNo       int        `json:"attempt_no"`
	Message         string     `json:"message,omitempty"`
	LeaseExpiresAt  *time.Time `json:"lease_expires_at,omitempty"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

func (r UpdateJobProgressRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !workerKeyPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedJobProgressStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.ProgressPercent < 0 || r.ProgressPercent > 100 {
		errs = append(errs, ValidationError{
			Field:   "progress_percent",
			Message: "0-100 araliginda olmali",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if r.LeaseExtendSeconds < 0 || r.LeaseExtendSeconds > 3600 {
		errs = append(errs, ValidationError{
			Field:   "lease_extend_seconds",
			Message: "0-3600 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r UpdateJobProgressResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !workerKeyPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedJobProgressStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.ProgressPercent < 0 || r.ProgressPercent > 100 {
		errs = append(errs, ValidationError{
			Field:   "progress_percent",
			Message: "0-100 araliginda olmali",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if r.UpdatedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "updated_at",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.Status) == "processing" && r.LeaseExpiresAt == nil {
		errs = append(errs, ValidationError{
			Field:   "lease_expires_at",
			Message: "processing durumunda zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
