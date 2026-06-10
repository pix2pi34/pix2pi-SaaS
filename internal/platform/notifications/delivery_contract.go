package notifications

import (
	"strings"
	"time"
)

var allowedNotificationDeliveryStatuses = map[string]struct{}{
	"sending":   {},
	"sent":      {},
	"failed":    {},
	"cancelled": {},
}

type ClaimNotificationDeliveryRequest struct {
	TenantID     string `json:"tenant_id,omitempty"`
	Channel      string `json:"channel"`
	WorkerID     string `json:"worker_id"`
	LeaseSeconds int    `json:"lease_seconds"`
}

type ClaimNotificationDeliveryResponse struct {
	Claimed         bool       `json:"claimed"`
	NotificationID  string     `json:"notification_id,omitempty"`
	Channel         string     `json:"channel,omitempty"`
	NotificationKey string     `json:"notification_key,omitempty"`
	RecipientRef    string     `json:"recipient_ref,omitempty"`
	Subject         string     `json:"subject,omitempty"`
	MessageBody     string     `json:"message_body,omitempty"`
	TemplateRef     string     `json:"template_ref,omitempty"`
	Priority        string     `json:"priority,omitempty"`
	Status          string     `json:"status,omitempty"`
	AttemptNo       int        `json:"attempt_no,omitempty"`
	WorkerID        string     `json:"worker_id,omitempty"`
	LeaseExpiresAt  *time.Time `json:"lease_expires_at,omitempty"`
	ClaimedAt       time.Time  `json:"claimed_at"`
}

func (r ClaimNotificationDeliveryRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !channelKeyPattern.MatchString(strings.TrimSpace(r.Channel)) || !containsValue(allowedNotificationChannels, strings.TrimSpace(r.Channel)) {
		errs = append(errs, ValidationError{
			Field:   "channel",
			Message: "desteklenmeyen veya gecersiz format",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
		errs = append(errs, ValidationError{
			Field:   "worker_id",
			Message: "gecersiz format",
		})
	}

	if r.LeaseSeconds < 5 || r.LeaseSeconds > 3600 {
		errs = append(errs, ValidationError{
			Field:   "lease_seconds",
			Message: "5-3600 araliginda olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ClaimNotificationDeliveryResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if r.ClaimedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "claimed_at",
			Message: "zorunlu alan",
		})
	}

	if r.Claimed {
		if strings.TrimSpace(r.NotificationID) == "" {
			errs = append(errs, ValidationError{
				Field:   "notification_id",
				Message: "zorunlu alan",
			})
		}

		if !channelKeyPattern.MatchString(strings.TrimSpace(r.Channel)) || !containsValue(allowedNotificationChannels, strings.TrimSpace(r.Channel)) {
			errs = append(errs, ValidationError{
				Field:   "channel",
				Message: "desteklenmeyen veya gecersiz format",
			})
		}

		if !notificationKeyPattern.MatchString(strings.TrimSpace(r.NotificationKey)) {
			errs = append(errs, ValidationError{
				Field:   "notification_key",
				Message: "gecersiz format",
			})
		}

		if !recipientRefPattern.MatchString(strings.TrimSpace(r.RecipientRef)) {
			errs = append(errs, ValidationError{
				Field:   "recipient_ref",
				Message: "gecersiz format",
			})
		}

		if !containsValue(allowedNotificationPriorities, strings.TrimSpace(r.Priority)) {
			errs = append(errs, ValidationError{
				Field:   "priority",
				Message: "desteklenmeyen deger",
			})
		}

		if !containsValue(allowedNotificationDeliveryStatuses, strings.TrimSpace(r.Status)) || strings.TrimSpace(r.Status) != "sending" {
			errs = append(errs, ValidationError{
				Field:   "status",
				Message: "sending olmali",
			})
		}

		if r.AttemptNo < 1 {
			errs = append(errs, ValidationError{
				Field:   "attempt_no",
				Message: "1 veya daha buyuk olmali",
			})
		}

		if !actorRefPattern.MatchString(strings.TrimSpace(r.WorkerID)) {
			errs = append(errs, ValidationError{
				Field:   "worker_id",
				Message: "gecersiz format",
			})
		}

		if r.LeaseExpiresAt == nil || r.LeaseExpiresAt.IsZero() {
			errs = append(errs, ValidationError{
				Field:   "lease_expires_at",
				Message: "zorunlu alan",
			})
		}

		if strings.TrimSpace(r.MessageBody) == "" && strings.TrimSpace(r.TemplateRef) == "" {
			errs = append(errs, ValidationError{
				Field:   "content",
				Message: "message_body veya template_ref zorunlu",
			})
		}
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
