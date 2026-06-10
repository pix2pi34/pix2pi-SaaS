package jobsqueue

import (
	"strings"
	"time"
)

var allowedJobAuditEventTypes = map[string]struct{}{
	"enqueued":      {},
	"claimed":       {},
	"progressed":    {},
	"completed":     {},
	"failed":        {},
	"cancelled":     {},
	"retried":       {},
	"requeued":      {},
	"dead_lettered": {},
}

type RecordJobAuditEventRequest struct {
	TenantID        string         `json:"tenant_id,omitempty"`
	JobID           string         `json:"job_id"`
	EventType       string         `json:"event_type"`
	ActorRef        string         `json:"actor_ref"`
	Status          string         `json:"status"`
	AttemptNo       int            `json:"attempt_no"`
	Message         string         `json:"message,omitempty"`
	Metadata        map[string]any `json:"metadata,omitempty"`
}

type RecordJobAuditEventResponse struct {
	AuditID      string         `json:"audit_id"`
	JobID        string         `json:"job_id"`
	EventType    string         `json:"event_type"`
	ActorRef     string         `json:"actor_ref"`
	Status       string         `json:"status"`
	AttemptNo    int            `json:"attempt_no"`
	Message      string         `json:"message,omitempty"`
	Metadata     map[string]any `json:"metadata,omitempty"`
	OccurredAt   time.Time      `json:"occurred_at"`
}

func (r RecordJobAuditEventRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedJobAuditEventTypes, strings.TrimSpace(r.EventType)) {
		errs = append(errs, ValidationError{
			Field:   "event_type",
			Message: "desteklenmeyen deger",
		})
	}

	if strings.TrimSpace(r.ActorRef) == "" {
		errs = append(errs, ValidationError{
			Field:   "actor_ref",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.Status) != "" && !containsValue(allowedJobStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 0 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "0-100 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r RecordJobAuditEventResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.AuditID) == "" {
		errs = append(errs, ValidationError{
			Field:   "audit_id",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.JobID) == "" {
		errs = append(errs, ValidationError{
			Field:   "job_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedJobAuditEventTypes, strings.TrimSpace(r.EventType)) {
		errs = append(errs, ValidationError{
			Field:   "event_type",
			Message: "desteklenmeyen deger",
		})
	}

	if strings.TrimSpace(r.ActorRef) == "" {
		errs = append(errs, ValidationError{
			Field:   "actor_ref",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.Status) != "" && !containsValue(allowedJobStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.AttemptNo < 0 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "0-100 araliginda olmali",
		})
	}

	if r.OccurredAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "occurred_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
