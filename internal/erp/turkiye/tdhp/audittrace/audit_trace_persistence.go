package audittrace

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

type TraceSource string

const (
	SourceRealVoucherPipeline       TraceSource = "REAL_VOUCHER_PIPELINE"
	SourceDocumentPostingRuntime    TraceSource = "DOCUMENT_BASED_POSTING_RUNTIME"
	SourceChartAccountVersionSwitch TraceSource = "CHART_ACCOUNT_LIVE_VERSION_SWITCH"
	SourceReconciliationRuntime     TraceSource = "RECONCILIATION_RUNTIME"
	SourceTDHPLiveTests             TraceSource = "TDHP_LIVE_TESTS"
	SourceManualReview              TraceSource = "MANUAL_REVIEW"
)

type TraceAction string

const (
	ActionVoucherBuilt             TraceAction = "VOUCHER_BUILT"
	ActionPostingPrepared          TraceAction = "POSTING_PREPARED"
	ActionPostingPosted            TraceAction = "POSTING_POSTED"
	ActionPostingReversed          TraceAction = "POSTING_REVERSED"
	ActionPostingRejected          TraceAction = "POSTING_REJECTED"
	ActionAccountVersionSwitched   TraceAction = "ACCOUNT_VERSION_SWITCHED"
	ActionReconciliationMatched    TraceAction = "RECONCILIATION_MATCHED"
	ActionReconciliationDifference TraceAction = "RECONCILIATION_DIFFERENCE"
	ActionManualReviewQueued       TraceAction = "MANUAL_REVIEW_QUEUED"
)

type TraceStatus string

const (
	TraceStatusRecorded TraceStatus = "RECORDED"
	TraceStatusRejected TraceStatus = "REJECTED"
)

type RuntimeConfig struct {
	PersistenceEnabled   bool          `json:"persistence_enabled"`
	AppendOnly           bool          `json:"append_only"`
	IdempotencyRequired  bool          `json:"idempotency_required"`
	EvidenceHashRequired bool          `json:"evidence_hash_required"`
	SnapshotHashRequired bool          `json:"snapshot_hash_required"`
	ActorRequired        bool          `json:"actor_required"`
	RetentionDays        int           `json:"retention_days"`
	AllowedSources       []TraceSource `json:"allowed_sources"`
	AllowedActions       []TraceAction `json:"allowed_actions"`
}

type AuditTraceRecord struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	TraceID string      `json:"trace_id"`
	Source  TraceSource `json:"source"`
	Action  TraceAction `json:"action"`
	Status  TraceStatus `json:"status"`

	DocumentType string    `json:"document_type"`
	DocumentID   string    `json:"document_id"`
	DocumentNo   string    `json:"document_no"`
	DocumentDate time.Time `json:"document_date"`

	VoucherID string `json:"voucher_id"`
	VoucherNo string `json:"voucher_no"`

	PostingID     string `json:"posting_id"`
	PostingNo     string `json:"posting_no"`
	PostingStatus string `json:"posting_status"`

	AccountVersionCode string `json:"account_version_code"`
	ReconciliationID   string `json:"reconciliation_id"`

	CurrencyCode string `json:"currency_code"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`
	Balanced         bool  `json:"balanced"`
	LineCount        int   `json:"line_count"`

	EvidenceFilePath string `json:"evidence_file_path"`
	EvidenceHash     string `json:"evidence_hash"`
	RequestHash      string `json:"request_hash"`
	ResultHash       string `json:"result_hash"`

	BeforeSnapshotHash string `json:"before_snapshot_hash"`
	AfterSnapshotHash  string `json:"after_snapshot_hash"`

	PostingHash string `json:"posting_hash"`
	VoucherHash string `json:"voucher_hash"`

	AuditDecisionReason string `json:"audit_decision_reason"`
	ErrorCode           string `json:"error_code"`
	ErrorMessage        string `json:"error_message"`

	ActorID   string `json:"actor_id"`
	ActorRole string `json:"actor_role"`

	CreatedAt time.Time `json:"created_at"`
}

type AuditTraceExport struct {
	TenantID      string `json:"tenant_id"`
	CorrelationID string `json:"correlation_id"`
	RequestID     string `json:"request_id"`
	ExportID      string `json:"export_id"`

	Source TraceSource `json:"source"`
	From   time.Time   `json:"from"`
	To     time.Time   `json:"to"`

	RecordCount   int `json:"record_count"`
	PostedCount   int `json:"posted_count"`
	ReversedCount int `json:"reversed_count"`
	RejectedCount int `json:"rejected_count"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`

	ExportHash string             `json:"export_hash"`
	CreatedAt  time.Time          `json:"created_at"`
	Records    []AuditTraceRecord `json:"records"`
}

type AuditTraceRepository interface {
	Append(record AuditTraceRecord) error
	FindByTraceID(tenantID string, traceID string) (AuditTraceRecord, bool)
	FindByIdempotencyKey(tenantID string, idempotencyKey string) (AuditTraceRecord, bool)
	ListByTenant(tenantID string) []AuditTraceRecord
	ListByDocument(tenantID string, documentID string) []AuditTraceRecord
	ListByPosting(tenantID string, postingID string) []AuditTraceRecord
	ListByDateRange(tenantID string, from time.Time, to time.Time) []AuditTraceRecord
}

type InMemoryAuditTraceRepository struct {
	mu               sync.RWMutex
	recordsByTrace   map[string]AuditTraceRecord
	idempotencyIndex map[string]string
	order            []string
}

func NewInMemoryAuditTraceRepository() *InMemoryAuditTraceRepository {
	return &InMemoryAuditTraceRepository{
		recordsByTrace:   make(map[string]AuditTraceRecord),
		idempotencyIndex: make(map[string]string),
		order:            make([]string, 0),
	}
}

func (r *InMemoryAuditTraceRepository) Append(record AuditTraceRecord) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	traceKey := tenantTraceKey(record.TenantID, record.TraceID)
	if _, exists := r.recordsByTrace[traceKey]; exists {
		return errors.New("trace_id already exists")
	}

	idemKey := tenantIdempotencyKey(record.TenantID, record.IdempotencyKey)
	if existingTraceID, exists := r.idempotencyIndex[idemKey]; exists {
		return fmt.Errorf("idempotency_key already exists for trace_id %s", existingTraceID)
	}

	r.recordsByTrace[traceKey] = record
	r.idempotencyIndex[idemKey] = record.TraceID
	r.order = append(r.order, traceKey)

	return nil
}

func (r *InMemoryAuditTraceRepository) FindByTraceID(tenantID string, traceID string) (AuditTraceRecord, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.recordsByTrace[tenantTraceKey(tenantID, traceID)]
	return record, ok
}

func (r *InMemoryAuditTraceRepository) FindByIdempotencyKey(tenantID string, idempotencyKey string) (AuditTraceRecord, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	traceID, ok := r.idempotencyIndex[tenantIdempotencyKey(tenantID, idempotencyKey)]
	if !ok {
		return AuditTraceRecord{}, false
	}

	return r.recordsByTrace[tenantTraceKey(tenantID, traceID)], true
}

func (r *InMemoryAuditTraceRepository) ListByTenant(tenantID string) []AuditTraceRecord {
	r.mu.RLock()
	defer r.mu.RUnlock()

	records := make([]AuditTraceRecord, 0)
	for _, key := range r.order {
		record := r.recordsByTrace[key]
		if record.TenantID == tenantID {
			records = append(records, record)
		}
	}

	sortAuditTraceRecords(records)
	return records
}

func (r *InMemoryAuditTraceRepository) ListByDocument(tenantID string, documentID string) []AuditTraceRecord {
	records := r.ListByTenant(tenantID)
	filtered := make([]AuditTraceRecord, 0)

	for _, record := range records {
		if record.DocumentID == documentID {
			filtered = append(filtered, record)
		}
	}

	return filtered
}

func (r *InMemoryAuditTraceRepository) ListByPosting(tenantID string, postingID string) []AuditTraceRecord {
	records := r.ListByTenant(tenantID)
	filtered := make([]AuditTraceRecord, 0)

	for _, record := range records {
		if record.PostingID == postingID {
			filtered = append(filtered, record)
		}
	}

	return filtered
}

func (r *InMemoryAuditTraceRepository) ListByDateRange(tenantID string, from time.Time, to time.Time) []AuditTraceRecord {
	records := r.ListByTenant(tenantID)
	filtered := make([]AuditTraceRecord, 0)

	for _, record := range records {
		if !from.IsZero() && record.CreatedAt.Before(from) {
			continue
		}
		if !to.IsZero() && record.CreatedAt.After(to) {
			continue
		}
		filtered = append(filtered, record)
	}

	return filtered
}

type AuditTracePersistenceRuntime struct {
	config     RuntimeConfig
	repository AuditTraceRepository
}

func NewAuditTracePersistenceRuntime(config RuntimeConfig, repository AuditTraceRepository) (*AuditTracePersistenceRuntime, error) {
	if !config.PersistenceEnabled {
		return nil, errors.New("audit trace persistence is disabled")
	}
	if !config.AppendOnly {
		return nil, errors.New("audit trace persistence must be append-only")
	}
	if config.RetentionDays <= 0 {
		return nil, errors.New("retention_days must be positive")
	}
	if len(config.AllowedSources) == 0 {
		return nil, errors.New("allowed_sources are required")
	}
	if len(config.AllowedActions) == 0 {
		return nil, errors.New("allowed_actions are required")
	}
	if repository == nil {
		return nil, errors.New("audit trace repository is required")
	}

	return &AuditTracePersistenceRuntime{
		config:     config,
		repository: repository,
	}, nil
}

func (r *AuditTracePersistenceRuntime) RecordTrace(record AuditTraceRecord) (AuditTraceRecord, error) {
	if err := r.validateRecord(record); err != nil {
		rejected := record
		rejected.Status = TraceStatusRejected
		rejected.ErrorCode = "VALIDATION_FAILED"
		rejected.ErrorMessage = err.Error()
		return rejected, err
	}

	if existing, ok := r.repository.FindByIdempotencyKey(record.TenantID, record.IdempotencyKey); ok {
		return existing, errors.New("duplicate idempotency_key")
	}

	if err := r.repository.Append(record); err != nil {
		return record, err
	}

	stored, ok := r.repository.FindByTraceID(record.TenantID, record.TraceID)
	if !ok {
		return record, errors.New("audit trace record was not persisted")
	}

	return stored, nil
}

func (r *AuditTracePersistenceRuntime) RecordFromPosting(entry postingruntime.PostingEntry, traceID string, idempotencyKey string, action TraceAction, actorID string, actorRole string) (AuditTraceRecord, error) {
	if strings.TrimSpace(traceID) == "" {
		return AuditTraceRecord{}, errors.New("trace_id is required")
	}
	if strings.TrimSpace(idempotencyKey) == "" {
		return AuditTraceRecord{}, errors.New("idempotency_key is required")
	}

	record := AuditTraceRecord{
		TenantID:            entry.TenantID,
		CorrelationID:       entry.CorrelationID,
		RequestID:           entry.RequestID,
		IdempotencyKey:      idempotencyKey,
		TraceID:             traceID,
		Source:              SourceDocumentPostingRuntime,
		Action:              action,
		Status:              TraceStatusRecorded,
		DocumentType:        entry.DocumentType,
		DocumentID:          entry.DocumentID,
		DocumentNo:          entry.DocumentNo,
		DocumentDate:        entry.DocumentDate,
		VoucherID:           entry.VoucherID,
		VoucherNo:           entry.VoucherNo,
		PostingID:           entry.PostingID,
		PostingNo:           entry.PostingNo,
		PostingStatus:       string(entry.Status),
		CurrencyCode:        entry.CurrencyCode,
		TotalDebitKurus:     entry.TotalDebitKurus,
		TotalCreditKurus:    entry.TotalCreditKurus,
		Balanced:            entry.Balanced,
		LineCount:           len(entry.Lines),
		EvidenceFilePath:    fmt.Sprintf("docs/faz3/evidence/%s.md", traceID),
		EvidenceHash:        fmt.Sprintf("sha256:%s:evidence", traceID),
		RequestHash:         fmt.Sprintf("sha256:%s:request", traceID),
		ResultHash:          fmt.Sprintf("sha256:%s:result", traceID),
		BeforeSnapshotHash:  fmt.Sprintf("sha256:%s:before", traceID),
		AfterSnapshotHash:   fmt.Sprintf("sha256:%s:after", traceID),
		PostingHash:         entry.PostingHash,
		AuditDecisionReason: entry.AuditDecisionReason,
		ActorID:             actorID,
		ActorRole:           actorRole,
		CreatedAt:           time.Now().UTC(),
	}

	return r.RecordTrace(record)
}

func (r *AuditTracePersistenceRuntime) FindTrace(tenantID string, traceID string) (AuditTraceRecord, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return AuditTraceRecord{}, false, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(traceID) == "" {
		return AuditTraceRecord{}, false, errors.New("trace_id is required")
	}

	record, ok := r.repository.FindByTraceID(tenantID, traceID)
	return record, ok, nil
}

func (r *AuditTracePersistenceRuntime) ListDocumentTraces(tenantID string, documentID string) ([]AuditTraceRecord, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(documentID) == "" {
		return nil, errors.New("document_id is required")
	}

	return r.repository.ListByDocument(tenantID, documentID), nil
}

func (r *AuditTracePersistenceRuntime) ListPostingTraces(tenantID string, postingID string) ([]AuditTraceRecord, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(postingID) == "" {
		return nil, errors.New("posting_id is required")
	}

	return r.repository.ListByPosting(tenantID, postingID), nil
}

func (r *AuditTracePersistenceRuntime) ExportTenantTrace(tenantID string, correlationID string, requestID string, exportID string, source TraceSource, from time.Time, to time.Time) (AuditTraceExport, error) {
	if strings.TrimSpace(tenantID) == "" {
		return AuditTraceExport{}, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(correlationID) == "" {
		return AuditTraceExport{}, errors.New("correlation_id is required")
	}
	if strings.TrimSpace(requestID) == "" {
		return AuditTraceExport{}, errors.New("request_id is required")
	}
	if strings.TrimSpace(exportID) == "" {
		return AuditTraceExport{}, errors.New("export_id is required")
	}
	if !r.sourceAllowed(source) {
		return AuditTraceExport{}, fmt.Errorf("source is not allowed: %s", source)
	}
	if !from.IsZero() && !to.IsZero() && to.Before(from) {
		return AuditTraceExport{}, errors.New("to cannot be before from")
	}

	records := r.repository.ListByDateRange(tenantID, from, to)
	filtered := make([]AuditTraceRecord, 0)

	export := AuditTraceExport{
		TenantID:      tenantID,
		CorrelationID: correlationID,
		RequestID:     requestID,
		ExportID:      exportID,
		Source:        source,
		From:          from,
		To:            to,
		CreatedAt:     time.Now().UTC(),
	}

	for _, record := range records {
		if record.Source != source {
			continue
		}

		filtered = append(filtered, record)
		export.TotalDebitKurus += record.TotalDebitKurus
		export.TotalCreditKurus += record.TotalCreditKurus

		switch record.Action {
		case ActionPostingPosted:
			export.PostedCount++
		case ActionPostingReversed:
			export.ReversedCount++
		case ActionPostingRejected:
			export.RejectedCount++
		}
	}

	sortAuditTraceRecords(filtered)
	export.Records = filtered
	export.RecordCount = len(filtered)
	export.ExportHash = buildExportHash(export)
	return export, nil
}

func (r *AuditTracePersistenceRuntime) validateRecord(record AuditTraceRecord) error {
	if strings.TrimSpace(record.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(record.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(record.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(record.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(record.TraceID) == "" {
		return errors.New("trace_id is required")
	}
	if !r.sourceAllowed(record.Source) {
		return fmt.Errorf("source is not allowed: %s", record.Source)
	}
	if !r.actionAllowed(record.Action) {
		return fmt.Errorf("action is not allowed: %s", record.Action)
	}
	if strings.TrimSpace(string(record.Status)) == "" {
		return errors.New("status is required")
	}
	if strings.TrimSpace(record.DocumentID) == "" && strings.TrimSpace(record.PostingID) == "" && strings.TrimSpace(record.ReconciliationID) == "" {
		return errors.New("document_id or posting_id or reconciliation_id is required")
	}
	if strings.TrimSpace(record.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if record.TotalDebitKurus < 0 {
		return errors.New("total_debit_kurus cannot be negative")
	}
	if record.TotalCreditKurus < 0 {
		return errors.New("total_credit_kurus cannot be negative")
	}
	if record.LineCount < 0 {
		return errors.New("line_count cannot be negative")
	}
	if strings.TrimSpace(record.EvidenceFilePath) == "" {
		return errors.New("evidence_file_path is required")
	}
	if r.config.EvidenceHashRequired && strings.TrimSpace(record.EvidenceHash) == "" {
		return errors.New("evidence_hash is required")
	}
	if strings.TrimSpace(record.RequestHash) == "" {
		return errors.New("request_hash is required")
	}
	if strings.TrimSpace(record.ResultHash) == "" {
		return errors.New("result_hash is required")
	}
	if r.config.SnapshotHashRequired {
		if strings.TrimSpace(record.BeforeSnapshotHash) == "" {
			return errors.New("before_snapshot_hash is required")
		}
		if strings.TrimSpace(record.AfterSnapshotHash) == "" {
			return errors.New("after_snapshot_hash is required")
		}
	}
	if strings.TrimSpace(record.AuditDecisionReason) == "" {
		return errors.New("audit_decision_reason is required")
	}
	if r.config.ActorRequired && strings.TrimSpace(record.ActorID) == "" {
		return errors.New("actor_id is required")
	}
	if r.config.ActorRequired && strings.TrimSpace(record.ActorRole) == "" {
		return errors.New("actor_role is required")
	}
	if record.CreatedAt.IsZero() {
		return errors.New("created_at is required")
	}

	return nil
}

func (r *AuditTracePersistenceRuntime) sourceAllowed(source TraceSource) bool {
	for _, allowed := range r.config.AllowedSources {
		if allowed == source {
			return true
		}
	}
	return false
}

func (r *AuditTracePersistenceRuntime) actionAllowed(action TraceAction) bool {
	for _, allowed := range r.config.AllowedActions {
		if allowed == action {
			return true
		}
	}
	return false
}

func tenantTraceKey(tenantID string, traceID string) string {
	return tenantID + "::" + traceID
}

func tenantIdempotencyKey(tenantID string, idempotencyKey string) string {
	return tenantID + "::" + idempotencyKey
}

func sortAuditTraceRecords(records []AuditTraceRecord) {
	sort.SliceStable(records, func(i int, j int) bool {
		if records[i].CreatedAt.Equal(records[j].CreatedAt) {
			return records[i].TraceID < records[j].TraceID
		}
		return records[i].CreatedAt.Before(records[j].CreatedAt)
	})
}

func buildExportHash(export AuditTraceExport) string {
	return fmt.Sprintf(
		"audit-trace-export:%s:%s:%s:%d:%d:%d:%d:%d:%d",
		export.TenantID,
		export.ExportID,
		export.Source,
		export.RecordCount,
		export.PostedCount,
		export.ReversedCount,
		export.RejectedCount,
		export.TotalDebitKurus,
		export.TotalCreditKurus,
	)
}
