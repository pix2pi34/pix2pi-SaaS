package opsruntime

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	WebhookRetryStateScheduled = "RETRY_SCHEDULED"
	WebhookRetryStateCompleted = "RETRY_COMPLETED"
	WebhookRetryStateExhausted = "RETRY_EXHAUSTED"
	WebhookRetryStateDLQ       = "DLQ"

	WebhookRetryDecisionAllow = "ALLOW"
	WebhookRetryDecisionDeny  = "DENY"

	WebhookRetryReasonAllowed             = "WEBHOOK_RETRY_ALLOWED"
	WebhookRetryReasonMissingTenant       = "WEBHOOK_RETRY_MISSING_TENANT"
	WebhookRetryReasonMissingDeliveryID   = "WEBHOOK_RETRY_MISSING_DELIVERY_ID"
	WebhookRetryReasonMissingEventType    = "WEBHOOK_RETRY_MISSING_EVENT_TYPE"
	WebhookRetryReasonMissingURL          = "WEBHOOK_RETRY_MISSING_URL"
	WebhookRetryReasonMissingPayloadHash  = "WEBHOOK_RETRY_MISSING_PAYLOAD_HASH"
	WebhookRetryReasonMissingError        = "WEBHOOK_RETRY_MISSING_ERROR"
	WebhookRetryReasonInvalidAttempt      = "WEBHOOK_RETRY_INVALID_ATTEMPT"
	WebhookRetryReasonMaxAttemptsExceeded = "WEBHOOK_RETRY_MAX_ATTEMPTS_EXCEEDED"
	WebhookRetryReasonDuplicateRetry      = "WEBHOOK_RETRY_DUPLICATE_RETRY"
	WebhookRetryReasonCrossTenant         = "WEBHOOK_RETRY_CROSS_TENANT_DENIED"
	WebhookRetryReasonRetryNotFound       = "WEBHOOK_RETRY_NOT_FOUND"
	WebhookRetryReasonDLQDisabled         = "WEBHOOK_RETRY_DLQ_DISABLED"
	WebhookRetryReasonDLQNotFound         = "WEBHOOK_RETRY_DLQ_NOT_FOUND"
)

var (
	ErrWebhookRetryMissingTenant       = errors.New("missing webhook retry tenant id")
	ErrWebhookRetryMissingDeliveryID   = errors.New("missing webhook retry delivery id")
	ErrWebhookRetryMissingEventType    = errors.New("missing webhook retry event type")
	ErrWebhookRetryMissingURL          = errors.New("missing webhook retry url")
	ErrWebhookRetryMissingPayloadHash  = errors.New("missing webhook retry payload hash")
	ErrWebhookRetryMissingError        = errors.New("missing webhook retry error")
	ErrWebhookRetryInvalidAttempt      = errors.New("invalid webhook retry attempt")
	ErrWebhookRetryMaxAttemptsExceeded = errors.New("webhook retry max attempts exceeded")
	ErrWebhookRetryDuplicateRetry      = errors.New("duplicate webhook retry")
	ErrWebhookRetryCrossTenant         = errors.New("cross-tenant webhook retry access denied")
	ErrWebhookRetryNotFound            = errors.New("webhook retry not found")
	ErrWebhookRetryDLQDisabled         = errors.New("webhook retry dlq disabled")
	ErrWebhookRetryDLQNotFound         = errors.New("webhook retry dlq not found")
)

type WebhookRetryDLQRuntimeConfig struct {
	RequireTenant      bool `json:"require_tenant"`
	MaxAttempts        int  `json:"max_attempts"`
	BaseBackoffSeconds int  `json:"base_backoff_seconds"`
	MaxBackoffSeconds  int  `json:"max_backoff_seconds"`
	EnableDLQ          bool `json:"enable_dlq"`
	RequirePayloadHash bool `json:"require_payload_hash"`
	RequireLastError   bool `json:"require_last_error"`
}

func DefaultWebhookRetryDLQRuntimeConfig() WebhookRetryDLQRuntimeConfig {
	return WebhookRetryDLQRuntimeConfig{
		RequireTenant:      true,
		MaxAttempts:        5,
		BaseBackoffSeconds: 5,
		MaxBackoffSeconds:  300,
		EnableDLQ:          true,
		RequirePayloadHash: true,
		RequireLastError:   true,
	}
}

type WebhookRetryRequest struct {
	TenantID      string            `json:"tenant_id"`
	DeliveryID    string            `json:"delivery_id"`
	WebhookID     string            `json:"webhook_id,omitempty"`
	EventType     string            `json:"event_type"`
	URL           string            `json:"url"`
	PayloadHash   string            `json:"payload_hash"`
	Attempt       int               `json:"attempt"`
	LastError     string            `json:"last_error"`
	RequestedBy   string            `json:"requested_by,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
}

type WebhookRetryRecord struct {
	TenantID       string            `json:"tenant_id"`
	RetryID        string            `json:"retry_id"`
	DeliveryID     string            `json:"delivery_id"`
	WebhookID      string            `json:"webhook_id,omitempty"`
	EventType      string            `json:"event_type"`
	URL            string            `json:"url"`
	PayloadHash    string            `json:"payload_hash"`
	Attempt        int               `json:"attempt"`
	NextAttemptAt  string            `json:"next_attempt_at"`
	BackoffSeconds int               `json:"backoff_seconds"`
	State          string            `json:"state"`
	LastError      string            `json:"last_error"`
	RequestedBy    string            `json:"requested_by,omitempty"`
	CorrelationID  string            `json:"correlation_id,omitempty"`
	Metadata       map[string]string `json:"metadata,omitempty"`
	CreatedAt      string            `json:"created_at"`
	UpdatedAt      string            `json:"updated_at"`
}

type WebhookDLQRecord struct {
	TenantID      string            `json:"tenant_id"`
	DLQID         string            `json:"dlq_id"`
	DeliveryID    string            `json:"delivery_id"`
	WebhookID     string            `json:"webhook_id,omitempty"`
	EventType     string            `json:"event_type"`
	URL           string            `json:"url"`
	PayloadHash   string            `json:"payload_hash"`
	FinalAttempt  int               `json:"final_attempt"`
	LastError     string            `json:"last_error"`
	State         string            `json:"state"`
	RequestedBy   string            `json:"requested_by,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	CreatedAt     string            `json:"created_at"`
}

type WebhookRetryDLQDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	RetryID        string `json:"retry_id,omitempty"`
	DLQID          string `json:"dlq_id,omitempty"`
	DeliveryID     string `json:"delivery_id,omitempty"`
	EventType      string `json:"event_type,omitempty"`
	Attempt        int    `json:"attempt,omitempty"`
	BackoffSeconds int    `json:"backoff_seconds,omitempty"`
	NextAttemptAt  string `json:"next_attempt_at,omitempty"`
	State          string `json:"state,omitempty"`
	RequestedBy    string `json:"requested_by,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type WebhookRetryDLQRuntime struct {
	config  WebhookRetryDLQRuntimeConfig
	mu      sync.RWMutex
	retries map[string]WebhookRetryRecord
	dlq     map[string]WebhookDLQRecord
	dedupe  map[string]string
}

func NewWebhookRetryDLQRuntime(config WebhookRetryDLQRuntimeConfig) *WebhookRetryDLQRuntime {
	defaults := DefaultWebhookRetryDLQRuntimeConfig()

	if config.MaxAttempts <= 0 {
		config.MaxAttempts = defaults.MaxAttempts
	}
	if config.BaseBackoffSeconds <= 0 {
		config.BaseBackoffSeconds = defaults.BaseBackoffSeconds
	}
	if config.MaxBackoffSeconds <= 0 {
		config.MaxBackoffSeconds = defaults.MaxBackoffSeconds
	}

	return &WebhookRetryDLQRuntime{
		config:  config,
		retries: make(map[string]WebhookRetryRecord),
		dlq:     make(map[string]WebhookDLQRecord),
		dedupe:  make(map[string]string),
	}
}

func (r *WebhookRetryDLQRuntime) ScheduleRetry(req WebhookRetryRequest) (WebhookRetryRecord, WebhookRetryDLQDecision, error) {
	nowTime := time.Now().UTC()
	now := nowTime.Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	deliveryID := strings.TrimSpace(req.DeliveryID)
	eventType := strings.TrimSpace(req.EventType)
	targetURL := strings.TrimSpace(req.URL)
	payloadHash := strings.TrimSpace(req.PayloadHash)
	lastError := strings.TrimSpace(req.LastError)
	attempt := req.Attempt

	decision := WebhookRetryDLQDecision{
		Decision:      WebhookRetryDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		DeliveryID:    deliveryID,
		EventType:     eventType,
		Attempt:       attempt,
		RequestedBy:   strings.TrimSpace(req.RequestedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        WebhookRetryReasonAllowed,
		CheckedAt:     now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WebhookRetryReasonMissingTenant
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMissingTenant
	}

	if deliveryID == "" {
		decision.Reason = WebhookRetryReasonMissingDeliveryID
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMissingDeliveryID
	}

	if eventType == "" {
		decision.Reason = WebhookRetryReasonMissingEventType
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMissingEventType
	}

	if targetURL == "" {
		decision.Reason = WebhookRetryReasonMissingURL
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMissingURL
	}

	if r.config.RequirePayloadHash && payloadHash == "" {
		decision.Reason = WebhookRetryReasonMissingPayloadHash
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMissingPayloadHash
	}

	if r.config.RequireLastError && lastError == "" {
		decision.Reason = WebhookRetryReasonMissingError
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMissingError
	}

	if attempt <= 0 {
		decision.Reason = WebhookRetryReasonInvalidAttempt
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryInvalidAttempt
	}

	if attempt > r.config.MaxAttempts {
		decision.Reason = WebhookRetryReasonMaxAttemptsExceeded
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMaxAttemptsExceeded
	}

	dedupeKey := webhookRetryDedupeKey(tenantID, deliveryID, attempt)

	r.mu.Lock()
	defer r.mu.Unlock()

	if existingRetryID, ok := r.dedupe[dedupeKey]; ok {
		decision.Reason = WebhookRetryReasonDuplicateRetry
		decision.RetryID = existingRetryID
		decision.State = WebhookRetryStateExhausted
		return WebhookRetryRecord{}, decision, ErrWebhookRetryDuplicateRetry
	}

	backoffSeconds := CalculateWebhookRetryBackoffSeconds(attempt, r.config.BaseBackoffSeconds, r.config.MaxBackoffSeconds)
	nextAttemptAt := nowTime.Add(time.Duration(backoffSeconds) * time.Second).Format(time.RFC3339Nano)

	record := WebhookRetryRecord{
		TenantID:       tenantID,
		RetryID:        NewWebhookRetryID(),
		DeliveryID:     deliveryID,
		WebhookID:      strings.TrimSpace(req.WebhookID),
		EventType:      eventType,
		URL:            targetURL,
		PayloadHash:    payloadHash,
		Attempt:        attempt,
		NextAttemptAt:  nextAttemptAt,
		BackoffSeconds: backoffSeconds,
		State:          WebhookRetryStateScheduled,
		LastError:      lastError,
		RequestedBy:    strings.TrimSpace(req.RequestedBy),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Metadata:       cloneJobDispatchPayload(req.Metadata),
		CreatedAt:      now,
		UpdatedAt:      now,
	}

	r.retries[record.RetryID] = record
	r.dedupe[dedupeKey] = record.RetryID

	decision.Decision = WebhookRetryDecisionAllow
	decision.Allowed = true
	decision.RetryID = record.RetryID
	decision.BackoffSeconds = record.BackoffSeconds
	decision.NextAttemptAt = record.NextAttemptAt
	decision.State = record.State
	decision.Reason = WebhookRetryReasonAllowed

	return record, decision, nil
}

func (r *WebhookRetryDLQRuntime) MarkRetryCompleted(tenantID string, retryID string) (WebhookRetryRecord, WebhookRetryDLQDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID = strings.TrimSpace(tenantID)
	retryID = strings.TrimSpace(retryID)

	decision := WebhookRetryDLQDecision{
		Decision:  WebhookRetryDecisionDeny,
		Allowed:   false,
		TenantID:  tenantID,
		RetryID:   retryID,
		Reason:    WebhookRetryReasonAllowed,
		CheckedAt: now,
	}

	if tenantID == "" {
		decision.Reason = WebhookRetryReasonMissingTenant
		return WebhookRetryRecord{}, decision, ErrWebhookRetryMissingTenant
	}

	if retryID == "" {
		decision.Reason = WebhookRetryReasonRetryNotFound
		return WebhookRetryRecord{}, decision, ErrWebhookRetryNotFound
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	record, ok := r.retries[retryID]
	if !ok {
		decision.Reason = WebhookRetryReasonRetryNotFound
		return WebhookRetryRecord{}, decision, ErrWebhookRetryNotFound
	}

	if record.TenantID != tenantID {
		decision.Reason = WebhookRetryReasonCrossTenant
		return WebhookRetryRecord{}, decision, ErrWebhookRetryCrossTenant
	}

	record.State = WebhookRetryStateCompleted
	record.UpdatedAt = now
	r.retries[retryID] = record

	decision.Decision = WebhookRetryDecisionAllow
	decision.Allowed = true
	decision.DeliveryID = record.DeliveryID
	decision.EventType = record.EventType
	decision.Attempt = record.Attempt
	decision.State = record.State
	decision.RequestedBy = record.RequestedBy
	decision.CorrelationID = record.CorrelationID
	decision.Reason = WebhookRetryReasonAllowed

	return record, decision, nil
}

func (r *WebhookRetryDLQRuntime) MoveToDLQ(req WebhookRetryRequest) (WebhookDLQRecord, WebhookRetryDLQDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	deliveryID := strings.TrimSpace(req.DeliveryID)
	eventType := strings.TrimSpace(req.EventType)
	targetURL := strings.TrimSpace(req.URL)
	payloadHash := strings.TrimSpace(req.PayloadHash)
	lastError := strings.TrimSpace(req.LastError)
	attempt := req.Attempt

	decision := WebhookRetryDLQDecision{
		Decision:      WebhookRetryDecisionDeny,
		Allowed:       false,
		TenantID:      tenantID,
		DeliveryID:    deliveryID,
		EventType:     eventType,
		Attempt:       attempt,
		RequestedBy:   strings.TrimSpace(req.RequestedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Reason:        WebhookRetryReasonAllowed,
		CheckedAt:     now,
	}

	if !r.config.EnableDLQ {
		decision.Reason = WebhookRetryReasonDLQDisabled
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryDLQDisabled
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = WebhookRetryReasonMissingTenant
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryMissingTenant
	}

	if deliveryID == "" {
		decision.Reason = WebhookRetryReasonMissingDeliveryID
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryMissingDeliveryID
	}

	if eventType == "" {
		decision.Reason = WebhookRetryReasonMissingEventType
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryMissingEventType
	}

	if targetURL == "" {
		decision.Reason = WebhookRetryReasonMissingURL
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryMissingURL
	}

	if r.config.RequirePayloadHash && payloadHash == "" {
		decision.Reason = WebhookRetryReasonMissingPayloadHash
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryMissingPayloadHash
	}

	if r.config.RequireLastError && lastError == "" {
		decision.Reason = WebhookRetryReasonMissingError
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryMissingError
	}

	if attempt <= 0 {
		decision.Reason = WebhookRetryReasonInvalidAttempt
		decision.State = WebhookRetryStateExhausted
		return WebhookDLQRecord{}, decision, ErrWebhookRetryInvalidAttempt
	}

	record := WebhookDLQRecord{
		TenantID:      tenantID,
		DLQID:         NewWebhookDLQID(),
		DeliveryID:    deliveryID,
		WebhookID:     strings.TrimSpace(req.WebhookID),
		EventType:     eventType,
		URL:           targetURL,
		PayloadHash:   payloadHash,
		FinalAttempt:  attempt,
		LastError:     lastError,
		State:         WebhookRetryStateDLQ,
		RequestedBy:   strings.TrimSpace(req.RequestedBy),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		Metadata:      cloneJobDispatchPayload(req.Metadata),
		CreatedAt:     now,
	}

	r.mu.Lock()
	r.dlq[record.DLQID] = record
	r.mu.Unlock()

	decision.Decision = WebhookRetryDecisionAllow
	decision.Allowed = true
	decision.DLQID = record.DLQID
	decision.State = record.State
	decision.Reason = WebhookRetryReasonAllowed

	return record, decision, nil
}

func (r *WebhookRetryDLQRuntime) GetRetry(tenantID string, retryID string) (WebhookRetryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	retryID = strings.TrimSpace(retryID)

	if tenantID == "" {
		return WebhookRetryRecord{}, ErrWebhookRetryMissingTenant
	}
	if retryID == "" {
		return WebhookRetryRecord{}, ErrWebhookRetryNotFound
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.retries[retryID]
	if !ok {
		return WebhookRetryRecord{}, ErrWebhookRetryNotFound
	}

	if record.TenantID != tenantID {
		return WebhookRetryRecord{}, ErrWebhookRetryCrossTenant
	}

	return record, nil
}

func (r *WebhookRetryDLQRuntime) GetDLQ(tenantID string, dlqID string) (WebhookDLQRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	dlqID = strings.TrimSpace(dlqID)

	if tenantID == "" {
		return WebhookDLQRecord{}, ErrWebhookRetryMissingTenant
	}
	if dlqID == "" {
		return WebhookDLQRecord{}, ErrWebhookRetryDLQNotFound
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.dlq[dlqID]
	if !ok {
		return WebhookDLQRecord{}, ErrWebhookRetryDLQNotFound
	}

	if record.TenantID != tenantID {
		return WebhookDLQRecord{}, ErrWebhookRetryCrossTenant
	}

	return record, nil
}

func (r *WebhookRetryDLQRuntime) ListTenantRetries(tenantID string) ([]WebhookRetryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrWebhookRetryMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]WebhookRetryRecord, 0)
	for _, record := range r.retries {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *WebhookRetryDLQRuntime) ListTenantDLQ(tenantID string) ([]WebhookDLQRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrWebhookRetryMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]WebhookDLQRecord, 0)
	for _, record := range r.dlq {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}

	return out, nil
}

func (r *WebhookRetryDLQRuntime) ListDeliveryRetries(tenantID string, deliveryID string) ([]WebhookRetryRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	deliveryID = strings.TrimSpace(deliveryID)

	if tenantID == "" {
		return nil, ErrWebhookRetryMissingTenant
	}
	if deliveryID == "" {
		return nil, ErrWebhookRetryMissingDeliveryID
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]WebhookRetryRecord, 0)
	for _, record := range r.retries {
		if record.TenantID == tenantID && record.DeliveryID == deliveryID {
			out = append(out, record)
		}
	}

	return out, nil
}

func CalculateWebhookRetryBackoffSeconds(attempt int, baseSeconds int, maxSeconds int) int {
	if attempt <= 0 {
		return 0
	}
	if baseSeconds <= 0 {
		baseSeconds = 5
	}
	if maxSeconds <= 0 {
		maxSeconds = 300
	}

	backoff := baseSeconds
	for i := 1; i < attempt; i++ {
		backoff = backoff * 2
		if backoff >= maxSeconds {
			return maxSeconds
		}
	}
	if backoff > maxSeconds {
		return maxSeconds
	}
	return backoff
}

func webhookRetryDedupeKey(tenantID string, deliveryID string, attempt int) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(deliveryID) + "::" + webhookRetryAttemptKey(attempt)
}

func webhookRetryAttemptKey(attempt int) string {
	return "attempt_" + strings.TrimSpace(time.Unix(int64(attempt), 0).UTC().Format("5"))
}

func NewWebhookRetryID() string {
	return randomOpsRuntimeID("webhook_retry_")
}

func NewWebhookDLQID() string {
	return randomOpsRuntimeID("webhook_dlq_")
}
