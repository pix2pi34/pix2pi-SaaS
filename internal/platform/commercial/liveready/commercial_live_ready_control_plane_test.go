package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedCommercialLiveReadyRuntime() *CommercialLiveReadyControlPlaneRuntime {
	r := NewDefaultCommercialLiveReadyControlPlaneRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 13, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenThirteenBuildLiveReadyReportKeepsRealOperationsClosed(t *testing.T) {
	r := fixedCommercialLiveReadyRuntime()
	report, err := r.BuildLiveReadyReport(CommercialLiveReadyActivationInput{})
	if err != nil {
		t.Fatalf("BuildLiveReadyReport returned error: %v", err)
	}
	if report.ModuleCode != CommercialLiveReadyModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != CommercialLiveReadyMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.ProductionActivationAllowed {
		t.Fatal("production activation must remain disabled in FAZ 7-13")
	}
	if report.RealMoneyMovementAllowed || report.RealProviderAPICallAllowed || report.RealFileDeliveryAllowed || report.RealCustomerDataExportAllowed || report.RealERPWriteAllowed {
		t.Fatalf("real operations must remain disabled: %#v", report)
	}
	if err := report.Gate.AssertRealOperationsClosed(); err != nil {
		t.Fatalf("gate must keep real operations closed: %v", err)
	}
}

func TestSevenThirteenActivationBlockedWhenRequirementsMissing(t *testing.T) {
	r := fixedCommercialLiveReadyRuntime()
	decision := r.EvaluateProductionActivation(CommercialLiveReadyActivationInput{})
	if decision.Allowed {
		t.Fatalf("activation must be blocked when requirements are missing: %#v", decision)
	}
	if len(decision.MissingRequirements) == 0 {
		t.Fatalf("missing requirements must be listed: %#v", decision)
	}
	if decision.RealMoneyMovementAllowed || decision.RealProviderAPICallAllowed || decision.RealCustomerDataExportAllowed || decision.RealERPWriteAllowed {
		t.Fatalf("decision must not allow real operations: %#v", decision)
	}
}

func TestSevenThirteenActivationStillBlockedWhenAllRequirementsReadyBecausePhaseLock(t *testing.T) {
	r := fixedCommercialLiveReadyRuntime()
	decision := r.EvaluateProductionActivation(AllCommercialLiveReadyInput())
	if decision.Allowed {
		t.Fatalf("activation must remain blocked by FAZ 7-13 phase lock: %#v", decision)
	}
	if len(decision.MissingRequirements) != 0 {
		t.Fatalf("all ready input should have no missing requirements, got %#v", decision.MissingRequirements)
	}
	if decision.Reason != CommercialLiveReadyStatusActivationLocked {
		t.Fatalf("expected phase lock reason, got %s", decision.Reason)
	}
}

func TestSevenThirteenRequirementsAndNextModules(t *testing.T) {
	requirements := BuildCommercialLiveReadyRequirements(AllCommercialLiveReadyInput())
	if len(requirements) < 10 {
		t.Fatalf("expected broad live-ready requirement matrix, got %#v", requirements)
	}
	for _, req := range requirements {
		if !req.Required || !req.Ready || req.Status != CommercialLiveReadyStatusRequiredReady {
			t.Fatalf("all-ready input should mark requirement ready: %#v", req)
		}
	}
	next := DefaultCommercialLiveReadyNextModules()
	expected := []string{
		"FAZ_7_14_ACCOUNTANT_BILLING_LIVE_READY_RUNTIME",
		"FAZ_7_15_PAYMENT_CAPTURE_LIVE_READY_RUNTIME",
		"FAZ_7_16_PROVIDER_LIVE_ADAPTER_READINESS",
		"FAZ_7_17_EXPORT_LIVE_READY_PIPELINE",
		"FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME",
		"FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX",
		"FAZ_7_20_COMMERCIAL_MASTER_CLOSURE",
	}
	if len(next) != len(expected) {
		t.Fatalf("unexpected next module list: %#v", next)
	}
	for i := range expected {
		if next[i] != expected[i] {
			t.Fatalf("unexpected next module at index %d: got %s want %s", i, next[i], expected[i])
		}
	}
}

func TestSevenThirteenRealOperationBlockers(t *testing.T) {
	r := fixedCommercialLiveReadyRuntime()
	if err := r.RequestRealBilling(); !errors.Is(err, ErrCommercialLiveReadyRealOperationClosed) {
		t.Fatalf("real billing must be blocked, got %v", err)
	}
	if err := r.RequestRealPaymentCapture(); !errors.Is(err, ErrCommercialLiveReadyRealOperationClosed) {
		t.Fatalf("real payment capture must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI("PARASUT"); !errors.Is(err, ErrCommercialLiveReadyRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealFileDelivery("LOGO"); !errors.Is(err, ErrCommercialLiveReadyRealOperationClosed) {
		t.Fatalf("real file delivery must be blocked, got %v", err)
	}
	if err := r.RequestRealERPWrite(); !errors.Is(err, ErrCommercialLiveReadyRealOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
	if err := r.RequestRealCustomerDataExport(); !errors.Is(err, ErrCommercialLiveReadyRealOperationClosed) {
		t.Fatalf("real customer data export must be blocked, got %v", err)
	}
}

func TestSevenThirteenGateRejectsOpenedRealOperation(t *testing.T) {
	r := fixedCommercialLiveReadyRuntime()
	r.gate.RealProviderAPICallAllowed = true
	_, err := r.BuildLiveReadyReport(CommercialLiveReadyActivationInput{})
	if err == nil {
		t.Fatal("control plane must reject opened provider API gate")
	}

	r = fixedCommercialLiveReadyRuntime()
	r.gate.ProductionActivationAllowed = true
	_, err = r.BuildLiveReadyReport(CommercialLiveReadyActivationInput{})
	if err == nil {
		t.Fatal("control plane must reject opened production activation")
	}
}

func TestSevenThirteenAuditTrail(t *testing.T) {
	r := fixedCommercialLiveReadyRuntime()
	_, _ = r.BuildLiveReadyReport(CommercialLiveReadyActivationInput{})
	_ = r.RequestRealProviderAPI("MIKRO")
	decision := r.EvaluateProductionActivation(CommercialLiveReadyActivationInput{})
	if decision.Allowed {
		t.Fatal("decision must remain blocked")
	}
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
