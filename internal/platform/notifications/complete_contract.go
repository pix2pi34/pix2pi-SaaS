package notifications

import (
	"strings"
	"time"
)

var allowedNotificationCompletionStatuses = map[string]struct{}{
	"sent":      {},
	"failed":    {},
	"cancelled": {},
}

type CompleteNotificationDeliveryRequest struct {
	TenantID        string `json:"tenant_id,omitempty"`
	NotificationID  string `json:"notification_id"`
	WorkerID        string `json:"worker_id"`
	Status          string `json:"status"`
	AttemptNo       int    `json:"attempt_no"`
	DeliveryRef     string `json:"delivery_ref,omitempty"`
	ProviderCode    string `json:"provider_code,omitempty"`
	ErrorCode       string `json:"error_code,omitempty"`
	CompletionNote  string `json:"completion_note,omitempty"`
}

type CompleteNotificationDeliveryResponse struct {
	NotificationID string    `json:"notification_id"`
	WorkerID       string    `json:"worker_id"`
	Status         string    `json:"status"`
	AttemptNo      int       `json:"attempt_no"`
	DeliveryRef    string    `json:"delivery_ref,omitempty"`
	ProviderCode   string    `json:"provider_code,omitempty"`
	ErrorCode      string    `json:"error_code,omitempty"`
	CompletionNote string    `json:"completion_note,omitempty"`
	LeaseReleased  bool      `json:"lease_released"`
	CompletedAt    time.Time `json:"completed_at"`
}

func (r CompleteNotificationDeliveryRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !notificationKeyPattern.MatchString(strings.TrimSpace(r.NotificationID)) {
		errs = append(errs, ValidationError{
			Field:   "notification_id",
			Message: "gecersiz format",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedNotificationCompletionStatuses, strings.TrimSpace(r.Status)) {
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

	if strings.TrimSpace(r.DeliveryRef) != "" && !notificationKeyPattern.MatchString(strings.TrimSpace(r.DeliveryRef)) {
		errs = append(errs, ValidationError{
			Field:   "delivery_ref",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ProviderCode) != "" && !notificationKeyPattern.MatchString(strings.TrimSpace(r.ProviderCode)) {
		errs = append(errs, ValidationError{
			Field:   "provider_code",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ErrorCode) != "" && !notificationKeyPattern.MatchString(strings.TrimSpace(r.ErrorCode)) {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "gecersiz format",
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

func (r CompleteNotificationDeliveryResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !notificationKeyPattern.MatchString(strings.TrimSpace(r.NotificationID)) {
		errs = append(errs, ValidationError{
			Field:   "notification_id",
			Message: "gecersiz format",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedNotificationCompletionStatuses, strings.TrimSpace(r.Status)) {
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

	if strings.TrimSpace(r.DeliveryRef) != "" && !notificationKeyPattern.MatchString(strings.TrimSpace(r.DeliveryRef)) {
		errs = append(errs, ValidationError{
			Field:   "delivery_ref",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ProviderCode) != "" && !notificationKeyPattern.MatchString(strings.TrimSpace(r.ProviderCode)) {
		errs = append(errs, ValidationError{
			Field:   "provider_code",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.ErrorCode) != "" && !notificationKeyPattern.MatchString(strings.TrimSpace(r.ErrorCode)) {
		errs = append(errs, ValidationError{
			Field:   "error_code",
			Message: "gecersiz format",
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

	if r.CompletedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "completed_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
