package liveready

import (
	"errors"
	"testing"
	"time"
)

func fixedProviderLiveAdapterReadinessRuntime() *ProviderLiveAdapterReadinessRuntime {
	r := NewDefaultProviderLiveAdapterReadinessRuntime()
	r.now = func() time.Time { return time.Date(2026, 5, 3, 16, 0, 0, 0, time.UTC) }
	return r
}

func TestSevenSixteenBuildProviderLiveAdapterReadinessReport(t *testing.T) {
	r := fixedProviderLiveAdapterReadinessRuntime()
	report, err := r.BuildProviderLiveAdapterReadinessReport(AllProviderLiveAdapterReadinessInput())
	if err != nil {
		t.Fatalf("BuildProviderLiveAdapterReadinessReport returned error: %v", err)
	}
	if report.ModuleCode != ProviderLiveAdapterReadinessModuleCode {
		t.Fatalf("unexpected module code: %s", report.ModuleCode)
	}
	if report.Mode != ProviderLiveAdapterReadinessMode {
		t.Fatalf("unexpected mode: %s", report.Mode)
	}
	if report.ProductionProviderAPIAllowed || report.RealProviderAPICallAllowed || report.RealProviderSecretUseAllowed || report.RealWebhookIngestionAllowed || report.RealFileDeliveryAllowed || report.RealERPWriteAllowed {
		t.Fatalf("real provider flags must remain disabled: %#v", report)
	}
	if len(report.SecretContracts) != 4 || len(report.EndpointContracts) != 4 || len(report.SupportedProviders) != 4 {
		t.Fatalf("expected four provider contracts/providers: %#v", report)
	}
	if report.NextModule != "FAZ_7_17_EXPORT_LIVE_READY_PIPELINE" {
		t.Fatalf("unexpected next module: %s", report.NextModule)
	}
	if err := report.Gate.AssertRealProviderOperationsClosed(); err != nil {
		t.Fatalf("provider gate must remain closed: %v", err)
	}
}

func TestSevenSixteenMissingProviderRequirements(t *testing.T) {
	missing := MissingProviderLiveAdapterRequirements(ProviderLiveAdapterReadinessInput{})
	if len(missing) < 12 {
		t.Fatalf("expected broad missing requirements list, got %#v", missing)
	}
	allReadyMissing := MissingProviderLiveAdapterRequirements(AllProviderLiveAdapterReadinessInput())
	if len(allReadyMissing) != 0 {
		t.Fatalf("all-ready input should have no missing requirements, got %#v", allReadyMissing)
	}
}

func TestSevenSixteenBuildProviderOperationPlanNoRealAPI(t *testing.T) {
	r := fixedProviderLiveAdapterReadinessRuntime()
	for _, provider := range []string{"PARASUT", "LOGO", "MIKRO", "ZIRVE"} {
		plan, err := r.BuildProviderOperationPlan(ProviderOperationPlanRequest{
			ProviderCode:      provider,
			OperationCode:     "capture",
			CorrelationID:     "corr_" + provider,
			IdempotencyKey:    "idem_" + provider,
			TenantID:          "tenant_7",
			DryRunReferenceID: "dryrun_" + provider,
		})
		if err != nil {
			t.Fatalf("BuildProviderOperationPlan(%s) returned error: %v", provider, err)
		}
		if plan.ProviderCode != provider || plan.OperationCode != "CAPTURE" {
			t.Fatalf("provider/operation must be normalized: %#v", plan)
		}
		if plan.RealProviderAPICallRequested || plan.RealProviderSecretUseRequested || plan.RealWebhookIngestionRequested || plan.RealFileDeliveryRequested || plan.RealERPWriteRequested || plan.RealCustomerDataExportRequested {
			t.Fatalf("provider operation plan must not request real operation: %#v", plan)
		}
		if plan.SecretContractStatus != ProviderLiveAdapterReadinessStatusSecretContractReady || plan.EndpointContractStatus != ProviderLiveAdapterReadinessStatusEndpointContractReady || plan.OperationContractStatus != ProviderLiveAdapterReadinessStatusOperationContractReady {
			t.Fatalf("contracts must be ready: %#v", plan)
		}
	}
}

func TestSevenSixteenProviderOperationPlanIdempotency(t *testing.T) {
	r := fixedProviderLiveAdapterReadinessRuntime()
	req := ProviderOperationPlanRequest{
		ProviderCode:      "LOGO",
		OperationCode:     "refund",
		CorrelationID:     "corr_1",
		IdempotencyKey:    "idem_001",
		TenantID:          "tenant_7",
		DryRunReferenceID: "dryrun_1",
	}
	first, err := r.BuildProviderOperationPlan(req)
	if err != nil {
		t.Fatalf("first BuildProviderOperationPlan returned error: %v", err)
	}
	second, err := r.BuildProviderOperationPlan(req)
	if err != nil {
		t.Fatalf("second BuildProviderOperationPlan returned error: %v", err)
	}
	if first.PlanID != second.PlanID {
		t.Fatalf("idempotency replay should return same plan id: first=%s second=%s", first.PlanID, second.PlanID)
	}
}

func TestSevenSixteenRejectInvalidProviderPlan(t *testing.T) {
	r := fixedProviderLiveAdapterReadinessRuntime()
	_, err := r.BuildProviderOperationPlan(ProviderOperationPlanRequest{
		ProviderCode:      "UNKNOWN",
		OperationCode:     "CAPTURE",
		CorrelationID:     "corr",
		IdempotencyKey:    "idem",
		TenantID:          "tenant_7",
		DryRunReferenceID: "dryrun",
	})
	if err == nil {
		t.Fatal("unsupported provider must be rejected")
	}
	_, err = r.BuildProviderOperationPlan(ProviderOperationPlanRequest{
		ProviderCode:      "LOGO",
		OperationCode:     "",
		CorrelationID:     "corr",
		IdempotencyKey:    "idem",
		TenantID:          "tenant_7",
		DryRunReferenceID: "dryrun",
	})
	if err == nil {
		t.Fatal("missing operation must be rejected")
	}
}

func TestSevenSixteenRealProviderOperationBlockers(t *testing.T) {
	r := fixedProviderLiveAdapterReadinessRuntime()
	if err := r.RequestRealProviderAPI("PARASUT"); !errors.Is(err, ErrProviderLiveAdapterRealOperationClosed) {
		t.Fatalf("real provider API must be blocked, got %v", err)
	}
	if err := r.RequestRealProviderSecretUse("LOGO"); !errors.Is(err, ErrProviderLiveAdapterRealOperationClosed) {
		t.Fatalf("real secret use must be blocked, got %v", err)
	}
	if err := r.RequestRealWebhookIngestion("MIKRO"); !errors.Is(err, ErrProviderLiveAdapterRealOperationClosed) {
		t.Fatalf("real webhook ingestion must be blocked, got %v", err)
	}
	if err := r.RequestRealFileDelivery("ZIRVE"); !errors.Is(err, ErrProviderLiveAdapterRealOperationClosed) {
		t.Fatalf("real file delivery must be blocked, got %v", err)
	}
	if err := r.RequestRealERPWrite("LOGO"); !errors.Is(err, ErrProviderLiveAdapterRealOperationClosed) {
		t.Fatalf("real ERP write must be blocked, got %v", err)
	}
	if err := r.RequestRealOperatorProviderAction("PARASUT"); !errors.Is(err, ErrProviderLiveAdapterRealOperationClosed) {
		t.Fatalf("real operator provider action must be blocked, got %v", err)
	}
}

func TestSevenSixteenGateRejectsOpenedRealProviderAPI(t *testing.T) {
	r := fixedProviderLiveAdapterReadinessRuntime()
	r.gate.RealProviderAPICallAllowed = true
	_, err := r.BuildProviderLiveAdapterReadinessReport(AllProviderLiveAdapterReadinessInput())
	if err == nil {
		t.Fatal("opened provider API gate must be rejected")
	}

	r = fixedProviderLiveAdapterReadinessRuntime()
	r.gate.RealProviderSecretUseAllowed = true
	_, err = r.BuildProviderOperationPlan(ProviderOperationPlanRequest{
		ProviderCode:      "LOGO",
		OperationCode:     "CAPTURE",
		CorrelationID:     "corr",
		IdempotencyKey:    "idem",
		TenantID:          "tenant_7",
		DryRunReferenceID: "dryrun",
	})
	if err == nil {
		t.Fatal("opened secret use gate must be rejected")
	}
}

func TestSevenSixteenAuditTrail(t *testing.T) {
	r := fixedProviderLiveAdapterReadinessRuntime()
	_, _ = r.BuildProviderLiveAdapterReadinessReport(AllProviderLiveAdapterReadinessInput())
	_, _ = r.BuildProviderOperationPlan(ProviderOperationPlanRequest{
		ProviderCode:      "MIKRO",
		OperationCode:     "VOID",
		CorrelationID:     "corr_1",
		IdempotencyKey:    "idem_1",
		TenantID:          "tenant_7",
		DryRunReferenceID: "dryrun_1",
	})
	_ = r.RequestRealProviderAPI("MIKRO")
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
