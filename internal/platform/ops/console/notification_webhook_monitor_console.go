package opsconsole

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	NotificationMonitorChannelEmail   = "EMAIL"
	NotificationMonitorChannelSMS     = "SMS"
	NotificationMonitorChannelPush    = "PUSH"
	NotificationMonitorChannelWebhook = "WEBHOOK"

	NotificationMonitorStateQueued         = "QUEUED"
	NotificationMonitorStateDelivered      = "DELIVERED"
	NotificationMonitorStateFailed         = "FAILED"
	NotificationMonitorStateRetryScheduled = "RETRY_SCHEDULED"
	NotificationMonitorStateDLQ            = "DLQ"

	NotificationMonitorDecisionAllow = "ALLOW"
	NotificationMonitorDecisionDeny  = "DENY"

	NotificationMonitorReasonAllowed            = "NOTIFICATION_MONITOR_ALLOWED"
	NotificationMonitorReasonMissingTenant      = "NOTIFICATION_MONITOR_MISSING_TENANT"
	NotificationMonitorReasonCrossTenant        = "NOTIFICATION_MONITOR_CROSS_TENANT_DENIED"
	NotificationMonitorReasonMissingDeliveryID  = "NOTIFICATION_MONITOR_MISSING_DELIVERY_ID"
	NotificationMonitorReasonMissingChannel     = "NOTIFICATION_MONITOR_MISSING_CHANNEL"
	NotificationMonitorReasonInvalidChannel     = "NOTIFICATION_MONITOR_INVALID_CHANNEL"
	NotificationMonitorReasonMissingState       = "NOTIFICATION_MONITOR_MISSING_STATE"
	NotificationMonitorReasonInvalidState       = "NOTIFICATION_MONITOR_INVALID_STATE"
	NotificationMonitorReasonMissingDestination = "NOTIFICATION_MONITOR_MISSING_DESTINATION"
)

var (
	ErrNotificationMonitorMissingTenant      = errors.New("missing notification monitor tenant id")
	ErrNotificationMonitorCrossTenant        = errors.New("cross-tenant notification monitor access denied")
	ErrNotificationMonitorMissingDeliveryID  = errors.New("missing notification monitor delivery id")
	ErrNotificationMonitorMissingChannel     = errors.New("missing notification monitor channel")
	ErrNotificationMonitorInvalidChannel     = errors.New("invalid notification monitor channel")
	ErrNotificationMonitorMissingState       = errors.New("missing notification monitor state")
	ErrNotificationMonitorInvalidState       = errors.New("invalid notification monitor state")
	ErrNotificationMonitorMissingDestination = errors.New("missing notification monitor destination")
)

type NotificationWebhookMonitorConsoleConfig struct {
	RequireTenant        bool     `json:"require_tenant"`
	AllowPlatformViewer  bool     `json:"allow_platform_viewer"`
	MaxVisibleDeliveries int      `json:"max_visible_deliveries"`
	AllowedChannels      []string `json:"allowed_channels"`
	AllowedStates        []string `json:"allowed_states"`
}

func DefaultNotificationWebhookMonitorConsoleConfig() NotificationWebhookMonitorConsoleConfig {
	return NotificationWebhookMonitorConsoleConfig{
		RequireTenant:        true,
		AllowPlatformViewer:  true,
		MaxVisibleDeliveries: 100,
		AllowedChannels: []string{
			NotificationMonitorChannelEmail,
			NotificationMonitorChannelSMS,
			NotificationMonitorChannelPush,
			NotificationMonitorChannelWebhook,
		},
		AllowedStates: []string{
			NotificationMonitorStateQueued,
			NotificationMonitorStateDelivered,
			NotificationMonitorStateFailed,
			NotificationMonitorStateRetryScheduled,
			NotificationMonitorStateDLQ,
		},
	}
}

type NotificationWebhookMonitorEntry struct {
	TenantID       string            `json:"tenant_id"`
	DeliveryID     string            `json:"delivery_id"`
	NotificationID string            `json:"notification_id,omitempty"`
	Channel        string            `json:"channel"`
	Provider       string            `json:"provider,omitempty"`
	Destination    string            `json:"destination"`
	EventType      string            `json:"event_type,omitempty"`
	State          string            `json:"state"`
	Attempt        int               `json:"attempt"`
	LastError      string            `json:"last_error,omitempty"`
	RetryAt        string            `json:"retry_at,omitempty"`
	DLQID          string            `json:"dlq_id,omitempty"`
	SignatureTrace string            `json:"signature_trace,omitempty"`
	CorrelationID  string            `json:"correlation_id,omitempty"`
	Metadata       map[string]string `json:"metadata,omitempty"`
	CreatedAt      string            `json:"created_at"`
	UpdatedAt      string            `json:"updated_at"`
}

type NotificationWebhookMonitorRequest struct {
	TenantID           string `json:"tenant_id"`
	ViewerTenantID     string `json:"viewer_tenant_id,omitempty"`
	ChannelFilter      string `json:"channel_filter,omitempty"`
	StateFilter        string `json:"state_filter,omitempty"`
	IncludeFailed      bool   `json:"include_failed"`
	IncludeWebhookOnly bool   `json:"include_webhook_only"`
	CorrelationID      string `json:"correlation_id,omitempty"`
}

type NotificationWebhookMonitorDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	ChannelFilter  string `json:"channel_filter,omitempty"`
	StateFilter    string `json:"state_filter,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type NotificationWebhookMonitorSnapshot struct {
	OK                  bool                              `json:"ok"`
	TenantID            string                            `json:"tenant_id"`
	ViewerTenantID      string                            `json:"viewer_tenant_id"`
	ChannelFilter       string                            `json:"channel_filter,omitempty"`
	StateFilter         string                            `json:"state_filter,omitempty"`
	DeliveryCount       int                               `json:"delivery_count"`
	EmailCount          int                               `json:"email_count"`
	SMSCount            int                               `json:"sms_count"`
	PushCount           int                               `json:"push_count"`
	WebhookCount        int                               `json:"webhook_count"`
	QueuedCount         int                               `json:"queued_count"`
	DeliveredCount      int                               `json:"delivered_count"`
	FailedCount         int                               `json:"failed_count"`
	RetryScheduledCount int                               `json:"retry_scheduled_count"`
	DLQCount            int                               `json:"dlq_count"`
	Channels            []string                          `json:"channels"`
	Deliveries          []NotificationWebhookMonitorEntry `json:"deliveries"`
	CorrelationID       string                            `json:"correlation_id,omitempty"`
	GeneratedAt         string                            `json:"generated_at"`
}

type NotificationWebhookMonitorConsoleRuntime struct {
	config     NotificationWebhookMonitorConsoleConfig
	mu         sync.RWMutex
	deliveries map[string]NotificationWebhookMonitorEntry
}

func NewNotificationWebhookMonitorConsoleRuntime(config NotificationWebhookMonitorConsoleConfig) *NotificationWebhookMonitorConsoleRuntime {
	defaults := DefaultNotificationWebhookMonitorConsoleConfig()

	if config.MaxVisibleDeliveries <= 0 {
		config.MaxVisibleDeliveries = defaults.MaxVisibleDeliveries
	}
	if len(config.AllowedChannels) == 0 {
		config.AllowedChannels = defaults.AllowedChannels
	}
	if len(config.AllowedStates) == 0 {
		config.AllowedStates = defaults.AllowedStates
	}

	return &NotificationWebhookMonitorConsoleRuntime{
		config:     config,
		deliveries: make(map[string]NotificationWebhookMonitorEntry),
	}
}

func (r *NotificationWebhookMonitorConsoleRuntime) UpsertDelivery(entry NotificationWebhookMonitorEntry) (NotificationWebhookMonitorEntry, NotificationWebhookMonitorDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.DeliveryID = strings.TrimSpace(entry.DeliveryID)
	entry.NotificationID = strings.TrimSpace(entry.NotificationID)
	entry.Channel = normalizeOpsConsoleValue(entry.Channel)
	entry.Provider = normalizeOpsConsoleValue(entry.Provider)
	entry.Destination = strings.TrimSpace(entry.Destination)
	entry.EventType = strings.TrimSpace(entry.EventType)
	entry.State = normalizeOpsConsoleValue(entry.State)

	decision := NotificationWebhookMonitorDecision{
		Decision:  NotificationMonitorDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    NotificationMonitorReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = NotificationMonitorReasonMissingTenant
		return NotificationWebhookMonitorEntry{}, decision, ErrNotificationMonitorMissingTenant
	}

	if entry.DeliveryID == "" {
		decision.Reason = NotificationMonitorReasonMissingDeliveryID
		return NotificationWebhookMonitorEntry{}, decision, ErrNotificationMonitorMissingDeliveryID
	}

	if entry.Channel == "" {
		decision.Reason = NotificationMonitorReasonMissingChannel
		return NotificationWebhookMonitorEntry{}, decision, ErrNotificationMonitorMissingChannel
	}

	if !r.channelAllowed(entry.Channel) {
		decision.Reason = NotificationMonitorReasonInvalidChannel
		return NotificationWebhookMonitorEntry{}, decision, ErrNotificationMonitorInvalidChannel
	}

	if entry.State == "" {
		decision.Reason = NotificationMonitorReasonMissingState
		return NotificationWebhookMonitorEntry{}, decision, ErrNotificationMonitorMissingState
	}

	if !r.stateAllowed(entry.State) {
		decision.Reason = NotificationMonitorReasonInvalidState
		return NotificationWebhookMonitorEntry{}, decision, ErrNotificationMonitorInvalidState
	}

	if entry.Destination == "" {
		decision.Reason = NotificationMonitorReasonMissingDestination
		return NotificationWebhookMonitorEntry{}, decision, ErrNotificationMonitorMissingDestination
	}

	if entry.Attempt <= 0 {
		entry.Attempt = 1
	}
	if entry.CreatedAt == "" {
		entry.CreatedAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.deliveries[notificationMonitorKey(entry.TenantID, entry.DeliveryID)] = entry
	r.mu.Unlock()

	decision.Decision = NotificationMonitorDecisionAllow
	decision.Allowed = true
	decision.Reason = NotificationMonitorReasonAllowed

	return entry, decision, nil
}

func (r *NotificationWebhookMonitorConsoleRuntime) BuildSnapshot(req NotificationWebhookMonitorRequest) (NotificationWebhookMonitorSnapshot, NotificationWebhookMonitorDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	channelFilter := normalizeOpsConsoleValue(req.ChannelFilter)
	stateFilter := normalizeOpsConsoleValue(req.StateFilter)

	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := NotificationWebhookMonitorDecision{
		Decision:       NotificationMonitorDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		ChannelFilter:  channelFilter,
		StateFilter:    stateFilter,
		Reason:         NotificationMonitorReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = NotificationMonitorReasonMissingTenant
		return NotificationWebhookMonitorSnapshot{}, decision, ErrNotificationMonitorMissingTenant
	}

	if viewerTenantID != tenantID && !(r.config.AllowPlatformViewer && viewerTenantID == "platform") {
		decision.Reason = NotificationMonitorReasonCrossTenant
		return NotificationWebhookMonitorSnapshot{}, decision, ErrNotificationMonitorCrossTenant
	}

	if channelFilter != "" && !r.channelAllowed(channelFilter) {
		decision.Reason = NotificationMonitorReasonInvalidChannel
		return NotificationWebhookMonitorSnapshot{}, decision, ErrNotificationMonitorInvalidChannel
	}

	if stateFilter != "" && !r.stateAllowed(stateFilter) {
		decision.Reason = NotificationMonitorReasonInvalidState
		return NotificationWebhookMonitorSnapshot{}, decision, ErrNotificationMonitorInvalidState
	}

	snapshot := NotificationWebhookMonitorSnapshot{
		OK:             true,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		ChannelFilter:  channelFilter,
		StateFilter:    stateFilter,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		GeneratedAt:    now,
	}

	channelSeen := map[string]bool{}

	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, delivery := range r.deliveries {
		if delivery.TenantID != tenantID {
			continue
		}
		if req.IncludeWebhookOnly && delivery.Channel != NotificationMonitorChannelWebhook {
			continue
		}
		if channelFilter != "" && delivery.Channel != channelFilter {
			continue
		}
		if stateFilter != "" && delivery.State != stateFilter {
			continue
		}
		if !req.IncludeFailed && (delivery.State == NotificationMonitorStateFailed || delivery.State == NotificationMonitorStateDLQ) {
			continue
		}
		if snapshot.DeliveryCount >= r.config.MaxVisibleDeliveries {
			continue
		}

		snapshot.Deliveries = append(snapshot.Deliveries, delivery)
		snapshot.DeliveryCount++

		if !channelSeen[delivery.Channel] {
			channelSeen[delivery.Channel] = true
			snapshot.Channels = append(snapshot.Channels, delivery.Channel)
		}

		switch delivery.Channel {
		case NotificationMonitorChannelEmail:
			snapshot.EmailCount++
		case NotificationMonitorChannelSMS:
			snapshot.SMSCount++
		case NotificationMonitorChannelPush:
			snapshot.PushCount++
		case NotificationMonitorChannelWebhook:
			snapshot.WebhookCount++
		}

		switch delivery.State {
		case NotificationMonitorStateQueued:
			snapshot.QueuedCount++
		case NotificationMonitorStateDelivered:
			snapshot.DeliveredCount++
		case NotificationMonitorStateFailed:
			snapshot.FailedCount++
		case NotificationMonitorStateRetryScheduled:
			snapshot.RetryScheduledCount++
		case NotificationMonitorStateDLQ:
			snapshot.DLQCount++
		}
	}

	decision.Decision = NotificationMonitorDecisionAllow
	decision.Allowed = true
	decision.Reason = NotificationMonitorReasonAllowed

	return snapshot, decision, nil
}

func (r *NotificationWebhookMonitorConsoleRuntime) channelAllowed(channel string) bool {
	channel = normalizeOpsConsoleValue(channel)
	for _, allowed := range r.config.AllowedChannels {
		if normalizeOpsConsoleValue(allowed) == channel {
			return true
		}
	}
	return false
}

func (r *NotificationWebhookMonitorConsoleRuntime) stateAllowed(state string) bool {
	state = normalizeOpsConsoleValue(state)
	for _, allowed := range r.config.AllowedStates {
		if normalizeOpsConsoleValue(allowed) == state {
			return true
		}
	}
	return false
}

func notificationMonitorKey(tenantID string, deliveryID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(deliveryID)
}
