package jobsqueue

import (
	"strings"
	"time"
)

var allowedJobTerminalStatuses = map[string]struct{}{
	"succeeded": {},
	"failed":    {},
	"cancelled": {},
}

type CompleteJobRequest struct {
	TenantID       string         `json:"tenant_id,omitempty"`
	JobID          string         `json:"job_id"`
	WorkerID       string         `json:"worker_id"`
	Status         string         `json:"status"`
	AttemptNo      int            `json:"attempt_no"`
	CompletionNote string         `json:"completion_note,omitempty"`
	ErrorCode      string         `json:"error_code,omitempty"`
	OutputPayload  map[string]any `json:"output_payload,omitempty"`
}

type CompleteJobResponse struct {
	JobID           string         `json:"job_id"`
	WorkerID        string         `json:"worker_id"`
	Status          string         `json:"status"`
	AttemptNo       int            `json:"attempt_no"`
	CompletionNote  string         `json:"completion_note,omitempty"`
	ErrorCode       string         `json:"error_code,omitempty"`
	OutputPayload   map[string]any `json:"output_payload,omitempty"`
	LeaseReleased   bool           `json:"lease_released"`
	FinishedAt      time.Time      `json:"finished_at"`
}

func (r CompleteJobRequest) Validate() error {
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

	if !containsValue(allowedJobTerminalStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if strings.TrimSpace(r.Status) == "failed" && strings.TrimSpace(r.ErrorCode) == "" {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "failed durumunda zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r CompleteJobResponse) Validate() error {
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

	if !containsValue(allowedJobTerminalStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if strings.TrimSpace(r.Status) == "failed" && strings.TrimSpace(r.ErrorCode) == "" {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "failed durumunda zorunlu alan",
		})
	}

	if !r.LeaseReleased {
		errs = append(errs, ValidationError{
			Field:   "lease_released",
			Message: "true olmali",
		})
	}

	if r.FinishedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "finished_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
