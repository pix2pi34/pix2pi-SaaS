package accountantportal

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	AccountantPortalFinalClosureModuleCode = "FAZ_7_12_ACCOUNTANT_PORTAL_FINAL_CLOSURE"

	AccountantPortalFinalClosureMode = "ACCOUNTANT_PORTAL_FINAL_CLOSURE_COMMERCIAL_HANDOFF_GATE"

	AccountantPortalFinalClosureStatusPass       = "PASS"
	AccountantPortalFinalClosureStatusFail       = "FAIL"
	AccountantPortalFinalClosureSealStatusSealed = "SEALED"
	AccountantPortalFinalClosureStatusReady      = "READY"
	AccountantPortalFinalClosureStatusNotStarted = "NOT_STARTED"
	AccountantPortalFinalClosureStatusClosed     = "CLOSED"

	AccountantPortalCommercialHandoffGateReady = "READY_FOR_COMMERCIAL_LIVE_MODULE"
	AccountantPortalLiveModuleStatusNotStarted = "NOT_STARTED"

	AccountantPortalFinalClosedUntilBillingLiveModule    = "CLOSED_UNTIL_BILLING_LIVE_MODULE"
	AccountantPortalFinalClosedUntilPaymentLiveModule    = "CLOSED_UNTIL_BILLING_LIVE_MODULE"
	AccountantPortalFinalClosedUntilProviderLiveModule   = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	AccountantPortalFinalClosedUntilSyncWorkerLiveModule = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	AccountantPortalFinalClosedUntilExportLiveModule     = "CLOSED_UNTIL_EXPORT_LIVE_MODULE"

	AccountantPortalFinalNoRealBillingPolicy      = "NO_REAL_ACCOUNTANT_BILLING_IN_FINAL_CLOSURE"
	AccountantPortalFinalNoRealPaymentPolicy      = "NO_REAL_PAYMENT_CAPTURE_IN_FINAL_CLOSURE"
	AccountantPortalFinalNoRealProviderAPIPolicy  = "NO_REAL_PROVIDER_API_OPERATION_IN_FINAL_CLOSURE"
	AccountantPortalFinalNoRealFileDeliveryPolicy = "NO_REAL_FILE_DELIVERY_IN_FINAL_CLOSURE"
	AccountantPortalFinalNoRealERPWritePolicy     = "NO_REAL_ERP_WRITE_IN_FINAL_CLOSURE"
	AccountantPortalFinalNoRealCustomerDataPolicy = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FINAL_CLOSURE"

	AccountantPortalProviderDryRunSet = "PARASUT_LOGO_MIKRO_ZIRVE"
)

var ErrAccountantPortalFinalLiveOperationClosed = errors.New("accountant portal live operation is closed in FAZ 7-12 final closure")

type AccountantPortalDependencySeal struct {
	ModuleCode   string `json:"module_code"`
	FinalStatus  string `json:"final_status"`
	SealStatus   string `json:"seal_status"`
	GateStatus   string `json:"gate_status"`
	EvidenceFile string `json:"evidence_file"`
}

type AccountantPortalProviderClosureStatus struct {
	ProviderCode          string `json:"provider_code"`
	DryRunSealStatus      string `json:"dry_run_seal_status"`
	ProviderLiveStatus    string `json:"provider_live_status"`
	RealProviderAPIStatus string `json:"real_provider_api_status"`
	RealFileDelivery      string `json:"real_file_delivery_status"`
	RealERPWriteStatus    string `json:"real_erp_write_status"`
}

type AccountantPortalFinalClosureGate struct {
	RealAccountantBillingStatus      string `json:"real_accountant_billing_status"`
	RealPaymentCaptureStatus         string `json:"real_payment_capture_status"`
	RealProviderAPIStatus            string `json:"real_provider_api_status"`
	RealFileDeliveryStatus           string `json:"real_file_delivery_status"`
	RealERPWriteStatus               string `json:"real_erp_write_status"`
	RealCustomerDataExportLiveStatus string `json:"real_customer_data_export_live_status"`
	RealOperatorProviderActionStatus string `json:"real_operator_provider_action_status"`
	CommercialLiveModuleStatus       string `json:"commercial_live_module_status"`
	ProviderLiveModulesStatus        string `json:"provider_live_modules_status"`
	SyncWorkerLiveModuleStatus       string `json:"sync_worker_live_module_status"`
	ExportLiveModuleStatus           string `json:"export_live_module_status"`
}

func DefaultAccountantPortalFinalClosureGate() AccountantPortalFinalClosureGate {
	return AccountantPortalFinalClosureGate{
		RealAccountantBillingStatus:      AccountantPortalFinalClosedUntilBillingLiveModule,
		RealPaymentCaptureStatus:         AccountantPortalFinalClosedUntilPaymentLiveModule,
		RealProviderAPIStatus:            AccountantPortalFinalClosedUntilProviderLiveModule,
		RealFileDeliveryStatus:           AccountantPortalFinalClosedUntilProviderLiveModule,
		RealERPWriteStatus:               AccountantPortalFinalClosedUntilSyncWorkerLiveModule,
		RealCustomerDataExportLiveStatus: AccountantPortalFinalClosedUntilExportLiveModule,
		RealOperatorProviderActionStatus: AccountantPortalFinalClosedUntilProviderLiveModule,
		CommercialLiveModuleStatus:       AccountantPortalLiveModuleStatusNotStarted,
		ProviderLiveModulesStatus:        AccountantPortalLiveModuleStatusNotStarted,
		SyncWorkerLiveModuleStatus:       AccountantPortalLiveModuleStatusNotStarted,
		ExportLiveModuleStatus:           AccountantPortalLiveModuleStatusNotStarted,
	}
}

func (g AccountantPortalFinalClosureGate) AssertLiveOperationsClosed() error {
	checks := map[string]string{
		"real_accountant_billing_status":        g.RealAccountantBillingStatus,
		"real_payment_capture_status":           g.RealPaymentCaptureStatus,
		"real_provider_api_status":              g.RealProviderAPIStatus,
		"real_file_delivery_status":             g.RealFileDeliveryStatus,
		"real_erp_write_status":                 g.RealERPWriteStatus,
		"real_customer_data_export_live_status": g.RealCustomerDataExportLiveStatus,
		"real_operator_provider_action_status":  g.RealOperatorProviderActionStatus,
	}
	for name, value := range checks {
		if !strings.HasPrefix(value, "CLOSED_") {
			return fmt.Errorf("%s must remain closed, got %q", name, value)
		}
	}
	if g.CommercialLiveModuleStatus != AccountantPortalLiveModuleStatusNotStarted {
		return fmt.Errorf("commercial live module must remain NOT_STARTED, got %q", g.CommercialLiveModuleStatus)
	}
	if g.ProviderLiveModulesStatus != AccountantPortalLiveModuleStatusNotStarted {
		return fmt.Errorf("provider live modules must remain NOT_STARTED, got %q", g.ProviderLiveModulesStatus)
	}
	if g.SyncWorkerLiveModuleStatus != AccountantPortalLiveModuleStatusNotStarted {
		return fmt.Errorf("sync worker live module must remain NOT_STARTED, got %q", g.SyncWorkerLiveModuleStatus)
	}
	if g.ExportLiveModuleStatus != AccountantPortalLiveModuleStatusNotStarted {
		return fmt.Errorf("export live module must remain NOT_STARTED, got %q", g.ExportLiveModuleStatus)
	}
	return nil
}

type AccountantPortalFinalClosureReport struct {
	ModuleCode                   string                                  `json:"module_code"`
	Mode                         string                                  `json:"mode"`
	FinalStatus                  string                                  `json:"final_status"`
	SealStatus                   string                                  `json:"seal_status"`
	CommercialHandoffGate        string                                  `json:"commercial_handoff_gate"`
	AccountantPortalModuleStatus string                                  `json:"accountant_portal_module_status"`
	CommercialLiveModuleStatus   string                                  `json:"commercial_live_module_status"`
	ProviderDryRunSet            string                                  `json:"provider_dry_run_set"`
	Dependencies                 []AccountantPortalDependencySeal        `json:"dependencies"`
	ProviderStatuses             []AccountantPortalProviderClosureStatus `json:"provider_statuses"`
	Gate                         AccountantPortalFinalClosureGate        `json:"gate"`
	LiveOperationPolicies        map[string]string                       `json:"live_operation_policies"`
	AllRealOperationsClosed      bool                                    `json:"all_real_operations_closed"`
	NextRecommendedModule        string                                  `json:"next_recommended_module"`
	CreatedAt                    time.Time                               `json:"created_at"`
}

type AccountantPortalFinalClosureAuditEvent struct {
	EventCode string    `json:"event_code"`
	Status    string    `json:"status"`
	Reason    string    `json:"reason,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type AccountantPortalFinalClosureRuntime struct {
	gate        AccountantPortalFinalClosureGate
	deps        []AccountantPortalDependencySeal
	providers   []AccountantPortalProviderClosureStatus
	auditEvents []AccountantPortalFinalClosureAuditEvent
	now         func() time.Time
}

func NewDefaultAccountantPortalFinalClosureRuntime() *AccountantPortalFinalClosureRuntime {
	return &AccountantPortalFinalClosureRuntime{
		gate:        DefaultAccountantPortalFinalClosureGate(),
		deps:        defaultAccountantPortalDependencies(),
		providers:   defaultAccountantPortalProviderClosureStatuses(),
		auditEvents: []AccountantPortalFinalClosureAuditEvent{},
		now:         time.Now,
	}
}

func (r *AccountantPortalFinalClosureRuntime) BuildFinalClosureReport() (AccountantPortalFinalClosureReport, error) {
	if err := r.validateDependencies(); err != nil {
		r.appendAudit("ACCOUNTANT_PORTAL_FINAL_CLOSURE_DENIED", AccountantPortalFinalClosureStatusFail, err.Error())
		return AccountantPortalFinalClosureReport{}, err
	}
	if err := r.validateProviders(); err != nil {
		r.appendAudit("ACCOUNTANT_PORTAL_FINAL_CLOSURE_DENIED", AccountantPortalFinalClosureStatusFail, err.Error())
		return AccountantPortalFinalClosureReport{}, err
	}
	if err := r.gate.AssertLiveOperationsClosed(); err != nil {
		r.appendAudit("ACCOUNTANT_PORTAL_FINAL_CLOSURE_DENIED", AccountantPortalFinalClosureStatusFail, err.Error())
		return AccountantPortalFinalClosureReport{}, err
	}
	report := AccountantPortalFinalClosureReport{
		ModuleCode:                   AccountantPortalFinalClosureModuleCode,
		Mode:                         AccountantPortalFinalClosureMode,
		FinalStatus:                  AccountantPortalFinalClosureStatusPass,
		SealStatus:                   AccountantPortalFinalClosureSealStatusSealed,
		CommercialHandoffGate:        AccountantPortalCommercialHandoffGateReady,
		AccountantPortalModuleStatus: AccountantPortalFinalClosureSealStatusSealed,
		CommercialLiveModuleStatus:   AccountantPortalLiveModuleStatusNotStarted,
		ProviderDryRunSet:            AccountantPortalProviderDryRunSet,
		Dependencies:                 cloneDependencySeals(r.deps),
		ProviderStatuses:             cloneProviderStatuses(r.providers),
		Gate:                         r.gate,
		LiveOperationPolicies: map[string]string{
			"billing":              AccountantPortalFinalNoRealBillingPolicy,
			"payment_capture":      AccountantPortalFinalNoRealPaymentPolicy,
			"provider_api":         AccountantPortalFinalNoRealProviderAPIPolicy,
			"file_delivery":        AccountantPortalFinalNoRealFileDeliveryPolicy,
			"erp_write":            AccountantPortalFinalNoRealERPWritePolicy,
			"customer_data_export": AccountantPortalFinalNoRealCustomerDataPolicy,
		},
		AllRealOperationsClosed: true,
		NextRecommendedModule:   "FAZ_7_COMMERCIAL_MODULE_MASTER_CLOSURE_OR_NEXT_PHASE_PLANNING",
		CreatedAt:               r.now().UTC(),
	}
	r.appendAudit("ACCOUNTANT_PORTAL_FINAL_CLOSURE_BUILT", AccountantPortalFinalClosureStatusPass, "")
	return report, nil
}

func (r *AccountantPortalFinalClosureRuntime) RequestRealAccountantBilling() error {
	r.appendAudit("ACCOUNTANT_PORTAL_REAL_BILLING_BLOCKED", AccountantPortalFinalClosureStatusClosed, AccountantPortalFinalNoRealBillingPolicy)
	return ErrAccountantPortalFinalLiveOperationClosed
}

func (r *AccountantPortalFinalClosureRuntime) RequestRealPaymentCapture() error {
	r.appendAudit("ACCOUNTANT_PORTAL_REAL_PAYMENT_CAPTURE_BLOCKED", AccountantPortalFinalClosureStatusClosed, AccountantPortalFinalNoRealPaymentPolicy)
	return ErrAccountantPortalFinalLiveOperationClosed
}

func (r *AccountantPortalFinalClosureRuntime) RequestRealProviderAPI(providerCode string) error {
	_ = providerCode
	r.appendAudit("ACCOUNTANT_PORTAL_REAL_PROVIDER_API_BLOCKED", AccountantPortalFinalClosureStatusClosed, AccountantPortalFinalNoRealProviderAPIPolicy)
	return ErrAccountantPortalFinalLiveOperationClosed
}

func (r *AccountantPortalFinalClosureRuntime) RequestRealFileDelivery(providerCode string) error {
	_ = providerCode
	r.appendAudit("ACCOUNTANT_PORTAL_REAL_FILE_DELIVERY_BLOCKED", AccountantPortalFinalClosureStatusClosed, AccountantPortalFinalNoRealFileDeliveryPolicy)
	return ErrAccountantPortalFinalLiveOperationClosed
}

func (r *AccountantPortalFinalClosureRuntime) RequestRealERPWrite() error {
	r.appendAudit("ACCOUNTANT_PORTAL_REAL_ERP_WRITE_BLOCKED", AccountantPortalFinalClosureStatusClosed, AccountantPortalFinalNoRealERPWritePolicy)
	return ErrAccountantPortalFinalLiveOperationClosed
}

func (r *AccountantPortalFinalClosureRuntime) RequestRealCustomerDataExport() error {
	r.appendAudit("ACCOUNTANT_PORTAL_REAL_CUSTOMER_DATA_EXPORT_BLOCKED", AccountantPortalFinalClosureStatusClosed, AccountantPortalFinalNoRealCustomerDataPolicy)
	return ErrAccountantPortalFinalLiveOperationClosed
}

func (r *AccountantPortalFinalClosureRuntime) AuditEvents() []AccountantPortalFinalClosureAuditEvent {
	out := make([]AccountantPortalFinalClosureAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *AccountantPortalFinalClosureRuntime) Gate() AccountantPortalFinalClosureGate {
	return r.gate
}

func (r *AccountantPortalFinalClosureRuntime) validateDependencies() error {
	if len(r.deps) == 0 {
		return errors.New("accountant portal dependencies are required")
	}
	for _, dep := range r.deps {
		if dep.FinalStatus != AccountantPortalFinalClosureStatusPass {
			return fmt.Errorf("dependency %s final status must be PASS, got %s", dep.ModuleCode, dep.FinalStatus)
		}
		if dep.SealStatus != AccountantPortalFinalClosureSealStatusSealed {
			return fmt.Errorf("dependency %s seal status must be SEALED, got %s", dep.ModuleCode, dep.SealStatus)
		}
		if dep.GateStatus == "" {
			return fmt.Errorf("dependency %s gate status is required", dep.ModuleCode)
		}
	}
	return nil
}

func (r *AccountantPortalFinalClosureRuntime) validateProviders() error {
	if len(r.providers) != 4 {
		return fmt.Errorf("expected four dry-run providers, got %d", len(r.providers))
	}
	seen := map[string]bool{}
	for _, provider := range r.providers {
		if provider.ProviderCode == "" {
			return errors.New("provider code is required")
		}
		seen[provider.ProviderCode] = true
		if provider.DryRunSealStatus != AccountantPortalFinalClosureSealStatusSealed {
			return fmt.Errorf("provider %s dry-run seal must be SEALED", provider.ProviderCode)
		}
		if provider.ProviderLiveStatus != AccountantPortalLiveModuleStatusNotStarted {
			return fmt.Errorf("provider %s live module must remain NOT_STARTED", provider.ProviderCode)
		}
		if !strings.HasPrefix(provider.RealProviderAPIStatus, "CLOSED_") {
			return fmt.Errorf("provider %s real provider API must remain closed", provider.ProviderCode)
		}
		if !strings.HasPrefix(provider.RealFileDelivery, "CLOSED_") {
			return fmt.Errorf("provider %s real file delivery must remain closed", provider.ProviderCode)
		}
		if !strings.HasPrefix(provider.RealERPWriteStatus, "CLOSED_") {
			return fmt.Errorf("provider %s real ERP write must remain closed", provider.ProviderCode)
		}
	}
	for _, required := range []string{"PARASUT", "LOGO", "MIKRO", "ZIRVE"} {
		if !seen[required] {
			return fmt.Errorf("provider %s is required in dry-run set", required)
		}
	}
	return nil
}

func (r *AccountantPortalFinalClosureRuntime) appendAudit(code, status, reason string) {
	r.auditEvents = append(r.auditEvents, AccountantPortalFinalClosureAuditEvent{
		EventCode: code,
		Status:    status,
		Reason:    reason,
		CreatedAt: r.now().UTC(),
	})
}

func defaultAccountantPortalDependencies() []AccountantPortalDependencySeal {
	return []AccountantPortalDependencySeal{
		{
			ModuleCode:   "FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE",
			FinalStatus:  AccountantPortalFinalClosureStatusPass,
			SealStatus:   AccountantPortalFinalClosureSealStatusSealed,
			GateStatus:   "READY_AFTER_TEST_AND_AUDIT_PASS",
			EvidenceFile: "docs/faz7/evidence/FAZ_7_9_ACCOUNTANT_PORTAL_COMMERCIAL_SURFACE_REAL_IMPLEMENTATION_AUDIT.md",
		},
		{
			ModuleCode:   "FAZ_7_10_ACCOUNTANT_PORTAL_ACCESS_RUNTIME",
			FinalStatus:  AccountantPortalFinalClosureStatusPass,
			SealStatus:   AccountantPortalFinalClosureSealStatusSealed,
			GateStatus:   "READY_AFTER_TEST_AND_AUDIT_PASS",
			EvidenceFile: "docs/faz7/evidence/FAZ_7_10_FIX_V2_ACCOUNTANT_PORTAL_ACCESS_RUNTIME_REAL_IMPLEMENTATION_AUDIT.md",
		},
		{
			ModuleCode:   "FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW",
			FinalStatus:  AccountantPortalFinalClosureStatusPass,
			SealStatus:   AccountantPortalFinalClosureSealStatusSealed,
			GateStatus:   "READY_AFTER_TEST_AND_AUDIT_PASS",
			EvidenceFile: "docs/faz7/evidence/FAZ_7_11_ACCOUNTANT_PORTAL_REPORTING_EXPORT_PREVIEW_REAL_IMPLEMENTATION_AUDIT.md",
		},
	}
}

func defaultAccountantPortalProviderClosureStatuses() []AccountantPortalProviderClosureStatus {
	providers := []AccountantPortalProviderClosureStatus{
		{
			ProviderCode:          "PARASUT",
			DryRunSealStatus:      AccountantPortalFinalClosureSealStatusSealed,
			ProviderLiveStatus:    AccountantPortalLiveModuleStatusNotStarted,
			RealProviderAPIStatus: AccountantPortalFinalClosedUntilProviderLiveModule,
			RealFileDelivery:      AccountantPortalFinalClosedUntilProviderLiveModule,
			RealERPWriteStatus:    AccountantPortalFinalClosedUntilSyncWorkerLiveModule,
		},
		{
			ProviderCode:          "LOGO",
			DryRunSealStatus:      AccountantPortalFinalClosureSealStatusSealed,
			ProviderLiveStatus:    AccountantPortalLiveModuleStatusNotStarted,
			RealProviderAPIStatus: AccountantPortalFinalClosedUntilProviderLiveModule,
			RealFileDelivery:      AccountantPortalFinalClosedUntilProviderLiveModule,
			RealERPWriteStatus:    AccountantPortalFinalClosedUntilSyncWorkerLiveModule,
		},
		{
			ProviderCode:          "MIKRO",
			DryRunSealStatus:      AccountantPortalFinalClosureSealStatusSealed,
			ProviderLiveStatus:    AccountantPortalLiveModuleStatusNotStarted,
			RealProviderAPIStatus: AccountantPortalFinalClosedUntilProviderLiveModule,
			RealFileDelivery:      AccountantPortalFinalClosedUntilProviderLiveModule,
			RealERPWriteStatus:    AccountantPortalFinalClosedUntilSyncWorkerLiveModule,
		},
		{
			ProviderCode:          "ZIRVE",
			DryRunSealStatus:      AccountantPortalFinalClosureSealStatusSealed,
			ProviderLiveStatus:    AccountantPortalLiveModuleStatusNotStarted,
			RealProviderAPIStatus: AccountantPortalFinalClosedUntilProviderLiveModule,
			RealFileDelivery:      AccountantPortalFinalClosedUntilProviderLiveModule,
			RealERPWriteStatus:    AccountantPortalFinalClosedUntilSyncWorkerLiveModule,
		},
	}
	sort.Slice(providers, func(i, j int) bool {
		return providers[i].ProviderCode < providers[j].ProviderCode
	})
	return providers
}

func cloneDependencySeals(in []AccountantPortalDependencySeal) []AccountantPortalDependencySeal {
	out := make([]AccountantPortalDependencySeal, len(in))
	copy(out, in)
	return out
}

func cloneProviderStatuses(in []AccountantPortalProviderClosureStatus) []AccountantPortalProviderClosureStatus {
	out := make([]AccountantPortalProviderClosureStatus, len(in))
	copy(out, in)
	return out
}
