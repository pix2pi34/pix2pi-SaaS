package notifications

import (
	"regexp"
	"strings"
	"time"
)

var (
	notificationKeyPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	recipientRefPattern    = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:@+-]*$`)
	channelKeyPattern      = regexp.MustCompile(`^[a-z][a-z0-9_]*$`)
	actorRefPattern        = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	templateRefPattern     = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var allowedNotificationChannels = map[string]struct{}{
	"email":   {},
	"sms":     {},
	"push":    {},
	"webhook": {},
	"in_app":  {},
}

var allowedNotificationPriorities = map[string]struct{}{
	"low":      {},
	"normal":   {},
	"high":     {},
	"critical": {},
}

var allowedNotificationStatuses = map[string]struct{}{
	"queued":    {},
	"scheduled": {},
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

type CreateNotificationRequest struct {
	TenantID        string         `json:"tenant_id,omitempty"`
	Channel         string         `json:"channel"`
	NotificationKey string         `json:"notification_key"`
	RecipientRef    string         `json:"recipient_ref"`
	Subject         string         `json:"subject,omitempty"`
	MessageBody     string         `json:"message_body,omitempty"`
	TemplateRef     string         `json:"template_ref,omitempty"`
	Priority        string         `json:"priority"`
	DedupKey        string         `json:"dedup_key,omitempty"`
	ScheduledAt     *time.Time     `json:"scheduled_at,omitempty"`
	RequestedBy     string         `json:"requested_by"`
	Metadata        map[string]any `json:"metadata,omitempty"`
}

type CreateNotificationResponse struct {
	NotificationID  string     `json:"notification_id"`
	Channel         string     `json:"channel"`
	NotificationKey string     `json:"notification_key"`
	RecipientRef    string     `json:"recipient_ref"`
	Priority        string     `json:"priority"`
	Status          string     `json:"status"`
	DedupMatched    bool       `json:"dedup_matched"`
	ScheduledAt     *time.Time `json:"scheduled_at,omitempty"`
	EnqueuedAt      time.Time  `json:"enqueued_at"`
}

func (r CreateNotificationRequest) Validate() error {
	errs := make(ValidationErrors, 0)

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

	if strings.TrimSpace(r.TemplateRef) != "" && !templateRefPattern.MatchString(strings.TrimSpace(r.TemplateRef)) {
		errs = append(errs, ValidationError{
			Field:   "template_ref",
			Message: "gecersiz format",
		})
	}

	if strings.TrimSpace(r.MessageBody) == "" && strings.TrimSpace(r.TemplateRef) == "" {
		errs = append(errs, ValidationError{
			Field:   "content",
			Message: "message_body veya template_ref zorunlu",
		})
	}

	if !actorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{
			Field:   "requested_by",
			Message: "gecersiz format",
		})
	}

	if r.ScheduledAt != nil && r.ScheduledAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "scheduled_at",
			Message: "gecersiz zaman",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r CreateNotificationResponse) Validate() error {
	errs := make(ValidationErrors, 0)

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

	if !containsValue(allowedNotificationStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{
			Field:   "status",
			Message: "desteklenmeyen deger",
		})
	}

	if r.EnqueuedAt.IsZero() {
		errs = append(errs, ValidationError{
			Field:   "enqueued_at",
			Message: "zorunlu alan",
		})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
