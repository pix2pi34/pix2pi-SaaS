package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedPaymentCaptureLiveReadyRuntime() *PaymentCaptureLiveReadyRuntime {
	r := NewDefaultPaymentCaptureLiveReadyRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 15, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenFifteenBuildPaymentCaptureLiveReadyReport(t *testing.T) {
	r := fixedPaymentCaptureLiveReadyRuntime()
	report, err := r.BuildPaymentCaptureLiveReadyReport(AllPaymentCaptureLiveReadyInput())
	if err != nil {
		t.Fatalf("BuildPaymentCaptureLiveReadyReport returned error: %v", err)
	}
	if report.ModuleCode != PaymentCaptureLiveReadyModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != PaymentCaptureLiveReadyMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.ProductionPaymentAllowed || report.RealAuthorizationAllowed || report.RealCaptureAllowed || report.RealRefundAllowed || report.RealVoidAllowed || report.RealMoneyMovementAllowed || report.RealProviderAPICallAllowed {
		t.Fatalf("real payment flags must remain disabled: %#v", report)
	}
	if report.NextModule != "FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS" {
		t.Fatalf("unexpected next module: %s", report.NextModule)
	}
	if err := report.Gate.AssertRealPaymentClosed(); err != nil {
		t.Fatalf("payment gate must remain closed: %v", err)
	}
}

func TestSevenFifteenMissingPaymentRequirements(t *testing.T) {
	missing := MissingPaymentCaptureLiveReadyRequirements(PaymentCaptureLiveReadyInput{})
	if len(missing) < 12 {
		t.Fatalf("expected broad missing requirements list, got %#v", missing)
	}
	allReadyMissing := MissingPaymentCaptureLiveReadyRequirements(AllPaymentCaptureLiveReadyInput())
	if len(allReadyMissing) != 0 {
		t.Fatalf("all-ready input should have no missing requirements, got %#v", allReadyMissing)
	}
}

func TestSevenFifteenBuildCapturePlanNoRealCapture(t *testing.T) {
	r := fixedPaymentCaptureLiveReadyRuntime()
	plan, err := r.BuildCapturePlan(PaymentCapturePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingPlanID:      "bill_plan_1",
		PaymentAttemptID:   "pay_attempt_1",
		ProviderCode:       "parasut",
		Currency:           "try",
		AmountMinor:        120000,
		IdempotencyKey:     "idem_pay_001",
		CaptureMode:        "manual_capture_ready",
	})
	if err != nil {
		t.Fatalf("BuildCapturePlan returned error: %v", err)
	}
	if plan.Status != PaymentCaptureLiveReadyStatusPlanBuilt {
		t.Fatalf("unexpected plan status: %s", plan.Status)
	}
	if plan.ProviderCode != "PARASUT" || plan.Currency != "TRY" || plan.CaptureMode != "MANUAL_CAPTURE_READY" {
		t.Fatalf("provider/currency/capture mode must be normalized: %#v", plan)
	}
	if plan.RealAuthorizationRequested || plan.RealCaptureRequested || plan.RealRefundRequested || plan.RealVoidRequested || plan.RealMoneyMovementAllowed || plan.RealProviderAPICallRequested || plan.RealSettlementRequested || plan.RealWebhookIngestionRequested {
		t.Fatalf("capture plan must not perform real payment operation: %#v", plan)
	}
	if plan.RetryPolicyStatus != PaymentCaptureLiveReadyStatusRetryReady || plan.DLQPolicyStatus != PaymentCaptureLiveReadyStatusDLQReady || plan.WebhookVerificationStatus != PaymentCaptureLiveReadyStatusWebhookReady {
		t.Fatalf("retry/DLQ/webhook readiness must be present: %#v", plan)
	}
}

func TestSevenFifteenCapturePlanIdempotency(t *testing.T) {
	r := fixedPaymentCaptureLiveReadyRuntime()
	req := PaymentCapturePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingPlanID:      "bill_plan_1",
		PaymentAttemptID:   "pay_attempt_1",
		ProviderCode:       "LOGO",
		Currency:           "TRY",
		AmountMinor:        120000,
		IdempotencyKey:     "idem_pay_001",
	}
	first, err := r.BuildCapturePlan(req)
	if err != nil {
		t.Fatalf("first BuildCapturePlan returned error: %v", err)
	}
	second, err := r.BuildCapturePlan(req)
	if err != nil {
		t.Fatalf("second BuildCapturePlan returned error: %v", err)
	}
	if first.PlanID != second.PlanID {
		t.Fatalf("idempotency replay should return same plan id: first=%s second=%s", first.PlanID, second.PlanID)
	}
}

func TestSevenFifteenRejectInvalidCapturePlan(t *testing.T) {
	r := fixedPaymentCaptureLiveReadyRuntime()
	_, err := r.BuildCapturePlan(PaymentCapturePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingPlanID:      "bill_plan_1",
		PaymentAttemptID:   "pay_attempt_1",
		ProviderCode:       "LOGO",
		Currency:           "TRY",
		AmountMinor:        0,
		IdempotencyKey:     "idem_pay_002",
	})
	if err == nil {
		t.Fatal("zero amount must be rejected")
	}

	_, err = r.BuildCapturePlan(PaymentCapturePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingPlanID:      "bill_plan_1",
		PaymentAttemptID:   "",
		ProviderCode:       "LOGO",
		Currency:           "TRY",
		AmountMinor:        100,
		IdempotencyKey:     "idem_pay_003",
	})
	if err == nil {
		t.Fatal("missing payment attempt id must be rejected")
	}
}

func TestSevenFifteenRealPaymentOperationBlockers(t *testing.T) {
	r := fixedPaymentCaptureLiveReadyRuntime()
	if err := r.RequestRealAuthorization(); !errors.Is(err, ErrPaymentCaptureRealOperationClosed) {
		t.Fatalf("real authorization must be blocked, got %v", err)
	}
	if err := r.RequestRealCapture(); !errors.Is(err, ErrPaymentCaptureRealOperationClosed) {
		t.Fatalf("real capture must be blocked, got %v", err)
	}
	if err := r.RequestRealRefund(); !errors.Is(err, ErrPaymentCaptureRealOperationClosed) {
		t.Fatalf("real refund must be blocked, got %v", err)
	}
	if err := r.RequestRealVoid(); !errors.Is(err, ErrPaymentCaptureRealOperationClosed) {
		t.Fatalf("real void must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI(); !errors.Is(err, ErrPaymentCaptureRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealSettlement(); !errors.Is(err, ErrPaymentCaptureRealOperationClosed) {
		t.Fatalf("real settlement must be blocked, got %v", err)
	}
}

func TestSevenFifteenGateRejectsOpenedRealPayment(t *testing.T) {
	r := fixedPaymentCaptureLiveReadyRuntime()
	r.gate.RealCaptureAllowed = true
	_, err := r.BuildPaymentCaptureLiveReadyReport(AllPaymentCaptureLiveReadyInput())
	if err == nil {
		t.Fatal("opened capture gate must be rejected")
	}

	r = fixedPaymentCaptureLiveReadyRuntime()
	r.gate.RealMoneyMovementAllowed = true
	_, err = r.BuildCapturePlan(PaymentCapturePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingPlanID:      "bill_plan_1",
		PaymentAttemptID:   "pay_attempt_1",
		ProviderCode:       "LOGO",
		Currency:           "TRY",
		AmountMinor:        1000,
		IdempotencyKey:     "idem_pay_004",
	})
	if err == nil {
		t.Fatal("opened money movement gate must be rejected")
	}
}

func TestSevenFifteenAuditTrail(t *testing.T) {
	r := fixedPaymentCaptureLiveReadyRuntime()
	_, _ = r.BuildPaymentCaptureLiveReadyReport(AllPaymentCaptureLiveReadyInput())
	_, _ = r.BuildCapturePlan(PaymentCapturePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		BillingPlanID:      "bill_plan_1",
		PaymentAttemptID:   "pay_attempt_1",
		ProviderCode:       "MIKRO",
		Currency:           "TRY",
		AmountMinor:        1000,
		IdempotencyKey:     "idem_pay_005",
	})
	_ = r.RequestRealCapture()
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
