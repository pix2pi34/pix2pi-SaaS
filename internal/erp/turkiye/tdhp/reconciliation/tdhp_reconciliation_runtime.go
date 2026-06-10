package reconciliation

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type ReconciliationStatus string

const (
	ReconciliationStatusMatched          ReconciliationStatus = "MATCHED"
	ReconciliationStatusDifferenceReview ReconciliationStatus = "DIFFERENCE_REVIEW"
	ReconciliationStatusRejected         ReconciliationStatus = "REJECTED"
)

type ReconciliationDecision string

const (
	DecisionMatched      ReconciliationDecision = "MATCHED"
	DecisionManualReview ReconciliationDecision = "MANUAL_REVIEW"
	DecisionRejected     ReconciliationDecision = "REJECTED"
)

type RuntimeConfig struct {
	RuntimeEnabled         bool   `json:"runtime_enabled"`
	RequireTenantScope     bool   `json:"require_tenant_scope"`
	RequireCorrelation     bool   `json:"require_correlation"`
	RequireIdempotency     bool   `json:"require_idempotency"`
	RequirePostingHash     bool   `json:"require_posting_hash"`
	RequireAuditTraceHash  bool   `json:"require_audit_trace_hash"`
	RequireLedgerReady     bool   `json:"require_ledger_ready"`
	RequireBalancedAmounts bool   `json:"require_balanced_amounts"`
	RequireResultHash      bool   `json:"require_result_hash"`
	DefaultCurrency        string `json:"default_currency"`
	ToleranceMinor         int64  `json:"tolerance_minor"`
}

type ReconciliationRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReconciliationID string `json:"reconciliation_id"`
	DocumentID       string `json:"document_id"`
	DocumentNo       string `json:"document_no"`
	VoucherID        string `json:"voucher_id"`
	VoucherNo        string `json:"voucher_no"`
	PostingID        string `json:"posting_id"`

	ExpectedDebitMinor  int64 `json:"expected_debit_minor"`
	ExpectedCreditMinor int64 `json:"expected_credit_minor"`
	ActualDebitMinor    int64 `json:"actual_debit_minor"`
	ActualCreditMinor   int64 `json:"actual_credit_minor"`

	Currency string `json:"currency"`

	PostingHash    string `json:"posting_hash"`
	AuditTraceHash string `json:"audit_trace_hash"`

	LedgerReady bool `json:"ledger_ready"`

	RequestedAt time.Time `json:"requested_at"`
}

type ReconciliationResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReconciliationID string `json:"reconciliation_id"`
	DocumentID       string `json:"document_id"`
	VoucherID        string `json:"voucher_id"`
	PostingID        string `json:"posting_id"`

	Status   ReconciliationStatus   `json:"status"`
	Decision ReconciliationDecision `json:"decision"`

	ExpectedDebitMinor  int64 `json:"expected_debit_minor"`
	ExpectedCreditMinor int64 `json:"expected_credit_minor"`
	ActualDebitMinor    int64 `json:"actual_debit_minor"`
	ActualCreditMinor   int64 `json:"actual_credit_minor"`

	DebitDifferenceMinor  int64 `json:"debit_difference_minor"`
	CreditDifferenceMinor int64 `json:"credit_difference_minor"`

	Currency string `json:"currency"`

	LedgerReady bool `json:"ledger_ready"`

	ResultHash string `json:"result_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type TDHPReconciliationRuntime struct {
	config RuntimeConfig
}

func NewTDHPReconciliationRuntime(config RuntimeConfig) (*TDHPReconciliationRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("TDHP reconciliation runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrency) == "" {
		return nil, errors.New("default_currency is required")
	}
	if config.ToleranceMinor < 0 {
		return nil, errors.New("tolerance_minor cannot be negative")
	}

	return &TDHPReconciliationRuntime{config: config}, nil
}

func (r *TDHPReconciliationRuntime) Reconcile(req ReconciliationRequest) (ReconciliationResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejected(req, "VALIDATION_FAILED", err.Error()), err
	}

	debitDiff := abs(req.ExpectedDebitMinor - req.ActualDebitMinor)
	creditDiff := abs(req.ExpectedCreditMinor - req.ActualCreditMinor)

	status := ReconciliationStatusMatched
	decision := DecisionMatched
	reasonCode := "TDHP_RECONCILIATION_MATCHED"
	reason := "TDHP posting, voucher and ledger amounts matched"

	if debitDiff > r.config.ToleranceMinor || creditDiff > r.config.ToleranceMinor {
		status = ReconciliationStatusDifferenceReview
		decision = DecisionManualReview
		reasonCode = "TDHP_RECONCILIATION_DIFFERENCE_REVIEW"
		reason = "TDHP reconciliation difference requires manual review"
	}

	result := ReconciliationResult{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		IdempotencyKey:        req.IdempotencyKey,
		ReconciliationID:      req.ReconciliationID,
		DocumentID:            req.DocumentID,
		VoucherID:             req.VoucherID,
		PostingID:             req.PostingID,
		Status:                status,
		Decision:              decision,
		ExpectedDebitMinor:    req.ExpectedDebitMinor,
		ExpectedCreditMinor:   req.ExpectedCreditMinor,
		ActualDebitMinor:      req.ActualDebitMinor,
		ActualCreditMinor:     req.ActualCreditMinor,
		DebitDifferenceMinor:  debitDiff,
		CreditDifferenceMinor: creditDiff,
		Currency:              req.Currency,
		LedgerReady:           req.LedgerReady,
		ResultHash:            buildResultHash(req, debitDiff, creditDiff, status),
		AuditAction:           "TDHP_RECONCILIATION_COMPLETED",
		AuditDecisionReason:   reason,
		CreatedAt:             time.Now().UTC(),
	}

	if r.config.RequireResultHash && strings.TrimSpace(result.ResultHash) == "" {
		err := errors.New("result_hash is required")
		return rejected(req, "RESULT_HASH_MISSING", err.Error()), err
	}

	if status != ReconciliationStatusMatched {
		return result, errors.New(reasonCode + ": " + reason)
	}

	return result, nil
}

func (r *TDHPReconciliationRuntime) validateRequest(req ReconciliationRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if r.config.RequireCorrelation && strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.RequireIdempotency && strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.ReconciliationID) == "" {
		return errors.New("reconciliation_id is required")
	}
	if strings.TrimSpace(req.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(req.VoucherID) == "" {
		return errors.New("voucher_id is required")
	}
	if strings.TrimSpace(req.PostingID) == "" {
		return errors.New("posting_id is required")
	}
	if strings.TrimSpace(req.Currency) == "" {
		return errors.New("currency is required")
	}
	if req.Currency != r.config.DefaultCurrency {
		return errors.New("currency mismatch")
	}
	if req.ExpectedDebitMinor < 0 || req.ExpectedCreditMinor < 0 || req.ActualDebitMinor < 0 || req.ActualCreditMinor < 0 {
		return errors.New("amounts cannot be negative")
	}
	if r.config.RequireBalancedAmounts && req.ExpectedDebitMinor != req.ExpectedCreditMinor {
		return errors.New("expected debit and credit must be balanced")
	}
	if r.config.RequireBalancedAmounts && req.ActualDebitMinor != req.ActualCreditMinor {
		return errors.New("actual debit and credit must be balanced")
	}
	if r.config.RequirePostingHash && strings.TrimSpace(req.PostingHash) == "" {
		return errors.New("posting_hash is required")
	}
	if r.config.RequireAuditTraceHash && strings.TrimSpace(req.AuditTraceHash) == "" {
		return errors.New("audit_trace_hash is required")
	}
	if r.config.RequireLedgerReady && !req.LedgerReady {
		return errors.New("ledger_ready is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func buildResultHash(req ReconciliationRequest, debitDiff int64, creditDiff int64, status ReconciliationStatus) string {
	return "tdhp-reconciliation:" + strings.Join([]string{
		req.TenantID,
		req.ReconciliationID,
		req.DocumentID,
		req.VoucherID,
		req.PostingID,
		req.PostingHash,
		req.AuditTraceHash,
		fmt.Sprintf("debit_diff:%d", debitDiff),
		fmt.Sprintf("credit_diff:%d", creditDiff),
		string(status),
	}, ":")
}

func rejected(req ReconciliationRequest, code string, message string) ReconciliationResult {
	return ReconciliationResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ReconciliationID:    req.ReconciliationID,
		DocumentID:          req.DocumentID,
		VoucherID:           req.VoucherID,
		PostingID:           req.PostingID,
		Status:              ReconciliationStatusRejected,
		Decision:            DecisionRejected,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "TDHP_RECONCILIATION_REJECTED",
		AuditDecisionReason: "TDHP reconciliation rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}

func abs(value int64) int64 {
	if value < 0 {
		return -value
	}
	return value
}
