package payment

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:               true,
		RequireAllModules:            true,
		RequirePOSProvider:           true,
		RequireBankCollection:        true,
		RequireReconciliation:        true,
		RequireRefundCancel:          true,
		RequireStatusSync:            true,
		RequireErrorRetry:            true,
		RequireIntegrationAudit:      true,
		RequireIntegrationTests:      true,
		RequireTenantGuard:           true,
		RequireCorrelationGuard:      true,
		RequireIdempotencyGuard:      true,
		RequireRealPaymentGateClosed: true,
		RequireSmokeHash:             true,
		MinimumPassCount:             60,
		RequiredModules: []SmokeModule{
			ModulePOSProvider,
			ModuleBankCollection,
			ModuleReconciliation,
			ModuleRefundCancel,
			ModuleStatusSync,
			ModuleErrorRetry,
			ModuleIntegrationAudit,
			ModuleIntegrationTests,
		},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 8, 0, 5, 0, 0, time.UTC)
}

func validRequest() SmokeRequest {
	return SmokeRequest{
		TenantID:       "tenant-payment-smoke-001",
		CorrelationID:  "corr-payment-smoke-001",
		RequestID:      "req-payment-smoke-001",
		IdempotencyKey: "idem-payment-smoke-001",
		SmokeID:        "payment-smoke-001",
		RequestedAt:    validNow(),
	}
}

func newRuntime(t *testing.T) *PaymentSmokeRuntime {
	t.Helper()

	runtime, err := NewPaymentSmokeRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestPaymentSmokePasses(t *testing.T) {
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
	if result.PassCount < 60 {
		t.Fatalf("expected pass count >= 60, got %d", result.PassCount)
	}
	if result.SmokeHash == "" {
		t.Fatal("expected smoke hash")
	}
}

func TestPaymentSmokeCoversAllModules(t *testing.T) {
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

func TestPaymentSmokeKeepsRealPaymentGateClosed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}
	if result.RealPaymentGateStatus != "CLOSED" {
		t.Fatalf("expected real payment gate CLOSED, got %s", result.RealPaymentGateStatus)
	}
	if result.RealBankGateStatus != "CLOSED" {
		t.Fatalf("expected real bank gate CLOSED, got %s", result.RealBankGateStatus)
	}
	if result.ProductionApproved {
		t.Fatal("production must remain unapproved in payment smoke")
	}
}

func TestPaymentSmokeCoversProviderBankReconciliation(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	posReady := false
	bankReady := false
	reconReady := false

	for _, module := range result.Modules {
		if module.Module == ModulePOSProvider && hasCheck(module.Checks, CheckProviderOperation) {
			posReady = true
		}
		if module.Module == ModuleBankCollection && hasCheck(module.Checks, CheckBankOperation) {
			bankReady = true
		}
		if module.Module == ModuleReconciliation && hasCheck(module.Checks, CheckReconciliation) {
			reconReady = true
		}
	}

	if !posReady {
		t.Fatal("expected POS provider readiness")
	}
	if !bankReady {
		t.Fatal("expected bank collection readiness")
	}
	if !reconReady {
		t.Fatal("expected reconciliation readiness")
	}
}

func TestPaymentSmokeCoversRefundStatusRetryAuditE2E(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Run(validRequest())
	if err != nil {
		t.Fatalf("expected smoke pass, got error: %v", err)
	}

	refundReady := false
	statusReady := false
	retryReady := false
	auditReady := false
	e2eReady := false

	for _, module := range result.Modules {
		if module.Module == ModuleRefundCancel && hasCheck(module.Checks, CheckRefundCancel) {
			refundReady = true
		}
		if module.Module == ModuleStatusSync && hasCheck(module.Checks, CheckStatusSync) {
			statusReady = true
		}
		if module.Module == ModuleErrorRetry && hasCheck(module.Checks, CheckRetryDLQ) {
			retryReady = true
		}
		if module.Module == ModuleIntegrationAudit && hasCheck(module.Checks, CheckIntegrationAudit) {
			auditReady = true
		}
		if module.Module == ModuleIntegrationTests && hasCheck(module.Checks, CheckE2EFlow) {
			e2eReady = true
		}
	}

	if !refundReady {
		t.Fatal("expected refund/cancel readiness")
	}
	if !statusReady {
		t.Fatal("expected status sync readiness")
	}
	if !retryReady {
		t.Fatal("expected retry/DLQ readiness")
	}
	if !auditReady {
		t.Fatal("expected integration audit readiness")
	}
	if !e2eReady {
		t.Fatal("expected E2E readiness")
	}
}

func TestPaymentSmokeHasTenantCorrelationIdempotencyGuards(t *testing.T) {
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

func TestPaymentSmokeRejectsMissingTenant(t *testing.T) {
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

func TestPaymentSmokeRejectsMinimumPassCount(t *testing.T) {
	cfg := validConfig()
	cfg.MinimumPassCount = 999

	runtime, err := NewPaymentSmokeRuntime(cfg)
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

	_, err := NewPaymentSmokeRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingModulesConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredModules = nil

	_, err := NewPaymentSmokeRuntime(cfg)
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
