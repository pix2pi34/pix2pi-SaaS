package missioncontrol

import (
	"regexp"
	"strings"
	"time"
)

var actionRefPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)

var allowedActionStatuses = map[string]struct{}{
	"requested": {},
	"approved":  {},
	"running":   {},
	"succeeded": {},
	"failed":    {},
	"cancelled": {},
}

type RestartActionRequest struct {
	TenantID        string `json:"tenant_id,omitempty"`
	IncidentID      string `json:"incident_id"`
	ServiceID       string `json:"service_id"`
	InstanceID      string `json:"instance_id,omitempty"`
	RequestedBy     string `json:"requested_by"`
	RequestedReason string `json:"requested_reason"`
	DryRun          bool   `json:"dry_run"`
}

type RestartActionResponse struct {
	ActionID     string    `json:"action_id"`
	IncidentID   string    `json:"incident_id"`
	ServiceID    string    `json:"service_id"`
	InstanceID   string    `json:"instance_id,omitempty"`
	ActionType   string    `json:"action_type"`
	ActionStatus string    `json:"action_status"`
	DryRun       bool      `json:"dry_run"`
	RequestedAt  time.Time `json:"requested_at"`
}

func (r RestartActionRequest) Validate() error {
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

func (r RestartActionResponse) Validate() error {
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

	if r.ActionType != "restart" {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "restart olmali",
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
