package notifications

import (
	"strings"
	"time"
)

var allowedNotificationRecoveryActionTypes = map[string]struct{}{
	"retry":       {},
	"requeue":     {},
	"dead_letter": {},
}

var allowedNotificationRecoveryStatuses = map[string]struct{}{
	"queued":      {},
	"dead_letter": {},
}

type RecoverNotificationRequest struct {
	TenantID      string `json:"tenant_id,omitempty"`
	NotificationID string `json:"notification_id"`
	ActionType    string `json:"action_type"`
	RequestedBy   string `json:"requested_by"`
	TargetChannel string `json:"target_channel,omitempty"`
	Reason        string `json:"reason,omitempty"`
	ResetAttempts bool   `json:"reset_attempts"`
}

type RecoverNotificationResponse struct {
	NotificationID string    `json:"notification_id"`
	ActionType     string    `json:"action_type"`
	Status         string    `json:"status"`
	Channel        string    `json:"channel,omitempty"`
	AttemptNo      int       `json:"attempt_no"`
	LeaseReleased  bool      `json:"lease_released"`
	RequestedBy    string    `json:"requested_by"`
	Reason         string    `json:"reason,omitempty"`
	RequestedAt    time.Time `json:"requested_at"`
}

func (r RecoverNotificationRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !notificationKeyPattern.MatchString(strings.TrimSpace(r.NotificationID)) {
		errs = append(errs, ValidationError{
			Field:   "notification_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedNotificationRecoveryActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if targetChannel := strings.TrimSpace(r.TargetChannel); targetChannel != "" {
		if !channelKeyPattern.MatchString(targetChannel) || !containsValue(allowedNotificationChannels, targetChannel) {
			errs = append(errs, ValidationError{
				Field:   "target_channel",
				Message: "desteklenmeyen veya gecersiz format",
			})
		}
	}

	if strings.TrimSpace(r.ActionType) == "requeue" && strings.TrimSpace(r.TargetChannel) == "" {
		errs = append(errs, ValidationError{
			Field:   "target_channel",
			Message: "requeue icin zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r RecoverNotificationResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !notificationKeyPattern.MatchString(strings.TrimSpace(r.NotificationID)) {
		errs = append(errs, ValidationError{
			Field:   "notification_id",
			Message: "gecersiz format",
		})
	}

	if !containsValue(allowedNotificationRecoveryActionTypes, strings.TrimSpace(r.ActionType)) {
		errs = append(errs, ValidationError{
			Field:   "action_type",
			Message: "desteklenmeyen deger",
		})
	}

	if !containsValue(allowedNotificationRecoveryStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if channel := strings.TrimSpace(r.Channel); channel != "" {
		if !channelKeyPattern.MatchString(channel) || !containsValue(allowedNotificationChannels, channel) {
			errs = append(errs, ValidationError{
				Field:   "channel",
				Message: "desteklenmeyen veya gecersiz format",
			})
		}
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if r.AttemptNo < 0 || r.AttemptNo > 100 {
		errs = append(errs, ValidationError{
			Field:   "attempt_no",
			Message: "0-100 araliginda olmali",
		})
	}

	if !r.LeaseReleased {
		errs = append(errs, ValidationError{
			Field:   "lease_released",
			Message: "true olmali",
		})
	}

	if r.RequestedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "requested_at",
			Message: "zorunlu alan",
		})
	}

	if strings.TrimSpace(r.ActionType) == "dead_letter" && strings.TrimSpace(r.Status) != "dead_letter" {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "dead_letter action icin dead_letter olmali",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
