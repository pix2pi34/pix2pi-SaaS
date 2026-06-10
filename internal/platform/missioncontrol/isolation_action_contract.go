package missioncontrol

import (
	"strings"
	"time"
)

var allowedIsolationActionTypes = map[string]struct{}{
	"isolate":    {},
	"quarantine": {},
}

type IsolationActionRequest struct {
	TenantID        string `json:"tenant_id,omitempty"`
	IncidentID      string `json:"incident_id"`
	ServiceID       string `json:"service_id"`
	InstanceID      string `json:"instance_id,omitempty"`
	ActionType      string `json:"action_type"`
	RequestedBy     string `json:"requested_by"`
	RequestedReason string `json:"requested_reason"`
	DryRun          bool   `json:"dry_run"`
}

type IsolationActionResponse struct {
	ActionID     string    `json:"action_id"`
	IncidentID   string    `json:"incident_id"`
	ServiceID    string    `json:"service_id"`
	InstanceID   string    `json:"instance_id,omitempty"`
	ActionType   string    `json:"action_type"`
	ActionStatus string    `json:"action_status"`
	DryRun       bool      `json:"dry_run"`
	RequestedAt  time.Time `json:"requested_at"`
}

func (r IsolationActionRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.IncidentID) == "" {
		errs = append(errs, ValidationError{
			Field:   "incident_id",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.ServiceID) == "" {
		errs = append(errs, ValidationError{
			Field:   "service_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedIsolationActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if requestedBy := strings.TrimSpace(r.RequestedBy); requestedBy == "" || !actionRefPattern.MatchString(requestedBy) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.RequestedReason) == "" {
		errs = append(errs, ValidationError{
			Field:   "requested_reason",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r IsolationActionResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(r.ActionID) == "" {
		errs = append(errs, ValidationError{
			Field:   "action_id",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.IncidentID) == "" {
		errs = append(errs, ValidationError{
			Field:   "incident_id",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.ServiceID) == "" {
		errs = append(errs, ValidationError{
			Field:   "service_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedIsolationActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedActionStatuses, strings.TrimSpace(r.ActionStatus)) {
		errs = append(errs, ValidationError{
			Field:   "action_status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.RequestedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "requested_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
