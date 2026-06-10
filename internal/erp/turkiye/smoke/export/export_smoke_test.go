package exportsmoke

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:          true,
		RequireAllModules:       true,
		RequireETAFormat:        true,
		RequireLogoFormat:       true,
		RequireMikroFormat:      true,
		RequireZirveFormat:      true,
		RequireFormatMatrix:     true,
		RequireAdapterTests:     true,
		RequireTenantGuard:      true,
		RequireCorrelationGuard: true,
		RequireIdempotencyGuard: true,
		RequireSmokeHash:        true,
		MinimumPassCount:        70,
		RequiredModules: []SmokeModule{
			ModuleETAFormat,
			ModuleLogoFormat,
			ModuleMikroFormat,
			ModuleZirveFormat,
			ModuleFormatMatrix,
			ModuleAdapterTests,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validRequest() SmokeRequest {
	return SmokeRequest{
		TenantID:       "tenant-export-smoke-001",
		CorrelationID:  "corr-export-smoke-001",
		RequestID:      "req-export-smoke-001",
		IdempotencyKey: "idem-export-smoke-001",
		SmokeID:        "export-smoke-001",
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *ExportSmokeRuntime {
	t.Helper()

	runtime, err := NewExportSmokeRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestExportSmokePasses(t *testing.T) {
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
	if result.PassCount < 70 {
		t.Fatalf("expected pass count >= 70, got %d", result.PassCount)
	}
	if result.SmokeHash == "" {
		t.Fatal("expected smoke hash")
	}
}

func TestExportSmokeCoversAllModules(t *testing.T) {
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

func TestExportSmokeCoversAllExportTargets(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	expected := map[SmokeModule]bool{
		ModuleETAFormat:   false,
		ModuleLogoFormat:  false,
		ModuleMikroFormat: false,
		ModuleZirveFormat: false,
	}

	for _, module := range result.Modules {
		if _, ok := expected[module.Module]; ok {
			if !hasCheck(module.Checks, CheckTargetSystemGuard) {
				t.Fatalf("expected target system guard for %s", module.Module)
			}
			if !hasCheck(module.Checks, CheckFormatVersionGuard) {
				t.Fatalf("expected format version guard for %s", module.Module)
			}
			expected[module.Module] = true
		}
	}

	for module, seen := range expected {
		if !seen {
			t.Fatalf("expected export target %s", module)
		}
	}
}

func TestExportSmokeCoversHashesAndFiles(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	for _, module := range result.Modules {
		if module.Module == ModuleFormatMatrix || module.Module == ModuleAdapterTests {
			continue
		}
		if !hasCheck(module.Checks, CheckPackageHash) {
			t.Fatalf("expected package hash for %s", module.Module)
		}
		if !hasCheck(module.Checks, CheckFileHash) {
			t.Fatalf("expected file hash for %s", module.Module)
		}
		if !hasCheck(module.Checks, CheckJournalFile) {
			t.Fatalf("expected journal file for %s", module.Module)
		}
		if !hasCheck(module.Checks, CheckLedgerFile) {
			t.Fatalf("expected ledger file for %s", module.Module)
		}
		if !hasCheck(module.Checks, CheckSummaryFile) {
			t.Fatalf("expected summary file for %s", module.Module)
		}
	}
}

func TestExportSmokeCoversMatrixAndAdapterTests(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	matrixReady := false
	adapterReady := false

	for _, module := range result.Modules {
		if module.Module == ModuleFormatMatrix && hasCheck(module.Checks, CheckAllTargetsCovered) && hasCheck(module.Checks, CheckNegativeTests) {
			matrixReady = true
		}
		if module.Module == ModuleAdapterTests && hasCheck(module.Checks, CheckAllTargetsCovered) && hasCheck(module.Checks, CheckNegativeTests) {
			adapterReady = true
		}
	}

	if !matrixReady {
		t.Fatal("expected format matrix readiness")
	}
	if !adapterReady {
		t.Fatal("expected adapter tests readiness")
	}
}

func TestExportSmokeKeepsRealDeliveryClosed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}
	if result.RealDeliveryStatus != "CLOSED" {
		t.Fatalf("expected real delivery closed, got %s", result.RealDeliveryStatus)
	}
	if result.ProductionApproved {
		t.Fatal("production must remain unapproved in smoke")
	}
}

func TestExportSmokeRejectsMissingTenant(t *testing.T) {
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

func TestExportSmokeRejectsMinimumPassCount(t *testing.T) {
	cfg := validConfig()
	cfg.MinimumPassCount = 999

	runtime, err := NewExportSmokeRuntime(cfg)
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

	_, err := NewExportSmokeRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingModulesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredModules = nil

	_, err := NewExportSmokeRuntime(cfg)
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
