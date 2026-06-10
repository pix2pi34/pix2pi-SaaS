package webhooks

import (
	"regexp"
	"strings"
	"time"
)

var (
	webhookKeyPattern       = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	webhookEventTypePattern = regexp.MustCompile(`^[a-z][a-z0-9._:-]*$`)
	actorRefPattern        = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var allowedWebhookDeliveryStatuses = map[string]struct{}{
	"pending":   {},
	"sending":   {},
	"delivered": {},
	"failed":    {},
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

type ValidationErrors []ValidationError

func (v ValidationErrors) Error() string {
	if len(v) == 0 {
		return "validation failed"
	}

	parts := make([]string, 0, len(v))
	for _, item := range v {
		parts = append(parts, item.Field+": "+item.Message)
	}

	return strings.Join(parts, ", ")
}

func containsValue(values map[string]struct{}, value string) bool {
	_, ok := values[value]
	return ok
}

type DeliverWebhookRequest struct {
	TenantID        string         `json:"tenant_id,omitempty"`
	WebhookID       string         `json:"webhook_id"`
	SubscriptionID  string         `json:"subscription_id"`
	EventID         string         `json:"event_id"`
	EventType       string         `json:"event_type"`
	TargetURL       string         `json:"target_url"`
	SecretRef       string         `json:"secret_ref"`
	Payload         map[string]any `json:"payload"`
	RequestedBy     string         `json:"requested_by"`
}

type DeliverWebhookResponse struct {
	WebhookID      string    `json:"webhook_id"`
	SubscriptionID string    `json:"subscription_id"`
	EventID        string    `json:"event_id"`
	EventType      string    `json:"event_type"`
	TargetURL      string    `json:"target_url"`
	Signature      string    `json:"signature"`
	Status         string    `json:"status"`
	AttemptNo      int       `json:"attempt_no"`
	DeliveryRef    string    `json:"delivery_ref,omitempty"`
	RequestedBy    string    `json:"requested_by"`
	SignedAt       time.Time `json:"signed_at"`
}

func (r DeliverWebhookRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.WebhookID)) {
		errs = append(errs, ValidationError{Field: "webhook_id", Message: "gecersiz format"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.SubscriptionID)) {
		errs = append(errs, ValidationError{Field: "subscription_id", Message: "gecersiz format"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.EventID)) {
		errs = append(errs, ValidationError{Field: "event_id", Message: "gecersiz format"})
	}

	if !webhookEventTypePattern.MatchString(strings.TrimSpace(r.EventType)) {
		errs = append(errs, ValidationError{Field: "event_type", Message: "gecersiz format"})
	}

	targetURL := strings.TrimSpace(r.TargetURL)
	if targetURL == "" || !(strings.HasPrefix(targetURL, "https://") || strings.HasPrefix(targetURL, "http://")) {
		errs = append(errs, ValidationError{Field: "target_url", Message: "http veya https URL olmali"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.SecretRef)) {
		errs = append(errs, ValidationError{Field: "secret_ref", Message: "gecersiz format"})
	}

	if len(r.Payload) == 0 {
		errs = append(errs, ValidationError{Field: "payload", Message: "bos olamaz"})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r DeliverWebhookResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.WebhookID)) {
		errs = append(errs, ValidationError{Field: "webhook_id", Message: "gecersiz format"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.SubscriptionID)) {
		errs = append(errs, ValidationError{Field: "subscription_id", Message: "gecersiz format"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.EventID)) {
		errs = append(errs, ValidationError{Field: "event_id", Message: "gecersiz format"})
	}

	if !webhookEventTypePattern.MatchString(strings.TrimSpace(r.EventType)) {
		errs = append(errs, ValidationError{Field: "event_type", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.TargetURL) == "" {
		errs = append(errs, ValidationError{Field: "target_url", Message: "zorunlu alan"})
	}

	if !webhookKeyPattern.MatchString(strings.TrimSpace(r.Signature)) {
		errs = append(errs, ValidationError{Field: "signature", Message: "gecersiz format"})
	}

	if !containsValue(allowedWebhookDeliveryStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{Field: "status", Message: "desteklenmeyen deger"})
	}

	if r.AttemptNo < 1 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{Field: "attempt_no", Message: "1-100 araliginda olmali"})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if r.SignedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "signed_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
