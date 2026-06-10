package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedExportLiveReadyRuntime() *ExportLiveReadyRuntime {
	r := NewDefaultExportLiveReadyRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 17, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenSeventeenBuildExportLiveReadyReport(t *testing.T) {
	r := fixedExportLiveReadyRuntime()
	report, err := r.BuildExportLiveReadyReport(AllExportLiveReadyInput())
	if err != nil {
		t.Fatalf("BuildExportLiveReadyReport returned error: %v", err)
	}
	if report.ModuleCode != ExportLiveReadyModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != ExportLiveReadyMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.ProductionExportAllowed || report.RealCustomerDataExportAllowed || report.RealFileDeliveryAllowed || report.RealProviderAPICallAllowed || report.RealERPWriteAllowed {
		t.Fatalf("real export flags must remain disabled: %#v", report)
	}
	if len(report.SupportedProviders) != 4 || len(report.SupportedFormats) != 4 {
		t.Fatalf("expected four providers and formats: %#v", report)
	}
	if report.NextModule != "FAZ_7_18_ERP_SYNC_WORKER_LIVE_READY_RUNTIME" {
		t.Fatalf("unexpected next module: %s", report.NextModule)
	}
	if err := report.Gate.AssertRealExportClosed(); err != nil {
		t.Fatalf("export gate must remain closed: %v", err)
	}
}

func TestSevenSeventeenMissingExportRequirements(t *testing.T) {
	missing := MissingExportLiveReadyRequirements(ExportLiveReadyInput{})
	if len(missing) < 12 {
		t.Fatalf("expected broad missing requirements list, got %#v", missing)
	}
	allReadyMissing := MissingExportLiveReadyRequirements(AllExportLiveReadyInput())
	if len(allReadyMissing) != 0 {
		t.Fatalf("all-ready input should have no missing requirements, got %#v", allReadyMissing)
	}
}

func TestSevenSeventeenBuildExportPackagePlanNoRealExport(t *testing.T) {
	r := fixedExportLiveReadyRuntime()
	for _, provider := range []string{"PARASUT", "LOGO", "MIKRO", "ZIRVE"} {
		plan, err := r.BuildExportPackagePlan(ExportPackagePlanRequest{
			AccountantTenantID: "accountant_tenant_1",
			FirmTenantID:       "firm_tenant_7",
			ProviderCode:       provider,
			PeriodYYYYMM:       "2026-05",
			CorrelationID:      "corr_" + provider,
			IdempotencyKey:     "idem_" + provider,
			DryRunReferenceID:  "dryrun_" + provider,
			RequestedByUserID:  "user_1",
		})
		if err != nil {
			t.Fatalf("BuildExportPackagePlan(%s) returned error: %v", provider, err)
		}
		if plan.ProviderCode != provider {
			t.Fatalf("provider must be normalized: %#v", plan)
		}
		if plan.Status != ExportLiveReadyStatusPackagePlanBuilt {
			t.Fatalf("unexpected status: %#v", plan)
		}
		if plan.PackageChecksum == "" {
			t.Fatalf("checksum must be produced: %#v", plan)
		}
		if len(plan.Manifest) == 0 {
			t.Fatalf("manifest must be produced: %#v", plan)
		}
		if plan.RealCustomerDataExportRequested || plan.RealCustomerPayloadIncluded || plan.RealFileDeliveryRequested || plan.RealProviderAPICallRequested || plan.RealERPWriteRequested || plan.RealOperatorExportAction {
			t.Fatalf("export plan must not request real operations: %#v", plan)
		}
		if plan.DeliveryPlan.RealDeliveryAllowed || plan.DeliveryPlan.RealProviderAPIAllowed || plan.DeliveryPlan.RealERPWriteAllowed {
			t.Fatalf("delivery plan must not allow real delivery/API/ERP write: %#v", plan.DeliveryPlan)
		}
		for _, item := range plan.Manifest {
			if !item.SyntheticPayloadOnly || item.ContainsRealCustomerData {
				t.Fatalf("manifest must be synthetic and no-real-data: %#v", item)
			}
		}
	}
}

func TestSevenSeventeenExportPackagePlanIdempotency(t *testing.T) {
	r := fixedExportLiveReadyRuntime()
	req := ExportPackagePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "LOGO",
		PeriodYYYYMM:       "2026-05",
		CorrelationID:      "corr_1",
		IdempotencyKey:     "idem_001",
		DryRunReferenceID:  "dryrun_1",
		RequestedByUserID:  "user_1",
	}
	first, err := r.BuildExportPackagePlan(req)
	if err != nil {
		t.Fatalf("first BuildExportPackagePlan returned error: %v", err)
	}
	second, err := r.BuildExportPackagePlan(req)
	if err != nil {
		t.Fatalf("second BuildExportPackagePlan returned error: %v", err)
	}
	if first.PlanID != second.PlanID || first.PackageChecksum != second.PackageChecksum {
		t.Fatalf("idempotency replay should return same plan/checksum: first=%#v second=%#v", first, second)
	}
}

func TestSevenSeventeenRejectInvalidExportPackagePlan(t *testing.T) {
	r := fixedExportLiveReadyRuntime()
	_, err := r.BuildExportPackagePlan(ExportPackagePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "UNKNOWN",
		PeriodYYYYMM:       "2026-05",
		CorrelationID:      "corr",
		IdempotencyKey:     "idem",
		DryRunReferenceID:  "dryrun",
		RequestedByUserID:  "user_1",
	})
	if err == nil {
		t.Fatal("unsupported provider must be rejected")
	}

	_, err = r.BuildExportPackagePlan(ExportPackagePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "LOGO",
		PeriodYYYYMM:       "202605",
		CorrelationID:      "corr",
		IdempotencyKey:     "idem",
		DryRunReferenceID:  "dryrun",
		RequestedByUserID:  "user_1",
	})
	if err == nil {
		t.Fatal("invalid period must be rejected")
	}
}

func TestSevenSeventeenRealExportOperationBlockers(t *testing.T) {
	r := fixedExportLiveReadyRuntime()
	if err := r.RequestRealCustomerDataExport(); !errors.Is(err, ErrExportLiveReadyRealOperationClosed) {
		t.Fatalf("real customer data export must be blocked, got %v", err)
	}
	if err := r.RequestRealFileDelivery("LOGO"); !errors.Is(err, ErrExportLiveReadyRealOperationClosed) {
		t.Fatalf("real file delivery must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderAPI("PARASUT"); !errors.Is(err, ErrExportLiveReadyRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealERPWrite("MIKRO"); !errors.Is(err, ErrExportLiveReadyRealOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
	if err := r.RequestRealOperatorExportAction("ZIRVE"); !errors.Is(err, ErrExportLiveReadyRealOperationClosed) {
		t.Fatalf("real operator export action must be blocked, got %v", err)
	}
}

func TestSevenSeventeenGateRejectsOpenedRealExport(t *testing.T) {
	r := fixedExportLiveReadyRuntime()
	r.gate.RealCustomerDataExportAllowed = true
	_, err := r.BuildExportLiveReadyReport(AllExportLiveReadyInput())
	if err == nil {
		t.Fatal("opened customer export gate must be rejected")
	}

	r = fixedExportLiveReadyRuntime()
	r.gate.RealFileDeliveryAllowed = true
	_, err = r.BuildExportPackagePlan(ExportPackagePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "LOGO",
		PeriodYYYYMM:       "2026-05",
		CorrelationID:      "corr",
		IdempotencyKey:     "idem",
		DryRunReferenceID:  "dryrun",
		RequestedByUserID:  "user_1",
	})
	if err == nil {
		t.Fatal("opened file delivery gate must be rejected")
	}
}

func TestSevenSeventeenAuditTrail(t *testing.T) {
	r := fixedExportLiveReadyRuntime()
	_, _ = r.BuildExportLiveReadyReport(AllExportLiveReadyInput())
	_, _ = r.BuildExportPackagePlan(ExportPackagePlanRequest{
		AccountantTenantID: "accountant_tenant_1",
		FirmTenantID:       "firm_tenant_7",
		ProviderCode:       "MIKRO",
		PeriodYYYYMM:       "2026-05",
		CorrelationID:      "corr_1",
		IdempotencyKey:     "idem_1",
		DryRunReferenceID:  "dryrun_1",
		RequestedByUserID:  "user_1",
	})
	_ = r.RequestRealFileDelivery("MIKRO")
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
