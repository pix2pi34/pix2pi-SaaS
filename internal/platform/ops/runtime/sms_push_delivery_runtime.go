package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	SMSPushDeliveryChannelSMS  = "SMS"
	SMSPushDeliveryChannelPush = "PUSH"

	SMSPushDeliveryProviderSimulation  = "SIMULATION"
	SMSPushDeliveryProviderSMSGateway  = "SMS_GATEWAY"
	SMSPushDeliveryProviderPushGateway = "PUSH_GATEWAY"

	SMSPushDeliveryStateQueued    = "QUEUED"
	SMSPushDeliveryStateDelivered = "DELIVERED"
	SMSPushDeliveryStateRejected  = "REJECTED"

	SMSPushDeliveryDecisionAllow = "ALLOW"
	SMSPushDeliveryDecisionDeny  = "DENY"

	SMSPushDeliveryReasonAllowed              = "SMS_PUSH_DELIVERY_ALLOWED"
	SMSPushDeliveryReasonMissingTenant        = "SMS_PUSH_DELIVERY_MISSING_TENANT"
	SMSPushDeliveryReasonInvalidChannel       = "SMS_PUSH_DELIVERY_INVALID_CHANNEL"
	SMSPushDeliveryReasonInvalidProvider      = "SMS_PUSH_DELIVERY_INVALID_PROVIDER"
	SMSPushDeliveryReasonMissingRecipient     = "SMS_PUSH_DELIVERY_MISSING_RECIPIENT"
	SMSPushDeliveryReasonInvalidPhone         = "SMS_PUSH_DELIVERY_INVALID_PHONE"
	SMSPushDeliveryReasonInvalidDeviceToken   = "SMS_PUSH_DELIVERY_INVALID_DEVICE_TOKEN"
	SMSPushDeliveryReasonTooManyRecipients    = "SMS_PUSH_DELIVERY_TOO_MANY_RECIPIENTS"
	SMSPushDeliveryReasonMissingMessage       = "SMS_PUSH_DELIVERY_MISSING_MESSAGE"
	SMSPushDeliveryReasonDuplicateIdempotency = "SMS_PUSH_DELIVERY_DUPLICATE_IDEMPOTENCY_KEY"
	SMSPushDeliveryReasonCrossTenant          = "SMS_PUSH_DELIVERY_CROSS_TENANT_DENIED"
	SMSPushDeliveryReasonNotFound             = "SMS_PUSH_DELIVERY_NOT_FOUND"
)

var (
	ErrSMSPushDeliveryMissingTenant        = errors.New("missing sms push delivery tenant id")
	ErrSMSPushDeliveryInvalidChannel       = errors.New("invalid sms push delivery channel")
	ErrSMSPushDeliveryInvalidProvider      = errors.New("invalid sms push delivery provider")
	ErrSMSPushDeliveryMissingRecipient     = errors.New("missing sms push delivery recipient")
	ErrSMSPushDeliveryInvalidPhone         = errors.New("invalid sms delivery phone")
	ErrSMSPushDeliveryInvalidDeviceToken   = errors.New("invalid push delivery device token")
	ErrSMSPushDeliveryTooManyRecipients    = errors.New("too many sms push delivery recipients")
	ErrSMSPushDeliveryMissingMessage       = errors.New("missing sms push delivery message")
	ErrSMSPushDeliveryDuplicateIdempotency = errors.New("duplicate sms push delivery idempotency key")
	ErrSMSPushDeliveryCrossTenant          = errors.New("cross-tenant sms push delivery access denied")
	ErrSMSPushDeliveryNotFound             = errors.New("sms push delivery not found")
)

type SMSPushDeliveryRuntimeConfig struct {
	RequireTenant     bool     `json:"require_tenant"`
	AllowedChannels   []string `json:"allowed_channels"`
	AllowedProviders  []string `json:"allowed_providers"`
	DefaultProvider   string   `json:"default_provider"`
	MaxRecipients     int      `json:"max_recipients"`
	RequireMessage    bool     `json:"require_message"`
	EnableIdempotency bool     `json:"enable_idempotency"`
	DryRunOnly        bool     `json:"dry_run_only"`
}

func DefaultSMSPushDeliveryRuntimeConfig() SMSPushDeliveryRuntimeConfig {
	return SMSPushDeliveryRuntimeConfig{
		RequireTenant: true,
		AllowedChannels: []string{
			SMSPushDeliveryChannelSMS,
			SMSPushDeliveryChannelPush,
		},
		AllowedProviders: []string{
			SMSPushDeliveryProviderSimulation,
			SMSPushDeliveryProviderSMSGateway,
			SMSPushDeliveryProviderPushGateway,
		},
		DefaultProvider:   SMSPushDeliveryProviderSimulation,
		MaxRecipients:     25,
		RequireMessage:    true,
		EnableIdempotency: true,
		DryRunOnly:        true,
	}
}

type SMSPushDeliveryRequest struct {
	TenantID       string            `json:"tenant_id"`
	NotificationID string            `json:"notification_id,omitempty"`
	Channel        string            `json:"channel"`
	Provider       string            `json:"provider,omitempty"`
	PhoneNumbers   []string          `json:"phone_numbers,omitempty"`
	DeviceTokens   []string          `json:"device_tokens,omitempty"`
	Title          string            `json:"title,omitempty"`
	Message        string            `json:"message"`
	TemplateID     string            `json:"template_id,omitempty"`
	IdempotencyKey string            `json:"idempotency_key,omitempty"`
	RequestedBy    string            `json:"requested_by,omitempty"`
	CorrelationID  string            `json:"correlation_id,omitempty"`
	Metadata       map[string]string `json:"metadata,omitempty"`
}

type SMSPushDeliveryRecord struct {
	TenantID       string            `json:"tenant_id"`
	DeliveryID     string            `json:"delivery_id"`
	NotificationID string            `json:"notification_id,omitempty"`
	Channel        string            `json:"channel"`
	Provider       string            `json:"provider"`
	PhoneNumbers   []string          `json:"phone_numbers,omitempty"`
	DeviceTokens   []string          `json:"device_tokens,omitempty"`
	Title          string            `json:"title,omitempty"`
	MessageHash    string            `json:"message_hash"`
	TemplateID     string            `json:"template_id,omitempty"`
	State          string            `json:"state"`
	DryRunOnly     bool              `json:"dry_run_only"`
	IdempotencyKey string            `json:"idempotency_key,omitempty"`
	RequestedBy    string            `json:"requested_by,omitempty"`
	CorrelationID  string            `json:"correlation_id,omitempty"`
	Metadata       map[string]string `json:"metadata,omitempty"`
	CreatedAt      string            `json:"created_at"`
	UpdatedAt      string            `json:"updated_at"`
}

type SMSPushDeliveryDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	DeliveryID     string `json:"delivery_id,omitempty"`
	NotificationID string `json:"notification_id,omitempty"`
	Channel        string `json:"channel,omitempty"`
	Provider       string `json:"provider,omitempty"`
	RecipientCount int    `json:"recipient_count"`
	State          string `json:"state,omitempty"`
	IdempotencyKey string `json:"idempotency_key,omitempty"`
	RequestedBy    string `json:"requested_by,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type SMSPushDeliveryRuntime struct {
	config      SMSPushDeliveryRuntimeConfig
	mu          sync.RWMutex
	deliveries  map[string]SMSPushDeliveryRecord
	idempotency map[string]string
}

func NewSMSPushDeliveryRuntime(config SMSPushDeliveryRuntimeConfig) *SMSPushDeliveryRuntime {
	defaults := DefaultSMSPushDeliveryRuntimeConfig()

	if len(config.AllowedChannels) == 0 {
		config.AllowedChannels = defaults.AllowedChannels
	}
	if len(config.AllowedProviders) == 0 {
		config.AllowedProviders = defaults.AllowedProviders
	}
	if strings.TrimSpace(config.DefaultProvider) == "" {
		config.DefaultProvider = defaults.DefaultProvider
	}
	if config.MaxRecipients <= 0 {
		config.MaxRecipients = defaults.MaxRecipients
	}

	return &SMSPushDeliveryRuntime{
		config:      config,
		deliveries:  make(map[string]SMSPushDeliveryRecord),
		idempotency: make(map[string]string),
	}
}

func (r *SMSPushDeliveryRuntime) DispatchSMS(req SMSPushDeliveryRequest) (SMSPushDeliveryRecord, SMSPushDeliveryDecision, error) {
	req.Channel = SMSPushDeliveryChannelSMS
	return r.Dispatch(req)
}

func (r *SMSPushDeliveryRuntime) DispatchPush(req SMSPushDeliveryRequest) (SMSPushDeliveryRecord, SMSPushDeliveryDecision, error) {
	req.Channel = SMSPushDeliveryChannelPush
	return r.Dispatch(req)
}

func (r *SMSPushDeliveryRuntime) Dispatch(req SMSPushDeliveryRequest) (SMSPushDeliveryRecord, SMSPushDeliveryDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	channel := normalizeSMSPushValue(req.Channel)
	provider := normalizeSMSPushValue(req.Provider)
	if provider == "" {
		provider = normalizeSMSPushValue(r.config.DefaultProvider)
	}

	phones := normalizePhoneNumbers(req.PhoneNumbers)
	tokens := normalizeDeviceTokens(req.DeviceTokens)
	idempotencyKey := strings.TrimSpace(req.IdempotencyKey)

	recipientCount := len(phones)
	if channel == SMSPushDeliveryChannelPush {
		recipientCount = len(tokens)
	}

	decision := SMSPushDeliveryDecision{
		Decision:       SMSPushDeliveryDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		NotificationID: strings.TrimSpace(req.NotificationID),
		Channel:        channel,
		Provider:       provider,
		RecipientCount: recipientCount,
		IdempotencyKey: idempotencyKey,
		RequestedBy:    strings.TrimSpace(req.RequestedBy),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Reason:         SMSPushDeliveryReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = SMSPushDeliveryReasonMissingTenant
		decision.State = SMSPushDeliveryStateRejected
		return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryMissingTenant
	}

	if channel == "" || !r.channelAllowed(channel) {
		decision.Reason = SMSPushDeliveryReasonInvalidChannel
		decision.State = SMSPushDeliveryStateRejected
		return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryInvalidChannel
	}

	if !r.providerAllowed(provider) {
		decision.Reason = SMSPushDeliveryReasonInvalidProvider
		decision.State = SMSPushDeliveryStateRejected
		return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryInvalidProvider
	}

	if channel == SMSPushDeliveryChannelSMS {
		if len(phones) == 0 {
			decision.Reason = SMSPushDeliveryReasonMissingRecipient
			decision.State = SMSPushDeliveryStateRejected
			return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryMissingRecipient
		}
		if len(phones) > r.config.MaxRecipients {
			decision.Reason = SMSPushDeliveryReasonTooManyRecipients
			decision.State = SMSPushDeliveryStateRejected
			return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryTooManyRecipients
		}
		if invalid := firstInvalidPhoneNumber(phones); invalid != "" {
			decision.Reason = SMSPushDeliveryReasonInvalidPhone
			decision.State = SMSPushDeliveryStateRejected
			return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryInvalidPhone
		}
	}

	if channel == SMSPushDeliveryChannelPush {
		if len(tokens) == 0 {
			decision.Reason = SMSPushDeliveryReasonMissingRecipient
			decision.State = SMSPushDeliveryStateRejected
			return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryMissingRecipient
		}
		if len(tokens) > r.config.MaxRecipients {
			decision.Reason = SMSPushDeliveryReasonTooManyRecipients
			decision.State = SMSPushDeliveryStateRejected
			return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryTooManyRecipients
		}
		if invalid := firstInvalidDeviceToken(tokens); invalid != "" {
			decision.Reason = SMSPushDeliveryReasonInvalidDeviceToken
			decision.State = SMSPushDeliveryStateRejected
			return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryInvalidDeviceToken
		}
	}

	if r.config.RequireMessage && strings.TrimSpace(req.Message) == "" {
		decision.Reason = SMSPushDeliveryReasonMissingMessage
		decision.State = SMSPushDeliveryStateRejected
		return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryMissingMessage
	}

	if r.config.EnableIdempotency && idempotencyKey != "" {
		if existingDeliveryID, ok := r.idempotency[smsPushDeliveryIdempotencyKey(tenantID, channel, idempotencyKey)]; ok {
			decision.Reason = SMSPushDeliveryReasonDuplicateIdempotency
			decision.DeliveryID = existingDeliveryID
			decision.State = SMSPushDeliveryStateRejected
			return SMSPushDeliveryRecord{}, decision, ErrSMSPushDeliveryDuplicateIdempotency
		}
	}

	state := SMSPushDeliveryStateQueued
	if r.config.DryRunOnly {
		state = SMSPushDeliveryStateDelivered
	}

	record := SMSPushDeliveryRecord{
		TenantID:       tenantID,
		DeliveryID:     NewSMSPushDeliveryID(),
		NotificationID: strings.TrimSpace(req.NotificationID),
		Channel:        channel,
		Provider:       provider,
		PhoneNumbers:   phones,
		DeviceTokens:   tokens,
		Title:          strings.TrimSpace(req.Title),
		MessageHash:    stableOpsRuntimeHash(strings.TrimSpace(req.Message)),
		TemplateID:     strings.TrimSpace(req.TemplateID),
		State:          state,
		DryRunOnly:     r.config.DryRunOnly,
		IdempotencyKey: idempotencyKey,
		RequestedBy:    strings.TrimSpace(req.RequestedBy),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Metadata:       cloneJobDispatchPayload(req.Metadata),
		CreatedAt:      now,
		UpdatedAt:      now,
	}

	r.mu.Lock()
	r.deliveries[record.DeliveryID] = record
	if r.config.EnableIdempotency && idempotencyKey != "" {
		r.idempotency[smsPushDeliveryIdempotencyKey(tenantID, channel, idempotencyKey)] = record.DeliveryID
	}
	r.mu.Unlock()

	decision.Decision = SMSPushDeliveryDecisionAllow
	decision.Allowed = true
	decision.DeliveryID = record.DeliveryID
	decision.State = record.State
	decision.Reason = SMSPushDeliveryReasonAllowed

	return record, decision, nil
}

func (r *SMSPushDeliveryRuntime) GetDelivery(tenantID string, deliveryID string) (SMSPushDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	deliveryID = strings.TrimSpace(deliveryID)

	if tenantID == "" {
		return SMSPushDeliveryRecord{}, ErrSMSPushDeliveryMissingTenant
	}
	if deliveryID == "" {
		return SMSPushDeliveryRecord{}, ErrSMSPushDeliveryNotFound
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.deliveries[deliveryID]
	if !ok {
		return SMSPushDeliveryRecord{}, ErrSMSPushDeliveryNotFound
	}
	if record.TenantID != tenantID {
		return SMSPushDeliveryRecord{}, ErrSMSPushDeliveryCrossTenant
	}

	return record, nil
}

func (r *SMSPushDeliveryRuntime) ListTenantDeliveries(tenantID string) ([]SMSPushDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrSMSPushDeliveryMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]SMSPushDeliveryRecord, 0)
	for _, record := range r.deliveries {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *SMSPushDeliveryRuntime) ListTenantChannelDeliveries(tenantID string, channel string) ([]SMSPushDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	channel = normalizeSMSPushValue(channel)

	if tenantID == "" {
		return nil, ErrSMSPushDeliveryMissingTenant
	}
	if channel == "" || !r.channelAllowed(channel) {
		return nil, ErrSMSPushDeliveryInvalidChannel
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]SMSPushDeliveryRecord, 0)
	for _, record := range r.deliveries {
		if record.TenantID == tenantID && record.Channel == channel {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *SMSPushDeliveryRuntime) channelAllowed(channel string) bool {
	channel = normalizeSMSPushValue(channel)
	for _, allowed := range r.config.AllowedChannels {
		if normalizeSMSPushValue(allowed) == channel {
			return true
		}
	}
	return false
}

func (r *SMSPushDeliveryRuntime) providerAllowed(provider string) bool {
	provider = normalizeSMSPushValue(provider)
	for _, allowed := range r.config.AllowedProviders {
		if normalizeSMSPushValue(allowed) == provider {
			return true
		}
	}
	return false
}

func normalizeSMSPushValue(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func normalizePhoneNumbers(numbers []string) []string {
	out := make([]string, 0)
	seen := map[string]bool{}

	for _, number := range numbers {
		number = strings.TrimSpace(number)
		number = strings.ReplaceAll(number, " ", "")
		number = strings.ReplaceAll(number, "-", "")
		number = strings.ReplaceAll(number, "(", "")
		number = strings.ReplaceAll(number, ")", "")
		if number == "" {
			continue
		}
		if seen[number] {
			continue
		}
		seen[number] = true
		out = append(out, number)
	}

	return out
}

func normalizeDeviceTokens(tokens []string) []string {
	out := make([]string, 0)
	seen := map[string]bool{}

	for _, token := range tokens {
		token = strings.TrimSpace(token)
		if token == "" {
			continue
		}
		if seen[token] {
			continue
		}
		seen[token] = true
		out = append(out, token)
	}

	return out
}

func firstInvalidPhoneNumber(numbers []string) string {
	for _, number := range numbers {
		if len(number) < 9 || len(number) > 16 {
			return number
		}
		if !strings.HasPrefix(number, "+") {
			return number
		}
		for _, ch := range strings.TrimPrefix(number, "+") {
			if ch < '0' || ch > '9' {
				return number
			}
		}
	}
	return ""
}

func firstInvalidDeviceToken(tokens []string) string {
	for _, token := range tokens {
		if len(token) < 8 {
			return token
		}
	}
	return ""
}

func smsPushDeliveryIdempotencyKey(tenantID string, channel string, idempotencyKey string) string {
	return strings.TrimSpace(tenantID) + "::" + normalizeSMSPushValue(channel) + "::" + strings.TrimSpace(idempotencyKey)
}

func NewSMSPushDeliveryID() string {
	return randomOpsRuntimeID("sms_push_delivery_")
}
