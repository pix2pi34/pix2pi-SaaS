package postingruntime

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	voucherpipeline "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/voucherpipeline"
)

type PostingStatus string

const (
	PostingStatusPrepared PostingStatus = "PREPARED"
	PostingStatusPosted   PostingStatus = "POSTED"
	PostingStatusRejected PostingStatus = "REJECTED"
	PostingStatusReversed PostingStatus = "REVERSED"
)

type PostingDecision string

const (
	DecisionPrepared PostingDecision = "PREPARED"
	DecisionPosted   PostingDecision = "POSTED"
	DecisionRejected PostingDecision = "REJECTED"
	DecisionReversed PostingDecision = "REVERSED"
)

type PostingSource string

const (
	SourceVoucherPipeline PostingSource = "REAL_VOUCHER_PIPELINE"
	SourceSalesRuntime    PostingSource = "SALES_RUNTIME"
	SourcePurchaseRuntime PostingSource = "PURCHASE_RUNTIME"
	SourcePaymentRuntime  PostingSource = "PAYMENT_RUNTIME"
	SourceManualRuntime   PostingSource = "MANUAL_RUNTIME"
)

type RuntimeConfig struct {
	RuntimeEnabled        bool            `json:"runtime_enabled"`
	DefaultCurrencyCode   string          `json:"default_currency_code"`
	IdempotencyRequired   bool            `json:"idempotency_required"`
	RequireVoucherReady   bool            `json:"require_voucher_ready"`
	RequireBalanced       bool            `json:"require_balanced"`
	RequireAuditTrace     bool            `json:"require_audit_trace"`
	AppendOnlyLedger      bool            `json:"append_only_ledger"`
	AllowReversal         bool            `json:"allow_reversal"`
	AllowedPostingSources []PostingSource `json:"allowed_posting_sources"`
}

type PostingRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	PostingID     string        `json:"posting_id"`
	PostingSource PostingSource `json:"posting_source"`

	Voucher voucherpipeline.Voucher `json:"voucher"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type PostingLine struct {
	PostingLineID string `json:"posting_line_id"`
	LineNo        int    `json:"line_no"`

	AccountCode string `json:"account_code"`
	AccountName string `json:"account_name"`

	DebitAmountKurus  int64 `json:"debit_amount_kurus"`
	CreditAmountKurus int64 `json:"credit_amount_kurus"`

	DocumentID string `json:"document_id"`
	DocumentNo string `json:"document_no"`
	PartyID    string `json:"party_id"`
	PartyTaxNo string `json:"party_tax_no"`

	TaxTraceCode string `json:"tax_trace_code"`
	Description  string `json:"description"`
}

type PostingEntry struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	PostingID     string        `json:"posting_id"`
	PostingNo     string        `json:"posting_no"`
	PostingSource PostingSource `json:"posting_source"`
	Status        PostingStatus `json:"status"`

	VoucherID string `json:"voucher_id"`
	VoucherNo string `json:"voucher_no"`

	DocumentType string    `json:"document_type"`
	DocumentID   string    `json:"document_id"`
	DocumentNo   string    `json:"document_no"`
	DocumentDate time.Time `json:"document_date"`

	CurrencyCode string `json:"currency_code"`

	Lines []PostingLine `json:"lines"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`
	Balanced         bool  `json:"balanced"`

	PostingReady bool `json:"posting_ready"`
	LedgerReady  bool `json:"ledger_ready"`

	AuditTraceID string `json:"audit_trace_id"`
	PostingHash  string `json:"posting_hash"`

	AuditAction         string `json:"audit_action"`
	AuditDecisionReason string `json:"audit_decision_reason"`
	ErrorCode           string `json:"error_code"`
	ErrorMessage        string `json:"error_message"`

	PostedBy  string    `json:"posted_by"`
	PostedAt  time.Time `json:"posted_at"`
	CreatedAt time.Time `json:"created_at"`
}

type ReversalRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ReversalID string `json:"reversal_id"`

	OriginalPosting PostingEntry `json:"original_posting"`

	ReasonCode string `json:"reason_code"`
	ReasonText string `json:"reason_text"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type PostingRepository interface {
	Append(entry PostingEntry) error
	FindByPostingID(tenantID string, postingID string) (PostingEntry, bool)
	FindByIdempotencyKey(tenantID string, idempotencyKey string) (PostingEntry, bool)
	ListByTenant(tenantID string) []PostingEntry
	ListByDocument(tenantID string, documentID string) []PostingEntry
}

type InMemoryPostingRepository struct {
	mu               sync.RWMutex
	entriesByID      map[string]PostingEntry
	idempotencyIndex map[string]string
	order            []string
}

func NewInMemoryPostingRepository() *InMemoryPostingRepository {
	return &InMemoryPostingRepository{
		entriesByID:      make(map[string]PostingEntry),
		idempotencyIndex: make(map[string]string),
		order:            make([]string, 0),
	}
}

func (r *InMemoryPostingRepository) Append(entry PostingEntry) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	postingKey := tenantPostingKey(entry.TenantID, entry.PostingID)
	if _, exists := r.entriesByID[postingKey]; exists {
		return errors.New("posting_id already exists")
	}

	idemKey := tenantIdempotencyKey(entry.TenantID, entry.IdempotencyKey)
	if existingPostingID, exists := r.idempotencyIndex[idemKey]; exists {
		return fmt.Errorf("idempotency_key already exists for posting_id %s", existingPostingID)
	}

	r.entriesByID[postingKey] = entry
	r.idempotencyIndex[idemKey] = entry.PostingID
	r.order = append(r.order, postingKey)

	return nil
}

func (r *InMemoryPostingRepository) FindByPostingID(tenantID string, postingID string) (PostingEntry, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	entry, ok := r.entriesByID[tenantPostingKey(tenantID, postingID)]
	return entry, ok
}

func (r *InMemoryPostingRepository) FindByIdempotencyKey(tenantID string, idempotencyKey string) (PostingEntry, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	postingID, ok := r.idempotencyIndex[tenantIdempotencyKey(tenantID, idempotencyKey)]
	if !ok {
		return PostingEntry{}, false
	}

	return r.entriesByID[tenantPostingKey(tenantID, postingID)], true
}

func (r *InMemoryPostingRepository) ListByTenant(tenantID string) []PostingEntry {
	r.mu.RLock()
	defer r.mu.RUnlock()

	entries := make([]PostingEntry, 0)
	for _, key := range r.order {
		entry := r.entriesByID[key]
		if entry.TenantID == tenantID {
			entries = append(entries, entry)
		}
	}

	return entries
}

func (r *InMemoryPostingRepository) ListByDocument(tenantID string, documentID string) []PostingEntry {
	entries := r.ListByTenant(tenantID)
	filtered := make([]PostingEntry, 0)

	for _, entry := range entries {
		if entry.DocumentID == documentID {
			filtered = append(filtered, entry)
		}
	}

	return filtered
}

type DocumentPostingRuntime struct {
	config     RuntimeConfig
	repository PostingRepository
}

func NewDocumentPostingRuntime(config RuntimeConfig, repository PostingRepository) (*DocumentPostingRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("document based posting runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if !config.AppendOnlyLedger {
		return nil, errors.New("append_only_ledger must be enabled")
	}
	if len(config.AllowedPostingSources) == 0 {
		return nil, errors.New("allowed_posting_sources are required")
	}
	if repository == nil {
		return nil, errors.New("posting repository is required")
	}

	return &DocumentPostingRuntime{
		config:     config,
		repository: repository,
	}, nil
}

func (r *DocumentPostingRuntime) PreparePosting(req PostingRequest) (PostingEntry, error) {
	if err := r.validatePostingRequest(req); err != nil {
		return rejectedPosting(req, "VALIDATION_FAILED", err.Error()), err
	}

	entry := r.buildPostingEntry(req, PostingStatusPrepared)
	entry.AuditAction = "DOCUMENT_BASED_POSTING_PREPARED"
	entry.AuditDecisionReason = "voucher validated and posting entry prepared"
	entry.LedgerReady = true

	return entry, nil
}

func (r *DocumentPostingRuntime) PostDocument(req PostingRequest) (PostingEntry, error) {
	if existing, ok := r.repository.FindByIdempotencyKey(req.TenantID, req.IdempotencyKey); ok {
		return existing, errors.New("duplicate idempotency_key")
	}

	if err := r.validatePostingRequest(req); err != nil {
		return rejectedPosting(req, "VALIDATION_FAILED", err.Error()), err
	}

	entry := r.buildPostingEntry(req, PostingStatusPosted)
	entry.AuditAction = "DOCUMENT_BASED_POSTING_POSTED"
	entry.AuditDecisionReason = "voucher posted to append-only ledger repository"
	entry.LedgerReady = true
	entry.PostedBy = req.RequestedBy
	entry.PostedAt = time.Now().UTC()

	if err := r.repository.Append(entry); err != nil {
		return entry, err
	}

	stored, ok := r.repository.FindByPostingID(entry.TenantID, entry.PostingID)
	if !ok {
		return entry, errors.New("posting entry was not persisted")
	}

	return stored, nil
}

func (r *DocumentPostingRuntime) ReversePosting(req ReversalRequest) (PostingEntry, error) {
	if !r.config.AllowReversal {
		return rejectedReversal(req, "REVERSAL_DISABLED", "posting reversal is disabled"), errors.New("posting reversal is disabled")
	}
	if existing, ok := r.repository.FindByIdempotencyKey(req.TenantID, req.IdempotencyKey); ok {
		return existing, errors.New("duplicate idempotency_key")
	}
	if err := r.validateReversalRequest(req); err != nil {
		return rejectedReversal(req, "VALIDATION_FAILED", err.Error()), err
	}

	original := req.OriginalPosting
	lines := make([]PostingLine, 0, len(original.Lines))

	for _, originalLine := range original.Lines {
		reversed := originalLine
		reversed.PostingLineID = fmt.Sprintf("%s:reverse:%d", req.ReversalID, originalLine.LineNo)
		reversed.DebitAmountKurus = originalLine.CreditAmountKurus
		reversed.CreditAmountKurus = originalLine.DebitAmountKurus
		reversed.Description = "Ters kayıt: " + originalLine.Description
		lines = append(lines, reversed)
	}

	entry := PostingEntry{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		PostingID:           req.ReversalID,
		PostingNo:           fmt.Sprintf("REV-%s", original.PostingNo),
		PostingSource:       original.PostingSource,
		Status:              PostingStatusReversed,
		VoucherID:           original.VoucherID,
		VoucherNo:           original.VoucherNo,
		DocumentType:        original.DocumentType,
		DocumentID:          original.DocumentID,
		DocumentNo:          original.DocumentNo,
		DocumentDate:        original.DocumentDate,
		CurrencyCode:        original.CurrencyCode,
		Lines:               lines,
		TotalDebitKurus:     original.TotalCreditKurus,
		TotalCreditKurus:    original.TotalDebitKurus,
		Balanced:            original.TotalCreditKurus == original.TotalDebitKurus,
		PostingReady:        true,
		LedgerReady:         true,
		AuditTraceID:        fmt.Sprintf("posting-reversal-audit:%s:%s", req.TenantID, req.ReversalID),
		PostingHash:         buildPostingHash(req.TenantID, req.ReversalID, original.TotalCreditKurus, original.TotalDebitKurus, len(lines)),
		AuditAction:         "DOCUMENT_BASED_POSTING_REVERSED",
		AuditDecisionReason: "posting reversal generated with mirrored debit/credit lines",
		PostedBy:            req.RequestedBy,
		PostedAt:            time.Now().UTC(),
		CreatedAt:           time.Now().UTC(),
	}

	if !entry.Balanced {
		entry.Status = PostingStatusRejected
		entry.ErrorCode = "REVERSAL_NOT_BALANCED"
		entry.ErrorMessage = "reversal debit and credit totals are not equal"
		return entry, errors.New("reversal debit and credit totals are not equal")
	}

	if err := r.repository.Append(entry); err != nil {
		return entry, err
	}

	stored, ok := r.repository.FindByPostingID(entry.TenantID, entry.PostingID)
	if !ok {
		return entry, errors.New("reversal entry was not persisted")
	}

	return stored, nil
}

func (r *DocumentPostingRuntime) FindPosting(tenantID string, postingID string) (PostingEntry, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return PostingEntry{}, false, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(postingID) == "" {
		return PostingEntry{}, false, errors.New("posting_id is required")
	}

	entry, ok := r.repository.FindByPostingID(tenantID, postingID)
	return entry, ok, nil
}

func (r *DocumentPostingRuntime) ListDocumentPostings(tenantID string, documentID string) ([]PostingEntry, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(documentID) == "" {
		return nil, errors.New("document_id is required")
	}

	return r.repository.ListByDocument(tenantID, documentID), nil
}

func (r *DocumentPostingRuntime) validatePostingRequest(req PostingRequest) error {
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
	if strings.TrimSpace(req.PostingID) == "" {
		return errors.New("posting_id is required")
	}
	if !r.postingSourceAllowed(req.PostingSource) {
		return fmt.Errorf("posting_source is not allowed: %s", req.PostingSource)
	}
	if err := r.validateVoucher(req.Voucher); err != nil {
		return err
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *DocumentPostingRuntime) validateVoucher(v voucherpipeline.Voucher) error {
	if strings.TrimSpace(v.TenantID) == "" {
		return errors.New("voucher tenant_id is required")
	}
	if strings.TrimSpace(v.VoucherID) == "" {
		return errors.New("voucher_id is required")
	}
	if strings.TrimSpace(v.VoucherNo) == "" {
		return errors.New("voucher_no is required")
	}
	if strings.TrimSpace(v.DocumentID) == "" {
		return errors.New("voucher document_id is required")
	}
	if strings.TrimSpace(v.DocumentNo) == "" {
		return errors.New("voucher document_no is required")
	}
	if v.DocumentDate.IsZero() {
		return errors.New("voucher document_date is required")
	}
	if strings.TrimSpace(v.CurrencyCode) == "" {
		return errors.New("voucher currency_code is required")
	}
	if v.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("voucher currency_code mismatch")
	}
	if r.config.RequireVoucherReady && !v.PostingReady {
		return errors.New("voucher posting_ready is required")
	}
	if r.config.RequireBalanced && !v.Balanced {
		return errors.New("voucher balanced is required")
	}
	if v.TotalDebitKurus <= 0 {
		return errors.New("voucher total_debit_kurus must be positive")
	}
	if v.TotalCreditKurus <= 0 {
		return errors.New("voucher total_credit_kurus must be positive")
	}
	if v.TotalDebitKurus != v.TotalCreditKurus {
		return errors.New("voucher debit and credit totals must match")
	}
	if len(v.Lines) == 0 {
		return errors.New("voucher lines are required")
	}
	if r.config.RequireAuditTrace && strings.TrimSpace(v.AuditTraceID) == "" {
		return errors.New("voucher audit_trace_id is required")
	}

	for _, line := range v.Lines {
		if line.LineNo <= 0 {
			return errors.New("voucher line_no must be positive")
		}
		if strings.TrimSpace(line.AccountCode) == "" {
			return errors.New("voucher line account_code is required")
		}
		if line.DebitAmountKurus < 0 {
			return errors.New("voucher line debit_amount_kurus cannot be negative")
		}
		if line.CreditAmountKurus < 0 {
			return errors.New("voucher line credit_amount_kurus cannot be negative")
		}
		if line.DebitAmountKurus == 0 && line.CreditAmountKurus == 0 {
			return errors.New("voucher line debit or credit amount is required")
		}
		if line.DebitAmountKurus > 0 && line.CreditAmountKurus > 0 {
			return errors.New("voucher line cannot have both debit and credit")
		}
	}

	return nil
}

func (r *DocumentPostingRuntime) validateReversalRequest(req ReversalRequest) error {
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
	if strings.TrimSpace(req.ReversalID) == "" {
		return errors.New("reversal_id is required")
	}
	if req.OriginalPosting.Status != PostingStatusPosted {
		return errors.New("original posting must be POSTED")
	}
	if strings.TrimSpace(req.ReasonCode) == "" {
		return errors.New("reason_code is required")
	}
	if strings.TrimSpace(req.ReasonText) == "" {
		return errors.New("reason_text is required")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *DocumentPostingRuntime) buildPostingEntry(req PostingRequest, status PostingStatus) PostingEntry {
	lines := make([]PostingLine, 0, len(req.Voucher.Lines))

	for _, voucherLine := range req.Voucher.Lines {
		lines = append(lines, PostingLine{
			PostingLineID:     fmt.Sprintf("%s:%d", req.PostingID, voucherLine.LineNo),
			LineNo:            voucherLine.LineNo,
			AccountCode:       voucherLine.AccountCode,
			AccountName:       voucherLine.AccountName,
			DebitAmountKurus:  voucherLine.DebitAmountKurus,
			CreditAmountKurus: voucherLine.CreditAmountKurus,
			DocumentID:        voucherLine.DocumentID,
			DocumentNo:        voucherLine.DocumentNo,
			PartyID:           voucherLine.PartyID,
			PartyTaxNo:        voucherLine.PartyTaxNo,
			TaxTraceCode:      voucherLine.TaxTraceCode,
			Description:       voucherLine.Description,
		})
	}

	return PostingEntry{
		TenantID:         req.TenantID,
		CorrelationID:    req.CorrelationID,
		RequestID:        req.RequestID,
		IdempotencyKey:   req.IdempotencyKey,
		PostingID:        req.PostingID,
		PostingNo:        fmt.Sprintf("POST-%s", req.Voucher.VoucherNo),
		PostingSource:    req.PostingSource,
		Status:           status,
		VoucherID:        req.Voucher.VoucherID,
		VoucherNo:        req.Voucher.VoucherNo,
		DocumentType:     string(req.Voucher.DocumentType),
		DocumentID:       req.Voucher.DocumentID,
		DocumentNo:       req.Voucher.DocumentNo,
		DocumentDate:     req.Voucher.DocumentDate,
		CurrencyCode:     req.Voucher.CurrencyCode,
		Lines:            lines,
		TotalDebitKurus:  req.Voucher.TotalDebitKurus,
		TotalCreditKurus: req.Voucher.TotalCreditKurus,
		Balanced:         req.Voucher.Balanced,
		PostingReady:     req.Voucher.PostingReady,
		AuditTraceID:     fmt.Sprintf("posting-audit:%s:%s:%s", req.TenantID, req.PostingID, req.Voucher.AuditTraceID),
		PostingHash:      buildPostingHash(req.TenantID, req.PostingID, req.Voucher.TotalDebitKurus, req.Voucher.TotalCreditKurus, len(lines)),
		CreatedAt:        time.Now().UTC(),
	}
}

func (r *DocumentPostingRuntime) postingSourceAllowed(source PostingSource) bool {
	for _, allowed := range r.config.AllowedPostingSources {
		if allowed == source {
			return true
		}
	}
	return false
}

func tenantPostingKey(tenantID string, postingID string) string {
	return tenantID + "::" + postingID
}

func tenantIdempotencyKey(tenantID string, idempotencyKey string) string {
	return tenantID + "::" + idempotencyKey
}

func buildPostingHash(tenantID string, postingID string, debit int64, credit int64, lineCount int) string {
	return fmt.Sprintf("posting:%s:%s:%d:%d:%d", tenantID, postingID, debit, credit, lineCount)
}

func rejectedPosting(req PostingRequest, code string, message string) PostingEntry {
	return PostingEntry{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		PostingID:           req.PostingID,
		PostingSource:       req.PostingSource,
		Status:              PostingStatusRejected,
		VoucherID:           req.Voucher.VoucherID,
		VoucherNo:           req.Voucher.VoucherNo,
		DocumentType:        string(req.Voucher.DocumentType),
		DocumentID:          req.Voucher.DocumentID,
		DocumentNo:          req.Voucher.DocumentNo,
		CurrencyCode:        req.Voucher.CurrencyCode,
		Balanced:            false,
		PostingReady:        false,
		LedgerReady:         false,
		AuditAction:         "DOCUMENT_BASED_POSTING_REJECTED",
		AuditDecisionReason: "document posting rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		CreatedAt:           time.Now().UTC(),
	}
}

func rejectedReversal(req ReversalRequest, code string, message string) PostingEntry {
	return PostingEntry{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		PostingID:           req.ReversalID,
		Status:              PostingStatusRejected,
		DocumentID:          req.OriginalPosting.DocumentID,
		DocumentNo:          req.OriginalPosting.DocumentNo,
		CurrencyCode:        req.OriginalPosting.CurrencyCode,
		Balanced:            false,
		PostingReady:        false,
		LedgerReady:         false,
		AuditAction:         "DOCUMENT_BASED_POSTING_REVERSAL_REJECTED",
		AuditDecisionReason: "posting reversal rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		CreatedAt:           time.Now().UTC(),
	}
}
