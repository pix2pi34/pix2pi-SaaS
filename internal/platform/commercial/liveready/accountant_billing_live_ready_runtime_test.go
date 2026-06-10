package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedAccountantBillingLiveReadyRuntime() *AccountantBillingLiveReadyRuntime {
	r := NewDefaultAccountantBillingLiveReadyRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 14, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenFourteenBuildBillingLiveReadyReport(t *testing.T) {
	r := fixedAccountantBillingLiveReadyRuntime()
	report, err := r.BuildBillingLiveReadyReport(AllAccountantBillingLiveReadyInput())
	if err != nil {
		t.Fatalf("BuildBillingLiveReadyReport returned error: %v", err)
	}
	if report.ModuleCode != AccountantBillingLiveReadyModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != AccountantBillingLiveReadyMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.ProductionBillingAllowed || report.RealInvoiceIssueAllowed || report.RealBillingCommitAllowed || report.RealPaymentCaptureAllowed || report.RealMoneyMovementAllowed || report.RealTaxSubmissionAllowed || report.RealProviderAPICallAllowed {
		t.Fatalf("real billing flags must remain disabled: %#v", report)
	}
	if report.NextModule != "FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME" {
		t.Fatalf("unexpected next module: %s", report.NextModule)
	}
	if err := report.Gate.AssertRealBillingClosed(); err != nil {
		t.Fatalf("billing gate must remain closed: %v", err)
	}
}

func TestSevenFourteenMissingBillingRequirements(t *testing.T) {
	missing := MissingAccountantBillingLiveReadyRequirements(AccountantBillingLiveReadyInput{})
	if len(missing) < 10 {
		t.Fatalf("expected broad missing requirements list, got %#v", missing)
	}
	allReadyMissing := MissingAccountantBillingLiveReadyRequirements(AllAccountantBillingLiveReadyInput())
	if len(allReadyMissing) != 0 {
		t.Fatalf("all-ready input should have no missing requirements, got %#v", allReadyMissing)
	}
}

func TestSevenFourteenBuildInvoiceIssuePlanNoRealInvoice(t *testing.T) {
	r := fixedAccountantBillingLiveReadyRuntime()
	plan, err := r.BuildInvoiceIssuePlan(AccountantBillingIssuePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingAccountID:   "acct_bill_1",
		SubscriptionID:     "sub_1",
		PlanCode:           "ACCOUNTANT_PRO",
		PeriodYYYYMM:       "2026-05",
		IdempotencyKey:     "idem_001",
		Currency:           "try",
		AmountTRY:          10000,
		VatRateBasisPoints: 2000,
	})
	if err != nil {
		t.Fatalf("BuildInvoiceIssuePlan returned error: %v", err)
	}
	if plan.Status != AccountantBillingLiveReadyStatusPlanBuilt {
		t.Fatalf("unexpected plan status: %s", plan.Status)
	}
	if plan.Currency != "TRY" {
		t.Fatalf("currency must be normalized, got %s", plan.Currency)
	}
	if plan.VatAmountTRY != 2000 || plan.GrossAmountTRY != 12000 {
		t.Fatalf("unexpected VAT/gross amount: %#v", plan)
	}
	if plan.RealInvoiceIssued || plan.RealBillingCommitted || plan.RealPaymentCaptureRequested || plan.RealMoneyMovementAllowed || plan.RealTaxSubmissionRequested || plan.RealProviderAPICallRequested {
		t.Fatalf("issue plan must not perform real billing operation: %#v", plan)
	}
}

func TestSevenFourteenInvoiceIssuePlanIdempotency(t *testing.T) {
	r := fixedAccountantBillingLiveReadyRuntime()
	req := AccountantBillingIssuePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingAccountID:   "acct_bill_1",
		SubscriptionID:     "sub_1",
		PlanCode:           "ACCOUNTANT_PRO",
		PeriodYYYYMM:       "2026-05",
		IdempotencyKey:     "idem_001",
		AmountTRY:          10000,
		VatRateBasisPoints: 2000,
	}
	first, err := r.BuildInvoiceIssuePlan(req)
	if err != nil {
		t.Fatalf("first BuildInvoiceIssuePlan returned error: %v", err)
	}
	second, err := r.BuildInvoiceIssuePlan(req)
	if err != nil {
		t.Fatalf("second BuildInvoiceIssuePlan returned error: %v", err)
	}
	if first.PlanID != second.PlanID {
		t.Fatalf("idempotency replay should return same plan id: first=%s second=%s", first.PlanID, second.PlanID)
	}
}

func TestSevenFourteenRejectInvalidInvoiceIssuePlan(t *testing.T) {
	r := fixedAccountantBillingLiveReadyRuntime()
	_, err := r.BuildInvoiceIssuePlan(AccountantBillingIssuePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingAccountID:   "acct_bill_1",
		SubscriptionID:     "sub_1",
		PlanCode:           "ACCOUNTANT_PRO",
		PeriodYYYYMM:       "202605",
		IdempotencyKey:     "idem_001",
		AmountTRY:          10000,
		VatRateBasisPoints: 2000,
	})
	if err == nil {
		t.Fatal("invalid period must be rejected")
	}
	_, err = r.BuildInvoiceIssuePlan(AccountantBillingIssuePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingAccountID:   "acct_bill_1",
		SubscriptionID:     "sub_1",
		PlanCode:           "ACCOUNTANT_PRO",
		PeriodYYYYMM:       "2026-05",
		IdempotencyKey:     "idem_002",
		AmountTRY:          -1,
		VatRateBasisPoints: 2000,
	})
	if err == nil {
		t.Fatal("negative amount must be rejected")
	}
}

func TestSevenFourteenRealBillingOperationBlockers(t *testing.T) {
	r := fixedAccountantBillingLiveReadyRuntime()
	if err := r.RequestRealInvoiceIssue(); !errors.Is(err, ErrAccountantBillingRealOperationClosed) {
		t.Fatalf("real invoice issue must be blocked, got %v", err)
	}
	if err := r.RequestRealBillingCommit(); !errors.Is(err, ErrAccountantBillingRealOperationClosed) {
		t.Fatalf("real billing commit must be blocked, got %v", err)
	}
	if err := r.RequestRealPaymentCapture(); !errors.Is(err, ErrAccountantBillingRealOperationClosed) {
		t.Fatalf("real payment capture must be blocked, got %v", err)
	}
	if err := r.RequestRealTaxSubmission(); !errors.Is(err, ErrAccountantBillingRealOperationClosed) {
		t.Fatalf("real tax submission must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI(); !errors.Is(err, ErrAccountantBillingRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
}

func TestSevenFourteenGateRejectsOpenedRealBilling(t *testing.T) {
	r := fixedAccountantBillingLiveReadyRuntime()
	r.gate.RealInvoiceIssueAllowed = true
	_, err := r.BuildBillingLiveReadyReport(AllAccountantBillingLiveReadyInput())
	if err == nil {
		t.Fatal("opened invoice issue gate must be rejected")
	}

	r = fixedAccountantBillingLiveReadyRuntime()
	r.gate.RealMoneyMovementAllowed = true
	_, err = r.BuildInvoiceIssuePlan(AccountantBillingIssuePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingAccountID:   "acct_bill_1",
		SubscriptionID:     "sub_1",
		PlanCode:           "ACCOUNTANT_PRO",
		PeriodYYYYMM:       "2026-05",
		IdempotencyKey:     "idem_003",
		AmountTRY:          10000,
		VatRateBasisPoints: 2000,
	})
	if err == nil {
		t.Fatal("opened money movement gate must be rejected")
	}
}

func TestSevenFourteenAuditTrail(t *testing.T) {
	r := fixedAccountantBillingLiveReadyRuntime()
	_, _ = r.BuildBillingLiveReadyReport(AllAccountantBillingLiveReadyInput())
	_, _ = r.BuildInvoiceIssuePlan(AccountantBillingIssuePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingAccountID:   "acct_bill_1",
		SubscriptionID:     "sub_1",
		PlanCode:           "ACCOUNTANT_PRO",
		PeriodYYYYMM:       "2026-05",
		IdempotencyKey:     "idem_004",
		AmountTRY:          10000,
		VatRateBasisPoints: 2000,
	})
	_ = r.RequestRealInvoiceIssue()
	events := r.AuditEvents()
	if len(events) != 3 {
		t.Fatalf("expected three audit events, got %#v", events)
	}
	for _, event := range events {
		if event.EventCode == "" || event.Status == "" {
			t.Fatalf("audit event must carry event code and status: %#v", event)
		}
	}
}
