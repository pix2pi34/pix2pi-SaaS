package liveready

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

const (
	AccountantBillingLiveReadyModuleCode = "FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME"

	AccountantBillingLiveReadyMode = "ACCOUNTANT_BILLING_LIVE_READY_WITH_REAL_BILLING_DISABLED"

	AccountantBillingLiveReadyStatusReady               = "BILLING_LIVE_READY_RUNTIME_READY"
	AccountantBillingLiveReadyStatusPlanBuilt           = "BILLING_ISSUE_PLAN_BUILT_NO_REAL_INVOICE"
	AccountantBillingLiveReadyStatusBlocked             = "BLOCKED"
	AccountantBillingLiveReadyStatusClosed              = "CLOSED"
	AccountantBillingLiveReadyStatusRequirementReady    = "REQUIRED_READY"
	AccountantBillingLiveReadyStatusRequirementNotReady = "REQUIRED_NOT_READY"
	AccountantBillingLiveReadyStatusProductionLocked    = "PRODUCTION_BILLING_LOCKED_IN_FAZ_7_14"
	AccountantBillingLiveReadyStatusInvoiceDraftOnly    = "INVOICE_DRAFT_ONLY_NO_REAL_INVOICE"
	AccountantBillingLiveReadyStatusNoMoneyMovement     = "NO_MONEY_MOVEMENT"
	AccountantBillingLiveReadyStatusTenantSafe          = "TENANT_SAFE"
	AccountantBillingLiveReadyStatusIdempotent          = "IDEMPOTENT"
	AccountantBillingLiveReadyStatusAuditReady          = "AUDIT_READY"
	AccountantBillingLiveReadyStatusRollbackReady       = "ROLLBACK_READY"
	AccountantBillingLiveReadyStatusLegalFinanceGuarded = "LEGAL_FINANCE_APPROVAL_GUARDED"

	AccountantBillingLiveReadyClosedUntilBillingLiveModule  = "CLOSED_UNTIL_BILLING_LIVE_MODULE"
	AccountantBillingLiveReadyClosedUntilPaymentLiveModule  = "CLOSED_UNTIL_PAYMENT_LIVE_MODULE"
	AccountantBillingLiveReadyClosedUntilApprovalMatrix     = "CLOSED_UNTIL_APPROVAL_MATRIX_PASS"
	AccountantBillingLiveReadyClosedUntilTaxLiveModule      = "CLOSED_UNTIL_TAX_LIVE_MODULE"
	AccountantBillingLiveReadyClosedUntilProviderLiveModule = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"

	AccountantBillingNoRealInvoicePolicy       = "NO_REAL_INVOICE_ISSUE_IN_FAZ_7_14"
	AccountantBillingNoRealBillingPolicy       = "NO_REAL_BILLING_COMMIT_IN_FAZ_7_14"
	AccountantBillingNoRealPaymentPolicy       = "NO_REAL_PAYMENT_CAPTURE_IN_FAZ_7_14"
	AccountantBillingNoRealMoneyMovementPolicy = "NO_REAL_MONEY_MOVEMENT_IN_FAZ_7_14"
	AccountantBillingNoRealTaxSubmissionPolicy = "NO_REAL_TAX_SUBMISSION_IN_FAZ_7_14"
	AccountantBillingNoRealProviderAPIPolicy   = "NO_REAL_PROVIDER_API_CALL_IN_FAZ_7_14"
	AccountantBillingNoRealCustomerDataPolicy  = "NO_REAL_CUSTOMER_DATA_EXPORT_IN_FAZ_7_14"

	BillingRequirementPlanCatalogReady         = "plan_catalog_ready"
	BillingRequirementSubscriptionReady        = "subscription_runtime_ready"
	BillingRequirementInvoiceDraftReady        = "invoice_draft_runtime_ready"
	BillingRequirementTenantAccountReady       = "tenant_account_binding_ready"
	BillingRequirementTaxConfigReady           = "tax_config_ready"
	BillingRequirementIdempotencyReady         = "billing_idempotency_ready"
	BillingRequirementAuditReady               = "billing_audit_ready"
	BillingRequirementRollbackReady            = "billing_rollback_ready"
	BillingRequirementLegalApprovalGateReady   = "legal_approval_gate_ready"
	BillingRequirementFinanceApprovalGateReady = "finance_approval_gate_ready"
	BillingRequirementSecurityGateReady        = "security_gate_ready"
	BillingRequirementObservabilityReady       = "billing_observability_ready"
)

var ErrAccountantBillingRealOperationClosed = errors.New("accountant billing real operation is closed in FAZ 7-14")

type AccountantBillingLiveReadyGate struct {
	ProductionBillingAllowed      bool `json:"production_billing_allowed"`
	RealInvoiceIssueAllowed       bool `json:"real_invoice_issue_allowed"`
	RealBillingCommitAllowed      bool `json:"real_billing_commit_allowed"`
	RealPaymentCaptureAllowed     bool `json:"real_payment_capture_allowed"`
	RealMoneyMovementAllowed      bool `json:"real_money_movement_allowed"`
	RealTaxSubmissionAllowed      bool `json:"real_tax_submission_allowed"`
	RealProviderAPICallAllowed    bool `json:"real_provider_api_call_allowed"`
	RealCustomerDataExportAllowed bool `json:"real_customer_data_export_allowed"`

	BillingLiveModuleStatus  string `json:"billing_live_module_status"`
	PaymentLiveModuleStatus  string `json:"payment_live_module_status"`
	ApprovalMatrixStatus     string `json:"approval_matrix_status"`
	TaxLiveModuleStatus      string `json:"tax_live_module_status"`
	ProviderLiveModuleStatus string `json:"provider_live_module_status"`
	ProductionBillingLock    string `json:"production_billing_lock"`
	ControlPlaneGate         string `json:"control_plane_gate"`
}

func DefaultAccountantBillingLiveReadyGate() AccountantBillingLiveReadyGate {
	return AccountantBillingLiveReadyGate{
		ProductionBillingAllowed:      false,
		RealInvoiceIssueAllowed:       false,
		RealBillingCommitAllowed:      false,
		RealPaymentCaptureAllowed:     false,
		RealMoneyMovementAllowed:      false,
		RealTaxSubmissionAllowed:      false,
		RealProviderAPICallAllowed:    false,
		RealCustomerDataExportAllowed: false,

		BillingLiveModuleStatus:  AccountantBillingLiveReadyStatusReady,
		PaymentLiveModuleStatus:  CommercialLiveReadyStatusNotStarted,
		ApprovalMatrixStatus:     AccountantBillingLiveReadyClosedUntilApprovalMatrix,
		TaxLiveModuleStatus:      AccountantBillingLiveReadyClosedUntilTaxLiveModule,
		ProviderLiveModuleStatus: AccountantBillingLiveReadyClosedUntilProviderLiveModule,
		ProductionBillingLock:    AccountantBillingLiveReadyStatusProductionLocked,
		ControlPlaneGate:         CommercialLiveReadyGateReady,
	}
}

func (g AccountantBillingLiveReadyGate) AssertRealBillingClosed() error {
	checks := map[string]bool{
		"production_billing_allowed":        g.ProductionBillingAllowed,
		"real_invoice_issue_allowed":        g.RealInvoiceIssueAllowed,
		"real_billing_commit_allowed":       g.RealBillingCommitAllowed,
		"real_payment_capture_allowed":      g.RealPaymentCaptureAllowed,
		"real_money_movement_allowed":       g.RealMoneyMovementAllowed,
		"real_tax_submission_allowed":       g.RealTaxSubmissionAllowed,
		"real_provider_api_call_allowed":    g.RealProviderAPICallAllowed,
		"real_customer_data_export_allowed": g.RealCustomerDataExportAllowed,
	}
	for name, value := range checks {
		if value {
			return fmt.Errorf("%s must remain false in FAZ 7-14", name)
		}
	}
	if g.ProductionBillingLock != AccountantBillingLiveReadyStatusProductionLocked {
		return fmt.Errorf("production billing lock must remain %s", AccountantBillingLiveReadyStatusProductionLocked)
	}
	return nil
}

type AccountantBillingLiveReadyInput struct {
	PlanCatalogReady          bool
	SubscriptionRuntimeReady  bool
	InvoiceDraftRuntimeReady  bool
	TenantAccountBindingReady bool
	TaxConfigReady            bool
	IdempotencyReady          bool
	AuditReady                bool
	RollbackReady             bool
	LegalApprovalGateReady    bool
	FinanceApprovalGateReady  bool
	SecurityGateReady         bool
	ObservabilityReady        bool
}

type AccountantBillingLiveReadyRequirement struct {
	Code        string `json:"code"`
	Required    bool   `json:"required"`
	Ready       bool   `json:"ready"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type AccountantBillingIssuePlanRequest struct {
	AccountantTenantID string
	FirmTenantID       string
	BillingAccountID   string
	SubscriptionID     string
	PlanCode           string
	PeriodYYYYMM       string
	IdempotencyKey     string
	Currency           string
	AmountTRY          int
	VatRateBasisPoints int
}

type AccountantBillingIssuePlan struct {
	PlanID                       string    `json:"plan_id"`
	ModuleCode                   string    `json:"module_code"`
	Mode                         string    `json:"mode"`
	AccountantTenantID           string    `json:"accountant_tenant_id"`
	FirmTenantID                 string    `json:"firm_tenant_id"`
	BillingAccountID             string    `json:"billing_account_id"`
	SubscriptionID               string    `json:"subscription_id"`
	PlanCode                     string    `json:"plan_code"`
	PeriodYYYYMM                 string    `json:"period_yyyy_mm"`
	IdempotencyKey               string    `json:"idempotency_key"`
	Currency                     string    `json:"currency"`
	NetAmountTRY                 int       `json:"net_amount_try"`
	VatRateBasisPoints           int       `json:"vat_rate_basis_points"`
	VatAmountTRY                 int       `json:"vat_amount_try"`
	GrossAmountTRY               int       `json:"gross_amount_try"`
	Status                       string    `json:"status"`
	RealInvoiceIssued            bool      `json:"real_invoice_issued"`
	RealBillingCommitted         bool      `json:"real_billing_committed"`
	RealPaymentCaptureRequested  bool      `json:"real_payment_capture_requested"`
	RealMoneyMovementAllowed     bool      `json:"real_money_movement_allowed"`
	RealTaxSubmissionRequested   bool      `json:"real_tax_submission_requested"`
	RealProviderAPICallRequested bool      `json:"real_provider_api_call_requested"`
	LiveOperationPolicy          string    `json:"live_operation_policy"`
	CreatedAt                    time.Time `json:"created_at"`
}

type AccountantBillingLiveReadyReport struct {
	ModuleCode                 string                                  `json:"module_code"`
	Mode                       string                                  `json:"mode"`
	Status                     string                                  `json:"status"`
	Gate                       AccountantBillingLiveReadyGate          `json:"gate"`
	Requirements               []AccountantBillingLiveReadyRequirement `json:"requirements"`
	LiveOperationPolicies      map[string]string                       `json:"live_operation_policies"`
	ProductionBillingAllowed   bool                                    `json:"production_billing_allowed"`
	RealInvoiceIssueAllowed    bool                                    `json:"real_invoice_issue_allowed"`
	RealBillingCommitAllowed   bool                                    `json:"real_billing_commit_allowed"`
	RealPaymentCaptureAllowed  bool                                    `json:"real_payment_capture_allowed"`
	RealMoneyMovementAllowed   bool                                    `json:"real_money_movement_allowed"`
	RealTaxSubmissionAllowed   bool                                    `json:"real_tax_submission_allowed"`
	RealProviderAPICallAllowed bool                                    `json:"real_provider_api_call_allowed"`
	NextModule                 string                                  `json:"next_module"`
	CreatedAt                  time.Time                               `json:"created_at"`
}

type AccountantBillingAuditEvent struct {
	EventCode          string    `json:"event_code"`
	AccountantTenantID string    `json:"accountant_tenant_id,omitempty"`
	FirmTenantID       string    `json:"firm_tenant_id,omitempty"`
	Status             string    `json:"status"`
	Reason             string    `json:"reason,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
}

type AccountantBillingLiveReadyRuntime struct {
	gate        AccountantBillingLiveReadyGate
	issuePlans  map[string]AccountantBillingIssuePlan
	auditEvents []AccountantBillingAuditEvent
	now         func() time.Time
}

func NewDefaultAccountantBillingLiveReadyRuntime() *AccountantBillingLiveReadyRuntime {
	return &AccountantBillingLiveReadyRuntime{
		gate:        DefaultAccountantBillingLiveReadyGate(),
		issuePlans:  map[string]AccountantBillingIssuePlan{},
		auditEvents: []AccountantBillingAuditEvent{},
		now:         time.Now,
	}
}

func (r *AccountantBillingLiveReadyRuntime) BuildBillingLiveReadyReport(input AccountantBillingLiveReadyInput) (AccountantBillingLiveReadyReport, error) {
	if err := r.gate.AssertRealBillingClosed(); err != nil {
		r.appendAudit("ACCOUNTANT_BILLING_LIVE_READY_REPORT_DENIED", "", "", AccountantBillingLiveReadyStatusBlocked, err.Error())
		return AccountantBillingLiveReadyReport{}, err
	}
	report := AccountantBillingLiveReadyReport{
		ModuleCode:                 AccountantBillingLiveReadyModuleCode,
		Mode:                       AccountantBillingLiveReadyMode,
		Status:                     AccountantBillingLiveReadyStatusReady,
		Gate:                       r.gate,
		Requirements:               BuildAccountantBillingLiveReadyRequirements(input),
		LiveOperationPolicies:      DefaultAccountantBillingLiveReadyPolicies(),
		ProductionBillingAllowed:   false,
		RealInvoiceIssueAllowed:    false,
		RealBillingCommitAllowed:   false,
		RealPaymentCaptureAllowed:  false,
		RealMoneyMovementAllowed:   false,
		RealTaxSubmissionAllowed:   false,
		RealProviderAPICallAllowed: false,
		NextModule:                 "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME",
		CreatedAt:                  r.now().UTC(),
	}
	r.appendAudit("ACCOUNTANT_BILLING_LIVE_READY_REPORT_BUILT", "", "", AccountantBillingLiveReadyStatusReady, "")
	return report, nil
}

func (r *AccountantBillingLiveReadyRuntime) BuildInvoiceIssuePlan(req AccountantBillingIssuePlanRequest) (AccountantBillingIssuePlan, error) {
	if err := r.gate.AssertRealBillingClosed(); err != nil {
		r.appendAudit("ACCOUNTANT_BILLING_ISSUE_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, AccountantBillingLiveReadyStatusBlocked, err.Error())
		return AccountantBillingIssuePlan{}, err
	}
	if err := validateBillingIssuePlanRequest(req); err != nil {
		r.appendAudit("ACCOUNTANT_BILLING_ISSUE_PLAN_DENIED", req.AccountantTenantID, req.FirmTenantID, AccountantBillingLiveReadyStatusBlocked, err.Error())
		return AccountantBillingIssuePlan{}, err
	}
	key := billingIssuePlanKey(req.AccountantTenantID, req.FirmTenantID, req.PeriodYYYYMM, req.IdempotencyKey)
	if existing, ok := r.issuePlans[key]; ok {
		r.appendAudit("ACCOUNTANT_BILLING_ISSUE_PLAN_IDEMPOTENCY_REPLAY", req.AccountantTenantID, req.FirmTenantID, AccountantBillingLiveReadyStatusIdempotent, "")
		return existing, nil
	}
	currency := strings.ToUpper(strings.TrimSpace(req.Currency))
	if currency == "" {
		currency = "TRY"
	}
	vatAmount := req.AmountTRY * req.VatRateBasisPoints / 10000
	plan := AccountantBillingIssuePlan{
		PlanID:                       billingLiveReadyID("ACCT-BILLING-ISSUE-PLAN", req.AccountantTenantID, req.FirmTenantID, req.PeriodYYYYMM, req.IdempotencyKey),
		ModuleCode:                   AccountantBillingLiveReadyModuleCode,
		Mode:                         AccountantBillingLiveReadyMode,
		AccountantTenantID:           req.AccountantTenantID,
		FirmTenantID:                 req.FirmTenantID,
		BillingAccountID:             req.BillingAccountID,
		SubscriptionID:               req.SubscriptionID,
		PlanCode:                     req.PlanCode,
		PeriodYYYYMM:                 req.PeriodYYYYMM,
		IdempotencyKey:               req.IdempotencyKey,
		Currency:                     currency,
		NetAmountTRY:                 req.AmountTRY,
		VatRateBasisPoints:           req.VatRateBasisPoints,
		VatAmountTRY:                 vatAmount,
		GrossAmountTRY:               req.AmountTRY + vatAmount,
		Status:                       AccountantBillingLiveReadyStatusPlanBuilt,
		RealInvoiceIssued:            false,
		RealBillingCommitted:         false,
		RealPaymentCaptureRequested:  false,
		RealMoneyMovementAllowed:     false,
		RealTaxSubmissionRequested:   false,
		RealProviderAPICallRequested: false,
		LiveOperationPolicy:          AccountantBillingNoRealInvoicePolicy,
		CreatedAt:                    r.now().UTC(),
	}
	r.issuePlans[key] = plan
	r.appendAudit("ACCOUNTANT_BILLING_ISSUE_PLAN_BUILT", req.AccountantTenantID, req.FirmTenantID, AccountantBillingLiveReadyStatusPlanBuilt, "")
	return plan, nil
}

func (r *AccountantBillingLiveReadyRuntime) RequestRealInvoiceIssue() error {
	r.appendAudit("ACCOUNTANT_REAL_INVOICE_ISSUE_BLOCKED", "", "", AccountantBillingLiveReadyStatusClosed, AccountantBillingNoRealInvoicePolicy)
	return ErrAccountantBillingRealOperationClosed
}

func (r *AccountantBillingLiveReadyRuntime) RequestRealBillingCommit() error {
	r.appendAudit("ACCOUNTANT_REAL_BILLING_COMMIT_BLOCKED", "", "", AccountantBillingLiveReadyStatusClosed, AccountantBillingNoRealBillingPolicy)
	return ErrAccountantBillingRealOperationClosed
}

func (r *AccountantBillingLiveReadyRuntime) RequestRealPaymentCapture() error {
	r.appendAudit("ACCOUNTANT_REAL_PAYMENT_CAPTURE_BLOCKED", "", "", AccountantBillingLiveReadyStatusClosed, AccountantBillingNoRealPaymentPolicy)
	return ErrAccountantBillingRealOperationClosed
}

func (r *AccountantBillingLiveReadyRuntime) RequestRealTaxSubmission() error {
	r.appendAudit("ACCOUNTANT_REAL_TAX_SUBMISSION_BLOCKED", "", "", AccountantBillingLiveReadyStatusClosed, AccountantBillingNoRealTaxSubmissionPolicy)
	return ErrAccountantBillingRealOperationClosed
}

func (r *AccountantBillingLiveReadyRuntime) RequestRealProviderAPI() error {
	r.appendAudit("ACCOUNTANT_REAL_PROVIDER_API_BLOCKED", "", "", AccountantBillingLiveReadyStatusClosed, AccountantBillingNoRealProviderAPIPolicy)
	return ErrAccountantBillingRealOperationClosed
}

func (r *AccountantBillingLiveReadyRuntime) Gate() AccountantBillingLiveReadyGate {
	return r.gate
}

func (r *AccountantBillingLiveReadyRuntime) AuditEvents() []AccountantBillingAuditEvent {
	out := make([]AccountantBillingAuditEvent, len(r.auditEvents))
	copy(out, r.auditEvents)
	return out
}

func (r *AccountantBillingLiveReadyRuntime) appendAudit(code, accountantTenantID, firmTenantID, status, reason string) {
	r.auditEvents = append(r.auditEvents, AccountantBillingAuditEvent{
		EventCode:          code,
		AccountantTenantID: accountantTenantID,
		FirmTenantID:       firmTenantID,
		Status:             status,
		Reason:             reason,
		CreatedAt:          r.now().UTC(),
	})
}

func BuildAccountantBillingLiveReadyRequirements(input AccountantBillingLiveReadyInput) []AccountantBillingLiveReadyRequirement {
	requirements := []AccountantBillingLiveReadyRequirement{
		billingRequirement(BillingRequirementPlanCatalogReady, input.PlanCatalogReady, "plan catalog is available for accountant billing"),
		billingRequirement(BillingRequirementSubscriptionReady, input.SubscriptionRuntimeReady, "subscription runtime is available"),
		billingRequirement(BillingRequirementInvoiceDraftReady, input.InvoiceDraftRuntimeReady, "invoice draft runtime is available"),
		billingRequirement(BillingRequirementTenantAccountReady, input.TenantAccountBindingReady, "tenant billing account binding is available"),
		billingRequirement(BillingRequirementTaxConfigReady, input.TaxConfigReady, "tax configuration is available"),
		billingRequirement(BillingRequirementIdempotencyReady, input.IdempotencyReady, "billing idempotency guard is available"),
		billingRequirement(BillingRequirementAuditReady, input.AuditReady, "billing audit trail is available"),
		billingRequirement(BillingRequirementRollbackReady, input.RollbackReady, "billing rollback policy is available"),
		billingRequirement(BillingRequirementLegalApprovalGateReady, input.LegalApprovalGateReady, "legal approval gate is modeled"),
		billingRequirement(BillingRequirementFinanceApprovalGateReady, input.FinanceApprovalGateReady, "finance approval gate is modeled"),
		billingRequirement(BillingRequirementSecurityGateReady, input.SecurityGateReady, "security approval gate is modeled"),
		billingRequirement(BillingRequirementObservabilityReady, input.ObservabilityReady, "billing observability is available"),
	}
	sort.Slice(requirements, func(i, j int) bool {
		return requirements[i].Code < requirements[j].Code
	})
	return requirements
}

func MissingAccountantBillingLiveReadyRequirements(input AccountantBillingLiveReadyInput) []string {
	missing := []string{}
	for _, req := range BuildAccountantBillingLiveReadyRequirements(input) {
		if req.Required && !req.Ready {
			missing = append(missing, req.Code)
		}
	}
	sort.Strings(missing)
	return missing
}

func AllAccountantBillingLiveReadyInput() AccountantBillingLiveReadyInput {
	return AccountantBillingLiveReadyInput{
		PlanCatalogReady:          true,
		SubscriptionRuntimeReady:  true,
		InvoiceDraftRuntimeReady:  true,
		TenantAccountBindingReady: true,
		TaxConfigReady:            true,
		IdempotencyReady:          true,
		AuditReady:                true,
		RollbackReady:             true,
		LegalApprovalGateReady:    true,
		FinanceApprovalGateReady:  true,
		SecurityGateReady:         true,
		ObservabilityReady:        true,
	}
}

func DefaultAccountantBillingLiveReadyPolicies() map[string]string {
	return map[string]string{
		"invoice_issue":   AccountantBillingNoRealInvoicePolicy,
		"billing_commit":  AccountantBillingNoRealBillingPolicy,
		"payment_capture": AccountantBillingNoRealPaymentPolicy,
		"money_movement":  AccountantBillingNoRealMoneyMovementPolicy,
		"tax_submission":  AccountantBillingNoRealTaxSubmissionPolicy,
		"provider_api":    AccountantBillingNoRealProviderAPIPolicy,
		"customer_export": AccountantBillingNoRealCustomerDataPolicy,
	}
}

func validateBillingIssuePlanRequest(req AccountantBillingIssuePlanRequest) error {
	if strings.TrimSpace(req.AccountantTenantID) == "" {
		return errors.New("accountant tenant id is required")
	}
	if strings.TrimSpace(req.FirmTenantID) == "" {
		return errors.New("firm tenant id is required")
	}
	if strings.TrimSpace(req.BillingAccountID) == "" {
		return errors.New("billing account id is required")
	}
	if strings.TrimSpace(req.SubscriptionID) == "" {
		return errors.New("subscription id is required")
	}
	if strings.TrimSpace(req.PlanCode) == "" {
		return errors.New("plan code is required")
	}
	if len(req.PeriodYYYYMM) != 7 || req.PeriodYYYYMM[4] != '-' {
		return errors.New("period must use YYYY-MM format")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency key is required")
	}
	if req.AmountTRY <= 0 {
		return errors.New("amount must be positive")
	}
	if req.VatRateBasisPoints < 0 || req.VatRateBasisPoints > 10000 {
		return errors.New("vat rate basis points must be between 0 and 10000")
	}
	return nil
}

func billingRequirement(code string, ready bool, description string) AccountantBillingLiveReadyRequirement {
	status := AccountantBillingLiveReadyStatusRequirementNotReady
	if ready {
		status = AccountantBillingLiveReadyStatusRequirementReady
	}
	return AccountantBillingLiveReadyRequirement{
		Code:        code,
		Required:    true,
		Ready:       ready,
		Status:      status,
		Description: description,
	}
}

func billingIssuePlanKey(accountantTenantID, firmTenantID, period, idempotencyKey string) string {
	return accountantTenantID + "|" + firmTenantID + "|" + period + "|" + idempotencyKey
}

func billingLiveReadyID(prefix string, parts ...string) string {
	joined := strings.ToUpper(strings.ReplaceAll(strings.Join(parts, "-"), " ", "-"))
	joined = strings.ReplaceAll(joined, "|", "-")
	return prefix + "-" + joined
}
