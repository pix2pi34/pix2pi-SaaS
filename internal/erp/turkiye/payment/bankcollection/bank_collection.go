package bankcollection

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

type CollectionOperation string

const (
	OperationRegisterTransfer  CollectionOperation = "REGISTER_BANK_TRANSFER"
	OperationMatchStatement    CollectionOperation = "MATCH_BANK_STATEMENT"
	OperationReconcile         CollectionOperation = "RECONCILE_COLLECTION"
	OperationBuildSettlement   CollectionOperation = "BUILD_SETTLEMENT"
	OperationReverseCollection CollectionOperation = "REVERSE_COLLECTION"
	OperationStatusCheck       CollectionOperation = "STATUS_CHECK"
)

type CollectionDecisionStatus string

const (
	DecisionAccepted CollectionDecisionStatus = "ACCEPTED"
	DecisionRejected CollectionDecisionStatus = "REJECTED"
	DecisionMatched  CollectionDecisionStatus = "MATCHED"
	DecisionQueued   CollectionDecisionStatus = "QUEUED"
	DecisionIgnored  CollectionDecisionStatus = "IGNORED"
)

type CollectionStatus string

const (
	CollectionRegistered CollectionStatus = "REGISTERED"
	CollectionMatched    CollectionStatus = "MATCHED"
	CollectionReconciled CollectionStatus = "RECONCILED"
	CollectionSettled    CollectionStatus = "SETTLED"
	CollectionReversed   CollectionStatus = "REVERSED"
	CollectionFailed     CollectionStatus = "FAILED"
)

type RuntimeConfig struct {
	Mode                         RuntimeMode `json:"mode"`
	ProviderBankCode             string      `json:"provider_bank_code"`
	RealBankGateOpen             bool        `json:"real_bank_gate_open"`
	ProductionApproved           bool        `json:"production_approved"`
	EndpointBaseURL              string      `json:"endpoint_base_url"`
	CredentialRef                string      `json:"credential_ref"`
	RequestTimeoutMS             int         `json:"request_timeout_ms"`
	MaxRetryCount                int         `json:"max_retry_count"`
	IdempotencyRequired          bool        `json:"idempotency_required"`
	StatementHashRequired        bool        `json:"statement_hash_required"`
	ReconciliationToleranceKurus int64       `json:"reconciliation_tolerance_kurus"`
}

type CollectionRequest struct {
	TenantID       string              `json:"tenant_id"`
	CorrelationID  string              `json:"correlation_id"`
	RequestID      string              `json:"request_id"`
	IdempotencyKey string              `json:"idempotency_key"`
	Operation      CollectionOperation `json:"operation"`

	PaymentTransactionID string `json:"payment_transaction_id"`
	CollectionNo         string `json:"collection_no"`

	BankAccountID    string `json:"bank_account_id"`
	ProviderBankCode string `json:"provider_bank_code"`
	IBAN             string `json:"iban"`

	BankReferenceNo      string `json:"bank_reference_no"`
	StatementLineID      string `json:"statement_line_id"`
	StatementPayloadHash string `json:"statement_payload_hash"`

	PayerPartyID string `json:"payer_party_id"`
	PayerTitle   string `json:"payer_title"`
	PayerTaxNo   string `json:"payer_tax_no"`
	Description  string `json:"description"`

	SourceDocumentType string `json:"source_document_type"`
	SourceDocumentID   string `json:"source_document_id"`
	SourceDocumentNo   string `json:"source_document_no"`

	AmountKurus  int64  `json:"amount_kurus"`
	CurrencyCode string `json:"currency_code"`

	ExpectedAmountKurus int64 `json:"expected_amount_kurus"`
	ActualAmountKurus   int64 `json:"actual_amount_kurus"`

	ValueDate   time.Time `json:"value_date"`
	ReceivedAt  time.Time `json:"received_at"`
	RequestedAt time.Time `json:"requested_at"`

	ReverseReasonCode string `json:"reverse_reason_code"`
	ReverseReasonText string `json:"reverse_reason_text"`
}

type CollectionResponse struct {
	TenantID         string                   `json:"tenant_id"`
	CorrelationID    string                   `json:"correlation_id"`
	RequestID        string                   `json:"request_id"`
	Operation        CollectionOperation      `json:"operation"`
	DecisionStatus   CollectionDecisionStatus `json:"decision_status"`
	CollectionStatus CollectionStatus         `json:"collection_status"`

	ProviderBankCode string `json:"provider_bank_code"`
	BankReferenceNo  string `json:"bank_reference_no"`
	ReconciliationID string `json:"reconciliation_id"`
	SettlementID     string `json:"settlement_id"`

	MatchedAmountKurus    int64 `json:"matched_amount_kurus"`
	DifferenceAmountKurus int64 `json:"difference_amount_kurus"`

	Retryable           bool      `json:"retryable"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	RespondedAt         time.Time `json:"responded_at"`
}

type BankCollectionRuntime struct {
	config RuntimeConfig
}

func NewBankCollectionRuntime(config RuntimeConfig) (*BankCollectionRuntime, error) {
	if config.Mode == "" {
		return nil, errors.New("runtime mode is required")
	}
	if strings.TrimSpace(config.ProviderBankCode) == "" {
		return nil, errors.New("provider_bank_code is required")
	}
	if config.RequestTimeoutMS <= 0 {
		return nil, errors.New("request_timeout_ms must be positive")
	}
	if config.MaxRetryCount < 0 {
		return nil, errors.New("max_retry_count cannot be negative")
	}
	if config.ReconciliationToleranceKurus < 0 {
		return nil, errors.New("reconciliation_tolerance_kurus cannot be negative")
	}
	if config.Mode == RuntimeModeProduction && (!config.RealBankGateOpen || !config.ProductionApproved) {
		return nil, errors.New("production real bank access is closed until approvals and real bank gate are open")
	}

	return &BankCollectionRuntime{config: config}, nil
}

func (r *BankCollectionRuntime) RegisterBankTransfer(req CollectionRequest) (CollectionResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejectedResponse(r.config, req, OperationRegisterTransfer, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateBankReference(req); err != nil {
		return rejectedResponse(r.config, req, OperationRegisterTransfer, "BANK_REFERENCE_VALIDATION_FAILED", err.Error()), err
	}

	return r.acceptedResponse(req, OperationRegisterTransfer, DecisionAccepted, CollectionRegistered, "bank transfer registered in controlled runtime"), nil
}

func (r *BankCollectionRuntime) MatchBankStatement(req CollectionRequest) (CollectionResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejectedResponse(r.config, req, OperationMatchStatement, "VALIDATION_FAILED", err.Error()), err
	}
	if err := r.validateBankReference(req); err != nil {
		return rejectedResponse(r.config, req, OperationMatchStatement, "BANK_REFERENCE_VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.StatementLineID) == "" {
		return rejectedResponse(r.config, req, OperationMatchStatement, "STATEMENT_LINE_ID_REQUIRED", "statement_line_id is required"), errors.New("statement_line_id is required")
	}
	if r.config.StatementHashRequired && strings.TrimSpace(req.StatementPayloadHash) == "" {
		return rejectedResponse(r.config, req, OperationMatchStatement, "STATEMENT_PAYLOAD_HASH_REQUIRED", "statement_payload_hash is required"), errors.New("statement_payload_hash is required")
	}

	return r.acceptedResponse(req, OperationMatchStatement, DecisionMatched, CollectionMatched, "bank statement matched with collection transaction"), nil
}

func (r *BankCollectionRuntime) ReconcileCollection(req CollectionRequest) (CollectionResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejectedResponse(r.config, req, OperationReconcile, "VALIDATION_FAILED", err.Error()), err
	}
	if req.ExpectedAmountKurus <= 0 {
		return rejectedResponse(r.config, req, OperationReconcile, "EXPECTED_AMOUNT_REQUIRED", "expected_amount_kurus must be positive"), errors.New("expected_amount_kurus must be positive")
	}
	if req.ActualAmountKurus <= 0 {
		return rejectedResponse(r.config, req, OperationReconcile, "ACTUAL_AMOUNT_REQUIRED", "actual_amount_kurus must be positive"), errors.New("actual_amount_kurus must be positive")
	}

	diff := absoluteDiff(req.ExpectedAmountKurus, req.ActualAmountKurus)
	if diff > r.config.ReconciliationToleranceKurus {
		resp := rejectedResponse(r.config, req, OperationReconcile, "RECONCILIATION_DIFFERENCE_EXCEEDED", "reconciliation difference exceeds tolerance")
		resp.DifferenceAmountKurus = diff
		return resp, errors.New("reconciliation difference exceeds tolerance")
	}

	resp := r.acceptedResponse(req, OperationReconcile, DecisionAccepted, CollectionReconciled, "collection reconciled inside tolerance")
	resp.DifferenceAmountKurus = diff
	resp.ReconciliationID = fmt.Sprintf("RECON-%s-%s", r.config.ProviderBankCode, req.PaymentTransactionID)
	resp.MatchedAmountKurus = req.ActualAmountKurus
	return resp, nil
}

func (r *BankCollectionRuntime) BuildSettlement(req CollectionRequest) (CollectionResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejectedResponse(r.config, req, OperationBuildSettlement, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.BankReferenceNo) == "" {
		return rejectedResponse(r.config, req, OperationBuildSettlement, "BANK_REFERENCE_NO_REQUIRED", "bank_reference_no is required"), errors.New("bank_reference_no is required")
	}

	resp := r.acceptedResponse(req, OperationBuildSettlement, DecisionQueued, CollectionSettled, "settlement package built for bank collection")
	resp.SettlementID = fmt.Sprintf("SETTLE-%s-%s", r.config.ProviderBankCode, req.PaymentTransactionID)
	return resp, nil
}

func (r *BankCollectionRuntime) ReverseCollection(req CollectionRequest) (CollectionResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejectedResponse(r.config, req, OperationReverseCollection, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.BankReferenceNo) == "" {
		return rejectedResponse(r.config, req, OperationReverseCollection, "BANK_REFERENCE_NO_REQUIRED", "bank_reference_no is required"), errors.New("bank_reference_no is required")
	}
	if strings.TrimSpace(req.ReverseReasonCode) == "" {
		return rejectedResponse(r.config, req, OperationReverseCollection, "REVERSE_REASON_REQUIRED", "reverse_reason_code is required"), errors.New("reverse_reason_code is required")
	}

	return r.acceptedResponse(req, OperationReverseCollection, DecisionAccepted, CollectionReversed, "collection reversal accepted"), nil
}

func (r *BankCollectionRuntime) CheckStatus(req CollectionRequest) (CollectionResponse, error) {
	if err := r.validateBaseRequest(req); err != nil {
		return rejectedResponse(r.config, req, OperationStatusCheck, "VALIDATION_FAILED", err.Error()), err
	}
	if strings.TrimSpace(req.BankReferenceNo) == "" {
		return rejectedResponse(r.config, req, OperationStatusCheck, "BANK_REFERENCE_NO_REQUIRED", "bank_reference_no is required"), errors.New("bank_reference_no is required")
	}

	return r.acceptedResponse(req, OperationStatusCheck, DecisionAccepted, CollectionMatched, "bank collection status checked"), nil
}

func (r *BankCollectionRuntime) validateBaseRequest(req CollectionRequest) error {
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
	if strings.TrimSpace(req.CollectionNo) == "" {
		return errors.New("collection_no is required")
	}
	if strings.TrimSpace(req.BankAccountID) == "" {
		return errors.New("bank_account_id is required")
	}
	if strings.TrimSpace(req.ProviderBankCode) == "" {
		return errors.New("provider_bank_code is required")
	}
	if req.ProviderBankCode != r.config.ProviderBankCode {
		return errors.New("provider_bank_code mismatch")
	}
	if req.AmountKurus <= 0 {
		return errors.New("amount_kurus must be positive")
	}
	if strings.TrimSpace(req.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if req.ValueDate.IsZero() {
		return errors.New("value_date is required")
	}
	if req.ReceivedAt.IsZero() {
		return errors.New("received_at is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *BankCollectionRuntime) validateBankReference(req CollectionRequest) error {
	if strings.TrimSpace(req.BankReferenceNo) == "" {
		return errors.New("bank_reference_no is required")
	}
	if strings.TrimSpace(req.PayerTitle) == "" {
		return errors.New("payer_title is required")
	}
	if strings.TrimSpace(req.Description) == "" {
		return errors.New("description is required")
	}
	return nil
}

func (r *BankCollectionRuntime) acceptedResponse(req CollectionRequest, op CollectionOperation, decision CollectionDecisionStatus, status CollectionStatus, reason string) CollectionResponse {
	now := time.Now().UTC()

	return CollectionResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      decision,
		CollectionStatus:    status,
		ProviderBankCode:    r.config.ProviderBankCode,
		BankReferenceNo:     req.BankReferenceNo,
		MatchedAmountKurus:  req.AmountKurus,
		Retryable:           false,
		AuditDecisionReason: reason,
		RespondedAt:         now,
	}
}

func rejectedResponse(config RuntimeConfig, req CollectionRequest, op CollectionOperation, code string, message string) CollectionResponse {
	return CollectionResponse{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		Operation:           op,
		DecisionStatus:      DecisionRejected,
		CollectionStatus:    CollectionFailed,
		ProviderBankCode:    config.ProviderBankCode,
		BankReferenceNo:     req.BankReferenceNo,
		Retryable:           false,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditDecisionReason: "bank collection request rejected by runtime validation guard",
		RespondedAt:         time.Now().UTC(),
	}
}

func absoluteDiff(a int64, b int64) int64 {
	if a > b {
		return a - b
	}
	return b - a
}
