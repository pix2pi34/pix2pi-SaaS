package accountantportal

import (
	"errors"
	"testing"
	"time"
)

func fixedFinalClosureRuntime() *AccountantPortalFinalClosureRuntime {
	r := NewDefaultAccountantPortalFinalClosureRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 12, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenTwelveBuildFinalClosureReport(t *testing.T) {
	r := fixedFinalClosureRuntime()
	report, err := r.BuildFinalClosureReport()
	if err != nil {
		t.Fatalf("BuildFinalClosureReport returned error: %v", err)
	}
	if report.ModuleCode != AccountantPortalFinalClosureModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.FinalStatus != AccountantPortalFinalClosureStatusPass {
		t.Fatalf("final status must be PASS, got %s", report.FinalStatus)
	}
	if report.SealStatus != AccountantPortalFinalClosureSealStatusSealed {
		t.Fatalf("seal status must be SEALED, got %s", report.SealStatus)
	}
	if report.CommercialHandoffGate != AccountantPortalCommercialHandoffGateReady {
		t.Fatalf("commercial handoff gate must be ready, got %s", report.CommercialHandoffGate)
	}
	if !report.AllRealOperationsClosed {
		t.Fatalf("all real operations must remain closed: %#v", report)
	}
	if err := report.Gate.AssertLiveOperationsClosed(); err != nil {
		t.Fatalf("live operations must remain closed: %v", err)
	}
}

func TestSevenTwelveDependenciesMustBePassAndSealed(t *testing.T) {
	r := fixedFinalClosureRuntime()
	r.deps[1].FinalStatus = AccountantPortalFinalClosureStatusFail
	_, err := r.BuildFinalClosureReport()
	if err == nil {
		t.Fatal("final closure must fail when a dependency is not PASS")
	}
	r = fixedFinalClosureRuntime()
	r.deps[2].SealStatus = "OPEN"
	_, err = r.BuildFinalClosureReport()
	if err == nil {
		t.Fatal("final closure must fail when a dependency is not SEALED")
	}
}

func TestSevenTwelveProviderDryRunSetClosedAndSealed(t *testing.T) {
	r := fixedFinalClosureRuntime()
	report, err := r.BuildFinalClosureReport()
	if err != nil {
		t.Fatalf("BuildFinalClosureReport returned error: %v", err)
	}
	if report.ProviderDryRunSet != AccountantPortalProviderDryRunSet {
		t.Fatalf("unexpected provider set: %s", report.ProviderDryRunSet)
	}
	if len(report.ProviderStatuses) != 4 {
		t.Fatalf("expected four provider statuses, got %#v", report.ProviderStatuses)
	}
	seen := map[string]bool{}
	for _, provider := range report.ProviderStatuses {
		seen[provider.ProviderCode] = true
		if provider.DryRunSealStatus != AccountantPortalFinalClosureSealStatusSealed {
			t.Fatalf("provider dry-run must be sealed: %#v", provider)
		}
		if provider.ProviderLiveStatus != AccountantPortalLiveModuleStatusNotStarted {
			t.Fatalf("provider live must remain not started: %#v", provider)
		}
		if provider.RealProviderAPIStatus != AccountantPortalFinalClosedUntilProviderLiveModule {
			t.Fatalf("provider API must remain closed: %#v", provider)
		}
		if provider.RealFileDelivery != AccountantPortalFinalClosedUntilProviderLiveModule {
			t.Fatalf("file delivery must remain closed: %#v", provider)
		}
		if provider.RealERPWriteStatus != AccountantPortalFinalClosedUntilSyncWorkerLiveModule {
			t.Fatalf("ERP write must remain closed: %#v", provider)
		}
	}
	for _, required := range []string{"PARASUT", "LOGO", "MIKRO", "ZIRVE"} {
		if !seen[required] {
			t.Fatalf("required provider %s missing", required)
		}
	}
}

func TestSevenTwelveLiveOperationBlockers(t *testing.T) {
	r := fixedFinalClosureRuntime()
	if err := r.RequestRealAccountantBilling(); !errors.Is(err, ErrAccountantPortalFinalLiveOperationClosed) {
		t.Fatalf("real accountant billing must be blocked, got %v", err)
	}
	if err := r.RequestRealPaymentCapture(); !errors.Is(err, ErrAccountantPortalFinalLiveOperationClosed) {
		t.Fatalf("real payment capture must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI("LOGO"); !errors.Is(err, ErrAccountantPortalFinalLiveOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealFileDelivery("MIKRO"); !errors.Is(err, ErrAccountantPortalFinalLiveOperationClosed) {
		t.Fatalf("real file delivery must be blocked, got %v", err)
	}
	if err := r.RequestRealERPWrite(); !errors.Is(err, ErrAccountantPortalFinalLiveOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
	if err := r.RequestRealCustomerDataExport(); !errors.Is(err, ErrAccountantPortalFinalLiveOperationClosed) {
		t.Fatalf("real customer data export must be blocked, got %v", err)
	}
}

func TestSevenTwelveGateRejectsOpenedLiveModule(t *testing.T) {
	r := fixedFinalClosureRuntime()
	r.gate.RealProviderAPIStatus = "OPEN"
	_, err := r.BuildFinalClosureReport()
	if err == nil {
		t.Fatal("final closure must reject opened provider API gate")
	}
	r = fixedFinalClosureRuntime()
	r.gate.CommercialLiveModuleStatus = "STARTED"
	_, err = r.BuildFinalClosureReport()
	if err == nil {
		t.Fatal("final closure must reject started commercial live module")
	}
}

func TestSevenTwelveAuditTrail(t *testing.T) {
	r := fixedFinalClosureRuntime()
	_, err := r.BuildFinalClosureReport()
	if err != nil {
		t.Fatalf("BuildFinalClosureReport returned error: %v", err)
	}
	_ = r.RequestRealProviderAPI("PARASUT")
	events := r.AuditEvents()
	if len(events) != 2 {
		t.Fatalf("expected two audit events, got %#v", events)
	}
	for _, event := range events {
		if event.EventCode == "" || event.Status == "" {
			t.Fatalf("audit event must carry event code and status: %#v", event)
		}
	}
}
