package liveready

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	ExportLiveReadyModuleCode = "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE"

	ExportLiveReadyMode = "EXPORT_LIVE_READY_PIPELINE_WITH_REAL_EXPORT_DISABLED"

	ExportLiveReadyStatusReady                = "EXPORT_LIVE_READY_PIPELINE_READY"
	ExportLiveReadyStatusPackagePlanBuilt     = "EXPORT_PACKAGE_PLAN_BUILT_NO_REAL_EXPORT"
	ExportLiveReadyStatusBlocked              = "BLOCKED"
	ExportLiveReadyStatusClosed               = "CLOSED"
	ExportLiveReadyStatusRequirementReady     = "REQUIRED_READY"
	ExportLiveReadyStatusRequirementNotReady  = "REQUIRED_NOT_READY"
	ExportLiveReadyStatusProductionLocked     = "PRODUCTION_EXPORT_LOCKED_IN_FAZ_7_17"
	ExportLiveReadyStatusManifestReady        = "MANIFEST_READY"
	ExportLiveReadyStatusChecksumReady        = "CHECKSUM_READY"
	ExportLiveReadyStatusDeliveryPlanReady    = "DELIVERY_PLAN_READY"
	ExportLiveReadyStatusIdempotent           = "IDEMPOTENT"
	ExportLiveReadyStatusAuditReady           = "AUDIT_READY"
	ExportLiveReadyStatusRollbackReady        = "ROLLBACK_READY"
	ExportLiveReadyStatusSyntheticPayloadOnly = "SYNTHETIC_PAYLOAD_ONLY"

	ExportLiveReadyClosedUntilExportLiveModule    = "CLOSED_UNTIL_EXPORT_LIVE_MODULE"
	ExportLiveReadyClosedUntilProviderLiveModule  = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	ExportLiveReadyClosedUntilFileDeliveryModule  = "CLOSED_UNTIL_FILE_DELIVERY_LIVE_MODULE"
	ExportLiveReadyClosedUntilSyncWorkerModule    = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	ExportLiveReadyClosedUntilApprovalMatrix      = "CLOSED_UNTIL_APPROVAL_MATRIX_PASS"
	ExportLiveReadyClosedUntilCustomerConsentGate = "CLOSED_UNTIL_CUSTOMER_DATA_CONSENT_GATE"

	ExportLiveReadyNoRealExportPolicy         = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_17"
	ExportLiveReadyNoRealFileDeliveryPolicy   = "NO_REAL_FILE_DELIVERY_IN_FAZ_7_17"
	ExportLiveReadyNoRealProviderAPIPolicy    = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_17"
	ExportLiveReadyNoRealERPWritePolicy       = "NO_REAL_ERP_WRITE_IN_FAZ_7_17"
	ExportLiveReadyNoRealCustomerDataPolicy   = "NO_REAL_CUSTOMER_DATA_PAYLOAD_IN_FAZ_7_17"
	ExportLiveReadyNoRealOperatorActionPolicy = "NO_REAL_OPERATOR_EXPORT_ACTION_IN_FAZ_7_17"

	ExportRequirementProviderLiveAdapterReady = "provider_live_adapter_ready"
	ExportRequirementExportSchemaReady        = "export_schema_ready"
	ExportRequirementManifestReady            = "export_manifest_ready"
	ExportRequirementPackageBuilderReady      = "export_package_builder_ready"
	ExportRequirementChecksumReady            = "export_checksum_ready"
	ExportRequirementDeliveryPlanReady        = "export_delivery_plan_ready"
	ExportRequirementCustomerConsentGateReady = "customer_data_consent_gate_ready"
	ExportRequirementIdempotencyReady         = "export_idempotency_ready"
	ExportRequirementRetryDLQReady            = "export_retry_dlq_ready"
	ExportRequirementAuditReady               = "export_audit_ready"
	ExportRequirementRollbackReady            = "export_rollback_ready"
	ExportRequirementLegalApprovalReady       = "legal_approval_gate_ready"
	ExportRequirementFinanceApprovalReady     = "finance_approval_gate_ready"
	ExportRequirementSecurityApprovalReady    = "security_gate_ready"
	ExportRequirementObservabilityReady       = "export_observability_ready"

	ExportFormatParasutDryRun = "PARASUT_EXPORT_DRY_RUN_PACKAGE"
	ExportFormatLogoDryRun    = "LOGO_EXPORT_DRY_RUN_PACKAGE"
	ExportFormatMikroDryRun   = "MIKRO_EXPORT_DRY_RUN_PACKAGE"
	ExportFormatZirveDryRun   = "ZIRVE_EXPORT_DRY_RUN_PACKAGE"
)

var ErrExportLiveReadyRealOperationClosed = errors.New("export live-ready real operation is closed in FAZ 7-17")

type ExportLiveReadyGate struct {
	ProductionExportAllowed       bool `json:"production_export_allowed"`
	RealCustomerDataExportAllowed bool `json:"real_customer_data_export_allowed"`
	RealFileDeliveryAllowed       bool `json:"real_file_delivery_allowed"`
	RealProviderAPICallAllowed    bool `json:"real_provider_api_call_allowed"`
	RealERPWriteAllowed           bool `json:"real_erp_write_allowed"`
	RealOperatorExportAction      bool `json:"real_operator_export_action_allowed"`
	RealCustomerPayloadAllowed    bool `json:"real_customer_payload_allowed"`

	ExportLiveModuleStatus     string `json:"export_live_module_status"`
	ProviderLiveModuleStatus   string `json:"provider_live_module_status"`
	FileDeliveryModuleStatus   string `json:"file_delivery_module_status"`
	SyncWorkerLiveModuleStatus string `json:"sync_worker_live_module_status"`
	ApprovalMatrixStatus       string `json:"approval_matrix_status"`
	CustomerConsentGateStatus  string `json:"customer_consent_gate_status"`
	ProductionExportLock       string `json:"production_export_lock"`
	ControlPlaneGate           string `json:"control_plane_gate"`
	ProviderDryRunSet          string `json:"provider_dry_run_set"`
}

func DefaultExportLiveReadyGate() ExportLiveReadyGate {
	return ExportLiveReadyGate{
		ProductionExportAllowed:       false,
		RealCustomerDataExportAllowed: false,
		RealFileDeliveryAllowed:       false,
		RealProviderAPICallAllowed:    false,
		RealERPWriteAllowed:           false,
		RealOperatorExportAction:      false,
		RealCustomerPayloadAllowed:    false,

		ExportLiveModuleStatus:     ExportLiveReadyStatusReady,
		ProviderLiveModuleStatus:   ExportLiveReadyClosedUntilProviderLiveModule,
		FileDeliveryModuleStatus:   ExportLiveReadyClosedUntilFileDeliveryModule,
		SyncWorkerLiveModuleStatus: ExportLiveReadyClosedUntilSyncWorkerModule,
		ApprovalMatrixStatus:       ExportLiveReadyClosedUntilApprovalMatrix,
		CustomerConsentGateStatus:  ExportLiveReadyClosedUntilCustomerConsentGate,
		ProductionExportLock:       ExportLiveReadyStatusProductionLocked,
		ControlPlaneGate:           CommercialLiveReadyGateReady,
		ProviderDryRunSet:          CommercialLiveReadyProviderDryRunSet,
	}
}

func (g ExportLiveReadyGate) AssertRealExportClosed() error {
	checks := map[string]bool{
		"production_export_allowed":           g.ProductionExportAllowed,
		"real_customer_data_export_allowed":   g.RealCustomerDataExportAllowed,
		"real_file_delivery_allowed":          g.RealFileDeliveryAllowed,
		"real_provider_api_call_allowed":      g.RealProviderAPICallAllowed,
		"real_erp_write_allowed":              g.RealERPWriteAllowed,
		"real_operator_export_action_allowed": g.RealOperatorExportAction,
		"real_customer_payload_allowed":       g.RealCustomerPayloadAllowed,
	}
	for name, value := range checks {
		if value {
			return fmt.Errorf("%s must remain false in FAZ 7-17", name)
		}
	}
	if g.ProductionExportLock != ExportLiveReadyStatusProductionLocked {
		return fmt.Errorf("production export lock must remain %s", ExportLiveReadyStatusProductionLocked)
	}
	return nil
}

type ExportLiveReadyInput struct {
	ProviderLiveAdapterReady bool
	ExportSchemaReady        bool
	ManifestReady            bool
	PackageBuilderReady      bool
	ChecksumReady            bool
	DeliveryPlanReady        bool
	CustomerConsentGateReady bool
	IdempotencyReady         bool
	RetryDLQReady            bool
	AuditReady               bool
	RollbackReady            bool
	LegalApprovalReady       bool
	FinanceApprovalReady     bool
	SecurityApprovalReady    bool
	ObservabilityReady       bool
}

type ExportLiveReadyRequirement struct {
	Code        string `json:"code"`
	Required    bool   `json:"required"`
	Ready       bool   `json:"ready"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type ExportPackagePlanRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	ProviderCode       string
	ExportFormat       string
	PeriodYYYYMM       string
	CorrelationID      string
	IdempotencyKey     string
	DryRunReferenceID  string
	RequestedByUserID  string
}

type ExportManifestItem struct {
	FileName                 string `json:"file_name"`
	FileKind                 string `json:"file_kind"`
	ProviderCode             string `json:"provider_code"`
	ExportFormat             string `json:"export_format"`
	SyntheticPayloadOnly     bool   `json:"synthetic_payload_only"`
	ContainsRealCustomerData bool   `json:"contains_real_customer_data"`
	ChecksumStatus           string `json:"checksum_status"`
	DeliveryStatus           string `json:"delivery_status"`
	ProviderAPIStatus        string `json:"provider_api_status"`
	ERPWriteStatus           string `json:"erp_write_status"`
}

type ExportDeliveryPlan struct {
	DeliveryPlanID         string `json:"delivery_plan_id"`
	DeliveryChannel        string `json:"delivery_channel"`
	RealDeliveryAllowed    bool   `json:"real_delivery_allowed"`
	RealProviderAPIAllowed bool   `json:"real_provider_api_allowed"`
	RealERPWriteAllowed    bool   `json:"real_erp_write_allowed"`
	DeliveryStatus         string `json:"delivery_status"`
	RollbackStatus         string `json:"rollback_status"`
}

type ExportPackagePlan struct {
	PlanID                          string               `json:"plan_id"`
	ModuleCode                      string               `json:"module_code"`
	Mode                            string               `json:"mode"`
	AccountantTenantID              string               `json:"accountant_tenant_id"`
	FirmTenantID                    string               `json:"firm_tenant_id"`
	ProviderCode                    string               `json:"provider_code"`
	ExportFormat                    string               `json:"export_format"`
	PeriodYYYYMM                    string               `json:"period_yyyy_mm"`
	CorrelationID                   string               `json:"correlation_id"`
	IdempotencyKey                  string               `json:"idempotency_key"`
	DryRunReferenceID               string               `json:"dry_run_reference_id"`
	RequestedByUserID               string               `json:"requested_by_user_id"`
	Status                          string               `json:"status"`
	ManifestStatus                  string               `json:"manifest_status"`
	ChecksumStatus                  string               `json:"checksum_status"`
	DeliveryPlanStatus              string               `json:"delivery_plan_status"`
	Manifest                        []ExportManifestItem `json:"manifest"`
	DeliveryPlan                    ExportDeliveryPlan   `json:"delivery_plan"`
	PackageChecksum                 string               `json:"package_checksum"`
	RealCustomerDataExportRequested bool                 `json:"real_customer_data_export_requested"`
	RealCustomerPayloadIncluded     bool                 `json:"real_customer_payload_included"`
	RealFileDeliveryRequested       bool                 `json:"real_file_delivery_requested"`
	RealProviderAPICallRequested    bool                 `json:"real_provider_api_call_requested"`
	RealERPWriteRequested           bool                 `json:"real_erp_write_requested"`
	RealOperatorExportAction        bool                 `json:"real_operator_export_action"`
	LiveOperationPolicy             string               `json:"live_operation_policy"`
	CreatedAt                       time.Time            `json:"created_at"`
}

type ExportLiveReadyReport struct {
	ModuleCode                    string                       `json:"module_code"`
	Mode                          string                       `json:"mode"`
	Status                        string                       `json:"status"`
	Gate                          ExportLiveReadyGate          `json:"gate"`
	Requirements                  []ExportLiveReadyRequirement `json:"requirements"`
	SupportedProviders            []string                     `json:"supported_providers"`
	SupportedFormats              []string                     `json:"supported_formats"`
	LiveOperationPolicies         map[string]string            `json:"live_operation_policies"`
	ProductionExportAllowed       bool                         `json:"production_export_allowed"`
	RealCustomerDataExportAllowed bool                         `json:"real_customer_data_export_allowed"`
	RealFileDeliveryAllowed       bool                         `json:"real_file_delivery_allowed"`
	RealProviderAPICallAllowed    bool                         `json:"real_provider_api_call_allowed"`
	RealERPWriteAllowed           bool                         `json:"real_erp_write_allowed"`
	NextModule                    string                       `json:"next_module"`
	CreatedAt                     time.Time                    `json:"created_at"`
}

type ExportLiveReadyAuditEvent struct {
	EventCode          string    `json:"event_code"`
	AccountantTenantID string    `json:"accountant_tenant_id,omitempty"`
	FirmTenantID       string    `json:"firm_tenant_id,omitempty"`
	ProviderCode       string    `json:"provider_code,omitempty"`
	Status             string    `json:"status"`
	Reason             string    `json:"reason,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
}

type ExportLiveReadyRuntime struct {
	gate        ExportLiveReadyGate
	plans       map[string]ExportPackagePlan
	auditEvents []ExportLiveReadyAuditEvent
	now         func() time.Time
}

func NewDefaultExportLiveReadyRuntime() *ExportLiveReadyRuntime {
	return &ExportLiveReadyRuntime{
		gate:        DefaultExportLiveReadyGate(),
		plans:       map[string]ExportPackagePlan{},
		auditEvents: []ExportLiveReadyAuditEvent{},
		now:         time.Now,
	}
}

func (r *ExportLiveReadyRuntime) BuildExportLiveReadyReport(input ExportLiveReadyInput) (ExportLiveReadyReport, error) {
	if err := r.gate.AssertRealExportClosed(); err != nil {
		r.appendAudit("EXPORT_LIVE_READY_REPORT_DENIED", "", "", "", ExportLiveReadyStatusBlocked, err.Error())
		return ExportLiveReadyReport{}, err
	}
	report := ExportLiveReadyReport{
		ModuleCode:                    ExportLiveReadyModuleCode,
		Mode:                          ExportLiveReadyMode,
		Status:                        ExportLiveReadyStatusReady,
		Gate:                          r.gate,
		Requirements:                  BuildExportLiveReadyRequirements(input),
		SupportedProviders:            SupportedExportLiveReadyProviders(),
		SupportedFormats:              SupportedExportLiveReadyFormats(),
		LiveOperationPolicies:         DefaultExportLiveReadyPolicies(),
		ProductionExportAllowed:       false,
		RealCustomerDataExportAllowed: false,
		RealFileDeliveryAllowed:       false,
		RealProviderAPICallAllowed:    false,
		RealERPWriteAllowed:           false,
		NextModule:                    "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME",
		CreatedAt:                     r.now().UTC(),
	}
	r.appendAudit("EXPORT_LIVE_READY_REPORT_BUILT", "", "", "", ExportLiveReadyStatusReady, "")
	return report, nil
}

func (r *ExportLiveReadyRuntime) BuildExportPackagePlan(req ExportPackagePlanRequest) (ExportPackagePlan, error) {
	if err := r.gate.AssertRealExportClosed(); err != nil {
		r.appendAudit("EXPORT_PACKAGE_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, req.ProviderCode, ExportLiveReadyStatusBlocked, err.Error())
		return ExportPackagePlan{}, err
	}
	if err := validateExportPackagePlanRequest(req); err != nil {
		r.appendAudit("EXPORT_PACKAGE_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, req.ProviderCode, ExportLiveReadyStatusBlocked, err.Error())
		return ExportPackagePlan{}, err
	}
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	format := normalizeExportFormat(provider, req.ExportFormat)
	key := exportPackagePlanKey(req.AccountantTenantID, req.FirmTenantID, provider, req.PeriodYYYYMM, req.IdempotencyKey)
	if existing, ok := r.plans[key]; ok {
		r.appendAudit("EXPORT_PACKAGE_PLAN_IDEMPOTENCY_REPLAY", req.AccountantTenantID, req.FirmTenantID, provider, ExportLiveReadyStatusIdempotent, "")
		return existing, nil
	}
	manifest := buildSyntheticExportManifest(provider, format)
	planID := exportLiveReadyID("EXPORT-PACKAGE-PLAN", req.AccountantTenantID, req.FirmTenantID, provider, req.PeriodYYYYMM, req.IdempotencyKey)
	checksum := exportChecksum(planID + "|" + req.DryRunReferenceID + "|" + provider + "|" + format)
	plan := ExportPackagePlan{
		PlanID:                          planID,
		ModuleCode:                      ExportLiveReadyModuleCode,
		Mode:                            ExportLiveReadyMode,
		AccountantTenantID:              req.AccountantTenantID,
		FirmTenantID:                    req.FirmTenantID,
		ProviderCode:                    provider,
		ExportFormat:                    format,
		PeriodYYYYMM:                    req.PeriodYYYYMM,
		CorrelationID:                   req.CorrelationID,
		IdempotencyKey:                  req.IdempotencyKey,
		DryRunReferenceID:               req.DryRunReferenceID,
		RequestedByUserID:               req.RequestedByUserID,
		Status:                          ExportLiveReadyStatusPackagePlanBuilt,
		ManifestStatus:                  ExportLiveReadyStatusManifestReady,
		ChecksumStatus:                  ExportLiveReadyStatusChecksumReady,
		DeliveryPlanStatus:              ExportLiveReadyStatusDeliveryPlanReady,
		Manifest:                        manifest,
		DeliveryPlan:                    buildExportDeliveryPlan(planID),
		PackageChecksum:                 checksum,
		RealCustomerDataExportRequested: false,
		RealCustomerPayloadIncluded:     false,
		RealFileDeliveryRequested:       false,
		RealProviderAPICallRequested:    false,
		RealERPWriteRequested:           false,
		RealOperatorExportAction:        false,
		LiveOperationPolicy:             ExportLiveReadyNoRealExportPolicy,
		CreatedAt:                       r.now().UTC(),
	}
	r.plans[key] = plan
	r.appendAudit("EXPORT_PACKAGE_PLAN_BUILT", req.AccountantTenantID, req.FirmTenantID, provider, ExportLiveReadyStatusPackagePlanBuilt, "")
	return plan, nil
}

func (r *ExportLiveReadyRuntime) RequestRealCustomerDataExport() error {
	r.appendAudit("EXPORT_REAL_CUSTOMER_DATA_EXPORT_BLOCKED", "", "", "", ExportLiveReadyStatusClosed, ExportLiveReadyNoRealExportPolicy)
	return ErrExportLiveReadyRealOperationClosed
}

func (r *ExportLiveReadyRuntime) RequestRealFileDelivery(providerCode string) error {
	r.appendAudit("EXPORT_REAL_FILE_DELIVERY_BLOCKED", "", "", providerCode, ExportLiveReadyStatusClosed, ExportLiveReadyNoRealFileDeliveryPolicy)
	return ErrExportLiveReadyRealOperationClosed
}

func (r *ExportLiveReadyRuntime) RequestRealProviderAPI(providerCode string) error {
	r.appendAudit("EXPORT_REAL_PROVIDER_API_BLOCKED", "", "", providerCode, ExportLiveReadyStatusClosed, ExportLiveReadyNoRealProviderAPIPolicy)
	return ErrExportLiveReadyRealOperationClosed
}

func (r *ExportLiveReadyRuntime) RequestRealERPWrite(providerCode string) error {
	r.appendAudit("EXPORT_REAL_ERP_WRITE_BLOCKED", "", "", providerCode, ExportLiveReadyStatusClosed, ExportLiveReadyNoRealERPWritePolicy)
	return ErrExportLiveReadyRealOperationClosed
}

func (r *ExportLiveReadyRuntime) RequestRealOperatorExportAction(providerCode string) error {
	r.appendAudit("EXPORT_REAL_OPERATOR_ACTION_BLOCKED", "", "", providerCode, ExportLiveReadyStatusClosed, ExportLiveReadyNoRealOperatorActionPolicy)
	return ErrExportLiveReadyRealOperationClosed
}

func (r *ExportLiveReadyRuntime) Gate() ExportLiveReadyGate {
	return r.gate
}

func (r *ExportLiveReadyRuntime) AuditEvents() []ExportLiveReadyAuditEvent {
	out := make([]ExportLiveReadyAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *ExportLiveReadyRuntime) appendAudit(code, accountantTenantID, firmTenantID, providerCode, status, reason string) {
	r.auditEvents = append(r.auditEvents, ExportLiveReadyAuditEvent{
		EventCode:          code,
		AccountantTenantID: accountantTenantID,
		FirmTenantID:       firmTenantID,
		ProviderCode:       strings.ToUpper(strings.TrimSpace(providerCode)),
		Status:             status,
		Reason:             reason,
		CreatedAt:          r.now().UTC(),
	})
}

func BuildExportLiveReadyRequirements(input ExportLiveReadyInput) []ExportLiveReadyRequirement {
	requirements := []ExportLiveReadyRequirement{
		exportRequirement(ExportRequirementProviderLiveAdapterReady, input.ProviderLiveAdapterReady, "provider live adapter readiness is prepared"),
		exportRequirement(ExportRequirementExportSchemaReady, input.ExportSchemaReady, "export schema contract is prepared"),
		exportRequirement(ExportRequirementManifestReady, input.ManifestReady, "export manifest is prepared"),
		exportRequirement(ExportRequirementPackageBuilderReady, input.PackageBuilderReady, "export package builder is prepared"),
		exportRequirement(ExportRequirementChecksumReady, input.ChecksumReady, "checksum and integrity guard is prepared"),
		exportRequirement(ExportRequirementDeliveryPlanReady, input.DeliveryPlanReady, "delivery plan is prepared"),
		exportRequirement(ExportRequirementCustomerConsentGateReady, input.CustomerConsentGateReady, "customer data consent gate is modeled"),
		exportRequirement(ExportRequirementIdempotencyReady, input.IdempotencyReady, "export idempotency is prepared"),
		exportRequirement(ExportRequirementRetryDLQReady, input.RetryDLQReady, "export retry and DLQ policy is prepared"),
		exportRequirement(ExportRequirementAuditReady, input.AuditReady, "export audit trail is prepared"),
		exportRequirement(ExportRequirementRollbackReady, input.RollbackReady, "export rollback is prepared"),
		exportRequirement(ExportRequirementLegalApprovalReady, input.LegalApprovalReady, "legal approval gate is modeled"),
		exportRequirement(ExportRequirementFinanceApprovalReady, input.FinanceApprovalReady, "finance approval gate is modeled"),
		exportRequirement(ExportRequirementSecurityApprovalReady, input.SecurityApprovalReady, "security gate is modeled"),
		exportRequirement(ExportRequirementObservabilityReady, input.ObservabilityReady, "export observability is prepared"),
	}
	sort.Slice(requirements, func(i, j int) bool {
		return requirements[i].Code < requirements[j].Code
	})
	return requirements
}

func MissingExportLiveReadyRequirements(input ExportLiveReadyInput) []string {
	missing := []string{}
	for _, req := range BuildExportLiveReadyRequirements(input) {
		if req.Required && !req.Ready {
			missing = append(missing, req.Code)
		}
	}
	sort.Strings(missing)
	return missing
}

func AllExportLiveReadyInput() ExportLiveReadyInput {
	return ExportLiveReadyInput{
		ProviderLiveAdapterReady: true,
		ExportSchemaReady:        true,
		ManifestReady:            true,
		PackageBuilderReady:      true,
		ChecksumReady:            true,
		DeliveryPlanReady:        true,
		CustomerConsentGateReady: true,
		IdempotencyReady:         true,
		RetryDLQReady:            true,
		AuditReady:               true,
		RollbackReady:            true,
		LegalApprovalReady:       true,
		FinanceApprovalReady:     true,
		SecurityApprovalReady:    true,
		ObservabilityReady:       true,
	}
}

func SupportedExportLiveReadyProviders() []string {
	return []string{ProviderCodeLogo, ProviderCodeMikro, ProviderCodeParasut, ProviderCodeZirve}
}

func SupportedExportLiveReadyFormats() []string {
	return []string{
		ExportFormatLogoDryRun,
		ExportFormatMikroDryRun,
		ExportFormatParasutDryRun,
		ExportFormatZirveDryRun,
	}
}

func DefaultExportLiveReadyPolicies() map[string]string {
	return map[string]string{
		"customer_data_export": ExportLiveReadyNoRealExportPolicy,
		"file_delivery":        ExportLiveReadyNoRealFileDeliveryPolicy,
		"provider_api":         ExportLiveReadyNoRealProviderAPIPolicy,
		"erp_write":            ExportLiveReadyNoRealERPWritePolicy,
		"customer_payload":     ExportLiveReadyNoRealCustomerDataPolicy,
		"operator_action":      ExportLiveReadyNoRealOperatorActionPolicy,
	}
}

func validateExportPackagePlanRequest(req ExportPackagePlanRequest) error {
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	if !isLiveReadyProvider(provider) {
		return errors.New("unsupported provider code")
	}
	if strings.TrimSpace(req.AccountantTenantID) == "" {
		return errors.New("accountant tenant id is required")
	}
	if strings.TrimSpace(req.FirmTenantID) == "" {
		return errors.New("firm tenant id is required")
	}
	if len(req.PeriodYYYYMM) != 7 || req.PeriodYYYYMM[4] != '-' {
		return errors.New("period must use YYYY-MM format")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency key is required")
	}
	if strings.TrimSpace(req.DryRunReferenceID) == "" {
		return errors.New("dry-run reference id is required")
	}
	if strings.TrimSpace(req.RequestedByUserID) == "" {
		return errors.New("requested by user id is required")
	}
	return nil
}

func normalizeExportFormat(provider, format string) string {
	format = strings.ToUpper(strings.TrimSpace(format))
	if format != "" {
		return format
	}
	switch provider {
	case ProviderCodeParasut:
		return ExportFormatParasutDryRun
	case ProviderCodeLogo:
		return ExportFormatLogoDryRun
	case ProviderCodeMikro:
		return ExportFormatMikroDryRun
	case ProviderCodeZirve:
		return ExportFormatZirveDryRun
	default:
		return "UNKNOWN_EXPORT_DRY_RUN_PACKAGE"
	}
}

func buildSyntheticExportManifest(provider, format string) []ExportManifestItem {
	items := []ExportManifestItem{
		{
			FileName:                 strings.ToLower(provider) + "_manifest_preview.json",
			FileKind:                 "MANIFEST_PREVIEW",
			ProviderCode:             provider,
			ExportFormat:             format,
			SyntheticPayloadOnly:     true,
			ContainsRealCustomerData: false,
			ChecksumStatus:           ExportLiveReadyStatusChecksumReady,
			DeliveryStatus:           ExportLiveReadyClosedUntilFileDeliveryModule,
			ProviderAPIStatus:        ExportLiveReadyClosedUntilProviderLiveModule,
			ERPWriteStatus:           ExportLiveReadyClosedUntilSyncWorkerModule,
		},
		{
			FileName:                 strings.ToLower(provider) + "_export_payload_preview.txt",
			FileKind:                 "EXPORT_PAYLOAD_PREVIEW",
			ProviderCode:             provider,
			ExportFormat:             format,
			SyntheticPayloadOnly:     true,
			ContainsRealCustomerData: false,
			ChecksumStatus:           ExportLiveReadyStatusChecksumReady,
			DeliveryStatus:           ExportLiveReadyClosedUntilFileDeliveryModule,
			ProviderAPIStatus:        ExportLiveReadyClosedUntilProviderLiveModule,
			ERPWriteStatus:           ExportLiveReadyClosedUntilSyncWorkerModule,
		},
	}
	sort.Slice(items, func(i, j int) bool {
		return items[i].FileName < items[j].FileName
	})
	return items
}

func buildExportDeliveryPlan(planID string) ExportDeliveryPlan {
	return ExportDeliveryPlan{
		DeliveryPlanID:         exportLiveReadyID("EXPORT-DELIVERY-PLAN", planID),
		DeliveryChannel:        "LOCAL_DRY_RUN_PACKAGE_ONLY",
		RealDeliveryAllowed:    false,
		RealProviderAPIAllowed: false,
		RealERPWriteAllowed:    false,
		DeliveryStatus:         ExportLiveReadyClosedUntilFileDeliveryModule,
		RollbackStatus:         ExportLiveReadyStatusRollbackReady,
	}
}

func exportRequirement(code string, ready bool, description string) ExportLiveReadyRequirement {
	status := ExportLiveReadyStatusRequirementNotReady
	if ready {
		status = ExportLiveReadyStatusRequirementReady
	}
	return ExportLiveReadyRequirement{
		Code:        code,
		Required:    true,
		Ready:       ready,
		Status:      status,
		Description: description,
	}
}

func exportPackagePlanKey(accountantTenantID, firmTenantID, provider, period, idempotencyKey string) string {
	return accountantTenantID + "|" + firmTenantID + "|" + provider + "|" + period + "|" + idempotencyKey
}

func exportChecksum(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

func exportLiveReadyID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
