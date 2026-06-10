package opsruntime

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/mail"
	"strings"
	"sync"
	"time"
)

const (
	EmailDeliveryProviderSimulation = "SIMULATION"
	EmailDeliveryProviderSMTP       = "SMTP"

	EmailDeliveryStateQueued    = "QUEUED"
	EmailDeliveryStateDelivered = "DELIVERED"
	EmailDeliveryStateRejected  = "REJECTED"

	EmailDeliveryDecisionAllow = "ALLOW"
	EmailDeliveryDecisionDeny  = "DENY"

	EmailDeliveryReasonAllowed              = "EMAIL_DELIVERY_ALLOWED"
	EmailDeliveryReasonMissingTenant        = "EMAIL_DELIVERY_MISSING_TENANT"
	EmailDeliveryReasonMissingRecipient     = "EMAIL_DELIVERY_MISSING_RECIPIENT"
	EmailDeliveryReasonInvalidRecipient     = "EMAIL_DELIVERY_INVALID_RECIPIENT"
	EmailDeliveryReasonTooManyRecipients    = "EMAIL_DELIVERY_TOO_MANY_RECIPIENTS"
	EmailDeliveryReasonMissingSubject       = "EMAIL_DELIVERY_MISSING_SUBJECT"
	EmailDeliveryReasonMissingBody          = "EMAIL_DELIVERY_MISSING_BODY"
	EmailDeliveryReasonInvalidProvider      = "EMAIL_DELIVERY_INVALID_PROVIDER"
	EmailDeliveryReasonDuplicateIdempotency = "EMAIL_DELIVERY_DUPLICATE_IDEMPOTENCY_KEY"
	EmailDeliveryReasonCrossTenant          = "EMAIL_DELIVERY_CROSS_TENANT_DENIED"
	EmailDeliveryReasonNotFound             = "EMAIL_DELIVERY_NOT_FOUND"
)

var (
	ErrEmailDeliveryMissingTenant        = errors.New("missing email delivery tenant id")
	ErrEmailDeliveryMissingRecipient     = errors.New("missing email delivery recipient")
	ErrEmailDeliveryInvalidRecipient     = errors.New("invalid email delivery recipient")
	ErrEmailDeliveryTooManyRecipients    = errors.New("too many email delivery recipients")
	ErrEmailDeliveryMissingSubject       = errors.New("missing email delivery subject")
	ErrEmailDeliveryMissingBody          = errors.New("missing email delivery body")
	ErrEmailDeliveryInvalidProvider      = errors.New("invalid email delivery provider")
	ErrEmailDeliveryDuplicateIdempotency = errors.New("duplicate email delivery idempotency key")
	ErrEmailDeliveryCrossTenant          = errors.New("cross-tenant email delivery access denied")
	ErrEmailDeliveryNotFound             = errors.New("email delivery not found")
)

type EmailDeliveryRuntimeConfig struct {
	RequireTenant     bool     `json:"require_tenant"`
	AllowedProviders  []string `json:"allowed_providers"`
	DefaultProvider   string   `json:"default_provider"`
	MaxRecipients     int      `json:"max_recipients"`
	RequireSubject    bool     `json:"require_subject"`
	RequireBody       bool     `json:"require_body"`
	EnableIdempotency bool     `json:"enable_idempotency"`
	DryRunOnly        bool     `json:"dry_run_only"`
}

func DefaultEmailDeliveryRuntimeConfig() EmailDeliveryRuntimeConfig {
	return EmailDeliveryRuntimeConfig{
		RequireTenant: true,
		AllowedProviders: []string{
			EmailDeliveryProviderSimulation,
			EmailDeliveryProviderSMTP,
		},
		DefaultProvider:   EmailDeliveryProviderSimulation,
		MaxRecipients:     10,
		RequireSubject:    true,
		RequireBody:       true,
		EnableIdempotency: true,
		DryRunOnly:        true,
	}
}

type EmailDeliveryRequest struct {
	TenantID       string            `json:"tenant_id"`
	NotificationID string            `json:"notification_id,omitempty"`
	Provider       string            `json:"provider,omitempty"`
	To             []string          `json:"to"`
	Subject        string            `json:"subject"`
	Body           string            `json:"body"`
	TemplateID     string            `json:"template_id,omitempty"`
	IdempotencyKey string            `json:"idempotency_key,omitempty"`
	RequestedBy    string            `json:"requested_by,omitempty"`
	CorrelationID  string            `json:"correlation_id,omitempty"`
	Metadata       map[string]string `json:"metadata,omitempty"`
}

type EmailDeliveryRecord struct {
	TenantID       string            `json:"tenant_id"`
	DeliveryID     string            `json:"delivery_id"`
	NotificationID string            `json:"notification_id,omitempty"`
	Provider       string            `json:"provider"`
	To             []string          `json:"to"`
	Subject        string            `json:"subject"`
	BodyHash       string            `json:"body_hash"`
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

type EmailDeliveryDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	DeliveryID     string `json:"delivery_id,omitempty"`
	NotificationID string `json:"notification_id,omitempty"`
	Provider       string `json:"provider,omitempty"`
	RecipientCount int    `json:"recipient_count"`
	State          string `json:"state,omitempty"`
	IdempotencyKey string `json:"idempotency_key,omitempty"`
	RequestedBy    string `json:"requested_by,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type EmailDeliveryRuntime struct {
	config      EmailDeliveryRuntimeConfig
	mu          sync.RWMutex
	deliveries  map[string]EmailDeliveryRecord
	idempotency map[string]string
}

func NewEmailDeliveryRuntime(config EmailDeliveryRuntimeConfig) *EmailDeliveryRuntime {
	defaults := DefaultEmailDeliveryRuntimeConfig()

	if len(config.AllowedProviders) == 0 {
		config.AllowedProviders = defaults.AllowedProviders
	}
	if strings.TrimSpace(config.DefaultProvider) == "" {
		config.DefaultProvider = defaults.DefaultProvider
	}
	if config.MaxRecipients <= 0 {
		config.MaxRecipients = defaults.MaxRecipients
	}

	return &EmailDeliveryRuntime{
		config:      config,
		deliveries:  make(map[string]EmailDeliveryRecord),
		idempotency: make(map[string]string),
	}
}

func (r *EmailDeliveryRuntime) DispatchEmail(req EmailDeliveryRequest) (EmailDeliveryRecord, EmailDeliveryDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	provider := normalizeEmailDeliveryValue(req.Provider)
	if provider == "" {
		provider = normalizeEmailDeliveryValue(r.config.DefaultProvider)
	}

	recipients := normalizeEmailRecipients(req.To)
	idempotencyKey := strings.TrimSpace(req.IdempotencyKey)

	decision := EmailDeliveryDecision{
		Decision:       EmailDeliveryDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		NotificationID: strings.TrimSpace(req.NotificationID),
		Provider:       provider,
		RecipientCount: len(recipients),
		IdempotencyKey: idempotencyKey,
		RequestedBy:    strings.TrimSpace(req.RequestedBy),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Reason:         EmailDeliveryReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = EmailDeliveryReasonMissingTenant
		decision.State = EmailDeliveryStateRejected
		return EmailDeliveryRecord{}, decision, ErrEmailDeliveryMissingTenant
	}

	if len(recipients) == 0 {
		decision.Reason = EmailDeliveryReasonMissingRecipient
		decision.State = EmailDeliveryStateRejected
		return EmailDeliveryRecord{}, decision, ErrEmailDeliveryMissingRecipient
	}

	if len(recipients) > r.config.MaxRecipients {
		decision.Reason = EmailDeliveryReasonTooManyRecipients
		decision.State = EmailDeliveryStateRejected
		return EmailDeliveryRecord{}, decision, ErrEmailDeliveryTooManyRecipients
	}

	if !r.providerAllowed(provider) {
		decision.Reason = EmailDeliveryReasonInvalidProvider
		decision.State = EmailDeliveryStateRejected
		return EmailDeliveryRecord{}, decision, ErrEmailDeliveryInvalidProvider
	}

	if invalid := firstInvalidEmailRecipient(recipients); invalid != "" {
		decision.Reason = EmailDeliveryReasonInvalidRecipient
		decision.State = EmailDeliveryStateRejected
		return EmailDeliveryRecord{}, decision, ErrEmailDeliveryInvalidRecipient
	}

	if r.config.RequireSubject && strings.TrimSpace(req.Subject) == "" {
		decision.Reason = EmailDeliveryReasonMissingSubject
		decision.State = EmailDeliveryStateRejected
		return EmailDeliveryRecord{}, decision, ErrEmailDeliveryMissingSubject
	}

	if r.config.RequireBody && strings.TrimSpace(req.Body) == "" {
		decision.Reason = EmailDeliveryReasonMissingBody
		decision.State = EmailDeliveryStateRejected
		return EmailDeliveryRecord{}, decision, ErrEmailDeliveryMissingBody
	}

	if r.config.EnableIdempotency && idempotencyKey != "" {
		if existingDeliveryID, ok := r.idempotency[emailDeliveryIdempotencyKey(tenantID, idempotencyKey)]; ok {
			decision.Reason = EmailDeliveryReasonDuplicateIdempotency
			decision.DeliveryID = existingDeliveryID
			decision.State = EmailDeliveryStateRejected
			return EmailDeliveryRecord{}, decision, ErrEmailDeliveryDuplicateIdempotency
		}
	}

	state := EmailDeliveryStateQueued
	if r.config.DryRunOnly {
		state = EmailDeliveryStateDelivered
	}

	record := EmailDeliveryRecord{
		TenantID:       tenantID,
		DeliveryID:     NewEmailDeliveryID(),
		NotificationID: strings.TrimSpace(req.NotificationID),
		Provider:       provider,
		To:             recipients,
		Subject:        strings.TrimSpace(req.Subject),
		BodyHash:       stableOpsRuntimeHash(strings.TrimSpace(req.Body)),
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
		r.idempotency[emailDeliveryIdempotencyKey(tenantID, idempotencyKey)] = record.DeliveryID
	}
	r.mu.Unlock()

	decision.Decision = EmailDeliveryDecisionAllow
	decision.Allowed = true
	decision.DeliveryID = record.DeliveryID
	decision.State = record.State
	decision.Reason = EmailDeliveryReasonAllowed

	return record, decision, nil
}

func (r *EmailDeliveryRuntime) GetDelivery(tenantID string, deliveryID string) (EmailDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	deliveryID = strings.TrimSpace(deliveryID)

	if tenantID == "" {
		return EmailDeliveryRecord{}, ErrEmailDeliveryMissingTenant
	}
	if deliveryID == "" {
		return EmailDeliveryRecord{}, ErrEmailDeliveryNotFound
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.deliveries[deliveryID]
	if !ok {
		return EmailDeliveryRecord{}, ErrEmailDeliveryNotFound
	}
	if record.TenantID != tenantID {
		return EmailDeliveryRecord{}, ErrEmailDeliveryCrossTenant
	}

	return record, nil
}

func (r *EmailDeliveryRuntime) ListTenantDeliveries(tenantID string) ([]EmailDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrEmailDeliveryMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]EmailDeliveryRecord, 0)
	for _, record := range r.deliveries {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *EmailDeliveryRuntime) ListRecipientDeliveries(tenantID string, recipient string) ([]EmailDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	recipient = strings.TrimSpace(strings.ToLower(recipient))

	if tenantID == "" {
		return nil, ErrEmailDeliveryMissingTenant
	}
	if recipient == "" {
		return nil, ErrEmailDeliveryMissingRecipient
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]EmailDeliveryRecord, 0)
	for _, record := range r.deliveries {
		if record.TenantID != tenantID {
			continue
		}
		for _, to := range record.To {
			if strings.EqualFold(to, recipient) {
				out = append(out, record)
			}
		}
	}

	return out, nil
}

func (r *EmailDeliveryRuntime) providerAllowed(provider string) bool {
	provider = normalizeEmailDeliveryValue(provider)
	for _, allowed := range r.config.AllowedProviders {
		if normalizeEmailDeliveryValue(allowed) == provider {
			return true
		}
	}
	return false
}

func normalizeEmailDeliveryValue(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func normalizeEmailRecipients(recipients []string) []string {
	out := make([]string, 0)
	seen := map[string]bool{}

	for _, recipient := range recipients {
		recipient = strings.TrimSpace(strings.ToLower(recipient))
		if recipient == "" {
			continue
		}
		if seen[recipient] {
			continue
		}
		seen[recipient] = true
		out = append(out, recipient)
	}

	return out
}

func firstInvalidEmailRecipient(recipients []string) string {
	for _, recipient := range recipients {
		if _, err := mail.ParseAddress(recipient); err != nil {
			return recipient
		}
	}
	return ""
}

func stableOpsRuntimeHash(value string) string {
	sum := sha256.Sum256([]byte(strings.TrimSpace(value)))
	return hex.EncodeToString(sum[:])
}

func emailDeliveryIdempotencyKey(tenantID string, idempotencyKey string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(idempotencyKey)
}

func NewEmailDeliveryID() string {
	return randomOpsRuntimeID("email_delivery_")
}
