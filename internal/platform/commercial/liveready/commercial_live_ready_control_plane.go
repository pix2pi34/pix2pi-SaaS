package liveready

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	CommercialLiveReadyModuleCode = "FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE"

	CommercialLiveReadyMode = "LIVE_READY_CONTROL_PLANE_WITH_PRODUCTION_ACTIVATION_DISABLED"

	CommercialLiveReadyStatusPass                = "PASS"
	CommercialLiveReadyStatusFail                = "FAIL"
	CommercialLiveReadyStatusReady               = "READY"
	CommercialLiveReadyStatusBlocked             = "BLOCKED"
	CommercialLiveReadyStatusClosed              = "CLOSED"
	CommercialLiveReadyStatusNotStarted          = "NOT_STARTED"
	CommercialLiveReadyStatusRequiredNotReady    = "REQUIRED_NOT_READY"
	CommercialLiveReadyStatusRequiredReady       = "REQUIRED_READY"
	CommercialLiveReadyStatusControlPlaneReady   = "CONTROL_PLANE_READY"
	CommercialLiveReadyStatusActivationLocked    = "PRODUCTION_ACTIVATION_LOCKED_IN_FAZ_7_13"
	CommercialLiveReadyStatusLiveReadyConfigured = "LIVE_READY_CONFIGURED"

	CommercialLiveReadyGateReady = "READY_FOR_LIVE_READY_MODULES"

	CommercialLiveReadyClosedUntilBillingLiveModule    = "CLOSED_UNTIL_BILLING_LIVE_MODULE"
	CommercialLiveReadyClosedUntilPaymentLiveModule    = "CLOSED_UNTIL_PAYMENT_LIVE_MODULE"
	CommercialLiveReadyClosedUntilProviderLiveModule   = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	CommercialLiveReadyClosedUntilExportLiveModule     = "CLOSED_UNTIL_EXPORT_LIVE_MODULE"
	CommercialLiveReadyClosedUntilSyncWorkerLiveModule = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	CommercialLiveReadyClosedUntilApprovalMatrix       = "CLOSED_UNTIL_APPROVAL_MATRIX_PASS"

	CommercialLiveReadyNoRealMoneyPolicy        = "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_13"
	CommercialLiveReadyNoRealBillingPolicy      = "NO_REAL_BILLING_IN_FAZ_7_13"
	CommercialLiveReadyNoRealPaymentPolicy      = "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_13"
	CommercialLiveReadyNoRealProviderAPIPolicy  = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_13"
	CommercialLiveReadyNoRealFileDeliveryPolicy = "NO_REAL_FILE_DELIVERY_IN_FAZ_7_13"
	CommercialLiveReadyNoRealERPWritePolicy     = "NO_REAL_ERP_WRITE_IN_FAZ_7_13"
	CommercialLiveReadyNoRealCustomerDataPolicy = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_13"

	CommercialLiveReadyProviderDryRunSet = "PARASUT_LOGO_MIKRO_ZIRVE"

	RequirementBillingLiveReady      = "billing_live_ready"
	RequirementPaymentCaptureReady   = "payment_capture_live_ready"
	RequirementProviderLiveReady     = "provider_live_ready"
	RequirementExportLiveReady       = "export_live_ready"
	RequirementERPSyncLiveReady      = "erp_sync_live_ready"
	RequirementSecretsReady          = "secrets_ready"
	RequirementLegalApprovalReady    = "legal_approval_ready"
	RequirementFinanceApprovalReady  = "finance_approval_ready"
	RequirementSecurityApprovalReady = "security_approval_ready"
	RequirementOperatorApprovalReady = "operator_approval_ready"
	RequirementRollbackReady         = "rollback_ready"
	RequirementObservabilityReady    = "observability_ready"
	RequirementIncidentResponseReady = "incident_response_ready"
	RequirementTenantIsolationReady  = "tenant_isolation_ready"
)

var ErrCommercialLiveReadyRealOperationClosed = errors.New("commercial live-ready control plane blocks real operation in FAZ 7-13")

type CommercialLiveReadyGate struct {
	ProductionActivationAllowed bool `json:"production_activation_allowed"`
	RealMoneyMovementAllowed    bool `json:"real_money_movement_allowed"`
	RealBillingAllowed          bool `json:"real_billing_allowed"`
	RealPaymentCaptureAllowed   bool `json:"real_payment_capture_allowed"`
	RealProviderAPICallAllowed  bool `json:"real_provider_api_call_allowed"`
	RealFileDeliveryAllowed     bool `json:"real_file_delivery_allowed"`
	RealERPWriteAllowed         bool `json:"real_erp_write_allowed"`
	RealCustomerDataExport      bool `json:"real_customer_data_export_allowed"`
	RealOperatorProviderAction  bool `json:"real_operator_provider_action_allowed"`

	BillingLiveModuleStatus  string `json:"billing_live_module_status"`
	PaymentLiveModuleStatus  string `json:"payment_live_module_status"`
	ProviderLiveModuleStatus string `json:"provider_live_module_status"`
	ExportLiveModuleStatus   string `json:"export_live_module_status"`
	ERPSyncWorkerLiveStatus  string `json:"erp_sync_worker_live_status"`
	ApprovalMatrixStatus     string `json:"approval_matrix_status"`
	ProductionActivationLock string `json:"production_activation_lock"`
	CommercialLiveReadyGate  string `json:"commercial_live_ready_gate"`
	ProviderDryRunSet        string `json:"provider_dry_run_set"`
}

func DefaultCommercialLiveReadyGate() CommercialLiveReadyGate {
	return CommercialLiveReadyGate{
		ProductionActivationAllowed: false,
		RealMoneyMovementAllowed:    false,
		RealBillingAllowed:          false,
		RealPaymentCaptureAllowed:   false,
		RealProviderAPICallAllowed:  false,
		RealFileDeliveryAllowed:     false,
		RealERPWriteAllowed:         false,
		RealCustomerDataExport:      false,
		RealOperatorProviderAction:  false,

		BillingLiveModuleStatus:  CommercialLiveReadyStatusNotStarted,
		PaymentLiveModuleStatus:  CommercialLiveReadyStatusNotStarted,
		ProviderLiveModuleStatus: CommercialLiveReadyStatusNotStarted,
		ExportLiveModuleStatus:   CommercialLiveReadyStatusNotStarted,
		ERPSyncWorkerLiveStatus:  CommercialLiveReadyStatusNotStarted,
		ApprovalMatrixStatus:     CommercialLiveReadyClosedUntilApprovalMatrix,
		ProductionActivationLock: CommercialLiveReadyStatusActivationLocked,
		CommercialLiveReadyGate:  CommercialLiveReadyGateReady,
		ProviderDryRunSet:        CommercialLiveReadyProviderDryRunSet,
	}
}

func (g CommercialLiveReadyGate) AssertRealOperationsClosed() error {
	checks := map[string]bool{
		"production_activation_allowed":         g.ProductionActivationAllowed,
		"real_money_movement_allowed":           g.RealMoneyMovementAllowed,
		"real_billing_allowed":                  g.RealBillingAllowed,
		"real_payment_capture_allowed":          g.RealPaymentCaptureAllowed,
		"real_provider_api_call_allowed":        g.RealProviderAPICallAllowed,
		"real_file_delivery_allowed":            g.RealFileDeliveryAllowed,
		"real_erp_write_allowed":                g.RealERPWriteAllowed,
		"real_customer_data_export_allowed":     g.RealCustomerDataExport,
		"real_operator_provider_action_allowed": g.RealOperatorProviderAction,
	}
	for name, value := range checks {
		if value {
			return fmt.Errorf("%s must remain false in FAZ 7-13", name)
		}
	}
	if g.ProductionActivationLock != CommercialLiveReadyStatusActivationLocked {
		return fmt.Errorf("production activation lock must remain %s", CommercialLiveReadyStatusActivationLocked)
	}
	return nil
}

type CommercialLiveReadyRequirement struct {
	Code        string `json:"code"`
	Required    bool   `json:"required"`
	Ready       bool   `json:"ready"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type CommercialLiveReadyActivationInput struct {
	BillingLiveReady      bool
	PaymentCaptureReady   bool
	ProviderLiveReady     bool
	ExportLiveReady       bool
	ERPSyncLiveReady      bool
	SecretsReady          bool
	LegalApprovalReady    bool
	FinanceApprovalReady  bool
	SecurityApprovalReady bool
	OperatorApprovalReady bool
	RollbackReady         bool
	ObservabilityReady    bool
	IncidentResponseReady bool
	TenantIsolationReady  bool
}

type CommercialLiveReadyActivationDecision struct {
	DecisionID                    string    `json:"decision_id"`
	ModuleCode                    string    `json:"module_code"`
	Allowed                       bool      `json:"allowed"`
	Status                        string    `json:"status"`
	Reason                        string    `json:"reason"`
	MissingRequirements           []string  `json:"missing_requirements"`
	ProductionActivationLock      string    `json:"production_activation_lock"`
	RealMoneyMovementAllowed      bool      `json:"real_money_movement_allowed"`
	RealProviderAPICallAllowed    bool      `json:"real_provider_api_call_allowed"`
	RealCustomerDataExportAllowed bool      `json:"real_customer_data_export_allowed"`
	RealERPWriteAllowed           bool      `json:"real_erp_write_allowed"`
	CreatedAt                     time.Time `json:"created_at"`
}

type CommercialLiveReadyReport struct {
	ModuleCode                    string                           `json:"module_code"`
	Mode                          string                           `json:"mode"`
	Status                        string                           `json:"status"`
	Gate                          CommercialLiveReadyGate          `json:"gate"`
	Requirements                  []CommercialLiveReadyRequirement `json:"requirements"`
	ProviderDryRunSet             string                           `json:"provider_dry_run_set"`
	NextModules                   []string                         `json:"next_modules"`
	LiveOperationPolicies         map[string]string                `json:"live_operation_policies"`
	ProductionActivationAllowed   bool                             `json:"production_activation_allowed"`
	RealMoneyMovementAllowed      bool                             `json:"real_money_movement_allowed"`
	RealProviderAPICallAllowed    bool                             `json:"real_provider_api_call_allowed"`
	RealFileDeliveryAllowed       bool                             `json:"real_file_delivery_allowed"`
	RealCustomerDataExportAllowed bool                             `json:"real_customer_data_export_allowed"`
	RealERPWriteAllowed           bool                             `json:"real_erp_write_allowed"`
	CreatedAt                     time.Time                        `json:"created_at"`
}

type CommercialLiveReadyAuditEvent struct {
	EventCode string    `json:"event_code"`
	Status    string    `json:"status"`
	Reason    string    `json:"reason,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type CommercialLiveReadyControlPlaneRuntime struct {
	gate        CommercialLiveReadyGate
	auditEvents []CommercialLiveReadyAuditEvent
	now         func() time.Time
}

func NewDefaultCommercialLiveReadyControlPlaneRuntime() *CommercialLiveReadyControlPlaneRuntime {
	return &CommercialLiveReadyControlPlaneRuntime{
		gate:        DefaultCommercialLiveReadyGate(),
		auditEvents: []CommercialLiveReadyAuditEvent{},
		now:         time.Now,
	}
}

func (r *CommercialLiveReadyControlPlaneRuntime) BuildLiveReadyReport(input CommercialLiveReadyActivationInput) (CommercialLiveReadyReport, error) {
	if err := r.gate.AssertRealOperationsClosed(); err != nil {
		r.appendAudit("COMMERCIAL_LIVE_READY_REPORT_DENIED", CommercialLiveReadyStatusFail, err.Error())
		return CommercialLiveReadyReport{}, err
	}
	requirements := BuildCommercialLiveReadyRequirements(input)
	report := CommercialLiveReadyReport{
		ModuleCode:                    CommercialLiveReadyModuleCode,
		Mode:                          CommercialLiveReadyMode,
		Status:                        CommercialLiveReadyStatusControlPlaneReady,
		Gate:                          r.gate,
		Requirements:                  requirements,
		ProviderDryRunSet:             CommercialLiveReadyProviderDryRunSet,
		NextModules:                   DefaultCommercialLiveReadyNextModules(),
		LiveOperationPolicies:         DefaultCommercialLiveReadyPolicies(),
		ProductionActivationAllowed:   false,
		RealMoneyMovementAllowed:      false,
		RealProviderAPICallAllowed:    false,
		RealFileDeliveryAllowed:       false,
		RealCustomerDataExportAllowed: false,
		RealERPWriteAllowed:           false,
		CreatedAt:                     r.now().UTC(),
	}
	r.appendAudit("COMMERCIAL_LIVE_READY_REPORT_BUILT", CommercialLiveReadyStatusControlPlaneReady, "")
	return report, nil
}

func (r *CommercialLiveReadyControlPlaneRuntime) EvaluateProductionActivation(input CommercialLiveReadyActivationInput) CommercialLiveReadyActivationDecision {
	missing := MissingCommercialLiveReadyRequirements(input)
	decision := CommercialLiveReadyActivationDecision{
		DecisionID:                    commercialLiveReadyID("COMMERCIAL-ACTIVATION-DECISION", CommercialLiveReadyModuleCode),
		ModuleCode:                    CommercialLiveReadyModuleCode,
		Allowed:                       false,
		Status:                        CommercialLiveReadyStatusBlocked,
		Reason:                        CommercialLiveReadyStatusActivationLocked,
		MissingRequirements:           missing,
		ProductionActivationLock:      r.gate.ProductionActivationLock,
		RealMoneyMovementAllowed:      false,
		RealProviderAPICallAllowed:    false,
		RealCustomerDataExportAllowed: false,
		RealERPWriteAllowed:           false,
		CreatedAt:                     r.now().UTC(),
	}

	if len(missing) > 0 {
		decision.Reason = "missing live-ready requirements"
		r.appendAudit("COMMERCIAL_PRODUCTION_ACTIVATION_BLOCKED", CommercialLiveReadyStatusBlocked, decision.Reason)
		return decision
	}

	if r.gate.ProductionActivationLock == CommercialLiveReadyStatusActivationLocked {
		decision.Reason = CommercialLiveReadyStatusActivationLocked
		r.appendAudit("COMMERCIAL_PRODUCTION_ACTIVATION_BLOCKED", CommercialLiveReadyStatusBlocked, decision.Reason)
		return decision
	}

	decision.Reason = "production activation requires later live module"
	r.appendAudit("COMMERCIAL_PRODUCTION_ACTIVATION_BLOCKED", CommercialLiveReadyStatusBlocked, decision.Reason)
	return decision
}

func (r *CommercialLiveReadyControlPlaneRuntime) RequestRealBilling() error {
	r.appendAudit("COMMERCIAL_REAL_BILLING_BLOCKED", CommercialLiveReadyStatusClosed, CommercialLiveReadyNoRealBillingPolicy)
	return ErrCommercialLiveReadyRealOperationClosed
}

func (r *CommercialLiveReadyControlPlaneRuntime) RequestRealPaymentCapture() error {
	r.appendAudit("COMMERCIAL_REAL_PAYMENT_CAPTURE_BLOCKED", CommercialLiveReadyStatusClosed, CommercialLiveReadyNoRealPaymentPolicy)
	return ErrCommercialLiveReadyRealOperationClosed
}

func (r *CommercialLiveReadyControlPlaneRuntime) RequestRealProviderAPI(providerCode string) error {
	_ = providerCode
	r.appendAudit("COMMERCIAL_REAL_PROVIDER_API_BLOCKED", CommercialLiveReadyStatusClosed, CommercialLiveReadyNoRealProviderAPIPolicy)
	return ErrCommercialLiveReadyRealOperationClosed
}

func (r *CommercialLiveReadyControlPlaneRuntime) RequestRealFileDelivery(providerCode string) error {
	_ = providerCode
	r.appendAudit("COMMERCIAL_REAL_FILE_DELIVERY_BLOCKED", CommercialLiveReadyStatusClosed, CommercialLiveReadyNoRealFileDeliveryPolicy)
	return ErrCommercialLiveReadyRealOperationClosed
}

func (r *CommercialLiveReadyControlPlaneRuntime) RequestRealERPWrite() error {
	r.appendAudit("COMMERCIAL_REAL_ERP_WRITE_BLOCKED", CommercialLiveReadyStatusClosed, CommercialLiveReadyNoRealERPWritePolicy)
	return ErrCommercialLiveReadyRealOperationClosed
}

func (r *CommercialLiveReadyControlPlaneRuntime) RequestRealCustomerDataExport() error {
	r.appendAudit("COMMERCIAL_REAL_CUSTOMER_DATA_EXPORT_BLOCKED", CommercialLiveReadyStatusClosed, CommercialLiveReadyNoRealCustomerDataPolicy)
	return ErrCommercialLiveReadyRealOperationClosed
}

func (r *CommercialLiveReadyControlPlaneRuntime) Gate() CommercialLiveReadyGate {
	return r.gate
}

func (r *CommercialLiveReadyControlPlaneRuntime) AuditEvents() []CommercialLiveReadyAuditEvent {
	out := make([]CommercialLiveReadyAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *CommercialLiveReadyControlPlaneRuntime) appendAudit(code, status, reason string) {
	r.auditEvents = append(r.auditEvents, CommercialLiveReadyAuditEvent{
		EventCode: code,
		Status:    status,
		Reason:    reason,
		CreatedAt: r.now().UTC(),
	})
}

func BuildCommercialLiveReadyRequirements(input CommercialLiveReadyActivationInput) []CommercialLiveReadyRequirement {
	requirements := []CommercialLiveReadyRequirement{
		requirement(RequirementBillingLiveReady, input.BillingLiveReady, "billing live-ready runtime prepared"),
		requirement(RequirementPaymentCaptureReady, input.PaymentCaptureReady, "payment capture live-ready runtime prepared"),
		requirement(RequirementProviderLiveReady, input.ProviderLiveReady, "provider live adapter readiness prepared"),
		requirement(RequirementExportLiveReady, input.ExportLiveReady, "export live-ready pipeline prepared"),
		requirement(RequirementERPSyncLiveReady, input.ERPSyncLiveReady, "ERP sync worker live-ready runtime prepared"),
		requirement(RequirementSecretsReady, input.SecretsReady, "production secrets contract prepared"),
		requirement(RequirementLegalApprovalReady, input.LegalApprovalReady, "legal approval gate prepared"),
		requirement(RequirementFinanceApprovalReady, input.FinanceApprovalReady, "finance approval gate prepared"),
		requirement(RequirementSecurityApprovalReady, input.SecurityApprovalReady, "security approval gate prepared"),
		requirement(RequirementOperatorApprovalReady, input.OperatorApprovalReady, "operator approval gate prepared"),
		requirement(RequirementRollbackReady, input.RollbackReady, "rollback plan prepared"),
		requirement(RequirementObservabilityReady, input.ObservabilityReady, "observability and alerting prepared"),
		requirement(RequirementIncidentResponseReady, input.IncidentResponseReady, "incident response prepared"),
		requirement(RequirementTenantIsolationReady, input.TenantIsolationReady, "tenant isolation verified for live operations"),
	}
	sort.Slice(requirements, func(i, j int) bool {
		return requirements[i].Code < requirements[j].Code
	})
	return requirements
}

func MissingCommercialLiveReadyRequirements(input CommercialLiveReadyActivationInput) []string {
	missing := []string{}
	for _, req := range BuildCommercialLiveReadyRequirements(input) {
		if req.Required && !req.Ready {
			missing = append(missing, req.Code)
		}
	}
	sort.Strings(missing)
	return missing
}

func DefaultCommercialLiveReadyNextModules() []string {
	return []string{
		"FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME",
		"FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME",
		"FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS",
		"FAZ_7_17_EXPORT_LIVE_READY_PIPELINE",
		"FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME",
		"FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX",
		"FAZ_7_20_COMMERCIAL_MASTER_CLOSURE",
	}
}

func DefaultCommercialLiveReadyPolicies() map[string]string {
	return map[string]string{
		"money_movement":       CommercialLiveReadyNoRealMoneyPolicy,
		"billing":              CommercialLiveReadyNoRealBillingPolicy,
		"payment_capture":      CommercialLiveReadyNoRealPaymentPolicy,
		"provider_api":         CommercialLiveReadyNoRealProviderAPIPolicy,
		"file_delivery":        CommercialLiveReadyNoRealFileDeliveryPolicy,
		"erp_write":            CommercialLiveReadyNoRealERPWritePolicy,
		"customer_data_export": CommercialLiveReadyNoRealCustomerDataPolicy,
	}
}

func AllCommercialLiveReadyInput() CommercialLiveReadyActivationInput {
	return CommercialLiveReadyActivationInput{
		BillingLiveReady:      true,
		PaymentCaptureReady:   true,
		ProviderLiveReady:     true,
		ExportLiveReady:       true,
		ERPSyncLiveReady:      true,
		SecretsReady:          true,
		LegalApprovalReady:    true,
		FinanceApprovalReady:  true,
		SecurityApprovalReady: true,
		OperatorApprovalReady: true,
		RollbackReady:         true,
		ObservabilityReady:    true,
		IncidentResponseReady: true,
		TenantIsolationReady:  true,
	}
}

func requirement(code string, ready bool, description string) CommercialLiveReadyRequirement {
	status := CommercialLiveReadyStatusRequiredNotReady
	if ready {
		status = CommercialLiveReadyStatusRequiredReady
	}
	return CommercialLiveReadyRequirement{
		Code:        code,
		Required:    true,
		Ready:       ready,
		Status:      status,
		Description: description,
	}
}

func commercialLiveReadyID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
