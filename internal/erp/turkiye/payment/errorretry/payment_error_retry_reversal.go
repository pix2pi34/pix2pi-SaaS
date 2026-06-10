package errorretry

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
	PaymentChannelPOS            PaymentChannel = "POS"
	PaymentChannelVirtualPOS     PaymentChannel = "VIRTUAL_POS"
	PaymentChannelBankCollection PaymentChannel = "BANK_COLLECTION"
	PaymentChannelBankTransfer   PaymentChannel = "BANK_TRANSFER"
	PaymentChannelMarketplace    PaymentChannel = "MARKETPLACE_SETTLEMENT"
)

type PaymentOperation string

const (
	OperationAuthorize      PaymentOperation = "AUTHORIZE"
	OperationCapture        PaymentOperation = "CAPTURE"
	OperationSale           PaymentOperation = "SALE"
	OperationRefund         PaymentOperation = "REFUND"
	OperationVoid           PaymentOperation = "VOID"
	OperationStatusCheck    PaymentOperation = "STATUS_CHECK"
	OperationBankCollection PaymentOperation = "BANK_COLLECTION"
	OperationReversal       PaymentOperation = "REVERSAL"
)

type ErrorClass string

const (
	ErrorClassRetryable    ErrorClass = "RETRYABLE"
	ErrorClassNonRetryable ErrorClass = "NON_RETRYABLE"
	ErrorClassDuplicate    ErrorClass = "DUPLICATE"
	ErrorClassManualReview ErrorClass = "MANUAL_REVIEW"
)

type RetryDecisionStatus string

const (
	DecisionRetryScheduled RetryDecisionStatus = "RETRY_SCHEDULED"
	DecisionDLQ            RetryDecisionStatus = "DLQ"
	DecisionNoRetry        RetryDecisionStatus = "NO_RETRY"
	DecisionDuplicate      RetryDecisionStatus = "DUPLICATE_IGNORED"
	DecisionManualReview   RetryDecisionStatus = "MANUAL_REVIEW"
)

type ReversalDecisionStatus string

const (
	ReversalDecisionQueued   ReversalDecisionStatus = "REVERSAL_QUEUED"
	ReversalDecisionAccepted ReversalDecisionStatus = "REVERSAL_ACCEPTED"
	ReversalDecisionRejected ReversalDecisionStatus = "REVERSAL_REJECTED"
)

type RuntimeConfig struct {
	Mode                        RuntimeMode      `json:"mode"`
	RealPaymentGateOpen         bool             `json:"real_payment_gate_open"`
	ProductionApproved          bool             `json:"production_approved"`
	MaxRetryCount               int              `json:"max_retry_count"`
	BaseRetryDelaySec           int              `json:"base_retry_delay_sec"`
	MaxRetryDelaySec            int              `json:"max_retry_delay_sec"`
	DLQEnabled                  bool             `json:"dlq_enabled"`
	ManualReviewEnabled         bool             `json:"manual_review_enabled"`
	ReversalReasonRequired      bool             `json:"reversal_reason_required"`
	IdempotencyRequired         bool             `json:"idempotency_required"`
	ProviderPayloadHashRequired bool             `json:"provider_payload_hash_required"`
	AllowedChannels             []PaymentChannel `json:"allowed_channels"`
	AllowedProviderCodes        []string         `json:"allowed_provider_codes"`
	RetryableErrorCodes         []string         `json:"retryable_error_codes"`
	FatalErrorCodes             []string         `json:"fatal_error_codes"`
	ManualReviewCodes           []string         `json:"manual_review_codes"`
}

type PaymentErrorEvent struct {
	TenantID              string           `json:"tenant_id"`
	CorrelationID         string           `json:"correlation_id"`
	RequestID             string           `json:"request_id"`
	IdempotencyKey        string           `json:"idempotency_key"`
	PaymentTransactionID  string           `json:"payment_transaction_id"`
	TransactionNo         string           `json:"transaction_no"`
	Channel               PaymentChannel   `json:"channel"`
	ProviderCode          string           `json:"provider_code"`
	ProviderTransactionID string           `json:"provider_transaction_id"`
	Operation             PaymentOperation `json:"operation"`
	ProviderErrorCode     string           `json:"provider_error_code"`
	ProviderErrorText     string           `json:"provider_error_text"`
	ProviderPayloadHash   string           `json:"provider_payload_hash"`
	AmountKurus           int64            `json:"amount_kurus"`
	CurrencyCode          string           `json:"currency_code"`
	RetryCount            int              `json:"retry_count"`
	OccurredAt            time.Time        `json:"occurred_at"`
	ReceivedAt            time.Time        `json:"received_at"`
}

type RetryDecision struct {
	TenantID              string              `json:"tenant_id"`
	CorrelationID         string              `json:"correlation_id"`
	RequestID             string              `json:"request_id"`
	PaymentTransactionID  string              `json:"payment_transaction_id"`
	TransactionNo         string              `json:"transaction_no"`
	Channel               PaymentChannel      `json:"channel"`
	ProviderCode          string              `json:"provider_code"`
	ProviderTransactionID string              `json:"provider_transaction_id"`
	Operation             PaymentOperation    `json:"operation"`
	ErrorClass            ErrorClass          `json:"error_class"`
	DecisionStatus        RetryDecisionStatus `json:"decision_status"`
	RetryCount            int                 `json:"retry_count"`
	NextRetryCount        int                 `json:"next_retry_count"`
	RetryAfter            time.Time           `json:"retry_after"`
	DLQRequired           bool                `json:"dlq_required"`
	ManualReviewRequired  bool                `json:"manual_review_required"`
	AuditAction           string              `json:"audit_action"`
	AuditDecisionReason   string              `json:"audit_decision_reason"`
	ErrorCode             string              `json:"error_code"`
	ErrorMessage          string              `json:"error_message"`
	DecidedAt             time.Time           `json:"decided_at"`
}

type ReversalRequest struct {
	TenantID              string           `json:"tenant_id"`
	CorrelationID         string           `json:"correlation_id"`
	RequestID             string           `json:"request_id"`
	IdempotencyKey        string           `json:"idempotency_key"`
	PaymentTransactionID  string           `json:"payment_transaction_id"`
	TransactionNo         string           `json:"transaction_no"`
	Channel               PaymentChannel   `json:"channel"`
	ProviderCode          string           `json:"provider_code"`
	ProviderTransactionID string           `json:"provider_transaction_id"`
	OriginalOperation     PaymentOperation `json:"original_operation"`
	AmountKurus           int64            `json:"amount_kurus"`
	CurrencyCode          string           `json:"currency_code"`
	ReversalReasonCode    string           `json:"reversal_reason_code"`
	ReversalReasonText    string           `json:"reversal_reason_text"`
	RequestedBy           string           `json:"requested_by"`
	RequestedAt           time.Time        `json:"requested_at"`
}

type ReversalDecision struct {
	TenantID              string                 `json:"tenant_id"`
	CorrelationID         string                 `json:"correlation_id"`
	RequestID             string                 `json:"request_id"`
	PaymentTransactionID  string                 `json:"payment_transaction_id"`
	TransactionNo         string                 `json:"transaction_no"`
	Channel               PaymentChannel         `json:"channel"`
	ProviderCode          string                 `json:"provider_code"`
	ProviderTransactionID string                 `json:"provider_transaction_id"`
	DecisionStatus        ReversalDecisionStatus `json:"decision_status"`
	ReversalID            string                 `json:"reversal_id"`
	AuditAction           string                 `json:"audit_action"`
	AuditDecisionReason   string                 `json:"audit_decision_reason"`
	ErrorCode             string                 `json:"error_code"`
	ErrorMessage          string                 `json:"error_message"`
	DecidedAt             time.Time              `json:"decided_at"`
}

type PaymentErrorRetryReversalRuntime struct {
	config RuntimeConfig
}

func NewPaymentErrorRetryReversalRuntime(config RuntimeConfig) (*PaymentErrorRetryReversalRuntime, error) {
	if config.Mode == "" {
		return nil, errors.New("runtime mode is required")
	}
	if config.MaxRetryCount < 0 {
		return nil, errors.New("max_retry_count cannot be negative")
	}
	if config.BaseRetryDelaySec <= 0 {
		return nil, errors.New("base_retry_delay_sec must be positive")
	}
	if config.MaxRetryDelaySec < config.BaseRetryDelaySec {
		return nil, errors.New("max_retry_delay_sec must be greater than or equal to base_retry_delay_sec")
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

	return &PaymentErrorRetryReversalRuntime{config: config}, nil
}

func (r *PaymentErrorRetryReversalRuntime) HandleProviderError(event PaymentErrorEvent) (RetryDecision, error) {
	if err := r.validateErrorEvent(event); err != nil {
		return rejectedRetryDecision(event, "VALIDATION_FAILED", err.Error()), err
	}

	class := r.classifyError(event.ProviderErrorCode)
	now := time.Now().UTC()

	switch class {
	case ErrorClassDuplicate:
		return RetryDecision{
			TenantID:              event.TenantID,
			CorrelationID:         event.CorrelationID,
			RequestID:             event.RequestID,
			PaymentTransactionID:  event.PaymentTransactionID,
			TransactionNo:         event.TransactionNo,
			Channel:               event.Channel,
			ProviderCode:          event.ProviderCode,
			ProviderTransactionID: event.ProviderTransactionID,
			Operation:             event.Operation,
			ErrorClass:            class,
			DecisionStatus:        DecisionDuplicate,
			RetryCount:            event.RetryCount,
			NextRetryCount:        event.RetryCount,
			AuditAction:           "PAYMENT_PROVIDER_ERROR_DUPLICATE_IGNORED",
			AuditDecisionReason:   "duplicate provider/idempotency error does not create a new retry",
			DecidedAt:             now,
		}, nil

	case ErrorClassManualReview:
		return RetryDecision{
			TenantID:              event.TenantID,
			CorrelationID:         event.CorrelationID,
			RequestID:             event.RequestID,
			PaymentTransactionID:  event.PaymentTransactionID,
			TransactionNo:         event.TransactionNo,
			Channel:               event.Channel,
			ProviderCode:          event.ProviderCode,
			ProviderTransactionID: event.ProviderTransactionID,
			Operation:             event.Operation,
			ErrorClass:            class,
			DecisionStatus:        DecisionManualReview,
			RetryCount:            event.RetryCount,
			NextRetryCount:        event.RetryCount,
			ManualReviewRequired:  r.config.ManualReviewEnabled,
			AuditAction:           "PAYMENT_PROVIDER_ERROR_MANUAL_REVIEW_REQUIRED",
			AuditDecisionReason:   "provider payment error requires manual review",
			DecidedAt:             now,
		}, nil

	case ErrorClassNonRetryable:
		return RetryDecision{
			TenantID:              event.TenantID,
			CorrelationID:         event.CorrelationID,
			RequestID:             event.RequestID,
			PaymentTransactionID:  event.PaymentTransactionID,
			TransactionNo:         event.TransactionNo,
			Channel:               event.Channel,
			ProviderCode:          event.ProviderCode,
			ProviderTransactionID: event.ProviderTransactionID,
			Operation:             event.Operation,
			ErrorClass:            class,
			DecisionStatus:        DecisionNoRetry,
			RetryCount:            event.RetryCount,
			NextRetryCount:        event.RetryCount,
			AuditAction:           "PAYMENT_PROVIDER_ERROR_NON_RETRYABLE",
			AuditDecisionReason:   "payment provider error is classified as non-retryable",
			DecidedAt:             now,
		}, nil

	default:
		if event.RetryCount >= r.config.MaxRetryCount {
			return RetryDecision{
				TenantID:              event.TenantID,
				CorrelationID:         event.CorrelationID,
				RequestID:             event.RequestID,
				PaymentTransactionID:  event.PaymentTransactionID,
				TransactionNo:         event.TransactionNo,
				Channel:               event.Channel,
				ProviderCode:          event.ProviderCode,
				ProviderTransactionID: event.ProviderTransactionID,
				Operation:             event.Operation,
				ErrorClass:            ErrorClassRetryable,
				DecisionStatus:        DecisionDLQ,
				RetryCount:            event.RetryCount,
				NextRetryCount:        event.RetryCount,
				DLQRequired:           r.config.DLQEnabled,
				AuditAction:           "PAYMENT_PROVIDER_ERROR_RETRY_EXHAUSTED_DLQ",
				AuditDecisionReason:   "max retry count reached; payment error must be moved to DLQ",
				DecidedAt:             now,
			}, nil
		}

		nextRetry := event.RetryCount + 1
		retryAfter := event.ReceivedAt.Add(time.Duration(r.retryDelaySeconds(nextRetry)) * time.Second).UTC()

		return RetryDecision{
			TenantID:              event.TenantID,
			CorrelationID:         event.CorrelationID,
			RequestID:             event.RequestID,
			PaymentTransactionID:  event.PaymentTransactionID,
			TransactionNo:         event.TransactionNo,
			Channel:               event.Channel,
			ProviderCode:          event.ProviderCode,
			ProviderTransactionID: event.ProviderTransactionID,
			Operation:             event.Operation,
			ErrorClass:            ErrorClassRetryable,
			DecisionStatus:        DecisionRetryScheduled,
			RetryCount:            event.RetryCount,
			NextRetryCount:        nextRetry,
			RetryAfter:            retryAfter,
			AuditAction:           "PAYMENT_PROVIDER_ERROR_RETRY_SCHEDULED",
			AuditDecisionReason:   "retryable payment provider error scheduled with bounded backoff",
			DecidedAt:             now,
		}, nil
	}
}

func (r *PaymentErrorRetryReversalRuntime) PrepareReversal(req ReversalRequest) (ReversalDecision, error) {
	if err := r.validateReversalRequest(req); err != nil {
		return rejectedReversalDecision(req, "VALIDATION_FAILED", err.Error()), err
	}

	return ReversalDecision{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		PaymentTransactionID:  req.PaymentTransactionID,
		TransactionNo:         req.TransactionNo,
		Channel:               req.Channel,
		ProviderCode:          req.ProviderCode,
		ProviderTransactionID: req.ProviderTransactionID,
		DecisionStatus:        ReversalDecisionQueued,
		ReversalID:            fmt.Sprintf("REVERSAL-%s-%s", req.ProviderCode, req.PaymentTransactionID),
		AuditAction:           "PAYMENT_REVERSAL_QUEUED",
		AuditDecisionReason:   "payment reversal request validated and queued",
		DecidedAt:             time.Now().UTC(),
	}, nil
}

func (r *PaymentErrorRetryReversalRuntime) RegisterReversalAccepted(req ReversalRequest) (ReversalDecision, error) {
	if err := r.validateReversalRequest(req); err != nil {
		return rejectedReversalDecision(req, "VALIDATION_FAILED", err.Error()), err
	}

	return ReversalDecision{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		PaymentTransactionID:  req.PaymentTransactionID,
		TransactionNo:         req.TransactionNo,
		Channel:               req.Channel,
		ProviderCode:          req.ProviderCode,
		ProviderTransactionID: req.ProviderTransactionID,
		DecisionStatus:        ReversalDecisionAccepted,
		ReversalID:            fmt.Sprintf("REVERSAL-ACCEPTED-%s-%s", req.ProviderCode, req.PaymentTransactionID),
		AuditAction:           "PAYMENT_REVERSAL_ACCEPTED",
		AuditDecisionReason:   "provider reversal result accepted",
		DecidedAt:             time.Now().UTC(),
	}, nil
}

func (r *PaymentErrorRetryReversalRuntime) classifyError(code string) ErrorClass {
	normalized := strings.ToUpper(strings.TrimSpace(code))

	if normalized == "DUPLICATE_IDEMPOTENCY_KEY" || normalized == "DUPLICATE_PROVIDER_TRANSACTION" {
		return ErrorClassDuplicate
	}

	for _, manual := range r.config.ManualReviewCodes {
		if normalized == strings.ToUpper(strings.TrimSpace(manual)) {
			return ErrorClassManualReview
		}
	}

	for _, fatal := range r.config.FatalErrorCodes {
		if normalized == strings.ToUpper(strings.TrimSpace(fatal)) {
			return ErrorClassNonRetryable
		}
	}

	for _, retryable := range r.config.RetryableErrorCodes {
		if normalized == strings.ToUpper(strings.TrimSpace(retryable)) {
			return ErrorClassRetryable
		}
	}

	return ErrorClassNonRetryable
}

func (r *PaymentErrorRetryReversalRuntime) retryDelaySeconds(nextRetryCount int) int {
	delay := r.config.BaseRetryDelaySec

	for i := 1; i < nextRetryCount; i++ {
		delay = delay * 2
		if delay >= r.config.MaxRetryDelaySec {
			return r.config.MaxRetryDelaySec
		}
	}

	if delay > r.config.MaxRetryDelaySec {
		return r.config.MaxRetryDelaySec
	}

	return delay
}

func (r *PaymentErrorRetryReversalRuntime) validateErrorEvent(event PaymentErrorEvent) error {
	if strings.TrimSpace(event.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(event.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(event.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(event.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(event.PaymentTransactionID) == "" {
		return errors.New("payment_transaction_id is required")
	}
	if strings.TrimSpace(event.TransactionNo) == "" {
		return errors.New("transaction_no is required")
	}
	if !r.channelAllowed(event.Channel) {
		return fmt.Errorf("payment channel is not allowed: %s", event.Channel)
	}
	if !r.providerAllowed(event.ProviderCode) {
		return fmt.Errorf("provider_code is not allowed: %s", event.ProviderCode)
	}
	if strings.TrimSpace(event.ProviderTransactionID) == "" {
		return errors.New("provider_transaction_id is required")
	}
	if strings.TrimSpace(string(event.Operation)) == "" {
		return errors.New("operation is required")
	}
	if strings.TrimSpace(event.ProviderErrorCode) == "" {
		return errors.New("provider_error_code is required")
	}
	if r.config.ProviderPayloadHashRequired && strings.TrimSpace(event.ProviderPayloadHash) == "" {
		return errors.New("provider_payload_hash is required")
	}
	if event.AmountKurus <= 0 {
		return errors.New("amount_kurus must be positive")
	}
	if strings.TrimSpace(event.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if event.RetryCount < 0 {
		return errors.New("retry_count cannot be negative")
	}
	if event.OccurredAt.IsZero() {
		return errors.New("occurred_at is required")
	}
	if event.ReceivedAt.IsZero() {
		return errors.New("received_at is required")
	}
	return nil
}

func (r *PaymentErrorRetryReversalRuntime) validateReversalRequest(req ReversalRequest) error {
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
	if strings.TrimSpace(string(req.OriginalOperation)) == "" {
		return errors.New("original_operation is required")
	}
	if req.AmountKurus <= 0 {
		return errors.New("amount_kurus must be positive")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if r.config.ReversalReasonRequired && strings.TrimSpace(req.ReversalReasonCode) == "" {
		return errors.New("reversal_reason_code is required")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *PaymentErrorRetryReversalRuntime) channelAllowed(channel PaymentChannel) bool {
	for _, allowed := range r.config.AllowedChannels {
		if allowed == channel {
			return true
		}
	}
	return false
}

func (r *PaymentErrorRetryReversalRuntime) providerAllowed(providerCode string) bool {
	for _, allowed := range r.config.AllowedProviderCodes {
		if allowed == providerCode {
			return true
		}
	}
	return false
}

func rejectedRetryDecision(event PaymentErrorEvent, code string, message string) RetryDecision {
	return RetryDecision{
		TenantID:              event.TenantID,
		CorrelationID:         event.CorrelationID,
		RequestID:             event.RequestID,
		PaymentTransactionID:  event.PaymentTransactionID,
		TransactionNo:         event.TransactionNo,
		Channel:               event.Channel,
		ProviderCode:          event.ProviderCode,
		ProviderTransactionID: event.ProviderTransactionID,
		Operation:             event.Operation,
		DecisionStatus:        DecisionNoRetry,
		ErrorClass:            ErrorClassNonRetryable,
		AuditAction:           "PAYMENT_PROVIDER_ERROR_REJECTED",
		AuditDecisionReason:   "payment provider error event rejected by validation guard",
		ErrorCode:             code,
		ErrorMessage:          message,
		DecidedAt:             time.Now().UTC(),
	}
}

func rejectedReversalDecision(req ReversalRequest, code string, message string) ReversalDecision {
	return ReversalDecision{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		PaymentTransactionID:  req.PaymentTransactionID,
		TransactionNo:         req.TransactionNo,
		Channel:               req.Channel,
		ProviderCode:          req.ProviderCode,
		ProviderTransactionID: req.ProviderTransactionID,
		DecisionStatus:        ReversalDecisionRejected,
		AuditAction:           "PAYMENT_REVERSAL_REJECTED",
		AuditDecisionReason:   "payment reversal request rejected by validation guard",
		ErrorCode:             code,
		ErrorMessage:          message,
		DecidedAt:             time.Now().UTC(),
	}
}
