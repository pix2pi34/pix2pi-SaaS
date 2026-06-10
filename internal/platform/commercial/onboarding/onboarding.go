package onboarding

import (
	"fmt"
	"net/mail"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/billing"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/subscription"
)

type TenantStatus string
type Status string
type StartMode string
type AdminRole string
type ReasonCode string

const (
	TenantStatusActive  TenantStatus = "ACTIVE"
	TenantStatusPending TenantStatus = "PENDING"
	TenantStatusBlocked TenantStatus = "BLOCKED"
)

const (
	StatusReadyForTrial Status = "READY_FOR_TRIAL"
	StatusCompleted     Status = "COMPLETED"
	StatusDenied        Status = "DENIED"
)

const (
	StartModeDemoData StartMode = "demo_data"
	StartModeBlank    StartMode = "blank"
)

const (
	AdminRoleTenantAdmin AdminRole = "TENANT_ADMIN"
)

const (
	ReasonAllowOnboardingReady     ReasonCode = "ALLOW_ONBOARDING_READY"
	ReasonDenyTenantRequired      ReasonCode = "DENY_TENANT_REQUIRED"
	ReasonDenyAccountRequired     ReasonCode = "DENY_ACCOUNT_REQUIRED"
	ReasonDenyBusinessRequired    ReasonCode = "DENY_BUSINESS_REQUIRED"
	ReasonDenyLegalRequired       ReasonCode = "DENY_LEGAL_REQUIRED"
	ReasonDenyTaxProfileRequired  ReasonCode = "DENY_TAX_PROFILE_REQUIRED"
	ReasonDenyBillingRequired     ReasonCode = "DENY_BILLING_PROFILE_REQUIRED"
	ReasonDenyAdminRequired       ReasonCode = "DENY_ADMIN_REQUIRED"
	ReasonDenyPlanRequired        ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown         ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenyStartModeInvalid    ReasonCode = "DENY_START_MODE_INVALID"
	ReasonDenySubscriptionFailed  ReasonCode = "DENY_SUBSCRIPTION_FAILED"
	ReasonDenyBillingFailed       ReasonCode = "DENY_BILLING_FAILED"
)

type Request struct {
	TenantID string
	AccountID string

	BusinessName string
	LegalName string
	TaxNumber string
	TaxOffice string

	BillingEmail string
	BillingAddress string

	AdminUserID string
	AdminEmail string

	Plan catalog.PlanCode
	StartMode StartMode

	RequestedAt time.Time
	TrialDays int
}

type TenantRecord struct {
	TenantID string
	AccountID string
	BusinessName string
	LegalName string
	TaxNumber string
	TaxOffice string
	Status TenantStatus
	StartMode StartMode
	CreatedAt time.Time
}

type AdminUserRecord struct {
	TenantID string
	UserID string
	Email string
	Role AdminRole
	CreatedAt time.Time
}

type Decision struct {
	Status entitlement.DecisionStatus
	ReasonCode string
	ReasonMessage string

	TenantID string
	AccountID string
	AdminUserID string
	AdminEmail string
	PlanCode catalog.PlanCode
	StartMode StartMode

	TenantStatus TenantStatus
	OnboardingStatus Status
	SubscriptionStatus subscription.Status
	BillingStatus billing.BillingStatus
}

type Result struct {
	Tenant TenantRecord
	AdminUser AdminUserRecord
	Subscription subscription.Account
	BillingProfile billing.BillingProfile
	InvoiceDraft billing.InvoiceDraft
	Decision Decision
}

type Runtime struct {
	catalog catalog.Catalog
	subscriptionRuntime *subscription.Runtime
	billingRuntime *billing.Runtime

	DefaultTrialDays int
	RealPaymentEnabled bool
	BillingSimulationEnabled bool
}

func NewDefaultRuntime() (*Runtime, error) {
	c := catalog.DefaultCatalog()
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	subscriptionRuntime, err := subscription.NewRuntime(c)
	if err != nil {
		return nil, fmt.Errorf("invalid subscription runtime: %w", err)
	}

	billingRuntime, err := billing.NewDefaultRuntime()
	if err != nil {
		return nil, fmt.Errorf("invalid billing runtime: %w", err)
	}

	return &Runtime{
		catalog: c,
		subscriptionRuntime: subscriptionRuntime,
		billingRuntime: billingRuntime,
		DefaultTrialDays: 14,
		RealPaymentEnabled: false,
		BillingSimulationEnabled: true,
	}, nil
}

func (r *Runtime) StartTrialOnboarding(req Request) (Result, Decision) {
	if req.RequestedAt.IsZero() {
		req.RequestedAt = time.Now().UTC()
	}
	if req.TrialDays == 0 {
		req.TrialDays = r.DefaultTrialDays
	}

	if decision, ok := r.validateRequest(req); !ok {
		return Result{Decision: decision}, decision
	}

	tenant := TenantRecord{
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		BusinessName: req.BusinessName,
		LegalName: req.LegalName,
		TaxNumber: req.TaxNumber,
		TaxOffice: req.TaxOffice,
		Status: TenantStatusActive,
		StartMode: req.StartMode,
		CreatedAt: req.RequestedAt,
	}

	admin := AdminUserRecord{
		TenantID: req.TenantID,
		UserID: req.AdminUserID,
		Email: req.AdminEmail,
		Role: AdminRoleTenantAdmin,
		CreatedAt: req.RequestedAt,
	}

	account, subscriptionDecision := r.subscriptionRuntime.StartTrial(
		req.TenantID,
		req.AccountID,
		req.Plan,
		req.RequestedAt,
		time.Duration(req.TrialDays) * 24 * time.Hour,
	)
	if subscriptionDecision.Status == entitlement.DecisionDeny {
		decision := r.deny(req, ReasonDenySubscriptionFailed, subscriptionDecision.ReasonMessage)
		decision.SubscriptionStatus = account.Status
		return Result{
			Tenant: tenant,
			AdminUser: admin,
			Subscription: account,
			Decision: decision,
		}, decision
	}

	profile := billing.BillingProfile{
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		LegalName: req.LegalName,
		TaxNumber: req.TaxNumber,
		TaxOffice: req.TaxOffice,
		BillingEmail: req.BillingEmail,
		BillingAddress: req.BillingAddress,
	}

	invoiceDraft, billingDecision := r.billingRuntime.BuildInvoiceDraft(
		account,
		profile,
		req.RequestedAt,
		req.RequestedAt.Add(time.Duration(req.TrialDays) * 24 * time.Hour),
	)
	if billingDecision.Status == entitlement.DecisionDeny {
		decision := r.deny(req, ReasonDenyBillingFailed, billingDecision.ReasonMessage)
		decision.SubscriptionStatus = account.Status
		decision.BillingStatus = invoiceDraft.BillingStatus
		return Result{
			Tenant: tenant,
			AdminUser: admin,
			Subscription: account,
			BillingProfile: profile,
			InvoiceDraft: invoiceDraft,
			Decision: decision,
		}, decision
	}

	decision := Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(ReasonAllowOnboardingReady),
		ReasonMessage: "tenant onboarding is ready for trial",
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		AdminUserID: req.AdminUserID,
		AdminEmail: req.AdminEmail,
		PlanCode: req.Plan,
		StartMode: req.StartMode,
		TenantStatus: tenant.Status,
		OnboardingStatus: StatusReadyForTrial,
		SubscriptionStatus: account.Status,
		BillingStatus: invoiceDraft.BillingStatus,
	}

	return Result{
		Tenant: tenant,
		AdminUser: admin,
		Subscription: account,
		BillingProfile: profile,
		InvoiceDraft: invoiceDraft,
		Decision: decision,
	}, decision
}

func (r *Runtime) CompleteOnboarding(result Result) (Result, Decision) {
	if result.Tenant.TenantID == "" || result.Subscription.TenantID == "" {
		decision := Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyTenantRequired),
			ReasonMessage: "tenant result is required",
			OnboardingStatus: StatusDenied,
		}
		result.Decision = decision
		return result, decision
	}
	if result.AdminUser.UserID == "" {
		decision := Decision{
			Status: entitlement.DecisionDeny,
			ReasonCode: string(ReasonDenyAdminRequired),
			ReasonMessage: "admin user result is required",
			TenantID: result.Tenant.TenantID,
			AccountID: result.Tenant.AccountID,
			OnboardingStatus: StatusDenied,
		}
		result.Decision = decision
		return result, decision
	}

	result.Decision.Status = entitlement.DecisionAllow
	result.Decision.ReasonCode = string(ReasonAllowOnboardingReady)
	result.Decision.ReasonMessage = "tenant onboarding completed"
	result.Decision.OnboardingStatus = StatusCompleted

	return result, result.Decision
}

func (r *Runtime) validateRequest(req Request) (Decision, bool) {
	if req.TenantID == "" {
		return r.deny(req, ReasonDenyTenantRequired, "tenant id is required"), false
	}
	if req.AccountID == "" {
		return r.deny(req, ReasonDenyAccountRequired, "account id is required"), false
	}
	if req.BusinessName == "" {
		return r.deny(req, ReasonDenyBusinessRequired, "business name is required"), false
	}
	if req.LegalName == "" {
		return r.deny(req, ReasonDenyLegalRequired, "legal name is required"), false
	}
	if req.TaxNumber == "" || req.TaxOffice == "" {
		return r.deny(req, ReasonDenyTaxProfileRequired, "tax number and tax office are required"), false
	}
	if req.BillingEmail == "" || req.BillingAddress == "" {
		return r.deny(req, ReasonDenyBillingRequired, "billing email and address are required"), false
	}
	if _, err := mail.ParseAddress(req.BillingEmail); err != nil {
		return r.deny(req, ReasonDenyBillingRequired, "billing email is invalid"), false
	}
	if req.AdminUserID == "" || req.AdminEmail == "" {
		return r.deny(req, ReasonDenyAdminRequired, "admin user id and email are required"), false
	}
	if _, err := mail.ParseAddress(req.AdminEmail); err != nil {
		return r.deny(req, ReasonDenyAdminRequired, "admin email is invalid"), false
	}
	if req.Plan == "" {
		return r.deny(req, ReasonDenyPlanRequired, "plan code is required"), false
	}
	if _, ok := r.catalog.Plan(req.Plan); !ok {
		return r.deny(req, ReasonDenyPlanUnknown, "plan is not defined in catalog"), false
	}
	if req.StartMode != StartModeDemoData && req.StartMode != StartModeBlank {
		return r.deny(req, ReasonDenyStartModeInvalid, "start mode must be demo_data or blank"), false
	}
	if req.TrialDays < 0 {
		return r.deny(req, ReasonDenySubscriptionFailed, "trial days cannot be negative"), false
	}

	return Decision{}, true
}

func (r *Runtime) deny(req Request, reason ReasonCode, message string) Decision {
	return Decision{
		Status: entitlement.DecisionDeny,
		ReasonCode: string(reason),
		ReasonMessage: message,
		TenantID: req.TenantID,
		AccountID: req.AccountID,
		AdminUserID: req.AdminUserID,
		AdminEmail: req.AdminEmail,
		PlanCode: req.Plan,
		StartMode: req.StartMode,
		TenantStatus: TenantStatusBlocked,
		OnboardingStatus: StatusDenied,
	}
}
