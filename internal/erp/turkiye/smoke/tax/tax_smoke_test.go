package tax

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:          true,
		RequireAllModules:       true,
		RequireKDVRuntime:       true,
		RequireStopajRuntime:    true,
		RequireExemptionRuntime: true,
		RequireRuleRollout:      true,
		RequireAuditPersistence: true,
		RequireTaxRuntimeTests:  true,
		RequireTenantGuard:      true,
		RequireCorrelationGuard: true,
		RequireIdempotencyGuard: true,
		RequireSmokeHash:        true,
		MinimumPassCount:        50,
		RequiredModules: []SmokeModule{
			ModuleKDVRuntime,
			ModuleStopajRuntime,
			ModuleExemptionRuntime,
			ModuleRuleRollout,
			ModuleAuditPersistence,
			ModuleTaxRuntimeTests,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validRequest() SmokeRequest {
	return SmokeRequest{
		TenantID:       "tenant-tax-smoke-001",
		CorrelationID:  "corr-tax-smoke-001",
		RequestID:      "req-tax-smoke-001",
		IdempotencyKey: "idem-tax-smoke-001",
		SmokeID:        "tax-smoke-001",
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *TaxSmokeRuntime {
	t.Helper()

	runtime, err := NewTaxSmokeRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestTaxSmokePasses(t *testing.T) {
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
	if result.PassCount < 50 {
		t.Fatalf("expected pass count >= 50, got %d", result.PassCount)
	}
	if result.SmokeHash == "" {
		t.Fatal("expected smoke hash")
	}
}

func TestTaxSmokeCoversAllModules(t *testing.T) {
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

func TestTaxSmokeHasTenantCorrelationIdempotencyGuards(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	for _, module := range result.Modules {
		if module.Module == ModuleTaxRuntimeTests {
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

func TestTaxSmokeCoversKDVStopajExemption(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	kdvReady := false
	stopajReady := false
	exemptionReady := false

	for _, module := range result.Modules {
		if module.Module == ModuleKDVRuntime && hasCheck(module.Checks, CheckKDVRateCoverage) && hasCheck(module.Checks, CheckTDHPAccountTrace) {
			kdvReady = true
		}
		if module.Module == ModuleStopajRuntime && hasCheck(module.Checks, CheckStopajSubjectCoverage) && hasCheck(module.Checks, CheckTDHPAccountTrace) {
			stopajReady = true
		}
		if module.Module == ModuleExemptionRuntime && hasCheck(module.Checks, CheckExemptionCoverage) {
			exemptionReady = true
		}
	}

	if !kdvReady {
		t.Fatal("expected KDV readiness")
	}
	if !stopajReady {
		t.Fatal("expected stopaj readiness")
	}
	if !exemptionReady {
		t.Fatal("expected exemption readiness")
	}
}

func TestTaxSmokeCoversRolloutAndAuditPersistence(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	rolloutReady := false
	auditReady := false

	for _, module := range result.Modules {
		if module.Module == ModuleRuleRollout && hasCheck(module.Checks, CheckRolloutCoverage) && hasCheck(module.Checks, CheckAuditHash) {
			rolloutReady = true
		}
		if module.Module == ModuleAuditPersistence && hasCheck(module.Checks, CheckAuditPersistence) && hasCheck(module.Checks, CheckAuditHash) {
			auditReady = true
		}
	}

	if !rolloutReady {
		t.Fatal("expected rollout readiness")
	}
	if !auditReady {
		t.Fatal("expected audit persistence readiness")
	}
}

func TestTaxSmokeKeepsRealExternalClosed(t *testing.T) {
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
	if result.LegalRuleStatus != "READY_FOR_RULE_VERSION_CONTROL" {
		t.Fatalf("unexpected legal rule status: %s", result.LegalRuleStatus)
	}
}

func TestTaxSmokeRejectsMissingTenant(t *testing.T) {
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

func TestTaxSmokeRejectsMinimumPassCount(t *testing.T) {
	cfg := validConfig()
	cfg.MinimumPassCount = 999

	runtime, err := NewTaxSmokeRuntime(cfg)
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

	_, err := NewTaxSmokeRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingModulesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredModules = nil

	_, err := NewTaxSmokeRuntime(cfg)
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
