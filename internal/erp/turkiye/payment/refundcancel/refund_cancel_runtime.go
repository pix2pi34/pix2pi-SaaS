package refundcancel

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type RuntimeMode string

const (
	RuntimeModeSimulation RuntimeMode = "SIMULATION"
	RuntimeModeSandbox    RuntimeMode = "SANDBOX"
	RuntimeModeProduction RuntimeMode = "PRODUCTION"
)

type PaymentChannel string

const (
	ChannelPOS                   PaymentChannel = "POS"
	ChannelVirtualPOS            PaymentChannel = "VIRTUAL_POS"
	ChannelBankTransfer          PaymentChannel = "BANK_TRANSFER"
	ChannelBankCollection        PaymentChannel = "BANK_COLLECTION"
	ChannelMarketplaceSettlement PaymentChannel = "MARKETPLACE_SETTLEMENT"
)

type RefundCancelOperation string

const (
	OperationPrepareRefund    RefundCancelOperation = "PREPARE_REFUND"
	OperationRegisterRefund   RefundCancelOperation = "REGISTER_REFUND_ACCEPTED"
	OperationPrepareCancel    RefundCancelOperation = "PREPARE_CANCEL"
	OperationRegisterCancel   RefundCancelOperation = "REGISTER_CANCEL_ACCEPTED"
	OperationPrepareVoid      RefundCancelOperation = "PREPARE_VOID"
	OperationRegisterVoid     RefundCancelOperation = "REGISTER_VOID_ACCEPTED"
	OperationPrepareReversal  RefundCancelOperation = "PREPARE_REVERSAL"
	OperationRegisterReversal RefundCancelOperation = "REGISTER_REVERSAL_ACCEPTED"
	OperationStatusCheck      RefundCancelOperation = "STATUS_CHECK"
)

type DecisionStatus string

const (
	DecisionQueued   DecisionStatus = "QUEUED"
	DecisionAccepted DecisionStatus = "ACCEPTED"
	DecisionRejected DecisionStatus = "REJECTED"
	DecisionIgnored  DecisionStatus = "IGNORED"
)

type LifecycleStatus string

const (
	LifecycleRefundQueued     LifecycleStatus = "REFUND_QUEUED"
	LifecycleRefundAccepted   LifecycleStatus = "REFUND_ACCEPTED"
	LifecycleCancelQueued     LifecycleStatus = "CANCEL_QUEUED"
	LifecycleCancelAccepted   LifecycleStatus = "CANCEL_ACCEPTED"
	LifecycleVoidQueued       LifecycleStatus = "VOID_QUEUED"
	LifecycleVoidAccepted     LifecycleStatus = "VOID_ACCEPTED"
	LifecycleReversalQueued   LifecycleStatus = "REVERSAL_QUEUED"
	LifecycleReversalAccepted LifecycleStatus = "REVERSAL_ACCEPTED"
	LifecycleStatusChecked    LifecycleStatus = "STATUS_CHECKED"
	LifecycleRejected         LifecycleStatus = "REJECTED"
)

type RuntimeConfig struct {
	Mode                           RuntimeMode      `json:"mode"`
	RealPaymentGateOpen            bool             `json:"real_payment_gate_open"`
	ProductionApproved             bool             `json:"production_approved"`
	DefaultCurrencyCode            string           `json:"default_currency_code"`
	IdempotencyRequired            bool             `json:"idempotency_required"`
	ProviderPayloadHashRequired    bool             `json:"provider_payload_hash_required"`
	ReasonRequired                 bool             `json:"reason_required"`
	PartialRefundAllowed           bool             `json:"partial_refund_allowed"`
	FullRefundAllowed              bool             `json:"full_refund_allowed"`
	VoidAllowedBeforeSettlement    bool             `json:"void_allowed_before_settlement"`
	CancelAllowedBeforeCapture     bool             `json:"cancel_allowed_before_capture"`
	ReversalAllowedAfterSettlement bool             `json:"reversal_allowed_after_settlement"`
	AllowedChannels                []PaymentChannel `json:"allowed_channels"`
	AllowedProviderCodes           []string         `json:"allowed_provider_codes"`
}

type RefundCancelRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	TransactionNo        string `json:"transaction_no"`

	Channel               PaymentChannel `json:"channel"`
	ProviderCode          string         `json:"provider_code"`
	ProviderTransactionID string         `json:"provider_transaction_id"`
	ProviderPayloadHash   string         `json:"provider_payload_hash"`

	SourceDocumentType string `json:"source_document_type"`
	SourceDocumentID   string `json:"source_document_id"`
	SourceDocumentNo   string `json:"source_document_no"`

	OriginalAmountKurus        int64  `json:"original_amount_kurus"`
	RequestedAmountKurus       int64  `json:"requested_amount_kurus"`
	AlreadyRefundedAmountKurus int64  `json:"already_refunded_amount_kurus"`
	CurrencyCode               string `json:"currency_code"`

	Settled    bool `json:"settled"`
	Captured   bool `json:"captured"`
	Authorized bool `json:"authorized"`

	ReasonCode  string    `json:"reason_code"`
	ReasonText  string    `json:"reason_text"`
	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type RefundCancelResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	TransactionNo        string `json:"transaction_no"`

	Channel               PaymentChannel `json:"channel"`
	ProviderCode          string         `json:"provider_code"`
	ProviderTransactionID string         `json:"provider_transaction_id"`

	Operation       RefundCancelOperation `json:"operation"`
	DecisionStatus  DecisionStatus        `json:"decision_status"`
	LifecycleStatus LifecycleStatus       `json:"lifecycle_status"`

	RefundCancelID   string `json:"refund_cancel_id"`
	ProviderActionID string `json:"provider_action_id"`

	OriginalAmountKurus            int64 `json:"original_amount_kurus"`
	RequestedAmountKurus           int64 `json:"requested_amount_kurus"`
	RemainingRefundableAmountKurus int64 `json:"remaining_refundable_amount_kurus"`

	ProviderCallReady      bool `json:"provider_call_ready"`
	ReconciliationRequired bool `json:"reconciliation_required"`
	LedgerPostingRequired  bool `json:"ledger_posting_required"`
	ManualReviewRequired   bool `json:"manual_review_required"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	DecidedAt           time.Time `json:"decided_at"`
}

type RefundCancelRuntime struct {
	config RuntimeConfig
}

func NewRefundCancelRuntime(config RuntimeConfig) (*RefundCancelRuntime, error) {
	if config.Mode == "" {
		return nil, errors.New("runtime mode is required")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if len(config.AllowedChannels) == 0 {
		return nil, errors.New("allowed_channels are required")
	}
	if len(config.AllowedProviderCodes) == 0 {
		return nil, errors.New("allowed_provider_codes are required")
	}
	if config.Mode == RuntimeModeProduction && (!config.RealPaymentGateOpen || !config.ProductionApproved) {
		return nil, errors.New("production real payment access is closed until approvals and real payment gate are open")
	}

	return &RefundCancelRuntime{config: config}, nil
}

func (r *RefundCancelRuntime) PrepareRefund(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationPrepareRefund, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateRefundRequest(req); err != nil {
		return rejected(req, OperationPrepareRefund, "REFUND_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationPrepareRefund, DecisionQueued, LifecycleRefundQueued, "REFUND_PREPARED", "refund request validated and queued for provider runtime"), nil
}

func (r *RefundCancelRuntime) RegisterRefundAccepted(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationRegisterRefund, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateRefundRequest(req); err != nil {
		return rejected(req, OperationRegisterRefund, "REFUND_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationRegisterRefund, DecisionAccepted, LifecycleRefundAccepted, "REFUND_ACCEPTED", "provider refund accepted and lifecycle can continue"), nil
}

func (r *RefundCancelRuntime) PrepareCancel(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationPrepareCancel, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCancelRequest(req); err != nil {
		return rejected(req, OperationPrepareCancel, "CANCEL_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationPrepareCancel, DecisionQueued, LifecycleCancelQueued, "CANCEL_PREPARED", "cancel request validated and queued for provider runtime"), nil
}

func (r *RefundCancelRuntime) RegisterCancelAccepted(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationRegisterCancel, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateCancelRequest(req); err != nil {
		return rejected(req, OperationRegisterCancel, "CANCEL_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationRegisterCancel, DecisionAccepted, LifecycleCancelAccepted, "CANCEL_ACCEPTED", "provider cancel accepted and lifecycle can continue"), nil
}

func (r *RefundCancelRuntime) PrepareVoid(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationPrepareVoid, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateVoidRequest(req); err != nil {
		return rejected(req, OperationPrepareVoid, "VOID_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationPrepareVoid, DecisionQueued, LifecycleVoidQueued, "VOID_PREPARED", "void request validated and queued for provider runtime"), nil
}

func (r *RefundCancelRuntime) RegisterVoidAccepted(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationRegisterVoid, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateVoidRequest(req); err != nil {
		return rejected(req, OperationRegisterVoid, "VOID_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationRegisterVoid, DecisionAccepted, LifecycleVoidAccepted, "VOID_ACCEPTED", "provider void accepted and lifecycle can continue"), nil
}

func (r *RefundCancelRuntime) PrepareReversal(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationPrepareReversal, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateReversalRequest(req); err != nil {
		return rejected(req, OperationPrepareReversal, "REVERSAL_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationPrepareReversal, DecisionQueued, LifecycleReversalQueued, "REVERSAL_PREPARED", "reversal request validated and queued for provider runtime"), nil
}

func (r *RefundCancelRuntime) RegisterReversalAccepted(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationRegisterReversal, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateReversalRequest(req); err != nil {
		return rejected(req, OperationRegisterReversal, "REVERSAL_VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationRegisterReversal, DecisionAccepted, LifecycleReversalAccepted, "REVERSAL_ACCEPTED", "provider reversal accepted and lifecycle can continue"), nil
}

func (r *RefundCancelRuntime) CheckStatus(req RefundCancelRequest) (RefundCancelResult, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejected(req, OperationStatusCheck, "VALIDATION_FAILED", err.Error()), err
	}

	return r.accepted(req, OperationStatusCheck, DecisionAccepted, LifecycleStatusChecked, "REFUND_CANCEL_STATUS_CHECKED", "refund/cancel/reversal status checked"), nil
}

func (r *RefundCancelRuntime) validateBaseRequest(req RefundCancelRequest) error {
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
	if r.config.ProviderPayloadHashRequired && strings.TrimSpace(req.ProviderPayloadHash) == "" {
		return errors.New("provider_payload_hash is required")
	}
	if req.OriginalAmountKurus <= 0 {
		return errors.New("original_amount_kurus must be positive")
	}
	if req.RequestedAmountKurus <= 0 {
		return errors.New("requested_amount_kurus must be positive")
	}
	if req.AlreadyRefundedAmountKurus < 0 {
		return errors.New("already_refunded_amount_kurus cannot be negative")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("currency_code mismatch")
	}
	if r.config.ReasonRequired && strings.TrimSpace(req.ReasonCode) == "" {
		return errors.New("reason_code is required")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *RefundCancelRuntime) validateRefundRequest(req RefundCancelRequest) error {
	if !r.config.PartialRefundAllowed && req.RequestedAmountKurus < req.OriginalAmountKurus {
		return errors.New("partial refund is not allowed")
	}
	if !r.config.FullRefundAllowed && req.RequestedAmountKurus == req.OriginalAmountKurus {
		return errors.New("full refund is not allowed")
	}
	remaining := remainingRefundable(req)
	if req.RequestedAmountKurus > remaining {
		return errors.New("requested_amount_kurus exceeds remaining refundable amount")
	}
	if !req.Captured {
		return errors.New("refund requires captured payment")
	}
	return nil
}

func (r *RefundCancelRuntime) validateCancelRequest(req RefundCancelRequest) error {
	if !r.config.CancelAllowedBeforeCapture {
		return errors.New("cancel before capture is disabled")
	}
	if !req.Authorized {
		return errors.New("cancel requires authorized payment")
	}
	if req.Captured {
		return errors.New("cancel is not allowed after capture")
	}
	if req.Settled {
		return errors.New("cancel is not allowed after settlement")
	}
	return nil
}

func (r *RefundCancelRuntime) validateVoidRequest(req RefundCancelRequest) error {
	if !r.config.VoidAllowedBeforeSettlement {
		return errors.New("void before settlement is disabled")
	}
	if !req.Captured {
		return errors.New("void requires captured payment")
	}
	if req.Settled {
		return errors.New("void is not allowed after settlement")
	}
	return nil
}

func (r *RefundCancelRuntime) validateReversalRequest(req RefundCancelRequest) error {
	if !r.config.ReversalAllowedAfterSettlement {
		return errors.New("reversal after settlement is disabled")
	}
	if !req.Settled {
		return errors.New("reversal requires settled payment")
	}
	return nil
}

func (r *RefundCancelRuntime) accepted(req RefundCancelRequest, operation RefundCancelOperation, decision DecisionStatus, lifecycle LifecycleStatus, auditAction string, reason string) RefundCancelResult {
	now := time.Now().UTC()

	return RefundCancelResult{
		TenantID:                       req.TenantID,
		CorrelationID:                  req.CorrelationID,
		RequestID:                      req.RequestID,
		IdempotencyKey:                 req.IdempotencyKey,
		PaymentTransactionID:           req.PaymentTransactionID,
		TransactionNo:                  req.TransactionNo,
		Channel:                        req.Channel,
		ProviderCode:                   req.ProviderCode,
		ProviderTransactionID:          req.ProviderTransactionID,
		Operation:                      operation,
		DecisionStatus:                 decision,
		LifecycleStatus:                lifecycle,
		RefundCancelID:                 fmt.Sprintf("RFC-%s-%s", req.ProviderCode, req.PaymentTransactionID),
		ProviderActionID:               fmt.Sprintf("%s-%s-%s", operation, req.ProviderCode, req.PaymentTransactionID),
		OriginalAmountKurus:            req.OriginalAmountKurus,
		RequestedAmountKurus:           req.RequestedAmountKurus,
		RemainingRefundableAmountKurus: remainingRefundable(req) - req.RequestedAmountKurus,
		ProviderCallReady:              true,
		ReconciliationRequired:         true,
		LedgerPostingRequired:          true,
		ManualReviewRequired:           false,
		AuditAction:                    auditAction,
		AuditDecisionReason:            reason,
		DecidedAt:                      now,
	}
}

func rejected(req RefundCancelRequest, operation RefundCancelOperation, code string, message string) RefundCancelResult {
	return RefundCancelResult{
		TenantID:               req.TenantID,
		CorrelationID:          req.CorrelationID,
		RequestID:              req.RequestID,
		IdempotencyKey:         req.IdempotencyKey,
		PaymentTransactionID:   req.PaymentTransactionID,
		TransactionNo:          req.TransactionNo,
		Channel:                req.Channel,
		ProviderCode:           req.ProviderCode,
		ProviderTransactionID:  req.ProviderTransactionID,
		Operation:              operation,
		DecisionStatus:         DecisionRejected,
		LifecycleStatus:        LifecycleRejected,
		OriginalAmountKurus:    req.OriginalAmountKurus,
		RequestedAmountKurus:   req.RequestedAmountKurus,
		ProviderCallReady:      false,
		ReconciliationRequired: false,
		LedgerPostingRequired:  false,
		ManualReviewRequired:   true,
		ErrorCode:              code,
		ErrorMessage:           message,
		AuditAction:            "REFUND_CANCEL_REJECTED",
		AuditDecisionReason:    "refund/cancel request rejected by runtime validation guard",
		DecidedAt:              time.Now().UTC(),
	}
}

func remainingRefundable(req RefundCancelRequest) int64 {
	remaining := req.OriginalAmountKurus - req.AlreadyRefundedAmountKurus
	if remaining < 0 {
		return 0
	}
	return remaining
}

func (r *RefundCancelRuntime) channelAllowed(channel PaymentChannel) bool {
	for _, allowed := range r.config.AllowedChannels {
		if allowed == channel {
			return true
		}
	}
	return false
}

func (r *RefundCancelRuntime) providerAllowed(providerCode string) bool {
	for _, allowed := range r.config.AllowedProviderCodes {
		if allowed == providerCode {
			return true
		}
	}
	return false
}
