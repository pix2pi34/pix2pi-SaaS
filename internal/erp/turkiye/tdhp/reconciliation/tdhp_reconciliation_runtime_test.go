package reconciliation

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:         true,
		RequireTenantScope:     true,
		RequireCorrelation:     true,
		RequireIdempotency:     true,
		RequirePostingHash:     true,
		RequireAuditTraceHash:  true,
		RequireLedgerReady:     true,
		RequireBalancedAmounts: true,
		RequireResultHash:      true,
		DefaultCurrency:        "TRY",
		ToleranceMinor:         0,
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validRequest() ReconciliationRequest {
	return ReconciliationRequest{
		TenantID:            "tenant-tdhp-001",
		CorrelationID:       "corr-tdhp-recon-001",
		RequestID:           "req-tdhp-recon-001",
		IdempotencyKey:      "idem-tdhp-recon-001",
		ReconciliationID:    "recon-001",
		DocumentID:          "doc-001",
		DocumentNo:          "INV-001",
		VoucherID:           "voucher-001",
		VoucherNo:           "JRNL-001",
		PostingID:           "posting-001",
		ExpectedDebitMinor:  120000,
		ExpectedCreditMinor: 120000,
		ActualDebitMinor:    120000,
		ActualCreditMinor:   120000,
		Currency:            "TRY",
		PostingHash:         "posting-hash-001",
		AuditTraceHash:      "audit-trace-hash-001",
		LedgerReady:         true,
		RequestedAt:         validNow(),
	}
}

func newRuntime(t *testing.T) *TDHPReconciliationRuntime {
	t.Helper()

	runtime, err := NewTDHPReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestReconcileMatched(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Reconcile(validRequest())
	if err != nil {
		t.Fatalf("expected matched reconciliation, got error: %v", err)
	}
	if result.Status != ReconciliationStatusMatched {
		t.Fatalf("expected MATCHED, got %s", result.Status)
	}
	if result.Decision != DecisionMatched {
		t.Fatalf("expected MATCHED decision, got %s", result.Decision)
	}
	if result.ResultHash == "" {
		t.Fatal("expected result hash")
	}
}

func TestReconcileDifferenceReview(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.ActualDebitMinor = 119900
	req.ActualCreditMinor = 119900

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected difference review error")
	}
	if result.Status != ReconciliationStatusDifferenceReview {
		t.Fatalf("expected DIFFERENCE_REVIEW, got %s", result.Status)
	}
	if result.Decision != DecisionManualReview {
		t.Fatalf("expected MANUAL_REVIEW, got %s", result.Decision)
	}
}

func TestReconcileRejectsUnbalancedExpected(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.ExpectedCreditMinor = 110000

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected unbalanced expected error")
	}
	if result.Status != ReconciliationStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
}

func TestReconcileRejectsUnbalancedActual(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.ActualCreditMinor = 110000

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected unbalanced actual error")
	}
	if result.Status != ReconciliationStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
}

func TestReconcileRejectsCurrencyMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Currency = "USD"

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected currency mismatch error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestReconcileRejectsMissingPostingHash(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.PostingHash = ""

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected posting hash error")
	}
	if result.Status != ReconciliationStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
}

func TestReconcileRejectsMissingAuditTraceHash(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.AuditTraceHash = ""

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected audit trace hash error")
	}
	if result.Status != ReconciliationStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
}

func TestReconcileRejectsLedgerNotReady(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.LedgerReady = false

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected ledger ready error")
	}
	if result.Status != ReconciliationStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewTDHPReconciliationRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingCurrencyConfig(t *testing.T) {
	cfg := validConfig()
	cfg.DefaultCurrency = ""

	_, err := NewTDHPReconciliationRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing currency config error")
	}
}
