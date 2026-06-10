package missioncontrol

import (
	"strings"
	"time"
)

var allowedIncidentTimelineEventTypes = map[string]struct{}{
	"action":       {},
	"state_change": {},
	"note":         {},
	"system":       {},
}

type IncidentTimelineRequest struct {
	TenantID            string `json:"tenant_id,omitempty"`
	IncidentID          string `json:"incident_id"`
	ServiceID           string `json:"service_id"`
	IncludeActions      bool   `json:"include_actions"`
	IncludeStateChanges bool   `json:"include_state_changes"`
	IncludeNotes        bool   `json:"include_notes"`
	Limit               int    `json:"limit"`
}

type IncidentTimelineItem struct {
	EventID         string    `json:"event_id"`
	IncidentID      string    `json:"incident_id"`
	ServiceID       string    `json:"service_id"`
	EventType       string    `json:"event_type"`
	ActionType      string    `json:"action_type,omitempty"`
	ActionStatus    string    `json:"action_status,omitempty"`
	IncidentStatus  string    `json:"incident_status,omitempty"`
	ActorRef        string    `json:"actor_ref,omitempty"`
	Message         string    `json:"message,omitempty"`
	OccurredAt      time.Time `json:"occurred_at"`
}

type IncidentTimelineResponse struct {
	GeneratedAt time.Time              `json:"generated_at"`
	Count       int                    `json:"count"`
	Items       []IncidentTimelineItem `json:"items"`
}

func (r IncidentTimelineRequest) Validate() error {
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

	if r.Limit < 1 || r.Limit > 500 {
		errs = append(errs, ValidationError{
			Field:   "limit",
			Message: "1-500 araliginda olmali",
		})
	}

	if !r.IncludeActions && !r.IncludeStateChanges && !r.IncludeNotes {
		errs = append(errs, ValidationError{
			Field:   "include_flags",
			Message: "en az bir timeline kaynagi secilmeli",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (i IncidentTimelineItem) Validate() error {
	errs := make(ValidationErrors, 0)

	if strings.TrimSpace(i.EventID) == "" {
		errs = append(errs, ValidationError{
			Field:   "event_id",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(i.IncidentID) == "" {
		errs = append(errs, ValidationError{
			Field:   "incident_id",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(i.ServiceID) == "" {
		errs = append(errs, ValidationError{
			Field:   "service_id",
			Message: "zorunlu alan",
		})
	}

	if !containsValue(allowedIncidentTimelineEventTypes, strings.TrimSpace(i.EventType)) {
		errs = append(errs, ValidationError{
			Field:   "event_type",
			Message: "desteklenmeyen deger",
		})
	}

	if i.OccurredAt.IsZero() {
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

func (r IncidentTimelineResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.GeneratedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "generated_at",
			Message: "zorunlu alan",
		})
	}

	if r.Count < 0 {
		errs = append(errs, ValidationError{
			Field:   "count",
			Message: "negatif olamaz",
		})
	}

	for idx, item := range r.Items {
		if err := item.Validate(); err != nil {
			errs = append(errs, ValidationError{
				Field:   "items[" + strings.TrimSpace(string(rune(idx+'0'))) + "]",
				Message: err.Error(),
			})
		}
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
