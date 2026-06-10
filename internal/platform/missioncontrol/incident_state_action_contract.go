package missioncontrol

import (
	"strings"
	"time"
)

var allowedIncidentStateActionTypes = map[string]struct{}{
	"acknowledge": {},
	"resolve":     {},
}

var allowedIncidentRuntimeStatuses = map[string]struct{}{
	"open":          {},
	"acknowledged":  {},
	"investigating": {},
	"mitigated":     {},
	"resolved":      {},
	"closed":        {},
}

type IncidentStateActionRequest struct {
	TenantID      string `json:"tenant_id,omitempty"`
	IncidentID    string `json:"incident_id"`
	ServiceID     string `json:"service_id"`
	ActionType    string `json:"action_type"`
	RequestedBy   string `json:"requested_by"`
	ResponseNote  string `json:"response_note,omitempty"`
	DryRun        bool   `json:"dry_run"`
}

type IncidentStateActionResponse struct {
	ActionID        string    `json:"action_id"`
	IncidentID      string    `json:"incident_id"`
	ServiceID       string    `json:"service_id"`
	ActionType      string    `json:"action_type"`
	ActionStatus    string    `json:"action_status"`
	IncidentStatus  string    `json:"incident_status"`
	ResponseNote    string    `json:"response_note,omitempty"`
	DryRun          bool      `json:"dry_run"`
	RequestedAt     time.Time `json:"requested_at"`
}

func (r IncidentStateActionRequest) Validate() error {
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

	if !containsValue(allowedIncidentStateActionTypes, strings.TrimSpace(r.ActionType)) {
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

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r IncidentStateActionResponse) Validate() error {
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

	if !containsValue(allowedIncidentStateActionTypes, strings.TrimSpace(r.ActionType)) {
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

	if !containsValue(allowedIncidentRuntimeStatuses, strings.TrimSpace(r.IncidentStatus)) {
		errs = append(errs, ValidationError{
			Field:   "incident_status",
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
