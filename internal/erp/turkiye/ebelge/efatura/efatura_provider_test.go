package efatura

import (
	"testing"
	"time"
)

func validConfig() ProviderConfig {
	return ProviderConfig{
		ProviderCode:       "SIM_GIB_EFATURA",
		Mode:               ProviderModeSimulation,
		RealAPIGateOpen:    false,
		EndpointBaseURL:    "https://simulation.local/efatura",
		CredentialRef:      "secret://simulation/e-fatura",
		RequestTimeoutMS:   5000,
		MaxRetryCount:      3,
		SignatureRequired:  true,
		UBLRequired:        true,
		ProductionApproved: false,
	}
}

func validRequest() ProviderRequest {
	return ProviderRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-001",
		RequestID:      "req-001",
		IdempotencyKey: "idem-001",
		Operation:      OperationSend,
		DocumentID:     "doc-001",
		DocumentNo:     "EF2026000000001",
		DocumentType:   EFaturaInvoice,
		TaxIdentityNo:  "1234567890",
		PartyTitle:     "Test Musteri A.S.",
		CurrencyCode:   "TRY",
		TotalAmount:    125000,
		UBLHash:        "sha256:test-ubl-hash",
		RequestedAt:    time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC),
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = ProviderModeProduction
	cfg.RealAPIGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewEFaturaProviderRuntime(cfg); err == nil {
		t.Fatal("expected production gate to be closed")
	}
}

func TestSendInvoiceSimulationAllowed(t *testing.T) {
	runtime, err := NewEFaturaProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.SendInvoice(validRequest())
	if err != nil {
		t.Fatalf("send invoice failed: %v", err)
	}

	if resp.DecisionStatus != DecisionAllowed {
		t.Fatalf("expected allowed decision, got %s", resp.DecisionStatus)
	}
	if resp.EFaturaStatus != EFaturaProviderQueued {
		t.Fatalf("expected provider queued status, got %s", resp.EFaturaStatus)
	}
	if resp.ProviderDocumentID == "" {
		t.Fatal("expected provider document id")
	}
	if resp.ProviderEnvelopeID == "" {
		t.Fatal("expected provider envelope id")
	}
}

func TestSendInvoiceRequiresUBLHash(t *testing.T) {
	runtime, err := NewEFaturaProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.UBLHash = ""

	resp, err := runtime.SendInvoice(req)
	if err == nil {
		t.Fatal("expected validation error")
	}
	if resp.DecisionStatus != DecisionDenied {
		t.Fatalf("expected denied decision, got %s", resp.DecisionStatus)
	}
	if resp.ErrorCode != "SEND_VALIDATION_FAILED" {
		t.Fatalf("expected SEND_VALIDATION_FAILED, got %s", resp.ErrorCode)
	}
}

func TestStatusCancelAndDownloadUBL(t *testing.T) {
	runtime, err := NewEFaturaProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()

	statusResp, err := runtime.CheckStatus(req)
	if err != nil {
		t.Fatalf("check status failed: %v", err)
	}
	if statusResp.EFaturaStatus != EFaturaDelivered {
		t.Fatalf("expected delivered, got %s", statusResp.EFaturaStatus)
	}

	cancelReq := req
	cancelReq.CancelReasonCode = "CUSTOMER_REQUEST"
	cancelReq.CancelReasonText = "Musteri talebi"

	cancelResp, err := runtime.CancelInvoice(cancelReq)
	if err != nil {
		t.Fatalf("cancel invoice failed: %v", err)
	}
	if cancelResp.EFaturaStatus != EFaturaCanceled {
		t.Fatalf("expected canceled, got %s", cancelResp.EFaturaStatus)
	}

	ublResp, err := runtime.DownloadUBL(req)
	if err != nil {
		t.Fatalf("download ubl failed: %v", err)
	}
	if ublResp.Operation != OperationDownloadUBL {
		t.Fatalf("expected download ubl operation, got %s", ublResp.Operation)
	}
}

func TestCancelRequiresReasonCode(t *testing.T) {
	runtime, err := NewEFaturaProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.CancelInvoice(validRequest())
	if err == nil {
		t.Fatal("expected cancel reason error")
	}
	if resp.ErrorCode != "CANCEL_REASON_REQUIRED" {
		t.Fatalf("expected cancel reason error code, got %s", resp.ErrorCode)
	}
}
