package reconciliation

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:               true,
		DefaultCurrencyCode:          "TRY",
		ReconciliationToleranceKurus: 100,
		IdempotencyRequired:          true,
		StatementHashRequired:        true,
		ProviderPayloadHashRequired:  true,
		ManualReviewEnabled:          true,
		AllowedChannels: []ReconciliationChannel{
			ChannelPOS,
			ChannelVirtualPOS,
			ChannelBankTransfer,
			ChannelBankCollection,
			ChannelMarketplaceSettlement,
		},
		AllowedProviderCodes: []string{
			"SIM_BANK_POS",
			"SIM_BANK",
			"SIM_MARKETPLACE",
		},
	}
}

func validRequest() ReconciliationRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return ReconciliationRequest{
		TenantID:              "tenant-001",
		CorrelationID:         "corr-001",
		RequestID:             "req-001",
		IdempotencyKey:        "idem-001",
		ReconciliationID:      "recon-001",
		PaymentTransactionID:  "pay-001",
		TransactionNo:         "PAY-001",
		Channel:               ChannelPOS,
		ProviderCode:          "SIM_BANK_POS",
		ProviderTransactionID: "provider-pay-001",
		ProviderPayloadHash:   "sha256:provider",
		BankAccountID:         "bank-account-001",
		BankReferenceNo:       "BANK-REF-001",
		StatementLineID:       "STMT-001",
		StatementPayloadHash:  "sha256:statement",
		SourceDocumentType:    "SALES_INVOICE",
		SourceDocumentID:      "inv-001",
		SourceDocumentNo:      "INV-001",
		LedgerMovementID:      "ledger-001",
		JournalID:             "journal-001",
		ExpectedAmountKurus:   100000,
		ActualAmountKurus:     100050,
		CurrencyCode:          "TRY",
		OccurredAt:            now,
		RequestedAt:           now.Add(time.Second),
	}
}

func TestReconcilePaymentCaptureWithinTolerance(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.ReconcilePaymentCapture(validRequest())
	if err != nil {
		t.Fatalf("reconcile payment capture failed: %v", err)
	}

	if result.DecisionStatus != DecisionMatched {
		t.Fatalf("expected matched, got %s", result.DecisionStatus)
	}
	if !result.Matched {
		t.Fatal("expected matched true")
	}
	if !result.LedgerPostingReady {
		t.Fatal("expected ledger posting ready")
	}
	if !result.PaymentClosureReady {
		t.Fatal("expected payment closure ready")
	}
	if result.DifferenceAmountKurus != 50 {
		t.Fatalf("expected diff 50, got %d", result.DifferenceAmountKurus)
	}
}

func TestReconcilePaymentCaptureDifferenceReview(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ActualAmountKurus = 101000

	result, err := runtime.ReconcilePaymentCapture(req)
	if err != nil {
		t.Fatalf("reconcile payment capture failed: %v", err)
	}

	if result.DecisionStatus != DecisionDifferenceReview {
		t.Fatalf("expected difference review, got %s", result.DecisionStatus)
	}
	if !result.ManualReviewRequired {
		t.Fatal("expected manual review required")
	}
	if result.LedgerPostingReady {
		t.Fatal("expected ledger posting not ready")
	}
}

func TestReconcileBankStatementRequiresStatementHash(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Channel = ChannelBankCollection
	req.ProviderCode = "SIM_BANK"
	req.StatementPayloadHash = ""

	result, err := runtime.ReconcileBankStatement(req)
	if err == nil {
		t.Fatal("expected statement hash error")
	}
	if result.ErrorCode != "STATEMENT_PAYLOAD_HASH_REQUIRED" {
		t.Fatalf("expected STATEMENT_PAYLOAD_HASH_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestReconcileBankStatementMatched(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Channel = ChannelBankCollection
	req.ProviderCode = "SIM_BANK"

	result, err := runtime.ReconcileBankStatement(req)
	if err != nil {
		t.Fatalf("bank statement reconcile failed: %v", err)
	}
	if result.DecisionStatus != DecisionMatched {
		t.Fatalf("expected matched, got %s", result.DecisionStatus)
	}
}

func TestReconcileMarketplaceSettlementUsesNetAmount(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Channel = ChannelMarketplaceSettlement
	req.ProviderCode = "SIM_MARKETPLACE"
	req.MarketplaceSettlementID = "settlement-001"
	req.ExpectedAmountKurus = 100000
	req.FeeAmountKurus = 2500
	req.CommissionAmountKurus = 5000
	req.ActualAmountKurus = 92500

	result, err := runtime.ReconcileMarketplaceSettlement(req)
	if err != nil {
		t.Fatalf("marketplace reconcile failed: %v", err)
	}
	if result.DecisionStatus != DecisionMatched {
		t.Fatalf("expected matched, got %s", result.DecisionStatus)
	}
	if result.ExpectedAmountKurus != 92500 {
		t.Fatalf("expected net amount 92500, got %d", result.ExpectedAmountKurus)
	}
}

func TestReconcileMarketplaceSettlementRequiresSettlementID(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.Channel = ChannelMarketplaceSettlement
	req.ProviderCode = "SIM_MARKETPLACE"
	req.MarketplaceSettlementID = ""

	result, err := runtime.ReconcileMarketplaceSettlement(req)
	if err == nil {
		t.Fatal("expected marketplace settlement id error")
	}
	if result.ErrorCode != "MARKETPLACE_SETTLEMENT_ID_REQUIRED" {
		t.Fatalf("expected MARKETPLACE_SETTLEMENT_ID_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestReconcileRefundReversalMatched(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.ReconcileRefundReversal(validRequest())
	if err != nil {
		t.Fatalf("refund reversal reconcile failed: %v", err)
	}
	if result.DecisionStatus != DecisionMatched {
		t.Fatalf("expected matched, got %s", result.DecisionStatus)
	}
}

func TestRegisterManualReview(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ActualAmountKurus = 101000

	result, err := runtime.RegisterManualReview(req, "operator review required")
	if err != nil {
		t.Fatalf("manual review failed: %v", err)
	}

	if result.ReconciliationStatus != StatusManualReview {
		t.Fatalf("expected manual review, got %s", result.ReconciliationStatus)
	}
	if !result.ManualReviewRequired {
		t.Fatal("expected manual review required")
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	if _, err := NewReconciliationRuntime(cfg); err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestValidationRejectsCurrencyMismatch(t *testing.T) {
	runtime, err := NewReconciliationRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.CurrencyCode = "USD"

	result, err := runtime.ReconcilePaymentCapture(req)
	if err == nil {
		t.Fatal("expected currency mismatch")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}
