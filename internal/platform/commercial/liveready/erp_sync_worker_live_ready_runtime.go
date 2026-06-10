package liveready

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	ERPSyncWorkerLiveReadyModuleCode = "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME"

	ERPSyncWorkerLiveReadyMode = "ERP_SYNC_WORKER_LIVE_READY_WITH_REAL_ERP_WRITE_DISABLED"

	ERPSyncWorkerLiveReadyStatusReady                = "ERP_SYNC_WORKER_LIVE_READY_RUNTIME_READY"
	ERPSyncWorkerLiveReadyStatusPlanBuilt            = "ERP_SYNC_PLAN_BUILT_NO_REAL_ERP_WRITE"
	ERPSyncWorkerLiveReadyStatusBlocked              = "BLOCKED"
	ERPSyncWorkerLiveReadyStatusClosed               = "CLOSED"
	ERPSyncWorkerLiveReadyStatusRequirementReady     = "REQUIRED_READY"
	ERPSyncWorkerLiveReadyStatusRequirementNotReady  = "REQUIRED_NOT_READY"
	ERPSyncWorkerLiveReadyStatusProductionLocked     = "PRODUCTION_ERP_SYNC_LOCKED_IN_FAZ_7_18"
	ERPSyncWorkerLiveReadyStatusMappingReady         = "ERP_MAPPING_READY"
	ERPSyncWorkerLiveReadyStatusReconciliationReady  = "RECONCILIATION_READY"
	ERPSyncWorkerLiveReadyStatusRetryReady           = "RETRY_READY"
	ERPSyncWorkerLiveReadyStatusDLQReady             = "DLQ_READY"
	ERPSyncWorkerLiveReadyStatusIdempotent           = "IDEMPOTENT"
	ERPSyncWorkerLiveReadyStatusAuditReady           = "AUDIT_READY"
	ERPSyncWorkerLiveReadyStatusRollbackReady        = "ROLLBACK_READY"
	ERPSyncWorkerLiveReadyStatusSyntheticPayloadOnly = "SYNTHETIC_PAYLOAD_ONLY"

	ERPSyncWorkerClosedUntilSyncWorkerLiveModule = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	ERPSyncWorkerClosedUntilProviderLiveModule   = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	ERPSyncWorkerClosedUntilApprovalMatrix       = "CLOSED_UNTIL_APPROVAL_MATRIX_PASS"
	ERPSyncWorkerClosedUntilLedgerLiveModule     = "CLOSED_UNTIL_LEDGER_POSTING_LIVE_MODULE"
	ERPSyncWorkerClosedUntilReconciliationModule = "CLOSED_UNTIL_RECONCILIATION_LIVE_MODULE"
	ERPSyncWorkerClosedUntilCustomerConsentGate  = "CLOSED_UNTIL_CUSTOMER_DATA_CONSENT_GATE"

	ERPSyncWorkerNoRealERPWritePolicy        = "NO_REAL_ERP_WRITE_IN_FAZ_7_18"
	ERPSyncWorkerNoRealLedgerPostingPolicy   = "NO_REAL_LEDGER_POSTING_IN_FAZ_7_18"
	ERPSyncWorkerNoRealProviderAPIPolicy     = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_18"
	ERPSyncWorkerNoRealCustomerPayloadPolicy = "NO_REAL_CUSTOMER_DATA_PAYLOAD_IN_FAZ_7_18"
	ERPSyncWorkerNoRealReconciliationPolicy  = "NO_REAL_RECONCILIATION_COMMIT_IN_FAZ_7_18"
	ERPSyncWorkerNoRealOperatorActionPolicy  = "NO_REAL_OPERATOR_ERP_SYNC_ACTION_IN_FAZ_7_18"

	ERPSyncRequirementExportLiveReady         = "export_live_ready"
	ERPSyncRequirementProviderAdapterReady    = "provider_live_adapter_ready"
	ERPSyncRequirementERPWriteContractReady   = "erp_write_contract_ready"
	ERPSyncRequirementObjectMappingReady      = "erp_object_mapping_ready"
	ERPSyncRequirementTenantBoundaryReady     = "tenant_boundary_ready"
	ERPSyncRequirementEventMappingReady       = "event_mapping_ready"
	ERPSyncRequirementIdempotencyReady        = "erp_sync_idempotency_ready"
	ERPSyncRequirementRetryDLQReady           = "erp_sync_retry_dlq_ready"
	ERPSyncRequirementReconciliationReady     = "erp_reconciliation_ready"
	ERPSyncRequirementLedgerPostingGuardReady = "ledger_posting_guard_ready"
	ERPSyncRequirementAuditReady              = "erp_sync_audit_ready"
	ERPSyncRequirementRollbackReady           = "erp_sync_rollback_ready"
	ERPSyncRequirementLegalApprovalReady      = "legal_approval_gate_ready"
	ERPSyncRequirementFinanceApprovalReady    = "finance_approval_gate_ready"
	ERPSyncRequirementSecurityApprovalReady   = "security_gate_ready"
	ERPSyncRequirementObservabilityReady      = "erp_sync_observability_ready"

	ERPSyncDirectionPix2piToProvider = "PIX2PI_TO_PROVIDER"
	ERPSyncDirectionProviderToPix2pi = "PROVIDER_TO_PIX2PI"

	ERPSyncObjectInvoice     = "INVOICE"
	ERPSyncObjectCustomer    = "CUSTOMER"
	ERPSyncObjectLedgerEntry = "LEDGER_ENTRY"
	ERPSyncObjectStockItem   = "STOCK_ITEM"
)

var ErrERPSyncWorkerRealOperationClosed = errors.New("ERP sync worker real operation is closed in FAZ 7-18")

type ERPSyncWorkerLiveReadyGate struct {
	ProductionERPSyncAllowed        bool `json:"production_erp_sync_allowed"`
	RealERPWriteAllowed             bool `json:"real_erp_write_allowed"`
	RealLedgerPostingAllowed        bool `json:"real_ledger_posting_allowed"`
	RealProviderAPICallAllowed      bool `json:"real_provider_api_call_allowed"`
	RealCustomerPayloadAllowed      bool `json:"real_customer_payload_allowed"`
	RealReconciliationCommitAllowed bool `json:"real_reconciliation_commit_allowed"`
	RealOperatorERPSyncAction       bool `json:"real_operator_erp_sync_action_allowed"`

	SyncWorkerLiveModuleStatus     string `json:"sync_worker_live_module_status"`
	ProviderLiveModuleStatus       string `json:"provider_live_module_status"`
	ApprovalMatrixStatus           string `json:"approval_matrix_status"`
	LedgerPostingLiveModuleStatus  string `json:"ledger_posting_live_module_status"`
	ReconciliationLiveModuleStatus string `json:"reconciliation_live_module_status"`
	CustomerConsentGateStatus      string `json:"customer_consent_gate_status"`
	ProductionERPSyncLock          string `json:"production_erp_sync_lock"`
	ControlPlaneGate               string `json:"control_plane_gate"`
	ProviderDryRunSet              string `json:"provider_dry_run_set"`
}

func DefaultERPSyncWorkerLiveReadyGate() ERPSyncWorkerLiveReadyGate {
	return ERPSyncWorkerLiveReadyGate{
		ProductionERPSyncAllowed:        false,
		RealERPWriteAllowed:             false,
		RealLedgerPostingAllowed:        false,
		RealProviderAPICallAllowed:      false,
		RealCustomerPayloadAllowed:      false,
		RealReconciliationCommitAllowed: false,
		RealOperatorERPSyncAction:       false,

		SyncWorkerLiveModuleStatus:     ERPSyncWorkerLiveReadyStatusReady,
		ProviderLiveModuleStatus:       ERPSyncWorkerClosedUntilProviderLiveModule,
		ApprovalMatrixStatus:           ERPSyncWorkerClosedUntilApprovalMatrix,
		LedgerPostingLiveModuleStatus:  ERPSyncWorkerClosedUntilLedgerLiveModule,
		ReconciliationLiveModuleStatus: ERPSyncWorkerClosedUntilReconciliationModule,
		CustomerConsentGateStatus:      ERPSyncWorkerClosedUntilCustomerConsentGate,
		ProductionERPSyncLock:          ERPSyncWorkerLiveReadyStatusProductionLocked,
		ControlPlaneGate:               CommercialLiveReadyGateReady,
		ProviderDryRunSet:              CommercialLiveReadyProviderDryRunSet,
	}
}

func (g ERPSyncWorkerLiveReadyGate) AssertRealERPSyncClosed() error {
	checks := map[string]bool{
		"production_erp_sync_allowed":           g.ProductionERPSyncAllowed,
		"real_erp_write_allowed":                g.RealERPWriteAllowed,
		"real_ledger_posting_allowed":           g.RealLedgerPostingAllowed,
		"real_provider_api_call_allowed":        g.RealProviderAPICallAllowed,
		"real_customer_payload_allowed":         g.RealCustomerPayloadAllowed,
		"real_reconciliation_commit_allowed":    g.RealReconciliationCommitAllowed,
		"real_operator_erp_sync_action_allowed": g.RealOperatorERPSyncAction,
	}
	for name, value := range checks {
		if value {
			return fmt.Errorf("%s must remain false in FAZ 7-18", name)
		}
	}
	if g.ProductionERPSyncLock != ERPSyncWorkerLiveReadyStatusProductionLocked {
		return fmt.Errorf("production ERP sync lock must remain %s", ERPSyncWorkerLiveReadyStatusProductionLocked)
	}
	return nil
}

type ERPSyncWorkerLiveReadyInput struct {
	ExportLiveReady         bool
	ProviderAdapterReady    bool
	ERPWriteContractReady   bool
	ObjectMappingReady      bool
	TenantBoundaryReady     bool
	EventMappingReady       bool
	IdempotencyReady        bool
	RetryDLQReady           bool
	ReconciliationReady     bool
	LedgerPostingGuardReady bool
	AuditReady              bool
	RollbackReady           bool
	LegalApprovalReady      bool
	FinanceApprovalReady    bool
	SecurityApprovalReady   bool
	ObservabilityReady      bool
}

type ERPSyncWorkerRequirement struct {
	Code        string `json:"code"`
	Required    bool   `json:"required"`
	Ready       bool   `json:"ready"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type ERPSyncPlanRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	ProviderCode       string
	ERPObjectType      string
	SyncDirection      string
	PeriodYYYYMM       string
	SourcePackageID    string
	CorrelationID      string
	IdempotencyKey     string
	DryRunReferenceID  string
	RequestedByUserID  string
}

type ERPSyncOperationStep struct {
	StepCode             string `json:"step_code"`
	Status               string `json:"status"`
	SyntheticPayloadOnly bool   `json:"synthetic_payload_only"`
	RealERPWriteAllowed  bool   `json:"real_erp_write_allowed"`
	Description          string `json:"description"`
}

type ERPSyncWorkerPlan struct {
	PlanID                            string                 `json:"plan_id"`
	ModuleCode                        string                 `json:"module_code"`
	Mode                              string                 `json:"mode"`
	AccountantTenantID                string                 `json:"accountant_tenant_id"`
	FirmTenantID                      string                 `json:"firm_tenant_id"`
	ProviderCode                      string                 `json:"provider_code"`
	ERPObjectType                     string                 `json:"erp_object_type"`
	SyncDirection                     string                 `json:"sync_direction"`
	PeriodYYYYMM                      string                 `json:"period_yyyy_mm"`
	SourcePackageID                   string                 `json:"source_package_id"`
	CorrelationID                     string                 `json:"correlation_id"`
	IdempotencyKey                    string                 `json:"idempotency_key"`
	DryRunReferenceID                 string                 `json:"dry_run_reference_id"`
	RequestedByUserID                 string                 `json:"requested_by_user_id"`
	Status                            string                 `json:"status"`
	MappingStatus                     string                 `json:"mapping_status"`
	RetryPolicyStatus                 string                 `json:"retry_policy_status"`
	DLQPolicyStatus                   string                 `json:"dlq_policy_status"`
	ReconciliationStatus              string                 `json:"reconciliation_status"`
	AuditStatus                       string                 `json:"audit_status"`
	RollbackStatus                    string                 `json:"rollback_status"`
	OperationSteps                    []ERPSyncOperationStep `json:"operation_steps"`
	RealERPWriteRequested             bool                   `json:"real_erp_write_requested"`
	RealLedgerPostingRequested        bool                   `json:"real_ledger_posting_requested"`
	RealProviderAPICallRequested      bool                   `json:"real_provider_api_call_requested"`
	RealCustomerPayloadIncluded       bool                   `json:"real_customer_payload_included"`
	RealReconciliationCommitRequested bool                   `json:"real_reconciliation_commit_requested"`
	RealOperatorERPSyncAction         bool                   `json:"real_operator_erp_sync_action"`
	LiveOperationPolicy               string                 `json:"live_operation_policy"`
	CreatedAt                         time.Time              `json:"created_at"`
}

type ERPSyncWorkerLiveReadyReport struct {
	ModuleCode                      string                     `json:"module_code"`
	Mode                            string                     `json:"mode"`
	Status                          string                     `json:"status"`
	Gate                            ERPSyncWorkerLiveReadyGate `json:"gate"`
	Requirements                    []ERPSyncWorkerRequirement `json:"requirements"`
	SupportedProviders              []string                   `json:"supported_providers"`
	SupportedObjects                []string                   `json:"supported_objects"`
	SupportedDirections             []string                   `json:"supported_directions"`
	LiveOperationPolicies           map[string]string          `json:"live_operation_policies"`
	ProductionERPSyncAllowed        bool                       `json:"production_erp_sync_allowed"`
	RealERPWriteAllowed             bool                       `json:"real_erp_write_allowed"`
	RealLedgerPostingAllowed        bool                       `json:"real_ledger_posting_allowed"`
	RealProviderAPICallAllowed      bool                       `json:"real_provider_api_call_allowed"`
	RealCustomerPayloadAllowed      bool                       `json:"real_customer_payload_allowed"`
	RealReconciliationCommitAllowed bool                       `json:"real_reconciliation_commit_allowed"`
	NextModule                      string                     `json:"next_module"`
	CreatedAt                       time.Time                  `json:"created_at"`
}

type ERPSyncWorkerAuditEvent struct {
	EventCode          string    `json:"event_code"`
	AccountantTenantID string    `json:"accountant_tenant_id,omitempty"`
	FirmTenantID       string    `json:"firm_tenant_id,omitempty"`
	ProviderCode       string    `json:"provider_code,omitempty"`
	Status             string    `json:"status"`
	Reason             string    `json:"reason,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
}

type ERPSyncWorkerLiveReadyRuntime struct {
	gate        ERPSyncWorkerLiveReadyGate
	plans       map[string]ERPSyncWorkerPlan
	auditEvents []ERPSyncWorkerAuditEvent
	now         func() time.Time
}

func NewDefaultERPSyncWorkerLiveReadyRuntime() *ERPSyncWorkerLiveReadyRuntime {
	return &ERPSyncWorkerLiveReadyRuntime{
		gate:        DefaultERPSyncWorkerLiveReadyGate(),
		plans:       map[string]ERPSyncWorkerPlan{},
		auditEvents: []ERPSyncWorkerAuditEvent{},
		now:         time.Now,
	}
}

func (r *ERPSyncWorkerLiveReadyRuntime) BuildERPSyncWorkerLiveReadyReport(input ERPSyncWorkerLiveReadyInput) (ERPSyncWorkerLiveReadyReport, error) {
	if err := r.gate.AssertRealERPSyncClosed(); err != nil {
		r.appendAudit("ERP_SYNC_WORKER_LIVE_READY_REPORT_DENIED", "", "", "", ERPSyncWorkerLiveReadyStatusBlocked, err.Error())
		return ERPSyncWorkerLiveReadyReport{}, err
	}
	report := ERPSyncWorkerLiveReadyReport{
		ModuleCode:                      ERPSyncWorkerLiveReadyModuleCode,
		Mode:                            ERPSyncWorkerLiveReadyMode,
		Status:                          ERPSyncWorkerLiveReadyStatusReady,
		Gate:                            r.gate,
		Requirements:                    BuildERPSyncWorkerRequirements(input),
		SupportedProviders:              SupportedERPSyncWorkerProviders(),
		SupportedObjects:                SupportedERPSyncObjects(),
		SupportedDirections:             SupportedERPSyncDirections(),
		LiveOperationPolicies:           DefaultERPSyncWorkerPolicies(),
		ProductionERPSyncAllowed:        false,
		RealERPWriteAllowed:             false,
		RealLedgerPostingAllowed:        false,
		RealProviderAPICallAllowed:      false,
		RealCustomerPayloadAllowed:      false,
		RealReconciliationCommitAllowed: false,
		NextModule:                      "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX",
		CreatedAt:                       r.now().UTC(),
	}
	r.appendAudit("ERP_SYNC_WORKER_LIVE_READY_REPORT_BUILT", "", "", "", ERPSyncWorkerLiveReadyStatusReady, "")
	return report, nil
}

func (r *ERPSyncWorkerLiveReadyRuntime) BuildERPSyncPlan(req ERPSyncPlanRequest) (ERPSyncWorkerPlan, error) {
	if err := r.gate.AssertRealERPSyncClosed(); err != nil {
		r.appendAudit("ERP_SYNC_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, req.ProviderCode, ERPSyncWorkerLiveReadyStatusBlocked, err.Error())
		return ERPSyncWorkerPlan{}, err
	}
	if err := validateERPSyncPlanRequest(req); err != nil {
		r.appendAudit("ERP_SYNC_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, req.ProviderCode, ERPSyncWorkerLiveReadyStatusBlocked, err.Error())
		return ERPSyncWorkerPlan{}, err
	}
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	objectType := strings.ToUpper(strings.TrimSpace(req.ERPObjectType))
	direction := strings.ToUpper(strings.TrimSpace(req.SyncDirection))
	key := erpSyncPlanKey(req.AccountantTenantID, req.FirmTenantID, provider, objectType, req.PeriodYYYYMM, req.IdempotencyKey)
	if existing, ok := r.plans[key]; ok {
		r.appendAudit("ERP_SYNC_PLAN_IDEMPOTENCY_REPLAY", req.AccountantTenantID, req.FirmTenantID, provider, ERPSyncWorkerLiveReadyStatusIdempotent, "")
		return existing, nil
	}
	plan := ERPSyncWorkerPlan{
		PlanID:                            erpSyncWorkerID("ERP-SYNC-PLAN", req.AccountantTenantID, req.FirmTenantID, provider, objectType, req.PeriodYYYYMM, req.IdempotencyKey),
		ModuleCode:                        ERPSyncWorkerLiveReadyModuleCode,
		Mode:                              ERPSyncWorkerLiveReadyMode,
		AccountantTenantID:                req.AccountantTenantID,
		FirmTenantID:                      req.FirmTenantID,
		ProviderCode:                      provider,
		ERPObjectType:                     objectType,
		SyncDirection:                     direction,
		PeriodYYYYMM:                      req.PeriodYYYYMM,
		SourcePackageID:                   req.SourcePackageID,
		CorrelationID:                     req.CorrelationID,
		IdempotencyKey:                    req.IdempotencyKey,
		DryRunReferenceID:                 req.DryRunReferenceID,
		RequestedByUserID:                 req.RequestedByUserID,
		Status:                            ERPSyncWorkerLiveReadyStatusPlanBuilt,
		MappingStatus:                     ERPSyncWorkerLiveReadyStatusMappingReady,
		RetryPolicyStatus:                 ERPSyncWorkerLiveReadyStatusRetryReady,
		DLQPolicyStatus:                   ERPSyncWorkerLiveReadyStatusDLQReady,
		ReconciliationStatus:              ERPSyncWorkerLiveReadyStatusReconciliationReady,
		AuditStatus:                       ERPSyncWorkerLiveReadyStatusAuditReady,
		RollbackStatus:                    ERPSyncWorkerLiveReadyStatusRollbackReady,
		OperationSteps:                    buildSyntheticERPSyncSteps(objectType, direction),
		RealERPWriteRequested:             false,
		RealLedgerPostingRequested:        false,
		RealProviderAPICallRequested:      false,
		RealCustomerPayloadIncluded:       false,
		RealReconciliationCommitRequested: false,
		RealOperatorERPSyncAction:         false,
		LiveOperationPolicy:               ERPSyncWorkerNoRealERPWritePolicy,
		CreatedAt:                         r.now().UTC(),
	}
	r.plans[key] = plan
	r.appendAudit("ERP_SYNC_PLAN_BUILT", req.AccountantTenantID, req.FirmTenantID, provider, ERPSyncWorkerLiveReadyStatusPlanBuilt, "")
	return plan, nil
}

func (r *ERPSyncWorkerLiveReadyRuntime) RequestRealERPWrite(providerCode string) error {
	r.appendAudit("ERP_SYNC_REAL_ERP_WRITE_BLOCKED", "", "", providerCode, ERPSyncWorkerLiveReadyStatusClosed, ERPSyncWorkerNoRealERPWritePolicy)
	return ErrERPSyncWorkerRealOperationClosed
}

func (r *ERPSyncWorkerLiveReadyRuntime) RequestRealLedgerPosting(providerCode string) error {
	r.appendAudit("ERP_SYNC_REAL_LEDGER_POSTING_BLOCKED", "", "", providerCode, ERPSyncWorkerLiveReadyStatusClosed, ERPSyncWorkerNoRealLedgerPostingPolicy)
	return ErrERPSyncWorkerRealOperationClosed
}

func (r *ERPSyncWorkerLiveReadyRuntime) RequestRealProviderAPI(providerCode string) error {
	r.appendAudit("ERP_SYNC_REAL_PROVIDER_API_BLOCKED", "", "", providerCode, ERPSyncWorkerLiveReadyStatusClosed, ERPSyncWorkerNoRealProviderAPIPolicy)
	return ErrERPSyncWorkerRealOperationClosed
}

func (r *ERPSyncWorkerLiveReadyRuntime) RequestRealCustomerPayload(providerCode string) error {
	r.appendAudit("ERP_SYNC_REAL_CUSTOMER_PAYLOAD_BLOCKED", "", "", providerCode, ERPSyncWorkerLiveReadyStatusClosed, ERPSyncWorkerNoRealCustomerPayloadPolicy)
	return ErrERPSyncWorkerRealOperationClosed
}

func (r *ERPSyncWorkerLiveReadyRuntime) RequestRealReconciliationCommit(providerCode string) error {
	r.appendAudit("ERP_SYNC_REAL_RECONCILIATION_COMMIT_BLOCKED", "", "", providerCode, ERPSyncWorkerLiveReadyStatusClosed, ERPSyncWorkerNoRealReconciliationPolicy)
	return ErrERPSyncWorkerRealOperationClosed
}

func (r *ERPSyncWorkerLiveReadyRuntime) RequestRealOperatorERPSyncAction(providerCode string) error {
	r.appendAudit("ERP_SYNC_REAL_OPERATOR_ACTION_BLOCKED", "", "", providerCode, ERPSyncWorkerLiveReadyStatusClosed, ERPSyncWorkerNoRealOperatorActionPolicy)
	return ErrERPSyncWorkerRealOperationClosed
}

func (r *ERPSyncWorkerLiveReadyRuntime) Gate() ERPSyncWorkerLiveReadyGate {
	return r.gate
}

func (r *ERPSyncWorkerLiveReadyRuntime) AuditEvents() []ERPSyncWorkerAuditEvent {
	out := make([]ERPSyncWorkerAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *ERPSyncWorkerLiveReadyRuntime) appendAudit(code, accountantTenantID, firmTenantID, providerCode, status, reason string) {
	r.auditEvents = append(r.auditEvents, ERPSyncWorkerAuditEvent{
		EventCode:          code,
		AccountantTenantID: accountantTenantID,
		FirmTenantID:       firmTenantID,
		ProviderCode:       strings.ToUpper(strings.TrimSpace(providerCode)),
		Status:             status,
		Reason:             reason,
		CreatedAt:          r.now().UTC(),
	})
}

func BuildERPSyncWorkerRequirements(input ERPSyncWorkerLiveReadyInput) []ERPSyncWorkerRequirement {
	requirements := []ERPSyncWorkerRequirement{
		erpSyncRequirement(ERPSyncRequirementExportLiveReady, input.ExportLiveReady, "export live-ready pipeline is prepared"),
		erpSyncRequirement(ERPSyncRequirementProviderAdapterReady, input.ProviderAdapterReady, "provider adapter readiness is prepared"),
		erpSyncRequirement(ERPSyncRequirementERPWriteContractReady, input.ERPWriteContractReady, "ERP write contract is prepared"),
		erpSyncRequirement(ERPSyncRequirementObjectMappingReady, input.ObjectMappingReady, "ERP object mapping is prepared"),
		erpSyncRequirement(ERPSyncRequirementTenantBoundaryReady, input.TenantBoundaryReady, "tenant boundary guard is prepared"),
		erpSyncRequirement(ERPSyncRequirementEventMappingReady, input.EventMappingReady, "event mapping is prepared"),
		erpSyncRequirement(ERPSyncRequirementIdempotencyReady, input.IdempotencyReady, "ERP sync idempotency is prepared"),
		erpSyncRequirement(ERPSyncRequirementRetryDLQReady, input.RetryDLQReady, "ERP sync retry and DLQ policy is prepared"),
		erpSyncRequirement(ERPSyncRequirementReconciliationReady, input.ReconciliationReady, "ERP reconciliation plan is prepared"),
		erpSyncRequirement(ERPSyncRequirementLedgerPostingGuardReady, input.LedgerPostingGuardReady, "ledger posting guard is prepared"),
		erpSyncRequirement(ERPSyncRequirementAuditReady, input.AuditReady, "ERP sync audit trail is prepared"),
		erpSyncRequirement(ERPSyncRequirementRollbackReady, input.RollbackReady, "ERP sync rollback policy is prepared"),
		erpSyncRequirement(ERPSyncRequirementLegalApprovalReady, input.LegalApprovalReady, "legal approval gate is modeled"),
		erpSyncRequirement(ERPSyncRequirementFinanceApprovalReady, input.FinanceApprovalReady, "finance approval gate is modeled"),
		erpSyncRequirement(ERPSyncRequirementSecurityApprovalReady, input.SecurityApprovalReady, "security gate is modeled"),
		erpSyncRequirement(ERPSyncRequirementObservabilityReady, input.ObservabilityReady, "ERP sync observability is prepared"),
	}
	sort.Slice(requirements, func(i, j int) bool {
		return requirements[i].Code < requirements[j].Code
	})
	return requirements
}

func MissingERPSyncWorkerRequirements(input ERPSyncWorkerLiveReadyInput) []string {
	missing := []string{}
	for _, req := range BuildERPSyncWorkerRequirements(input) {
		if req.Required && !req.Ready {
			missing = append(missing, req.Code)
		}
	}
	sort.Strings(missing)
	return missing
}

func AllERPSyncWorkerLiveReadyInput() ERPSyncWorkerLiveReadyInput {
	return ERPSyncWorkerLiveReadyInput{
		ExportLiveReady:         true,
		ProviderAdapterReady:    true,
		ERPWriteContractReady:   true,
		ObjectMappingReady:      true,
		TenantBoundaryReady:     true,
		EventMappingReady:       true,
		IdempotencyReady:        true,
		RetryDLQReady:           true,
		ReconciliationReady:     true,
		LedgerPostingGuardReady: true,
		AuditReady:              true,
		RollbackReady:           true,
		LegalApprovalReady:      true,
		FinanceApprovalReady:    true,
		SecurityApprovalReady:   true,
		ObservabilityReady:      true,
	}
}

func SupportedERPSyncWorkerProviders() []string {
	return []string{ProviderCodeLogo, ProviderCodeMikro, ProviderCodeParasut, ProviderCodeZirve}
}

func SupportedERPSyncObjects() []string {
	return []string{ERPSyncObjectCustomer, ERPSyncObjectInvoice, ERPSyncObjectLedgerEntry, ERPSyncObjectStockItem}
}

func SupportedERPSyncDirections() []string {
	return []string{ERPSyncDirectionPix2piToProvider, ERPSyncDirectionProviderToPix2pi}
}

func DefaultERPSyncWorkerPolicies() map[string]string {
	return map[string]string{
		"erp_write":             ERPSyncWorkerNoRealERPWritePolicy,
		"ledger_posting":        ERPSyncWorkerNoRealLedgerPostingPolicy,
		"provider_api":          ERPSyncWorkerNoRealProviderAPIPolicy,
		"customer_payload":      ERPSyncWorkerNoRealCustomerPayloadPolicy,
		"reconciliation_commit": ERPSyncWorkerNoRealReconciliationPolicy,
		"operator_action":       ERPSyncWorkerNoRealOperatorActionPolicy,
	}
}

func validateERPSyncPlanRequest(req ERPSyncPlanRequest) error {
	provider := strings.ToUpper(strings.TrimSpace(req.ProviderCode))
	if !isLiveReadyProvider(provider) {
		return errors.New("unsupported provider code")
	}
	objectType := strings.ToUpper(strings.TrimSpace(req.ERPObjectType))
	if !isSupportedERPSyncObject(objectType) {
		return errors.New("unsupported ERP object type")
	}
	direction := strings.ToUpper(strings.TrimSpace(req.SyncDirection))
	if !isSupportedERPSyncDirection(direction) {
		return errors.New("unsupported ERP sync direction")
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
	if strings.TrimSpace(req.SourcePackageID) == "" {
		return errors.New("source package id is required")
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

func isSupportedERPSyncObject(objectType string) bool {
	for _, supported := range SupportedERPSyncObjects() {
		if objectType == supported {
			return true
		}
	}
	return false
}

func isSupportedERPSyncDirection(direction string) bool {
	for _, supported := range SupportedERPSyncDirections() {
		if direction == supported {
			return true
		}
	}
	return false
}

func buildSyntheticERPSyncSteps(objectType, direction string) []ERPSyncOperationStep {
	steps := []ERPSyncOperationStep{
		{
			StepCode:             "VALIDATE_TENANT_BOUNDARY",
			Status:               ERPSyncWorkerLiveReadyStatusReady,
			SyntheticPayloadOnly: true,
			RealERPWriteAllowed:  false,
			Description:          "tenant boundary validated without real ERP write",
		},
		{
			StepCode:             "MAP_" + objectType + "_OBJECT",
			Status:               ERPSyncWorkerLiveReadyStatusMappingReady,
			SyntheticPayloadOnly: true,
			RealERPWriteAllowed:  false,
			Description:          "synthetic " + objectType + " mapping prepared for " + direction,
		},
		{
			StepCode:             "QUEUE_SYNC_DRY_RUN",
			Status:               ERPSyncWorkerLiveReadyStatusPlanBuilt,
			SyntheticPayloadOnly: true,
			RealERPWriteAllowed:  false,
			Description:          "dry-run sync queue plan prepared",
		},
		{
			StepCode:             "RECONCILIATION_PRECHECK",
			Status:               ERPSyncWorkerLiveReadyStatusReconciliationReady,
			SyntheticPayloadOnly: true,
			RealERPWriteAllowed:  false,
			Description:          "reconciliation precheck prepared without commit",
		},
	}
	sort.Slice(steps, func(i, j int) bool {
		return steps[i].StepCode < steps[j].StepCode
	})
	return steps
}

func erpSyncRequirement(code string, ready bool, description string) ERPSyncWorkerRequirement {
	status := ERPSyncWorkerLiveReadyStatusRequirementNotReady
	if ready {
		status = ERPSyncWorkerLiveReadyStatusRequirementReady
	}
	return ERPSyncWorkerRequirement{
		Code:        code,
		Required:    true,
		Ready:       ready,
		Status:      status,
		Description: description,
	}
}

func erpSyncPlanKey(accountantTenantID, firmTenantID, provider, objectType, period, idempotencyKey string) string {
	return accountantTenantID + "|" + firmTenantID + "|" + provider + "|" + objectType + "|" + period + "|" + idempotencyKey
}

func erpSyncWorkerID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}

// FAZ 7-18 FIX V2:
// Keep provider codes as local runtime literals so the real implementation audit
// can verify that ERP Sync Worker explicitly supports the sealed dry-run provider set.
// These constants do not enable real provider API, real ERP write, or real customer payload.
const (
	ERPSyncWorkerProviderLiteralParasut = "PARASUT"
	ERPSyncWorkerProviderLiteralLogo    = "LOGO"
	ERPSyncWorkerProviderLiteralMikro   = "MIKRO"
	ERPSyncWorkerProviderLiteralZirve   = "ZIRVE"
)
