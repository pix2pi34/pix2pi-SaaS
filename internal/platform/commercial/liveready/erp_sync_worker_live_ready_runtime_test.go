package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedERPSyncWorkerLiveReadyRuntime() *ERPSyncWorkerLiveReadyRuntime {
	r := NewDefaultERPSyncWorkerLiveReadyRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 18, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenEighteenBuildERPSyncWorkerLiveReadyReport(t *testing.T) {
	r := fixedERPSyncWorkerLiveReadyRuntime()
	report, err := r.BuildERPSyncWorkerLiveReadyReport(AllERPSyncWorkerLiveReadyInput())
	if err != nil {
		t.Fatalf("BuildERPSyncWorkerLiveReadyReport returned error: %v", err)
	}
	if report.ModuleCode != ERPSyncWorkerLiveReadyModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != ERPSyncWorkerLiveReadyMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.ProductionERPSyncAllowed || report.RealERPWriteAllowed || report.RealLedgerPostingAllowed || report.RealProviderAPICallAllowed || report.RealCustomerPayloadAllowed || report.RealReconciliationCommitAllowed {
		t.Fatalf("real ERP sync flags must remain disabled: %#v", report)
	}
	if len(report.SupportedProviders) != 4 || len(report.SupportedObjects) != 4 || len(report.SupportedDirections) != 2 {
		t.Fatalf("expected provider/object/direction sets: %#v", report)
	}
	if report.NextModule != "FAZ_7_19_LIVE_ACTIVATION_GUARD_APPROVAL_MATRIX" {
		t.Fatalf("unexpected next module: %s", report.NextModule)
	}
	if err := report.Gate.AssertRealERPSyncClosed(); err != nil {
		t.Fatalf("ERP sync gate must remain closed: %v", err)
	}
}

func TestSevenEighteenMissingERPSyncWorkerRequirements(t *testing.T) {
	missing := MissingERPSyncWorkerRequirements(ERPSyncWorkerLiveReadyInput{})
	if len(missing) < 14 {
		t.Fatalf("expected broad missing requirements list, got %#v", missing)
	}
	allReadyMissing := MissingERPSyncWorkerRequirements(AllERPSyncWorkerLiveReadyInput())
	if len(allReadyMissing) != 0 {
		t.Fatalf("all-ready input should have no missing requirements, got %#v", allReadyMissing)
	}
}

func TestSevenEighteenBuildERPSyncPlanNoRealWrite(t *testing.T) {
	r := fixedERPSyncWorkerLiveReadyRuntime()
	for _, provider := range []string{"PARASUT", "LOGO", "MIKRO", "ZIRVE"} {
		plan, err := r.BuildERPSyncPlan(ERPSyncPlanRequest{
			AccountantTenantID: "accountant_tenant_1",
			FirmTenantID:       "firm_tenant_7",
			ProviderCode:       provider,
			ERPObjectType:      "invoice",
			SyncDirection:      "pix2pi_to_provider",
			PeriodYYYYMM:       "2026-05",
			SourcePackageID:    "export_pkg_" + provider,
			CorrelationID:      "corr_" + provider,
			IdempotencyKey:     "idem_" + provider,
			DryRunReferenceID:  "dryrun_" + provider,
			RequestedByUserID:  "user_1",
		})
		if err != nil {
			t.Fatalf("BuildERPSyncPlan(%s) returned error: %v", provider, err)
		}
		if plan.ProviderCode != provider || plan.ERPObjectType != ERPSyncObjectInvoice || plan.SyncDirection != ERPSyncDirectionPix2piToProvider {
			t.Fatalf("provider/object/direction must be normalized: %#v", plan)
		}
		if plan.Status != ERPSyncWorkerLiveReadyStatusPlanBuilt {
			t.Fatalf("unexpected status: %#v", plan)
		}
		if len(plan.OperationSteps) == 0 {
			t.Fatalf("operation steps must be built: %#v", plan)
		}
		if plan.RealERPWriteRequested || plan.RealLedgerPostingRequested || plan.RealProviderAPICallRequested || plan.RealCustomerPayloadIncluded || plan.RealReconciliationCommitRequested || plan.RealOperatorERPSyncAction {
			t.Fatalf("ERP sync plan must not request real operations: %#v", plan)
		}
		for _, step := range plan.OperationSteps {
			if !step.SyntheticPayloadOnly || step.RealERPWriteAllowed {
				t.Fatalf("step must be synthetic and no-real-write: %#v", step)
			}
		}
	}
}

func TestSevenEighteenERPSyncPlanIdempotency(t *testing.T) {
	r := fixedERPSyncWorkerLiveReadyRuntime()
	req := ERPSyncPlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "LOGO",
		ERPObjectType:      "CUSTOMER",
		SyncDirection:      "PROVIDER_TO_PIX2PI",
		PeriodYYYYMM:       "2026-05",
		SourcePackageID:    "export_pkg_1",
		CorrelationID:      "corr_1",
		IdempotencyKey:     "idem_001",
		DryRunReferenceID:  "dryrun_1",
		RequestedByUserID:  "user_1",
	}
	first, err := r.BuildERPSyncPlan(req)
	if err != nil {
		t.Fatalf("first BuildERPSyncPlan returned error: %v", err)
	}
	second, err := r.BuildERPSyncPlan(req)
	if err != nil {
		t.Fatalf("second BuildERPSyncPlan returned error: %v", err)
	}
	if first.PlanID != second.PlanID {
		t.Fatalf("idempotency replay should return same plan id: first=%s second=%s", first.PlanID, second.PlanID)
	}
}

func TestSevenEighteenRejectInvalidERPSyncPlan(t *testing.T) {
	r := fixedERPSyncWorkerLiveReadyRuntime()
	_, err := r.BuildERPSyncPlan(ERPSyncPlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "UNKNOWN",
		ERPObjectType:      "INVOICE",
		SyncDirection:      "PIX2PI_TO_PROVIDER",
		PeriodYYYYMM:       "2026-05",
		SourcePackageID:    "pkg",
		CorrelationID:      "corr",
		IdempotencyKey:     "idem",
		DryRunReferenceID:  "dryrun",
		RequestedByUserID:  "user_1",
	})
	if err == nil {
		t.Fatal("unsupported provider must be rejected")
	}

	_, err = r.BuildERPSyncPlan(ERPSyncPlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "LOGO",
		ERPObjectType:      "UNKNOWN_OBJECT",
		SyncDirection:      "PIX2PI_TO_PROVIDER",
		PeriodYYYYMM:       "2026-05",
		SourcePackageID:    "pkg",
		CorrelationID:      "corr",
		IdempotencyKey:     "idem",
		DryRunReferenceID:  "dryrun",
		RequestedByUserID:  "user_1",
	})
	if err == nil {
		t.Fatal("unsupported ERP object must be rejected")
	}
}

func TestSevenEighteenRealERPSyncOperationBlockers(t *testing.T) {
	r := fixedERPSyncWorkerLiveReadyRuntime()
	if err := r.RequestRealERPWrite("LOGO"); !errors.Is(err, ErrERPSyncWorkerRealOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
	if err := r.RequestRealLedgerPosting("MIKRO"); !errors.Is(err, ErrERPSyncWorkerRealOperationClosed) {
		t.Fatalf("real ledger posting must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI("PARASUT"); !errors.Is(err, ErrERPSyncWorkerRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealCustomerPayload("ZIRVE"); !errors.Is(err, ErrERPSyncWorkerRealOperationClosed) {
		t.Fatalf("real customer payload must be blocked, got %v", err)
	}
	if err := r.RequestRealReconciliationCommit("LOGO"); !errors.Is(err, ErrERPSyncWorkerRealOperationClosed) {
		t.Fatalf("real reconciliation commit must be blocked, got %v", err)
	}
	if err := r.RequestRealOperatorERPSyncAction("MIKRO"); !errors.Is(err, ErrERPSyncWorkerRealOperationClosed) {
		t.Fatalf("real operator ERP sync action must be blocked, got %v", err)
	}
}

func TestSevenEighteenGateRejectsOpenedRealERPSync(t *testing.T) {
	r := fixedERPSyncWorkerLiveReadyRuntime()
	r.gate.RealERPWriteAllowed = true
	_, err := r.BuildERPSyncWorkerLiveReadyReport(AllERPSyncWorkerLiveReadyInput())
	if err == nil {
		t.Fatal("opened ERP write gate must be rejected")
	}

	r = fixedERPSyncWorkerLiveReadyRuntime()
	r.gate.RealCustomerPayloadAllowed = true
	_, err = r.BuildERPSyncPlan(ERPSyncPlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "LOGO",
		ERPObjectType:      "INVOICE",
		SyncDirection:      "PIX2PI_TO_PROVIDER",
		PeriodYYYYMM:       "2026-05",
		SourcePackageID:    "pkg",
		CorrelationID:      "corr",
		IdempotencyKey:     "idem",
		DryRunReferenceID:  "dryrun",
		RequestedByUserID:  "user_1",
	})
	if err == nil {
		t.Fatal("opened customer payload gate must be rejected")
	}
}

func TestSevenEighteenAuditTrail(t *testing.T) {
	r := fixedERPSyncWorkerLiveReadyRuntime()
	_, _ = r.BuildERPSyncWorkerLiveReadyReport(AllERPSyncWorkerLiveReadyInput())
	_, _ = r.BuildERPSyncPlan(ERPSyncPlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "MIKRO",
		ERPObjectType:      "LEDGER_ENTRY",
		SyncDirection:      "PIX2PI_TO_PROVIDER",
		PeriodYYYYMM:       "2026-05",
		SourcePackageID:    "pkg",
		CorrelationID:      "corr_1",
		IdempotencyKey:     "idem_1",
		DryRunReferenceID:  "dryrun_1",
		RequestedByUserID:  "user_1",
	})
	_ = r.RequestRealERPWrite("MIKRO")
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
