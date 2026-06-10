package integrationruntime

import (
	"fmt"
	"strings"
	"time"
)

type ParasutERPObjectType string

const (
	ParasutERPObjectCustomer ParasutERPObjectType = "CUSTOMER"
	ParasutERPObjectProduct  ParasutERPObjectType = "PRODUCT"
	ParasutERPObjectInvoice  ParasutERPObjectType = "INVOICE"
)

type ParasutERPSyncStatus string

const (
	ParasutERPSyncStatusMapped       ParasutERPSyncStatus = "MAPPED"
	ParasutERPSyncStatusDuplicate    ParasutERPSyncStatus = "DUPLICATE_SAFE"
	ParasutERPSyncStatusConflict     ParasutERPSyncStatus = "CONFLICT"
	ParasutERPSyncStatusDryRunReady  ParasutERPSyncStatus = "ERP_WRITE_DRY_RUN_READY"
	ParasutERPSyncStatusAuditWritten ParasutERPSyncStatus = "MAPPING_AUDIT_WRITTEN"
)

type ParasutSourceBase struct {
	TenantID         string
	ProviderKey      string
	AppKey           string
	ExternalObjectID string
	CorrelationID    string
	ReceivedAt       time.Time
}

type ParasutCustomerSource struct {
	ParasutSourceBase
	TaxNumber string
	Name      string
	Email     string
	Phone     string
}

type ParasutProductSource struct {
	ParasutSourceBase
	SKU     string
	Name    string
	Unit    string
	VATRate int
}

type ParasutInvoiceLineSource struct {
	LineID         string
	ProductSKU     string
	Description    string
	Quantity       int64
	UnitPriceMinor int64
	VATRate        int
}

type ParasutInvoiceSource struct {
	ParasutSourceBase
	InvoiceNumber      string
	CustomerExternalID string
	Currency           string
	AmountMinor        int64
	VATAmountMinor     int64
	Lines              []ParasutInvoiceLineSource
}

type Pix2piERPSyncRecord struct {
	TenantID           string
	ProviderKey        string
	AppKey             string
	ObjectType         ParasutERPObjectType
	ProviderExternalID string
	ERPObjectKey       string
	SyncKey            string
	Status             ParasutERPSyncStatus
	CorrelationID      string
	CreatedAt          time.Time
	Fields             map[string]string
	AmountMinor        int64
	VATAmountMinor     int64
	AuditDecision      AuditDecision
}

func validateParasutSourceBase(base ParasutSourceBase) error {
	if err := requireNonEmpty(base.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(base.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if normalize(base.ProviderKey) != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(base.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(base.ExternalObjectID, "external_object_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(base.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return nil
}

func BuildParasutCustomerERPSync(src ParasutCustomerSource) (Pix2piERPSyncRecord, error) {
	if err := validateParasutSourceBase(src.ParasutSourceBase); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.TaxNumber, "tax_number"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.Name, "name"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}

	createdAt := src.ReceivedAt
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}

	syncKey := BuildParasutSyncKey(src.TenantID, ParasutERPObjectCustomer, src.ExternalObjectID)

	return Pix2piERPSyncRecord{
		TenantID:           normalize(src.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(src.AppKey),
		ObjectType:         ParasutERPObjectCustomer,
		ProviderExternalID: normalize(src.ExternalObjectID),
		ERPObjectKey:       "erp_customer:" + normalize(src.TaxNumber),
		SyncKey:            syncKey,
		Status:             ParasutERPSyncStatusMapped,
		CorrelationID:      normalize(src.CorrelationID),
		CreatedAt:          createdAt,
		Fields: map[string]string{
			"tax_number": normalize(src.TaxNumber),
			"name":       normalize(src.Name),
			"email":      normalize(src.Email),
			"phone":      normalize(src.Phone),
		},
		AuditDecision: AuditDecisionAllowed,
	}, nil
}

func BuildParasutProductERPSync(src ParasutProductSource) (Pix2piERPSyncRecord, error) {
	if err := validateParasutSourceBase(src.ParasutSourceBase); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.SKU, "sku"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.Name, "name"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.Unit, "unit"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if src.VATRate < 0 {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: vat_rate must be non-negative", ErrInvalidIntegrationRequest)
	}

	createdAt := src.ReceivedAt
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}

	syncKey := BuildParasutSyncKey(src.TenantID, ParasutERPObjectProduct, src.ExternalObjectID)
	normalizedSKU := strings.ToLower(normalize(src.SKU))

	return Pix2piERPSyncRecord{
		TenantID:           normalize(src.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(src.AppKey),
		ObjectType:         ParasutERPObjectProduct,
		ProviderExternalID: normalize(src.ExternalObjectID),
		ERPObjectKey:       "erp_product:" + normalizedSKU,
		SyncKey:            syncKey,
		Status:             ParasutERPSyncStatusMapped,
		CorrelationID:      normalize(src.CorrelationID),
		CreatedAt:          createdAt,
		Fields: map[string]string{
			"sku":      normalizedSKU,
			"name":     normalize(src.Name),
			"unit":     strings.ToUpper(normalize(src.Unit)),
			"vat_rate": fmt.Sprintf("%d", src.VATRate),
		},
		AuditDecision: AuditDecisionAllowed,
	}, nil
}

func BuildParasutInvoiceERPSync(src ParasutInvoiceSource) (Pix2piERPSyncRecord, error) {
	if err := validateParasutSourceBase(src.ParasutSourceBase); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.InvoiceNumber, "invoice_number"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.CustomerExternalID, "customer_external_id"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(src.Currency, "currency"); err != nil {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
	}
	if src.AmountMinor <= 0 {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: amount_minor must be positive", ErrInvalidIntegrationRequest)
	}
	if src.VATAmountMinor < 0 {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: vat_amount_minor must be non-negative", ErrInvalidIntegrationRequest)
	}
	if len(src.Lines) == 0 {
		return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: invoice lines required", ErrInvalidIntegrationRequest)
	}
	for _, line := range src.Lines {
		if err := validateParasutInvoiceLine(line); err != nil {
			return Pix2piERPSyncRecord{AuditDecision: AuditDecisionDenied}, err
		}
	}

	createdAt := src.ReceivedAt
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}

	syncKey := BuildParasutSyncKey(src.TenantID, ParasutERPObjectInvoice, src.ExternalObjectID)
	normalizedInvoiceNumber := strings.ToLower(normalize(src.InvoiceNumber))

	return Pix2piERPSyncRecord{
		TenantID:           normalize(src.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(src.AppKey),
		ObjectType:         ParasutERPObjectInvoice,
		ProviderExternalID: normalize(src.ExternalObjectID),
		ERPObjectKey:       "erp_invoice:" + normalizedInvoiceNumber,
		SyncKey:            syncKey,
		Status:             ParasutERPSyncStatusMapped,
		CorrelationID:      normalize(src.CorrelationID),
		CreatedAt:          createdAt,
		Fields: map[string]string{
			"invoice_number":       normalizedInvoiceNumber,
			"customer_external_id": normalize(src.CustomerExternalID),
			"currency":             strings.ToUpper(normalize(src.Currency)),
			"line_count":           fmt.Sprintf("%d", len(src.Lines)),
		},
		AmountMinor:    src.AmountMinor,
		VATAmountMinor: src.VATAmountMinor,
		AuditDecision:  AuditDecisionAllowed,
	}, nil
}

func validateParasutInvoiceLine(line ParasutInvoiceLineSource) error {
	if err := requireNonEmpty(line.LineID, "line_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(line.ProductSKU, "product_sku"); err != nil {
		return err
	}
	if line.Quantity <= 0 {
		return fmt.Errorf("%w: line quantity must be positive", ErrInvalidIntegrationRequest)
	}
	if line.UnitPriceMinor <= 0 {
		return fmt.Errorf("%w: line unit_price_minor must be positive", ErrInvalidIntegrationRequest)
	}
	if line.VATRate < 0 {
		return fmt.Errorf("%w: line vat_rate must be non-negative", ErrInvalidIntegrationRequest)
	}
	return nil
}

func BuildParasutSyncKey(tenantID string, objectType ParasutERPObjectType, externalObjectID string) string {
	return fmt.Sprintf("%s:%s:%s:%s", normalize(tenantID), ParasutProviderKey, objectType, normalize(externalObjectID))
}

type ParasutSyncConflictDecision struct {
	Decision      ParasutERPSyncStatus
	Retryable     bool
	Reason        string
	AuditDecision AuditDecision
}

func EvaluateParasutSyncConflict(existing Pix2piERPSyncRecord, incoming Pix2piERPSyncRecord) ParasutSyncConflictDecision {
	if existing.TenantID == "" {
		return ParasutSyncConflictDecision{
			Decision:      ParasutERPSyncStatusMapped,
			Retryable:     false,
			Reason:        "no_existing_record",
			AuditDecision: AuditDecisionAllowed,
		}
	}
	if existing.TenantID != incoming.TenantID {
		return ParasutSyncConflictDecision{
			Decision:      ParasutERPSyncStatusConflict,
			Retryable:     false,
			Reason:        "cross_tenant_mapping_rejected",
			AuditDecision: AuditDecisionDenied,
		}
	}
	if existing.ObjectType != incoming.ObjectType {
		return ParasutSyncConflictDecision{
			Decision:      ParasutERPSyncStatusConflict,
			Retryable:     false,
			Reason:        "object_type_mismatch_rejected",
			AuditDecision: AuditDecisionDenied,
		}
	}
	if existing.SyncKey == incoming.SyncKey {
		return ParasutSyncConflictDecision{
			Decision:      ParasutERPSyncStatusDuplicate,
			Retryable:     false,
			Reason:        "same_sync_key_duplicate_safe",
			AuditDecision: AuditDecisionAllowed,
		}
	}
	if existing.ProviderExternalID == incoming.ProviderExternalID && existing.ERPObjectKey != incoming.ERPObjectKey {
		return ParasutSyncConflictDecision{
			Decision:      ParasutERPSyncStatusConflict,
			Retryable:     false,
			Reason:        "same_provider_external_id_conflict",
			AuditDecision: AuditDecisionDenied,
		}
	}
	return ParasutSyncConflictDecision{
		Decision:      ParasutERPSyncStatusMapped,
		Retryable:     false,
		Reason:        "safe_new_mapping",
		AuditDecision: AuditDecisionAllowed,
	}
}

type ParasutERPWriteContractRequest struct {
	TenantID            string
	AppKey              string
	Record              Pix2piERPSyncRecord
	RequestedBy         string
	CorrelationID       string
	RealERPWriteEnabled bool
	Now                 time.Time
}

type ParasutERPWriteContractResult struct {
	TenantID      string
	ProviderKey   string
	AppKey        string
	ObjectType    ParasutERPObjectType
	ERPObjectKey  string
	SyncKey       string
	Status        ParasutERPSyncStatus
	DryRunOnly    bool
	RealERPWrite  bool
	AuditDecision AuditDecision
	CorrelationID string
	CreatedAt     time.Time
}

func BuildParasutERPWriteDryRunContract(req ParasutERPWriteContractRequest) (ParasutERPWriteContractResult, error) {
	if err := validateParasutERPWriteContractRequest(req); err != nil {
		return ParasutERPWriteContractResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return ParasutERPWriteContractResult{
		TenantID:      normalize(req.TenantID),
		ProviderKey:   ParasutProviderKey,
		AppKey:        normalize(req.AppKey),
		ObjectType:    req.Record.ObjectType,
		ERPObjectKey:  req.Record.ERPObjectKey,
		SyncKey:       req.Record.SyncKey,
		Status:        ParasutERPSyncStatusDryRunReady,
		DryRunOnly:    true,
		RealERPWrite:  false,
		AuditDecision: AuditDecisionAllowed,
		CorrelationID: normalize(req.CorrelationID),
		CreatedAt:     now,
	}, nil
}

func validateParasutERPWriteContractRequest(req ParasutERPWriteContractRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := validateParasutERPSyncRecord(req.Record); err != nil {
		return err
	}
	if req.Record.TenantID != normalize(req.TenantID) {
		return fmt.Errorf("%w: tenant mismatch for erp write contract", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealERPWriteEnabled {
		return fmt.Errorf("%w: real erp write must remain disabled in data mapping readiness phase", ErrInvalidIntegrationRequest)
	}
	return nil
}

func validateParasutERPSyncRecord(record Pix2piERPSyncRecord) error {
	if err := requireNonEmpty(record.TenantID, "tenant_id"); err != nil {
		return err
	}
	if record.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(record.AppKey, "app_key"); err != nil {
		return err
	}
	if record.ObjectType == "" {
		return fmt.Errorf("%w: object_type required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(record.ProviderExternalID, "provider_external_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(record.ERPObjectKey, "erp_object_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(record.SyncKey, "sync_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(record.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return nil
}

func RecordParasutMappingAudit(obs *ConnectorObservabilityRuntime, writeResult ParasutERPWriteContractResult) error {
	if obs == nil {
		return fmt.Errorf("%w: observability runtime required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(writeResult.TenantID, "tenant_id"); err != nil {
		return err
	}
	if writeResult.ProviderKey != ParasutProviderKey {
		return fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(writeResult.CorrelationID, "correlation_id"); err != nil {
		return err
	}

	return obs.RecordOperation(ConnectorAuditEvent{
		TenantID:      writeResult.TenantID,
		ProviderKey:   ParasutProviderKey,
		AppKey:        writeResult.AppKey,
		Operation:     "ERP_SYNC_MAPPING_" + string(writeResult.ObjectType),
		Status:        "DRY_RUN_READY",
		Decision:      writeResult.AuditDecision,
		CorrelationID: writeResult.CorrelationID,
		Message:       writeResult.SyncKey,
		CreatedAt:     writeResult.CreatedAt,
	})
}

type ParasutDataMappingReadinessGateInput struct {
	SourceDataContractReady      bool
	CustomerMappingReady         bool
	ProductMappingReady          bool
	InvoiceMappingReady          bool
	IdempotencyConflictReady     bool
	ERPWriteDryRunReady          bool
	AuditObservabilityReady      bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	RealProviderAPIEnabled       bool
	RealERPWriteEnabled          bool
}

type ParasutDataMappingReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutDataMappingReadinessGate(input ParasutDataMappingReadinessGateInput) ParasutDataMappingReadinessGateResult {
	blockers := []string{}

	if !input.SourceDataContractReady {
		blockers = append(blockers, "source_data_contract_not_ready")
	}
	if !input.CustomerMappingReady {
		blockers = append(blockers, "customer_mapping_not_ready")
	}
	if !input.ProductMappingReady {
		blockers = append(blockers, "product_mapping_not_ready")
	}
	if !input.InvoiceMappingReady {
		blockers = append(blockers, "invoice_mapping_not_ready")
	}
	if !input.IdempotencyConflictReady {
		blockers = append(blockers, "idempotency_conflict_not_ready")
	}
	if !input.ERPWriteDryRunReady {
		blockers = append(blockers, "erp_write_dry_run_not_ready")
	}
	if !input.AuditObservabilityReady {
		blockers = append(blockers, "audit_observability_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealProviderAPIEnabled {
		blockers = append(blockers, "real_provider_api_must_remain_false_in_data_mapping_phase")
	}
	if input.RealERPWriteEnabled {
		blockers = append(blockers, "real_erp_write_must_remain_false_in_data_mapping_phase")
	}

	if len(blockers) > 0 {
		return ParasutDataMappingReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutDataMappingReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_DATA_MAPPING_ERP_SYNC_DRY_RUN_READY_WITH_REAL_API_CLOSED",
		Blockers: []string{},
	}
}
