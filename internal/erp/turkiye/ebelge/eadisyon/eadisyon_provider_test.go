package eadisyon

import (
	"testing"
	"time"
)

func validConfig() ProviderConfig {
	return ProviderConfig{
		ProviderCode:       "SIM_GIB_EADISYON",
		Mode:               ProviderModeSimulation,
		RealAPIGateOpen:    false,
		EndpointBaseURL:    "https://simulation.local/eadisyon",
		CredentialRef:      "secret://simulation/e-adisyon",
		RequestTimeoutMS:   5000,
		MaxRetryCount:      3,
		SignatureRequired:  true,
		UBLRequired:        true,
		PDFRequired:        true,
		ProductionApproved: false,
	}
}

func validRequest() ProviderRequest {
	openedAt := time.Date(2026, 5, 7, 10, 30, 0, 0, time.UTC)
	closedAt := time.Date(2026, 5, 7, 11, 20, 0, 0, time.UTC)

	return ProviderRequest{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-001",
		RequestID:           "req-001",
		IdempotencyKey:      "idem-001",
		Operation:           OperationSend,
		DocumentID:          "doc-001",
		DocumentNo:          "AD2026000000001",
		DocumentType:        EAdisyonReceipt,
		VenueID:             "venue-001",
		VenueName:           "Pix2pi Test Lokanta",
		TableNo:             "Masa-7",
		AdisyonNo:           "ADSY-0001",
		WaiterCode:          "GARSON-1",
		TaxIdentityNo:       "11111111111",
		PartyTitle:          "Perakende Musteri",
		CurrencyCode:        "TRY",
		SubtotalAmount:      100000,
		TaxAmount:           10000,
		ServiceChargeAmount: 5000,
		TotalAmount:         115000,
		OpenedAt:            openedAt,
		ClosedAt:            closedAt,
		UBLHash:             "sha256:test-ubl-hash",
		PDFHash:             "sha256:test-pdf-hash",
		RequestedAt:         time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC),
	}
}

func TestRuntimeRejectsProductionWithoutApproval(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = ProviderModeProduction
	cfg.RealAPIGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewEAdisyonProviderRuntime(cfg); err == nil {
		t.Fatal("expected production gate to be closed")
	}
}

func TestOpenCloseAndSendAdisyonSimulationAllowed(t *testing.T) {
	runtime, err := NewEAdisyonProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()

	openResp, err := runtime.OpenAdisyon(req)
	if err != nil {
		t.Fatalf("open adisyon failed: %v", err)
	}
	if openResp.EAdisyonStatus != EAdisyonOpened {
		t.Fatalf("expected opened, got %s", openResp.EAdisyonStatus)
	}

	closeResp, err := runtime.CloseAdisyon(req)
	if err != nil {
		t.Fatalf("close adisyon failed: %v", err)
	}
	if closeResp.EAdisyonStatus != EAdisyonClosed {
		t.Fatalf("expected closed, got %s", closeResp.EAdisyonStatus)
	}

	sendResp, err := runtime.SendAdisyon(req)
	if err != nil {
		t.Fatalf("send adisyon failed: %v", err)
	}
	if sendResp.DecisionStatus != DecisionAllowed {
		t.Fatalf("expected allowed decision, got %s", sendResp.DecisionStatus)
	}
	if sendResp.EAdisyonStatus != EAdisyonProviderQueued {
		t.Fatalf("expected provider queued, got %s", sendResp.EAdisyonStatus)
	}
	if sendResp.ProviderDocumentID == "" {
		t.Fatal("expected provider document id")
	}
	if sendResp.ProviderReportID == "" {
		t.Fatal("expected provider report id")
	}
}

func TestSendAdisyonRequiresPDFHash(t *testing.T) {
	runtime, err := NewEAdisyonProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.PDFHash = ""

	resp, err := runtime.SendAdisyon(req)
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

func TestCloseAdisyonRejectsClosedAtBeforeOpenedAt(t *testing.T) {
	runtime, err := NewEAdisyonProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()
	req.ClosedAt = req.OpenedAt.Add(-time.Minute)

	resp, err := runtime.CloseAdisyon(req)
	if err == nil {
		t.Fatal("expected closed_at validation error")
	}
	if resp.ErrorCode != "CLOSED_AT_BEFORE_OPENED_AT" {
		t.Fatalf("expected CLOSED_AT_BEFORE_OPENED_AT, got %s", resp.ErrorCode)
	}
}

func TestStatusCancelPDFAndUBL(t *testing.T) {
	runtime, err := NewEAdisyonProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRequest()

	statusResp, err := runtime.CheckStatus(req)
	if err != nil {
		t.Fatalf("check status failed: %v", err)
	}
	if statusResp.EAdisyonStatus != EAdisyonReported {
		t.Fatalf("expected reported, got %s", statusResp.EAdisyonStatus)
	}

	cancelReq := req
	cancelReq.CancelReasonCode = "CUSTOMER_REQUEST"
	cancelReq.CancelReasonText = "Musteri talebi"

	cancelResp, err := runtime.CancelAdisyon(cancelReq)
	if err != nil {
		t.Fatalf("cancel adisyon failed: %v", err)
	}
	if cancelResp.EAdisyonStatus != EAdisyonCanceled {
		t.Fatalf("expected canceled, got %s", cancelResp.EAdisyonStatus)
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
	runtime, err := NewEAdisyonProviderRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	resp, err := runtime.CancelAdisyon(validRequest())
	if err == nil {
		t.Fatal("expected cancel reason error")
	}
	if resp.ErrorCode != "CANCEL_REASON_REQUIRED" {
		t.Fatalf("expected cancel reason error code, got %s", resp.ErrorCode)
	}
}
