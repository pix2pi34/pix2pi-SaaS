package livereadiness

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:                 true,
		RequireAllAreas:                true,
		RequireCoreFinalRecheck:        true,
		RequireTDHPLiveTests:           true,
		RequireTaxRuntimeTests:         true,
		RequirePaymentIntegration:      true,
		RequireExportAdapterTests:      true,
		RequireDocumentAITests:         true,
		RequireEBelgeSmoke:             true,
		RequireRealProviderGatesClosed: true,
		RequireClosureHash:             true,
		MinimumPassCount:               40,
		RequiredAreas: []ReadinessArea{
			AreaERPTRCoreFinalRecheck,
			AreaTDHPLiveTests,
			AreaTaxRuntimeTests,
			AreaPaymentIntegration,
			AreaExportAdapterTests,
			AreaDocumentAITests,
			AreaEBelgeSmoke,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validRequest() ClosureRequest {
	return ClosureRequest{
		TenantID:       "tenant-live-readiness-001",
		CorrelationID:  "corr-erp-tr-live-readiness-001",
		RequestID:      "req-erp-tr-live-readiness-001",
		IdempotencyKey: "idem-erp-tr-live-readiness-001",
		ClosureID:      "erp-tr-live-readiness-closure-001",
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *ERPTRLiveReadinessClosureRuntime {
	t.Helper()

	runtime, err := NewERPTRLiveReadinessClosureRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestERPTRLiveReadinessClosurePasses(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Close(validRequest())
	if err != nil {
		t.Fatalf("expected closure pass, got error: %v", err)
	}
	if result.Status != ClosureStatusPass {
		t.Fatalf("expected PASS, got %s", result.Status)
	}
	if result.FailCount != 0 {
		t.Fatalf("expected fail count 0, got %d", result.FailCount)
	}
	if result.PassCount < 40 {
		t.Fatalf("expected pass count >= 40, got %d", result.PassCount)
	}
	if result.ClosureHash == "" {
		t.Fatal("expected closure hash")
	}
}

func TestERPTRLiveReadinessCoversAllAreas(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Close(validRequest())
	if err != nil {
		t.Fatalf("expected closure pass, got error: %v", err)
	}

	seen := map[ReadinessArea]bool{}
	for _, area := range result.Areas {
		seen[area.Area] = true
	}

	for _, required := range validConfig().RequiredAreas {
		if !seen[required] {
			t.Fatalf("expected readiness area %s", required)
		}
	}
}

func TestERPTRLiveReadinessKeepsRealProviderGatesClosed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Close(validRequest())
	if err != nil {
		t.Fatalf("expected closure pass, got error: %v", err)
	}
	if result.RealProviderGateStatus != "CLOSED_UNTIL_PROVIDER_LIVE_APPROVALS" {
		t.Fatalf("expected provider gates closed, got %s", result.RealProviderGateStatus)
	}
	if result.ProductionApproved {
		t.Fatal("production must remain unapproved in this closure")
	}
}

func TestERPTRLiveReadinessIncludesEBelgeSmoke(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Close(validRequest())
	if err != nil {
		t.Fatalf("expected closure pass, got error: %v", err)
	}

	found := false
	for _, area := range result.Areas {
		if area.Area == AreaEBelgeSmoke {
			found = true
			if area.SealStatus != "SEALED" {
				t.Fatalf("expected e-Belge smoke sealed, got %s", area.SealStatus)
			}
			if area.LivePolicy != "REAL_EBELGE_PROVIDER_GATE_CLOSED" {
				t.Fatalf("expected e-Belge real provider gate closed, got %s", area.LivePolicy)
			}
		}
	}
	if !found {
		t.Fatal("expected e-Belge smoke area")
	}
}

func TestERPTRLiveReadinessIncludesDocumentAI(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Close(validRequest())
	if err != nil {
		t.Fatalf("expected closure pass, got error: %v", err)
	}

	found := false
	for _, area := range result.Areas {
		if area.Area == AreaDocumentAITests {
			found = true
			if area.SealStatus != "SEALED" {
				t.Fatalf("expected Document AI sealed, got %s", area.SealStatus)
			}
		}
	}
	if !found {
		t.Fatal("expected Document AI area")
	}
}

func TestERPTRLiveReadinessIncludesPaymentIntegration(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Close(validRequest())
	if err != nil {
		t.Fatalf("expected closure pass, got error: %v", err)
	}

	found := false
	for _, area := range result.Areas {
		if area.Area == AreaPaymentIntegration {
			found = true
			if area.LivePolicy != "REAL_PAYMENT_GATE_CLOSED" {
				t.Fatalf("expected real payment gate closed, got %s", area.LivePolicy)
			}
		}
	}
	if !found {
		t.Fatal("expected payment integration area")
	}
}

func TestERPTRLiveReadinessRejectsMissingTenant(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.TenantID = ""

	result, err := runtime.Close(req)
	if err == nil {
		t.Fatal("expected validation failure")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestERPTRLiveReadinessRejectsMinimumPassCount(t *testing.T) {
	cfg := validConfig()
	cfg.MinimumPassCount = 999

	runtime, err := NewERPTRLiveReadinessClosureRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.Close(validRequest())
	if err == nil {
		t.Fatal("expected minimum pass count failure")
	}
	if result.Status != ClosureStatusFail {
		t.Fatalf("expected FAIL, got %s", result.Status)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewERPTRLiveReadinessClosureRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingAreasConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredAreas = nil

	_, err := NewERPTRLiveReadinessClosureRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing required areas error")
	}
}
