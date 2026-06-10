package audittrace

import (
	"testing"
	"time"

	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		PersistenceEnabled:   true,
		AppendOnly:           true,
		IdempotencyRequired:  true,
		EvidenceHashRequired: true,
		SnapshotHashRequired: true,
		ActorRequired:        true,
		RetentionDays:        3650,
		AllowedSources: []TraceSource{
			SourceRealVoucherPipeline,
			SourceDocumentPostingRuntime,
			SourceChartAccountVersionSwitch,
			SourceReconciliationRuntime,
			SourceTDHPLiveTests,
			SourceManualReview,
		},
		AllowedActions: []TraceAction{
			ActionVoucherBuilt,
			ActionPostingPrepared,
			ActionPostingPosted,
			ActionPostingReversed,
			ActionPostingRejected,
			ActionAccountVersionSwitched,
			ActionReconciliationMatched,
			ActionReconciliationDifference,
			ActionManualReviewQueued,
		},
	}
}

func validPostingEntry() postingruntime.PostingEntry {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return postingruntime.PostingEntry{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-001",
		RequestID:      "req-001",
		IdempotencyKey: "posting-idem-001",
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
				Description:       "Alıcı borç",
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
				Description:       "Satış geliri",
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
				Description:       "KDV",
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

func validManualTrace() AuditTraceRecord {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return AuditTraceRecord{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-manual-001",
		RequestID:           "req-manual-001",
		IdempotencyKey:      "idem-manual-001",
		TraceID:             "trace-manual-001",
		Source:              SourceManualReview,
		Action:              ActionManualReviewQueued,
		Status:              TraceStatusRecorded,
		DocumentType:        "SALES_INVOICE",
		DocumentID:          "invoice-001",
		DocumentNo:          "INV-001",
		DocumentDate:        now,
		PostingID:           "posting-001",
		PostingNo:           "POST-TDHP-INV-001",
		PostingStatus:       "POSTED",
		CurrencyCode:        "TRY",
		TotalDebitKurus:     1200000,
		TotalCreditKurus:    1200000,
		Balanced:            true,
		LineCount:           3,
		EvidenceFilePath:    "docs/faz3/evidence/trace-manual-001.md",
		EvidenceHash:        "sha256:trace-manual-evidence",
		RequestHash:         "sha256:trace-manual-request",
		ResultHash:          "sha256:trace-manual-result",
		BeforeSnapshotHash:  "sha256:trace-manual-before",
		AfterSnapshotHash:   "sha256:trace-manual-after",
		PostingHash:         "posting:tenant-001:posting-001:1200000:1200000:3",
		AuditDecisionReason: "manual review queued",
		ActorID:             "ops-user-001",
		ActorRole:           "OPS",
		CreatedAt:           now,
	}
}

func newRuntime(t *testing.T) *AuditTracePersistenceRuntime {
	t.Helper()

	runtime, err := NewAuditTracePersistenceRuntime(validConfig(), NewInMemoryAuditTraceRepository())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	return runtime
}

func TestRecordFromPostingPersistsTrace(t *testing.T) {
	runtime := newRuntime(t)

	stored, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-001", "idem-trace-posting-001", ActionPostingPosted, "system", "SYSTEM")
	if err != nil {
		t.Fatalf("record from posting failed: %v", err)
	}

	if stored.TraceID != "trace-posting-001" {
		t.Fatalf("expected trace-posting-001, got %s", stored.TraceID)
	}
	if stored.Source != SourceDocumentPostingRuntime {
		t.Fatalf("expected document posting source, got %s", stored.Source)
	}
	if stored.Action != ActionPostingPosted {
		t.Fatalf("expected posting posted action, got %s", stored.Action)
	}
	if stored.TotalDebitKurus != 1200000 || stored.TotalCreditKurus != 1200000 {
		t.Fatal("expected debit/credit totals from posting")
	}
}

func TestFindTraceIsTenantScoped(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-001", "idem-trace-posting-001", ActionPostingPosted, "system", "SYSTEM"); err != nil {
		t.Fatalf("record trace failed: %v", err)
	}

	found, ok, err := runtime.FindTrace("tenant-001", "trace-posting-001")
	if err != nil {
		t.Fatalf("find trace failed: %v", err)
	}
	if !ok {
		t.Fatal("expected trace found")
	}
	if found.TraceID != "trace-posting-001" {
		t.Fatalf("expected trace-posting-001, got %s", found.TraceID)
	}

	_, ok, err = runtime.FindTrace("tenant-002", "trace-posting-001")
	if err != nil {
		t.Fatalf("cross tenant find failed: %v", err)
	}
	if ok {
		t.Fatal("expected tenant isolation")
	}
}

func TestDuplicateIdempotencyRejected(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-001", "idem-trace-posting-001", ActionPostingPosted, "system", "SYSTEM"); err != nil {
		t.Fatalf("record trace failed: %v", err)
	}

	_, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-002", "idem-trace-posting-001", ActionPostingPosted, "system", "SYSTEM")
	if err == nil {
		t.Fatal("expected duplicate idempotency error")
	}
}

func TestDuplicateTraceIDRejected(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-001", "idem-trace-posting-001", ActionPostingPosted, "system", "SYSTEM"); err != nil {
		t.Fatalf("record trace failed: %v", err)
	}

	_, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-001", "idem-trace-posting-002", ActionPostingPosted, "system", "SYSTEM")
	if err == nil {
		t.Fatal("expected duplicate trace id error")
	}
}

func TestListDocumentAndPostingTraces(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-001", "idem-trace-posting-001", ActionPostingPosted, "system", "SYSTEM"); err != nil {
		t.Fatalf("record posting trace failed: %v", err)
	}
	if _, err := runtime.RecordTrace(validManualTrace()); err != nil {
		t.Fatalf("record manual trace failed: %v", err)
	}

	documentTraces, err := runtime.ListDocumentTraces("tenant-001", "invoice-001")
	if err != nil {
		t.Fatalf("list document traces failed: %v", err)
	}
	if len(documentTraces) != 2 {
		t.Fatalf("expected 2 document traces, got %d", len(documentTraces))
	}

	postingTraces, err := runtime.ListPostingTraces("tenant-001", "posting-001")
	if err != nil {
		t.Fatalf("list posting traces failed: %v", err)
	}
	if len(postingTraces) != 2 {
		t.Fatalf("expected 2 posting traces, got %d", len(postingTraces))
	}
}

func TestExportTenantTraceAggregatesDocumentPostingSource(t *testing.T) {
	runtime := newRuntime(t)

	if _, err := runtime.RecordFromPosting(validPostingEntry(), "trace-posting-001", "idem-trace-posting-001", ActionPostingPosted, "system", "SYSTEM"); err != nil {
		t.Fatalf("record posting trace failed: %v", err)
	}
	if _, err := runtime.RecordTrace(validManualTrace()); err != nil {
		t.Fatalf("record manual trace failed: %v", err)
	}

	from := time.Date(2026, 5, 7, 0, 0, 0, 0, time.UTC)
	to := time.Date(2026, 5, 8, 0, 0, 0, 0, time.UTC)

	export, err := runtime.ExportTenantTrace("tenant-001", "corr-export", "req-export", "export-trace-001", SourceDocumentPostingRuntime, from, to)
	if err != nil {
		t.Fatalf("export failed: %v", err)
	}

	if export.RecordCount != 1 {
		t.Fatalf("expected 1 document posting trace, got %d", export.RecordCount)
	}
	if export.PostedCount != 1 {
		t.Fatalf("expected posted count 1, got %d", export.PostedCount)
	}
	if export.TotalDebitKurus != 1200000 || export.TotalCreditKurus != 1200000 {
		t.Fatal("expected exported totals")
	}
	if export.ExportHash == "" {
		t.Fatal("expected export hash")
	}
}

func TestValidationRejectsMissingEvidenceHash(t *testing.T) {
	runtime := newRuntime(t)

	record := validManualTrace()
	record.EvidenceHash = ""

	_, err := runtime.RecordTrace(record)
	if err == nil {
		t.Fatal("expected evidence hash error")
	}
}

func TestValidationRejectsMissingSnapshotHash(t *testing.T) {
	runtime := newRuntime(t)

	record := validManualTrace()
	record.BeforeSnapshotHash = ""

	_, err := runtime.RecordTrace(record)
	if err == nil {
		t.Fatal("expected before snapshot hash error")
	}
}

func TestValidationRejectsMissingActor(t *testing.T) {
	runtime := newRuntime(t)

	record := validManualTrace()
	record.ActorID = ""

	_, err := runtime.RecordTrace(record)
	if err == nil {
		t.Fatal("expected actor id error")
	}
}

func TestRuntimeRejectsNonAppendOnlyConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AppendOnly = false

	_, err := NewAuditTracePersistenceRuntime(cfg, NewInMemoryAuditTraceRepository())
	if err == nil {
		t.Fatal("expected append-only config error")
	}
}

func TestRuntimeRejectsNilRepository(t *testing.T) {
	_, err := NewAuditTracePersistenceRuntime(validConfig(), nil)
	if err == nil {
		t.Fatal("expected repository required error")
	}
}
