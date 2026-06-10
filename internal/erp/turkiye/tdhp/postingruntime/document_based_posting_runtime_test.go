package postingruntime

import (
	"testing"
	"time"

	voucherpipeline "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/voucherpipeline"
)

func validPostingConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:      true,
		DefaultCurrencyCode: "TRY",
		IdempotencyRequired: true,
		RequireVoucherReady: true,
		RequireBalanced:     true,
		RequireAuditTrace:   true,
		AppendOnlyLedger:    true,
		AllowReversal:       true,
		AllowedPostingSources: []PostingSource{
			SourceVoucherPipeline,
			SourceSalesRuntime,
			SourcePurchaseRuntime,
			SourcePaymentRuntime,
			SourceManualRuntime,
		},
	}
}

func validVoucherPipelineConfig() voucherpipeline.RuntimeConfig {
	return voucherpipeline.RuntimeConfig{
		RuntimeEnabled:        true,
		DefaultCurrencyCode:   "TRY",
		IdempotencyRequired:   true,
		StrictBalanceRequired: true,
		RequireTaxTrace:       true,
		RequirePartyTrace:     true,
		AllowedDocumentTypes: []voucherpipeline.DocumentType{
			voucherpipeline.DocumentTypeSalesInvoice,
			voucherpipeline.DocumentTypePurchaseInvoice,
			voucherpipeline.DocumentTypePaymentCollection,
			voucherpipeline.DocumentTypeSalesRefund,
			voucherpipeline.DocumentTypePurchaseRefund,
			voucherpipeline.DocumentTypeOpeningBalance,
		},
		RequiredStages: []voucherpipeline.PipelineStage{
			voucherpipeline.StageInputValidated,
			voucherpipeline.StageAccountMapped,
			voucherpipeline.StageLinesBuilt,
			voucherpipeline.StageBalanced,
			voucherpipeline.StagePostingReady,
		},
	}
}

func validSourceDocument() voucherpipeline.SourceDocument {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return voucherpipeline.SourceDocument{
		TenantID:         "tenant-001",
		CorrelationID:    "corr-voucher-001",
		RequestID:        "req-voucher-001",
		IdempotencyKey:   "idem-voucher-001",
		DocumentType:     voucherpipeline.DocumentTypeSalesInvoice,
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

func buildValidVoucher(t *testing.T) voucherpipeline.Voucher {
	t.Helper()

	voucherRuntime, err := voucherpipeline.NewVoucherPipelineRuntime(validVoucherPipelineConfig(), voucherpipeline.DefaultTRAccountMapping())
	if err != nil {
		t.Fatalf("voucher runtime init failed: %v", err)
	}

	voucher, err := voucherRuntime.BuildVoucher(validSourceDocument())
	if err != nil {
		t.Fatalf("voucher build failed: %v", err)
	}

	return voucher
}

func newPostingRuntime(t *testing.T) *DocumentPostingRuntime {
	t.Helper()

	runtime, err := NewDocumentPostingRuntime(validPostingConfig(), NewInMemoryPostingRepository())
	if err != nil {
		t.Fatalf("posting runtime init failed: %v", err)
	}

	return runtime
}

func validPostingRequest(t *testing.T) PostingRequest {
	t.Helper()

	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return PostingRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-posting-001",
		RequestID:      "req-posting-001",
		IdempotencyKey: "idem-posting-001",
		PostingID:      "posting-001",
		PostingSource:  SourceVoucherPipeline,
		Voucher:        buildValidVoucher(t),
		RequestedBy:    "posting-runtime-test",
		RequestedAt:    now,
	}
}

func TestPreparePostingFromVoucher(t *testing.T) {
	runtime := newPostingRuntime(t)

	entry, err := runtime.PreparePosting(validPostingRequest(t))
	if err != nil {
		t.Fatalf("prepare posting failed: %v", err)
	}

	if entry.Status != PostingStatusPrepared {
		t.Fatalf("expected PREPARED, got %s", entry.Status)
	}
	if !entry.LedgerReady {
		t.Fatal("expected ledger ready")
	}
	if entry.TotalDebitKurus != entry.TotalCreditKurus {
		t.Fatal("expected balanced posting entry")
	}
	if len(entry.Lines) != 3 {
		t.Fatalf("expected 3 posting lines, got %d", len(entry.Lines))
	}
}

func TestPostDocumentPersistsEntry(t *testing.T) {
	runtime := newPostingRuntime(t)

	entry, err := runtime.PostDocument(validPostingRequest(t))
	if err != nil {
		t.Fatalf("post document failed: %v", err)
	}

	if entry.Status != PostingStatusPosted {
		t.Fatalf("expected POSTED, got %s", entry.Status)
	}
	if entry.PostingHash == "" {
		t.Fatal("expected posting hash")
	}
	if entry.AuditTraceID == "" {
		t.Fatal("expected audit trace id")
	}

	found, ok, err := runtime.FindPosting("tenant-001", "posting-001")
	if err != nil {
		t.Fatalf("find posting failed: %v", err)
	}
	if !ok {
		t.Fatal("expected posting to be found")
	}
	if found.PostingID != "posting-001" {
		t.Fatalf("expected posting-001, got %s", found.PostingID)
	}
}

func TestPostDocumentRejectsDuplicateIdempotency(t *testing.T) {
	runtime := newPostingRuntime(t)

	if _, err := runtime.PostDocument(validPostingRequest(t)); err != nil {
		t.Fatalf("post document failed: %v", err)
	}

	duplicate := validPostingRequest(t)
	duplicate.PostingID = "posting-duplicate"

	_, err := runtime.PostDocument(duplicate)
	if err == nil {
		t.Fatal("expected duplicate idempotency error")
	}
}

func TestListDocumentPostingsIsTenantScoped(t *testing.T) {
	runtime := newPostingRuntime(t)

	if _, err := runtime.PostDocument(validPostingRequest(t)); err != nil {
		t.Fatalf("post document failed: %v", err)
	}

	entries, err := runtime.ListDocumentPostings("tenant-001", "sales-invoice-001")
	if err != nil {
		t.Fatalf("list document postings failed: %v", err)
	}
	if len(entries) != 1 {
		t.Fatalf("expected 1 posting, got %d", len(entries))
	}

	otherTenant, err := runtime.ListDocumentPostings("tenant-002", "sales-invoice-001")
	if err != nil {
		t.Fatalf("list cross tenant failed: %v", err)
	}
	if len(otherTenant) != 0 {
		t.Fatal("expected tenant scoped isolation")
	}
}

func TestReversePostingMirrorsDebitCredit(t *testing.T) {
	runtime := newPostingRuntime(t)

	posted, err := runtime.PostDocument(validPostingRequest(t))
	if err != nil {
		t.Fatalf("post document failed: %v", err)
	}

	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
	reversal, err := runtime.ReversePosting(ReversalRequest{
		TenantID:        "tenant-001",
		CorrelationID:   "corr-reversal-001",
		RequestID:       "req-reversal-001",
		IdempotencyKey:  "idem-reversal-001",
		ReversalID:      "reversal-001",
		OriginalPosting: posted,
		ReasonCode:      "POSTING_TEST_REVERSAL",
		ReasonText:      "Test reversal",
		RequestedBy:     "posting-runtime-test",
		RequestedAt:     now,
	})
	if err != nil {
		t.Fatalf("reverse posting failed: %v", err)
	}

	if reversal.Status != PostingStatusReversed {
		t.Fatalf("expected REVERSED, got %s", reversal.Status)
	}
	if !reversal.Balanced {
		t.Fatal("expected balanced reversal")
	}
	if reversal.TotalDebitKurus != posted.TotalCreditKurus {
		t.Fatalf("expected reversal debit %d, got %d", posted.TotalCreditKurus, reversal.TotalDebitKurus)
	}
	if reversal.TotalCreditKurus != posted.TotalDebitKurus {
		t.Fatalf("expected reversal credit %d, got %d", posted.TotalDebitKurus, reversal.TotalCreditKurus)
	}
}

func TestRejectsUnbalancedVoucher(t *testing.T) {
	runtime := newPostingRuntime(t)

	req := validPostingRequest(t)
	req.Voucher.TotalCreditKurus = 1
	req.Voucher.Balanced = false

	entry, err := runtime.PreparePosting(req)
	if err == nil {
		t.Fatal("expected unbalanced voucher error")
	}
	if entry.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", entry.ErrorCode)
	}
}

func TestRejectsVoucherWithoutPostingReady(t *testing.T) {
	runtime := newPostingRuntime(t)

	req := validPostingRequest(t)
	req.Voucher.PostingReady = false

	entry, err := runtime.PreparePosting(req)
	if err == nil {
		t.Fatal("expected posting_ready error")
	}
	if entry.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", entry.ErrorCode)
	}
}

func TestRejectsInvalidPostingSource(t *testing.T) {
	runtime := newPostingRuntime(t)

	req := validPostingRequest(t)
	req.PostingSource = "UNKNOWN"

	entry, err := runtime.PreparePosting(req)
	if err == nil {
		t.Fatal("expected invalid source error")
	}
	if entry.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", entry.ErrorCode)
	}
}

func TestRuntimeRejectsNonAppendOnlyLedger(t *testing.T) {
	cfg := validPostingConfig()
	cfg.AppendOnlyLedger = false

	_, err := NewDocumentPostingRuntime(cfg, NewInMemoryPostingRepository())
	if err == nil {
		t.Fatal("expected append-only ledger config error")
	}
}

func TestRuntimeRejectsNilRepository(t *testing.T) {
	_, err := NewDocumentPostingRuntime(validPostingConfig(), nil)
	if err == nil {
		t.Fatal("expected repository required error")
	}
}
