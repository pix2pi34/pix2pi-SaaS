package billing

import (
	"fmt"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/subscription"
)

type CurrencyCode string
type BillingStatus string
type ReasonCode string

const (
	CurrencyTRY CurrencyCode = "TRY"
)

const (
	BillingStatusDraft           BillingStatus = "DRAFT"
	BillingStatusSimulationReady BillingStatus = "SIMULATION_READY"
	BillingStatusBlocked         BillingStatus = "BLOCKED"
)

const (
	ReasonAllowInvoiceDraftReady      ReasonCode = "ALLOW_INVOICE_DRAFT_READY"
	ReasonAllowBillingSimulationReady ReasonCode = "ALLOW_BILLING_SIMULATION_READY"
	ReasonDenyTenantRequired          ReasonCode = "DENY_TENANT_REQUIRED"
	ReasonDenyAccountRequired         ReasonCode = "DENY_ACCOUNT_REQUIRED"
	ReasonDenyPlanRequired            ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown             ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenyBillingProfileRequired  ReasonCode = "DENY_BILLING_PROFILE_REQUIRED"
	ReasonDenyInvalidPeriod           ReasonCode = "DENY_INVALID_PERIOD"
	ReasonDenySubscriptionNotBillable  ReasonCode = "DENY_SUBSCRIPTION_NOT_BILLABLE"
	ReasonDenyRealPaymentDisabled     ReasonCode = "DENY_REAL_PAYMENT_DISABLED"
	ReasonDenyFinancialApproval        ReasonCode = "DENY_FINANCIAL_APPROVAL_REQUIRED"
)

type BillingProfile struct {
	TenantID       string
	AccountID      string
	LegalName      string
	TaxNumber      string
	TaxOffice      string
	BillingEmail   string
	BillingAddress string
}

type PlanPrice struct {
	PlanCode              catalog.PlanCode
	MonthlyNetAmountKurus int64
	Currency              CurrencyCode
}

type InvoiceLine struct {
	Description     string
	PlanCode        catalog.PlanCode
	NetAmountKurus  int64
	VATRateBps      int
	VATAmountKurus  int64
	GrossAmountKurus int64
}

type InvoiceDraft struct {
	DraftID string

	TenantID  string
	AccountID string
	PlanCode  catalog.PlanCode

	BillingPeriodStart time.Time
	BillingPeriodEnd   time.Time

	NetAmountKurus   int64
	VATRateBps       int
	VATAmountKurus   int64
	GrossAmountKurus int64
	Currency         CurrencyCode

	BillingStatus      BillingStatus
	RealPaymentEnabled bool
	SimulationEnabled  bool

	Lines []InvoiceLine
}

type Decision struct {
	Status        entitlement.DecisionStatus
	ReasonCode    string
	ReasonMessage string

	TenantID  string
	AccountID string
	PlanCode  catalog.PlanCode

	BillingStatus      BillingStatus
	RealPaymentEnabled bool
	SimulationEnabled  bool
}

type Runtime struct {
	catalog catalog.Catalog

	prices map[catalog.PlanCode]PlanPrice

	DefaultVATRateBps int
	Currency          CurrencyCode

	RealPaymentEnabled                         bool
	BillingSimulationEnabled                   bool
	RequiresFinancialApprovalBeforeRealPayment bool
	RequiresTaxAdvisorApprovalBeforeRealBilling bool
	RequiresPaymentProviderContractBeforeRealPayment bool
}

func NewDefaultRuntime() (*Runtime, error) {
	c := catalog.DefaultCatalog()
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	runtime := &Runtime{
		catalog: c,
		prices: map[catalog.PlanCode]PlanPrice{
			catalog.PlanStarter: {
				PlanCode:              catalog.PlanStarter,
				MonthlyNetAmountKurus: 99000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanPro: {
				PlanCode:              catalog.PlanPro,
				MonthlyNetAmountKurus: 299000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanEnterprise: {
				PlanCode:              catalog.PlanEnterprise,
				MonthlyNetAmountKurus: 1499000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanAccountant: {
				PlanCode:              catalog.PlanAccountant,
				MonthlyNetAmountKurus: 499000,
				Currency:              CurrencyTRY,
			},
			catalog.PlanMarketplace: {
				PlanCode:              catalog.PlanMarketplace,
				MonthlyNetAmountKurus: 799000,
				Currency:              CurrencyTRY,
			},
		},
		DefaultVATRateBps: 2000,
		Currency:         CurrencyTRY,

		RealPaymentEnabled:                         false,
		BillingSimulationEnabled:                   true,
		RequiresFinancialApprovalBeforeRealPayment: true,
		RequiresTaxAdvisorApprovalBeforeRealBilling: true,
		RequiresPaymentProviderContractBeforeRealPayment: true,
	}

	if err := runtime.ValidatePriceCatalog(); err != nil {
		return nil, err
	}

	return runtime, nil
}

func (r *Runtime) ValidatePriceCatalog() error {
	requiredPlans := []catalog.PlanCode{
		catalog.PlanStarter,
		catalog.PlanPro,
		catalog.PlanEnterprise,
		catalog.PlanAccountant,
		catalog.PlanMarketplace,
	}

	for _, planCode := range requiredPlans {
		price, ok := r.prices[planCode]
		if !ok {
			return fmt.Errorf("price missing for plan: %s", planCode)
		}
		if price.MonthlyNetAmountKurus <= 0 {
			return fmt.Errorf("price must be positive for plan: %s", planCode)
		}
		if price.Currency != CurrencyTRY {
			return fmt.Errorf("unexpected currency for plan %s: %s", planCode, price.Currency)
		}
	}

	if r.DefaultVATRateBps <= 0 {
		return fmt.Errorf("vat rate must be positive")
	}

	if r.RealPaymentEnabled {
		return fmt.Errorf("real payment must be disabled in FAZ 7-5")
	}

	if !r.BillingSimulationEnabled {
		return fmt.Errorf("billing simulation must be enabled in FAZ 7-5")
	}

	if !r.RequiresFinancialApprovalBeforeRealPayment {
		return fmt.Errorf("financial approval gate must be enabled")
	}

	return nil
}

func (r *Runtime) Price(planCode catalog.PlanCode) (PlanPrice, bool) {
	price, ok := r.prices[planCode]
	return price, ok
}

func (r *Runtime) BuildInvoiceDraft(account subscription.Account, profile BillingProfile, periodStart time.Time, periodEnd time.Time) (InvoiceDraft, Decision) {
	if decision, ok := r.validateBillingRequest(account, profile, periodStart, periodEnd); !ok {
		return InvoiceDraft{
			TenantID: account.TenantID,
			AccountID: account.AccountID,
			PlanCode: account.Plan,
			BillingPeriodStart: periodStart,
			BillingPeriodEnd: periodEnd,
			BillingStatus: BillingStatusBlocked,
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}, decision
	}

	price, ok := r.Price(account.Plan)
	if !ok {
		return InvoiceDraft{}, r.deny(account, ReasonDenyPlanUnknown, "plan price is not defined")
	}

	vatAmount := CalculateVAT(price.MonthlyNetAmountKurus, r.DefaultVATRateBps)
	grossAmount := price.MonthlyNetAmountKurus + vatAmount

	draft := InvoiceDraft{
		DraftID: fmt.Sprintf("INV-DRAFT-%s-%s-%d", account.TenantID, account.AccountID, periodStart.Unix()),

		TenantID: account.TenantID,
		AccountID: account.AccountID,
		PlanCode: account.Plan,

		BillingPeriodStart: periodStart,
		BillingPeriodEnd: periodEnd,

		NetAmountKurus: price.MonthlyNetAmountKurus,
		VATRateBps: r.DefaultVATRateBps,
		VATAmountKurus: vatAmount,
		GrossAmountKurus: grossAmount,
		Currency: price.Currency,

		BillingStatus: BillingStatusSimulationReady,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,

		Lines: []InvoiceLine{
			{
				Description: fmt.Sprintf("Pix2pi %s monthly subscription", account.Plan),
				PlanCode: account.Plan,
				NetAmountKurus: price.MonthlyNetAmountKurus,
				VATRateBps: r.DefaultVATRateBps,
				VATAmountKurus: vatAmount,
				GrossAmountKurus: grossAmount,
			},
		},
	}

	return draft, Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowInvoiceDraftReady),
		ReasonMessage: "invoice draft is ready for billing simulation",
		TenantID: account.TenantID,
		AccountID: account.AccountID,
		PlanCode: account.Plan,
		BillingStatus: draft.BillingStatus,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func (r *Runtime) SimulateBilling(draft InvoiceDraft) Decision {
	if draft.DraftID == "" || draft.BillingStatus != BillingStatusSimulationReady {
		return Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyInvalidPeriod),
			ReasonMessage: "invoice draft is not simulation ready",
			TenantID: draft.TenantID,
			AccountID: draft.AccountID,
			PlanCode: draft.PlanCode,
			BillingStatus: draft.BillingStatus,
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}
	}

	return Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowBillingSimulationReady),
		ReasonMessage: "billing simulation is ready",
		TenantID: draft.TenantID,
		AccountID: draft.AccountID,
		PlanCode: draft.PlanCode,
		BillingStatus: draft.BillingStatus,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func (r *Runtime) CheckRealPaymentGate() Decision {
	if !r.RealPaymentEnabled {
		return Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyRealPaymentDisabled),
			ReasonMessage: "real payment is disabled in FAZ 7-5 billing readiness",
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}
	}

	if r.RequiresFinancialApprovalBeforeRealPayment {
		return Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyFinancialApproval),
			ReasonMessage: "financial approval is required before real payment",
			RealPaymentEnabled: r.RealPaymentEnabled,
			SimulationEnabled: r.BillingSimulationEnabled,
		}
	}

	return Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowBillingSimulationReady),
		ReasonMessage: "real payment gate is open",
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func (r *Runtime) validateBillingRequest(account subscription.Account, profile BillingProfile, periodStart time.Time, periodEnd time.Time) (Decision, bool) {
	if account.TenantID == "" {
		return r.deny(account, ReasonDenyTenantRequired, "tenant id is required"), false
	}
	if account.AccountID == "" {
		return r.deny(account, ReasonDenyAccountRequired, "account id is required"), false
	}
	if account.Plan == "" {
		return r.deny(account, ReasonDenyPlanRequired, "plan code is required"), false
	}
	if _, ok := r.catalog.Plan(account.Plan); !ok {
		return r.deny(account, ReasonDenyPlanUnknown, "plan is not defined in catalog"), false
	}
	if _, ok := r.Price(account.Plan); !ok {
		return r.deny(account, ReasonDenyPlanUnknown, "plan price is not defined"), false
	}
	if profile.TenantID == "" ||
		profile.AccountID == "" ||
		profile.LegalName == "" ||
		profile.TaxNumber == "" ||
		profile.TaxOffice == "" ||
		profile.BillingEmail == "" ||
		profile.BillingAddress == "" {
		return r.deny(account, ReasonDenyBillingProfileRequired, "billing profile is incomplete"), false
	}
	if profile.TenantID != account.TenantID || profile.AccountID != account.AccountID {
		return r.deny(account, ReasonDenyBillingProfileRequired, "billing profile does not match account"), false
	}
	if periodStart.IsZero() || periodEnd.IsZero() || !periodEnd.After(periodStart) {
		return r.deny(account, ReasonDenyInvalidPeriod, "billing period is invalid"), false
	}
	if account.Status == subscription.StatusCanceled ||
		account.Status == subscription.StatusExpired {
		return r.deny(account, ReasonDenySubscriptionNotBillable, "subscription is not billable"), false
	}

	return Decision{}, true
}

func (r *Runtime) deny(account subscription.Account, reason ReasonCode, message string) Decision {
	return Decision{
		Status: entitlement.DecisionDeny,
		ReasonCode: string(reason),
		ReasonMessage: message,
		TenantID: account.TenantID,
		AccountID: account.AccountID,
		PlanCode: account.Plan,
		BillingStatus: BillingStatusBlocked,
		RealPaymentEnabled: r.RealPaymentEnabled,
		SimulationEnabled: r.BillingSimulationEnabled,
	}
}

func CalculateVAT(netAmountKurus int64, vatRateBps int) int64 {
	return (netAmountKurus * int64(vatRateBps)) / 10000
}
