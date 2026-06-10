package bankcollection

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		Mode:                         RuntimeModeSimulation,
		ProviderBankCode:             "SIM_BANK",
		RealBankGateOpen:             false,
		ProductionApproved:           false,
		EndpointBaseURL:              "https://simulation.local/bank",
		CredentialRef:                "secret://simulation/bank",
		RequestTimeoutMS:             5000,
		MaxRetryCount:                3,
		IdempotencyRequired:          true,
		StatementHashRequired:        true,
		ReconciliationToleranceKurus: 100,
	}
}

func validRequest() CollectionRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return CollectionRequest{
		TenantID:             "tenant-001",
		CorrelationID:        "corr-001",
		RequestID:            "req-001",
		IdempotencyKey:       "idem-001",
		Operation:            OperationRegisterTransfer,
		PaymentTransactionID: "pay-001",
		CollectionNo:         "COL-001",
		BankAccountID:        "bank-account-001",
		ProviderBankCode:     "SIM_BANK",
		IBAN:                 "TR000000000000000000000001",
		BankReferenceNo:      "BANK-REF-001",
		StatementLineID:      "stmt-line-001",
		StatementPayloadHash: "sha256:statement",
		PayerPartyID:         "party-001",
		PayerTitle:           "Test Musteri A.S.",
		PayerTaxNo:           "1234567890",
		Description:          "Fatura tahsilati",
		SourceDocumentType:   "SALES_INVOICE",
		SourceDocumentID:     "invoice-001",
		SourceDocumentNo:     "INV-001",
		AmountKurus:          100000,
		CurrencyCode:         "TRY",
		ExpectedAmountKurus:  100000,
		ActualAmountKurus:    100050,
		ValueDate:            now,
		ReceivedAt:           now.Add(time.Second),
		RequestedAt:          now.Add(2 * time.Second),
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = RuntimeModeProduction
	cfg.RealBankGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewBankCollectionRuntime(cfg); err == nil {
		t.Fatal("expected production real bank gate to be closed")
	}
}

func TestRegisterBankTransferAccepted(t *testing.T) {
	runtime, err := NewBankCollectionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.RegisterBankTransfer(validRequest())
	if err != nil {
		t.Fatalf("register transfer failed: %v", err)
	}

	if resp.DecisionStatus != DecisionAccepted {
		t.Fatalf("expected accepted, got %s", resp.DecisionStatus)
	}
	if resp.CollectionStatus != CollectionRegistered {
		t.Fatalf("expected registered, got %s", resp.CollectionStatus)
	}
}

func TestMatchBankStatementRequiresHash(t *testing.T) {
	runtime, err := NewBankCollectionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.StatementPayloadHash = ""

	resp, err := runtime.MatchBankStatement(req)
	if err == nil {
		t.Fatal("expected statement hash error")
	}
	if resp.DecisionStatus != DecisionRejected {
		t.Fatalf("expected rejected, got %s", resp.DecisionStatus)
	}
	if resp.ErrorCode != "STATEMENT_PAYLOAD_HASH_REQUIRED" {
		t.Fatalf("expected STATEMENT_PAYLOAD_HASH_REQUIRED, got %s", resp.ErrorCode)
	}
}

func TestReconcileCollectionWithinTolerance(t *testing.T) {
	runtime, err := NewBankCollectionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.ReconcileCollection(validRequest())
	if err != nil {
		t.Fatalf("reconcile failed: %v", err)
	}

	if resp.CollectionStatus != CollectionReconciled {
		t.Fatalf("expected reconciled, got %s", resp.CollectionStatus)
	}
	if resp.DifferenceAmountKurus != 50 {
		t.Fatalf("expected diff 50, got %d", resp.DifferenceAmountKurus)
	}
	if resp.ReconciliationID == "" {
		t.Fatal("expected reconciliation id")
	}
}

func TestReconcileCollectionRejectsDifferenceExceeded(t *testing.T) {
	runtime, err := NewBankCollectionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ActualAmountKurus = 101000

	resp, err := runtime.ReconcileCollection(req)
	if err == nil {
		t.Fatal("expected tolerance error")
	}
	if resp.ErrorCode != "RECONCILIATION_DIFFERENCE_EXCEEDED" {
		t.Fatalf("expected RECONCILIATION_DIFFERENCE_EXCEEDED, got %s", resp.ErrorCode)
	}
}

func TestBuildSettlementAndStatus(t *testing.T) {
	runtime, err := NewBankCollectionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	settleResp, err := runtime.BuildSettlement(validRequest())
	if err != nil {
		t.Fatalf("build settlement failed: %v", err)
	}
	if settleResp.CollectionStatus != CollectionSettled {
		t.Fatalf("expected settled, got %s", settleResp.CollectionStatus)
	}
	if settleResp.SettlementID == "" {
		t.Fatal("expected settlement id")
	}

	statusResp, err := runtime.CheckStatus(validRequest())
	if err != nil {
		t.Fatalf("status check failed: %v", err)
	}
	if statusResp.CollectionStatus != CollectionMatched {
		t.Fatalf("expected matched status, got %s", statusResp.CollectionStatus)
	}
}

func TestReverseCollectionRequiresReason(t *testing.T) {
	runtime, err := NewBankCollectionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.ReverseCollection(validRequest())
	if err == nil {
		t.Fatal("expected reverse reason error")
	}
	if resp.ErrorCode != "REVERSE_REASON_REQUIRED" {
		t.Fatalf("expected REVERSE_REASON_REQUIRED, got %s", resp.ErrorCode)
	}

	req := validRequest()
	req.ReverseReasonCode = "OPERATOR_REVERSAL"
	req.ReverseReasonText = "Operator iptali"

	reversed, err := runtime.ReverseCollection(req)
	if err != nil {
		t.Fatalf("reverse collection failed: %v", err)
	}
	if reversed.CollectionStatus != CollectionReversed {
		t.Fatalf("expected reversed, got %s", reversed.CollectionStatus)
	}
}

func TestProviderBankCodeMismatchDenied(t *testing.T) {
	runtime, err := NewBankCollectionRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ProviderBankCode = "OTHER_BANK"

	resp, err := runtime.RegisterBankTransfer(req)
	if err == nil {
		t.Fatal("expected provider bank mismatch error")
	}
	if resp.DecisionStatus != DecisionRejected {
		t.Fatalf("expected rejected, got %s", resp.DecisionStatus)
	}
}
