package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedCommercialMasterClosureRuntime() *CommercialMasterClosureRuntime {
	r := NewDefaultCommercialMasterClosureRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 20, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenTwentyBuildCommercialMasterClosureReport(t *testing.T) {
	r := fixedCommercialMasterClosureRuntime()
	report, err := r.BuildCommercialMasterClosureReport()
	if err != nil {
		t.Fatalf("BuildCommercialMasterClosureReport returned error: %v", err)
	}
	if report.ModuleCode != CommercialMasterClosureModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != CommercialMasterClosureMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.FinalStatus != CommercialMasterClosureStatusPass || report.SealStatus != CommercialMasterClosureStatusSealed {
		t.Fatalf("commercial master closure must be PASS and SEALED: %#v", report)
	}
	if len(report.DependencySeals) < 10 {
		t.Fatalf("expected broad dependency seals: %#v", report.DependencySeals)
	}
	if len(report.OpenLiveItems) < 8 {
		t.Fatalf("expected explicit live open item handoff list: %#v", report.OpenLiveItems)
	}
	if report.ProductionActivationAllowed || report.RealMoneyMovementAllowed || report.RealBillingAllowed || report.RealPaymentCaptureAllowed || report.RealProviderAPICallAllowed || report.RealFileDeliveryAllowed || report.RealERPWriteAllowed || report.RealCustomerDataExportAllowed || report.RealLedgerPostingAllowed {
		t.Fatalf("real operations must remain disabled: %#v", report)
	}
	if err := report.Gate.AssertRealOperationsClosed(); err != nil {
		t.Fatalf("commercial master gate must keep real operations closed: %v", err)
	}
}

func TestSevenTwentyFinalizeCommercialMasterClosure(t *testing.T) {
	r := fixedCommercialMasterClosureRuntime()
	decision, err := r.FinalizeCommercialMasterClosure()
	if err != nil {
		t.Fatalf("FinalizeCommercialMasterClosure returned error: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("master closure decision should be allowed because this is closure, not live activation: %#v", decision)
	}
	if decision.FinalStatus != CommercialMasterClosureStatusPass || decision.SealStatus != CommercialMasterClosureStatusSealed {
		t.Fatalf("decision must seal commercial master closure: %#v", decision)
	}
	if decision.ProductionActivationAllowed || decision.RealMoneyMovementAllowed || decision.RealProviderAPICallAllowed || decision.RealERPWriteAllowed || decision.RealCustomerDataExportAllowed {
		t.Fatalf("closure decision must not allow real operations: %#v", decision)
	}
}

func TestSevenTwentyDependencySealsArePassAndSealed(t *testing.T) {
	deps := DefaultCommercialMasterDependencySeals()
	if err := validateCommercialMasterDependencySeals(deps); err != nil {
		t.Fatalf("default dependency seals must validate: %v", err)
	}
	seen := map[string]bool{}
	for _, dep := range deps {
		seen[dep.ModuleCode] = true
		if dep.FinalStatus != CommercialMasterClosureStatusPass {
			t.Fatalf("dependency must be PASS: %#v", dep)
		}
		if dep.SealStatus != CommercialMasterClosureStatusSealed {
			t.Fatalf("dependency must be SEALED: %#v", dep)
		}
	}
	required := []string{
		CommercialMasterClosureDependencyPaymentModule,
		CommercialMasterClosureDependencyIntegrationFamily,
		CommercialMasterClosureDependencyAccountantPortal,
		CommercialMasterClosureDependencyCommercialControl,
		CommercialMasterClosureDependencyBillingLiveReady,
		CommercialMasterClosureDependencyPaymentLiveReady,
		CommercialMasterClosureDependencyProviderLiveReady,
		CommercialMasterClosureDependencyExportLiveReady,
		CommercialMasterClosureDependencyERPSyncLiveReady,
		CommercialMasterClosureDependencyActivationGuard,
	}
	for _, code := range required {
		if !seen[code] {
			t.Fatalf("missing required dependency seal: %s", code)
		}
	}
}

func TestSevenTwentyOpenLiveItemsRemainClosed(t *testing.T) {
	items := DefaultCommercialMasterOpenLiveItems()
	if len(items) < 8 {
		t.Fatalf("expected live handoff items: %#v", items)
	}
	for _, item := range items {
		if item.Status != CommercialMasterClosureStatusClosed {
			t.Fatalf("live item must remain closed: %#v", item)
		}
		if item.TargetPhase == "" || item.Reason == "" {
			t.Fatalf("live item must carry target phase and reason: %#v", item)
		}
	}
}

func TestSevenTwentyRealOperationBlockers(t *testing.T) {
	r := fixedCommercialMasterClosureRuntime()
	if err := r.RequestProductionActivation(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("production activation must be blocked, got %v", err)
	}
	if err := r.RequestRealMoneyMovement(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real money movement must be blocked, got %v", err)
	}
	if err := r.RequestRealBilling(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real billing must be blocked, got %v", err)
	}
	if err := r.RequestRealPaymentCapture(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real payment capture must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealFileDelivery(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real file delivery must be blocked, got %v", err)
	}
	if err := r.RequestRealERPWrite(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
	if err := r.RequestRealCustomerDataExport(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real customer export must be blocked, got %v", err)
	}
	if err := r.RequestRealLedgerPosting(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real ledger posting must be blocked, got %v", err)
	}
	if err := r.RequestRealOperatorLiveAction(); !errors.Is(err, ErrCommercialMasterClosureRealOperationClosed) {
		t.Fatalf("real operator live action must be blocked, got %v", err)
	}
}

func TestSevenTwentyGateRejectsOpenedRealOperation(t *testing.T) {
	r := fixedCommercialMasterClosureRuntime()
	r.gate.ProductionActivationAllowed = true
	_, err := r.BuildCommercialMasterClosureReport()
	if err == nil {
		t.Fatal("opened production activation gate must be rejected")
	}

	r = fixedCommercialMasterClosureRuntime()
	r.gate.RealProviderAPICallAllowed = true
	_, err = r.FinalizeCommercialMasterClosure()
	if err == nil {
		t.Fatal("opened provider API gate must be rejected")
	}
}

func TestSevenTwentyAuditTrail(t *testing.T) {
	r := fixedCommercialMasterClosureRuntime()
	_, _ = r.BuildCommercialMasterClosureReport()
	_, _ = r.FinalizeCommercialMasterClosure()
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
