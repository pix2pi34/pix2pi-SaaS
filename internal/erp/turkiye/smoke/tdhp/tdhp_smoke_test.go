package tdhp

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:          true,
		RequireAllModules:       true,
		RequireVoucherPipeline:  true,
		RequireAccountSwitch:    true,
		RequirePostingRuntime:   true,
		RequireAuditTrace:       true,
		RequireReconciliation:   true,
		RequireTDHPLiveTests:    true,
		RequireTenantGuard:      true,
		RequireCorrelationGuard: true,
		RequireIdempotencyGuard: true,
		RequireSmokeHash:        true,
		MinimumPassCount:        40,
		RequiredModules: []SmokeModule{
			ModuleVoucherPipeline,
			ModuleAccountSwitch,
			ModulePostingRuntime,
			ModuleAuditTrace,
			ModuleReconciliation,
			ModuleTDHPLiveTests,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validRequest() SmokeRequest {
	return SmokeRequest{
		TenantID:       "tenant-tdhp-smoke-001",
		CorrelationID:  "corr-tdhp-smoke-001",
		RequestID:      "req-tdhp-smoke-001",
		IdempotencyKey: "idem-tdhp-smoke-001",
		SmokeID:        "tdhp-smoke-001",
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *TDHPSmokeRuntime {
	t.Helper()

	runtime, err := NewTDHPSmokeRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestTDHPSmokePasses(t *testing.T) {
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
	if result.PassCount < 40 {
		t.Fatalf("expected pass count >= 40, got %d", result.PassCount)
	}
	if result.SmokeHash == "" {
		t.Fatal("expected smoke hash")
	}
}

func TestTDHPSmokeCoversAllModules(t *testing.T) {
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

func TestTDHPSmokeHasTenantCorrelationIdempotencyGuards(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	for _, module := range result.Modules {
		if module.Module == ModuleTDHPLiveTests {
			continue
		}
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

func TestTDHPSmokeCoversVoucherAndPosting(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	voucherReady := false
	postingReady := false

	for _, module := range result.Modules {
		if module.Module == ModuleVoucherPipeline && hasCheck(module.Checks, CheckVoucherBalanced) && hasCheck(module.Checks, CheckPostingReady) {
			voucherReady = true
		}
		if module.Module == ModulePostingRuntime && hasCheck(module.Checks, CheckPostingReady) {
			postingReady = true
		}
	}

	if !voucherReady {
		t.Fatal("expected voucher pipeline readiness")
	}
	if !postingReady {
		t.Fatal("expected posting runtime readiness")
	}
}

func TestTDHPSmokeCoversAuditAndReconciliation(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	auditReady := false
	reconciliationReady := false

	for _, module := range result.Modules {
		if module.Module == ModuleAuditTrace && hasCheck(module.Checks, CheckAuditHash) {
			auditReady = true
		}
		if module.Module == ModuleReconciliation && hasCheck(module.Checks, CheckReconciliation) {
			reconciliationReady = true
		}
	}

	if !auditReady {
		t.Fatal("expected audit trace readiness")
	}
	if !reconciliationReady {
		t.Fatal("expected reconciliation readiness")
	}
}

func TestTDHPSmokeKeepsRealExternalClosed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}
	if result.RealExternalStatus != "CLOSED" {
		t.Fatalf("expected real external closed, got %s", result.RealExternalStatus)
	}
	if result.ProductionApproved {
		t.Fatal("production must remain unapproved in smoke")
	}
}

func TestTDHPSmokeRejectsMissingTenant(t *testing.T) {
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

func TestTDHPSmokeRejectsMinimumPassCount(t *testing.T) {
	cfg := validConfig()
	cfg.MinimumPassCount = 999

	runtime, err := NewTDHPSmokeRuntime(cfg)
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
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewTDHPSmokeRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingModulesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredModules = nil

	_, err := NewTDHPSmokeRuntime(cfg)
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
