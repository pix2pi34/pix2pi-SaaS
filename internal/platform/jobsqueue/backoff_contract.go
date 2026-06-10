package jobsqueue

import (
	"strings"
	"time"
)

var allowedBackoffStrategies = map[string]struct{}{
	"fixed":       {},
	"linear":      {},
	"exponential": {},
}

type CalculateJobBackoffRequest struct {
	TenantID          string `json:"tenant_id,omitempty"`
	JobID             string `json:"job_id"`
	Strategy          string `json:"strategy"`
	AttemptNo         int    `json:"attempt_no"`
	BaseDelaySeconds  int    `json:"base_delay_seconds"`
	MaxDelaySeconds   int    `json:"max_delay_seconds"`
	JitterPercent     int    `json:"jitter_percent"`
	LastErrorCode     string `json:"last_error_code,omitempty"`
}

type CalculateJobBackoffResponse struct {
	JobID              string    `json:"job_id"`
	Strategy           string    `json:"strategy"`
	AttemptNo          int       `json:"attempt_no"`
	BaseDelaySeconds   int       `json:"base_delay_seconds"`
	MaxDelaySeconds    int       `json:"max_delay_seconds"`
	JitterPercent      int       `json:"jitter_percent"`
	PlannedDelaySeconds int      `json:"planned_delay_seconds"`
	RetryAt            time.Time `json:"retry_at"`
	CalculatedAt       time.Time `json:"calculated_at"`
}

func (r CalculateJobBackoffRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedBackoffStrategies, strings.TrimSpace(r.Strategy)) {
		errs = append(errs, ValidationError{
			Field:   "strategy",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if r.BaseDelaySeconds < 1 || r.BaseDelaySeconds > 86400 {
		errs = append(errs, ValidationError{
			Field:   "base_delay_seconds",
			Message: "1-86400 araliginda olmali",
		})
	}

	if r.MaxDelaySeconds < 1 || r.MaxDelaySeconds > 604800 {
		errs = append(errs, ValidationError{
			Field:   "max_delay_seconds",
			Message: "1-604800 araliginda olmali",
		})
	}

	if r.MaxDelaySeconds < r.BaseDelaySeconds {
		errs = append(errs, ValidationError{
			Field:   "max_delay_seconds",
			Message: "base_delay_seconds degerinden kucuk olamaz",
		})
	}

	if r.JitterPercent < 0 || r.JitterPercent > 100 {
		errs = append(errs, ValidationError{
			Field:   "jitter_percent",
			Message: "0-100 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r CalculateJobBackoffResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedBackoffStrategies, strings.TrimSpace(r.Strategy)) {
		errs = append(errs, ValidationError{
			Field:   "strategy",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "1-100 araliginda olmali",
		})
	}

	if r.BaseDelaySeconds < 1 || r.BaseDelaySeconds > 86400 {
		errs = append(errs, ValidationError{
			Field:   "base_delay_seconds",
			Message: "1-86400 araliginda olmali",
		})
	}

	if r.MaxDelaySeconds < 1 || r.MaxDelaySeconds > 604800 {
		errs = append(errs, ValidationError{
			Field:   "max_delay_seconds",
			Message: "1-604800 araliginda olmali",
		})
	}

	if r.PlannedDelaySeconds < 1 || r.PlannedDelaySeconds > r.MaxDelaySeconds {
		errs = append(errs, ValidationError{
			Field:   "planned_delay_seconds",
			Message: "1 ile max_delay_seconds arasinda olmali",
		})
	}

	if r.RetryAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "retry_at",
			Message: "zorunlu alan",
		})
	}

	if r.CalculatedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "calculated_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
