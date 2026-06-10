package webhooks

import (
	"strings"
	"time"
)

var allowedWebhookRecoveryActions = map[string]struct{}{
	"retry":       {},
	"requeue":     {},
	"dead_letter": {},
}

var allowedWebhookRecoveryStatuses = map[string]struct{}{
	"pending":     {},
	"dead_letter": {},
}

type ApplyWebhookRecoveryRequest struct {
	TenantID      string     `json:"tenant_id,omitempty"`
	WebhookID     string     `json:"webhook_id"`
	DeliveryRef   string     `json:"delivery_ref"`
	ActionType    string     `json:"action_type"`
	RequestedBy   string     `json:"requested_by"`
	Reason        string     `json:"reason,omitempty"`
	ResetAttempts bool       `json:"reset_attempts"`
	NextAttemptAt *time.Time `json:"next_attempt_at,omitempty"`
}

type ApplyWebhookRecoveryResponse struct {
	WebhookID      string     `json:"webhook_id"`
	DeliveryRef   string     `json:"delivery_ref"`
	ActionType    string     `json:"action_type"`
	Status        string     `json:"status"`
	AttemptNo     int        `json:"attempt_no"`
	NextAttemptAt *time.Time `json:"next_attempt_at,omitempty"`
	LeaseReleased bool       `json:"lease_released"`
	RequestedBy   string     `json:"requested_by"`
	Reason        string     `json:"reason,omitempty"`
	RequestedAt   time.Time  `json:"requested_at"`
}

func (r ApplyWebhookRecoveryRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.WebhookID)) {
		errs = append(errs, ValidationError{Field: "webhook_id", Message: "gecersiz format"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.DeliveryRef)) {
		errs = append(errs, ValidationError{Field: "delivery_ref", Message: "gecersiz format"})
	}

	if !containsValue(allowedWebhookRecoveryActions, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{Field: "action_type", Message: "desteklenmeyen deger"})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.ActionType) == "requeue" && r.NextAttemptAt == nil {
		errs = append(errs, ValidationError{Field: "next_attempt_at", Message: "requeue icin zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ApplyWebhookRecoveryResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.WebhookID)) {
		errs = append(errs, ValidationError{Field: "webhook_id", Message: "gecersiz format"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.DeliveryRef)) {
		errs = append(errs, ValidationError{Field: "delivery_ref", Message: "gecersiz format"})
	}

	if !containsValue(allowedWebhookRecoveryActions, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{Field: "action_type", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedWebhookRecoveryStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{Field: "status", Message: "desteklenmeyen deger"})
	}

	if r.AttemptNo < 0 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{Field: "attempt_no", Message: "0-100 araliginda olmali"})
	}

	if !r.LeaseReleased {
		errs = append(errs, ValidationError{Field: "lease_released", Message: "true olmali"})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.ActionType) == "dead_letter" && strings.TrimSpace(r.Status) != "dead_letter" {
		errs = append(errs, ValidationError{Field: "status", Message: "dead_letter action icin dead_letter olmali"})
	}

	if r.RequestedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "requested_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
