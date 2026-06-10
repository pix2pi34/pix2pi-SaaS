package voucherpipeline

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:        true,
		DefaultCurrencyCode:   "TRY",
		IdempotencyRequired:   true,
		StrictBalanceRequired: true,
		RequireTaxTrace:       true,
		RequirePartyTrace:     true,
		AllowedDocumentTypes: []DocumentType{
			DocumentTypeSalesInvoice,
			DocumentTypePurchaseInvoice,
			DocumentTypePaymentCollection,
			DocumentTypeSalesRefund,
			DocumentTypePurchaseRefund,
			DocumentTypeOpeningBalance,
		},
		RequiredStages: []PipelineStage{
			StageInputValidated,
			StageAccountMapped,
			StageLinesBuilt,
			StageBalanced,
			StagePostingReady,
		},
	}
}

func validSalesInvoice() SourceDocument {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return SourceDocument{
		TenantID:         "tenant-001",
		CorrelationID:    "corr-001",
		RequestID:        "req-001",
		IdempotencyKey:   "idem-sales-001",
		DocumentType:     DocumentTypeSalesInvoice,
		DocumentID:       "sales-invoice-001",
		DocumentNo:       "INV-001",
		DocumentDate:     now,
		PartyID:          "party-001",
		PartyTitle:       "Test Musteri A.S.",
		PartyTaxNo:       "1234567890",
		NetAmountKurus:   1000000,
		TaxAmountKurus:   200000,
		GrossAmountKurus: 1200000,
		TaxRateBps:       2000,
		CurrencyCode:     "TRY",
		Description:      "Test satış faturası",
		SourceSystem:     "SALES_RUNTIME",
		RequestedBy:      "system-test",
		RequestedAt:      now,
	}
}

func newRuntime(t *testing.T) *VoucherPipelineRuntime {
	t.Helper()

	runtime, err := NewVoucherPipelineRuntime(validConfig(), DefaultTRAccountMapping())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	return runtime
}

func TestBuildSalesInvoiceVoucherBalancedAndPostingReady(t *testing.T) {
	runtime := newRuntime(t)

	voucher, err := runtime.BuildVoucher(validSalesInvoice())
	if err != nil {
		t.Fatalf("build voucher failed: %v", err)
	}

	if voucher.DecisionStatus != DecisionReady {
		t.Fatalf("expected READY, got %s", voucher.DecisionStatus)
	}
	if !voucher.PostingReady {
		t.Fatal("expected posting ready")
	}
	if !voucher.Balanced {
		t.Fatal("expected balanced voucher")
	}
	if voucher.TotalDebitKurus != 1200000 {
		t.Fatalf("expected debit 1200000, got %d", voucher.TotalDebitKurus)
	}
	if voucher.TotalCreditKurus != 1200000 {
		t.Fatalf("expected credit 1200000, got %d", voucher.TotalCreditKurus)
	}
	if len(voucher.Lines) != 3 {
		t.Fatalf("expected 3 lines, got %d", len(voucher.Lines))
	}
	if voucher.Lines[0].AccountCode != "120.01" {
		t.Fatalf("expected account 120.01, got %s", voucher.Lines[0].AccountCode)
	}
	if voucher.Lines[1].AccountCode != "600.01" {
		t.Fatalf("expected account 600.01, got %s", voucher.Lines[1].AccountCode)
	}
	if voucher.Lines[2].AccountCode != "391.01.20" {
		t.Fatalf("expected account 391.01.20, got %s", voucher.Lines[2].AccountCode)
	}
}

func TestBuildPurchaseInvoiceVoucherBalanced(t *testing.T) {
	runtime := newRuntime(t)

	doc := validSalesInvoice()
	doc.IdempotencyKey = "idem-purchase-001"
	doc.DocumentType = DocumentTypePurchaseInvoice
	doc.DocumentID = "purchase-invoice-001"
	doc.DocumentNo = "PUR-001"
	doc.SourceSystem = "PROCUREMENT_RUNTIME"

	voucher, err := runtime.BuildVoucher(doc)
	if err != nil {
		t.Fatalf("build purchase voucher failed: %v", err)
	}

	if !voucher.Balanced {
		t.Fatal("expected balanced voucher")
	}
	if voucher.Lines[0].AccountCode != "153.01" {
		t.Fatalf("expected inventory account 153.01, got %s", voucher.Lines[0].AccountCode)
	}
	if voucher.Lines[1].AccountCode != "191.01.20" {
		t.Fatalf("expected input KDV account 191.01.20, got %s", voucher.Lines[1].AccountCode)
	}
	if voucher.Lines[2].AccountCode != "320.01" {
		t.Fatalf("expected payable account 320.01, got %s", voucher.Lines[2].AccountCode)
	}
}

func TestBuildPaymentCollectionVoucherBalanced(t *testing.T) {
	runtime := newRuntime(t)

	doc := validSalesInvoice()
	doc.IdempotencyKey = "idem-collection-001"
	doc.DocumentType = DocumentTypePaymentCollection
	doc.DocumentID = "collection-001"
	doc.DocumentNo = "COL-001"
	doc.NetAmountKurus = 0
	doc.TaxAmountKurus = 0
	doc.GrossAmountKurus = 1200000
	doc.TaxRateBps = 0
	doc.SourceSystem = "PAYMENT_RUNTIME"

	voucher, err := runtime.BuildVoucher(doc)
	if err != nil {
		t.Fatalf("build collection voucher failed: %v", err)
	}

	if !voucher.Balanced {
		t.Fatal("expected balanced voucher")
	}
	if len(voucher.Lines) != 2 {
		t.Fatalf("expected 2 lines, got %d", len(voucher.Lines))
	}
	if voucher.Lines[0].AccountCode != "102.01" {
		t.Fatalf("expected bank account 102.01, got %s", voucher.Lines[0].AccountCode)
	}
	if voucher.Lines[1].AccountCode != "120.01" {
		t.Fatalf("expected receivable account 120.01, got %s", voucher.Lines[1].AccountCode)
	}
}

func TestBuildSalesRefundVoucherBalanced(t *testing.T) {
	runtime := newRuntime(t)

	doc := validSalesInvoice()
	doc.IdempotencyKey = "idem-sales-refund-001"
	doc.DocumentType = DocumentTypeSalesRefund
	doc.DocumentID = "sales-refund-001"
	doc.DocumentNo = "SRF-001"

	voucher, err := runtime.BuildVoucher(doc)
	if err != nil {
		t.Fatalf("build sales refund voucher failed: %v", err)
	}

	if !voucher.Balanced {
		t.Fatal("expected balanced voucher")
	}
	if voucher.Lines[0].AccountCode != "610.01" {
		t.Fatalf("expected sales return account 610.01, got %s", voucher.Lines[0].AccountCode)
	}
}

func TestBuildPurchaseRefundVoucherBalanced(t *testing.T) {
	runtime := newRuntime(t)

	doc := validSalesInvoice()
	doc.IdempotencyKey = "idem-purchase-refund-001"
	doc.DocumentType = DocumentTypePurchaseRefund
	doc.DocumentID = "purchase-refund-001"
	doc.DocumentNo = "PRF-001"

	voucher, err := runtime.BuildVoucher(doc)
	if err != nil {
		t.Fatalf("build purchase refund voucher failed: %v", err)
	}

	if !voucher.Balanced {
		t.Fatal("expected balanced voucher")
	}
	if voucher.Lines[0].AccountCode != "320.01" {
		t.Fatalf("expected payable debit account 320.01, got %s", voucher.Lines[0].AccountCode)
	}
}

func TestBuildVoucherRejectsAmountMismatch(t *testing.T) {
	runtime := newRuntime(t)

	doc := validSalesInvoice()
	doc.GrossAmountKurus = 1300000

	voucher, err := runtime.BuildVoucher(doc)
	if err == nil {
		t.Fatal("expected amount mismatch error")
	}
	if voucher.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", voucher.ErrorCode)
	}
}

func TestBuildVoucherRejectsCurrencyMismatch(t *testing.T) {
	runtime := newRuntime(t)

	doc := validSalesInvoice()
	doc.CurrencyCode = "USD"

	voucher, err := runtime.BuildVoucher(doc)
	if err == nil {
		t.Fatal("expected currency mismatch error")
	}
	if voucher.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", voucher.ErrorCode)
	}
}

func TestRuntimeRejectsInvalidAccountMapping(t *testing.T) {
	mapping := DefaultTRAccountMapping()
	mapping.AccountOutputKDV = "191.01.20"

	_, err := NewVoucherPipelineRuntime(validConfig(), mapping)
	if err == nil {
		t.Fatal("expected invalid output KDV account prefix error")
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewVoucherPipelineRuntime(cfg, DefaultTRAccountMapping())
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}
