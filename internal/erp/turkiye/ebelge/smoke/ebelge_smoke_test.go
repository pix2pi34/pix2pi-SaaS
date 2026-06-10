package smoke

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:              true,
		RequireAllModules:           true,
		RequireProviderRuntime:      true,
		RequireProviderOperations:   true,
		RequireProductionGateClosed: true,
		RequireTenantGuard:          true,
		RequireCorrelationGuard:     true,
		RequireIdempotencyGuard:     true,
		RequireDocumentGuard:        true,
		RequireStatusSync:           true,
		RequireRetryDLQ:             true,
		RequireLiveGateClosed:       true,
		RequireSmokeHash:            true,
		MinimumPassCount:            30,
		RequiredModules: []SmokeModule{
			ModuleEFaturaProvider,
			ModuleEArsivProvider,
			ModuleEAdisyonProvider,
			ModuleStatusSync,
			ModuleErrorCancelRetry,
			ModuleLiveIntegrationTests,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validRequest() SmokeRequest {
	return SmokeRequest{
		TenantID:       "tenant-smoke-001",
		CorrelationID:  "corr-ebelge-smoke-001",
		RequestID:      "req-ebelge-smoke-001",
		IdempotencyKey: "idem-ebelge-smoke-001",
		SmokeID:        "ebelge-smoke-001",
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *EBelgeSmokeRuntime {
	t.Helper()

	runtime, err := NewEBelgeSmokeRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestEBelgeSmokePasses(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}
	if result.Status != SmokeStatusPass {
		t.Fatalf("expected PASS, got %s", result.Status)
	}
	if result.FailCount != 0 {
		t.Fatalf("expected fail count 0, got %d", result.FailCount)
	}
	if result.PassCount < 30 {
		t.Fatalf("expected pass count >= 30, got %d", result.PassCount)
	}
	if result.SmokeHash == "" {
		t.Fatal("expected smoke hash")
	}
}

func TestEBelgeSmokeCoversAllModules(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	seen := map[SmokeModule]bool{}
	for _, module := range result.Modules {
		seen[module.Module] = true
	}

	for _, required := range validConfig().RequiredModules {
		if !seen[required] {
			t.Fatalf("expected module %s", required)
		}
	}
}

func TestEBelgeSmokeProviderModulesHaveProductionGateClosed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	for _, module := range result.Modules {
		switch module.Module {
		case ModuleEFaturaProvider, ModuleEArsivProvider, ModuleEAdisyonProvider, ModuleLiveIntegrationTests:
			if !hasCheck(module.Checks, CheckProductionGateClosed) {
				t.Fatalf("expected production gate check for %s", module.Module)
			}
		}
	}
}

func TestEBelgeSmokeHasTenantCorrelationIdempotencyGuards(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	for _, module := range result.Modules {
		if !hasCheck(module.Checks, CheckTenantGuard) {
			t.Fatalf("expected tenant guard for %s", module.Module)
		}
		if !hasCheck(module.Checks, CheckCorrelationGuard) {
			t.Fatalf("expected correlation guard for %s", module.Module)
		}
		if !hasCheck(module.Checks, CheckIdempotencyGuard) {
			t.Fatalf("expected idempotency guard for %s", module.Module)
		}
	}
}

func TestEBelgeSmokeStatusSyncCovered(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	found := false
	for _, module := range result.Modules {
		if module.Module == ModuleStatusSync && hasCheck(module.Checks, CheckStatusSync) {
			found = true
		}
	}
	if !found {
		t.Fatal("expected status sync coverage")
	}
}

func TestEBelgeSmokeRetryDLQCovered(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	found := false
	for _, module := range result.Modules {
		if module.Module == ModuleErrorCancelRetry && hasCheck(module.Checks, CheckRetryDLQ) {
			found = true
		}
	}
	if !found {
		t.Fatal("expected retry DLQ coverage")
	}
}

func TestEBelgeSmokeRejectsMissingTenant(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.TenantID = ""

	result, err := runtime.Run(req)
	if err == nil {
		t.Fatal("expected validation failure")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestEBelgeSmokeRejectsMinimumPassCount(t *testing.T) {
	cfg := validConfig()
	cfg.MinimumPassCount = 999

	runtime, err := NewEBelgeSmokeRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.Run(validRequest())
	if err == nil {
		t.Fatal("expected minimum pass count failure")
	}
	if result.Status != SmokeStatusFail {
		t.Fatalf("expected FAIL, got %s", result.Status)
	}
	if result.ErrorCode != "" {
		t.Fatalf("did not expect validation error code, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewEBelgeSmokeRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingModulesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredModules = nil

	_, err := NewEBelgeSmokeRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing required modules error")
	}
}

func hasCheck(items []SmokeCheck, check SmokeCheck) bool {
	for _, item := range items {
		if item == check {
			return true
		}
	}
	return false
}
