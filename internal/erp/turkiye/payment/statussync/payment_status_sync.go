package statussync

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type PaymentChannel string

const (
	PaymentChannelPOS                   PaymentChannel = "POS"
	PaymentChannelBankTransfer          PaymentChannel = "BANK_TRANSFER"
	PaymentChannelBankCollection        PaymentChannel = "BANK_COLLECTION"
	PaymentChannelVirtualPOS            PaymentChannel = "VIRTUAL_POS"
	PaymentChannelMarketplaceSettlement PaymentChannel = "MARKETPLACE_SETTLEMENT"
)

type SyncSource string

const (
	SyncSourceCallback      SyncSource = "CALLBACK"
	SyncSourcePoll          SyncSource = "POLL"
	SyncSourceWebhook       SyncSource = "WEBHOOK"
	SyncSourceManualRecheck SyncSource = "MANUAL_RECHECK"
)

type ProviderPaymentStatus string

const (
	ProviderStatusCreated    ProviderPaymentStatus = "CREATED"
	ProviderStatusAuthorized ProviderPaymentStatus = "AUTHORIZED"
	ProviderStatusCaptured   ProviderPaymentStatus = "CAPTURED"
	ProviderStatusSold       ProviderPaymentStatus = "SOLD"
	ProviderStatusPending3DS ProviderPaymentStatus = "PENDING_3DS"
	ProviderStatusRefunded   ProviderPaymentStatus = "REFUNDED"
	ProviderStatusVoided     ProviderPaymentStatus = "VOIDED"
	ProviderStatusFailed     ProviderPaymentStatus = "FAILED"
	ProviderStatusRegistered ProviderPaymentStatus = "REGISTERED"
	ProviderStatusMatched    ProviderPaymentStatus = "MATCHED"
	ProviderStatusReconciled ProviderPaymentStatus = "RECONCILED"
	ProviderStatusSettled    ProviderPaymentStatus = "SETTLED"
	ProviderStatusReversed   ProviderPaymentStatus = "REVERSED"
)

type CanonicalPaymentStatus string

const (
	CanonicalStatusCreated    CanonicalPaymentStatus = "CREATED"
	CanonicalStatusAuthorized CanonicalPaymentStatus = "AUTHORIZED"
	CanonicalStatusCaptured   CanonicalPaymentStatus = "CAPTURED"
	CanonicalStatusPaid       CanonicalPaymentStatus = "PAID"
	CanonicalStatusPending3DS CanonicalPaymentStatus = "PENDING_3DS"
	CanonicalStatusRefunded   CanonicalPaymentStatus = "REFUNDED"
	CanonicalStatusVoided     CanonicalPaymentStatus = "VOIDED"
	CanonicalStatusFailed     CanonicalPaymentStatus = "FAILED"
	CanonicalStatusRegistered CanonicalPaymentStatus = "REGISTERED"
	CanonicalStatusMatched    CanonicalPaymentStatus = "MATCHED"
	CanonicalStatusReconciled CanonicalPaymentStatus = "RECONCILED"
	CanonicalStatusSettled    CanonicalPaymentStatus = "SETTLED"
	CanonicalStatusReversed   CanonicalPaymentStatus = "REVERSED"
)

type SyncDecisionStatus string

const (
	DecisionAccepted  SyncDecisionStatus = "ACCEPTED"
	DecisionIgnored   SyncDecisionStatus = "IGNORED"
	DecisionRejected  SyncDecisionStatus = "REJECTED"
	DecisionScheduled SyncDecisionStatus = "SCHEDULED"
)

type RuntimeConfig struct {
	CallbackSignatureRequired bool             `json:"callback_signature_required"`
	WebhookSignatureRequired  bool             `json:"webhook_signature_required"`
	PollEnabled               bool             `json:"poll_enabled"`
	ManualRecheckEnabled      bool             `json:"manual_recheck_enabled"`
	PollIntervalSeconds       int              `json:"poll_interval_seconds"`
	MaxPollBatchSize          int              `json:"max_poll_batch_size"`
	MaxRetryCount             int              `json:"max_retry_count"`
	AllowedChannels           []PaymentChannel `json:"allowed_channels"`
	AllowedProviderCodes      []string         `json:"allowed_provider_codes"`
}

type PaymentStatusSyncRequest struct {
	TenantID       string     `json:"tenant_id"`
	CorrelationID  string     `json:"correlation_id"`
	RequestID      string     `json:"request_id"`
	IdempotencyKey string     `json:"idempotency_key"`
	Source         SyncSource `json:"source"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	TransactionNo        string `json:"transaction_no"`

	Channel               PaymentChannel        `json:"channel"`
	ProviderCode          string                `json:"provider_code"`
	ProviderTransactionID string                `json:"provider_transaction_id"`
	ProviderStatus        ProviderPaymentStatus `json:"provider_status"`
	ProviderStatusText    string                `json:"provider_status_text"`
	ProviderPayloadHash   string                `json:"provider_payload_hash"`

	BankReferenceNo string `json:"bank_reference_no"`
	StatementLineID string `json:"statement_line_id"`

	AmountKurus  int64  `json:"amount_kurus"`
	CurrencyCode string `json:"currency_code"`

	CallbackSignature string `json:"callback_signature"`
	WebhookSignature  string `json:"webhook_signature"`

	ProviderEventTime time.Time `json:"provider_event_time"`
	ReceivedAt        time.Time `json:"received_at"`
}

type PaymentStatusSyncResult struct {
	TenantID      string     `json:"tenant_id"`
	CorrelationID string     `json:"correlation_id"`
	RequestID     string     `json:"request_id"`
	Source        SyncSource `json:"source"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	TransactionNo        string `json:"transaction_no"`

	Channel        PaymentChannel        `json:"channel"`
	ProviderCode   string                `json:"provider_code"`
	ProviderStatus ProviderPaymentStatus `json:"provider_status"`

	DecisionStatus SyncDecisionStatus     `json:"decision_status"`
	PreviousStatus CanonicalPaymentStatus `json:"previous_status"`
	NewStatus      CanonicalPaymentStatus `json:"new_status"`
	StatusChanged  bool                   `json:"status_changed"`

	PaymentCompleted        bool `json:"payment_completed"`
	RefundCompleted         bool `json:"refund_completed"`
	ReversalCompleted       bool `json:"reversal_completed"`
	ReconciliationCompleted bool `json:"reconciliation_completed"`

	Retryable      bool      `json:"retryable"`
	RetryScheduled bool      `json:"retry_scheduled"`
	RetryAfter     time.Time `json:"retry_after"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	ProcessedAt         time.Time `json:"processed_at"`
}

type PaymentPollCandidate struct {
	TenantID              string                 `json:"tenant_id"`
	PaymentTransactionID  string                 `json:"payment_transaction_id"`
	TransactionNo         string                 `json:"transaction_no"`
	Channel               PaymentChannel         `json:"channel"`
	ProviderCode          string                 `json:"provider_code"`
	ProviderTransactionID string                 `json:"provider_transaction_id"`
	LastKnownStatus       CanonicalPaymentStatus `json:"last_known_status"`
	RetryCount            int                    `json:"retry_count"`
	NextPollAt            time.Time              `json:"next_poll_at"`
}

type PaymentPollPlan struct {
	DecisionStatus SyncDecisionStatus     `json:"decision_status"`
	Candidates     []PaymentPollCandidate `json:"candidates"`
	SkippedCount   int                    `json:"skipped_count"`
	Reason         string                 `json:"reason"`
	PlannedAt      time.Time              `json:"planned_at"`
}

type PaymentStatusSyncRuntime struct {
	config RuntimeConfig
}

func NewPaymentStatusSyncRuntime(config RuntimeConfig) (*PaymentStatusSyncRuntime, error) {
	if config.PollIntervalSeconds <= 0 {
		return nil, errors.New("poll_interval_seconds must be positive")
	}
	if config.MaxPollBatchSize <= 0 {
		return nil, errors.New("max_poll_batch_size must be positive")
	}
	if config.MaxRetryCount < 0 {
		return nil, errors.New("max_retry_count cannot be negative")
	}
	if len(config.AllowedChannels) == 0 {
		return nil, errors.New("allowed_channels are required")
	}
	if len(config.AllowedProviderCodes) == 0 {
		return nil, errors.New("allowed_provider_codes are required")
	}

	return &PaymentStatusSyncRuntime{config: config}, nil
}

func (r *PaymentStatusSyncRuntime) HandleCallback(req PaymentStatusSyncRequest, previous CanonicalPaymentStatus) (PaymentStatusSyncResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, previous, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Source != SyncSourceCallback {
		return rejected(req, previous, "INVALID_SOURCE", "callback handler requires CALLBACK source"), errors.New("callback handler requires CALLBACK source")
	}
	if r.config.CallbackSignatureRequired && strings.TrimSpace(req.CallbackSignature) == "" {
		return rejected(req, previous, "CALLBACK_SIGNATURE_REQUIRED", "callback_signature is required"), errors.New("callback_signature is required")
	}

	return r.applyStatus(req, previous), nil
}

func (r *PaymentStatusSyncRuntime) HandleWebhook(req PaymentStatusSyncRequest, previous CanonicalPaymentStatus) (PaymentStatusSyncResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, previous, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Source != SyncSourceWebhook {
		return rejected(req, previous, "INVALID_SOURCE", "webhook handler requires WEBHOOK source"), errors.New("webhook handler requires WEBHOOK source")
	}
	if r.config.WebhookSignatureRequired && strings.TrimSpace(req.WebhookSignature) == "" {
		return rejected(req, previous, "WEBHOOK_SIGNATURE_REQUIRED", "webhook_signature is required"), errors.New("webhook_signature is required")
	}

	return r.applyStatus(req, previous), nil
}

func (r *PaymentStatusSyncRuntime) HandlePollResult(req PaymentStatusSyncRequest, previous CanonicalPaymentStatus) (PaymentStatusSyncResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, previous, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Source != SyncSourcePoll {
		return rejected(req, previous, "INVALID_SOURCE", "poll handler requires POLL source"), errors.New("poll handler requires POLL source")
	}

	return r.applyStatus(req, previous), nil
}

func (r *PaymentStatusSyncRuntime) HandleManualRecheck(req PaymentStatusSyncRequest, previous CanonicalPaymentStatus) (PaymentStatusSyncResult, error) {
	if !r.config.ManualRecheckEnabled {
		return rejected(req, previous, "MANUAL_RECHECK_DISABLED", "manual recheck is disabled"), errors.New("manual recheck is disabled")
	}
	if err := r.validateRequest(req); err != nil {
		return rejected(req, previous, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Source != SyncSourceManualRecheck {
		return rejected(req, previous, "INVALID_SOURCE", "manual recheck handler requires MANUAL_RECHECK source"), errors.New("manual recheck handler requires MANUAL_RECHECK source")
	}

	return r.applyStatus(req, previous), nil
}

func (r *PaymentStatusSyncRuntime) BuildPollPlan(candidates []PaymentPollCandidate, now time.Time) PaymentPollPlan {
	if !r.config.PollEnabled {
		return PaymentPollPlan{
			DecisionStatus: DecisionIgnored,
			SkippedCount:   len(candidates),
			Reason:         "polling is disabled",
			PlannedAt:      now.UTC(),
		}
	}

	planned := make([]PaymentPollCandidate, 0, r.config.MaxPollBatchSize)
	skipped := 0

	for _, candidate := range candidates {
		if len(planned) >= r.config.MaxPollBatchSize {
			skipped++
			continue
		}
		if candidate.NextPollAt.After(now) {
			skipped++
			continue
		}
		if candidate.RetryCount > r.config.MaxRetryCount {
			skipped++
			continue
		}
		if !r.channelAllowed(candidate.Channel) || !r.providerAllowed(candidate.ProviderCode) {
			skipped++
			continue
		}
		if strings.TrimSpace(candidate.ProviderTransactionID) == "" {
			skipped++
			continue
		}
		planned = append(planned, candidate)
	}

	decision := DecisionScheduled
	reason := "payment poll candidates scheduled"
	if len(planned) == 0 {
		decision = DecisionIgnored
		reason = "no eligible payment poll candidates"
	}

	return PaymentPollPlan{
		DecisionStatus: decision,
		Candidates:     planned,
		SkippedCount:   skipped,
		Reason:         reason,
		PlannedAt:      now.UTC(),
	}
}

func (r *PaymentStatusSyncRuntime) validateRequest(req PaymentStatusSyncRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.PaymentTransactionID) == "" {
		return errors.New("payment_transaction_id is required")
	}
	if strings.TrimSpace(req.TransactionNo) == "" {
		return errors.New("transaction_no is required")
	}
	if !r.channelAllowed(req.Channel) {
		return fmt.Errorf("payment channel is not allowed: %s", req.Channel)
	}
	if !r.providerAllowed(req.ProviderCode) {
		return fmt.Errorf("provider_code is not allowed: %s", req.ProviderCode)
	}
	if strings.TrimSpace(req.ProviderTransactionID) == "" {
		return errors.New("provider_transaction_id is required")
	}
	if strings.TrimSpace(string(req.ProviderStatus)) == "" {
		return errors.New("provider_status is required")
	}
	if strings.TrimSpace(req.ProviderPayloadHash) == "" {
		return errors.New("provider_payload_hash is required")
	}
	if req.AmountKurus <= 0 {
		return errors.New("amount_kurus must be positive")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.ProviderEventTime.IsZero() {
		return errors.New("provider_event_time is required")
	}
	if req.ReceivedAt.IsZero() {
		return errors.New("received_at is required")
	}
	if req.Channel == PaymentChannelBankCollection && strings.TrimSpace(req.BankReferenceNo) == "" {
		return errors.New("bank_reference_no is required for bank collection")
	}
	return nil
}

func (r *PaymentStatusSyncRuntime) applyStatus(req PaymentStatusSyncRequest, previous CanonicalPaymentStatus) PaymentStatusSyncResult {
	next := canonicalize(req.ProviderStatus)
	changed := previous != next

	decision := DecisionAccepted
	action := "PAYMENT_STATUS_SYNC_ACCEPTED"
	reason := "provider payment status accepted and canonical payment status updated"

	if !changed {
		decision = DecisionIgnored
		action = "PAYMENT_STATUS_SYNC_NO_CHANGE"
		reason = "provider payment status accepted but canonical status already current"
	}

	retryable := next == CanonicalStatusFailed
	retryScheduled := retryable
	retryAfter := time.Time{}

	if retryScheduled {
		retryAfter = req.ReceivedAt.Add(time.Duration(r.config.PollIntervalSeconds) * time.Second).UTC()
	}

	return PaymentStatusSyncResult{
		TenantID:                req.TenantID,
		CorrelationID:           req.CorrelationID,
		RequestID:               req.RequestID,
		Source:                  req.Source,
		PaymentTransactionID:    req.PaymentTransactionID,
		TransactionNo:           req.TransactionNo,
		Channel:                 req.Channel,
		ProviderCode:            req.ProviderCode,
		ProviderStatus:          req.ProviderStatus,
		DecisionStatus:          decision,
		PreviousStatus:          previous,
		NewStatus:               next,
		StatusChanged:           changed,
		PaymentCompleted:        isPaymentCompleted(next),
		RefundCompleted:         next == CanonicalStatusRefunded,
		ReversalCompleted:       next == CanonicalStatusVoided || next == CanonicalStatusReversed,
		ReconciliationCompleted: next == CanonicalStatusReconciled || next == CanonicalStatusSettled,
		Retryable:               retryable,
		RetryScheduled:          retryScheduled,
		RetryAfter:              retryAfter,
		AuditAction:             action,
		AuditDecisionReason:     reason,
		ProcessedAt:             time.Now().UTC(),
	}
}

func canonicalize(status ProviderPaymentStatus) CanonicalPaymentStatus {
	switch status {
	case ProviderStatusCreated:
		return CanonicalStatusCreated
	case ProviderStatusAuthorized:
		return CanonicalStatusAuthorized
	case ProviderStatusCaptured:
		return CanonicalStatusCaptured
	case ProviderStatusSold:
		return CanonicalStatusPaid
	case ProviderStatusPending3DS:
		return CanonicalStatusPending3DS
	case ProviderStatusRefunded:
		return CanonicalStatusRefunded
	case ProviderStatusVoided:
		return CanonicalStatusVoided
	case ProviderStatusFailed:
		return CanonicalStatusFailed
	case ProviderStatusRegistered:
		return CanonicalStatusRegistered
	case ProviderStatusMatched:
		return CanonicalStatusMatched
	case ProviderStatusReconciled:
		return CanonicalStatusReconciled
	case ProviderStatusSettled:
		return CanonicalStatusSettled
	case ProviderStatusReversed:
		return CanonicalStatusReversed
	default:
		return CanonicalStatusFailed
	}
}

func isPaymentCompleted(status CanonicalPaymentStatus) bool {
	return status == CanonicalStatusCaptured ||
		status == CanonicalStatusPaid ||
		status == CanonicalStatusReconciled ||
		status == CanonicalStatusSettled
}

func rejected(req PaymentStatusSyncRequest, previous CanonicalPaymentStatus, code string, message string) PaymentStatusSyncResult {
	return PaymentStatusSyncResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		Source:               req.Source,
		PaymentTransactionID: req.PaymentTransactionID,
		TransactionNo:        req.TransactionNo,
		Channel:              req.Channel,
		ProviderCode:         req.ProviderCode,
		ProviderStatus:       req.ProviderStatus,
		DecisionStatus:       DecisionRejected,
		PreviousStatus:       previous,
		StatusChanged:        false,
		Retryable:            false,
		RetryScheduled:       false,
		AuditAction:          "PAYMENT_STATUS_SYNC_REJECTED",
		AuditDecisionReason:  "payment status sync request rejected by validation guard",
		ErrorCode:            code,
		ErrorMessage:         message,
		ProcessedAt:          time.Now().UTC(),
	}
}

func (r *PaymentStatusSyncRuntime) channelAllowed(channel PaymentChannel) bool {
	for _, allowed := range r.config.AllowedChannels {
		if allowed == channel {
			return true
		}
	}
	return false
}

func (r *PaymentStatusSyncRuntime) providerAllowed(providerCode string) bool {
	for _, allowed := range r.config.AllowedProviderCodes {
		if allowed == providerCode {
			return true
		}
	}
	return false
}
