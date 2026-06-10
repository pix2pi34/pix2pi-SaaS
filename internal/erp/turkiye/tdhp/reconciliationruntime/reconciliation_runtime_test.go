package reconciliationruntime

import (
	"testing"
	"time"

	audittrace "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/audittrace"
	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:         true,
		DefaultCurrencyCode:    "TRY",
		IdempotencyRequired:    true,
		AppendOnlyResult:       true,
		RequireBalancedPosting: true,
		RequireAuditTrace:      true,
		ManualReviewEnabled:    true,
		ToleranceKurus:         0,
		AllowedActions: []ReconciliationAction{
			ActionPostingVsDocument,
			ActionPostingVsAuditTrace,
			ActionReversalVsPosting,
			ActionPeriodBalance,
			ActionManualReviewRegister,
		},
	}
}

func validPostingEntry() postingruntime.PostingEntry {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return postingruntime.PostingEntry{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-001",
		RequestID:      "req-001",
		IdempotencyKey: "idem-posting-001",
		PostingID:      "posting-001",
		PostingNo:      "POST-TDHP-INV-001",
		PostingSource:  postingruntime.SourceVoucherPipeline,
		Status:         postingruntime.PostingStatusPosted,
		VoucherID:      "voucher-001",
		VoucherNo:      "TDHP-INV-001",
		DocumentType:   "SALES_INVOICE",
		DocumentID:     "invoice-001",
		DocumentNo:     "INV-001",
		DocumentDate:   now,
		CurrencyCode:   "TRY",
		Lines: []postingruntime.PostingLine{
			{
				PostingLineID:     "posting-001:1",
				LineNo:            1,
				AccountCode:       "120.01",
				AccountName:       "Alıcılar",
				DebitAmountKurus:  1200000,
				CreditAmountKurus: 0,
				DocumentID:        "invoice-001",
				DocumentNo:        "INV-001",
				PartyID:           "party-001",
				PartyTaxNo:        "1234567890",
			},
			{
				PostingLineID:     "posting-001:2",
				LineNo:            2,
				AccountCode:       "600.01",
				AccountName:       "Satışlar",
				DebitAmountKurus:  0,
				CreditAmountKurus: 1000000,
				DocumentID:        "invoice-001",
				DocumentNo:        "INV-001",
				PartyID:           "party-001",
				PartyTaxNo:        "1234567890",
			},
			{
				PostingLineID:     "posting-001:3",
				LineNo:            3,
				AccountCode:       "391.01.20",
				AccountName:       "Hesaplanan KDV",
				DebitAmountKurus:  0,
				CreditAmountKurus: 200000,
				DocumentID:        "invoice-001",
				DocumentNo:        "INV-001",
				PartyID:           "party-001",
				PartyTaxNo:        "1234567890",
				TaxTraceCode:      "OUTPUT_KDV",
			},
		},
		TotalDebitKurus:     1200000,
		TotalCreditKurus:    1200000,
		Balanced:            true,
		PostingReady:        true,
		LedgerReady:         true,
		AuditTraceID:        "posting-audit:tenant-001:posting-001",
		PostingHash:         "posting:tenant-001:posting-001:1200000:1200000:3",
		AuditAction:         "DOCUMENT_BASED_POSTING_POSTED",
		AuditDecisionReason: "voucher posted to append-only ledger repository",
		PostedBy:            "posting-runtime-test",
		PostedAt:            now,
		CreatedAt:           now,
	}
}

func validAuditTrace() audittrace.AuditTraceRecord {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return audittrace.AuditTraceRecord{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-001",
		RequestID:           "req-001",
		IdempotencyKey:      "idem-trace-001",
		TraceID:             "trace-001",
		Source:              audittrace.SourceDocumentPostingRuntime,
		Action:              audittrace.ActionPostingPosted,
		Status:              audittrace.TraceStatusRecorded,
		DocumentType:        "SALES_INVOICE",
		DocumentID:          "invoice-001",
		DocumentNo:          "INV-001",
		DocumentDate:        now,
		VoucherID:           "voucher-001",
		VoucherNo:           "TDHP-INV-001",
		PostingID:           "posting-001",
		PostingNo:           "POST-TDHP-INV-001",
		PostingStatus:       "POSTED",
		CurrencyCode:        "TRY",
		TotalDebitKurus:     1200000,
		TotalCreditKurus:    1200000,
		Balanced:            true,
		LineCount:           3,
		EvidenceFilePath:    "docs/faz3/evidence/trace-001.md",
		EvidenceHash:        "sha256:trace-evidence",
		RequestHash:         "sha256:trace-request",
		ResultHash:          "sha256:trace-result",
		BeforeSnapshotHash:  "sha256:trace-before",
		AfterSnapshotHash:   "sha256:trace-after",
		PostingHash:         "posting:tenant-001:posting-001:1200000:1200000:3",
		AuditDecisionReason: "posting trace",
		ActorID:             "system",
		ActorRole:           "SYSTEM",
		CreatedAt:           now,
	}
}

func validExpectedDocument() ExpectedDocument {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return ExpectedDocument{
		DocumentType:        "SALES_INVOICE",
		DocumentID:          "invoice-001",
		DocumentNo:          "INV-001",
		DocumentDate:        now,
		CurrencyCode:        "TRY",
		ExpectedDebitKurus:  1200000,
		ExpectedCreditKurus: 1200000,
		ExpectedGrossKurus:  1200000,
		ExpectedPostingID:   "posting-001",
		ExpectedVoucherID:   "voucher-001",
	}
}

func validRequest() ReconciliationRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return ReconciliationRequest{
		TenantID:         "tenant-001",
		CorrelationID:    "corr-recon-001",
		RequestID:        "req-recon-001",
		IdempotencyKey:   "idem-recon-001",
		ReconciliationID: "recon-001",
		Action:           ActionPostingVsAuditTrace,
		ExpectedDocument: validExpectedDocument(),
		PostingEntry:     validPostingEntry(),
		AuditTrace:       validAuditTrace(),
		RequestedBy:      "reconciliation-test",
		RequestedAt:      now,
	}
}

func newRuntime(t *testing.T) *ReconciliationRuntime {
	t.Helper()

	runtime, err := NewReconciliationRuntime(validConfig(), NewInMemoryReconciliationRepository())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	return runtime
}

func TestReconcileMatchedPostingVsAuditTrace(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Reconcile(validRequest())
	if err != nil {
		t.Fatalf("reconcile failed: %v", err)
	}

	if result.Status != ReconciliationStatusMatched {
		t.Fatalf("expected MATCHED, got %s", result.Status)
	}
	if !result.Matched {
		t.Fatal("expected matched")
	}
	if !result.LedgerClosureReady {
		t.Fatal("expected ledger closure ready")
	}
	if len(result.Differences) != 0 {
		t.Fatalf("expected no differences, got %d", len(result.Differences))
	}
}

func TestReconcileDetectsAmountDifference(t *testing.T) {
	runtime := newRuntime(t)

	req := validRequest()
	req.ReconciliationID = "recon-diff-001"
	req.IdempotencyKey = "idem-recon-diff-001"
	req.ExpectedDocument.ExpectedDebitKurus = 1100000

	result, err := runtime.Reconcile(req)
	if err != nil {
		t.Fatalf("reconcile difference should persist result, got error: %v", err)
	}

	if result.Status != ReconciliationStatusDifference {
		t.Fatalf("expected DIFFERENCE, got %s", result.Status)
	}
	if result.Matched {
		t.Fatal("expected not matched")
	}
	if !result.ManualReviewReady {
		t.Fatal("expected manual review ready")
	}
	if result.LedgerClosureReady {
		t.Fatal("expected ledger closure not ready")
	}
	if len(result.Differences) == 0 {
		t.Fatal("expected differences")
	}
}

func TestReconcileDetectsAuditTracePostingHashDifference(t *testing.T) {
	runtime := newRuntime(t)

	req := validRequest()
	req.ReconciliationID = "recon-trace-diff-001"
	req.IdempotencyKey = "idem-recon-trace-diff-001"
	req.AuditTrace.PostingHash = "posting:bad-hash"

	result, err := runtime.Reconcile(req)
	if err != nil {
		t.Fatalf("reconcile trace difference should persist result, got error: %v", err)
	}

	if result.Status != ReconciliationStatusDifference {
		t.Fatalf("expected DIFFERENCE, got %s", result.Status)
	}
	if len(result.Differences) == 0 {
		t.Fatal("expected audit trace difference")
	}
}

func TestDuplicateIdempotencyRejected(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.Reconcile(validRequest()); err != nil {
		t.Fatalf("first reconcile failed: %v", err)
	}

	req := validRequest()
	req.ReconciliationID = "recon-duplicate-001"

	_, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected duplicate idempotency error")
	}
}

func TestTenantScopedFindAndListing(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.Reconcile(validRequest()); err != nil {
		t.Fatalf("reconcile failed: %v", err)
	}

	found, ok, err := runtime.FindReconciliation("tenant-001", "recon-001")
	if err != nil {
		t.Fatalf("find failed: %v", err)
	}
	if !ok {
		t.Fatal("expected reconciliation found")
	}
	if found.ReconciliationID != "recon-001" {
		t.Fatalf("expected recon-001, got %s", found.ReconciliationID)
	}

	_, ok, err = runtime.FindReconciliation("tenant-002", "recon-001")
	if err != nil {
		t.Fatalf("cross tenant find failed: %v", err)
	}
	if ok {
		t.Fatal("expected tenant scoped isolation")
	}

	documentResults, err := runtime.ListDocumentReconciliations("tenant-001", "invoice-001")
	if err != nil {
		t.Fatalf("list document failed: %v", err)
	}
	if len(documentResults) != 1 {
		t.Fatalf("expected 1 document reconciliation, got %d", len(documentResults))
	}

	postingResults, err := runtime.ListPostingReconciliations("tenant-001", "posting-001")
	if err != nil {
		t.Fatalf("list posting failed: %v", err)
	}
	if len(postingResults) != 1 {
		t.Fatalf("expected 1 posting reconciliation, got %d", len(postingResults))
	}
}

func TestRegisterManualReview(t *testing.T) {
	runtime := newRuntime(t)

	req := validRequest()
	req.ReconciliationID = "recon-review-001"
	req.IdempotencyKey = "idem-recon-review-001"
	req.ExpectedDocument.ExpectedDebitKurus = 1100000

	result, err := runtime.RegisterManualReview(req, "amount difference requires review")
	if err != nil {
		t.Fatalf("register manual review failed: %v", err)
	}

	if result.Status != ReconciliationStatusManualReview {
		t.Fatalf("expected MANUAL_REVIEW, got %s", result.Status)
	}
	if !result.ManualReviewReady {
		t.Fatal("expected manual review ready")
	}
}

func TestRejectsUnbalancedPosting(t *testing.T) {
	runtime := newRuntime(t)

	req := validRequest()
	req.PostingEntry.Balanced = false

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected unbalanced posting error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRejectsMissingAuditTraceWhenRequired(t *testing.T) {
	runtime := newRuntime(t)

	req := validRequest()
	req.AuditTrace.TraceID = ""

	result, err := runtime.Reconcile(req)
	if err == nil {
		t.Fatal("expected missing audit trace error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsNonAppendOnlyConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AppendOnlyResult = false

	_, err := NewReconciliationRuntime(cfg, NewInMemoryReconciliationRepository())
	if err == nil {
		t.Fatal("expected append-only result config error")
	}
}

func TestRuntimeRejectsNilRepository(t *testing.T) {
	_, err := NewReconciliationRuntime(validConfig(), nil)
	if err == nil {
		t.Fatal("expected repository required error")
	}
}
