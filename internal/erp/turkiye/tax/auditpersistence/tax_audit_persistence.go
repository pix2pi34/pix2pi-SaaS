package auditpersistence

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"
)

type TaxFamily string

const (
	TaxFamilyKDV          TaxFamily = "KDV"
	TaxFamilyStopaj       TaxFamily = "STOPAJ"
	TaxFamilyTaxExemption TaxFamily = "TAX_EXEMPTION"
	TaxFamilyOTV          TaxFamily = "OTV"
	TaxFamilyDamga        TaxFamily = "DAMGA"
	TaxFamilyCustom       TaxFamily = "CUSTOM"
)

type AuditAction string

const (
	ActionKDVCalculated        AuditAction = "KDV_CALCULATED"
	ActionStopajCalculated     AuditAction = "STOPAJ_CALCULATED"
	ActionExemptionApplied     AuditAction = "EXEMPTION_APPLIED"
	ActionRuleVersionRolled    AuditAction = "RULE_VERSION_ROLLED"
	ActionRuleVersionActivated AuditAction = "RULE_VERSION_ACTIVATED"
	ActionRuleVersionRollback  AuditAction = "RULE_VERSION_ROLLBACK"
	ActionValidationRejected   AuditAction = "VALIDATION_REJECTED"
	ActionManualReview         AuditAction = "MANUAL_REVIEW"
)

type DecisionStatus string

const (
	DecisionApplied    DecisionStatus = "APPLIED"
	DecisionNotApplied DecisionStatus = "NOT_APPLIED"
	DecisionRejected   DecisionStatus = "REJECTED"
	DecisionReady      DecisionStatus = "READY"
	DecisionActivated  DecisionStatus = "ACTIVATED"
	DecisionRolledBack DecisionStatus = "ROLLED_BACK"
)

type SourceRuntime string

const (
	SourceKDVRuntime          SourceRuntime = "KDV_RUNTIME"
	SourceStopajRuntime       SourceRuntime = "STOPAJ_RUNTIME"
	SourceTaxExemptionRuntime SourceRuntime = "TAX_EXEMPTION_RUNTIME"
	SourceRuleRolloutRuntime  SourceRuntime = "TAX_RULE_VERSION_ROLLOUT_RUNTIME"
	SourceTaxRuntimeTestSuite SourceRuntime = "TAX_RUNTIME_TEST_SUITE"
)

type RuntimeConfig struct {
	PersistenceEnabled    bool            `json:"persistence_enabled"`
	AppendOnly            bool            `json:"append_only"`
	IdempotencyRequired   bool            `json:"idempotency_required"`
	EvidenceHashRequired  bool            `json:"evidence_hash_required"`
	RuleVersionRequired   bool            `json:"rule_version_required"`
	ActorRequired         bool            `json:"actor_required"`
	RetentionDays         int             `json:"retention_days"`
	AllowedTaxFamilies    []TaxFamily     `json:"allowed_tax_families"`
	AllowedAuditActions   []AuditAction   `json:"allowed_audit_actions"`
	AllowedSourceRuntimes []SourceRuntime `json:"allowed_source_runtimes"`
}

type TaxAuditRecord struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	AuditID string `json:"audit_id"`

	TaxFamily      TaxFamily      `json:"tax_family"`
	SourceRuntime  SourceRuntime  `json:"source_runtime"`
	Action         AuditAction    `json:"action"`
	DecisionStatus DecisionStatus `json:"decision_status"`

	RuleVersion         string `json:"rule_version"`
	PreviousRuleVersion string `json:"previous_rule_version"`
	TargetRuleVersion   string `json:"target_rule_version"`

	DocumentType string `json:"document_type"`
	DocumentID   string `json:"document_id"`
	DocumentNo   string `json:"document_no"`

	PartyID    string `json:"party_id"`
	PartyTaxNo string `json:"party_tax_no"`

	TaxBaseAmountKurus     int64 `json:"tax_base_amount_kurus"`
	TaxAmountKurus         int64 `json:"tax_amount_kurus"`
	ExemptedAmountKurus    int64 `json:"exempted_amount_kurus"`
	WithholdingAmountKurus int64 `json:"withholding_amount_kurus"`

	CurrencyCode string `json:"currency_code"`

	EvidenceFilePath string `json:"evidence_file_path"`
	EvidenceHash     string `json:"evidence_hash"`
	RequestHash      string `json:"request_hash"`
	ResultHash       string `json:"result_hash"`

	BeforeSnapshotHash string `json:"before_snapshot_hash"`
	AfterSnapshotHash  string `json:"after_snapshot_hash"`

	AuditDecisionReason string `json:"audit_decision_reason"`
	ErrorCode           string `json:"error_code"`
	ErrorMessage        string `json:"error_message"`

	ActorID   string `json:"actor_id"`
	ActorRole string `json:"actor_role"`

	CreatedAt time.Time `json:"created_at"`
}

type TaxAuditExport struct {
	TenantID      string `json:"tenant_id"`
	CorrelationID string `json:"correlation_id"`
	RequestID     string `json:"request_id"`
	ExportID      string `json:"export_id"`

	TaxFamily TaxFamily `json:"tax_family"`
	From      time.Time `json:"from"`
	To        time.Time `json:"to"`

	RecordCount                 int   `json:"record_count"`
	TotalTaxBaseAmountKurus     int64 `json:"total_tax_base_amount_kurus"`
	TotalTaxAmountKurus         int64 `json:"total_tax_amount_kurus"`
	TotalExemptedAmountKurus    int64 `json:"total_exempted_amount_kurus"`
	TotalWithholdingAmountKurus int64 `json:"total_withholding_amount_kurus"`

	ExportHash string           `json:"export_hash"`
	CreatedAt  time.Time        `json:"created_at"`
	Records    []TaxAuditRecord `json:"records"`
}

type TaxAuditRepository interface {
	Append(record TaxAuditRecord) error
	FindByAuditID(tenantID string, auditID string) (TaxAuditRecord, bool)
	FindByIdempotencyKey(tenantID string, idempotencyKey string) (TaxAuditRecord, bool)
	ListByTenant(tenantID string) []TaxAuditRecord
	ListByTaxFamily(tenantID string, family TaxFamily) []TaxAuditRecord
	ListByDateRange(tenantID string, from time.Time, to time.Time) []TaxAuditRecord
}

type InMemoryTaxAuditRepository struct {
	mu               sync.RWMutex
	recordsByAuditID map[string]TaxAuditRecord
	auditIDOrder     []string
	idempotencyIndex map[string]string
}

func NewInMemoryTaxAuditRepository() *InMemoryTaxAuditRepository {
	return &InMemoryTaxAuditRepository{
		recordsByAuditID: make(map[string]TaxAuditRecord),
		idempotencyIndex: make(map[string]string),
	}
}

func (r *InMemoryTaxAuditRepository) Append(record TaxAuditRecord) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	auditKey := tenantAuditKey(record.TenantID, record.AuditID)
	if _, exists := r.recordsByAuditID[auditKey]; exists {
		return errors.New("audit_id already exists")
	}

	idemKey := tenantIdempotencyKey(record.TenantID, record.IdempotencyKey)
	if existingAuditID, exists := r.idempotencyIndex[idemKey]; exists {
		return fmt.Errorf("idempotency_key already exists for audit_id %s", existingAuditID)
	}

	r.recordsByAuditID[auditKey] = record
	r.auditIDOrder = append(r.auditIDOrder, auditKey)
	r.idempotencyIndex[idemKey] = record.AuditID
	return nil
}

func (r *InMemoryTaxAuditRepository) FindByAuditID(tenantID string, auditID string) (TaxAuditRecord, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	record, ok := r.recordsByAuditID[tenantAuditKey(tenantID, auditID)]
	return record, ok
}

func (r *InMemoryTaxAuditRepository) FindByIdempotencyKey(tenantID string, idempotencyKey string) (TaxAuditRecord, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	auditID, ok := r.idempotencyIndex[tenantIdempotencyKey(tenantID, idempotencyKey)]
	if !ok {
		return TaxAuditRecord{}, false
	}

	return r.recordsByAuditID[tenantAuditKey(tenantID, auditID)], true
}

func (r *InMemoryTaxAuditRepository) ListByTenant(tenantID string) []TaxAuditRecord {
	r.mu.RLock()
	defer r.mu.RUnlock()

	records := make([]TaxAuditRecord, 0)
	for _, key := range r.auditIDOrder {
		record := r.recordsByAuditID[key]
		if record.TenantID == tenantID {
			records = append(records, record)
		}
	}

	sortTaxAuditRecords(records)
	return records
}

func (r *InMemoryTaxAuditRepository) ListByTaxFamily(tenantID string, family TaxFamily) []TaxAuditRecord {
	records := r.ListByTenant(tenantID)
	filtered := make([]TaxAuditRecord, 0)

	for _, record := range records {
		if record.TaxFamily == family {
			filtered = append(filtered, record)
		}
	}

	return filtered
}

func (r *InMemoryTaxAuditRepository) ListByDateRange(tenantID string, from time.Time, to time.Time) []TaxAuditRecord {
	records := r.ListByTenant(tenantID)
	filtered := make([]TaxAuditRecord, 0)

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

type TaxAuditPersistenceRuntime struct {
	config     RuntimeConfig
	repository TaxAuditRepository
}

func NewTaxAuditPersistenceRuntime(config RuntimeConfig, repository TaxAuditRepository) (*TaxAuditPersistenceRuntime, error) {
	if !config.PersistenceEnabled {
		return nil, errors.New("tax audit persistence is disabled")
	}
	if !config.AppendOnly {
		return nil, errors.New("tax audit persistence must be append-only")
	}
	if config.RetentionDays <= 0 {
		return nil, errors.New("retention_days must be positive")
	}
	if len(config.AllowedTaxFamilies) == 0 {
		return nil, errors.New("allowed_tax_families are required")
	}
	if len(config.AllowedAuditActions) == 0 {
		return nil, errors.New("allowed_audit_actions are required")
	}
	if len(config.AllowedSourceRuntimes) == 0 {
		return nil, errors.New("allowed_source_runtimes are required")
	}
	if repository == nil {
		return nil, errors.New("tax audit repository is required")
	}

	return &TaxAuditPersistenceRuntime{
		config:     config,
		repository: repository,
	}, nil
}

func (r *TaxAuditPersistenceRuntime) Record(record TaxAuditRecord) (TaxAuditRecord, error) {
	if err := r.validateRecord(record); err != nil {
		return record, err
	}

	if existing, ok := r.repository.FindByIdempotencyKey(record.TenantID, record.IdempotencyKey); ok {
		return existing, errors.New("duplicate idempotency_key")
	}

	if err := r.repository.Append(record); err != nil {
		return record, err
	}

	stored, ok := r.repository.FindByAuditID(record.TenantID, record.AuditID)
	if !ok {
		return record, errors.New("audit record was not persisted")
	}

	return stored, nil
}

func (r *TaxAuditPersistenceRuntime) FindByAuditID(tenantID string, auditID string) (TaxAuditRecord, bool, error) {
	if strings.TrimSpace(tenantID) == "" {
		return TaxAuditRecord{}, false, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(auditID) == "" {
		return TaxAuditRecord{}, false, errors.New("audit_id is required")
	}

	record, ok := r.repository.FindByAuditID(tenantID, auditID)
	return record, ok, nil
}

func (r *TaxAuditPersistenceRuntime) ExportTenantAuditTrail(tenantID string, correlationID string, requestID string, exportID string, family TaxFamily, from time.Time, to time.Time) (TaxAuditExport, error) {
	if strings.TrimSpace(tenantID) == "" {
		return TaxAuditExport{}, errors.New("tenant_id is required")
	}
	if strings.TrimSpace(correlationID) == "" {
		return TaxAuditExport{}, errors.New("correlation_id is required")
	}
	if strings.TrimSpace(requestID) == "" {
		return TaxAuditExport{}, errors.New("request_id is required")
	}
	if strings.TrimSpace(exportID) == "" {
		return TaxAuditExport{}, errors.New("export_id is required")
	}
	if !r.taxFamilyAllowed(family) {
		return TaxAuditExport{}, fmt.Errorf("tax_family is not allowed: %s", family)
	}
	if !to.IsZero() && !from.IsZero() && to.Before(from) {
		return TaxAuditExport{}, errors.New("to cannot be before from")
	}

	records := r.repository.ListByDateRange(tenantID, from, to)
	filtered := make([]TaxAuditRecord, 0)

	export := TaxAuditExport{
		TenantID:      tenantID,
		CorrelationID: correlationID,
		RequestID:     requestID,
		ExportID:      exportID,
		TaxFamily:     family,
		From:          from,
		To:            to,
		CreatedAt:     time.Now().UTC(),
	}

	for _, record := range records {
		if record.TaxFamily != family {
			continue
		}

		filtered = append(filtered, record)
		export.TotalTaxBaseAmountKurus += record.TaxBaseAmountKurus
		export.TotalTaxAmountKurus += record.TaxAmountKurus
		export.TotalExemptedAmountKurus += record.ExemptedAmountKurus
		export.TotalWithholdingAmountKurus += record.WithholdingAmountKurus
	}

	sortTaxAuditRecords(filtered)
	export.Records = filtered
	export.RecordCount = len(filtered)
	export.ExportHash = buildExportHash(export)
	return export, nil
}

func (r *TaxAuditPersistenceRuntime) validateRecord(record TaxAuditRecord) error {
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
	if strings.TrimSpace(record.AuditID) == "" {
		return errors.New("audit_id is required")
	}
	if !r.taxFamilyAllowed(record.TaxFamily) {
		return fmt.Errorf("tax_family is not allowed: %s", record.TaxFamily)
	}
	if !r.sourceRuntimeAllowed(record.SourceRuntime) {
		return fmt.Errorf("source_runtime is not allowed: %s", record.SourceRuntime)
	}
	if !r.auditActionAllowed(record.Action) {
		return fmt.Errorf("audit_action is not allowed: %s", record.Action)
	}
	if strings.TrimSpace(string(record.DecisionStatus)) == "" {
		return errors.New("decision_status is required")
	}
	if r.config.RuleVersionRequired && strings.TrimSpace(record.RuleVersion) == "" {
		return errors.New("rule_version is required")
	}
	if strings.TrimSpace(record.DocumentID) == "" && strings.TrimSpace(record.TargetRuleVersion) == "" {
		return errors.New("document_id or target_rule_version is required")
	}
	if record.TaxBaseAmountKurus < 0 {
		return errors.New("tax_base_amount_kurus cannot be negative")
	}
	if record.TaxAmountKurus < 0 {
		return errors.New("tax_amount_kurus cannot be negative")
	}
	if record.ExemptedAmountKurus < 0 {
		return errors.New("exempted_amount_kurus cannot be negative")
	}
	if record.WithholdingAmountKurus < 0 {
		return errors.New("withholding_amount_kurus cannot be negative")
	}
	if strings.TrimSpace(record.CurrencyCode) == "" {
		return errors.New("currency_code is required")
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

func (r *TaxAuditPersistenceRuntime) taxFamilyAllowed(family TaxFamily) bool {
	for _, allowed := range r.config.AllowedTaxFamilies {
		if allowed == family {
			return true
		}
	}
	return false
}

func (r *TaxAuditPersistenceRuntime) auditActionAllowed(action AuditAction) bool {
	for _, allowed := range r.config.AllowedAuditActions {
		if allowed == action {
			return true
		}
	}
	return false
}

func (r *TaxAuditPersistenceRuntime) sourceRuntimeAllowed(source SourceRuntime) bool {
	for _, allowed := range r.config.AllowedSourceRuntimes {
		if allowed == source {
			return true
		}
	}
	return false
}

func tenantAuditKey(tenantID string, auditID string) string {
	return tenantID + "::" + auditID
}

func tenantIdempotencyKey(tenantID string, idempotencyKey string) string {
	return tenantID + "::" + idempotencyKey
}

func sortTaxAuditRecords(records []TaxAuditRecord) {
	sort.SliceStable(records, func(i int, j int) bool {
		if records[i].CreatedAt.Equal(records[j].CreatedAt) {
			return records[i].AuditID < records[j].AuditID
		}
		return records[i].CreatedAt.Before(records[j].CreatedAt)
	})
}

func buildExportHash(export TaxAuditExport) string {
	return fmt.Sprintf(
		"tax-audit-export:%s:%s:%s:%d:%d:%d:%d:%d",
		export.TenantID,
		export.ExportID,
		export.TaxFamily,
		export.RecordCount,
		export.TotalTaxBaseAmountKurus,
		export.TotalTaxAmountKurus,
		export.TotalExemptedAmountKurus,
		export.TotalWithholdingAmountKurus,
	)
}
