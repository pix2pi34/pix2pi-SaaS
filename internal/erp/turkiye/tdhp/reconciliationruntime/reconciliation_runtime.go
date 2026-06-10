package reconciliationruntime

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	audittrace "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/audittrace"
	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

type ReconciliationStatus string

const (
	ReconciliationStatusMatched      ReconciliationStatus = "MATCHED"
	ReconciliationStatusDifference   ReconciliationStatus = "DIFFERENCE"
	ReconciliationStatusManualReview ReconciliationStatus = "MANUAL_REVIEW"
	ReconciliationStatusRejected     ReconciliationStatus = "REJECTED"
)

type ReconciliationAction string

const (
	ActionPostingVsDocument    ReconciliationAction = "POSTING_VS_DOCUMENT"
	ActionPostingVsAuditTrace  ReconciliationAction = "POSTING_VS_AUDIT_TRACE"
	ActionReversalVsPosting    ReconciliationAction = "REVERSAL_VS_POSTING"
	ActionPeriodBalance        ReconciliationAction = "PERIOD_BALANCE"
	ActionManualReviewRegister ReconciliationAction = "MANUAL_REVIEW_REGISTER"
)

type RuntimeConfig struct {
	RuntimeEnabled         bool                   `json:"runtime_enabled"`
	DefaultCurrencyCode    string                 `json:"default_currency_code"`
	IdempotencyRequired    bool                   `json:"idempotency_required"`
	AppendOnlyResult       bool                   `json:"append_only_result"`
	RequireBalancedPosting bool                   `json:"require_balanced_posting"`
	RequireAuditTrace      bool                   `json:"require_audit_trace"`
	ManualReviewEnabled    bool                   `json:"manual_review_enabled"`
	ToleranceKurus         int64                  `json:"tolerance_kurus"`
	AllowedActions         []ReconciliationAction `json:"allowed_actions"`
}

type ExpectedDocument struct {
	DocumentType string    `json:"document_type"`
	DocumentID   string    `json:"document_id"`
	DocumentNo   string    `json:"document_no"`
	DocumentDate time.Time `json:"document_date"`

	CurrencyCode string `json:"currency_code"`

	ExpectedDebitKurus  int64 `json:"expected_debit_kurus"`
	ExpectedCreditKurus int64 `json:"expected_credit_kurus"`
	ExpectedGrossKurus  int64 `json:"expected_gross_kurus"`

	ExpectedPostingID string `json:"expected_posting_id"`
	ExpectedVoucherID string `json:"expected_voucher_id"`
}

type ReconciliationRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReconciliationID string               `json:"reconciliation_id"`
	Action           ReconciliationAction `json:"action"`

	ExpectedDocument ExpectedDocument            `json:"expected_document"`
	PostingEntry     postingruntime.PostingEntry `json:"posting_entry"`
	AuditTrace       audittrace.AuditTraceRecord `json:"audit_trace"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type ReconciliationDifference struct {
	FieldName       string `json:"field_name"`
	ExpectedValue   string `json:"expected_value"`
	ActualValue     string `json:"actual_value"`
	DifferenceKurus int64  `json:"difference_kurus"`
	Severity        string `json:"severity"`
}

type ReconciliationResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReconciliationID string               `json:"reconciliation_id"`
	Action           ReconciliationAction `json:"action"`
	Status           ReconciliationStatus `json:"status"`

	DocumentID string `json:"document_id"`
	DocumentNo string `json:"document_no"`
	PostingID  string `json:"posting_id"`
	PostingNo  string `json:"posting_no"`
	TraceID    string `json:"trace_id"`

	CurrencyCode string `json:"currency_code"`

	ExpectedDebitKurus  int64 `json:"expected_debit_kurus"`
	ActualDebitKurus    int64 `json:"actual_debit_kurus"`
	ExpectedCreditKurus int64 `json:"expected_credit_kurus"`
	ActualCreditKurus   int64 `json:"actual_credit_kurus"`

	DebitDifferenceKurus  int64 `json:"debit_difference_kurus"`
	CreditDifferenceKurus int64 `json:"credit_difference_kurus"`

	Matched            bool `json:"matched"`
	ManualReviewReady  bool `json:"manual_review_ready"`
	LedgerClosureReady bool `json:"ledger_closure_ready"`

	Differences []ReconciliationDifference `json:"differences"`

	EvidenceFilePath string `json:"evidence_file_path"`
	EvidenceHash     string `json:"evidence_hash"`
	ResultHash       string `json:"result_hash"`

	AuditAction         string `json:"audit_action"`
	AuditDecisionReason string `json:"audit_decision_reason"`
	ErrorCode           string `json:"error_code"`
	ErrorMessage        string `json:"error_message"`

	CreatedAt time.Time `json:"created_at"`
}

type ReconciliationRepository interface {
	Append(result ReconciliationResult) error
	FindByReconciliationID(tenantID string, reconciliationID string) (ReconciliationResult, bool)
	FindByIdempotencyKey(tenantID string, idempotencyKey string) (ReconciliationResult, bool)
	ListByTenant(tenantID string) []ReconciliationResult
	ListByDocument(tenantID string, documentID string) []ReconciliationResult
	ListByPosting(tenantID string, postingID string) []ReconciliationResult
}

type InMemoryReconciliationRepository struct {
	mu               sync.RWMutex
	resultsByID      map[string]ReconciliationResult
	idempotencyIndex map[string]string
	order            []string
}

func NewInMemoryReconciliationRepository() *InMemoryReconciliationRepository {
	return &InMemoryReconciliationRepository{
		resultsByID:      make(map[string]ReconciliationResult),
		idempotencyIndex: make(map[string]string),
		order:            make([]string, 0),
	}
}

func (r *InMemoryReconciliationRepository) Append(result ReconciliationResult) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	resultKey := tenantReconciliationKey(result.TenantID, result.ReconciliationID)
	if _, exists := r.resultsByID[resultKey]; exists {
		return errors.New("reconciliation_id already exists")
	}

	idemKey := tenantIdempotencyKey(result.TenantID, result.IdempotencyKey)
	if existingID, exists := r.idempotencyIndex[idemKey]; exists {
		return fmt.Errorf("idempotency_key already exists for reconciliation_id %s", existingID)
	}

	r.resultsByID[resultKey] = result
	r.idempotencyIndex[idemKey] = result.ReconciliationID
	r.order = append(r.order, resultKey)

	return nil
}

func (r *InMemoryReconciliationRepository) FindByReconciliationID(tenantID string, reconciliationID string) (ReconciliationResult, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result, ok := r.resultsByID[tenantReconciliationKey(tenantID, reconciliationID)]
	return result, ok
}

func (r *InMemoryReconciliationRepository) FindByIdempotencyKey(tenantID string, idempotencyKey string) (ReconciliationResult, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	reconciliationID, ok := r.idempotencyIndex[tenantIdempotencyKey(tenantID, idempotencyKey)]
	if !ok {
		return ReconciliationResult{}, false
	}

	return r.resultsByID[tenantReconciliationKey(tenantID, reconciliationID)], true
}

func (r *InMemoryReconciliationRepository) ListByTenant(tenantID string) []ReconciliationResult {
	r.mu.RLock()
	defer r.mu.RUnlock()

	results := make([]ReconciliationResult, 0)
	for _, key := range r.order {
		result := r.resultsByID[key]
		if result.TenantID == tenantID {
			results = append(results, result)
		}
	}

	sort.SliceStable(results, func(i int, j int) bool {
		return results[i].CreatedAt.Before(results[j].CreatedAt)
	})

	return results
}

func (r *InMemoryReconciliationRepository) ListByDocument(tenantID string, documentID string) []ReconciliationResult {
	results := r.ListByTenant(tenantID)
	filtered := make([]ReconciliationResult, 0)

	for _, result := range results {
		if result.DocumentID == documentID {
			filtered = append(filtered, result)
		}
	}

	return filtered
}

func (r *InMemoryReconciliationRepository) ListByPosting(tenantID string, postingID string) []ReconciliationResult {
	results := r.ListByTenant(tenantID)
	filtered := make([]ReconciliationResult, 0)

	for _, result := range results {
		if result.PostingID == postingID {
			filtered = append(filtered, result)
		}
	}

	return filtered
}

type ReconciliationRuntime struct {
	config     RuntimeConfig
	repository ReconciliationRepository
}

func NewReconciliationRuntime(config RuntimeConfig, repository ReconciliationRepository) (*ReconciliationRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("reconciliation runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.ToleranceKurus < 0 {
		return nil, errors.New("tolerance_kurus cannot be negative")
	}
	if !config.AppendOnlyResult {
		return nil, errors.New("append_only_result must be enabled")
	}
	if len(config.AllowedActions) == 0 {
		return nil, errors.New("allowed_actions are required")
	}
	if repository == nil {
		return nil, errors.New("reconciliation repository is required")
	}

	return &ReconciliationRuntime{
		config:     config,
		repository: repository,
	}, nil
}

func (r *ReconciliationRuntime) Reconcile(req ReconciliationRequest) (ReconciliationResult, error) {
	if existing, ok := r.repository.FindByIdempotencyKey(req.TenantID, req.IdempotencyKey); ok {
		return existing, errors.New("duplicate idempotency_key")
	}

	if err := r.validateRequest(req); err != nil {
		return rejectedResult(req, "VALIDATION_FAILED", err.Error()), err
	}

	result := r.buildResult(req)

	if err := r.repository.Append(result); err != nil {
		return result, err
	}

	stored, ok := r.repository.FindByReconciliationID(result.TenantID, result.ReconciliationID)
	if !ok {
		return result, errors.New("reconciliation result was not persisted")
	}

	return stored, nil
}

func (r *ReconciliationRuntime) RegisterManualReview(req ReconciliationRequest, reason string) (ReconciliationResult, error) {
	if !r.config.ManualReviewEnabled {
		return rejectedResult(req, "MANUAL_REVIEW_DISABLED", "manual review is disabled"), errors.New("manual review is disabled")
	}
	if strings.TrimSpace(reason) == "" {
		return rejectedResult(req, "MANUAL_REVIEW_REASON_REQUIRED", "manual review reason is required"), errors.New("manual review reason is required")
	}

	req.Action = ActionManualReviewRegister
	result, err := r.Reconcile(req)
	if err != nil {
		return result, err
	}

	result.Status = ReconciliationStatusManualReview
	result.Matched = false
	result.ManualReviewReady = true
	result.LedgerClosureReady = false
	result.AuditAction = "TDHP_RECONCILIATION_MANUAL_REVIEW_REGISTERED"
	result.AuditDecisionReason = reason

	return result, nil
}

func (r *ReconciliationRuntime) FindReconciliation(tenantID string, reconciliationID string) (ReconciliationResult, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return ReconciliationResult{}, false, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(reconciliationID) == "" {
		return ReconciliationResult{}, false, errors.New("reconciliation_id is required")
	}

	result, ok := r.repository.FindByReconciliationID(tenantID, reconciliationID)
	return result, ok, nil
}

func (r *ReconciliationRuntime) ListDocumentReconciliations(tenantID string, documentID string) ([]ReconciliationResult, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(documentID) == "" {
		return nil, errors.New("document_id is required")
	}

	return r.repository.ListByDocument(tenantID, documentID), nil
}

func (r *ReconciliationRuntime) ListPostingReconciliations(tenantID string, postingID string) ([]ReconciliationResult, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(postingID) == "" {
		return nil, errors.New("posting_id is required")
	}

	return r.repository.ListByPosting(tenantID, postingID), nil
}

func (r *ReconciliationRuntime) validateRequest(req ReconciliationRequest) error {
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
	if !r.actionAllowed(req.Action) {
		return fmt.Errorf("reconciliation action is not allowed: %s", req.Action)
	}
	if err := r.validateExpectedDocument(req.ExpectedDocument); err != nil {
		return err
	}
	if err := r.validatePosting(req.PostingEntry); err != nil {
		return err
	}
	if r.config.RequireAuditTrace && req.Action == ActionPostingVsAuditTrace {
		if err := r.validateAuditTrace(req.AuditTrace); err != nil {
			return err
		}
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ReconciliationRuntime) validateExpectedDocument(doc ExpectedDocument) error {
	if strings.TrimSpace(doc.DocumentID) == "" {
		return errors.New("expected document_id is required")
	}
	if strings.TrimSpace(doc.DocumentNo) == "" {
		return errors.New("expected document_no is required")
	}
	if doc.DocumentDate.IsZero() {
		return errors.New("expected document_date is required")
	}
	if strings.TrimSpace(doc.CurrencyCode) == "" {
		return errors.New("expected currency_code is required")
	}
	if doc.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("expected currency_code mismatch")
	}
	if doc.ExpectedDebitKurus < 0 {
		return errors.New("expected_debit_kurus cannot be negative")
	}
	if doc.ExpectedCreditKurus < 0 {
		return errors.New("expected_credit_kurus cannot be negative")
	}
	if doc.ExpectedGrossKurus < 0 {
		return errors.New("expected_gross_kurus cannot be negative")
	}
	if strings.TrimSpace(doc.ExpectedPostingID) == "" {
		return errors.New("expected_posting_id is required")
	}
	if strings.TrimSpace(doc.ExpectedVoucherID) == "" {
		return errors.New("expected_voucher_id is required")
	}
	return nil
}

func (r *ReconciliationRuntime) validatePosting(entry postingruntime.PostingEntry) error {
	if strings.TrimSpace(entry.TenantID) == "" {
		return errors.New("posting tenant_id is required")
	}
	if strings.TrimSpace(entry.PostingID) == "" {
		return errors.New("posting_id is required")
	}
	if strings.TrimSpace(entry.VoucherID) == "" {
		return errors.New("posting voucher_id is required")
	}
	if strings.TrimSpace(entry.DocumentID) == "" {
		return errors.New("posting document_id is required")
	}
	if strings.TrimSpace(entry.DocumentNo) == "" {
		return errors.New("posting document_no is required")
	}
	if strings.TrimSpace(entry.CurrencyCode) == "" {
		return errors.New("posting currency_code is required")
	}
	if entry.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("posting currency_code mismatch")
	}
	if r.config.RequireBalancedPosting && !entry.Balanced {
		return errors.New("posting balanced is required")
	}
	if entry.TotalDebitKurus < 0 {
		return errors.New("posting total_debit_kurus cannot be negative")
	}
	if entry.TotalCreditKurus < 0 {
		return errors.New("posting total_credit_kurus cannot be negative")
	}
	if entry.TotalDebitKurus != entry.TotalCreditKurus {
		return errors.New("posting debit and credit totals must match")
	}
	if len(entry.Lines) == 0 {
		return errors.New("posting lines are required")
	}
	if strings.TrimSpace(entry.AuditTraceID) == "" {
		return errors.New("posting audit_trace_id is required")
	}
	if strings.TrimSpace(entry.PostingHash) == "" {
		return errors.New("posting_hash is required")
	}
	return nil
}

func (r *ReconciliationRuntime) validateAuditTrace(trace audittrace.AuditTraceRecord) error {
	if strings.TrimSpace(trace.TraceID) == "" {
		return errors.New("audit trace_id is required")
	}
	if strings.TrimSpace(trace.DocumentID) == "" {
		return errors.New("audit trace document_id is required")
	}
	if strings.TrimSpace(trace.PostingID) == "" {
		return errors.New("audit trace posting_id is required")
	}
	if strings.TrimSpace(trace.EvidenceHash) == "" {
		return errors.New("audit trace evidence_hash is required")
	}
	if strings.TrimSpace(trace.PostingHash) == "" {
		return errors.New("audit trace posting_hash is required")
	}
	return nil
}

func (r *ReconciliationRuntime) buildResult(req ReconciliationRequest) ReconciliationResult {
	differences := make([]ReconciliationDifference, 0)

	debitDiff := abs(req.ExpectedDocument.ExpectedDebitKurus - req.PostingEntry.TotalDebitKurus)
	creditDiff := abs(req.ExpectedDocument.ExpectedCreditKurus - req.PostingEntry.TotalCreditKurus)

	if debitDiff > r.config.ToleranceKurus {
		differences = append(differences, ReconciliationDifference{
			FieldName:       "total_debit_kurus",
			ExpectedValue:   fmt.Sprintf("%d", req.ExpectedDocument.ExpectedDebitKurus),
			ActualValue:     fmt.Sprintf("%d", req.PostingEntry.TotalDebitKurus),
			DifferenceKurus: debitDiff,
			Severity:        "BLOCKING",
		})
	}

	if creditDiff > r.config.ToleranceKurus {
		differences = append(differences, ReconciliationDifference{
			FieldName:       "total_credit_kurus",
			ExpectedValue:   fmt.Sprintf("%d", req.ExpectedDocument.ExpectedCreditKurus),
			ActualValue:     fmt.Sprintf("%d", req.PostingEntry.TotalCreditKurus),
			DifferenceKurus: creditDiff,
			Severity:        "BLOCKING",
		})
	}

	if req.ExpectedDocument.DocumentID != req.PostingEntry.DocumentID {
		differences = append(differences, ReconciliationDifference{
			FieldName:     "document_id",
			ExpectedValue: req.ExpectedDocument.DocumentID,
			ActualValue:   req.PostingEntry.DocumentID,
			Severity:      "BLOCKING",
		})
	}

	if req.ExpectedDocument.ExpectedPostingID != req.PostingEntry.PostingID {
		differences = append(differences, ReconciliationDifference{
			FieldName:     "posting_id",
			ExpectedValue: req.ExpectedDocument.ExpectedPostingID,
			ActualValue:   req.PostingEntry.PostingID,
			Severity:      "BLOCKING",
		})
	}

	if req.ExpectedDocument.ExpectedVoucherID != req.PostingEntry.VoucherID {
		differences = append(differences, ReconciliationDifference{
			FieldName:     "voucher_id",
			ExpectedValue: req.ExpectedDocument.ExpectedVoucherID,
			ActualValue:   req.PostingEntry.VoucherID,
			Severity:      "BLOCKING",
		})
	}

	if req.Action == ActionPostingVsAuditTrace {
		if req.AuditTrace.PostingID != req.PostingEntry.PostingID {
			differences = append(differences, ReconciliationDifference{
				FieldName:     "audit_trace.posting_id",
				ExpectedValue: req.PostingEntry.PostingID,
				ActualValue:   req.AuditTrace.PostingID,
				Severity:      "BLOCKING",
			})
		}
		if req.AuditTrace.PostingHash != req.PostingEntry.PostingHash {
			differences = append(differences, ReconciliationDifference{
				FieldName:     "audit_trace.posting_hash",
				ExpectedValue: req.PostingEntry.PostingHash,
				ActualValue:   req.AuditTrace.PostingHash,
				Severity:      "BLOCKING",
			})
		}
	}

	status := ReconciliationStatusMatched
	matched := true
	manualReviewReady := false
	ledgerClosureReady := true
	auditAction := "TDHP_RECONCILIATION_MATCHED"
	decisionReason := "posting matches expected document and audit trace within tolerance"

	if len(differences) > 0 {
		status = ReconciliationStatusDifference
		matched = false
		manualReviewReady = r.config.ManualReviewEnabled
		ledgerClosureReady = false
		auditAction = "TDHP_RECONCILIATION_DIFFERENCE"
		decisionReason = "reconciliation differences detected"
	}

	result := ReconciliationResult{
		TenantID:              req.TenantID,
		CorrelationID:         req.CorrelationID,
		RequestID:             req.RequestID,
		IdempotencyKey:        req.IdempotencyKey,
		ReconciliationID:      req.ReconciliationID,
		Action:                req.Action,
		Status:                status,
		DocumentID:            req.ExpectedDocument.DocumentID,
		DocumentNo:            req.ExpectedDocument.DocumentNo,
		PostingID:             req.PostingEntry.PostingID,
		PostingNo:             req.PostingEntry.PostingNo,
		TraceID:               req.AuditTrace.TraceID,
		CurrencyCode:          req.ExpectedDocument.CurrencyCode,
		ExpectedDebitKurus:    req.ExpectedDocument.ExpectedDebitKurus,
		ActualDebitKurus:      req.PostingEntry.TotalDebitKurus,
		ExpectedCreditKurus:   req.ExpectedDocument.ExpectedCreditKurus,
		ActualCreditKurus:     req.PostingEntry.TotalCreditKurus,
		DebitDifferenceKurus:  debitDiff,
		CreditDifferenceKurus: creditDiff,
		Matched:               matched,
		ManualReviewReady:     manualReviewReady,
		LedgerClosureReady:    ledgerClosureReady,
		Differences:           differences,
		EvidenceFilePath:      fmt.Sprintf("docs/faz3/evidence/%s.md", req.ReconciliationID),
		EvidenceHash:          fmt.Sprintf("sha256:%s:evidence", req.ReconciliationID),
		ResultHash:            buildResultHash(req.TenantID, req.ReconciliationID, debitDiff, creditDiff, len(differences)),
		AuditAction:           auditAction,
		AuditDecisionReason:   decisionReason,
		CreatedAt:             time.Now().UTC(),
	}

	return result
}

func (r *ReconciliationRuntime) actionAllowed(action ReconciliationAction) bool {
	for _, allowed := range r.config.AllowedActions {
		if allowed == action {
			return true
		}
	}
	return false
}

func tenantReconciliationKey(tenantID string, reconciliationID string) string {
	return tenantID + "::" + reconciliationID
}

func tenantIdempotencyKey(tenantID string, idempotencyKey string) string {
	return tenantID + "::" + idempotencyKey
}

func buildResultHash(tenantID string, reconciliationID string, debitDiff int64, creditDiff int64, diffCount int) string {
	return fmt.Sprintf("reconciliation:%s:%s:%d:%d:%d", tenantID, reconciliationID, debitDiff, creditDiff, diffCount)
}

func rejectedResult(req ReconciliationRequest, code string, message string) ReconciliationResult {
	return ReconciliationResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ReconciliationID:    req.ReconciliationID,
		Action:              req.Action,
		Status:              ReconciliationStatusRejected,
		DocumentID:          req.ExpectedDocument.DocumentID,
		DocumentNo:          req.ExpectedDocument.DocumentNo,
		PostingID:           req.PostingEntry.PostingID,
		PostingNo:           req.PostingEntry.PostingNo,
		TraceID:             req.AuditTrace.TraceID,
		CurrencyCode:        req.ExpectedDocument.CurrencyCode,
		Matched:             false,
		ManualReviewReady:   false,
		LedgerClosureReady:  false,
		AuditAction:         "TDHP_RECONCILIATION_REJECTED",
		AuditDecisionReason: "reconciliation rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		CreatedAt:           time.Now().UTC(),
	}
}

func abs(v int64) int64 {
	if v < 0 {
		return -v
	}
	return v
}
