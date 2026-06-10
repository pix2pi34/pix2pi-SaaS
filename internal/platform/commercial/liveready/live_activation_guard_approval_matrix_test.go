package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedLiveActivationGuardRuntime() *LiveActivationGuardRuntime {
	r := NewDefaultLiveActivationGuardRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 19, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenNineteenBuildLiveActivationGuardReport(t *testing.T) {
	r := fixedLiveActivationGuardRuntime()
	report, err := r.BuildLiveActivationGuardReport(AllLiveActivationApprovalInput())
	if err != nil {
		t.Fatalf("BuildLiveActivationGuardReport returned error: %v", err)
	}
	if report.ModuleCode != LiveActivationGuardModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != LiveActivationGuardMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.ProductionActivationAllowed || report.RealMoneyMovementAllowed || report.RealBillingAllowed || report.RealPaymentCaptureAllowed || report.RealProviderAPICallAllowed || report.RealFileDeliveryAllowed || report.RealERPWriteAllowed || report.RealCustomerDataExportAllowed || report.RealLedgerPostingAllowed {
		t.Fatalf("real live activation flags must remain disabled: %#v", report)
	}
	if len(report.DependencySeals) != 6 {
		t.Fatalf("expected six dependency seals, got %#v", report.DependencySeals)
	}
	if report.NextModule != "FAZ_7_20_COMMERCIAL_MASTER_CLOSURE" {
		t.Fatalf("unexpected next module: %s", report.NextModule)
	}
	if err := report.Gate.AssertProductionActivationClosed(); err != nil {
		t.Fatalf("live activation gate must remain closed: %v", err)
	}
}

func TestSevenNineteenMissingLiveActivationRequirements(t *testing.T) {
	missing := MissingLiveActivationRequirements(LiveActivationApprovalInput{})
	if len(missing) < 18 {
		t.Fatalf("expected broad missing requirements list, got %#v", missing)
	}
	allReadyMissing := MissingLiveActivationRequirements(AllLiveActivationApprovalInput())
	if len(allReadyMissing) != 0 {
		t.Fatalf("all-ready input should have no missing requirements, got %#v", allReadyMissing)
	}
}

func TestSevenNineteenEvaluateActivationBlockedWhenMissing(t *testing.T) {
	r := fixedLiveActivationGuardRuntime()
	decision, err := r.EvaluateLiveActivation(LiveActivationDecisionRequest{
		RequestedByUserID: "operator_1",
		CorrelationID:     "corr_1",
		Environment:       "production",
		Reason:            "dry-run approval test",
	}, LiveActivationApprovalInput{})
	if err != nil {
		t.Fatalf("EvaluateLiveActivation returned error: %v", err)
	}
	if decision.Allowed || decision.Armed {
		t.Fatalf("decision must be blocked when requirements are missing: %#v", decision)
	}
	if len(decision.MissingRequirements) == 0 {
		t.Fatalf("missing requirements must be listed: %#v", decision)
	}
}

func TestSevenNineteenEvaluateActivationArmedButStillLocked(t *testing.T) {
	r := fixedLiveActivationGuardRuntime()
	decision, err := r.EvaluateLiveActivation(LiveActivationDecisionRequest{
		RequestedByUserID: "operator_1",
		CorrelationID:     "corr_2",
		Environment:       "production",
		Reason:            "all approvals ready",
	}, AllLiveActivationApprovalInput())
	if err != nil {
		t.Fatalf("EvaluateLiveActivation returned error: %v", err)
	}
	if decision.Allowed {
		t.Fatalf("activation must not be allowed in FAZ 7-19: %#v", decision)
	}
	if !decision.Armed {
		t.Fatalf("all requirements should arm the decision while still locked: %#v", decision)
	}
	if decision.Status != LiveActivationGuardStatusDecisionArmedLocked {
		t.Fatalf("unexpected decision status: %#v", decision)
	}
	if decision.ProductionActivationAllowed || decision.RealMoneyMovementAllowed || decision.RealProviderAPICallAllowed || decision.RealERPWriteAllowed || decision.RealCustomerDataExportAllowed {
		t.Fatalf("decision must not allow real operations: %#v", decision)
	}
}

func TestSevenNineteenRejectInvalidDecisionRequest(t *testing.T) {
	r := fixedLiveActivationGuardRuntime()
	_, err := r.EvaluateLiveActivation(LiveActivationDecisionRequest{
		RequestedByUserID: "",
		CorrelationID:     "corr",
	}, AllLiveActivationApprovalInput())
	if err == nil {
		t.Fatal("missing requested by user id must be rejected")
	}
	_, err = r.EvaluateLiveActivation(LiveActivationDecisionRequest{
		RequestedByUserID: "operator_1",
		CorrelationID:     "",
	}, AllLiveActivationApprovalInput())
	if err == nil {
		t.Fatal("missing correlation id must be rejected")
	}
}

func TestSevenNineteenRealLiveOperationBlockers(t *testing.T) {
	r := fixedLiveActivationGuardRuntime()
	if err := r.RequestProductionActivation(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("production activation must be blocked, got %v", err)
	}
	if err := r.RequestRealMoneyMovement(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real money movement must be blocked, got %v", err)
	}
	if err := r.RequestRealBilling(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real billing must be blocked, got %v", err)
	}
	if err := r.RequestRealPaymentCapture(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real payment capture must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealFileDelivery(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real file delivery must be blocked, got %v", err)
	}
	if err := r.RequestRealERPWrite(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
	if err := r.RequestRealCustomerDataExport(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real customer data export must be blocked, got %v", err)
	}
	if err := r.RequestRealLedgerPosting(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real ledger posting must be blocked, got %v", err)
	}
	if err := r.RequestRealOperatorLiveAction(); !errors.Is(err, ErrLiveActivationRealOperationClosed) {
		t.Fatalf("real operator live action must be blocked, got %v", err)
	}
}

func TestSevenNineteenGateRejectsOpenedActivation(t *testing.T) {
	r := fixedLiveActivationGuardRuntime()
	r.gate.ProductionActivationAllowed = true
	_, err := r.BuildLiveActivationGuardReport(AllLiveActivationApprovalInput())
	if err == nil {
		t.Fatal("opened production activation gate must be rejected")
	}

	r = fixedLiveActivationGuardRuntime()
	r.gate.RealProviderAPICallAllowed = true
	_, err = r.EvaluateLiveActivation(LiveActivationDecisionRequest{
		RequestedByUserID: "operator_1",
		CorrelationID:     "corr_3",
	}, AllLiveActivationApprovalInput())
	if err == nil {
		t.Fatal("opened provider API gate must be rejected")
	}
}

func TestSevenNineteenAuditTrail(t *testing.T) {
	r := fixedLiveActivationGuardRuntime()
	_, _ = r.BuildLiveActivationGuardReport(AllLiveActivationApprovalInput())
	_, _ = r.EvaluateLiveActivation(LiveActivationDecisionRequest{
		RequestedByUserID: "operator_1",
		CorrelationID:     "corr_4",
	}, AllLiveActivationApprovalInput())
	_ = r.RequestProductionActivation()
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
