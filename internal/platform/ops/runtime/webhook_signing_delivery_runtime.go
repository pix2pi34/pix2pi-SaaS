package opsruntime

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/url"
	"strings"
	"sync"
	"time"
)

const (
	WebhookDeliveryProviderSimulation = "SIMULATION"
	WebhookDeliveryProviderHTTP       = "HTTP"

	WebhookDeliveryMethodPOST = "POST"
	WebhookDeliveryMethodPUT  = "PUT"

	WebhookDeliveryStateQueued    = "QUEUED"
	WebhookDeliveryStateDelivered = "DELIVERED"
	WebhookDeliveryStateRejected  = "REJECTED"

	WebhookSigningAlgorithmHMACSHA256 = "HMAC_SHA256"

	WebhookDeliveryDecisionAllow = "ALLOW"
	WebhookDeliveryDecisionDeny  = "DENY"

	WebhookDeliveryReasonAllowed              = "WEBHOOK_DELIVERY_ALLOWED"
	WebhookDeliveryReasonMissingTenant        = "WEBHOOK_DELIVERY_MISSING_TENANT"
	WebhookDeliveryReasonMissingURL           = "WEBHOOK_DELIVERY_MISSING_URL"
	WebhookDeliveryReasonInvalidURL           = "WEBHOOK_DELIVERY_INVALID_URL"
	WebhookDeliveryReasonInvalidProvider      = "WEBHOOK_DELIVERY_INVALID_PROVIDER"
	WebhookDeliveryReasonInvalidMethod        = "WEBHOOK_DELIVERY_INVALID_METHOD"
	WebhookDeliveryReasonMissingEventType     = "WEBHOOK_DELIVERY_MISSING_EVENT_TYPE"
	WebhookDeliveryReasonMissingPayload       = "WEBHOOK_DELIVERY_MISSING_PAYLOAD"
	WebhookDeliveryReasonMissingSecret        = "WEBHOOK_DELIVERY_MISSING_SECRET"
	WebhookDeliveryReasonDuplicateIdempotency = "WEBHOOK_DELIVERY_DUPLICATE_IDEMPOTENCY_KEY"
	WebhookDeliveryReasonSignatureMismatch    = "WEBHOOK_DELIVERY_SIGNATURE_MISMATCH"
	WebhookDeliveryReasonCrossTenant          = "WEBHOOK_DELIVERY_CROSS_TENANT_DENIED"
	WebhookDeliveryReasonNotFound             = "WEBHOOK_DELIVERY_NOT_FOUND"
)

var (
	ErrWebhookDeliveryMissingTenant        = errors.New("missing webhook delivery tenant id")
	ErrWebhookDeliveryMissingURL           = errors.New("missing webhook delivery url")
	ErrWebhookDeliveryInvalidURL           = errors.New("invalid webhook delivery url")
	ErrWebhookDeliveryInvalidProvider      = errors.New("invalid webhook delivery provider")
	ErrWebhookDeliveryInvalidMethod        = errors.New("invalid webhook delivery method")
	ErrWebhookDeliveryMissingEventType     = errors.New("missing webhook delivery event type")
	ErrWebhookDeliveryMissingPayload       = errors.New("missing webhook delivery payload")
	ErrWebhookDeliveryMissingSecret        = errors.New("missing webhook signing secret")
	ErrWebhookDeliveryDuplicateIdempotency = errors.New("duplicate webhook delivery idempotency key")
	ErrWebhookDeliverySignatureMismatch    = errors.New("webhook signature mismatch")
	ErrWebhookDeliveryCrossTenant          = errors.New("cross-tenant webhook delivery access denied")
	ErrWebhookDeliveryNotFound             = errors.New("webhook delivery not found")
)

type WebhookSigningDeliveryRuntimeConfig struct {
	RequireTenant     bool     `json:"require_tenant"`
	AllowedProviders  []string `json:"allowed_providers"`
	DefaultProvider   string   `json:"default_provider"`
	AllowedMethods    []string `json:"allowed_methods"`
	DefaultMethod     string   `json:"default_method"`
	RequirePayload    bool     `json:"require_payload"`
	RequireSecret     bool     `json:"require_secret"`
	EnableIdempotency bool     `json:"enable_idempotency"`
	DryRunOnly        bool     `json:"dry_run_only"`
}

func DefaultWebhookSigningDeliveryRuntimeConfig() WebhookSigningDeliveryRuntimeConfig {
	return WebhookSigningDeliveryRuntimeConfig{
		RequireTenant: true,
		AllowedProviders: []string{
			WebhookDeliveryProviderSimulation,
			WebhookDeliveryProviderHTTP,
		},
		DefaultProvider: WebhookDeliveryProviderSimulation,
		AllowedMethods: []string{
			WebhookDeliveryMethodPOST,
			WebhookDeliveryMethodPUT,
		},
		DefaultMethod:     WebhookDeliveryMethodPOST,
		RequirePayload:    true,
		RequireSecret:     true,
		EnableIdempotency: true,
		DryRunOnly:        true,
	}
}

type WebhookDeliveryRequest struct {
	TenantID       string            `json:"tenant_id"`
	WebhookID      string            `json:"webhook_id,omitempty"`
	Provider       string            `json:"provider,omitempty"`
	Method         string            `json:"method,omitempty"`
	URL            string            `json:"url"`
	EventType      string            `json:"event_type"`
	Payload        string            `json:"payload"`
	Secret         string            `json:"secret"`
	IdempotencyKey string            `json:"idempotency_key,omitempty"`
	RequestedBy    string            `json:"requested_by,omitempty"`
	CorrelationID  string            `json:"correlation_id,omitempty"`
	Headers        map[string]string `json:"headers,omitempty"`
	Metadata       map[string]string `json:"metadata,omitempty"`
}

type WebhookDeliveryRecord struct {
	TenantID           string            `json:"tenant_id"`
	DeliveryID         string            `json:"delivery_id"`
	WebhookID          string            `json:"webhook_id,omitempty"`
	Provider           string            `json:"provider"`
	Method             string            `json:"method"`
	URL                string            `json:"url"`
	EventType          string            `json:"event_type"`
	PayloadHash        string            `json:"payload_hash"`
	Signature          string            `json:"signature"`
	SignatureHeader    string            `json:"signature_header"`
	SignatureAlgorithm string            `json:"signature_algorithm"`
	State              string            `json:"state"`
	DryRunOnly         bool              `json:"dry_run_only"`
	IdempotencyKey     string            `json:"idempotency_key,omitempty"`
	RequestedBy        string            `json:"requested_by,omitempty"`
	CorrelationID      string            `json:"correlation_id,omitempty"`
	Headers            map[string]string `json:"headers,omitempty"`
	Metadata           map[string]string `json:"metadata,omitempty"`
	CreatedAt          string            `json:"created_at"`
	UpdatedAt          string            `json:"updated_at"`
}

type WebhookDeliveryDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	DeliveryID     string `json:"delivery_id,omitempty"`
	WebhookID      string `json:"webhook_id,omitempty"`
	Provider       string `json:"provider,omitempty"`
	Method         string `json:"method,omitempty"`
	URL            string `json:"url,omitempty"`
	EventType      string `json:"event_type,omitempty"`
	State          string `json:"state,omitempty"`
	IdempotencyKey string `json:"idempotency_key,omitempty"`
	RequestedBy    string `json:"requested_by,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type WebhookSigningDeliveryRuntime struct {
	config      WebhookSigningDeliveryRuntimeConfig
	mu          sync.RWMutex
	deliveries  map[string]WebhookDeliveryRecord
	idempotency map[string]string
}

func NewWebhookSigningDeliveryRuntime(config WebhookSigningDeliveryRuntimeConfig) *WebhookSigningDeliveryRuntime {
	defaults := DefaultWebhookSigningDeliveryRuntimeConfig()

	if len(config.AllowedProviders) == 0 {
		config.AllowedProviders = defaults.AllowedProviders
	}
	if strings.TrimSpace(config.DefaultProvider) == "" {
		config.DefaultProvider = defaults.DefaultProvider
	}
	if len(config.AllowedMethods) == 0 {
		config.AllowedMethods = defaults.AllowedMethods
	}
	if strings.TrimSpace(config.DefaultMethod) == "" {
		config.DefaultMethod = defaults.DefaultMethod
	}

	return &WebhookSigningDeliveryRuntime{
		config:      config,
		deliveries:  make(map[string]WebhookDeliveryRecord),
		idempotency: make(map[string]string),
	}
}

func (r *WebhookSigningDeliveryRuntime) DispatchWebhook(req WebhookDeliveryRequest) (WebhookDeliveryRecord, WebhookDeliveryDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	provider := normalizeWebhookDeliveryValue(req.Provider)
	if provider == "" {
		provider = normalizeWebhookDeliveryValue(r.config.DefaultProvider)
	}

	method := normalizeWebhookDeliveryValue(req.Method)
	if method == "" {
		method = normalizeWebhookDeliveryValue(r.config.DefaultMethod)
	}

	cleanURL := strings.TrimSpace(req.URL)
	eventType := strings.TrimSpace(req.EventType)
	payload := strings.TrimSpace(req.Payload)
	secret := strings.TrimSpace(req.Secret)
	idempotencyKey := strings.TrimSpace(req.IdempotencyKey)

	decision := WebhookDeliveryDecision{
		Decision:       WebhookDeliveryDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		WebhookID:      strings.TrimSpace(req.WebhookID),
		Provider:       provider,
		Method:         method,
		URL:            cleanURL,
		EventType:      eventType,
		IdempotencyKey: idempotencyKey,
		RequestedBy:    strings.TrimSpace(req.RequestedBy),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Reason:         WebhookDeliveryReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WebhookDeliveryReasonMissingTenant
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryMissingTenant
	}

	if cleanURL == "" {
		decision.Reason = WebhookDeliveryReasonMissingURL
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryMissingURL
	}

	if !isValidWebhookURL(cleanURL) {
		decision.Reason = WebhookDeliveryReasonInvalidURL
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryInvalidURL
	}

	if !r.providerAllowed(provider) {
		decision.Reason = WebhookDeliveryReasonInvalidProvider
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryInvalidProvider
	}

	if !r.methodAllowed(method) {
		decision.Reason = WebhookDeliveryReasonInvalidMethod
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryInvalidMethod
	}

	if eventType == "" {
		decision.Reason = WebhookDeliveryReasonMissingEventType
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryMissingEventType
	}

	if r.config.RequirePayload && payload == "" {
		decision.Reason = WebhookDeliveryReasonMissingPayload
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryMissingPayload
	}

	if r.config.RequireSecret && secret == "" {
		decision.Reason = WebhookDeliveryReasonMissingSecret
		decision.State = WebhookDeliveryStateRejected
		return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryMissingSecret
	}

	if r.config.EnableIdempotency && idempotencyKey != "" {
		if existingDeliveryID, ok := r.idempotency[webhookDeliveryIdempotencyKey(tenantID, idempotencyKey)]; ok {
			decision.Reason = WebhookDeliveryReasonDuplicateIdempotency
			decision.DeliveryID = existingDeliveryID
			decision.State = WebhookDeliveryStateRejected
			return WebhookDeliveryRecord{}, decision, ErrWebhookDeliveryDuplicateIdempotency
		}
	}

	signature := BuildWebhookSignature(secret, payload)
	signatureHeader := BuildWebhookSignatureHeader(signature)

	state := WebhookDeliveryStateQueued
	if r.config.DryRunOnly {
		state = WebhookDeliveryStateDelivered
	}

	headers := cloneJobDispatchPayload(req.Headers)
	headers["X-Pix2pi-Signature"] = signatureHeader
	headers["X-Pix2pi-Event-Type"] = eventType
	headers["X-Pix2pi-Tenant-ID"] = tenantID

	record := WebhookDeliveryRecord{
		TenantID:           tenantID,
		DeliveryID:         NewWebhookDeliveryID(),
		WebhookID:          strings.TrimSpace(req.WebhookID),
		Provider:           provider,
		Method:             method,
		URL:                cleanURL,
		EventType:          eventType,
		PayloadHash:        stableOpsRuntimeHash(payload),
		Signature:          signature,
		SignatureHeader:    signatureHeader,
		SignatureAlgorithm: WebhookSigningAlgorithmHMACSHA256,
		State:              state,
		DryRunOnly:         r.config.DryRunOnly,
		IdempotencyKey:     idempotencyKey,
		RequestedBy:        strings.TrimSpace(req.RequestedBy),
		CorrelationID:      strings.TrimSpace(req.CorrelationID),
		Headers:            headers,
		Metadata:           cloneJobDispatchPayload(req.Metadata),
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	r.mu.Lock()
	r.deliveries[record.DeliveryID] = record
	if r.config.EnableIdempotency && idempotencyKey != "" {
		r.idempotency[webhookDeliveryIdempotencyKey(tenantID, idempotencyKey)] = record.DeliveryID
	}
	r.mu.Unlock()

	decision.Decision = WebhookDeliveryDecisionAllow
	decision.Allowed = true
	decision.DeliveryID = record.DeliveryID
	decision.State = record.State
	decision.Reason = WebhookDeliveryReasonAllowed

	return record, decision, nil
}

func (r *WebhookSigningDeliveryRuntime) VerifySignature(secret string, payload string, signatureHeader string) (WebhookDeliveryDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	secret = strings.TrimSpace(secret)
	payload = strings.TrimSpace(payload)
	signatureHeader = strings.TrimSpace(signatureHeader)

	decision := WebhookDeliveryDecision{
		Decision:  WebhookDeliveryDecisionDeny,
		Allowed:   false,
		Reason:    WebhookDeliveryReasonAllowed,
		CheckedAt: now,
	}

	if secret == "" {
		decision.Reason = WebhookDeliveryReasonMissingSecret
		return decision, ErrWebhookDeliveryMissingSecret
	}

	if payload == "" {
		decision.Reason = WebhookDeliveryReasonMissingPayload
		return decision, ErrWebhookDeliveryMissingPayload
	}

	expected := BuildWebhookSignatureHeader(BuildWebhookSignature(secret, payload))
	if !hmac.Equal([]byte(expected), []byte(signatureHeader)) {
		decision.Reason = WebhookDeliveryReasonSignatureMismatch
		return decision, ErrWebhookDeliverySignatureMismatch
	}

	decision.Decision = WebhookDeliveryDecisionAllow
	decision.Allowed = true
	decision.Reason = WebhookDeliveryReasonAllowed

	return decision, nil
}

func (r *WebhookSigningDeliveryRuntime) GetDelivery(tenantID string, deliveryID string) (WebhookDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	deliveryID = strings.TrimSpace(deliveryID)

	if tenantID == "" {
		return WebhookDeliveryRecord{}, ErrWebhookDeliveryMissingTenant
	}
	if deliveryID == "" {
		return WebhookDeliveryRecord{}, ErrWebhookDeliveryNotFound
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.deliveries[deliveryID]
	if !ok {
		return WebhookDeliveryRecord{}, ErrWebhookDeliveryNotFound
	}
	if record.TenantID != tenantID {
		return WebhookDeliveryRecord{}, ErrWebhookDeliveryCrossTenant
	}

	return record, nil
}

func (r *WebhookSigningDeliveryRuntime) ListTenantDeliveries(tenantID string) ([]WebhookDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrWebhookDeliveryMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]WebhookDeliveryRecord, 0)
	for _, record := range r.deliveries {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *WebhookSigningDeliveryRuntime) ListTenantEventDeliveries(tenantID string, eventType string) ([]WebhookDeliveryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	eventType = strings.TrimSpace(eventType)

	if tenantID == "" {
		return nil, ErrWebhookDeliveryMissingTenant
	}
	if eventType == "" {
		return nil, ErrWebhookDeliveryMissingEventType
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]WebhookDeliveryRecord, 0)
	for _, record := range r.deliveries {
		if record.TenantID == tenantID && record.EventType == eventType {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *WebhookSigningDeliveryRuntime) providerAllowed(provider string) bool {
	provider = normalizeWebhookDeliveryValue(provider)
	for _, allowed := range r.config.AllowedProviders {
		if normalizeWebhookDeliveryValue(allowed) == provider {
			return true
		}
	}
	return false
}

func (r *WebhookSigningDeliveryRuntime) methodAllowed(method string) bool {
	method = normalizeWebhookDeliveryValue(method)
	for _, allowed := range r.config.AllowedMethods {
		if normalizeWebhookDeliveryValue(allowed) == method {
			return true
		}
	}
	return false
}

func BuildWebhookSignature(secret string, payload string) string {
	mac := hmac.New(sha256.New, []byte(strings.TrimSpace(secret)))
	mac.Write([]byte(strings.TrimSpace(payload)))
	return hex.EncodeToString(mac.Sum(nil))
}

func BuildWebhookSignatureHeader(signature string) string {
	return "sha256=" + strings.TrimSpace(signature)
}

func normalizeWebhookDeliveryValue(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func isValidWebhookURL(rawURL string) bool {
	parsed, err := url.Parse(strings.TrimSpace(rawURL))
	if err != nil {
		return false
	}
	if parsed.Scheme != "https" && parsed.Scheme != "http" {
		return false
	}
	if parsed.Host == "" {
		return false
	}
	return true
}

func webhookDeliveryIdempotencyKey(tenantID string, idempotencyKey string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(idempotencyKey)
}

func NewWebhookDeliveryID() string {
	return randomOpsRuntimeID("webhook_delivery_")
}
