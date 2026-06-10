package subscription

import (
	"fmt"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/catalog"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/commercial/entitlement"
)

type Status string
type ReasonCode string

const (
	StatusActive    Status = "ACTIVE"
	StatusTrialing  Status = "TRIALING"
	StatusSuspended Status = "SUSPENDED"
	StatusCanceled  Status = "CANCELED"
	StatusExpired   Status = "EXPIRED"
)

const (
	ReasonAllowSubscriptionActive  ReasonCode = "ALLOW_SUBSCRIPTION_ACTIVE"
	ReasonAllowTrialActive         ReasonCode = "ALLOW_TRIAL_ACTIVE"
	ReasonAllowSubscriptionUpdated ReasonCode = "ALLOW_SUBSCRIPTION_UPDATED"
	ReasonDenyTenantRequired       ReasonCode = "DENY_TENANT_REQUIRED"
	ReasonDenyAccountRequired      ReasonCode = "DENY_ACCOUNT_REQUIRED"
	ReasonDenyUserRequired         ReasonCode = "DENY_USER_REQUIRED"
	ReasonDenyPlanRequired         ReasonCode = "DENY_PLAN_REQUIRED"
	ReasonDenyPlanUnknown          ReasonCode = "DENY_PLAN_UNKNOWN"
	ReasonDenySuspended            ReasonCode = "DENY_SUBSCRIPTION_SUSPENDED"
	ReasonDenyCanceled             ReasonCode = "DENY_SUBSCRIPTION_CANCELED"
	ReasonDenyExpired              ReasonCode = "DENY_SUBSCRIPTION_EXPIRED"
	ReasonDenyTrialExpired         ReasonCode = "DENY_TRIAL_EXPIRED"
	ReasonDenyInvalidOperation     ReasonCode = "DENY_INVALID_OPERATION"
)

type Account struct {
	TenantID string
	AccountID string
	Plan catalog.PlanCode
	Status Status

	CurrentPeriodStart time.Time
	CurrentPeriodEnd time.Time
	TrialEndsAt time.Time

	CurrentUsers int
	CurrentTenants int
	CurrentAPIRequests int
	CurrentExports int
	CurrentAccountantFirms int
	CurrentIntegrations int
}

type Decision struct {
	Status entitlement.DecisionStatus
	ReasonCode string
	ReasonMessage string

	TenantID string
	AccountID string
	UserID string
	PlanCode catalog.PlanCode
	SubscriptionStatus Status

	FeatureCode catalog.FeatureCode
	LimitCode catalog.LimitCode

	LimitValue int
	CurrentUsage int
	RequestedAdd int
	NextUsage int
}

type Runtime struct {
	catalog catalog.Catalog
	entitlement *entitlement.Runtime
}

func NewRuntime(c catalog.Catalog) (*Runtime, error) {
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid catalog: %w", err)
	}

	entitlementRuntime, err := entitlement.NewRuntime(c)
	if err != nil {
		return nil, fmt.Errorf("invalid entitlement runtime: %w", err)
	}

	return &Runtime{
		catalog: c,
		entitlement: entitlementRuntime,
	}, nil
}

func NewDefaultRuntime() (*Runtime, error) {
	return NewRuntime(catalog.DefaultCatalog())
}

func (r *Runtime) StartTrial(tenantID string, accountID string, plan catalog.PlanCode, start time.Time, duration time.Duration) (Account, Decision) {
	if tenantID == "" {
		return Account{}, r.deny(Account{Plan: plan}, "", ReasonDenyTenantRequired, "tenant id is required")
	}
	if accountID == "" {
		return Account{}, r.deny(Account{TenantID: tenantID, Plan: plan}, "", ReasonDenyAccountRequired, "account id is required")
	}
	if plan == "" {
		return Account{}, r.deny(Account{TenantID: tenantID, AccountID: accountID}, "", ReasonDenyPlanRequired, "plan code is required")
	}
	if _, ok := r.catalog.Plan(plan); !ok {
		return Account{}, r.deny(Account{TenantID: tenantID, AccountID: accountID, Plan: plan}, "", ReasonDenyPlanUnknown, "plan is not defined in catalog")
	}
	if duration <= 0 {
		return Account{}, r.deny(Account{TenantID: tenantID, AccountID: accountID, Plan: plan}, "", ReasonDenyInvalidOperation, "trial duration must be positive")
	}

	account := Account{
		TenantID: tenantID,
		AccountID: accountID,
		Plan: plan,
		Status: StatusTrialing,
		CurrentPeriodStart: start,
		CurrentPeriodEnd: start.Add(duration),
		TrialEndsAt: start.Add(duration),
		CurrentTenants: 1,
	}

	return account, r.allow(account, "", ReasonAllowTrialActive, "trial subscription started")
}

func (r *Runtime) Activate(account Account, start time.Time, duration time.Duration) (Account, Decision) {
	if decision, ok := r.validateAccountBase(account); !ok {
		return account, decision
	}
	if duration <= 0 {
		return account, r.deny(account, "", ReasonDenyInvalidOperation, "activation duration must be positive")
	}

	account.Status = StatusActive
	account.CurrentPeriodStart = start
	account.CurrentPeriodEnd = start.Add(duration)
	account.TrialEndsAt = time.Time{}

	return account, r.allow(account, "", ReasonAllowSubscriptionUpdated, "subscription activated")
}

func (r *Runtime) ChangePlan(account Account, newPlan catalog.PlanCode) (Account, Decision) {
	if decision, ok := r.validateAccountBase(account); !ok {
		return account, decision
	}
	if newPlan == "" {
		return account, r.deny(account, "", ReasonDenyPlanRequired, "new plan code is required")
	}
	if _, ok := r.catalog.Plan(newPlan); !ok {
		return account, r.deny(account, "", ReasonDenyPlanUnknown, "new plan is not defined in catalog")
	}

	account.Plan = newPlan

	return account, r.allow(account, "", ReasonAllowSubscriptionUpdated, "subscription plan changed")
}

func (r *Runtime) Renew(account Account, start time.Time, duration time.Duration) (Account, Decision) {
	if decision, ok := r.validateAccountBase(account); !ok {
		return account, decision
	}
	if duration <= 0 {
		return account, r.deny(account, "", ReasonDenyInvalidOperation, "renew duration must be positive")
	}
	if account.Status == StatusCanceled {
		return account, r.deny(account, "", ReasonDenyCanceled, "canceled subscription cannot be renewed")
	}

	account.Status = StatusActive
	account.CurrentPeriodStart = start
	account.CurrentPeriodEnd = start.Add(duration)
	account.TrialEndsAt = time.Time{}
	account.CurrentAPIRequests = 0
	account.CurrentExports = 0

	return account, r.allow(account, "", ReasonAllowSubscriptionUpdated, "subscription renewed")
}

func (r *Runtime) Suspend(account Account) (Account, Decision) {
	if decision, ok := r.validateAccountBase(account); !ok {
		return account, decision
	}
	if account.Status == StatusCanceled {
		return account, r.deny(account, "", ReasonDenyCanceled, "canceled subscription cannot be suspended")
	}

	account.Status = StatusSuspended

	return account, r.allow(account, "", ReasonAllowSubscriptionUpdated, "subscription suspended")
}

func (r *Runtime) Resume(account Account) (Account, Decision) {
	if decision, ok := r.validateAccountBase(account); !ok {
		return account, decision
	}
	if account.Status == StatusCanceled {
		return account, r.deny(account, "", ReasonDenyCanceled, "canceled subscription cannot be resumed")
	}
	if account.Status == StatusExpired {
		return account, r.deny(account, "", ReasonDenyExpired, "expired subscription must be renewed before resume")
	}

	account.Status = StatusActive

	return account, r.allow(account, "", ReasonAllowSubscriptionUpdated, "subscription resumed")
}

func (r *Runtime) Cancel(account Account) (Account, Decision) {
	if decision, ok := r.validateAccountBase(account); !ok {
		return account, decision
	}

	account.Status = StatusCanceled

	return account, r.allow(account, "", ReasonAllowSubscriptionUpdated, "subscription canceled")
}

func (r *Runtime) CheckFeature(account Account, userID string, feature catalog.FeatureCode, now time.Time) Decision {
	if decision, ok := r.validateOperational(account, userID, now); !ok {
		decision.FeatureCode = feature
		return decision
	}

	entitlementDecision := r.entitlement.CheckFeature(entitlement.RuntimeContext{
		TenantID: account.TenantID,
		UserID: userID,
		Plan: account.Plan,
	}, feature)

	return r.fromEntitlement(account, userID, entitlementDecision)
}

func (r *Runtime) CheckLimit(account Account, userID string, limit catalog.LimitCode, currentUsage int, requestedAdd int, now time.Time) Decision {
	if decision, ok := r.validateOperational(account, userID, now); !ok {
		decision.LimitCode = limit
		decision.CurrentUsage = currentUsage
		decision.RequestedAdd = requestedAdd
		decision.NextUsage = currentUsage + requestedAdd
		return decision
	}

	entitlementDecision := r.entitlement.CheckLimit(entitlement.RuntimeContext{
		TenantID: account.TenantID,
		UserID: userID,
		Plan: account.Plan,
	}, limit, currentUsage, requestedAdd)

	return r.fromEntitlement(account, userID, entitlementDecision)
}

func (r *Runtime) CheckFeatureAndLimit(account Account, userID string, feature catalog.FeatureCode, limit catalog.LimitCode, currentUsage int, requestedAdd int, now time.Time) Decision {
	if decision, ok := r.validateOperational(account, userID, now); !ok {
		decision.FeatureCode = feature
		decision.LimitCode = limit
		decision.CurrentUsage = currentUsage
		decision.RequestedAdd = requestedAdd
		decision.NextUsage = currentUsage + requestedAdd
		return decision
	}

	entitlementDecision := r.entitlement.CheckFeatureAndLimit(entitlement.RuntimeContext{
		TenantID: account.TenantID,
		UserID: userID,
		Plan: account.Plan,
	}, feature, limit, currentUsage, requestedAdd)

	return r.fromEntitlement(account, userID, entitlementDecision)
}

func (r *Runtime) validateAccountBase(account Account) (Decision, bool) {
	if account.TenantID == "" {
		return r.deny(account, "", ReasonDenyTenantRequired, "tenant id is required"), false
	}
	if account.AccountID == "" {
		return r.deny(account, "", ReasonDenyAccountRequired, "account id is required"), false
	}
	if account.Plan == "" {
		return r.deny(account, "", ReasonDenyPlanRequired, "plan code is required"), false
	}
	if _, ok := r.catalog.Plan(account.Plan); !ok {
		return r.deny(account, "", ReasonDenyPlanUnknown, "plan is not defined in catalog"), false
	}
	return Decision{}, true
}

func (r *Runtime) validateOperational(account Account, userID string, now time.Time) (Decision, bool) {
	if decision, ok := r.validateAccountBase(account); !ok {
		decision.UserID = userID
		return decision, false
	}
	if userID == "" {
		return r.deny(account, userID, ReasonDenyUserRequired, "user id is required"), false
	}

	switch account.Status {
	case StatusActive:
		if !account.CurrentPeriodEnd.IsZero() && now.After(account.CurrentPeriodEnd) {
			return r.deny(account, userID, ReasonDenyExpired, "subscription period expired"), false
		}
		return Decision{}, true
	case StatusTrialing:
		if account.TrialEndsAt.IsZero() || now.After(account.TrialEndsAt) {
			return r.deny(account, userID, ReasonDenyTrialExpired, "trial period expired"), false
		}
		return Decision{}, true
	case StatusSuspended:
		return r.deny(account, userID, ReasonDenySuspended, "subscription is suspended"), false
	case StatusCanceled:
		return r.deny(account, userID, ReasonDenyCanceled, "subscription is canceled"), false
	case StatusExpired:
		return r.deny(account, userID, ReasonDenyExpired, "subscription is expired"), false
	default:
		return r.deny(account, userID, ReasonDenyInvalidOperation, "subscription status is invalid"), false
	}
}

func (r *Runtime) allow(account Account, userID string, reason ReasonCode, message string) Decision {
	return Decision{
		Status: entitlement.DecisionAllow,
		ReasonCode: string(reason),
		ReasonMessage: message,
		TenantID: account.TenantID,
		AccountID: account.AccountID,
		UserID: userID,
		PlanCode: account.Plan,
		SubscriptionStatus: account.Status,
	}
}

func (r *Runtime) deny(account Account, userID string, reason ReasonCode, message string) Decision {
	return Decision{
		Status: entitlement.DecisionDeny,
		ReasonCode: string(reason),
		ReasonMessage: message,
		TenantID: account.TenantID,
		AccountID: account.AccountID,
		UserID: userID,
		PlanCode: account.Plan,
		SubscriptionStatus: account.Status,
	}
}

func (r *Runtime) fromEntitlement(account Account, userID string, decision entitlement.Decision) Decision {
	return Decision{
		Status: decision.Status,
		ReasonCode: string(decision.ReasonCode),
		ReasonMessage: decision.ReasonMessage,
		TenantID: account.TenantID,
		AccountID: account.AccountID,
		UserID: userID,
		PlanCode: account.Plan,
		SubscriptionStatus: account.Status,
		FeatureCode: decision.FeatureCode,
		LimitCode: decision.LimitCode,
		LimitValue: decision.LimitValue,
		CurrentUsage: decision.CurrentUsage,
		RequestedAdd: decision.RequestedAdd,
		NextUsage: decision.NextUsage,
	}
}
