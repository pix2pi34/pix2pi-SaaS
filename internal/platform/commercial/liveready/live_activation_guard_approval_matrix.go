package liveready

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	LiveActivationGuardModuleCode = "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX"

	LiveActivationGuardMode = "LIVE_ACTIVATION_GUARD_READY_WITH_PRODUCTION_ACTIVATION_DISABLED"

	LiveActivationGuardStatusReady                  = "LIVE_ACTIVATION_GUARD_READY"
	LiveActivationGuardStatusMatrixBuilt            = "APPROVAL_MATRIX_BUILT_NO_PRODUCTION_ACTIVATION"
	LiveActivationGuardStatusDecisionBlocked        = "LIVE_ACTIVATION_BLOCKED"
	LiveActivationGuardStatusDecisionArmedLocked    = "LIVE_ACTIVATION_ARMED_BUT_LOCKED"
	LiveActivationGuardStatusClosed                 = "CLOSED"
	LiveActivationGuardStatusRequirementReady       = "REQUIRED_READY"
	LiveActivationGuardStatusRequirementNotReady    = "REQUIRED_NOT_READY"
	LiveActivationGuardStatusProductionLocked       = "PRODUCTION_ACTIVATION_LOCKED_IN_FAZ_7_19"
	LiveActivationGuardStatusApprovalMatrixReady    = "APPROVAL_MATRIX_READY"
	LiveActivationGuardStatusSecretGateReady        = "SECRET_GATE_READY"
	LiveActivationGuardStatusLegalGateReady         = "LEGAL_GATE_READY"
	LiveActivationGuardStatusFinanceGateReady       = "FINANCE_GATE_READY"
	LiveActivationGuardStatusSecurityGateReady      = "SECURITY_GATE_READY"
	LiveActivationGuardStatusOperatorGateReady      = "OPERATOR_GATE_READY"
	LiveActivationGuardStatusRollbackGateReady      = "ROLLBACK_GATE_READY"
	LiveActivationGuardStatusObservabilityGateReady = "OBSERVABILITY_GATE_READY"
	LiveActivationGuardStatusIncidentGateReady      = "INCIDENT_RESPONSE_GATE_READY"
	LiveActivationGuardStatusTenantGateReady        = "TENANT_ISOLATION_GATE_READY"
	LiveActivationGuardStatusAuditReady             = "AUDIT_READY"

	LiveActivationClosedUntilProductionActivationModule = "CLOSED_UNTIL_PRODUCTION_ACTIVATION_MODULE"
	LiveActivationClosedUntilApprovalMatrixPass         = "CLOSED_UNTIL_APPROVAL_MATRIX_PASS"
	LiveActivationClosedUntilSecretApproval             = "CLOSED_UNTIL_SECRET_APPROVAL"
	LiveActivationClosedUntilLegalApproval              = "CLOSED_UNTIL_LEGAL_APPROVAL"
	LiveActivationClosedUntilFinanceApproval            = "CLOSED_UNTIL_FINANCE_APPROVAL"
	LiveActivationClosedUntilSecurityApproval           = "CLOSED_UNTIL_SECURITY_APPROVAL"
	LiveActivationClosedUntilOperatorApproval           = "CLOSED_UNTIL_OPERATOR_APPROVAL"

	LiveActivationNoProductionActivationPolicy = "NO_PRODUCTION_ACTIVATION_IN_FAZ_7_19"
	LiveActivationNoRealMoneyMovementPolicy    = "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_19"
	LiveActivationNoRealBillingPolicy          = "NO_REAL_BILLING_IN_FAZ_7_19"
	LiveActivationNoRealPaymentPolicy          = "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_19"
	LiveActivationNoRealProviderAPIPolicy      = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_19"
	LiveActivationNoRealFileDeliveryPolicy     = "NO_REAL_FILE_DELIVERY_IN_FAZ_7_19"
	LiveActivationNoRealERPWritePolicy         = "NO_REAL_ERP_WRITE_IN_FAZ_7_19"
	LiveActivationNoRealCustomerExportPolicy   = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_19"
	LiveActivationNoRealLedgerPostingPolicy    = "NO_REAL_LEDGER_POSTING_IN_FAZ_7_19"
	LiveActivationNoRealOperatorActionPolicy   = "NO_REAL_OPERATOR_LIVE_ACTION_IN_FAZ_7_19"

	LiveActivationRequirementControlPlaneReady     = "commercial_live_ready_control_plane_ready"
	LiveActivationRequirementBillingReady          = "accountant_billing_live_ready"
	LiveActivationRequirementPaymentReady          = "payment_capture_live_ready"
	LiveActivationRequirementProviderReady         = "provider_live_adapter_ready"
	LiveActivationRequirementExportReady           = "export_live_ready"
	LiveActivationRequirementERPSyncReady          = "erp_sync_worker_live_ready"
	LiveActivationRequirementSecretsReady          = "production_secrets_ready"
	LiveActivationRequirementLegalApprovalReady    = "legal_approval_ready"
	LiveActivationRequirementFinanceApprovalReady  = "finance_approval_ready"
	LiveActivationRequirementSecurityApprovalReady = "security_approval_ready"
	LiveActivationRequirementOperatorApprovalReady = "operator_approval_ready"
	LiveActivationRequirementRollbackReady         = "rollback_ready"
	LiveActivationRequirementObservabilityReady    = "observability_ready"
	LiveActivationRequirementIncidentResponseReady = "incident_response_ready"
	LiveActivationRequirementTenantIsolationReady  = "tenant_isolation_ready"
	LiveActivationRequirementBackupRestoreReady    = "backup_restore_ready"
	LiveActivationRequirementRateLimitReady        = "rate_limit_ready"
	LiveActivationRequirementAuditTrailReady       = "audit_trail_ready"
	LiveActivationRequirementCustomerConsentReady  = "customer_data_consent_ready"
)

var ErrLiveActivationRealOperationClosed = errors.New("live activation real operation is closed in FAZ 7-19")

type LiveActivationGuardGate struct {
	ProductionActivationAllowed   bool `json:"production_activation_allowed"`
	RealMoneyMovementAllowed      bool `json:"real_money_movement_allowed"`
	RealBillingAllowed            bool `json:"real_billing_allowed"`
	RealPaymentCaptureAllowed     bool `json:"real_payment_capture_allowed"`
	RealProviderAPICallAllowed    bool `json:"real_provider_api_call_allowed"`
	RealFileDeliveryAllowed       bool `json:"real_file_delivery_allowed"`
	RealERPWriteAllowed           bool `json:"real_erp_write_allowed"`
	RealCustomerDataExportAllowed bool `json:"real_customer_data_export_allowed"`
	RealLedgerPostingAllowed      bool `json:"real_ledger_posting_allowed"`
	RealOperatorLiveActionAllowed bool `json:"real_operator_live_action_allowed"`

	ProductionActivationModuleStatus string `json:"production_activation_module_status"`
	ApprovalMatrixStatus             string `json:"approval_matrix_status"`
	SecretApprovalStatus             string `json:"secret_approval_status"`
	LegalApprovalStatus              string `json:"legal_approval_status"`
	FinanceApprovalStatus            string `json:"finance_approval_status"`
	SecurityApprovalStatus           string `json:"security_approval_status"`
	OperatorApprovalStatus           string `json:"operator_approval_status"`
	ProductionActivationLock         string `json:"production_activation_lock"`
	CommercialLiveReadyGate          string `json:"commercial_live_ready_gate"`
	ProviderDryRunSet                string `json:"provider_dry_run_set"`
}

func DefaultLiveActivationGuardGate() LiveActivationGuardGate {
	return LiveActivationGuardGate{
		ProductionActivationAllowed:   false,
		RealMoneyMovementAllowed:      false,
		RealBillingAllowed:            false,
		RealPaymentCaptureAllowed:     false,
		RealProviderAPICallAllowed:    false,
		RealFileDeliveryAllowed:       false,
		RealERPWriteAllowed:           false,
		RealCustomerDataExportAllowed: false,
		RealLedgerPostingAllowed:      false,
		RealOperatorLiveActionAllowed: false,

		ProductionActivationModuleStatus: LiveActivationClosedUntilProductionActivationModule,
		ApprovalMatrixStatus:             LiveActivationGuardStatusApprovalMatrixReady,
		SecretApprovalStatus:             LiveActivationClosedUntilSecretApproval,
		LegalApprovalStatus:              LiveActivationClosedUntilLegalApproval,
		FinanceApprovalStatus:            LiveActivationClosedUntilFinanceApproval,
		SecurityApprovalStatus:           LiveActivationClosedUntilSecurityApproval,
		OperatorApprovalStatus:           LiveActivationClosedUntilOperatorApproval,
		ProductionActivationLock:         LiveActivationGuardStatusProductionLocked,
		CommercialLiveReadyGate:          CommercialLiveReadyGateReady,
		ProviderDryRunSet:                CommercialLiveReadyProviderDryRunSet,
	}
}

func (g LiveActivationGuardGate) AssertProductionActivationClosed() error {
	checks := map[string]bool{
		"production_activation_allowed":     g.ProductionActivationAllowed,
		"real_money_movement_allowed":       g.RealMoneyMovementAllowed,
		"real_billing_allowed":              g.RealBillingAllowed,
		"real_payment_capture_allowed":      g.RealPaymentCaptureAllowed,
		"real_provider_api_call_allowed":    g.RealProviderAPICallAllowed,
		"real_file_delivery_allowed":        g.RealFileDeliveryAllowed,
		"real_erp_write_allowed":            g.RealERPWriteAllowed,
		"real_customer_data_export_allowed": g.RealCustomerDataExportAllowed,
		"real_ledger_posting_allowed":       g.RealLedgerPostingAllowed,
		"real_operator_live_action_allowed": g.RealOperatorLiveActionAllowed,
	}
	for name, value := range checks {
		if value {
			return fmt.Errorf("%s must remain false in FAZ 7-19", name)
		}
	}
	if g.ProductionActivationLock != LiveActivationGuardStatusProductionLocked {
		return fmt.Errorf("production activation lock must remain %s", LiveActivationGuardStatusProductionLocked)
	}
	return nil
}

type LiveActivationApprovalInput struct {
	CommercialControlPlaneReady bool
	AccountantBillingReady      bool
	PaymentCaptureReady         bool
	ProviderLiveAdapterReady    bool
	ExportLiveReady             bool
	ERPSyncWorkerReady          bool
	ProductionSecretsReady      bool
	LegalApprovalReady          bool
	FinanceApprovalReady        bool
	SecurityApprovalReady       bool
	OperatorApprovalReady       bool
	RollbackReady               bool
	ObservabilityReady          bool
	IncidentResponseReady       bool
	TenantIsolationReady        bool
	BackupRestoreReady          bool
	RateLimitReady              bool
	AuditTrailReady             bool
	CustomerConsentReady        bool
}

type LiveActivationRequirement struct {
	Code        string `json:"code"`
	Required    bool   `json:"required"`
	Ready       bool   `json:"ready"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type LiveActivationDependencySeal struct {
	ModuleCode  string `json:"module_code"`
	FinalStatus string `json:"final_status"`
	SealStatus  string `json:"seal_status"`
	GateStatus  string `json:"gate_status"`
}

type LiveActivationDecisionRequest struct {
	RequestedByUserID string
	CorrelationID     string
	Reason            string
	Environment       string
}

type LiveActivationDecision struct {
	DecisionID                    string    `json:"decision_id"`
	ModuleCode                    string    `json:"module_code"`
	Mode                          string    `json:"mode"`
	Allowed                       bool      `json:"allowed"`
	Armed                         bool      `json:"armed"`
	Status                        string    `json:"status"`
	Reason                        string    `json:"reason"`
	RequestedByUserID             string    `json:"requested_by_user_id"`
	CorrelationID                 string    `json:"correlation_id"`
	Environment                   string    `json:"environment"`
	MissingRequirements           []string  `json:"missing_requirements"`
	ProductionActivationLock      string    `json:"production_activation_lock"`
	ProductionActivationAllowed   bool      `json:"production_activation_allowed"`
	RealMoneyMovementAllowed      bool      `json:"real_money_movement_allowed"`
	RealBillingAllowed            bool      `json:"real_billing_allowed"`
	RealPaymentCaptureAllowed     bool      `json:"real_payment_capture_allowed"`
	RealProviderAPICallAllowed    bool      `json:"real_provider_api_call_allowed"`
	RealFileDeliveryAllowed       bool      `json:"real_file_delivery_allowed"`
	RealERPWriteAllowed           bool      `json:"real_erp_write_allowed"`
	RealCustomerDataExportAllowed bool      `json:"real_customer_data_export_allowed"`
	RealLedgerPostingAllowed      bool      `json:"real_ledger_posting_allowed"`
	CreatedAt                     time.Time `json:"created_at"`
}

type LiveActivationGuardReport struct {
	ModuleCode                    string                         `json:"module_code"`
	Mode                          string                         `json:"mode"`
	Status                        string                         `json:"status"`
	Gate                          LiveActivationGuardGate        `json:"gate"`
	Requirements                  []LiveActivationRequirement    `json:"requirements"`
	DependencySeals               []LiveActivationDependencySeal `json:"dependency_seals"`
	LiveOperationPolicies         map[string]string              `json:"live_operation_policies"`
	ProductionActivationAllowed   bool                           `json:"production_activation_allowed"`
	RealMoneyMovementAllowed      bool                           `json:"real_money_movement_allowed"`
	RealBillingAllowed            bool                           `json:"real_billing_allowed"`
	RealPaymentCaptureAllowed     bool                           `json:"real_payment_capture_allowed"`
	RealProviderAPICallAllowed    bool                           `json:"real_provider_api_call_allowed"`
	RealFileDeliveryAllowed       bool                           `json:"real_file_delivery_allowed"`
	RealERPWriteAllowed           bool                           `json:"real_erp_write_allowed"`
	RealCustomerDataExportAllowed bool                           `json:"real_customer_data_export_allowed"`
	RealLedgerPostingAllowed      bool                           `json:"real_ledger_posting_allowed"`
	NextModule                    string                         `json:"next_module"`
	CreatedAt                     time.Time                      `json:"created_at"`
}

type LiveActivationGuardAuditEvent struct {
	EventCode         string    `json:"event_code"`
	RequestedByUserID string    `json:"requested_by_user_id,omitempty"`
	Status            string    `json:"status"`
	Reason            string    `json:"reason,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
}

type LiveActivationGuardRuntime struct {
	gate        LiveActivationGuardGate
	auditEvents []LiveActivationGuardAuditEvent
	now         func() time.Time
}

func NewDefaultLiveActivationGuardRuntime() *LiveActivationGuardRuntime {
	return &LiveActivationGuardRuntime{
		gate:        DefaultLiveActivationGuardGate(),
		auditEvents: []LiveActivationGuardAuditEvent{},
		now:         time.Now,
	}
}

func (r *LiveActivationGuardRuntime) BuildLiveActivationGuardReport(input LiveActivationApprovalInput) (LiveActivationGuardReport, error) {
	if err := r.gate.AssertProductionActivationClosed(); err != nil {
		r.appendAudit("LIVE_ACTIVATION_GUARD_REPORT_DENIED", "", LiveActivationGuardStatusDecisionBlocked, err.Error())
		return LiveActivationGuardReport{}, err
	}
	report := LiveActivationGuardReport{
		ModuleCode:                    LiveActivationGuardModuleCode,
		Mode:                          LiveActivationGuardMode,
		Status:                        LiveActivationGuardStatusReady,
		Gate:                          r.gate,
		Requirements:                  BuildLiveActivationRequirements(input),
		DependencySeals:               DefaultLiveActivationDependencySeals(),
		LiveOperationPolicies:         DefaultLiveActivationPolicies(),
		ProductionActivationAllowed:   false,
		RealMoneyMovementAllowed:      false,
		RealBillingAllowed:            false,
		RealPaymentCaptureAllowed:     false,
		RealProviderAPICallAllowed:    false,
		RealFileDeliveryAllowed:       false,
		RealERPWriteAllowed:           false,
		RealCustomerDataExportAllowed: false,
		RealLedgerPostingAllowed:      false,
		NextModule:                    "FAZ_7_20_COMMERCIAL_MASTER_CLOSURE",
		CreatedAt:                     r.now().UTC(),
	}
	r.appendAudit("LIVE_ACTIVATION_GUARD_REPORT_BUILT", "", LiveActivationGuardStatusReady, "")
	return report, nil
}

func (r *LiveActivationGuardRuntime) EvaluateLiveActivation(req LiveActivationDecisionRequest, input LiveActivationApprovalInput) (LiveActivationDecision, error) {
	if err := r.gate.AssertProductionActivationClosed(); err != nil {
		r.appendAudit("LIVE_ACTIVATION_DECISION_DENIED", req.RequestedByUserID, LiveActivationGuardStatusDecisionBlocked, err.Error())
		return LiveActivationDecision{}, err
	}
	if strings.TrimSpace(req.RequestedByUserID) == "" {
		return LiveActivationDecision{}, errors.New("requested by user id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return LiveActivationDecision{}, errors.New("correlation id is required")
	}
	env := strings.ToUpper(strings.TrimSpace(req.Environment))
	if env == "" {
		env = "PRODUCTION"
	}
	missing := MissingLiveActivationRequirements(input)
	decision := LiveActivationDecision{
		DecisionID:                    liveActivationGuardID("LIVE-ACTIVATION-DECISION", req.RequestedByUserID, req.CorrelationID, env),
		ModuleCode:                    LiveActivationGuardModuleCode,
		Mode:                          LiveActivationGuardMode,
		Allowed:                       false,
		Armed:                         false,
		Status:                        LiveActivationGuardStatusDecisionBlocked,
		Reason:                        "missing live activation requirements",
		RequestedByUserID:             req.RequestedByUserID,
		CorrelationID:                 req.CorrelationID,
		Environment:                   env,
		MissingRequirements:           missing,
		ProductionActivationLock:      r.gate.ProductionActivationLock,
		ProductionActivationAllowed:   false,
		RealMoneyMovementAllowed:      false,
		RealBillingAllowed:            false,
		RealPaymentCaptureAllowed:     false,
		RealProviderAPICallAllowed:    false,
		RealFileDeliveryAllowed:       false,
		RealERPWriteAllowed:           false,
		RealCustomerDataExportAllowed: false,
		RealLedgerPostingAllowed:      false,
		CreatedAt:                     r.now().UTC(),
	}
	if len(missing) == 0 {
		decision.Armed = true
		decision.Status = LiveActivationGuardStatusDecisionArmedLocked
		decision.Reason = LiveActivationGuardStatusProductionLocked
	}
	r.appendAudit("LIVE_ACTIVATION_DECISION_EVALUATED", req.RequestedByUserID, decision.Status, decision.Reason)
	return decision, nil
}

func (r *LiveActivationGuardRuntime) RequestProductionActivation() error {
	r.appendAudit("LIVE_PRODUCTION_ACTIVATION_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoProductionActivationPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealMoneyMovement() error {
	r.appendAudit("LIVE_REAL_MONEY_MOVEMENT_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealMoneyMovementPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealBilling() error {
	r.appendAudit("LIVE_REAL_BILLING_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealBillingPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealPaymentCapture() error {
	r.appendAudit("LIVE_REAL_PAYMENT_CAPTURE_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealPaymentPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealProviderAPI() error {
	r.appendAudit("LIVE_REAL_PROVIDER_API_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealProviderAPIPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealFileDelivery() error {
	r.appendAudit("LIVE_REAL_FILE_DELIVERY_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealFileDeliveryPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealERPWrite() error {
	r.appendAudit("LIVE_REAL_ERP_WRITE_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealERPWritePolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealCustomerDataExport() error {
	r.appendAudit("LIVE_REAL_CUSTOMER_DATA_EXPORT_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealCustomerExportPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealLedgerPosting() error {
	r.appendAudit("LIVE_REAL_LEDGER_POSTING_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealLedgerPostingPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) RequestRealOperatorLiveAction() error {
	r.appendAudit("LIVE_REAL_OPERATOR_ACTION_BLOCKED", "", LiveActivationGuardStatusClosed, LiveActivationNoRealOperatorActionPolicy)
	return ErrLiveActivationRealOperationClosed
}

func (r *LiveActivationGuardRuntime) Gate() LiveActivationGuardGate {
	return r.gate
}

func (r *LiveActivationGuardRuntime) AuditEvents() []LiveActivationGuardAuditEvent {
	out := make([]LiveActivationGuardAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *LiveActivationGuardRuntime) appendAudit(code, requestedByUserID, status, reason string) {
	r.auditEvents = append(r.auditEvents, LiveActivationGuardAuditEvent{
		EventCode:         code,
		RequestedByUserID: requestedByUserID,
		Status:            status,
		Reason:            reason,
		CreatedAt:         r.now().UTC(),
	})
}

func BuildLiveActivationRequirements(input LiveActivationApprovalInput) []LiveActivationRequirement {
	requirements := []LiveActivationRequirement{
		liveActivationRequirement(LiveActivationRequirementControlPlaneReady, input.CommercialControlPlaneReady, "commercial live-ready control plane is sealed"),
		liveActivationRequirement(LiveActivationRequirementBillingReady, input.AccountantBillingReady, "accountant billing live-ready runtime is sealed"),
		liveActivationRequirement(LiveActivationRequirementPaymentReady, input.PaymentCaptureReady, "payment capture live-ready runtime is sealed"),
		liveActivationRequirement(LiveActivationRequirementProviderReady, input.ProviderLiveAdapterReady, "provider live adapter readiness is sealed"),
		liveActivationRequirement(LiveActivationRequirementExportReady, input.ExportLiveReady, "export live-ready pipeline is sealed"),
		liveActivationRequirement(LiveActivationRequirementERPSyncReady, input.ERPSyncWorkerReady, "ERP sync worker live-ready runtime is sealed"),
		liveActivationRequirement(LiveActivationRequirementSecretsReady, input.ProductionSecretsReady, "production secrets are ready but not used in this phase"),
		liveActivationRequirement(LiveActivationRequirementLegalApprovalReady, input.LegalApprovalReady, "legal approval gate is ready"),
		liveActivationRequirement(LiveActivationRequirementFinanceApprovalReady, input.FinanceApprovalReady, "finance approval gate is ready"),
		liveActivationRequirement(LiveActivationRequirementSecurityApprovalReady, input.SecurityApprovalReady, "security approval gate is ready"),
		liveActivationRequirement(LiveActivationRequirementOperatorApprovalReady, input.OperatorApprovalReady, "operator approval gate is ready"),
		liveActivationRequirement(LiveActivationRequirementRollbackReady, input.RollbackReady, "rollback plan is ready"),
		liveActivationRequirement(LiveActivationRequirementObservabilityReady, input.ObservabilityReady, "observability and alerting are ready"),
		liveActivationRequirement(LiveActivationRequirementIncidentResponseReady, input.IncidentResponseReady, "incident response is ready"),
		liveActivationRequirement(LiveActivationRequirementTenantIsolationReady, input.TenantIsolationReady, "tenant isolation is verified"),
		liveActivationRequirement(LiveActivationRequirementBackupRestoreReady, input.BackupRestoreReady, "backup/restore gate is ready"),
		liveActivationRequirement(LiveActivationRequirementRateLimitReady, input.RateLimitReady, "rate limit gate is ready"),
		liveActivationRequirement(LiveActivationRequirementAuditTrailReady, input.AuditTrailReady, "audit trail is ready"),
		liveActivationRequirement(LiveActivationRequirementCustomerConsentReady, input.CustomerConsentReady, "customer data consent gate is ready"),
	}
	sort.Slice(requirements, func(i, j int) bool {
		return requirements[i].Code < requirements[j].Code
	})
	return requirements
}

func MissingLiveActivationRequirements(input LiveActivationApprovalInput) []string {
	missing := []string{}
	for _, req := range BuildLiveActivationRequirements(input) {
		if req.Required && !req.Ready {
			missing = append(missing, req.Code)
		}
	}
	sort.Strings(missing)
	return missing
}

func AllLiveActivationApprovalInput() LiveActivationApprovalInput {
	return LiveActivationApprovalInput{
		CommercialControlPlaneReady: true,
		AccountantBillingReady:      true,
		PaymentCaptureReady:         true,
		ProviderLiveAdapterReady:    true,
		ExportLiveReady:             true,
		ERPSyncWorkerReady:          true,
		ProductionSecretsReady:      true,
		LegalApprovalReady:          true,
		FinanceApprovalReady:        true,
		SecurityApprovalReady:       true,
		OperatorApprovalReady:       true,
		RollbackReady:               true,
		ObservabilityReady:          true,
		IncidentResponseReady:       true,
		TenantIsolationReady:        true,
		BackupRestoreReady:          true,
		RateLimitReady:              true,
		AuditTrailReady:             true,
		CustomerConsentReady:        true,
	}
}

func DefaultLiveActivationDependencySeals() []LiveActivationDependencySeal {
	return []LiveActivationDependencySeal{
		{ModuleCode: "FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE", FinalStatus: "PASS", SealStatus: "SEALED", GateStatus: "READY_FOR_LIVE_READY_MODULES"},
		{ModuleCode: "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME", FinalStatus: "PASS", SealStatus: "SEALED", GateStatus: "BILLING_LIVE_READY_RUNTIME_READY"},
		{ModuleCode: "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME", FinalStatus: "PASS", SealStatus: "SEALED", GateStatus: "PAYMENT_CAPTURE_LIVE_READY_RUNTIME_READY"},
		{ModuleCode: "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS", FinalStatus: "PASS", SealStatus: "SEALED", GateStatus: "PROVIDER_LIVE_ADAPTER_READINESS_READY"},
		{ModuleCode: "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE", FinalStatus: "PASS", SealStatus: "SEALED", GateStatus: "EXPORT_LIVE_READY_PIPELINE_READY"},
		{ModuleCode: "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME", FinalStatus: "PASS", SealStatus: "SEALED", GateStatus: "ERP_SYNC_WORKER_LIVE_READY_RUNTIME_READY"},
	}
}

func DefaultLiveActivationPolicies() map[string]string {
	return map[string]string{
		"production_activation": LiveActivationNoProductionActivationPolicy,
		"money_movement":        LiveActivationNoRealMoneyMovementPolicy,
		"billing":               LiveActivationNoRealBillingPolicy,
		"payment_capture":       LiveActivationNoRealPaymentPolicy,
		"provider_api":          LiveActivationNoRealProviderAPIPolicy,
		"file_delivery":         LiveActivationNoRealFileDeliveryPolicy,
		"erp_write":             LiveActivationNoRealERPWritePolicy,
		"customer_data_export":  LiveActivationNoRealCustomerExportPolicy,
		"ledger_posting":        LiveActivationNoRealLedgerPostingPolicy,
		"operator_action":       LiveActivationNoRealOperatorActionPolicy,
	}
}

func liveActivationRequirement(code string, ready bool, description string) LiveActivationRequirement {
	status := LiveActivationGuardStatusRequirementNotReady
	if ready {
		status = LiveActivationGuardStatusRequirementReady
	}
	return LiveActivationRequirement{
		Code:        code,
		Required:    true,
		Ready:       ready,
		Status:      status,
		Description: description,
	}
}

func liveActivationGuardID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
