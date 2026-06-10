package pos

import (
	"testing"
	"time"
)

func validConfig() POSProviderConfig {
	return POSProviderConfig{
		ProviderCode:        "SIM_BANK_POS",
		Mode:                ProviderModeSimulation,
		RealPaymentGateOpen: false,
		ProductionApproved:  false,
		EndpointBaseURL:     "https://simulation.local/pos",
		CredentialRef:       "secret://simulation/pos",
		RequestTimeoutMS:    5000,
		MaxRetryCount:       3,
		ThreeDSEnabled:      true,
		CaptureRequired:     true,
		IdempotencyRequired: true,
	}
}

func validRequest() POSRequest {
	return POSRequest{
		TenantID:             "tenant-001",
		CorrelationID:        "corr-001",
		RequestID:            "req-001",
		IdempotencyKey:       "idem-001",
		Operation:            OperationAuthorize,
		PaymentTransactionID: "pay-001",
		SourceDocumentType:   "SALES_INVOICE",
		SourceDocumentID:     "invoice-001",
		SourceDocumentNo:     "INV-001",
		MerchantID:           "merchant-001",
		TerminalID:           "terminal-001",
		ProviderCode:         "SIM_BANK_POS",
		AmountKurus:          125000,
		CurrencyCode:         "TRY",
		InstallmentCount:     1,
		CardToken:            "card-token-001",
		MaskedCardPAN:        "4508********1234",
		CardHolderName:       "TEST USER",
		ThreeDSReturnURL:     "https://pix2pi.local/3ds/callback",
		RequestedAt:          time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC),
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = ProviderModeProduction
	cfg.RealPaymentGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewPOSProviderRuntime(cfg); err == nil {
		t.Fatal("expected production real payment gate to be closed")
	}
}

func TestAuthorizeAndSaleSimulationAllowed(t *testing.T) {
	runtime, err := NewPOSProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	authResp, err := runtime.Authorize(validRequest())
	if err != nil {
		t.Fatalf("authorize failed: %v", err)
	}
	if authResp.DecisionStatus != DecisionAllowed {
		t.Fatalf("expected allowed, got %s", authResp.DecisionStatus)
	}
	if authResp.TransactionStatus != TransactionAuthorized {
		t.Fatalf("expected authorized, got %s", authResp.TransactionStatus)
	}
	if authResp.ProviderTxnID == "" {
		t.Fatal("expected provider transaction id")
	}

	saleReq := validRequest()
	saleReq.Operation = OperationSale

	saleResp, err := runtime.Sale(saleReq)
	if err != nil {
		t.Fatalf("sale failed: %v", err)
	}
	if saleResp.TransactionStatus != TransactionSold {
		t.Fatalf("expected sold, got %s", saleResp.TransactionStatus)
	}
}

func TestAuthorizeRequiresMaskedPAN(t *testing.T) {
	runtime, err := NewPOSProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.MaskedCardPAN = "4508123412341234"

	resp, err := runtime.Authorize(req)
	if err == nil {
		t.Fatal("expected masked card validation error")
	}
	if resp.DecisionStatus != DecisionDenied {
		t.Fatalf("expected denied, got %s", resp.DecisionStatus)
	}
	if resp.ErrorCode != "CARD_PAYMENT_VALIDATION_FAILED" {
		t.Fatalf("expected CARD_PAYMENT_VALIDATION_FAILED, got %s", resp.ErrorCode)
	}
}

func TestCaptureStatusRefundAndVoid(t *testing.T) {
	runtime, err := NewPOSProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	base := validRequest()
	base.ProviderTxnID = "provider-txn-001"

	captureResp, err := runtime.Capture(base)
	if err != nil {
		t.Fatalf("capture failed: %v", err)
	}
	if captureResp.TransactionStatus != TransactionCaptured {
		t.Fatalf("expected captured, got %s", captureResp.TransactionStatus)
	}

	statusResp, err := runtime.CheckStatus(base)
	if err != nil {
		t.Fatalf("status check failed: %v", err)
	}
	if statusResp.TransactionStatus != TransactionCaptured {
		t.Fatalf("expected captured status, got %s", statusResp.TransactionStatus)
	}

	refundReq := base
	refundReq.RefundReasonCode = "CUSTOMER_RETURN"

	refundResp, err := runtime.Refund(refundReq)
	if err != nil {
		t.Fatalf("refund failed: %v", err)
	}
	if refundResp.TransactionStatus != TransactionRefunded {
		t.Fatalf("expected refunded, got %s", refundResp.TransactionStatus)
	}

	voidReq := base
	voidReq.VoidReasonCode = "OPERATOR_CANCEL"

	voidResp, err := runtime.Void(voidReq)
	if err != nil {
		t.Fatalf("void failed: %v", err)
	}
	if voidResp.TransactionStatus != TransactionVoided {
		t.Fatalf("expected voided, got %s", voidResp.TransactionStatus)
	}
}

func TestRefundRequiresReason(t *testing.T) {
	runtime, err := NewPOSProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ProviderTxnID = "provider-txn-001"

	resp, err := runtime.Refund(req)
	if err == nil {
		t.Fatal("expected refund reason error")
	}
	if resp.ErrorCode != "REFUND_REASON_REQUIRED" {
		t.Fatalf("expected REFUND_REASON_REQUIRED, got %s", resp.ErrorCode)
	}
}

func TestThreeDSInitAndComplete(t *testing.T) {
	runtime, err := NewPOSProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	initResp, err := runtime.ThreeDSInit(validRequest())
	if err != nil {
		t.Fatalf("3DS init failed: %v", err)
	}
	if initResp.TransactionStatus != TransactionPending3DS {
		t.Fatalf("expected pending 3DS, got %s", initResp.TransactionStatus)
	}
	if initResp.ThreeDSRedirectURL == "" {
		t.Fatal("expected 3DS redirect URL")
	}

	completeReq := validRequest()
	completeReq.ThreeDSMD = "md-value"
	completeReq.ThreeDSPares = "pares-value"

	completeResp, err := runtime.ThreeDSComplete(completeReq)
	if err != nil {
		t.Fatalf("3DS complete failed: %v", err)
	}
	if completeResp.TransactionStatus != TransactionAuthorized {
		t.Fatalf("expected authorized after 3DS, got %s", completeResp.TransactionStatus)
	}
}

func TestProviderCodeMismatchDenied(t *testing.T) {
	runtime, err := NewPOSProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ProviderCode = "OTHER_POS"

	resp, err := runtime.Authorize(req)
	if err == nil {
		t.Fatal("expected provider mismatch error")
	}
	if resp.DecisionStatus != DecisionDenied {
		t.Fatalf("expected denied, got %s", resp.DecisionStatus)
	}
}
