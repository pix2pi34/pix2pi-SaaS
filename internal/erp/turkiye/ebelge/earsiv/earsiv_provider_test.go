package earsiv

import (
	"testing"
	"time"
)

func validConfig() ProviderConfig {
	return ProviderConfig{
		ProviderCode:       "SIM_GIB_EARSIV",
		Mode:               ProviderModeSimulation,
		RealAPIGateOpen:    false,
		EndpointBaseURL:    "https://simulation.local/earsiv",
		CredentialRef:      "secret://simulation/e-arsiv",
		RequestTimeoutMS:   5000,
		MaxRetryCount:      3,
		SignatureRequired:  true,
		UBLRequired:        true,
		PDFRequired:        true,
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
		DocumentNo:     "EA2026000000001",
		DocumentType:   EArsivInvoice,
		TaxIdentityNo:  "11111111111",
		PartyTitle:     "Bireysel Musteri",
		BuyerEmail:     "musteri@example.com",
		CurrencyCode:   "TRY",
		TotalAmount:    75000,
		UBLHash:        "sha256:test-ubl-hash",
		PDFHash:        "sha256:test-pdf-hash",
		RequestedAt:    time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC),
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = ProviderModeProduction
	cfg.RealAPIGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewEArsivProviderRuntime(cfg); err == nil {
		t.Fatal("expected production gate to be closed")
	}
}

func TestSendArchiveSimulationAllowed(t *testing.T) {
	runtime, err := NewEArsivProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.SendArchive(validRequest())
	if err != nil {
		t.Fatalf("send archive failed: %v", err)
	}

	if resp.DecisionStatus != DecisionAllowed {
		t.Fatalf("expected allowed decision, got %s", resp.DecisionStatus)
	}
	if resp.EArsivStatus != EArsivProviderQueued {
		t.Fatalf("expected provider queued status, got %s", resp.EArsivStatus)
	}
	if resp.ProviderDocumentID == "" {
		t.Fatal("expected provider document id")
	}
	if resp.ProviderReportID == "" {
		t.Fatal("expected provider report id")
	}
}

func TestSendArchiveRequiresPDFHash(t *testing.T) {
	runtime, err := NewEArsivProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.PDFHash = ""

	resp, err := runtime.SendArchive(req)
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

func TestStatusCancelPDFAndUBL(t *testing.T) {
	runtime, err := NewEArsivProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()

	statusResp, err := runtime.CheckStatus(req)
	if err != nil {
		t.Fatalf("check status failed: %v", err)
	}
	if statusResp.EArsivStatus != EArsivReported {
		t.Fatalf("expected reported, got %s", statusResp.EArsivStatus)
	}

	cancelReq := req
	cancelReq.CancelReasonCode = "CUSTOMER_REQUEST"
	cancelReq.CancelReasonText = "Musteri talebi"

	cancelResp, err := runtime.CancelArchive(cancelReq)
	if err != nil {
		t.Fatalf("cancel archive failed: %v", err)
	}
	if cancelResp.EArsivStatus != EArsivCanceled {
		t.Fatalf("expected canceled, got %s", cancelResp.EArsivStatus)
	}

	pdfResp, err := runtime.DownloadPDF(req)
	if err != nil {
		t.Fatalf("download pdf failed: %v", err)
	}
	if pdfResp.Operation != OperationDownloadPDF {
		t.Fatalf("expected download pdf operation, got %s", pdfResp.Operation)
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
	runtime, err := NewEArsivProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.CancelArchive(validRequest())
	if err == nil {
		t.Fatal("expected cancel reason error")
	}
	if resp.ErrorCode != "CANCEL_REASON_REQUIRED" {
		t.Fatalf("expected cancel reason error code, got %s", resp.ErrorCode)
	}
}
