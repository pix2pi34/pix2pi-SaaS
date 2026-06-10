package liveready

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	CommercialMasterClosureModuleCode = "FAZ_7_20_COMMERCIAL_MASTER_CLOSURE"

	CommercialMasterClosureMode = "COMMERCIAL_MASTER_CLOSURE_WITH_PRODUCTION_ACTIVATION_DISABLED"

	CommercialMasterClosureStatusReady          = "COMMERCIAL_MASTER_CLOSURE_READY"
	CommercialMasterClosureStatusPass           = "PASS"
	CommercialMasterClosureStatusFail           = "FAIL"
	CommercialMasterClosureStatusSealed         = "SEALED"
	CommercialMasterClosureStatusOpen           = "OPEN"
	CommercialMasterClosureStatusBlocked        = "BLOCKED"
	CommercialMasterClosureStatusClosed         = "CLOSED"
	CommercialMasterClosureStatusFinalized      = "FAZ_7_COMMERCIAL_MASTER_FINALIZED"
	CommercialMasterClosureStatusProductionLock = "PRODUCTION_ACTIVATION_LOCKED_AFTER_FAZ_7"
	CommercialMasterClosureStatusHandoffReady   = "READY_FOR_NEXT_PHASE_PLANNING"
	CommercialMasterClosureStatusAuditReady     = "AUDIT_READY"

	CommercialMasterClosureNoProductionActivationPolicy = "NO_PRODUCTION_ACTIVATION_IN_FAZ_7_20"
	CommercialMasterClosureNoRealMoneyPolicy            = "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_20"
	CommercialMasterClosureNoRealBillingPolicy          = "NO_REAL_BILLING_IN_FAZ_7_20"
	CommercialMasterClosureNoRealPaymentPolicy          = "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_20"
	CommercialMasterClosureNoRealProviderAPIPolicy      = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_20"
	CommercialMasterClosureNoRealFileDeliveryPolicy     = "NO_REAL_FILE_DELIVERY_IN_FAZ_7_20"
	CommercialMasterClosureNoRealERPWritePolicy         = "NO_REAL_ERP_WRITE_IN_FAZ_7_20"
	CommercialMasterClosureNoRealCustomerExportPolicy   = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_20"
	CommercialMasterClosureNoRealLedgerPostingPolicy    = "NO_REAL_LEDGER_POSTING_IN_FAZ_7_20"
	CommercialMasterClosureNoRealOperatorActionPolicy   = "NO_REAL_OPERATOR_LIVE_ACTION_IN_FAZ_7_20"

	CommercialMasterClosureProviderDryRunSet = "PARASUT_LOGO_MIKRO_ZIRVE"

	CommercialMasterClosureDependencyPaymentModule      = "FAZ_7_5P_PAYMENT_PROVIDER_ADAPTER_MODULE"
	CommercialMasterClosureDependencyMarketplaceCatalog = "FAZ_7_8_MARKETPLACE_INTEGRATION_CATALOG_FOUNDATION"
	CommercialMasterClosureDependencyIntegrationFamily  = "FAZ_7_8_INTEGRATION_FAMILY_MASTER_CLOSURE"
	CommercialMasterClosureDependencyAccountantPortal   = "FAZ_7_ACCOUNTANT_PORTAL_FAMILY"
	CommercialMasterClosureDependencyCommercialControl  = "FAZ_7_13_COMMERCIAL_LIVE_READY_CONTROL_PLANE"
	CommercialMasterClosureDependencyBillingLiveReady   = "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME"
	CommercialMasterClosureDependencyPaymentLiveReady   = "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME"
	CommercialMasterClosureDependencyProviderLiveReady  = "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS"
	CommercialMasterClosureDependencyExportLiveReady    = "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE"
	CommercialMasterClosureDependencyERPSyncLiveReady   = "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME"
	CommercialMasterClosureDependencyActivationGuard    = "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX"
)

var ErrCommercialMasterClosureRealOperationClosed = errors.New("commercial master closure blocks real operation in FAZ 7-20")

type CommercialMasterClosureGate struct {
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

	CommercialMasterClosureStatus string `json:"commercial_master_closure_status"`
	FAZ7CommercialFinalStatus     string `json:"faz_7_commercial_final_status"`
	FAZ7CommercialSealStatus      string `json:"faz_7_commercial_seal_status"`
	ProductionActivationLock      string `json:"production_activation_lock"`
	ProviderDryRunSet             string `json:"provider_dry_run_set"`
	NextPhasePlanningStatus       string `json:"next_phase_planning_status"`
}

func DefaultCommercialMasterClosureGate() CommercialMasterClosureGate {
	return CommercialMasterClosureGate{
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

		CommercialMasterClosureStatus: CommercialMasterClosureStatusReady,
		FAZ7CommercialFinalStatus:     CommercialMasterClosureStatusPass,
		FAZ7CommercialSealStatus:      CommercialMasterClosureStatusSealed,
		ProductionActivationLock:      CommercialMasterClosureStatusProductionLock,
		ProviderDryRunSet:             CommercialMasterClosureProviderDryRunSet,
		NextPhasePlanningStatus:       CommercialMasterClosureStatusHandoffReady,
	}
}

func (g CommercialMasterClosureGate) AssertRealOperationsClosed() error {
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
			return fmt.Errorf("%s must remain false in FAZ 7-20", name)
		}
	}
	if g.ProductionActivationLock != CommercialMasterClosureStatusProductionLock {
		return fmt.Errorf("production activation lock must remain %s", CommercialMasterClosureStatusProductionLock)
	}
	return nil
}

type CommercialMasterDependencySeal struct {
	ModuleCode  string `json:"module_code"`
	FinalStatus string `json:"final_status"`
	SealStatus  string `json:"seal_status"`
	GateStatus  string `json:"gate_status"`
}

type CommercialMasterOpenItem struct {
	Code        string `json:"code"`
	Status      string `json:"status"`
	TargetPhase string `json:"target_phase"`
	Reason      string `json:"reason"`
}

type CommercialMasterClosureReport struct {
	ModuleCode                    string                           `json:"module_code"`
	Mode                          string                           `json:"mode"`
	FinalStatus                   string                           `json:"final_status"`
	SealStatus                    string                           `json:"seal_status"`
	Gate                          CommercialMasterClosureGate      `json:"gate"`
	DependencySeals               []CommercialMasterDependencySeal `json:"dependency_seals"`
	OpenLiveItems                 []CommercialMasterOpenItem       `json:"open_live_items"`
	LiveOperationPolicies         map[string]string                `json:"live_operation_policies"`
	ProviderDryRunSet             string                           `json:"provider_dry_run_set"`
	ProductionActivationAllowed   bool                             `json:"production_activation_allowed"`
	RealMoneyMovementAllowed      bool                             `json:"real_money_movement_allowed"`
	RealBillingAllowed            bool                             `json:"real_billing_allowed"`
	RealPaymentCaptureAllowed     bool                             `json:"real_payment_capture_allowed"`
	RealProviderAPICallAllowed    bool                             `json:"real_provider_api_call_allowed"`
	RealFileDeliveryAllowed       bool                             `json:"real_file_delivery_allowed"`
	RealERPWriteAllowed           bool                             `json:"real_erp_write_allowed"`
	RealCustomerDataExportAllowed bool                             `json:"real_customer_data_export_allowed"`
	RealLedgerPostingAllowed      bool                             `json:"real_ledger_posting_allowed"`
	NextPhasePlanningStatus       string                           `json:"next_phase_planning_status"`
	CreatedAt                     time.Time                        `json:"created_at"`
}

type CommercialMasterClosureDecision struct {
	DecisionID                    string    `json:"decision_id"`
	ModuleCode                    string    `json:"module_code"`
	Allowed                       bool      `json:"allowed"`
	FinalStatus                   string    `json:"final_status"`
	SealStatus                    string    `json:"seal_status"`
	Reason                        string    `json:"reason"`
	ProductionActivationAllowed   bool      `json:"production_activation_allowed"`
	RealMoneyMovementAllowed      bool      `json:"real_money_movement_allowed"`
	RealProviderAPICallAllowed    bool      `json:"real_provider_api_call_allowed"`
	RealERPWriteAllowed           bool      `json:"real_erp_write_allowed"`
	RealCustomerDataExportAllowed bool      `json:"real_customer_data_export_allowed"`
	CreatedAt                     time.Time `json:"created_at"`
}

type CommercialMasterClosureAuditEvent struct {
	EventCode string    `json:"event_code"`
	Status    string    `json:"status"`
	Reason    string    `json:"reason,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type CommercialMasterClosureRuntime struct {
	gate        CommercialMasterClosureGate
	auditEvents []CommercialMasterClosureAuditEvent
	now         func() time.Time
}

func NewDefaultCommercialMasterClosureRuntime() *CommercialMasterClosureRuntime {
	return &CommercialMasterClosureRuntime{
		gate:        DefaultCommercialMasterClosureGate(),
		auditEvents: []CommercialMasterClosureAuditEvent{},
		now:         time.Now,
	}
}

func (r *CommercialMasterClosureRuntime) BuildCommercialMasterClosureReport() (CommercialMasterClosureReport, error) {
	if err := r.gate.AssertRealOperationsClosed(); err != nil {
		r.appendAudit("COMMERCIAL_MASTER_CLOSURE_REPORT_DENIED", CommercialMasterClosureStatusBlocked, err.Error())
		return CommercialMasterClosureReport{}, err
	}
	deps := DefaultCommercialMasterDependencySeals()
	if err := validateCommercialMasterDependencySeals(deps); err != nil {
		r.appendAudit("COMMERCIAL_MASTER_CLOSURE_REPORT_DENIED", CommercialMasterClosureStatusBlocked, err.Error())
		return CommercialMasterClosureReport{}, err
	}
	report := CommercialMasterClosureReport{
		ModuleCode:                    CommercialMasterClosureModuleCode,
		Mode:                          CommercialMasterClosureMode,
		FinalStatus:                   CommercialMasterClosureStatusPass,
		SealStatus:                    CommercialMasterClosureStatusSealed,
		Gate:                          r.gate,
		DependencySeals:               deps,
		OpenLiveItems:                 DefaultCommercialMasterOpenLiveItems(),
		LiveOperationPolicies:         DefaultCommercialMasterClosurePolicies(),
		ProviderDryRunSet:             CommercialMasterClosureProviderDryRunSet,
		ProductionActivationAllowed:   false,
		RealMoneyMovementAllowed:      false,
		RealBillingAllowed:            false,
		RealPaymentCaptureAllowed:     false,
		RealProviderAPICallAllowed:    false,
		RealFileDeliveryAllowed:       false,
		RealERPWriteAllowed:           false,
		RealCustomerDataExportAllowed: false,
		RealLedgerPostingAllowed:      false,
		NextPhasePlanningStatus:       CommercialMasterClosureStatusHandoffReady,
		CreatedAt:                     r.now().UTC(),
	}
	r.appendAudit("COMMERCIAL_MASTER_CLOSURE_REPORT_BUILT", CommercialMasterClosureStatusFinalized, "")
	return report, nil
}

func (r *CommercialMasterClosureRuntime) FinalizeCommercialMasterClosure() (CommercialMasterClosureDecision, error) {
	if err := r.gate.AssertRealOperationsClosed(); err != nil {
		r.appendAudit("COMMERCIAL_MASTER_CLOSURE_FINALIZE_DENIED", CommercialMasterClosureStatusBlocked, err.Error())
		return CommercialMasterClosureDecision{}, err
	}
	deps := DefaultCommercialMasterDependencySeals()
	if err := validateCommercialMasterDependencySeals(deps); err != nil {
		r.appendAudit("COMMERCIAL_MASTER_CLOSURE_FINALIZE_DENIED", CommercialMasterClosureStatusBlocked, err.Error())
		return CommercialMasterClosureDecision{}, err
	}
	decision := CommercialMasterClosureDecision{
		DecisionID:                    commercialMasterClosureID("COMMERCIAL-MASTER-CLOSURE", CommercialMasterClosureModuleCode),
		ModuleCode:                    CommercialMasterClosureModuleCode,
		Allowed:                       true,
		FinalStatus:                   CommercialMasterClosureStatusPass,
		SealStatus:                    CommercialMasterClosureStatusSealed,
		Reason:                        CommercialMasterClosureStatusFinalized,
		ProductionActivationAllowed:   false,
		RealMoneyMovementAllowed:      false,
		RealProviderAPICallAllowed:    false,
		RealERPWriteAllowed:           false,
		RealCustomerDataExportAllowed: false,
		CreatedAt:                     r.now().UTC(),
	}
	r.appendAudit("COMMERCIAL_MASTER_CLOSURE_FINALIZED", CommercialMasterClosureStatusSealed, "")
	return decision, nil
}

func (r *CommercialMasterClosureRuntime) RequestProductionActivation() error {
	r.appendAudit("COMMERCIAL_MASTER_PRODUCTION_ACTIVATION_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoProductionActivationPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealMoneyMovement() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_MONEY_MOVEMENT_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealMoneyPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealBilling() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_BILLING_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealBillingPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealPaymentCapture() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_PAYMENT_CAPTURE_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealPaymentPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealProviderAPI() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_PROVIDER_API_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealProviderAPIPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealFileDelivery() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_FILE_DELIVERY_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealFileDeliveryPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealERPWrite() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_ERP_WRITE_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealERPWritePolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealCustomerDataExport() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_CUSTOMER_DATA_EXPORT_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealCustomerExportPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealLedgerPosting() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_LEDGER_POSTING_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealLedgerPostingPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) RequestRealOperatorLiveAction() error {
	r.appendAudit("COMMERCIAL_MASTER_REAL_OPERATOR_ACTION_BLOCKED", CommercialMasterClosureStatusClosed, CommercialMasterClosureNoRealOperatorActionPolicy)
	return ErrCommercialMasterClosureRealOperationClosed
}

func (r *CommercialMasterClosureRuntime) Gate() CommercialMasterClosureGate {
	return r.gate
}

func (r *CommercialMasterClosureRuntime) AuditEvents() []CommercialMasterClosureAuditEvent {
	out := make([]CommercialMasterClosureAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *CommercialMasterClosureRuntime) appendAudit(code, status, reason string) {
	r.auditEvents = append(r.auditEvents, CommercialMasterClosureAuditEvent{
		EventCode: code,
		Status:    status,
		Reason:    reason,
		CreatedAt: r.now().UTC(),
	})
}

func DefaultCommercialMasterDependencySeals() []CommercialMasterDependencySeal {
	deps := []CommercialMasterDependencySeal{
		{ModuleCode: CommercialMasterClosureDependencyPaymentModule, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "PAYMENT_PROVIDER_ADAPTER_MODULE_SEALED"},
		{ModuleCode: CommercialMasterClosureDependencyMarketplaceCatalog, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "MARKETPLACE_INTEGRATION_CATALOG_READY"},
		{ModuleCode: CommercialMasterClosureDependencyIntegrationFamily, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "PARASUT_LOGO_MIKRO_ZIRVE_SEALED"},
		{ModuleCode: CommercialMasterClosureDependencyAccountantPortal, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "ACCOUNTANT_PORTAL_FAMILY_SEALED"},
		{ModuleCode: CommercialMasterClosureDependencyCommercialControl, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "READY_FOR_LIVE_READY_MODULES"},
		{ModuleCode: CommercialMasterClosureDependencyBillingLiveReady, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "BILLING_LIVE_READY_RUNTIME_READY"},
		{ModuleCode: CommercialMasterClosureDependencyPaymentLiveReady, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "PAYMENT_CAPTURE_LIVE_READY_RUNTIME_READY"},
		{ModuleCode: CommercialMasterClosureDependencyProviderLiveReady, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "PROVIDER_LIVE_ADAPTER_READINESS_READY"},
		{ModuleCode: CommercialMasterClosureDependencyExportLiveReady, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "EXPORT_LIVE_READY_PIPELINE_READY"},
		{ModuleCode: CommercialMasterClosureDependencyERPSyncLiveReady, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "ERP_SYNC_WORKER_LIVE_READY_RUNTIME_READY"},
		{ModuleCode: CommercialMasterClosureDependencyActivationGuard, FinalStatus: CommercialMasterClosureStatusPass, SealStatus: CommercialMasterClosureStatusSealed, GateStatus: "LIVE_ACTIVATION_GUARD_READY"},
	}
	sort.Slice(deps, func(i, j int) bool {
		return deps[i].ModuleCode < deps[j].ModuleCode
	})
	return deps
}

func DefaultCommercialMasterOpenLiveItems() []CommercialMasterOpenItem {
	items := []CommercialMasterOpenItem{
		{Code: "PRODUCTION_ACTIVATION", Status: CommercialMasterClosureStatusClosed, TargetPhase: "PRODUCTION_ACTIVATION_MODULE", Reason: CommercialMasterClosureNoProductionActivationPolicy},
		{Code: "REAL_MONEY_MOVEMENT", Status: CommercialMasterClosureStatusClosed, TargetPhase: "PAYMENT_PROVIDER_LIVE_MODULE", Reason: CommercialMasterClosureNoRealMoneyPolicy},
		{Code: "REAL_BILLING", Status: CommercialMasterClosureStatusClosed, TargetPhase: "BILLING_LIVE_MODULE", Reason: CommercialMasterClosureNoRealBillingPolicy},
		{Code: "REAL_PAYMENT_CAPTURE", Status: CommercialMasterClosureStatusClosed, TargetPhase: "PAYMENT_CAPTURE_LIVE_MODULE", Reason: CommercialMasterClosureNoRealPaymentPolicy},
		{Code: "REAL_PROVIDER_API", Status: CommercialMasterClosureStatusClosed, TargetPhase: "PROVIDER_LIVE_MODULE", Reason: CommercialMasterClosureNoRealProviderAPIPolicy},
		{Code: "REAL_FILE_DELIVERY", Status: CommercialMasterClosureStatusClosed, TargetPhase: "FILE_DELIVERY_LIVE_MODULE", Reason: CommercialMasterClosureNoRealFileDeliveryPolicy},
		{Code: "REAL_ERP_WRITE", Status: CommercialMasterClosureStatusClosed, TargetPhase: "SYNC_WORKER_LIVE_MODULE", Reason: CommercialMasterClosureNoRealERPWritePolicy},
		{Code: "REAL_CUSTOMER_DATA_EXPORT", Status: CommercialMasterClosureStatusClosed, TargetPhase: "EXPORT_LIVE_MODULE", Reason: CommercialMasterClosureNoRealCustomerExportPolicy},
		{Code: "REAL_LEDGER_POSTING", Status: CommercialMasterClosureStatusClosed, TargetPhase: "LEDGER_POSTING_LIVE_MODULE", Reason: CommercialMasterClosureNoRealLedgerPostingPolicy},
		{Code: "REAL_OPERATOR_LIVE_ACTION", Status: CommercialMasterClosureStatusClosed, TargetPhase: "OPERATOR_APPROVAL_LIVE_MODULE", Reason: CommercialMasterClosureNoRealOperatorActionPolicy},
	}
	sort.Slice(items, func(i, j int) bool {
		return items[i].Code < items[j].Code
	})
	return items
}

func DefaultCommercialMasterClosurePolicies() map[string]string {
	return map[string]string{
		"production_activation": CommercialMasterClosureNoProductionActivationPolicy,
		"money_movement":        CommercialMasterClosureNoRealMoneyPolicy,
		"billing":               CommercialMasterClosureNoRealBillingPolicy,
		"payment_capture":       CommercialMasterClosureNoRealPaymentPolicy,
		"provider_api":          CommercialMasterClosureNoRealProviderAPIPolicy,
		"file_delivery":         CommercialMasterClosureNoRealFileDeliveryPolicy,
		"erp_write":             CommercialMasterClosureNoRealERPWritePolicy,
		"customer_data_export":  CommercialMasterClosureNoRealCustomerExportPolicy,
		"ledger_posting":        CommercialMasterClosureNoRealLedgerPostingPolicy,
		"operator_action":       CommercialMasterClosureNoRealOperatorActionPolicy,
	}
}

func validateCommercialMasterDependencySeals(deps []CommercialMasterDependencySeal) error {
	if len(deps) < 10 {
		return fmt.Errorf("commercial master closure requires broad dependency set, got %d", len(deps))
	}
	for _, dep := range deps {
		if strings.TrimSpace(dep.ModuleCode) == "" {
			return errors.New("dependency module code is required")
		}
		if dep.FinalStatus != CommercialMasterClosureStatusPass {
			return fmt.Errorf("dependency %s final status must be PASS", dep.ModuleCode)
		}
		if dep.SealStatus != CommercialMasterClosureStatusSealed {
			return fmt.Errorf("dependency %s seal status must be SEALED", dep.ModuleCode)
		}
		if strings.TrimSpace(dep.GateStatus) == "" {
			return fmt.Errorf("dependency %s gate status is required", dep.ModuleCode)
		}
	}
	return nil
}

func commercialMasterClosureID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
