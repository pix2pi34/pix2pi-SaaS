package reconciliation

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type ReconciliationChannel string

const (
	ChannelPOS                   ReconciliationChannel = "POS"
	ChannelVirtualPOS            ReconciliationChannel = "VIRTUAL_POS"
	ChannelBankTransfer          ReconciliationChannel = "BANK_TRANSFER"
	ChannelBankCollection        ReconciliationChannel = "BANK_COLLECTION"
	ChannelMarketplaceSettlement ReconciliationChannel = "MARKETPLACE_SETTLEMENT"
)

type ReconciliationKind string

const (
	KindPaymentCapture        ReconciliationKind = "PAYMENT_CAPTURE"
	KindBankStatement         ReconciliationKind = "BANK_STATEMENT"
	KindMarketplaceSettlement ReconciliationKind = "MARKETPLACE_SETTLEMENT"
	KindRefundReversal        ReconciliationKind = "REFUND_REVERSAL"
)

type DecisionStatus string

const (
	DecisionMatched          DecisionStatus = "MATCHED"
	DecisionDifferenceReview DecisionStatus = "DIFFERENCE_REVIEW"
	DecisionRejected         DecisionStatus = "REJECTED"
	DecisionIgnored          DecisionStatus = "IGNORED"
)

type ReconciliationStatus string

const (
	StatusMatched        ReconciliationStatus = "MATCHED"
	StatusDifference     ReconciliationStatus = "DIFFERENCE_FOUND"
	StatusManualReview   ReconciliationStatus = "MANUAL_REVIEW_REQUIRED"
	StatusRejected       ReconciliationStatus = "REJECTED"
	StatusAlreadyCurrent ReconciliationStatus = "ALREADY_CURRENT"
)

type RuntimeConfig struct {
	RuntimeEnabled               bool                    `json:"runtime_enabled"`
	DefaultCurrencyCode          string                  `json:"default_currency_code"`
	ReconciliationToleranceKurus int64                   `json:"reconciliation_tolerance_kurus"`
	IdempotencyRequired          bool                    `json:"idempotency_required"`
	StatementHashRequired        bool                    `json:"statement_hash_required"`
	ProviderPayloadHashRequired  bool                    `json:"provider_payload_hash_required"`
	ManualReviewEnabled          bool                    `json:"manual_review_enabled"`
	AllowedChannels              []ReconciliationChannel `json:"allowed_channels"`
	AllowedProviderCodes         []string                `json:"allowed_provider_codes"`
}

type ReconciliationRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReconciliationID string             `json:"reconciliation_id"`
	Kind             ReconciliationKind `json:"kind"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	TransactionNo        string `json:"transaction_no"`

	Channel               ReconciliationChannel `json:"channel"`
	ProviderCode          string                `json:"provider_code"`
	ProviderTransactionID string                `json:"provider_transaction_id"`
	ProviderPayloadHash   string                `json:"provider_payload_hash"`

	BankAccountID        string `json:"bank_account_id"`
	BankReferenceNo      string `json:"bank_reference_no"`
	StatementLineID      string `json:"statement_line_id"`
	StatementPayloadHash string `json:"statement_payload_hash"`

	MarketplaceSettlementID string `json:"marketplace_settlement_id"`
	MarketplaceOrderID      string `json:"marketplace_order_id"`

	SourceDocumentType string `json:"source_document_type"`
	SourceDocumentID   string `json:"source_document_id"`
	SourceDocumentNo   string `json:"source_document_no"`

	LedgerMovementID string `json:"ledger_movement_id"`
	JournalID        string `json:"journal_id"`

	ExpectedAmountKurus   int64  `json:"expected_amount_kurus"`
	ActualAmountKurus     int64  `json:"actual_amount_kurus"`
	FeeAmountKurus        int64  `json:"fee_amount_kurus"`
	CommissionAmountKurus int64  `json:"commission_amount_kurus"`
	CurrencyCode          string `json:"currency_code"`

	OccurredAt  time.Time `json:"occurred_at"`
	RequestedAt time.Time `json:"requested_at"`
}

type ReconciliationResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReconciliationID string             `json:"reconciliation_id"`
	Kind             ReconciliationKind `json:"kind"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	TransactionNo        string `json:"transaction_no"`

	Channel               ReconciliationChannel `json:"channel"`
	ProviderCode          string                `json:"provider_code"`
	ProviderTransactionID string                `json:"provider_transaction_id"`

	DecisionStatus       DecisionStatus       `json:"decision_status"`
	ReconciliationStatus ReconciliationStatus `json:"reconciliation_status"`

	ExpectedAmountKurus   int64 `json:"expected_amount_kurus"`
	ActualAmountKurus     int64 `json:"actual_amount_kurus"`
	DifferenceAmountKurus int64 `json:"difference_amount_kurus"`
	ToleranceKurus        int64 `json:"tolerance_kurus"`

	Matched              bool `json:"matched"`
	ManualReviewRequired bool `json:"manual_review_required"`
	LedgerPostingReady   bool `json:"ledger_posting_ready"`
	PaymentClosureReady  bool `json:"payment_closure_ready"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	ReconciledAt        time.Time `json:"reconciled_at"`
}

type ReconciliationRuntime struct {
	config RuntimeConfig
}

func NewReconciliationRuntime(config RuntimeConfig) (*ReconciliationRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("reconciliation runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.ReconciliationToleranceKurus < 0 {
		return nil, errors.New("reconciliation_tolerance_kurus cannot be negative")
	}
	if len(config.AllowedChannels) == 0 {
		return nil, errors.New("allowed_channels are required")
	}
	if len(config.AllowedProviderCodes) == 0 {
		return nil, errors.New("allowed_provider_codes are required")
	}

	return &ReconciliationRuntime{config: config}, nil
}

func (r *ReconciliationRuntime) ReconcilePaymentCapture(req ReconciliationRequest) (ReconciliationResult, error) {
	req.Kind = KindPaymentCapture

	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, r.config, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Channel != ChannelPOS && req.Channel != ChannelVirtualPOS {
		return rejected(req, r.config, "PAYMENT_CAPTURE_CHANNEL_INVALID", "payment capture reconciliation requires POS or VIRTUAL_POS channel"), errors.New("payment capture reconciliation requires POS or VIRTUAL_POS channel")
	}
	if strings.TrimSpace(req.ProviderTransactionID) == "" {
		return rejected(req, r.config, "PROVIDER_TRANSACTION_ID_REQUIRED", "provider_transaction_id is required"), errors.New("provider_transaction_id is required")
	}

	return r.applyAmountReconciliation(req), nil
}

func (r *ReconciliationRuntime) ReconcileBankStatement(req ReconciliationRequest) (ReconciliationResult, error) {
	req.Kind = KindBankStatement

	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, r.config, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Channel != ChannelBankCollection && req.Channel != ChannelBankTransfer {
		return rejected(req, r.config, "BANK_RECONCILIATION_CHANNEL_INVALID", "bank reconciliation requires BANK_COLLECTION or BANK_TRANSFER channel"), errors.New("bank reconciliation requires BANK_COLLECTION or BANK_TRANSFER channel")
	}
	if strings.TrimSpace(req.BankAccountID) == "" {
		return rejected(req, r.config, "BANK_ACCOUNT_ID_REQUIRED", "bank_account_id is required"), errors.New("bank_account_id is required")
	}
	if strings.TrimSpace(req.BankReferenceNo) == "" {
		return rejected(req, r.config, "BANK_REFERENCE_NO_REQUIRED", "bank_reference_no is required"), errors.New("bank_reference_no is required")
	}
	if strings.TrimSpace(req.StatementLineID) == "" {
		return rejected(req, r.config, "STATEMENT_LINE_ID_REQUIRED", "statement_line_id is required"), errors.New("statement_line_id is required")
	}
	if r.config.StatementHashRequired && strings.TrimSpace(req.StatementPayloadHash) == "" {
		return rejected(req, r.config, "STATEMENT_PAYLOAD_HASH_REQUIRED", "statement_payload_hash is required"), errors.New("statement_payload_hash is required")
	}

	return r.applyAmountReconciliation(req), nil
}

func (r *ReconciliationRuntime) ReconcileMarketplaceSettlement(req ReconciliationRequest) (ReconciliationResult, error) {
	req.Kind = KindMarketplaceSettlement

	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, r.config, "VALIDATION_FAILED", err.Error()), err
	}
	if req.Channel != ChannelMarketplaceSettlement {
		return rejected(req, r.config, "MARKETPLACE_CHANNEL_INVALID", "marketplace reconciliation requires MARKETPLACE_SETTLEMENT channel"), errors.New("marketplace reconciliation requires MARKETPLACE_SETTLEMENT channel")
	}
	if strings.TrimSpace(req.MarketplaceSettlementID) == "" {
		return rejected(req, r.config, "MARKETPLACE_SETTLEMENT_ID_REQUIRED", "marketplace_settlement_id is required"), errors.New("marketplace_settlement_id is required")
	}

	return r.applyNetSettlementReconciliation(req), nil
}

func (r *ReconciliationRuntime) ReconcileRefundReversal(req ReconciliationRequest) (ReconciliationResult, error) {
	req.Kind = KindRefundReversal

	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, r.config, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.ProviderTransactionID) == "" {
		return rejected(req, r.config, "PROVIDER_TRANSACTION_ID_REQUIRED", "provider_transaction_id is required"), errors.New("provider_transaction_id is required")
	}

	return r.applyAmountReconciliation(req), nil
}

func (r *ReconciliationRuntime) RegisterManualReview(req ReconciliationRequest, reason string) (ReconciliationResult, error) {
	if !r.config.ManualReviewEnabled {
		return rejected(req, r.config, "MANUAL_REVIEW_DISABLED", "manual review is disabled"), errors.New("manual review is disabled")
	}
	if strings.TrimSpace(reason) == "" {
		return rejected(req, r.config, "MANUAL_REVIEW_REASON_REQUIRED", "manual review reason is required"), errors.New("manual review reason is required")
	}
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, r.config, "VALIDATION_FAILED", err.Error()), err
	}

	result := r.baseResult(req)
	result.DecisionStatus = DecisionDifferenceReview
	result.ReconciliationStatus = StatusManualReview
	result.DifferenceAmountKurus = absoluteDiff(req.ExpectedAmountKurus, req.ActualAmountKurus)
	result.ManualReviewRequired = true
	result.AuditAction = "RECONCILIATION_MANUAL_REVIEW_REGISTERED"
	result.AuditDecisionReason = reason
	result.ReconciledAt = time.Now().UTC()
	return result, nil
}

func (r *ReconciliationRuntime) validateBaseRequest(req ReconciliationRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.ReconciliationID) == "" {
		return errors.New("reconciliation_id is required")
	}
	if strings.TrimSpace(req.PaymentTransactionID) == "" {
		return errors.New("payment_transaction_id is required")
	}
	if strings.TrimSpace(req.TransactionNo) == "" {
		return errors.New("transaction_no is required")
	}
	if !r.channelAllowed(req.Channel) {
		return fmt.Errorf("reconciliation channel is not allowed: %s", req.Channel)
	}
	if !r.providerAllowed(req.ProviderCode) {
		return fmt.Errorf("provider_code is not allowed: %s", req.ProviderCode)
	}
	if r.config.ProviderPayloadHashRequired && strings.TrimSpace(req.ProviderPayloadHash) == "" {
		return errors.New("provider_payload_hash is required")
	}
	if req.ExpectedAmountKurus <= 0 {
		return errors.New("expected_amount_kurus must be positive")
	}
	if req.ActualAmountKurus <= 0 {
		return errors.New("actual_amount_kurus must be positive")
	}
	if req.FeeAmountKurus < 0 {
		return errors.New("fee_amount_kurus cannot be negative")
	}
	if req.CommissionAmountKurus < 0 {
		return errors.New("commission_amount_kurus cannot be negative")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("currency_code mismatch")
	}
	if req.OccurredAt.IsZero() {
		return errors.New("occurred_at is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ReconciliationRuntime) applyAmountReconciliation(req ReconciliationRequest) ReconciliationResult {
	result := r.baseResult(req)
	diff := absoluteDiff(req.ExpectedAmountKurus, req.ActualAmountKurus)

	result.DifferenceAmountKurus = diff
	result.ToleranceKurus = r.config.ReconciliationToleranceKurus
	result.ReconciledAt = time.Now().UTC()

	if diff <= r.config.ReconciliationToleranceKurus {
		result.DecisionStatus = DecisionMatched
		result.ReconciliationStatus = StatusMatched
		result.Matched = true
		result.LedgerPostingReady = true
		result.PaymentClosureReady = true
		result.AuditAction = "RECONCILIATION_MATCHED"
		result.AuditDecisionReason = "actual amount is inside reconciliation tolerance"
		return result
	}

	result.DecisionStatus = DecisionDifferenceReview
	result.ReconciliationStatus = StatusDifference
	result.Matched = false
	result.ManualReviewRequired = r.config.ManualReviewEnabled
	result.LedgerPostingReady = false
	result.PaymentClosureReady = false
	result.AuditAction = "RECONCILIATION_DIFFERENCE_REVIEW_REQUIRED"
	result.AuditDecisionReason = "actual amount difference exceeds reconciliation tolerance"
	return result
}

func (r *ReconciliationRuntime) applyNetSettlementReconciliation(req ReconciliationRequest) ReconciliationResult {
	expectedNet := req.ExpectedAmountKurus - req.FeeAmountKurus - req.CommissionAmountKurus
	req.ExpectedAmountKurus = expectedNet
	return r.applyAmountReconciliation(req)
}

func (r *ReconciliationRuntime) baseResult(req ReconciliationRequest) ReconciliationResult {
	return ReconciliationResult{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		IdempotencyKey:        req.IdempotencyKey,
		ReconciliationID:      req.ReconciliationID,
		Kind:                  req.Kind,
		PaymentTransactionID:  req.PaymentTransactionID,
		TransactionNo:         req.TransactionNo,
		Channel:               req.Channel,
		ProviderCode:          req.ProviderCode,
		ProviderTransactionID: req.ProviderTransactionID,
		ExpectedAmountKurus:   req.ExpectedAmountKurus,
		ActualAmountKurus:     req.ActualAmountKurus,
	}
}

func rejected(req ReconciliationRequest, config RuntimeConfig, code string, message string) ReconciliationResult {
	return ReconciliationResult{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		IdempotencyKey:        req.IdempotencyKey,
		ReconciliationID:      req.ReconciliationID,
		Kind:                  req.Kind,
		PaymentTransactionID:  req.PaymentTransactionID,
		TransactionNo:         req.TransactionNo,
		Channel:               req.Channel,
		ProviderCode:          req.ProviderCode,
		ProviderTransactionID: req.ProviderTransactionID,
		DecisionStatus:        DecisionRejected,
		ReconciliationStatus:  StatusRejected,
		ExpectedAmountKurus:   req.ExpectedAmountKurus,
		ActualAmountKurus:     req.ActualAmountKurus,
		ToleranceKurus:        config.ReconciliationToleranceKurus,
		ErrorCode:             code,
		ErrorMessage:          message,
		AuditAction:           "RECONCILIATION_REJECTED",
		AuditDecisionReason:   "reconciliation request rejected by runtime validation guard",
		ReconciledAt:          time.Now().UTC(),
	}
}

func (r *ReconciliationRuntime) channelAllowed(channel ReconciliationChannel) bool {
	for _, allowed := range r.config.AllowedChannels {
		if allowed == channel {
			return true
		}
	}
	return false
}

func (r *ReconciliationRuntime) providerAllowed(providerCode string) bool {
	for _, allowed := range r.config.AllowedProviderCodes {
		if allowed == providerCode {
			return true
		}
	}
	return false
}

func absoluteDiff(a int64, b int64) int64 {
	if a > b {
		return a - b
	}
	return b - a
}
