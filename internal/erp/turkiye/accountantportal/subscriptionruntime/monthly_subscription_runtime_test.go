package subscriptionruntime

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:        true,
		DefaultCurrencyCode:   "TRY",
		RequireTenantScope:    true,
		RequireBillingProfile: true,
		RequireMonthlyCycle:   true,
		RequireFirmLimit:      true,
		RequireAuditActor:     true,
		AllowTrial:            true,
		AllowPlanChange:       true,
		AllowResumeSuspended:  true,
		DefaultTrialDays:      14,
		MaxAssignedFirmLimit:  100,
		AllowedPlanCodes:      []string{"ACCOUNTANT_STARTER", "ACCOUNTANT_PRO", "ACCOUNTANT_ENTERPRISE"},
		AllowedStatuses: []SubscriptionStatus{
			SubscriptionStatusDraft,
			SubscriptionStatusTrialing,
			SubscriptionStatusActive,
			SubscriptionStatusSuspended,
			SubscriptionStatusCanceled,
			SubscriptionStatusExpired,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func starterPlan() SubscriptionPlan {
	return SubscriptionPlan{
		PlanCode:           "ACCOUNTANT_STARTER",
		PlanName:           "Muhasebeci Starter",
		BillingCycle:       BillingCycleMonthly,
		CurrencyCode:       "TRY",
		MonthlyPriceKurus:  99000,
		IncludedFirmLimit:  10,
		IncludedUserLimit:  3,
		ExportQuotaMonthly: 250,
		TrialDays:          14,
	}
}

func proPlan() SubscriptionPlan {
	return SubscriptionPlan{
		PlanCode:           "ACCOUNTANT_PRO",
		PlanName:           "Muhasebeci Pro",
		BillingCycle:       BillingCycleMonthly,
		CurrencyCode:       "TRY",
		MonthlyPriceKurus:  199000,
		IncludedFirmLimit:  25,
		IncludedUserLimit:  8,
		ExportQuotaMonthly: 1000,
		TrialDays:          14,
	}
}

func validCommand(plan SubscriptionPlan) SubscriptionCommandRequest {
	return SubscriptionCommandRequest{
		TenantID:         "tenant-accountant-001",
		CorrelationID:    "corr-subscription-001",
		RequestID:        "req-subscription-001",
		IdempotencyKey:   "idem-subscription-001",
		CommandID:        "cmd-subscription-001",
		SubscriptionID:   "sub-001",
		AccountantFirmID: "acc-firm-001",
		BillingProfileID: "billing-profile-001",
		Plan:             plan,
		ActorID:          "acc-owner-001",
		Reason:           "test reason",
		EffectiveAt:      validNow(),
	}
}

func activeAccount() SubscriptionAccount {
	now := validNow()
	return SubscriptionAccount{
		TenantID:           "tenant-accountant-001",
		SubscriptionID:     "sub-001",
		AccountantFirmID:   "acc-firm-001",
		BillingProfileID:   "billing-profile-001",
		PlanCode:           "ACCOUNTANT_STARTER",
		PlanName:           "Muhasebeci Starter",
		Status:             SubscriptionStatusActive,
		BillingCycle:       BillingCycleMonthly,
		CurrencyCode:       "TRY",
		MonthlyPriceKurus:  99000,
		AssignedFirmLimit:  10,
		AssignedFirmCount:  2,
		IncludedUserLimit:  3,
		ExportQuotaMonthly: 250,
		PeriodStart:        time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC),
		PeriodEnd:          time.Date(2026, 5, 31, 23, 59, 59, 0, time.UTC),
		LastRenewedAt:      now,
		AuditActorID:       "acc-owner-001",
		UpdatedAt:          now,
	}
}

func newRuntime(t *testing.T) *MonthlySubscriptionRuntime {
	t.Helper()

	runtime, err := NewMonthlySubscriptionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestStartTrialCreatesTrialingSubscription(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.StartTrial(validCommand(starterPlan()))
	if err != nil {
		t.Fatalf("expected trial started, got error: %v", err)
	}
	if !decision.Allowed {
		t.Fatal("expected allowed")
	}
	if decision.Account.Status != SubscriptionStatusTrialing {
		t.Fatalf("expected TRIALING, got %s", decision.Account.Status)
	}
	if decision.Account.TrialEnd.IsZero() {
		t.Fatal("expected trial end")
	}
	if decision.DecisionHash == "" {
		t.Fatal("expected decision hash")
	}
}

func TestActivateMonthlyCreatesActiveSubscription(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.ActivateMonthly(validCommand(starterPlan()))
	if err != nil {
		t.Fatalf("expected activation, got error: %v", err)
	}
	if decision.Account.Status != SubscriptionStatusActive {
		t.Fatalf("expected ACTIVE, got %s", decision.Account.Status)
	}
	if decision.Account.PeriodEnd.Day() != 31 {
		t.Fatalf("expected period end day 31, got %d", decision.Account.PeriodEnd.Day())
	}
}

func TestRenewMonthlyAdvancesPeriod(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(starterPlan())
	req.Current = activeAccount()

	decision, err := runtime.RenewMonthly(req)
	if err != nil {
		t.Fatalf("expected renewal, got error: %v", err)
	}
	if decision.Account.Status != SubscriptionStatusActive {
		t.Fatalf("expected ACTIVE, got %s", decision.Account.Status)
	}
	if decision.Account.PeriodStart.Day() != 1 {
		t.Fatalf("expected next period day 1, got %d", decision.Account.PeriodStart.Day())
	}
	if decision.Account.PeriodStart.Month() != time.June {
		t.Fatalf("expected June period start, got %s", decision.Account.PeriodStart.Month())
	}
}

func TestChangePlanUpdatesLimits(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(proPlan())
	req.Current = activeAccount()

	decision, err := runtime.ChangePlan(req)
	if err != nil {
		t.Fatalf("expected plan change, got error: %v", err)
	}
	if decision.Account.PlanCode != "ACCOUNTANT_PRO" {
		t.Fatalf("expected ACCOUNTANT_PRO, got %s", decision.Account.PlanCode)
	}
	if decision.Account.AssignedFirmLimit != 25 {
		t.Fatalf("expected firm limit 25, got %d", decision.Account.AssignedFirmLimit)
	}
}

func TestChangePlanRejectsLimitDowngrade(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(starterPlan())
	req.Current = activeAccount()
	req.Current.PlanCode = "ACCOUNTANT_PRO"
	req.Current.PlanName = "Muhasebeci Pro"
	req.Current.AssignedFirmLimit = 25
	req.Current.AssignedFirmCount = 12

	decision, err := runtime.ChangePlan(req)
	if err == nil {
		t.Fatal("expected limit downgrade denial")
	}
	if decision.ReasonCode != "PLAN_LIMIT_DENIED" {
		t.Fatalf("expected PLAN_LIMIT_DENIED, got %s", decision.ReasonCode)
	}
}

func TestSuspendRequiresReason(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(starterPlan())
	req.Current = activeAccount()
	req.Reason = ""

	decision, err := runtime.Suspend(req)
	if err == nil {
		t.Fatal("expected suspend reason error")
	}
	if decision.ReasonCode != "SUSPEND_REASON_REQUIRED" {
		t.Fatalf("expected SUSPEND_REASON_REQUIRED, got %s", decision.ReasonCode)
	}
}

func TestSuspendAndResumeSubscription(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(starterPlan())
	req.Current = activeAccount()
	req.Reason = "payment failed"

	suspended, err := runtime.Suspend(req)
	if err != nil {
		t.Fatalf("expected suspend, got error: %v", err)
	}
	if suspended.Account.Status != SubscriptionStatusSuspended {
		t.Fatalf("expected SUSPENDED, got %s", suspended.Account.Status)
	}

	resumeReq := validCommand(starterPlan())
	resumeReq.Current = suspended.Account

	resumed, err := runtime.Resume(resumeReq)
	if err != nil {
		t.Fatalf("expected resume, got error: %v", err)
	}
	if resumed.Account.Status != SubscriptionStatusActive {
		t.Fatalf("expected ACTIVE, got %s", resumed.Account.Status)
	}
}

func TestCancelRequiresReason(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(starterPlan())
	req.Current = activeAccount()
	req.Reason = ""

	decision, err := runtime.Cancel(req)
	if err == nil {
		t.Fatal("expected cancel reason error")
	}
	if decision.ReasonCode != "CANCEL_REASON_REQUIRED" {
		t.Fatalf("expected CANCEL_REASON_REQUIRED, got %s", decision.ReasonCode)
	}
}

func TestCancelSubscription(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(starterPlan())
	req.Current = activeAccount()
	req.Reason = "customer requested"

	decision, err := runtime.Cancel(req)
	if err != nil {
		t.Fatalf("expected cancel, got error: %v", err)
	}
	if decision.Account.Status != SubscriptionStatusCanceled {
		t.Fatalf("expected CANCELED, got %s", decision.Account.Status)
	}
}

func TestCheckAccessAllowsActiveSubscription(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.CheckAccess(AccessCheckRequest{
		TenantID:          "tenant-accountant-001",
		CorrelationID:     "corr-access-001",
		RequestID:         "req-access-001",
		IdempotencyKey:    "idem-access-001",
		Subscription:      activeAccount(),
		RequiredFirmCount: 2,
		RequestedAt:       validNow(),
	})
	if err != nil {
		t.Fatalf("expected access allowed, got error: %v", err)
	}
	if !decision.Allowed {
		t.Fatal("expected allowed access")
	}
}

func TestCheckAccessRejectsSuspendedSubscription(t *testing.T) {
	runtime := newRuntime(t)
	sub := activeAccount()
	sub.Status = SubscriptionStatusSuspended

	decision, err := runtime.CheckAccess(AccessCheckRequest{
		TenantID:          "tenant-accountant-001",
		CorrelationID:     "corr-access-001",
		RequestID:         "req-access-001",
		IdempotencyKey:    "idem-access-001",
		Subscription:      sub,
		RequiredFirmCount: 2,
		RequestedAt:       validNow(),
	})
	if err == nil {
		t.Fatal("expected access denied")
	}
	if decision.ReasonCode != "ACCESS_STATUS_DENIED" {
		t.Fatalf("expected ACCESS_STATUS_DENIED, got %s", decision.ReasonCode)
	}
}

func TestCheckAccessRejectsFirmLimit(t *testing.T) {
	runtime := newRuntime(t)

	decision, err := runtime.CheckAccess(AccessCheckRequest{
		TenantID:          "tenant-accountant-001",
		CorrelationID:     "corr-access-001",
		RequestID:         "req-access-001",
		IdempotencyKey:    "idem-access-001",
		Subscription:      activeAccount(),
		RequiredFirmCount: 11,
		RequestedAt:       validNow(),
	})
	if err == nil {
		t.Fatal("expected firm limit denied")
	}
	if decision.ReasonCode != "ACCESS_FIRM_LIMIT_DENIED" {
		t.Fatalf("expected ACCESS_FIRM_LIMIT_DENIED, got %s", decision.ReasonCode)
	}
}

func TestRejectsInvalidPlanCurrency(t *testing.T) {
	runtime := newRuntime(t)
	plan := starterPlan()
	plan.CurrencyCode = "USD"

	decision, err := runtime.ActivateMonthly(validCommand(plan))
	if err == nil {
		t.Fatal("expected currency mismatch")
	}
	if decision.ReasonCode != "PLAN_INVALID" {
		t.Fatalf("expected PLAN_INVALID, got %s", decision.ReasonCode)
	}
}

func TestRejectsCurrentTenantMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validCommand(starterPlan())
	req.Current = activeAccount()
	req.Current.TenantID = "tenant-other"

	decision, err := runtime.RenewMonthly(req)
	if err == nil {
		t.Fatal("expected current tenant mismatch")
	}
	if decision.ReasonCode != "CURRENT_SUBSCRIPTION_INVALID" {
		t.Fatalf("expected CURRENT_SUBSCRIPTION_INVALID, got %s", decision.ReasonCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewMonthlySubscriptionRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingPlansConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AllowedPlanCodes = nil

	_, err := NewMonthlySubscriptionRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing plan config error")
	}
}
